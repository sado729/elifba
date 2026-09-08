import 'dart:convert';

import 'package:elifba/core/config.dart';
import 'package:elifba/core/progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProgressStore store;

  setUp(() {
    // Diskə yazmayan təmiz nüsxə: `load()` çağırılmadığı üçün `_prefs` null qalır.
    store = ProgressStore.forTesting();
  });

  tearDown(() => store.dispose());

  group('ulduz düsturu', () {
    test('heç nə edilməyibsə 0 ulduz', () {
      expect(ProgressStore.starsFor(0, 4), 0);
      expect(ProgressStore.starsFor(0, 40), 0);
    });

    test('məzmunu olmayan hərf 0 ulduz alır, 3 deyil', () {
      expect(ProgressStore.starsFor(0, 0), 0);
      // Əvvəl burada Ğ, I, Ü hərflərinin `letterTotal == 0` olması yoxlanılırdı.
      // Cızma tapşırığı əlavə olunandan sonra HƏR hərfin ən azı 1 tapşırığı var,
      // ona görə "məzmunsuz hərf" yalnız əlifbada olmayan açardır.
      expect(store.letterTotal('W'), 0);
      expect(store.starsOf('W'), 0);
      expect(store.hasContent('W'), isFalse);
    });

    test('heyvanı olmayan hərfin də cızma tapşırığı var', () {
      // Ğ, I, Ü hərflərinin heyvanı yoxdur, amma yazıla bilirlər.
      for (final letter in ['Ğ', 'I', 'Ü']) {
        expect(
          AppConfig.animalsByLetter[letter] ?? const [],
          isEmpty,
          reason: letter,
        );
        expect(store.letterTotal(letter), 1, reason: letter);
        expect(store.hasContent(letter), isTrue, reason: letter);
        expect(store.starsOf(letter), 0, reason: letter);
      }
    });

    test('ilk tamamlanan bölmə həmişə ən azı 1 ulduz verir', () {
      expect(ProgressStore.starsFor(1, 4), 1);
      expect(ProgressStore.starsFor(1, 40), 1);
    });

    test('2/3 həddi 2-ci ulduzu açır', () {
      expect(ProgressStore.starsFor(2, 4), 1); // 0.50
      expect(ProgressStore.starsFor(3, 4), 2); // 0.75
      expect(ProgressStore.starsFor(2, 3), 2); // tam 2/3
      expect(ProgressStore.starsFor(39, 40), 2); // 0.975 — hələ tam deyil
    });

    test('yalnız hər şey bitəndə tam ulduz', () {
      expect(ProgressStore.starsFor(4, 4), 3);
      expect(ProgressStore.starsFor(40, 40), 3);
      expect(ProgressStore.maxStarsPerLetter, 3);
    });

    test('düstur monotondur — bölmə tamamlamaq ulduzu azaltmır', () {
      for (final total in [1, 2, 3, 4, 5, 7, 40]) {
        var previous = 0;
        for (var done = 0; done <= total; done++) {
          final stars = ProgressStore.starsFor(done, total);
          expect(
            stars,
            greaterThanOrEqualTo(previous),
            reason: 'done=$done total=$total',
          );
          previous = stars;
        }
      }
    });
  });

  group('tapşırıq planı', () {
    test('səsli bölmələr sayılmır', () {
      // 'İnək'-in heyvan səsi var, 'Ağacdələn'-in info audiosu yoxdur —
      // ikisinin də tapşırıq siyahısı yalnız səssiz bölmələrdən ibarətdir.
      for (final animal in ['İnək', 'Ağacdələn']) {
        expect(
          store.tasksOf(animal),
          unorderedEquals([
            Activity.info,
            Activity.foods,
            Activity.wordPuzzle,
            Activity.tilePuzzle,
          ]),
          reason: animal,
        );
      }
    });

    test('hər heyvanın tapşırığı var və hamısı əldə ediləndir', () {
      for (final letter in AppConfig.alphabet) {
        for (final animal in AppConfig.animalsByLetter[letter] ?? const []) {
          expect(
            store.animalTotal(animal),
            greaterThan(0),
            reason: '$letter / $animal',
          );
        }
      }
    });

    test('pazlı olmayan heyvanda tilePuzzle tapşırığı yoxdur', () {
      final withoutPuzzle = AppConfig.animalsByLetter.values
          .expand((names) => names)
          .where((name) => !(AppConfig.animalHasPuzzle[name] ?? false));
      for (final animal in withoutPuzzle) {
        expect(store.tasksOf(animal), isNot(contains(Activity.tilePuzzle)));
      }
    });

    test('hərfin cəmi heyvanlarının cəmi + cızma tapşırığıdır', () {
      for (final letter in AppConfig.alphabet) {
        final animals = AppConfig.animalsByLetter[letter] ?? const <String>[];
        final expected = animals.fold<int>(
          0,
          (sum, animal) => sum + store.animalTotal(animal),
        );
        // +1 — hərfi cızmaq. Bütün 32 hərfin ştrix datası var, ona görə istisna yoxdur.
        expect(store.letterTotal(letter), expected + 1, reason: letter);
      }
    });

    test('kiçik hərflə sorğu da işləyir', () {
      expect(store.letterTotal('a'), store.letterTotal('A'));
      expect(store.starsOf('a'), store.starsOf('A'));
    });
  });

  group('markDone', () {
    test('idempotentdir və dinləyiciyə yalnız dəyişəndə xəbər verir', () {
      var notifications = 0;
      store.addListener(() => notifications++);

      store.markDone('At', Activity.info);
      expect(store.isDone('At', Activity.info), isTrue);
      expect(store.animalDone('At'), 1);
      expect(notifications, 1);

      store.markDone('At', Activity.info);
      expect(store.animalDone('At'), 1);
      expect(notifications, 1, reason: 'təkrar qeyd bildiriş yaratmamalıdır');
    });

    test('plana daxil olmayan bölmə nəzərə alınmır', () {
      final animal = AppConfig.animalsByLetter.values
          .expand((names) => names)
          .firstWhere(
            (name) => !(AppConfig.animalHasPuzzle[name] ?? false),
            orElse: () => '',
          );
      if (animal.isEmpty) return; // hazırda bütün heyvanların pazlı var
      store.markDone(animal, Activity.tilePuzzle);
      expect(store.animalDone(animal), 0);
    });

    test('naməlum heyvan səssizcə buraxılır', () {
      store.markDone('Dinozavr', Activity.info);
      expect(store.animalDone('Dinozavr'), 0);
      expect(store.totalStars, 0);
    });

    test('bütün bölmələr bitəndə heyvan tam ulduz alır', () {
      for (final task in store.tasksOf('At')) {
        if (task == Activity.foods) continue; // qidalar ayrıca yoxlanılır
        store.markDone('At', task);
      }
      for (final food in AppConfig.animalFoods['At']!) {
        store.markFoodFed('At', food);
      }
      expect(store.animalDone('At'), store.animalTotal('At'));
      expect(store.animalStars('At'), 3);
    });
  });

  group('markFoodFed', () {
    test('bütün qidalar verilənə qədər foods bölməsi bağlanmır', () {
      final foods = AppConfig.animalFoods['At']!;
      expect(foods.length, greaterThan(1));

      for (final food in foods.take(foods.length - 1)) {
        store.markFoodFed('At', food);
        expect(store.isDone('At', Activity.foods), isFalse);
      }
      store.markFoodFed('At', foods.last);
      expect(store.isDone('At', Activity.foods), isTrue);
      expect(store.fedFoods('At').length, foods.length);
    });

    test('təkrar verilən qida iki dəfə sayılmır', () {
      final food = AppConfig.animalFoods['At']!.first;
      store.markFoodFed('At', food);
      store.markFoodFed('At', food);
      expect(store.fedFoods('At'), {food});
    });

    test('heyvanın siyahısında olmayan qida nəzərə alınmır', () {
      store.markFoodFed('At', 'Pizza');
      expect(store.fedFoods('At'), isEmpty);
    });

    test('qaytarılan dəst dəyişdirilə bilməz', () {
      store.markFoodFed('At', AppConfig.animalFoods['At']!.first);
      expect(() => store.fedFoods('At').add('Pizza'), throwsUnsupportedError);
    });
  });

  group('hərf təbriki', () {
    test('yalnız 100%-də və yalnız bir dəfə verilir', () {
      // H hərfinin tək heyvanı var — ən qısa tam yol.
      const letter = 'H';
      final animals = AppConfig.animalsByLetter[letter]!;
      expect(animals.length, 1);
      final animal = animals.single;

      expect(store.takeLetterCelebration(letter), isFalse);
      store.markDone(animal, Activity.info);
      expect(store.takeLetterCelebration(letter), isFalse);

      for (final task in store.tasksOf(animal)) {
        store.markDone(animal, task);
      }
      for (final food in AppConfig.animalFoods[animal]!) {
        store.markFoodFed(animal, food);
      }

      // Heyvanın hər şeyi bitsə də hərf hələ 100% deyil: cızma tapşırığı qalır.
      expect(store.takeLetterCelebration(letter), isFalse);
      store.markWritten(letter);

      expect(store.letterDone(letter), store.letterTotal(letter));
      expect(store.starsOf(letter), 3);
      expect(store.takeLetterCelebration(letter), isTrue);
      expect(
        store.takeLetterCelebration(letter),
        isFalse,
        reason: 'təbrik təkrarlanmamalıdır',
      );
    });

    test('heyvanı olmayan hərf yalnız cızıldıqdan sonra təbrik verir', () {
      // Əvvəl bu test "Ğ heç vaxt təbrik yaratmır" idi; artıq Ğ-nin cızma
      // tapşırığı var, deməli yazılanda tam olur və təbriki bir dəfə verir.
      expect(store.takeLetterCelebration('Ğ'), isFalse);
      store.markWritten('Ğ');
      expect(store.takeLetterCelebration('Ğ'), isTrue);
      expect(store.takeLetterCelebration('Ğ'), isFalse);
    });

    test('əlifbada olmayan hərf təbrik yaratmır', () {
      expect(store.takeLetterCelebration('W'), isFalse);
    });
  });

  group('ümumi sayğac', () {
    test('maksimum ulduz = məzmunlu hərf sayı x 3', () {
      // Cızma tapşırığından sonra 32 hərfin hamısı məzmunludur (əvvəl 29 idi:
      // Ğ, I, Ü kənarda qalırdı).
      final withContent = AppConfig.alphabet.where(store.hasContent).length;
      expect(withContent, 32);
      expect(store.maxTotalStars, 32 * 3);
      expect(store.totalStars, 0);
    });

    test('bir bölmə tamamlamaq ümumi sayğacı artırır', () {
      store.markDone('At', Activity.info);
      expect(store.totalStars, 1);
    });
  });

  group('saxlanma', () {
    test('JSON gedər-gələr', () {
      store.markDone('At', Activity.info);
      store.markDone('At', Activity.wordPuzzle);
      store.markFoodFed('At', AppConfig.animalFoods['At']!.first);
      final encoded = store.encodeState();

      final restored = ProgressStore.forTesting()..restoreFromJson(encoded);
      addTearDown(restored.dispose);

      expect(restored.isDone('At', Activity.info), isTrue);
      expect(restored.isDone('At', Activity.wordPuzzle), isTrue);
      expect(restored.isDone('At', Activity.tilePuzzle), isFalse);
      expect(restored.fedFoods('At'), store.fedFoods('At'));
      expect(restored.totalStars, store.totalStars);
    });

    test('təbrik verilmiş hərflər də saxlanılır', () {
      const letter = 'H';
      final animal = AppConfig.animalsByLetter[letter]!.single;
      for (final task in store.tasksOf(animal)) {
        store.markDone(animal, task);
      }
      store.markWritten(letter); // hərf 100% olmadan təbrik verilmir
      expect(store.takeLetterCelebration(letter), isTrue);

      final restored =
          ProgressStore.forTesting()..restoreFromJson(store.encodeState());
      addTearDown(restored.dispose);
      expect(
        restored.takeLetterCelebration(letter),
        isFalse,
        reason: 'təbrik saxlanmalı və təkrarlanmamalıdır',
      );
    });

    test('yazılmış hərflər saxlanılır və deterministik sıralanır', () {
      store.markWritten('C');
      store.markWritten('A');
      store.markWritten('B');
      final encoded = store.encodeState();
      expect((jsonDecode(encoded) as Map)['w'], ['A', 'B', 'C']);

      final restored = ProgressStore.forTesting()..restoreFromJson(encoded);
      addTearDown(restored.dispose);
      expect(restored.writtenLetterCount, 3);
      for (final letter in ['A', 'B', 'C']) {
        expect(restored.isWritten(letter), isTrue, reason: letter);
      }
      expect(restored.totalStars, store.totalStars);
    });

    test('köhnə qeyddə "w" açarı yoxdursa yazma dəsti boş olur', () {
      // Geriyə uyğunluq: cızma xüsusiyyətindən əvvəl yazılmış JSON.
      store.restoreFromJson(
        jsonEncode({
          'v': 1,
          'a': {
            'At': {
              'd': ['info'],
            },
          },
        }),
      );
      expect(store.animalDone('At'), 1);
      expect(store.writtenLetterCount, 0);
      expect(store.isWritten('A'), isFalse);
    });

    test('bərpada əlifbada olmayan hərf qəbul edilmir', () {
      store.restoreFromJson(
        jsonEncode({
          'v': 1,
          'a': const {},
          'w': ['A', 'W', 42, 'ğ'],
        }),
      );
      expect(store.isWritten('A'), isTrue);
      expect(
        store.isWritten('Ğ'),
        isTrue,
        reason: 'kiçik hərf normallaşdırılır',
      );
      expect(store.isWritten('W'), isFalse);
      expect(store.writtenLetterCount, 2);
    });

    test('boş progres boş obyekt kimi saxlanılır', () {
      final decoded = jsonDecode(store.encodeState()) as Map;
      expect(decoded['v'], 1);
      expect(decoded['a'], isEmpty);
      expect(decoded.containsKey('c'), isFalse);
      expect(decoded.containsKey('w'), isFalse);
    });

    test('naməlum bölmə, heyvan və qida səssizcə buraxılır', () {
      store.restoreFromJson(
        jsonEncode({
          'v': 1,
          'a': {
            'At': {
              'd': ['info', 'youtube', 'sound'],
              'f': ['Pizza'],
            },
            'Dinozavr': {
              'd': ['info'],
            },
          },
          'gələcək_açar': 42,
        }),
      );
      expect(store.animalDone('At'), 1);
      expect(store.isDone('At', Activity.info), isTrue);
      expect(store.fedFoods('At'), isEmpty);
      expect(store.animalDone('Dinozavr'), 0);
    });

    test('korlanmış və ya boş məlumat çökmə yaratmır', () {
      for (final raw in [null, '', 'salam', '[]', '{"a":5}']) {
        expect(
          () => store.restoreFromJson(raw),
          returnsNormally,
          reason: '$raw',
        );
        expect(store.totalStars, 0, reason: '$raw');
      }
    });

    test('bərpa əvvəlki vəziyyəti tam əvəz edir', () {
      store.markDone('At', Activity.info);
      store.markWritten('A');
      store.restoreFromJson(null);
      expect(store.animalDone('At'), 0);
      expect(store.writtenLetterCount, 0);
    });
  });

  group('reset', () {
    test('hər şeyi silir', () async {
      store.markDone('At', Activity.info);
      store.markFoodFed('At', AppConfig.animalFoods['At']!.first);
      store.markWritten('A');
      expect(store.totalStars, greaterThan(0));

      await store.reset();

      expect(store.totalStars, 0);
      expect(store.animalDone('At'), 0);
      expect(store.fedFoods('At'), isEmpty);
      expect(store.isWritten('A'), isFalse);
      expect(store.writtenLetterCount, 0);
    });
  });

  group('hərf yazma', () {
    test('idempotentdir və dinləyiciyə yalnız dəyişəndə xəbər verir', () {
      var notifications = 0;
      store.addListener(() => notifications++);

      store.markWritten('A');
      expect(store.isWritten('A'), isTrue);
      expect(store.writtenLetterCount, 1);
      expect(notifications, 1);

      store.markWritten('A');
      expect(store.writtenLetterCount, 1);
      expect(notifications, 1, reason: 'təkrar qeyd bildiriş yaratmamalıdır');
    });

    test('kiçik hərflə sorğu və qeyd də işləyir', () {
      store.markWritten('b');
      expect(store.isWritten('B'), isTrue);
      expect(store.isWritten('b'), isTrue);
      expect(store.writtenLetterCount, 1);
    });

    test('naməlum hərf səssizcə buraxılır', () {
      store.markWritten('W');
      store.markWritten('');
      expect(store.isWritten('W'), isFalse);
      expect(store.writtenLetterCount, 0);
      expect(store.totalStars, 0);
    });

    test('yazma hərfin tamamlanmış bölmə sayını artırır', () {
      const letter = 'A';
      final before = store.letterDone(letter);
      store.markWritten(letter);
      expect(store.letterDone(letter), before + 1);
      // A hərfinin çoxlu heyvanı var — tək yazma yalnız 1-ci ulduzu verir.
      expect(store.starsOf(letter), 1);
    });

    test('heyvanı olmayan hərf yalnız yazma ilə tam ulduz alır', () {
      const letter = 'Ğ';
      expect(store.starsOf(letter), 0);
      store.markWritten(letter);
      expect(store.letterDone(letter), store.letterTotal(letter));
      expect(store.starsOf(letter), 3);
    });
  });

  group('nöqtəli/nöqtəsiz I', () {
    // CLAUDE.md → "Gotchas" 2-ci bənd: Dart-ın `toUpperCase()`-i 'i' → 'I'
    // verir, Azərbaycan dilində isə 'i' → 'İ', 'ı' → 'I'-dır. Aşağıdakı testlər
    // açar cədvəlinin bu iki hərfi qarışdırmadığını qoruyur.

    test('markWritten("i") İ hərfini yazılmış edir, I-nı yox', () {
      store.markWritten('i');
      expect(store.isWritten('İ'), isTrue);
      expect(store.isWritten('I'), isFalse);
      expect(store.writtenLetterCount, 1);
    });

    test('markWritten("ı") I hərfini yazılmış edir, İ-ni yox', () {
      store.markWritten('ı');
      expect(store.isWritten('I'), isTrue);
      expect(store.isWritten('İ'), isFalse);
      expect(store.writtenLetterCount, 1);
    });

    test('isWritten kiçik formanı öz böyük hərfinə yönləndirir', () {
      store.markWritten('İ');
      expect(store.isWritten('i'), isTrue);
      expect(store.isWritten('ı'), isFalse);

      store.markWritten('I');
      expect(store.isWritten('ı'), isTrue);
      expect(store.writtenLetterCount, 2);
    });

    test('letterTotal "i"/"ı" düzgün hərfin cəmini verir', () {
      // I hərfinin heyvanı yoxdur (yalnız cızma = 1), İ hərfinin isə var.
      expect(store.letterTotal('I'), 1);
      expect(store.letterTotal('ı'), store.letterTotal('I'));
      expect(store.letterTotal('İ'), greaterThan(1));
      expect(store.letterTotal('i'), store.letterTotal('İ'));
    });

    test('yazma ulduzu yalnız düzgün hərfə yazılır', () {
      store.markWritten('i');
      // İ-nin çoxlu heyvanı var: tək cızma 1-ci ulduzu verir.
      expect(store.letterDone('İ'), 1);
      expect(store.starsOf('İ'), 1);
      expect(store.starsOf('i'), store.starsOf('İ'));
      // I hərfi toxunulmamış qalmalıdır — əvvəl burada 0 əvəzinə 3 alınırdı.
      expect(store.letterDone('I'), 0);
      expect(store.starsOf('I'), 0);
      expect(store.starsOf('ı'), 0);
    });

    test('bərpada da "i" İ-yə, "ı" I-ya düşür', () {
      store.restoreFromJson(
        jsonEncode({
          'v': 1,
          'a': const {},
          'w': ['i'],
        }),
      );
      expect(store.isWritten('İ'), isTrue);
      expect(store.isWritten('I'), isFalse);

      store.restoreFromJson(
        jsonEncode({
          'v': 1,
          'a': const {},
          'w': ['ı'],
        }),
      );
      expect(store.isWritten('I'), isTrue);
      expect(store.isWritten('İ'), isFalse);
    });
  });

  group('diakritik hərflərin kiçik forması', () {
    test('ə, ç, ş, ğ, ö, ü düzgün böyük hərfə düşür', () {
      const pairs = {
        'ə': 'Ə',
        'ç': 'Ç',
        'ş': 'Ş',
        'ğ': 'Ğ',
        'ö': 'Ö',
        'ü': 'Ü',
      };
      pairs.forEach((lower, upper) {
        expect(AppConfig.alphabet, contains(upper), reason: upper);
        expect(
          store.letterTotal(lower),
          store.letterTotal(upper),
          reason: lower,
        );
        expect(store.letterTotal(lower), greaterThan(0), reason: lower);

        store.markWritten(lower);
        expect(store.isWritten(upper), isTrue, reason: lower);
        expect(store.isWritten(lower), isTrue, reason: lower);
      });
      expect(store.writtenLetterCount, pairs.length);
    });
  });
}
