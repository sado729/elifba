// Ana səhifənin (əlifba kitabı) yeni dizaynının testləri: oxların kitabın
// əvvəlində/sonunda söndürülməsi, «N / 16» səhifə nişanı, I/İ kiçik
// hərfləri, ✓ nişanı, ulduz sayğacının semantikası və müxtəlif ekranlarda
// daşma olmaması.
//
// Səhifə `GatedPlayer` qurur: CLAUDE.md gotcha 11-ə uyğun olaraq heç bir
// just_audio çağırışı `await` edilmir və `tester.runAsync` işlədilmir.

import 'package:elifba/core/progress.dart';
import 'package:elifba/core/settings.dart';
import 'package:elifba/pages/alphabet_page.dart';
import 'package:elifba/widgets/squishy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpHome(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: AlphabetPage()));
  await tester.pump();
}

/// Hərf səhifəsinin kartı (`Squishy`) — hərfin böyük `Text`-inə görə.
Finder _cardOf(String letter) =>
    find.ancestor(of: find.text(letter), matching: find.byType(SquishyButton));

void main() {
  final store = ProgressStore.instance;

  tearDown(() async {
    await store.reset();
    AppSettings.instance.masterSound = true;
  });

  group('kitabın oxları və səhifə nişanı', () {
    testWidgets('ilk səhifədə «geri» söndürülüb, nişan «1 / 16» yazır', (
      tester,
    ) async {
      await _pumpHome(tester);
      expect(find.text('1 / 16'), findsOneWidget);

      final semantics = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.byTooltip('Əvvəlki səhifə')),
        containsSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
          label: 'Əvvəlki səhifə',
        ),
      );
      expect(
        tester.getSemantics(find.byTooltip('Növbəti səhifə')),
        containsSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          label: 'Növbəti səhifə',
        ),
      );
      expect(find.bySemanticsLabel('Səhifə 1 / 16'), findsOneWidget);
      semantics.dispose();

      // Söndürülmüş oxa toxunmaq heç nə etmir.
      await tester.tap(find.byTooltip('Əvvəlki səhifə'));
      await tester.pumpAndSettle();
      expect(find.text('A'), findsOneWidget);
      expect(find.text('1 / 16'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('son səhifədə «irəli» söndürülüb, Y–Z və «16 / 16»', (
      tester,
    ) async {
      await _pumpHome(tester);

      for (var i = 0; i < 15; i++) {
        await tester.tap(find.byTooltip('Növbəti səhifə'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Y'), findsOneWidget);
      expect(find.text('Z'), findsOneWidget);
      expect(find.text('16 / 16'), findsOneWidget);

      final semantics = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.byTooltip('Növbəti səhifə')),
        containsSemantics(hasEnabledState: true, isEnabled: false),
      );
      expect(
        tester.getSemantics(find.byTooltip('Əvvəlki səhifə')),
        containsSemantics(hasEnabledState: true, isEnabled: true),
      );
      semantics.dispose();

      await tester.tap(find.byTooltip('Növbəti səhifə'));
      await tester.pumpAndSettle();
      expect(find.text('16 / 16'), findsOneWidget);
      expect(find.text('Z'), findsOneWidget);

      // «Geri» işləyir.
      await tester.tap(find.byTooltip('Əvvəlki səhifə'));
      await tester.pumpAndSettle();
      expect(find.text('15 / 16'), findsOneWidget);
      expect(find.text('V'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sürüşdürəndə nişan da dəyişir', (tester) async {
      await _pumpHome(tester);
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();
      expect(find.text('2 / 16'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('hərfin qlifi', () {
    testWidgets('hər səhifədə böyük və kiçik hərf ayrı-ayrı yazılır', (
      tester,
    ) async {
      await _pumpHome(tester);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('a'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('b'), findsOneWidget);
    });

    testWidgets('I və İ öz kiçik hərfini göstərir (ı, i)', (tester) async {
      await _pumpHome(tester);
      for (var i = 0; i < 6; i++) {
        await tester.tap(find.byTooltip('Növbəti səhifə'));
        await tester.pumpAndSettle();
      }
      expect(find.text('7 / 16'), findsOneWidget);
      expect(find.text('I'), findsOneWidget);
      expect(find.text('İ'), findsOneWidget);
      expect(find.text('ı'), findsOneWidget);
      expect(find.text('i'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('tamamlanma və sayğac', () {
    testWidgets('yarımçıq hərfdə ✓ nişanı yoxdur', (tester) async {
      await _pumpHome(tester);
      store.markWritten('B');
      await tester.pump();

      expect(store.starsOf('B'), 1);
      expect(
        find.descendant(
          of: find.byType(PageView),
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('hərf səhifəsinin semantikası ulduzları da oxuyur', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpHome(tester);
      expect(
        tester.getSemantics(_cardOf('A').first),
        containsSemantics(isButton: true, label: 'A hərfi\n3 ulduzdan 0'),
      );
      semantics.dispose();
    });

    testWidgets('ümumi sayğacın etiketi və tooltip-i', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpHome(tester);
      expect(find.text('0/96'), findsOneWidget);
      expect(
        find.bySemanticsLabel('96 ulduzdan 0 ulduz yığılıb'),
        findsOneWidget,
      );
      expect(find.byTooltip('96 ulduzdan 0 ulduz yığılıb'), findsOneWidget);
      semantics.dispose();
    });
  });

  group('sürətli mute', () {
    testWidgets('tooltip vəziyyətə görə dəyişir', (tester) async {
      await _pumpHome(tester);
      expect(find.byTooltip('Səsi söndür'), findsOneWidget);

      await tester.tap(find.byTooltip('Səsi söndür'));
      await tester.pumpAndSettle();
      expect(AppSettings.instance.masterSound, isFalse);
      expect(find.byTooltip('Səsi aç'), findsOneWidget);
      expect(find.byTooltip('Səsi söndür'), findsNothing);
    });
  });

  group('ekran ölçüləri', () {
    Future<void> pumpAt(WidgetTester tester, Size size) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);
      await _pumpHome(tester);
      expect(tester.takeException(), isNull, reason: '$size-də daşma');
    }

    testWidgets('360 × 640: kart 162 × 420 (kitabın hündürlük həddi)', (
      tester,
    ) async {
      await pumpAt(tester, const Size(360, 640));
      expect(tester.getSize(_cardOf('A').first), const Size(162, 420));
      expect(tester.getSize(_cardOf('B').first), const Size(162, 420));
    });

    testWidgets('412 × 915: kart 188 × 560', (tester) async {
      await pumpAt(tester, const Size(412, 915));
      expect(tester.getSize(_cardOf('A').first), const Size(188, 560));
    });

    testWidgets('800 × 600 test səthi: kart 276 × 400, kitab 560 enində', (
      tester,
    ) async {
      await pumpAt(tester, const Size(800, 600));
      expect(tester.getSize(_cardOf('A').first), const Size(276, 400));
      expect(tester.getSize(find.byType(PageView)).width, 560);
    });

    testWidgets('640 × 360 landşaft: daşma yoxdur', (tester) async {
      await pumpAt(tester, const Size(640, 360));
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('320 × 480: kiçik ekranda da daşma yoxdur', (tester) async {
      await pumpAt(tester, const Size(320, 480));
      expect(find.text('A'), findsOneWidget);
    });
  });
}
