// Heyvan səhifəsinin yeni quruluşunun testləri: radio tablar, yapışqan tab
// zolağı, söz tapmaca kafellərinin ölçüsü və pazl ipucunun qorunması
// (CLAUDE.md gotcha 14).
//
// Səhifə `GatedPlayer` qurur: heç bir just_audio çağırışı `await` edilmir və
// `tester.runAsync` işlədilmir (gotcha 11). Pazl şəklinin dekodu saxta
// async-də heç vaxt bitmir — xanalar boş qutu kimi çəkilir, məntiq isə
// eynidir.

import 'package:elifba/core/config.dart';
import 'package:elifba/core/progress.dart';
import 'package:elifba/core/settings.dart';
import 'package:elifba/core/utils.dart';
import 'package:elifba/pages/animal_detail_page.dart';
import 'package:elifba/pages/puzzle_page.dart';
import 'package:elifba/widgets/elifba_card.dart';
import 'package:elifba/widgets/pill_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void _surface(WidgetTester tester, double w, double h) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(w, h);
  addTearDown(tester.view.reset);
}

Future<ProgressStore> _pumpPage(WidgetTester tester, String animal) async {
  final store = ProgressStore.forTesting();
  addTearDown(store.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: AnimalDetailPage(
        animal: animal,
        animals: [animal],
        currentIndex: 0,
        store: store,
      ),
    ),
  );
  await tester.pump();
  return store;
}

/// Tab zolağı 360 dp-də üfüqi sürüşür (test şriftində yazılar daha enlidir):
/// tabı əvvəlcə görünən yerə gətirir.
Future<void> _tapTab(WidgetTester tester, IconData icon) async {
  final tab = find.byIcon(icon);
  await tester.ensureVisible(tab);
  await tester.pump();
  await tester.tap(tab);
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  tearDown(() => AppSettings.instance.puzzleGridSize = 3);

  group('tablar', () {
    testWidgets('seçilmiş taba yenidən toxunmaq bölməni gizlətmir (radio)', (
      tester,
    ) async {
      await _pumpPage(tester, 'Ayı');
      expect(find.text('Məlumat:'), findsOneWidget);

      // Əvvəl seçilmiş «Məlumat»-a toxunmaq bütün bölmələri gizlədirdi.
      await tester.tap(find.byIcon(Icons.auto_stories_rounded));
      await _settle(tester);
      expect(find.text('Məlumat:'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.restaurant_rounded));
      await _settle(tester);
      expect(find.text('Qidaları:'), findsOneWidget);
      expect(find.text('Məlumat:'), findsNothing);

      // Seçilmiş «Qidalar»-a təkrar toxunuş Məlumat-a QAYTARMIR.
      await tester.tap(find.byIcon(Icons.restaurant_rounded));
      await _settle(tester);
      expect(find.text('Qidaları:'), findsOneWidget);
      expect(find.text('Məlumat:'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('seçilmiş tab zolaqda görünən yerə sürüşür', (tester) async {
      _surface(tester, 360, 640);
      await _pumpPage(tester, 'Ayı');

      // Sağ kənardan qismən görünən ilk tab (test şriftində yazılar enlidir,
      // ona görə hansı olduğu sabit deyil).
      final tabs = find.byType(PillTab);
      Finder? partial;
      for (var i = 0; i < tabs.evaluate().length; i++) {
        final r = tester.getRect(tabs.at(i));
        if (r.left < 360 - 12 && r.right > 360) {
          partial = tabs.at(i);
          break;
        }
      }
      expect(partial, isNotNull, reason: 'kənardan kəsilən tab yoxdur');
      final before = tester.getRect(partial!);
      await tester.tapAt(Offset(before.left + 6, before.center.dy));
      await _settle(tester);

      final after = tester.getRect(partial);
      expect(after.left, greaterThanOrEqualTo(0));
      expect(after.right, lessThanOrEqualTo(360));
    });

    testWidgets('tab zolağı sürüşdürüləndə yuxarıda yapışıb qalır', (
      tester,
    ) async {
      _surface(tester, 360, 640);
      await _pumpPage(tester, 'Ayı');
      final appBarBottom = tester.getBottomLeft(find.byType(AppBar)).dy;
      final tab = find.ancestor(
        of: find.byIcon(Icons.auto_stories_rounded),
        matching: find.byType(PillTab),
      );
      final before = tester.getTopLeft(tab).dy;

      final scroll = find.byKey(const ValueKey('animalPageScroll'));
      await tester.drag(scroll, const Offset(0, -400));
      await _settle(tester);
      final pinned = tester.getTopLeft(tab).dy;
      expect(pinned, lessThan(before), reason: 'səhnə yuxarı sürüşüb getdi');
      // Zolaq sürüşən sahənin düz yuxarısındadır: 12 dp boşluq + tab.
      expect(pinned, moreOrLessEquals(appBarBottom + 12));

      await tester.drag(scroll, const Offset(0, -200));
      await _settle(tester);
      expect(tester.getTopLeft(tab).dy, moreOrLessEquals(pinned));
      expect(tester.takeException(), isNull);
    });

    testWidgets('landşaft 640x360: tablar və bölmənin başı görünür', (
      tester,
    ) async {
      _surface(tester, 640, 360);
      tester.view.padding = const FakeViewPadding(top: 24);
      tester.view.viewPadding = const FakeViewPadding(top: 24);
      final store = await _pumpPage(tester, 'Ayı');

      // 16:9 səhnə (320 dp) bütün sürüşən sahəni (272 dp) tuturdu.
      final stage = tester.getRect(find.byType(AnimalStage));
      expect(stage.height, lessThan(130));
      const tabs = [Icons.auto_stories_rounded, Icons.restaurant_rounded];
      for (final icon in tabs) {
        final tab = find.ancestor(
          of: find.byIcon(icon),
          matching: find.byType(PillTab),
        );
        expect(tester.getRect(tab).bottom, lessThanOrEqualTo(360));
        expect(find.byIcon(icon).hitTestable(), findsOneWidget);
      }
      final total = store.animalTotal('Ayı');
      expect(tester.getRect(find.text('1/$total')).bottom, lessThan(360));
      expect(tester.getRect(find.text('Məlumat:')).bottom, lessThan(360));
      expect(tester.takeException(), isNull);
    });

    testWidgets('portretdə səhnə 16:9 qalır (360 → 189, 412 → 218)', (
      tester,
    ) async {
      _surface(tester, 360, 640);
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
      tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
      await _pumpPage(tester, 'Ayı');
      expect(
        tester.getSize(find.byType(AnimalStage)).height,
        moreOrLessEquals(189),
      );

      _surface(tester, 412, 915);
      await tester.pump();
      expect(
        tester.getSize(find.byType(AnimalStage)).height,
        moreOrLessEquals(218.25),
      );
    });

    testWidgets('Məlumat mətni enli ekranda 34 em-dən (612 dp) enli olmur', (
      tester,
    ) async {
      // 800x600 test səthi.
      await _pumpPage(tester, 'Ayı');
      final info = AppConfig.findAnimal(getFirstLetter('Ayı'), 'Ayı')!;
      final first = info.description
          .split('\n')
          .map((s) => s.trim())
          .firstWhere((s) => s.isNotEmpty);
      expect(tester.getSize(find.text(first)).width, lessThanOrEqualTo(612));
    });

    testWidgets('360x640-da daşma yoxdur, ulduz nişanı tək mətndir', (
      tester,
    ) async {
      _surface(tester, 360, 640);
      final store = await _pumpPage(tester, 'Ayı');
      final total = store.animalTotal('Ayı');
      expect(find.text('1/$total'), findsOneWidget);
      expect(find.bySemanticsLabel('$total tapşırıqdan 1'), findsOneWidget);
      for (final icon in [Icons.restaurant_rounded, Icons.abc_rounded]) {
        await _tapTab(tester, icon);
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('söz tapmaca', () {
    testWidgets('360 dp-də uzun ad iki sətrə düzülür, kafel ≥ 44 dp', (
      tester,
    ) async {
      _surface(tester, 360, 640);
      await _pumpPage(tester, 'Qarışqayeyən');
      await _tapTab(tester, Icons.abc_rounded);

      final slots = find.byType(DragTarget<String>);
      expect(slots, findsNWidgets(12));
      final first = tester.getRect(slots.at(0));
      expect(first.width, greaterThanOrEqualTo(44));
      // Sətirdə 6 kafel: 6-cı birinci sətirdə, 7-ci ikincidə.
      expect(tester.getRect(slots.at(5)).top, first.top);
      expect(tester.getRect(slots.at(6)).top, greaterThan(first.bottom));
      expect(tester.takeException(), isNull);
    });

    testWidgets('6 hərfli ad 360 dp-də bir sətirdə qalır', (tester) async {
      _surface(tester, 360, 640);
      await _pumpPage(tester, 'Pələng');
      await _tapTab(tester, Icons.abc_rounded);

      final slots = find.byType(DragTarget<String>);
      expect(slots, findsNWidgets(6));
      expect(tester.getRect(slots.at(5)).top, tester.getRect(slots.at(0)).top);
      expect(tester.takeException(), isNull);
    });
  });

  group('pazl ipucu (gotcha 14)', () {
    Future<List<int>> pumpPuzzle(WidgetTester tester) async {
      final calls = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PuzzlePage(animal: 'Ayı', onCompleted: () => calls.add(1)),
            ),
          ),
        ),
      );
      await tester.pump();
      return calls;
    }

    // Səbətdəki parçalar `N² + idx` datası ilə sürüklənir.
    int trayPieces(WidgetTester tester) =>
        tester
            .widgetList<Draggable<int>>(find.byType(Draggable<int>))
            .where((d) => d.data! >= 9)
            .length;

    testWidgets('ipucu ulduz vermir və 2 s sonra lövhə geri qayıdır', (
      tester,
    ) async {
      final calls = await pumpPuzzle(tester);
      expect(trayPieces(tester), 9);

      await tester.tap(find.text('İpucu'));
      await tester.pump();
      expect(find.text('2 s'), findsOneWidget);
      expect(calls, isEmpty, reason: 'ipucu pazlı tamamlanmış saymır');

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(find.text('2 s'), findsNothing);
      expect(trayPieces(tester), 9);
      expect(calls, isEmpty);
    });

    testWidgets('ipucu zamanı uşağın öz lövhəsi görünür və toxunuşa bağlıdır', (
      tester,
    ) async {
      // Səbət lövhənin altındadır: hər ikisi ekranda olsun.
      _surface(tester, 800, 1200);
      final calls = await pumpPuzzle(tester);
      Finder trayPiece() =>
          find.byWidgetPredicate((w) => w is Draggable<int> && w.data! >= 9);
      Future<void> drag(Offset from, Offset to) async {
        final g = await tester.startGesture(from);
        await tester.pump();
        await g.moveBy(const Offset(0, -12));
        await tester.pump();
        await g.moveTo(to);
        await tester.pump();
        await g.up();
        await tester.pump();
      }

      final cell0 = tester.getCenter(find.byType(DragTarget<int>).at(0));
      final cell1 = tester.getCenter(find.byType(DragTarget<int>).at(1));
      await drag(tester.getCenter(trayPiece().first), cell0);
      await tester.pump(const Duration(milliseconds: 400));
      final marked = find.bySemanticsLabel(RegExp(r'doğru|səhv'));
      expect(marked, findsOneWidget);
      expect(trayPieces(tester), 8);

      await tester.tap(find.text('İpucu'));
      await tester.pump();
      expect(find.text('2 s'), findsOneWidget);
      // Əvvəl ipucu həll olunmuş lövhəni çəkir, səbəti boşaldırdı.
      expect(trayPieces(tester), 8, reason: 'səbət parçalarını saxlayır');
      expect(marked, findsOneWidget, reason: 'qoyulmuş parça nişanlıdır');

      // İpucu zamanı sürükləmə və geri qaytarma heç nə dəyişmir.
      await drag(tester.getCenter(trayPiece().first), cell1);
      await tester.tap(find.byType(DragTarget<int>).at(0), warnIfMissed: false);
      await tester.pump();
      expect(trayPieces(tester), 8);
      expect(marked, findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('2 s'), findsNothing);
      expect(trayPieces(tester), 8);
      expect(marked, findsOneWidget);
      expect(calls, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ipucu gedərkən ikinci toxunuş həll olunmuş lövhəni saxlamır', (
      tester,
    ) async {
      final calls = await pumpPuzzle(tester);

      await tester.tap(find.text('İpucu'));
      await tester.pump(const Duration(milliseconds: 500));
      // Əvvəl ikinci toxunuş həll olunmuş lövhəni "orijinal" kimi saxlayırdı
      // və ipucu bitəndə o qalırdı — ulduz bir addımlıq olurdu.
      await tester.tap(find.text('İpucu'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 500));

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(
        trayPieces(tester),
        9,
        reason: 'lövhə əvvəlki (boş) halına qayıdır',
      );
      expect(calls, isEmpty);
    });

    testWidgets('ipucu zamanı səviyyə dəyişəndə köhnə lövhə qayıtmır', (
      tester,
    ) async {
      await pumpPuzzle(tester);
      await tester.tap(find.text('İpucu'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Orta'));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      // 4x4: 16 parça səbətdə, xəta yoxdur (əvvəl 3x3-ün 9 yeri qayıdırdı).
      final pieces = tester
          .widgetList<Draggable<int>>(find.byType(Draggable<int>))
          .where((d) => d.data! >= 16);
      expect(pieces.length, 16);
      expect(tester.takeException(), isNull);
    });
  });
}
