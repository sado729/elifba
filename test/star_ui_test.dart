// Ulduz UI-sinin testləri.
//
// `progress_test.dart` modeli (ulduz riyaziyyatı, tapşırıq planı, saxlanma)
// yoxlayır; bu fayl isə həmin modelin EKRANDA göründüyünü yoxlayır: kitabdaki
// hərf ulduzları, ümumi sayğac, hərf tərəqqisi və heyvan kartındaki nişan.
//
// Qeydlər:
// * `ProgressStore.instance` singleton-dur və `main()`-də yüklənir. Testlər onu
//   yazmır — hər testdən sonra `reset()` çağırılır ki, testlər bir-birinə
//   sızmasın (`_prefs` null olduğu üçün diskə heç nə yazılmır).
// * Bu səhifələr `AudioPlayer` qurur, ona görə CLAUDE.md gotcha 11-ə uyğun
//   olaraq heç bir just_audio çağırışı `await` edilmir və `tester.runAsync`
//   istifadə olunmur.
// * Heyvan qridi lazy-dir: 800x600 test səthində yalnız ilk iki xana qurulur
//   (gotcha 11), ona görə testlər yalnız qurulan xanalara istinad edir.

import 'package:elifba/core/config.dart';
import 'package:elifba/core/progress.dart';
import 'package:elifba/pages/alphabet_page.dart';
import 'package:elifba/pages/animal_detail_page.dart';
import 'package:elifba/pages/animal_list_page.dart';
import 'package:elifba/widgets/star_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dolu ulduzların sayı: `StarRow` dolu ulduzu `Icons.star_rounded`,
/// boşu `Icons.star_outline_rounded` ilə çəkir.
int _filledStars(WidgetTester tester, Finder row) => find
    .descendant(of: row, matching: find.byIcon(Icons.star_rounded))
    .evaluate()
    .length;

int _emptyStars(WidgetTester tester, Finder row) => find
    .descendant(of: row, matching: find.byIcon(Icons.star_outline_rounded))
    .evaluate()
    .length;

/// `A` hərfinin bütün bölmələrini tamamlayır (heyvanlar + hərfi yazmaq).
void _completeLetter(ProgressStore store, String letter) {
  for (final animal in AppConfig.animalsByLetter[letter] ?? const <String>[]) {
    for (final task in store.tasksOf(animal)) {
      store.markDone(animal, task);
    }
    for (final food in AppConfig.animalFoods[animal] ?? const <String>[]) {
      store.markFoodFed(animal, food);
    }
  }
  store.markWritten(letter);
}

void main() {
  final store = ProgressStore.instance;

  tearDown(() async {
    await store.reset();
  });

  group('StarRow', () {
    testWidgets('dolu və boş ulduzları düzgün sayda çəkir', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: StarRow(filled: 2))),
        ),
      );

      final row = find.byType(StarRow);
      expect(_filledStars(tester, row), 2);
      expect(_emptyStars(tester, row), 1);
    });

    testWidgets('həddən böyük `filled` qiyməti kəsilir, daşma olmur', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: StarRow(filled: 99, total: 3))),
        ),
      );

      expect(_filledStars(tester, find.byType(StarRow)), 3);
      expect(_emptyStars(tester, find.byType(StarRow)), 0);
      expect(tester.takeException(), isNull);
    });
  });

  group('əlifba kitabı', () {
    testWidgets('hər hərf xanasının ulduz sırası var və ilk açılışda boşdur', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: AlphabetPage()));
      await tester.pump();

      // Kitabın ilk səhifəsində iki hərf var (A və B) — hər birinin bir sırası.
      expect(find.byType(StarRow), findsNWidgets(2));
      for (final row in find.byType(StarRow).evaluate()) {
        expect((row.widget as StarRow).filled, 0);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('ümumi sayğac 0/96 ilə başlayır', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AlphabetPage()));
      await tester.pump();

      // Cızma tapşırığı hər 32 hərfə məzmun verir: 32 x 3 = 96.
      expect(store.maxTotalStars, 96);
      expect(find.text('0/96'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('bölmə tamamlananda hərfin ulduzu və sayğac artır', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: AlphabetPage()));
      await tester.pump();

      // Səhifə store-u dinləyir: yaddaşdaki qeyd dərhal ekrana çıxmalıdır.
      store.markWritten('A');
      await tester.pump();

      expect(find.text('1/96'), findsOneWidget);
      final rows = find.byType(StarRow).evaluate().toList();
      expect((rows.first.widget as StarRow).filled, 1, reason: 'A hərfi');
      expect((rows[1].widget as StarRow).filled, 0, reason: 'B hərfi');
      expect(tester.takeException(), isNull);
    });

    testWidgets('hərf tam bitəndə 3 ulduz və qızılı çərçivə görünür', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: AlphabetPage()));
      await tester.pump();

      _completeLetter(store, 'A');
      await tester.pump();

      expect(store.starsOf('A'), 3);
      final rows = find.byType(StarRow).evaluate().toList();
      expect((rows.first.widget as StarRow).filled, 3);

      // Qızılı çərçivə yalnız tam bitmiş hərfdə olur, ona görə kitab
      // səhifəsində bir dənə görünməlidir (A, B deyil).
      final gold =
          find
              .byWidgetPredicate((w) {
                if (w is! Container) return false;
                final d = w.decoration;
                return d is BoxDecoration && d.border?.top.color == kStarGold;
              })
              .evaluate()
              .length;
      expect(gold, 1, reason: 'yalnız A hərfi qızılı çərçivə almalıdır');
      expect(tester.takeException(), isNull);
    });
  });

  group('hərf səhifəsi', () {
    testWidgets('tərəqqi zolağı "n/m" göstərir və heyvanlar başlığındadır', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: AnimalListPage(letter: 'A')),
      );
      await tester.pump();

      final total = store.letterTotal('A');
      expect(total, greaterThan(0));
      expect(find.text('0/$total'), findsOneWidget);

      // Zolaq "Heyvanlar" başlığı ilə EYNİ sətirdədir — ayrı şaquli blok kimi
      // qoyulanda qrid sıxılır (CLAUDE.md gotcha 13).
      final headingRow =
          find
              .ancestor(
                of: find.text('Heyvanlar'),
                matching: find.byType(Row),
              )
              .first;
      expect(
        find.descendant(of: headingRow, matching: find.text('0/$total')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('hərf tam bitəndə zolaq "Tamam!" yazır', (tester) async {
      _completeLetter(store, 'A');

      await tester.pumpWidget(
        const MaterialApp(home: AnimalListPage(letter: 'A')),
      );
      await tester.pump();

      expect(find.text('Tamam!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('qrid sıxılmır: tərəqqi zolağı xana qurulmasını pozmur', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: AnimalListPage(letter: 'A')),
      );
      await tester.pump();

      // Gotcha 13: zolaq şaquli yer tutsa `Expanded` sıfıra sıxılır və lazy
      // qrid HEÇ bir xana qurmur. 800x600 səthində qrid 357 px olmalıdır.
      final grid = tester.getSize(find.byType(GridView));
      expect(grid.height, greaterThan(300), reason: 'qrid sıxılmamalıdır');
      expect(
        find.descendant(
          of: find.byType(GridView),
          matching: find.text(AppConfig.animalsByLetter['A']!.first),
        ),
        findsOneWidget,
        reason: 'ilk heyvan xanası qurulmalıdır',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('heyvan kartında ulduz nişanı var və qeyd olunanda artır', (
      tester,
    ) async {
      const letter = 'A';
      final animal = AppConfig.animalsByLetter[letter]!.first;

      await tester.pumpWidget(
        const MaterialApp(home: AnimalListPage(letter: letter)),
      );
      await tester.pump();

      final cardStars = find.descendant(
        of: find
            .ancestor(of: find.text(animal), matching: find.byType(Column))
            .first,
        matching: find.byType(StarRow),
      );
      expect(cardStars, findsOneWidget);
      expect(tester.widget<StarRow>(cardStars).filled, 0);

      store.markDone(animal, Activity.info);
      await tester.pump();

      expect(tester.widget<StarRow>(cardStars).filled, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('yazı kartının ulduzu hərf yazılanda dolur', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AnimalListPage(letter: 'A')),
      );
      await tester.pump();

      // Yazı kartı qridin ilk xanasıdır və mətnsizdir: ulduzu ayrıca
      // `Icons.star_outline_rounded` ikonudur (StarRow deyil, tək tapşırıq).
      final outlineInGrid = find.descendant(
        of: find.byType(GridView),
        matching: find.byIcon(Icons.star_outline_rounded),
      );
      expect(outlineInGrid, findsWidgets);

      store.markWritten('A');
      await tester.pump();

      expect(store.isWritten('A'), isTrue);
      expect(
        find.descendant(
          of: find.byType(GridView),
          matching: find.byIcon(Icons.star_rounded),
        ),
        findsWidgets,
        reason: 'hərf yazılandan sonra dolu ulduz görünməlidir',
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('heyvan detalı', () {
    testWidgets('bölmələr bitəndə "Tam ulduz!" təbriki çıxır', (tester) async {
      const letter = 'A';
      final animal = AppConfig.animalsByLetter[letter]!.first;
      final testStore = ProgressStore.forTesting();
      addTearDown(testStore.dispose);

      // `info`-dan başqa hər şey hazırdır: səhifə açılanda `info` qeyd olunur
      // və heyvan həmin anda tamamlanır.
      for (final task in testStore.tasksOf(animal)) {
        if (task == Activity.info) continue;
        testStore.markDone(animal, task);
      }
      for (final food in AppConfig.animalFoods[animal]!) {
        testStore.markFoodFed(animal, food);
      }
      expect(testStore.isDone(animal, Activity.info), isFalse);

      await tester.pumpWidget(
        MaterialApp(
          home: AnimalDetailPage(
            animal: animal,
            animals: [animal],
            currentIndex: 0,
            store: testStore,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Tam ulduz!'), findsOneWidget);
      expect(find.text('$animal haqqında hər şeyi öyrəndin!'), findsOneWidget);
      expect(testStore.animalStars(animal), 3);
    });

    testWidgets('artıq bitmiş heyvanı açanda təbrik TƏKRARLANMIR', (
      tester,
    ) async {
      const letter = 'A';
      final animal = AppConfig.animalsByLetter[letter]!.first;
      final testStore = ProgressStore.forTesting();
      addTearDown(testStore.dispose);

      // Hər şey əvvəlki baxışda bitib.
      for (final task in testStore.tasksOf(animal)) {
        testStore.markDone(animal, task);
      }
      for (final food in AppConfig.animalFoods[animal]!) {
        testStore.markFoodFed(animal, food);
      }

      await tester.pumpWidget(
        MaterialApp(
          home: AnimalDetailPage(
            animal: animal,
            animals: [animal],
            currentIndex: 0,
            store: testStore,
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text('Tam ulduz!'),
        findsNothing,
        reason: 'bitmiş heyvanı hər açanda təbrik çıxmamalıdır',
      );
    });

    testWidgets('hero küncündəki nişan bölmə sayını göstərir', (tester) async {
      const letter = 'A';
      final animal = AppConfig.animalsByLetter[letter]!.first;
      final testStore = ProgressStore.forTesting();
      addTearDown(testStore.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: AnimalDetailPage(
            animal: animal,
            animals: [animal],
            currentIndex: 0,
            store: testStore,
          ),
        ),
      );
      await tester.pump();

      // Səhifə açılışı `info` bölməsini bağlayır: 4 bölmədən 1-i.
      final total = testStore.animalTotal(animal);
      expect(find.text('1/$total'), findsOneWidget);
      expect(testStore.isDone(animal, Activity.info), isTrue);
    });
  });

  group('progresin sıfırlanması', () {
    testWidgets('ℹ️ dialoqundan iki addımla sıfırlanır və sayğac 0-a düşür', (
      tester,
    ) async {
      _completeLetter(store, 'A');

      await tester.pumpWidget(const MaterialApp(home: AlphabetPage()));
      await tester.pump();
      expect(find.text('3/96'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pump();
      await tester.tap(find.text('Progresi sıfırla'));
      await tester.pump();

      // Birinci addım yalnız xəbərdarlıq göstərir — hələ heç nə silinmir.
      expect(find.text('Bütün ulduzlar silinsin?'), findsOneWidget);
      expect(store.totalStars, 3);

      // "Ləğv et" progresi saxlayır.
      await tester.tap(find.text('Ləğv et'));
      await tester.pump();
      expect(store.totalStars, 3);

      // İkinci cəhd, bu dəfə təsdiqlə.
      await tester.tap(find.text('Progresi sıfırla'));
      await tester.pump();
      await tester.tap(find.text('Bəli, sil'));
      await tester.pumpAndSettle();

      expect(store.totalStars, 0);
      expect(find.text('0/96'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
