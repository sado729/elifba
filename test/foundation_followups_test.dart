// Ekranlar birləşəndən sonra təmələ edilən əlavələrin testləri: klaviatura
// ilə basılan `Squishy`, başlığı bir dəfə oxunan valideyn dialoqu, düymələri
// ekrandan çıxmayan dialoq, ortada duran böyük təbrik kartı və qida çipinin
// 36 dp şəkli.

import 'package:elifba/theme/theme.dart';
import 'package:elifba/widgets/celebration.dart';
import 'package:elifba/widgets/food_chip.dart';
import 'package:elifba/widgets/parent_ui.dart';
import 'package:elifba/widgets/squishy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(
  theme: ElifbaTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('Squishy klaviatura ilə', () {
    testWidgets('fokuslanır, Enter və Space onTap-ı çağırır', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          Squishy(
            onTap: () => taps++,
            color: ElifbaPalette.primary,
            edge: ElifbaEdge.e5,
            edgeColor: ElifbaPalette.primaryEdge,
            width: 64,
            height: 64,
            tooltip: 'Növbəti səhifə',
            child: const Icon(Icons.arrow_forward_rounded),
          ),
        ),
      );

      // Tab fokusu düyməyə gətirir; fokus halqası (2 dp secondary) görünür.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final frame = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final shadows = (frame.decoration! as ShapeDecoration).shadows!;
      expect(shadows.last.color, ElifbaPalette.secondary);
      expect(shadows.last.spreadRadius, ElifbaRing.normal);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(taps, 2);
    });

    testWidgets('söndürülmüş düymə fokus almır', (tester) async {
      await tester.pumpWidget(
        _app(
          const Squishy(
            onTap: null,
            color: ElifbaPalette.primary,
            width: 64,
            height: 64,
            child: SizedBox(),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        FocusManager.instance.primaryFocus?.context?.widget,
        isNot(isA<FocusableActionDetector>()),
      );
      final frame = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final shadows = (frame.decoration! as ShapeDecoration).shadows!;
      expect(shadows.last.color.a, 0);
    });
  });

  group('ParentDialog', () {
    testWidgets('başlıq ekran oxuyucusunda bir dəfə səslənir', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          const ParentDialog(
            title: 'Bütün ulduzlar silinsin?',
            icon: Icons.warning_rounded,
            body: 'Bu addımı geri qaytarmaq mümkün deyil.',
          ),
        ),
      );
      expect(find.bySemanticsLabel('Bütün ulduzlar silinsin?'), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Bütün ulduzlar silinsin?')),
        containsSemantics(isHeader: true, namesRoute: true),
      );
      handle.dispose();
    });

    testWidgets('yer çatmayanda mətn kəsilir, düymələr qalır', (tester) async {
      tester.view.physicalSize = const Size(640, 300);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(
          ParentDialog(
            title: 'Bütün ulduzlar silinsin?',
            icon: Icons.warning_rounded,
            body:
                'Yığılmış 41 ulduz və tamamlanmış bütün bölmələr '
                    'silinəcək. Bu addımı geri qaytarmaq mümkün deyil. ' *
                6,
            actions: [
              TextButton(onPressed: () {}, child: const Text('Ləğv et')),
              FilledButton(onPressed: () {}, child: const Text('Bəli, sil')),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final button = tester.getRect(find.text('Bəli, sil'));
      expect(button.bottom, lessThanOrEqualTo(300));
    });
  });

  testWidgets('böyük təbrik kartı ekranın ortasında durur', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        CelebrationOverlay(
          onDismiss: () {},
          card: CelebrationCard.big(
            title: 'Tam ulduz!',
            message: 'Ayı haqqında hər şeyi öyrəndin!',
            animateEntrance: false,
            reduceMotion: true,
            action: CelebrationAction(
              label: 'Yaşa!',
              icon: Icons.thumb_up_rounded,
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final card = tester.getRect(find.byType(CelebrationCard));
    expect(card.center.dy, closeTo(320, 1));
  });

  testWidgets('qida çipinin şəkli diskin 4 dp içindədir', (tester) async {
    await tester.pumpWidget(
      _app(
        FoodChip(
          name: 'Bal',
          imagePath: 'assets/foods/bal.webp',
          fed: false,
          onTap: () {},
          cacheWidth: 256,
        ),
      ),
    );
    expect(tester.getSize(find.byType(Image)), const Size.square(36));
  });
}
