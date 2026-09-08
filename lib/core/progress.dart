import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config.dart';

/// Ulduz sistemində sayılan HEYVAN bölmələri.
///
/// Hərf cızma tapşırığı burada yoxdur — o, heyvana yox, hərfə bağlıdır və
/// `ProgressStore._writtenLetters` dəstində ayrıca saxlanılır.
///
/// Səsli bölmələr (heyvanın info audiosu, heyvan səsi, hərfin tələffüzü)
/// BİLƏRƏKDƏN bura daxil edilmir: audio fayllarının əhatəsi tam deyil (91
/// heyvandan 31-inin info səsi, 32 hərfdən yalnız 3-ünün tələffüzü var), ona görə
/// onları saymaq çoxlu heyvanı tam ulduzdan məhrum edərdi. Uşaqdan qulaq asmaq
/// tələb olunmur.
enum Activity {
  /// Məlumat bölməsi açıldı. Detal səhifəsi açılanda bu bölmə defolt görünür,
  /// yəni heyvanı ilk dəfə açmaq bu tapşırığı tamamlayır.
  info,

  /// Heyvanın BÜTÜN qidaları bir-bir ona verildi.
  foods,

  /// Söz tapmacası düzgün yığıldı.
  wordPuzzle,

  /// Şəkil pazlı tamamlandı. Yalnız `AppConfig.animalHasPuzzle` true olanlarda.
  tilePuzzle,
}

/// JSON-da saxlanılan qısa, sabit adlar. Enum adlarını birbaşa yazmırıq ki,
/// gələcəkdə enum yenidən adlandırılsa saxlanmış progres itməsin.
const Map<Activity, String> _activityKeys = {
  Activity.info: 'info',
  Activity.foods: 'foods',
  Activity.wordPuzzle: 'word',
  Activity.tilePuzzle: 'puzzle',
};

final Map<String, Activity> _activityByKey = {
  for (final e in _activityKeys.entries) e.value: e.key,
};

/// Öyrənilmiş bölmələri saxlayan və hərf/heyvan üzrə ulduz hesablayan store.
///
/// Paket asılılığı olmadan (`ChangeNotifier` Flutter-in özündədir) `AnimatedBuilder`
/// ilə istifadə olunur — layihənin "sadə setState" konvensiyasını pozmur.
class ProgressStore extends ChangeNotifier {
  ProgressStore._() {
    _buildPlan();
  }

  /// Tətbiq boyu tək nüsxə. `main()`-də `load()` çağırılır.
  static final ProgressStore instance = ProgressStore._();

  /// Testlər üçün təmiz, diskə yazmayan nüsxə.
  @visibleForTesting
  factory ProgressStore.forTesting() => ProgressStore._();

  static const String _prefsKey = 'progress_v1';

  /// Bir hərfin maksimum ulduz sayı.
  static const int maxStarsPerLetter = 3;

  /// Diskə yazmanı gecikdirmə müddəti — sürətli qida toxunuşları hər dəfə
  /// SharedPreferences-ə yazmasın.
  static const Duration _saveDebounce = Duration(milliseconds: 400);

  /// Kiçik → böyük hərf cədvəli (Azərbaycan əlifbasının 32 hərfi).
  ///
  /// CLAUDE.md → "Gotchas" 2-ci bənd: Dart-ın `toUpperCase()`-i Unicode-un
  /// dilə bağlı olmayan sadə qaydasını tətbiq edir, ona görə `'i'` → `'I'`
  /// (U+0049) verir, halbuki Azərbaycan dilində `'i'`-nin böyüyü `'İ'`-dir —
  /// nəticədə `markWritten('i')` səhvən `I` hərfini yazılmış sayırdı. Ona görə
  /// açar həmişə bu AÇIQ cədvəldən götürülür, `toUpperCase()`-dən yox.
  static const Map<String, String> _upperByLower = {
    'a': 'A',
    'b': 'B',
    'c': 'C',
    'ç': 'Ç',
    'd': 'D',
    'e': 'E',
    'ə': 'Ə',
    'f': 'F',
    'g': 'G',
    'ğ': 'Ğ',
    'h': 'H',
    'x': 'X',
    'ı': 'I',
    'i': 'İ',
    'j': 'J',
    'k': 'K',
    'q': 'Q',
    'l': 'L',
    'm': 'M',
    'n': 'N',
    'o': 'O',
    'ö': 'Ö',
    'p': 'P',
    'r': 'R',
    's': 'S',
    'ş': 'Ş',
    't': 'T',
    'u': 'U',
    'ü': 'Ü',
    'v': 'V',
    'y': 'Y',
    'z': 'Z',
  };

  /// Hərfi progres açarına (böyük hərfə) çevirir: əvvəlcə cədvələ baxır, orada
  /// yoxdursa `toUpperCase()`-ə düşür. Artıq böyük olan hərf olduğu kimi qalır
  /// (`'I'` → `'I'`, `'İ'` → `'İ'`, `'Ə'` → `'Ə'`).
  static String _canonical(String letter) =>
      _upperByLower[letter] ?? letter.toUpperCase();

  SharedPreferences? _prefs;
  Timer? _saveTimer;

  // --- Yığılmış progres (heyvan adı açardır, config-dəki join-key ilə eyni) ---
  final Map<String, Set<Activity>> _done = {};
  final Map<String, Set<String>> _fedFoods = {};
  final Set<String> _celebratedLetters = {};

  /// Cızma (yazma) tapşırığını tamamlamış hərflər — açar böyük hərfdir.
  ///
  /// Bilərəkdən [Activity] enum-una əlavə edilmir: enum HEYVAN açarlıdır
  /// (`_done`, `_tasksByAnimal`, bərpa məntiqi hamısı heyvan planına baxır),
  /// hərf yazmaq isə heyvana yox, HƏRFƏ bağlıdır. Ayrı dəst saxlamaq iki
  /// modeli qarışdırmır.
  final Set<String> _writtenLetters = {};

  // --- Tapşırıq planı: bir dəfə qurulur və keşlənir ---
  // `AppConfig.findLetter()` hər çağırışda yeni obyektlər yaradır; əlifba səhifəsi
  // 32 hərf üçün hər rebuild-də onu çağırsa ~91 `AnimalInfo` allokasiyası olardı.
  final Map<String, List<Activity>> _tasksByAnimal = {};
  final Map<String, int> _totalByLetter = {};

  void _buildPlan() {
    _tasksByAnimal.clear();
    _totalByLetter.clear();
    for (final letter in AppConfig.alphabet) {
      final names = AppConfig.animalsByLetter[letter] ?? const <String>[];
      var total = 0;
      for (final name in names) {
        final tasks = <Activity>[Activity.info];
        if ((AppConfig.animalFoods[name] ?? const <String>[]).isNotEmpty) {
          tasks.add(Activity.foods);
        }
        if (name.isNotEmpty) tasks.add(Activity.wordPuzzle);
        if (AppConfig.animalHasPuzzle[name] ?? false) {
          tasks.add(Activity.tilePuzzle);
        }
        _tasksByAnimal[name] = tasks;
        total += tasks.length;
      }
      // Hərfi cızmaq da bir tapşırıqdır. `letter_strokes_test.dart` bütün 32
      // hərfin ştrix datasının olmasını təmin edir, ona görə İSTİSNASIZ hər
      // hərf +1 alır — heyvanı olmayan Ğ, I, Ü daxil.
      _totalByLetter[letter] = total + 1;
    }
  }

  /// SharedPreferences-dən saxlanmış progresi oxuyur. Xəta olsa tətbiq yaddaşdaki
  /// (boş) progreslə işləməyə davam edir.
  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _restore(_prefs!.getString(_prefsKey));
    } catch (e) {
      debugPrint('Progres yüklənmədi: $e');
    }
  }

  // --------------------------------------------------------------- sorğular

  /// Heyvanın mövcud (əldə edilə bilən) bölmələri.
  List<Activity> tasksOf(String animal) =>
      _tasksByAnimal[animal] ?? const <Activity>[];

  bool isDone(String animal, Activity activity) =>
      _done[animal]?.contains(activity) ?? false;

  /// Heyvana artıq verilmiş qidalar.
  Set<String> fedFoods(String animal) =>
      Set.unmodifiable(_fedFoods[animal] ?? const <String>{});

  /// Yalnız plandaki bölmələri sayır — köhnə/naməlum qeyd cəmi şişirtməsin.
  int animalDone(String animal) {
    final done = _done[animal];
    if (done == null || done.isEmpty) return 0;
    var count = 0;
    for (final task in tasksOf(animal)) {
      if (done.contains(task)) count++;
    }
    return count;
  }

  int animalTotal(String animal) => tasksOf(animal).length;

  int animalStars(String animal) =>
      starsFor(animalDone(animal), animalTotal(animal));

  int letterDone(String letter) {
    final key = _canonical(letter);
    final names = AppConfig.animalsByLetter[key] ?? const <String>[];
    var count = 0;
    for (final name in names) {
      count += animalDone(name);
    }
    // Cızma tapşırığı — plandakı +1-in qarşılığı.
    if (_writtenLetters.contains(key)) count++;
    return count;
  }

  /// Hərf cızma tapşırığı tamamlanıbmı.
  bool isWritten(String letter) => _writtenLetters.contains(_canonical(letter));

  /// Yazılmış hərflərin sayı (valideyn ekranı / statistika üçün).
  int get writtenLetterCount => _writtenLetters.length;

  int letterTotal(String letter) => _totalByLetter[_canonical(letter)] ?? 0;

  int starsOf(String letter) =>
      starsFor(letterDone(letter), letterTotal(letter));

  /// Hərfin ulduz yığa biləcəyi məzmunu varmı.
  ///
  /// Cızma tapşırığı əlavə olunandan sonra əlifbadaki HƏR hərf üçün `true`-dur:
  /// heyvanı olmayan Ğ, I, Ü hərfləri də artıq yazıla bilir, deməli onların da
  /// ulduzu var — köhnəlmiş solğun "—" halı yalnız əlifbada olmayan (naməlum)
  /// hərf üçün qalır. Metod API kimi saxlanılır ki, çağıran səhifələr
  /// dəyişməsin və gələcəkdə hansısa hərf məzmunsuz qalsa yenə işləsin.
  bool hasContent(String letter) => letterTotal(letter) > 0;

  /// Toplanmış ulduz sayı (məzmunu olmayan hərflər sayılmır).
  int get totalStars {
    var sum = 0;
    for (final letter in AppConfig.alphabet) {
      sum += starsOf(letter);
    }
    return sum;
  }

  /// Mümkün maksimum ulduz sayı. Cızma tapşırığı hər hərfə məzmun verdiyi üçün
  /// bu indi 32 x 3 = 96-dır (əvvəl 29 x 3 = 87 idi).
  int get maxTotalStars {
    var count = 0;
    for (final letter in AppConfig.alphabet) {
      if (hasContent(letter)) count++;
    }
    return count * maxStarsPerLetter;
  }

  /// Ulduz düsturu. Heç nə edilməyibsə 0; hər şey edilibsə 3 (tam ulduz);
  /// arada — 2/3-dən çoxdursa 2, əks halda 1. Yəni ilk tamamlanan bölmə həmişə
  /// görünən mükafat verir, üçüncü ulduz isə yalnız hər şey bitəndə açılır.
  static int starsFor(int done, int total) {
    if (total <= 0 || done <= 0) return 0;
    if (done >= total) return maxStarsPerLetter;
    return done / total >= 2 / 3 ? 2 : 1;
  }

  // --------------------------------------------------------------- yazmalar

  /// Bölməni tamamlanmış kimi qeyd edir. Plana daxil olmayan bölmə nəzərə alınmır.
  void markDone(String animal, Activity activity) {
    if (!tasksOf(animal).contains(activity)) return;
    final done = _done.putIfAbsent(animal, () => <Activity>{});
    if (!done.add(activity)) return;
    _scheduleSave();
    notifyListeners();
  }

  /// Bir qidanın verildiyini qeyd edir; hamısı verilibsə `foods` bölməsini bağlayır.
  void markFoodFed(String animal, String food) {
    final all = AppConfig.animalFoods[animal] ?? const <String>[];
    if (!all.contains(food)) return;
    final fed = _fedFoods.putIfAbsent(animal, () => <String>{});
    if (!fed.add(food)) return;
    if (fed.length >= all.length) {
      _done.putIfAbsent(animal, () => <Activity>{}).add(Activity.foods);
    }
    _scheduleSave();
    notifyListeners();
  }

  /// Hərfin cızıldığını qeyd edir. Təkrar çağırış vəziyyəti dəyişmir.
  /// Əlifbada olmayan hərf səssizcə buraxılır — `markDone`-un naməlum heyvanı
  /// buraxdığı kimi.
  void markWritten(String letter) {
    final key = _canonical(letter);
    if (!AppConfig.alphabet.contains(key)) return;
    if (!_writtenLetters.add(key)) return;
    _scheduleSave();
    notifyListeners();
  }

  /// Hərf ilk dəfə 100%-ə çatanda `true` qaytarır — təbrik yalnız bir dəfə görünsün.
  ///
  /// Cızma tapşırığı plana daxil olduğuna görə hərf yazılmayana qədər 100%-ə
  /// çatmır, yəni heyvanların hamısı bitsə də təbrik verilmir. Bu qəsdəndir:
  /// hərfin təbriki artıq "bu hərfi tam öyrəndim" deməkdir, yazmaq da buna daxildir.
  bool takeLetterCelebration(String letter) {
    final key = _canonical(letter);
    final total = letterTotal(key);
    if (total <= 0 || letterDone(key) < total) return false;
    if (!_celebratedLetters.add(key)) return false;
    _scheduleSave();
    return true;
  }

  /// Bütün progresi silir (valideyn üçün "sıfırla").
  Future<void> reset() async {
    _done.clear();
    _fedFoods.clear();
    _celebratedLetters.clear();
    _writtenLetters.clear();
    notifyListeners();
    _saveTimer?.cancel();
    _saveTimer = null;
    await _persist();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }

  // ------------------------------------------------------------- saxlanma

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDebounce, _persist);
  }

  Future<void> _persist() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(_prefsKey, encodeState());
    } catch (e) {
      debugPrint('Progres yazılmadı: $e');
    }
  }

  @visibleForTesting
  String encodeState() {
    final animals = <String, dynamic>{};
    for (final name in {..._done.keys, ..._fedFoods.keys}) {
      final done = _done[name] ?? const <Activity>{};
      final fed = _fedFoods[name] ?? const <String>{};
      if (done.isEmpty && fed.isEmpty) continue;
      animals[name] = {
        if (done.isNotEmpty) 'd': [for (final a in done) _activityKeys[a]!],
        if (fed.isNotEmpty) 'f': fed.toList(),
      };
    }
    return jsonEncode({
      'v': 1,
      'a': animals,
      if (_celebratedLetters.isNotEmpty) 'c': _celebratedLetters.toList(),
      // Sıralanmış siyahı: eyni progres həmişə eyni JSON versin (deterministik).
      if (_writtenLetters.isNotEmpty) 'w': _writtenLetters.toList()..sort(),
    });
  }

  /// Naməlum açar, naməlum bölmə adı və konfiqurasiyadan çıxarılmış heyvan
  /// səssizcə buraxılır — köhnə qeydlər yeni versiyanı sındırmasın.
  @visibleForTesting
  void restoreFromJson(String? raw) => _restore(raw);

  void _restore(String? raw) {
    _done.clear();
    _fedFoods.clear();
    _celebratedLetters.clear();
    _writtenLetters.clear();
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;

      final animals = decoded['a'];
      if (animals is Map) {
        animals.forEach((name, value) {
          if (name is! String || value is! Map) return;
          final tasks = _tasksByAnimal[name];
          if (tasks == null) return;

          final rawDone = value['d'];
          if (rawDone is List) {
            final done = <Activity>{};
            for (final key in rawDone) {
              final activity = _activityByKey[key];
              if (activity != null && tasks.contains(activity)) {
                done.add(activity);
              }
            }
            if (done.isNotEmpty) _done[name] = done;
          }

          final rawFed = value['f'];
          if (rawFed is List) {
            final all = AppConfig.animalFoods[name] ?? const <String>[];
            final fed = <String>{
              for (final food in rawFed)
                if (food is String && all.contains(food)) food,
            };
            if (fed.isNotEmpty) _fedFoods[name] = fed;
          }
        });
      }

      final celebrated = decoded['c'];
      if (celebrated is List) {
        for (final letter in celebrated) {
          if (letter is String) _celebratedLetters.add(_canonical(letter));
        }
      }

      // Cızma dəsti. Köhnə qeydlərdə 'w' açarı yoxdur — o halda dəst boş qalır
      // (geriyə uyğunluq), yalnız əlifbadaki hərflər qəbul olunur.
      final written = decoded['w'];
      if (written is List) {
        for (final letter in written) {
          if (letter is! String) continue;
          final key = _canonical(letter);
          if (AppConfig.alphabet.contains(key)) _writtenLetters.add(key);
        }
      }
    } catch (e) {
      debugPrint('Saxlanmış progres oxunmadı: $e');
    }
  }
}
