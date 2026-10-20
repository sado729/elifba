// Yazı oyunu səhifəsinin (LetterWritingPage) testləri.
//
// CLAUDE.md gotcha 11: səhifə `GatedPlayer` (→ `AudioPlayer`) qurur, ona görə
//   * heç bir səs çağırışı `await` edilmir və `tester.runAsync` işlədilmir;
//   * səhifə açıqkən `pumpAndSettle` YOXDUR — başlanğıc halqası sonsuz nəfəs
//     alır;
//   * hər test `pumpWidget(SizedBox.shrink())` ilə bitir ki, təkrarlanan
//     animasiya testdən sonra asılı qalmasın.
import 'package:elifba/core/config.dart';
import 'package:elifba/core/letter_strokes.dart';
import 'package:elifba/core/progress.dart';
import 'package:elifba/core/settings.dart';
import 'package:elifba/core/stroke_tracker.dart';
import 'package:elifba/pages/letter_writing_page.dart';
import 'package:elifba/theme/theme.dart';
import 'package:elifba/widgets/star_row.dart';
import 'package:elifba/widgets/tracing_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ProgressStore> _pumpPage(
  WidgetTester tester, {
  String letter = 'B',
  ProgressStore? store,
}) async {
  final s = store ?? ProgressStore.forTesting();
  await tester.pumpWidget(
    MaterialApp(
      theme: ElifbaTheme.light(),
      home: LetterWritingPage(letter: letter, store: s),
    ),
  );
  await tester.pump();
  return s;
}

/// Telefon ölçüsü: status bar və jest paneli 24 + 24 dp.
void _phone(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
  tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
  addTearDown(tester.view.reset);
}

Finder get _canvas => find.byType(TracingCanvas);

TracingCanvas _canvasWidget(WidgetTester tester) =>
    tester.widget<TracingCanvas>(_canvas);

/// Kartın silkələnmə yerdəyişməsi (dp).
double _shakeDx(WidgetTester tester) => tester
    .widget<Transform>(find.byKey(kTraceCardShakeKey))
    .transform
    .getTranslation()
    .x;

/// Qutu koordinatını qlobal ekran koordinatına çevirir.
Offset _global(WidgetTester tester, Offset box) {
  final size = tester.getSize(_canvas);
  final s = glyphScale(size);
  return tester.getTopLeft(_canvas) + glyphOrigin(size, s) + box * s;
}

/// Bütün hərfi cızır; bitişik ştrixlərdə barmaq qalxmır (zəncirləmə).
Future<void> _traceAll(WidgetTester tester, List<TraceUnit> units) async {
  TestGesture? g;
  for (var k = 0; k < units.length; k++) {
    final u = units[k];
    if (u.kind == TraceUnitKind.dot) {
      await tester.tapAt(_global(tester, u.start));
      await tester.pump();
      continue;
    }
    g ??= await tester.startGesture(_global(tester, u.start));
    for (var i = 2; i < u.lastIndex; i += 2) {
      await g.moveTo(_global(tester, u.points[i]));
    }
    await g.moveTo(_global(tester, u.end));
    final joined =
        k + 1 < units.length && (units[k + 1].start - u.end).distance < 0.5;
    if (!joined) {
      await g.up();
      g = null;
    }
    await tester.pump();
  }
}

Finder _filledStar() =>
    find.byWidgetPredicate((w) => w is StarRow && w.filled == 1);

void main() {
  testWidgets('səhifə qurulur: başlıq, rejimlər, sayğac və düymələr', (
    tester,
  ) async {
    await _pumpPage(tester);

    for (final t in [
      'B hərfini yaz',
      'Bax',
      'İzlə',
      'Təkrarla',
      '0 / ${AppConfig.alphabet.length} hərf yazıldı',
      'Yenidən',
    ]) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    for (final icon in [
      Icons.arrow_back_rounded,
      Icons.chevron_left_rounded,
      Icons.chevron_right_rounded,
      Icons.visibility_rounded,
      Icons.touch_app_rounded,
      Icons.edit_rounded,
      Icons.refresh_rounded,
    ]) {
      expect(find.byIcon(icon), findsOneWidget, reason: '$icon');
    }
    expect(find.byTooltip('Geri'), findsOneWidget);
    expect(find.byTooltip('Əvvəlki hərf'), findsOneWidget);
    expect(find.byTooltip('Növbəti hərf'), findsOneWidget);
    // Başlıqda tək, boş ulduz.
    expect(
      find.byWidgetPredicate((w) => w is StarRow && w.total == 1),
      findsOneWidget,
    );
    expect(_filledStar(), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('rejim düymələri kətanın ÜSTÜNDƏdir', (tester) async {
    await _pumpPage(tester);

    expect(
      tester.getBottomLeft(find.text('İzlə')).dy,
      lessThan(tester.getTopLeft(_canvas).dy),
    );
    // Sayğac və «Yenidən» kətanın altında qalır.
    expect(
      tester.getTopLeft(find.text('Yenidən')).dy,
      greaterThan(tester.getBottomLeft(_canvas).dy),
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('rejim dəyişir; seçilmiş rejim semantikada seçilidir', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pumpPage(tester);

    expect(_canvasWidget(tester).mode, TracingMode.guided);
    expect(
      tester.getSemantics(find.bySemanticsLabel('İzlə')),
      containsSemantics(isButton: true, isSelected: true),
    );

    await tester.tap(find.text('Təkrarla'));
    await tester.pump();
    expect(_canvasWidget(tester).mode, TracingMode.faded);
    // Rəng keçidi 140 ms-dir.
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Təkrarla')),
      containsSemantics(isButton: true, isSelected: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('İzlə')),
      containsSemantics(isButton: true, isSelected: false),
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    handle.dispose();
  });

  testWidgets('seçilmiş rejimə yenidən toxunmaq kətanı sıfırlamır', (
    tester,
  ) async {
    await _pumpPage(tester);
    final before = _canvasWidget(tester).key;

    await tester.tap(find.text('İzlə'));
    await tester.pump();
    expect(_canvasWidget(tester).key, before);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('«Bax» nümayişi bitəndə özü «İzlə»-yə keçir, ulduz vermir', (
    tester,
  ) async {
    final store = await _pumpPage(tester);

    await tester.tap(find.text('Bax'));
    await tester.pump();
    expect(_canvasWidget(tester).mode, TracingMode.watch);

    // B-nin 3 ştrixi x 900 ms.
    final units = LetterStrokes.unitsFor('B')!.length;
    await tester.pump(Duration(milliseconds: 900 * units + 100));
    await tester.pump();
    expect(_canvasWidget(tester).mode, TracingMode.guided);
    expect(store.isWritten('B'), isFalse);
    expect(_filledStar(), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('oxlar hərfləri dövrə vurur', (tester) async {
    await _pumpPage(tester);
    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pump();
    expect(find.text('C hərfini yaz'), findsOneWidget);

    // Səhifə hərfi yalnız `initState`-də götürür — ağacı sıfırdan qururuq.
    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpPage(tester, letter: 'A');
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pump();
    expect(find.text('${AppConfig.alphabet.last} hərfini yaz'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pump();
    expect(find.text('A hərfini yaz'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('hərf dəyişəndə rejim «İzlə»-yə qayıdır', (tester) async {
    await _pumpPage(tester);
    await tester.tap(find.text('Təkrarla'));
    await tester.pump();
    expect(_canvasWidget(tester).mode, TracingMode.faded);

    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pump();
    expect(_canvasWidget(tester).mode, TracingMode.guided);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('«Yenidən» kətanın açarını dəyişir', (tester) async {
    await _pumpPage(tester);
    final before = _canvasWidget(tester).key;

    await tester.tap(find.text('Yenidən'));
    await tester.pump();
    expect(_canvasWidget(tester).key, isNot(before));

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('yazılmış hərf: sayğac artır, başlıq ulduzu dolur', (
    tester,
  ) async {
    final store = await _pumpPage(tester);

    store.markWritten('B');
    await tester.pump();
    expect(
      find.text('1 / ${AppConfig.alphabet.length} hərf yazıldı'),
      findsOneWidget,
    );
    expect(_filledStar(), findsOneWidget);

    // 200 ms fade-dən sonra yalnız dolu ulduz qalır.
    await tester.pump(const Duration(milliseconds: 250));
    expect(
      find.byWidgetPredicate((w) => w is StarRow && w.total == 1),
      findsOneWidget,
    );
    expect(_filledStar(), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('hərfi cızmaq onu yazılmış edir və ulduzu "pop" edir', (
    tester,
  ) async {
    final store = await _pumpPage(tester);

    await _traceAll(tester, LetterStrokes.unitsFor('B')!);
    expect(store.isWritten('B'), isTrue);

    await tester.pump(const Duration(milliseconds: 120));
    final pop = tester.widget<ScaleTransition>(
      find.byWidgetPredicate(
        (w) => w is ScaleTransition && w.child is AnimatedSwitcher,
      ),
    );
    expect(pop.scale.value, greaterThan(1));
    expect(_filledStar(), findsOneWidget);
    expect(
      find.text('1 / ${AppConfig.alphabet.length} hərf yazıldı'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    // Konfeti real saatla işləyir — settle etmədən ağacı sökürük.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('datası olmayan hərf: ehtiyat mətni, rejim düymələri yoxdur', (
    tester,
  ) async {
    await _pumpPage(tester, letter: 'W');

    expect(
      find.text('"W" hərfi üçün yazı datası hələ hazır deyil.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.edit_off_rounded), findsOneWidget);
    expect(find.text('Bax'), findsNothing);
    expect(_canvas, findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('səhv toxunuş kartı silkələyir', (tester) async {
    await _pumpPage(tester);
    expect(_shakeDx(tester), 0);

    // Kətanın sol-üst küncü B-nin başlanğıcından çox uzaqdır.
    await tester.tapAt(tester.getTopLeft(_canvas) + const Offset(4, 4));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(_shakeDx(tester).abs(), greaterThan(1));

    // 280 ms-dən sonra kart yerinə qayıdır.
    await tester.pump(const Duration(milliseconds: 300));
    expect(_shakeDx(tester), 0);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('azaldılmış hərəkət: səhv toxunuşda kart silkələnmir', (
    tester,
  ) async {
    AppSettings.instance.reduceMotion = true;
    addTearDown(() => AppSettings.instance.reduceMotion = false);
    await _pumpPage(tester);

    await tester.tapAt(tester.getTopLeft(_canvas) + const Offset(4, 4));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(_shakeDx(tester), 0);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('azaldılmış hərəkət: hərf bitəndə ulduz "pop" etmir', (
    tester,
  ) async {
    AppSettings.instance.reduceMotion = true;
    addTearDown(() => AppSettings.instance.reduceMotion = false);
    final store = await _pumpPage(tester);

    await _traceAll(tester, LetterStrokes.unitsFor('B')!);
    expect(store.isWritten('B'), isTrue);

    await tester.pump(const Duration(milliseconds: 120));
    final pop = tester.widget<ScaleTransition>(
      find.byWidgetPredicate(
        (w) => w is ScaleTransition && w.child is AnimatedSwitcher,
      ),
    );
    expect(pop.scale.value, 1);
    expect(_filledStar(), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final size in const [Size(360, 640), Size(412, 915)]) {
    testWidgets('daşma yoxdur: ${size.width.toInt()}x${size.height.toInt()}', (
      tester,
    ) async {
      _phone(tester, size);
      await _pumpPage(tester);
      expect(tester.takeException(), isNull);

      // Kart qalan yerin hamısını tutur: 64 başlıq + 58 rejim + 80 alt panel.
      final card = tester.getSize(_canvas);
      expect(card.width, size.width - 2 * 16 - 2 * 12);
      expect(card.height, size.height - 48 - 64 - 58 - 80 - 2 * 12);

      await tester.pumpWidget(const SizedBox.shrink());
      await _pumpPage(tester, letter: 'W');
      expect(find.byIcon(Icons.edit_off_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  // Yan tutulmuş telefon: portret düzülüşündə kətan 86 dp qalardı (miqyas
  // 0.83). Rejimlər sola, sayğac və «Yenidən» sağa keçir.
  for (final (size, padding) in const [
    (Size(640, 360), FakeViewPadding(top: 24, bottom: 24)),
    (Size(640, 360), FakeViewPadding(top: 24, right: 48)),
    (Size(915, 412), FakeViewPadding(top: 24, bottom: 24)),
  ]) {
    for (final textScale in const [1.0, 1.3]) {
      testWidgets(
        'yan düzülüş: ${size.width.toInt()}x${size.height.toInt()} '
        'sağ ${padding.right.toInt()}, mətn $textScale',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          tester.view.padding = padding;
          tester.view.viewPadding = padding;
          addTearDown(tester.view.reset);
          tester.platformDispatcher.textScaleFactorTestValue = textScale;
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          await _pumpPage(tester);
          expect(tester.takeException(), isNull);

          expect(glyphScale(tester.getSize(_canvas)), greaterThan(1.6));
          final canvas = tester.getRect(_canvas);
          for (final t in ['Bax', 'İzlə', 'Təkrarla']) {
            expect(tester.getRect(find.text(t)).right, lessThan(canvas.left));
          }
          expect(
            tester.getRect(find.text('Yenidən')).left,
            greaterThan(canvas.right),
          );
          expect(
            tester
                .getRect(
                  find.text('0 / ${AppConfig.alphabet.length} hərf yazıldı'),
                )
                .left,
            greaterThan(canvas.right),
          );

          await tester.pumpWidget(const SizedBox.shrink());
          await _pumpPage(tester, letter: 'W');
          expect(find.byIcon(Icons.edit_off_rounded), findsOneWidget);
          expect(tester.takeException(), isNull);

          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }

  testWidgets('ekran dönəndə kətan vəziyyətini saxlayır', (tester) async {
    _phone(tester, const Size(360, 640));
    await _pumpPage(tester);
    final before = tester.state(_canvas);
    final key = _canvasWidget(tester).key;

    tester.view.physicalSize = const Size(640, 360);
    await tester.pump();
    expect(tester.takeException(), isNull);
    // Yan düzülüşdə rejimlər kətanın solundadır — düzülüş həqiqətən dəyişib.
    expect(
      tester.getRect(find.text('İzlə')).right,
      lessThan(tester.getRect(_canvas).left),
    );
    expect(tester.state(_canvas), same(before));
    expect(_canvasWidget(tester).key, key);

    tester.view.physicalSize = const Size(360, 640);
    await tester.pump();
    expect(tester.state(_canvas), same(before));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('daşma yoxdur: 360x640, mətn miqyası 1.3', (tester) async {
    _phone(tester, const Size(360, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final store = ProgressStore.forTesting();
    for (final l in AppConfig.alphabet.take(12)) {
      store.markWritten(l);
    }
    await _pumpPage(tester, letter: 'Ş', store: store);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
