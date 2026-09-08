import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Səs kanalları. Hər kanal ayrıca söndürülə bilər, master açar hamısını
/// üstələyir.
///
/// Kanal bölgüsü faylın adına yox, səsin ROLUNA görədir: `click.mp3` həm pazlda,
/// həm hərf cızmada çalınır və hər ikisi [SoundChannel.effect]-dir.
enum SoundChannel {
  /// Hərfin və heyvanın izahı (`…_info_sound.mp3`) — uzun, danışıq səsi.
  narration,

  /// Heyvanın öz səsi (`…_sound.mp3`).
  animal,

  /// Qısa oyun effektləri: `click.mp3`, `win.mp3`, `page_flip.mp3`.
  effect,
}

/// İstifadəçi ayarlarını saxlayan store.
///
/// Forması bilərəkdən [ProgressStore] (`progress.dart`) ilə eynidir — eyni
/// `ChangeNotifier` + singleton + versiyalı JSON açarı + debounce nümunəsi.
/// Layihədə iki fərqli saxlama üslubu olmasın deyə yeni bir yanaşma
/// icad edilmir.
///
/// UI-a `AnimatedBuilder` ilə bağlanır; səs kodu isə dinləyici saxlamır,
/// çalınma anında birbaşa [isOn] oxuyur.
class AppSettings extends ChangeNotifier {
  AppSettings._();

  /// Tətbiq boyu tək nüsxə. `main()`-də [load] çağırılır.
  static final AppSettings instance = AppSettings._();

  /// Testlər üçün təmiz, diskə yazmayan nüsxə.
  @visibleForTesting
  factory AppSettings.forTesting() => AppSettings._();

  static const String _prefsKey = 'settings_v1';

  /// Diskə yazmanı gecikdirmə müddəti — açarı sürətlə bir neçə dəfə çevirmək
  /// hər dəfə SharedPreferences-ə yazmasın.
  static const Duration _saveDebounce = Duration(milliseconds: 400);

  /// İcazə verilən pazl ölçüləri. `puzzle_page.dart`-dakı seçici ilə eynidir.
  static const List<int> puzzleGridSizes = [3, 4];

  SharedPreferences? _prefs;
  Timer? _saveTimer;

  bool _masterSound = true;
  bool _narrationSound = true;
  bool _animalSound = true;
  bool _effectSound = true;
  bool _haptics = true;
  bool _reduceMotion = false;
  int _puzzleGridSize = 3;

  // ------------------------------------------------------------------ oxuma

  /// Ümumi səs açarı — söndürüləndə bütün kanallar susur, amma alt açarların
  /// öz dəyəri İTMİR (master geri açılanda əvvəlki vəziyyət qayıdır).
  bool get masterSound => _masterSound;

  /// İzah/nəqletmə kanalının öz açarı (master-dən asılı olmayan xam dəyər).
  bool get narrationSound => _narrationSound;

  /// Heyvan səsi kanalının öz açarı.
  bool get animalSound => _animalSound;

  /// Effekt kanalının öz açarı.
  bool get effectSound => _effectSound;

  /// Hərf cızarkən titrəmə (`TracingCanvas`).
  bool get haptics => _haptics;

  /// Konfeti və digər təbrik animasiyalarını söndürür.
  bool get reduceMotion => _reduceMotion;

  /// Şəkil pazlının ölçüsü (3 → 3x3, 4 → 4x4).
  int get puzzleGridSize => _puzzleGridSize;

  /// Kanal HAZIRDA səslənirmi. Səs çalan hər kod yolu bunu yoxlamalıdır —
  /// praktikada bunu `GatedPlayer` (`sound.dart`) avtomatik edir.
  bool isOn(SoundChannel channel) {
    if (!_masterSound) return false;
    switch (channel) {
      case SoundChannel.narration:
        return _narrationSound;
      case SoundChannel.animal:
        return _animalSound;
      case SoundChannel.effect:
        return _effectSound;
    }
  }

  // ------------------------------------------------------------------ yazma

  set masterSound(bool value) =>
      _set(() => _masterSound = value, _masterSound != value);

  set narrationSound(bool value) =>
      _set(() => _narrationSound = value, _narrationSound != value);

  set animalSound(bool value) =>
      _set(() => _animalSound = value, _animalSound != value);

  set effectSound(bool value) =>
      _set(() => _effectSound = value, _effectSound != value);

  set haptics(bool value) => _set(() => _haptics = value, _haptics != value);

  set reduceMotion(bool value) =>
      _set(() => _reduceMotion = value, _reduceMotion != value);

  /// Naməlum ölçü səssizcə buraxılır — `ProgressStore.markWritten()`-in
  /// əlifbada olmayan hərfi buraxdığı kimi.
  set puzzleGridSize(int value) {
    if (!puzzleGridSizes.contains(value)) return;
    _set(() => _puzzleGridSize = value, _puzzleGridSize != value);
  }

  void _set(VoidCallback apply, bool changed) {
    if (!changed) return;
    apply();
    _scheduleSave();
    notifyListeners();
  }

  // ------------------------------------------------------------- saxlanma

  /// SharedPreferences-dən ayarları oxuyur. Xəta olsa tətbiq default
  /// dəyərlərlə işləməyə davam edir — ayarların oxunmaması tətbiqi
  /// dayandırmamalıdır.
  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _restore(_prefs!.getString(_prefsKey));
    } catch (e) {
      debugPrint('Ayarlar yüklənmədi: $e');
    }
  }

  void _scheduleSave() {
    // `ProgressStore._scheduleSave()` ilə eyni səbəb: `_prefs` yoxdursa timer
    // qurulmur, əks halda widget testlərində ağac söküləndən sonra "pending
    // timer" xətası qalır.
    if (_prefs == null) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDebounce, _persist);
  }

  Future<void> _persist() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await prefs.setString(_prefsKey, encodeState());
    } catch (e) {
      debugPrint('Ayarlar yazılmadı: $e');
    }
  }

  /// JSON açarları qısa və SABİTdir — sahə adı dəyişsə də saxlanmış ayar itməsin.
  @visibleForTesting
  String encodeState() => jsonEncode({
    'v': 1,
    'm': _masterSound,
    'n': _narrationSound,
    'a': _animalSound,
    'e': _effectSound,
    'h': _haptics,
    'r': _reduceMotion,
    'g': _puzzleGridSize,
  });

  @visibleForTesting
  void restoreFromJson(String? raw) => _restore(raw);

  /// Zədələnmiş və ya natamam JSON təhlükəsizdir: oxunmayan hər sahə öz default
  /// dəyərində qalır, ümumi `catch` isə tam sıfırlamanı əvəz edir.
  void _restore(String? raw) {
    _masterSound = true;
    _narrationSound = true;
    _animalSound = true;
    _effectSound = true;
    _haptics = true;
    _reduceMotion = false;
    _puzzleGridSize = 3;
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      _masterSound = _bool(decoded['m'], _masterSound);
      _narrationSound = _bool(decoded['n'], _narrationSound);
      _animalSound = _bool(decoded['a'], _animalSound);
      _effectSound = _bool(decoded['e'], _effectSound);
      _haptics = _bool(decoded['h'], _haptics);
      _reduceMotion = _bool(decoded['r'], _reduceMotion);
      final grid = decoded['g'];
      if (grid is int && puzzleGridSizes.contains(grid)) _puzzleGridSize = grid;
    } catch (e) {
      debugPrint('Ayarlar oxunmadı: $e');
    }
  }

  static bool _bool(Object? value, bool fallback) =>
      value is bool ? value : fallback;

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}
