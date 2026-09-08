// Məzmun bütövlüyü testləri.
//
// Bu fayl `lib/core/config.dart`-dakı map-lar ilə `assets/` altındakı faktiki
// faylların uyğunluğunu yoxlayır. Widget qurmur, audio plagininə toxunmur —
// ona görə sürətlidir və `just_audio`-nun test mühitindəki tələlərinə düşmür.
//
// Yolları özü uydurmur: səhifələrin çağırdığı EYNİ funksiyaları çağırır
// (`AppConfig.findLetter`, `AppConfig.findAnimal`, `getFirstLetter`), yəni
// tətbiqin real istəyəcəyi yolları yoxlayır.
import 'dart:io';

import 'package:elifba/core/config.dart';
import 'package:elifba/core/utils.dart';
import 'package:flutter_test/flutter_test.dart';

// --- BİLİNƏN MƏZMUN BOŞLUQLARI ---
//
// Aşağıdakılar hazırda çatışmayan məzmundur. Testlər boşluğun DƏQİQ bu siyahı
// qədər olmasını tələb edir: fayl əlavə edəndə adı buradan da silin, yeni
// heyvan əlavə edib səsini unutsanız test uğursuz olacaq.

/// Səsli izahı (`<ad>_info_sound.mp3`) olmayan heyvanlar.
const Set<String> kAnimalsWithoutInfoAudio = {
  'Ağacdələn',
  'Bəbir',
  'Bülbül',
  'Çalağan',
  'Çaqqal',
  'Çəyirtkə',
  'Dovşan',
  'Dovdaq',
  'Dələ',
  'Dəvə',
  'İlbiz',
  'İnək',
  'İt',
  'Kərgədan',
  'Koala',
  'Köstəbək',
  'Qarışqayeyən',
  'Qırqovul',
  'Qorilla',
  'Qunduz',
  'Qurbağa',
  'Maral',
  'Panda',
  'Pişik',
  'Porsuq',
  'Piton',
  'Sarıköynək',
  'Suiti',
  'Timsah',
  'Turac',
};

/// Təsvir mətni (`animalInfo`) olmayan heyvanlar.
const Set<String> kAnimalsWithoutInfoText = {'Qarışqayeyən', 'Qırqovul'};

/// Heç bir heyvanı olmayan hərflər — siyahı səhifəsi boş açılır.
const Set<String> kLettersWithoutAnimals = {'Ğ', 'I', 'Ü'};

/// Hərf kartı şəkli (`<hərf>.webp`) olmayan hərflər.
///
/// `Ş` — fayl heç vaxt olmayıb.
/// `Ç` — `assets/images/ç/ç.png` şəkil deyil: 491 baytlıq Azure
/// "AuthenticationFailed" XML cavabıdır, ona görə WebP-ə çevrilməyib.
const Set<String> kLettersWithoutLetterImage = {'Ç', 'Ş'};


bool _exists(String assetPath) => File(assetPath).existsSync();

List<String> _allAnimals() =>
    AppConfig.animalsByLetter.values.expand((e) => e).toList();

/// Heyvanı detal səhifəsinin gördüyü kimi qurur: diakritik hərflərdə
/// normalizə olunmuş qovluğa baxır (Əqrəb -> `e/`).
AnimalInfo _asDetailPageSeesIt(String animal) {
  final info = AppConfig.findAnimal(getFirstLetter(animal), animal);
  expect(info, isNotNull, reason: '$animal üçün AnimalInfo qurula bilmədi');
  return info!;
}

void main() {
  setUpAll(() {
    // dart:io yolları `flutter test`-də layihə kökünə nisbətdir.
    expect(
      File('pubspec.yaml').existsSync(),
      isTrue,
      reason: 'testlər layihə kökündən işlədilməlidir',
    );
  });

  group('əlifba', () {
    test('32 unikal hərf var və hər birinin izahı var', () {
      expect(AppConfig.alphabet.length, 32);
      expect(AppConfig.alphabet.toSet().length, 32, reason: 'təkrar hərf var');
      for (final letter in AppConfig.alphabet) {
        expect(
          AppConfig.letterDescriptions[letter] ?? '',
          isNotEmpty,
          reason: '$letter hərfinin izahı yoxdur',
        );
      }
    });

    test('map açarları yalnız real hərflərdir', () {
      final known = AppConfig.alphabet.toSet();
      expect(
        AppConfig.letterDescriptions.keys.toSet().difference(known),
        isEmpty,
      );
      expect(AppConfig.animalsByLetter.keys.toSet().difference(known), isEmpty);
    });

    test('heyvanı olmayan hərflər yalnız bilinənlərdir', () {
      final empty =
          AppConfig.alphabet
              .where((l) => (AppConfig.animalsByLetter[l] ?? const []).isEmpty)
              .toSet();
      expect(empty, kLettersWithoutAnimals);
    });

    test('heyvan adları təkrarlanmır', () {
      final all = _allAnimals();
      expect(all.toSet().length, all.length, reason: 'təkrar heyvan adı var');
    });
  });

  group('hərf səsi', () {
    test('lettersWithAudio diskdəki fayllarla tam üst-üstə düşür', () {
      final onDisk = <String>{};
      for (final letter in AppConfig.alphabet) {
        if (_exists(AppConfig.letterAudioPath(letter))) {
          onDisk.add(letter.toUpperCase());
        }
      }
      expect(
        AppConfig.lettersWithAudio,
        onDisk,
        reason:
            'AppConfig.lettersWithAudio ilə assets/audios/ uyğun deyil — '
            'səs faylı əlavə/silinəndə siyahı da yenilənməlidir',
      );
    });

    test('hasLetterAudio yalnız faylı olan hərfə true qaytarır', () {
      for (final letter in AppConfig.alphabet) {
        expect(
          AppConfig.hasLetterAudio(letter),
          _exists(AppConfig.letterAudioPath(letter)),
          reason: '$letter üçün hasLetterAudio fayl vəziyyəti ilə uyğun deyil',
        );
      }
    });
  });

  group('heyvan məlumatları', () {
    test('hər heyvanın qida siyahısı var', () {
      for (final animal in _allAnimals()) {
        expect(
          AppConfig.animalFoods[animal] ?? const <String>[],
          isNotEmpty,
          reason: '$animal üçün qida siyahısı yoxdur',
        );
      }
    });

    test('təsvir mətni olmayanlar yalnız bilinənlərdir', () {
      final missing =
          _allAnimals()
              .where((a) => (AppConfig.animalInfo[a] ?? '').isEmpty)
              .toSet();
      expect(missing, kAnimalsWithoutInfoText);
    });

    test('map-larda sahibsiz açar yoxdur', () {
      final known = _allAnimals().toSet();
      final maps = <String, Iterable<String>>{
        'animalInfo': AppConfig.animalInfo.keys,
        'animalFoods': AppConfig.animalFoods.keys,
        'animalHasSound': AppConfig.animalHasSound.keys,
        'animalHasPuzzle': AppConfig.animalHasPuzzle.keys,
      };
      for (final entry in maps.entries) {
        expect(
          entry.value.toSet().difference(known),
          isEmpty,
          reason: '${entry.key} map-ında animalsByLetter-də olmayan açar var',
        );
      }
    });

    test('istinad edilən bütün qida şəkilləri mövcuddur', () {
      // `İlan` bir müddət `i` + U+0307 (birləşən nöqtə) ilə adlandırıldığı üçün
      // tapılmırdı; bu test həmin sinif səhvin qayıtmasının qarşısını alır.
      final missing = <String>{};
      for (final foods in AppConfig.animalFoods.values) {
        for (final food in foods) {
          final path = 'assets/foods/${AppConfig.normalizeFileName(food)}.webp';
          if (!_exists(path)) missing.add('$food -> $path');
        }
      }
      expect(missing, isEmpty, reason: 'çatışmayan qida şəkilləri: $missing');
    });
  });

  group('asset yolları — siyahı səhifəsinin gördüyü', () {
    test('hər heyvanın şəkli öz hərf qovluğunda var', () {
      final missing = <String>[];
      for (final letter in AppConfig.alphabet) {
        final animals =
            AppConfig.findLetter(letter)?.animals ?? const <AnimalInfo>[];
        for (final animal in animals) {
          if (!_exists(animal.imagePath)) {
            missing.add('$letter/${animal.name} -> ${animal.imagePath}');
          }
        }
      }
      expect(missing, isEmpty, reason: 'çatışmayan heyvan şəkilləri: $missing');
    });
  });

  group('asset yolları — detal səhifəsinin gördüyü', () {
    test('şəkil normalizə olunmuş qovluqda da var (diakritik güzgüləmə)', () {
      final missing = <String>[];
      for (final animal in _allAnimals()) {
        final path = _asDetailPageSeesIt(animal).imagePath;
        if (!_exists(path)) missing.add('$animal -> $path');
      }
      expect(
        missing,
        isEmpty,
        reason:
            'detal səhifəsi normalizə olunmuş qovluğa baxır (Əqrəb -> e/); '
            'diakritik hərflə başlayan heyvanın şəkli HƏR İKİ qovluqda '
            'olmalıdır. Çatışmayan: $missing',
      );
    });

    test('hasPuzzle=true olan hər heyvanın pazl şəkli var', () {
      final missing = <String>[];
      for (final animal in _allAnimals()) {
        if (AppConfig.animalHasPuzzle[animal] != true) continue;
        final puzzle = _asDetailPageSeesIt(
          animal,
        ).imagePath.replaceFirst('.webp', '_puzzle.jpg');
        expect(
          puzzle.endsWith('_puzzle.jpg'),
          isTrue,
          reason: '$animal üçün pazl yolu qurulmadı: $puzzle',
        );
        if (!_exists(puzzle)) missing.add('$animal -> $puzzle');
      }
      expect(missing, isEmpty, reason: 'çatışmayan pazl şəkilləri: $missing');
    });

    test('hasSound=true olan hər heyvanın səs faylı var', () {
      final missing = <String>[];
      for (final animal in _allAnimals()) {
        if (AppConfig.animalHasSound[animal] != true) continue;
        final path =
            'assets/audios/${getFirstLetter(animal)}/'
            '${AppConfig.normalizeFileName(animal)}_sound.mp3';
        if (!_exists(path)) missing.add('$animal -> $path');
      }
      expect(missing, isEmpty, reason: 'çatışmayan heyvan səsləri: $missing');
    });

    test('səs faylı olan heyvanın hasSound bayrağı da true-dur', () {
      final wrong = <String>[];
      for (final animal in _allAnimals()) {
        final path =
            'assets/audios/${getFirstLetter(animal)}/'
            '${AppConfig.normalizeFileName(animal)}_sound.mp3';
        if (_exists(path) && AppConfig.animalHasSound[animal] != true) {
          wrong.add(animal);
        }
      }
      expect(
        wrong,
        isEmpty,
        reason: 'səs faylı var, amma hasSound=false — düymə görünmür: $wrong',
      );
    });

    test('səsli izahı olmayanlar yalnız bilinənlərdir', () {
      final missing = <String>{};
      for (final animal in _allAnimals()) {
        if (!_exists(_asDetailPageSeesIt(animal).audioPath)) {
          missing.add(animal);
        }
      }
      expect(
        missing,
        kAnimalsWithoutInfoAudio,
        reason:
            'səsli izah boşluğu dəyişib. Yeni səs əlavə etmisinizsə adı '
            'kAnimalsWithoutInfoAudio siyahısından silin.',
      );
    });
  });

  group('hərf kartı şəkilləri', () {
    test('şəkli olmayan hərflər yalnız bilinənlərdir', () {
      final missing = <String>{};
      for (final letter in AppConfig.alphabet) {
        if (!_exists(AppConfig.findLetter(letter)!.imagePath)) {
          missing.add(letter);
        }
      }
      expect(missing, kLettersWithoutLetterImage);
    });
  });
}
