// Valideyn qapısının testləri.
//
// Qapı bilərəkdən ZƏİF mexanizmdir (basıb-saxlama, dizayn sənədi §2.1), amma
// zəif olması ilə sınıq olması eyni şey deyil: bu testlər onun ən azı elan
// edildiyi kimi işlədiyini qoruyur — müddət tam dolmalıdır, yarımçıq cəhdlər
// yığılmamalıdır.

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
}
