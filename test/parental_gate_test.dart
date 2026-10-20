// Valideyn qapısının testləri.
//
// Qapı bilərəkdən ZƏİF mexanizmdir (basıb-saxlama, dizayn sənədi §2.1), amma
// zəif olması ilə sınıq olması eyni şey deyil: bu testlər onun ən azı elan
// edildiyi kimi işlədiyini qoruyur — müddət tam dolmalıdır, yarımçıq cəhdlər
// yığılmamalıdır.

import 'package:elifba/theme/theme.dart';
import 'package:elifba/widgets/parental_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Qapını açan sadə ev sahibi widget. [result] qapı bağlananda dolur.
  Future<void> pumpHost(WidgetTester tester, List<bool> result) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder:
                (context) => ElevatedButton(
                  onPressed:
                      () async => result.add(await showParentalGate(context)),
                  child: const Text('Aç'),
                ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();
    expect(find.text('Valideynlər üçün'), findsOneWidget);
  }

  final holdTarget = find.byIcon(Icons.touch_app_outlined);

  testWidgets('müddət tam dolanda qapı açılır', (tester) async {
    final result = <bool>[];
    await pumpHost(tester, result);

    final gesture = await tester.startGesture(tester.getCenter(holdTarget));
    await tester.pump();
    await tester.pump(kParentalGateHold + const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(result, [true]);
    expect(find.text('Valideynlər üçün'), findsNothing);
  });

  testWidgets('müddət dolmamış barmaq qaldırılsa qapı açılmır', (tester) async {
    final result = <bool>[];
    await pumpHost(tester, result);

    final gesture = await tester.startGesture(tester.getCenter(holdTarget));
    await tester.pump();
    await tester.pump(kParentalGateHold - const Duration(milliseconds: 200));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(result, isEmpty, reason: 'qapı hələ bağlıdır, nəticə yoxdur');
    expect(find.text('Valideynlər üçün'), findsOneWidget);
  });

  testWidgets('sistemin "animasiyaları söndür"ü 3 s-i qısaltmır', (
    tester,
  ) async {
    // Android-in "Animasiyaları sil" ayarı `disableAnimations` bayrağını
    // qaldırır; adi `AnimationController` onda müddəti 20 dəfə qısaldır
    // (3 s → 150 ms). Qapı bu bayraqdan asılı olmamalıdır.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    final result = <bool>[];
    await pumpHost(tester, result);

    var gesture = await tester.startGesture(tester.getCenter(holdTarget));
    await tester.pump();
    await tester.pump(kParentalGateHold - const Duration(milliseconds: 200));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(result, isEmpty, reason: 'hədd yenə tam 3 s-dir');
    expect(find.text('Valideynlər üçün'), findsOneWidget);

    gesture = await tester.startGesture(tester.getCenter(holdTarget));
    await tester.pump();
    await tester.pump(kParentalGateHold + const Duration(milliseconds: 16));
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    // Yaşıl ✓ da tam 200 ms görünür (10 ms yox).
    await tester.pump(kParentalGateDoneDelay ~/ 2);
    expect(result, isEmpty);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(result, [true]);
  });

  testWidgets('ekran oxuyucusu "Valideynlər üçün"ü bir dəfə eşidir', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpHost(tester, <bool>[]);

    // Marşrutun adı yoxdur (spec §6); başlıq yeganə belə düyündür.
    expect(find.bySemanticsLabel('Valideynlər üçün'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Valideynlər üçün')),
      containsSemantics(isHeader: true),
    );
    handle.dispose();
  });

  testWidgets('yarımçıq cəhdlər YIĞILMIR — tərəqqi sıfırlanır', (tester) async {
    final result = <bool>[];
    await pumpHost(tester, result);

    // Üç dəfə müddətin yarısı qədər saxlamaq cəmdə 1.5 müddət edir, amma hər
    // buraxılış tərəqqini sıfırladığı üçün qapı açılmamalıdır. Bu, uşağın
    // təkrar-təkrar toxunaraq keçməsinin qarşısını alır.
    for (var i = 0; i < 3; i++) {
      final gesture = await tester.startGesture(tester.getCenter(holdTarget));
      await tester.pump();
      await tester.pump(kParentalGateHold ~/ 2);
      await gesture.up();
      await tester.pumpAndSettle();
    }

    expect(result, isEmpty);
    expect(find.text('Valideynlər üçün'), findsOneWidget);

    // Sıfırlandıqdan sonra TAM müddət hələ də işləyir.
    final gesture = await tester.startGesture(tester.getCenter(holdTarget));
    await tester.pump();
    await tester.pump(kParentalGateHold + const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(result, [true]);
  });

  testWidgets('"Ləğv et" false qaytarır', (tester) async {
    final result = <bool>[];
    await pumpHost(tester, result);

    await tester.tap(find.text('Ləğv et'));
    await tester.pumpAndSettle();

    expect(result, [false]);
    expect(find.text('Valideynlər üçün'), findsNothing);
  });

  testWidgets('kənara toxunub bağlamaq da false qaytarır', (tester) async {
    final result = <bool>[];
    await pumpHost(tester, result);

    // Barrier-ə toxunmaq dialoqu bağlayır; `showParentalGate` null-ı `false`-a
    // çevirməlidir, əks halda çağıran tərəf tip xətası alardı.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(result, [false]);
  });

  // ---------------------------------------------------------------- dizayn
  // Aşağıdakı testlər yenilənmiş görünüşü (dizayn §7.3) və onun gətirdiyi
  // "tamam" halını qoruyur: hədd yenə 3 s-dir, sonra 200 ms yaşıl ✓.

  /// Düymənin (72 dp dairə) hazırkı fon rəngi.
  Color buttonColor(WidgetTester tester) {
    final container = tester.widget<Container>(
      find
          .ancestor(
            of: find.byWidgetPredicate(
              (w) =>
                  w is Icon &&
                  (w.icon == Icons.touch_app_outlined ||
                      w.icon == Icons.check_rounded),
            ),
            matching: find.byType(Container),
          )
          .first,
    );
    return (container.decoration! as BoxDecoration).color!;
  }

  /// Halqanın rəssamı: `progress` (0..1) və qövsün rəngi.
  ({double progress, Color color}) ring(WidgetTester tester) {
    final paint = tester.widget<CustomPaint>(
      find.byWidgetPredicate(
        (w) =>
            w is CustomPaint &&
            w.painter.runtimeType.toString() == '_GateRingPainter',
      ),
    );
    final dynamic painter = paint.painter;
    return (
      progress: painter.progress as double,
      color: painter.color as Color,
    );
  }

  testWidgets(
    'halqa: gözləyir → basılıb (dolur) → buraxılanda dərhal boşalır',
    (tester) async {
      final result = <bool>[];
      await pumpHost(tester, result);

      // Gözləyir: #F1ECFF fon, əl ikonu, qövs yoxdur (yalnız iz).
      expect(buttonColor(tester), ElifbaPalette.surfaceContainer);
      expect(ring(tester).progress, 0);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);

      final gesture = await tester.startGesture(tester.getCenter(holdTarget));
      await tester.pump();
      await tester.pump(kParentalGateHold ~/ 2);

      // Basılıb: #E4DEFF fon, #5E5888 qövs düz yarıya qədər, xətti.
      expect(buttonColor(tester), ElifbaPalette.surfaceContainerHighest);
      expect(ring(tester).progress, closeTo(0.5, 0.001));
      expect(ring(tester).color, ElifbaPalette.onSurfaceVariant);

      // Buraxılış: geri animasiya yoxdur, elə həmin kadrda boşdur.
      await gesture.up();
      await tester.pump();
      expect(ring(tester).progress, 0);
      expect(buttonColor(tester), ElifbaPalette.surfaceContainer);
      expect(result, isEmpty);
    },
  );

  testWidgets('dolanda 200 ms yaşıl ✓ görünür, sonra qapı true ilə bağlanır', (
    tester,
  ) async {
    final result = <bool>[];
    await pumpHost(tester, result);

    final gesture = await tester.startGesture(tester.getCenter(holdTarget));
    await tester.pump();
    await tester.pump(kParentalGateHold + const Duration(milliseconds: 16));

    // Tamam: qərar verilib, amma dialoq hələ açıqdır.
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(holdTarget, findsNothing);
    expect(buttonColor(tester), ElifbaPalette.correctContainer);
    expect(ring(tester).progress, 1);
    expect(ring(tester).color, ElifbaPalette.correct);
    expect(result, isEmpty);
    expect(find.text('Valideynlər üçün'), findsOneWidget);

    // Gecikmə AnimationController ilə gedir (Timer yox): yarısında hələ açıq.
    await tester.pump(kParentalGateDoneDelay ~/ 2);
    await tester.pump(kParentalGateDoneDelay ~/ 2);
    expect(result, isEmpty);
    expect(find.text('Valideynlər üçün'), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(result, [true]);
    expect(find.text('Valideynlər üçün'), findsNothing);
  });

  testWidgets('tamam halı geri dönmür: buraxmaq, "Ləğv et", kənar və "geri"', (
    tester,
  ) async {
    final result = <bool>[];
    await pumpHost(tester, result);

    final gesture = await tester.startGesture(tester.getCenter(holdTarget));
    await tester.pump();
    await tester.pump(kParentalGateHold + const Duration(milliseconds: 16));
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    // Barmağı qaldırmaq halqanı sıfırlamır.
    await gesture.up();
    await tester.pump();
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(ring(tester).progress, 1);

    // "Ləğv et", scrim və sistemin "geri"si nəzərə alınmır.
    await tester.tap(find.text('Ləğv et'));
    await tester.pump();
    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    await tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
    await tester.pump();
    expect(result, isEmpty);
    expect(find.text('Valideynlər üçün'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(result, [true]);
  });

  testWidgets(
    'basılı ikən scrim-ə ikinci toxunuş: false, kitab yerində qalır',
    (tester) async {
      // Kök səhifə → kitab → qapı. Barmaq düyməni saxlayarkən ikinci barmaq
      // scrim-ə toxunur: nəticə `false`-dır və sönən dialoqun halqası heç vaxt
      // `pop` edib altdakı kitabı bağlamamalıdır. Bunu bu gün `Navigator`
      // özü təmin edir (pop zamanı aktiv toxunuşları ləğv edir → sıfırlanma);
      // `_close`-dakı `ModalRoute.isCurrentOf` yoxlaması əlavə sığortadır.
      final result = <bool>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder:
                (context) => Scaffold(
                  body: ElevatedButton(
                    onPressed:
                        () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder:
                                (context) => Scaffold(
                                  body: ElevatedButton(
                                    onPressed:
                                        () async => result.add(
                                          await showParentalGate(context),
                                        ),
                                    child: const Text('Aç'),
                                  ),
                                ),
                          ),
                        ),
                    child: const Text('Kitab'),
                  ),
                ),
          ),
        ),
      );
      await tester.tap(find.text('Kitab'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(tester.getCenter(holdTarget));
      await tester.pump();
      await tester.pump(kParentalGateHold - const Duration(milliseconds: 100));
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      expect(result, [false]);

      // Halqa sönmə animasiyası (150 ms) gedərkən dolur.
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(result, [false]);
      expect(find.text('Valideynlər üçün'), findsNothing);
      expect(find.text('Aç'), findsOneWidget, reason: 'kitab yerində qalır');
    },
  );

  for (final size in const [Size(360, 640), Size(412, 915), Size(800, 600)]) {
    testWidgets('ölçülər ${size.width.toInt()}x${size.height.toInt()}: '
        'dialoq 312, düymə 72, halqa 112, daşma yoxdur', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.reset);

      final result = <bool>[];
      await pumpHost(tester, result);

      final content = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(SingleChildScrollView),
      );
      // En 312; hündürlük = boşluqlar + kilid qutusu + halqa + düymə
      // (24 + 36 + 12 + 12 + 20 + 112 + 16 + 48 + 12 = 292) + iki mətn.
      // Testin şrifti (kvadrat qliflər) mətni əsl Andika-dan uzun sındırır;
      // real şriftlə 26 + 44 → 362 (tool/gate_screens_test.dart).
      final texts =
          tester.getSize(find.text('Valideynlər üçün')).height +
          tester
              .getSize(
                find.text('Davam etmək üçün düyməni 3 saniyə basıb saxlayın.'),
              )
              .height;
      expect(tester.getSize(content), Size(312, 292 + texts));
      expect(tester.getCenter(content).dx, size.width / 2);
      expect(tester.getCenter(content).dy, closeTo(size.height / 2, 0.5));

      // Toxunma sahəsi halqa deyil, 72×72 kvadratdır (künclər də daxil).
      final target = find.ancestor(
        of: holdTarget,
        matching: find.byType(GestureDetector),
      );
      expect(tester.getSize(target.first), const Size(72, 72));
      expect(
        tester.getSize(
          find.ancestor(of: holdTarget, matching: find.byType(Stack)).first,
        ),
        const Size(112, 112),
      );
      expect(tester.getSize(find.byType(TextButton)).height, 48);
      expect(tester.takeException(), isNull);

      // Kvadratın küncü (dairədən kənar) də basıb-saxlamanı başladır.
      final corner = tester.getTopLeft(target.first) + const Offset(2, 2);
      final gesture = await tester.startGesture(corner);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(ring(tester).progress, greaterThan(0));
      await gesture.up();
      await tester.pump();

      // Halqanın özü (düymədən kənar) hədəf deyil.
      final ringOnly = await tester.startGesture(
        tester.getCenter(target.first) - const Offset(0, 48),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(ring(tester).progress, 0);
      await ringOnly.up();
      await tester.pumpAndSettle();
      expect(result, isEmpty);
    });
  }

  testWidgets('landşaftda və iri şriftdə daşmır, qapı yenə açılır', (
    tester,
  ) async {
    for (final (size, scale) in const [
      (Size(640, 360), 1.0),
      (Size(360, 640), 2.0),
    ]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final result = <bool>[];
      await pumpHost(tester, result);
      expect(tester.takeException(), isNull);

      // Məzmun sığmır və sürüşür: `onTapDown` `kPressTimeout` (100 ms) gecikir.
      await tester.ensureVisible(holdTarget);
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(tester.getCenter(holdTarget));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(kParentalGateHold + const Duration(milliseconds: 100));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(result, [true], reason: '$size, şrift $scale');
      expect(tester.takeException(), isNull);
    }
  });
}
