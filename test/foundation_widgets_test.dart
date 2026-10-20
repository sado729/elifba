// Ortaq dizayn təməlinin (lib/theme + lib/widgets) testləri.
//
// Hər ortaq widget hər vəziyyətdə 360 və 412 dp endə qurulur: istisna və
// daşma (overflow) olmamalıdır. Əlavə olaraq ekran testlərinin söykəndiyi
// qaydalar yoxlanır: `Squishy`-nin tək `AnimatedContainer`-i, `StarRow`
// semantikası, söndürülmüş səs düyməsinin qeyri-aktivliyi, azaldılmış
// hərəkət variantları və boş ekranda `pumpAndSettle`-in bitməsi.
//
// Qeydlər:
// * `AppSettings.instance` singleton-dur — hər testdən sonra defoltlara
//   qaytarılır (`_prefs` null olduğu üçün diskə heç nə yazılmır).
// * Burada `AudioPlayer` qurulmur, amma CLAUDE.md gotcha 11 ruhunda
//   `tester.runAsync` işlədilmir.
// * Sonsuz animasiyalar (oxuyan səs düyməsinin nəbzi, böyük təbrikin
//   şüaları) açıq olanda `pumpAndSettle` çağırılmır.

import 'package:confetti/confetti.dart';
import 'package:elifba/core/config.dart';
import 'package:elifba/core/settings.dart';
import 'package:elifba/main.dart';
import 'package:elifba/theme/theme.dart';
import 'package:elifba/widgets/audio_button.dart';
import 'package:elifba/widgets/badges.dart';
import 'package:elifba/widgets/celebration.dart';
import 'package:elifba/widgets/elifba_card.dart';
import 'package:elifba/widgets/elifba_confetti.dart';
import 'package:elifba/widgets/food_chip.dart';
import 'package:elifba/widgets/game_feedback.dart';
import 'package:elifba/widgets/icon_buttons.dart';
import 'package:elifba/widgets/mute_button.dart';
import 'package:elifba/widgets/parent_ui.dart';
import 'package:elifba/widgets/pill_button.dart';
import 'package:elifba/widgets/pill_tab.dart';
import 'package:elifba/widgets/progress_bar.dart';
import 'package:elifba/widgets/sky_background.dart';
import 'package:elifba/widgets/squishy.dart';
import 'package:elifba/widgets/star_row.dart';
import 'package:elifba/widgets/sun_mascot.dart';
import 'package:elifba/widgets/sunburst.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _widths = [360.0, 412.0];

/// Konfeti controller-ini özü yaradıb atan sahib (`ElifbaConfetti` üçün).
class _ConfettiHost extends StatefulWidget {
  const _ConfettiHost();

  @override
  State<_ConfettiHost> createState() => _ConfettiHostState();
}

class _ConfettiHostState extends State<_ConfettiHost> {
  late final ConfettiController _c = ConfettiPreset.small.createController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: 40, height: 40, child: ElifbaConfetti(controller: _c));
}

/// Bütün ortaq widget-lər, bütün vəziyyətlərində. [endless] → oxuyan səs
/// düyməsi və fırlanan halqa da daxildir (onda `pumpAndSettle` bitmir).
List<Widget> _catalogue({required bool reduced, required bool endless}) {
  void noop() {}
  final tile = wordTileWidth(3, 300);
  return [
    // Squishy və düymələr.
    Squishy(
      onTap: noop,
      color: ElifbaPalette.surface,
      edge: 5,
      edgeColor: ElifbaPalette.outline,
      ringWidth: 2,
      ringColor: ElifbaPalette.outline,
      padding: const EdgeInsets.all(12),
      child: const Text('Squishy'),
    ),
    const Squishy(
      onTap: null,
      color: ElifbaPalette.primary,
      edge: 5,
      padding: EdgeInsets.all(12),
      child: Text('qeyri-aktiv'),
    ),
    for (final v in PillButtonVariant.values)
      for (final s in PillButtonSize.values) ...[
        PillButton(
          label: 'Yenidən',
          icon: Icons.refresh_rounded,
          onPressed: noop,
          variant: v,
          size: s,
        ),
        PillButton(label: 'Yaşa!', onPressed: noop, variant: v, size: s),
      ],
    const PillButton(
      label: 'Yenidən',
      icon: Icons.refresh_rounded,
      onPressed: null,
    ),
    SizedBox(
      width: 160,
      child: PillButton(
        label: 'Yenidən başla',
        icon: Icons.refresh_rounded,
        onPressed: noop,
        variant: PillButtonVariant.secondary,
        size: PillButtonSize.small,
        expand: true,
      ),
    ),
    NavRoundButton(
      icon: Icons.arrow_forward_rounded,
      onPressed: noop,
      tooltip: 'Növbəti səhifə',
    ),
    const NavRoundButton(
      icon: Icons.arrow_back_rounded,
      onPressed: null,
      tooltip: 'Əvvəlki səhifə',
    ),
    const ToolbarBackButton(),
    ToolbarChevron(forward: true, onPressed: noop, tooltip: 'Növbəti hərf'),
    const ToolbarChevron(
      forward: false,
      onPressed: null,
      tooltip: 'Əvvəlki hərf',
      width: 44,
    ),
    QuietIconButton(onPressed: noop),
    const ParentBackButton(),
    const MuteButton(),
    // Səs düymələri.
    for (final size in [ElifbaSize.audioL, ElifbaSize.audioM])
      for (final st in AudioButtonState.values)
        if (endless || st != AudioButtonState.playing || reduced)
          AudioButton(
            state: st,
            onPressed: noop,
            size: size,
            reduceMotion: reduced,
          ),
    for (final st in [AudioButtonState.ready, AudioButtonState.muted])
      AudioButton(
        state: st,
        onPressed: noop,
        tone: AudioTone.animal,
        size: ElifbaSize.audioM,
        reduceMotion: reduced,
      ),
    for (final st in AudioButtonState.values)
      if (endless || st != AudioButtonState.playing || reduced)
        AudioPillButton(state: st, onPressed: noop, reduceMotion: reduced),
    // Tablar.
    PillTab(
      label: 'Məlumat',
      icon: Icons.auto_stories_rounded,
      onTap: noop,
      selected: true,
    ),
    PillTab(
      label: 'Qidalar',
      icon: Icons.restaurant_rounded,
      onTap: noop,
      done: true,
    ),
    PillTab(
      label: 'Söz tapmaca',
      icon: Icons.abc_rounded,
      onTap: noop,
      selected: true,
      done: true,
    ),
    const PillTab(label: 'Pazl', icon: Icons.extension_rounded, onTap: null),
    const PillTab(
      label: 'Bax',
      icon: Icons.visibility_rounded,
      onTap: null,
      selected: true,
      unselectedIconColor: ElifbaPalette.onSurfaceVariant,
      animateSelection: false,
    ),
    SizedBox(
      width: 330,
      child: Row(
        children: [
          for (final n in [3, 4, 5]) ...[
            if (n != 3) const SizedBox(width: 8),
            Expanded(
              child: PillTab(
                label: ['Asan', 'Orta', 'Çətin'][n - 3],
                leading: GridGlyph(
                  n: n,
                  color: GridGlyph.colorFor(selected: n == 4),
                ),
                onTap: noop,
                selected: n == 4,
                expand: true,
              ),
            ),
          ],
        ],
      ),
    ),
    // Qida çipləri.
    for (final fed in [false, true])
      FoodChip(
        name: 'Balıq',
        imagePath: 'assets/foods/baliq.webp',
        fed: fed,
        onTap: noop,
        cacheWidth: 256,
        imageTint: ElifbaPalette.foodDiscTint(1),
      ),
    FoodChip(
      name: 'Quru yem',
      imagePath: 'assets/foods/__yoxdur__.webp',
      fed: false,
      onTap: noop,
      cacheWidth: 256,
      imageHidden: true,
    ),
    // Kartlar.
    const SizedBox(
      width: 200,
      height: 80,
      child: ElifbaCard(padding: EdgeInsets.all(12), child: Text('Kart')),
    ),
    const ElifbaCard.section(
      padding: EdgeInsets.all(12),
      child: Text('Bölmə kartı'),
    ),
    for (final complete in [false, true])
      SizedBox(
        width: 142,
        height: 126,
        child: AnimalStage(complete: complete, child: const ImagePlaceholder()),
      ),
    const SizedBox(
      width: 300,
      height: 180,
      child: AnimalStage(
        hill: StageHill.hero,
        radius: ElifbaRadius.r32,
        child: ImagePlaceholder(),
      ),
    ),
    const SizedBox(
      width: 142,
      height: 126,
      child: AnimalStage(hill: StageHill.none, child: ImagePlaceholder()),
    ),
    const ImagePlaceholder(size: 72, cloudColor: ElifbaPalette.stageSky),
    const SizedBox(
      width: 120,
      height: 140,
      child: CustomPaint(
        foregroundPainter: DashedRRectPainter(
          color: ElifbaPalette.secondary,
          strokeWidth: 2.5,
          radius: 28,
        ),
      ),
    ),
    // Ulduzlar, zolaq, nişanlar.
    for (var i = 0; i <= 3; i++) StarRow(filled: i, size: 20, spacing: 1),
    const StarRow(filled: 2, size: 26, spacing: 2),
    const StarGlyph(filled: true, size: 40, strokeWidth: 1.4),
    const StarGlyph(filled: false, size: 22),
    for (final v in [0.0, 0.3, 1.0])
      SizedBox(width: 200, child: ElifbaProgressBar(value: v)),
    const SizedBox(
      width: 200,
      child: ElifbaProgressBar(value: 0.5, complete: true),
    ),
    for (final s in [18.0, 20.0, 22.0, 32.0]) ...[
      CheckBadge(size: s, ringWidth: s == 32 ? 3 : 2),
      CrossBadge(size: s, ringWidth: s == 18 ? 0 : 2),
    ],
    // Oyun rəyi.
    for (final st in WordTileState.values)
      Padding(
        padding: const EdgeInsets.all(12),
        child: WordTileFace(
          state: st,
          glyph: 'A',
          width: tile,
          height: wordTileHeight(tile),
        ),
      ),
    PopOnTrigger(trigger: 1, reduceMotion: reduced, child: const CheckBadge()),
    ShakeOnTrigger(
      trigger: 1,
      reduceMotion: reduced,
      child: const CrossBadge(),
    ),
    for (final d in <Decoration>[
      GameDecorations.cellEmpty,
      GameDecorations.cellHover,
      GameDecorations.board,
      GameDecorations.boardDone,
    ])
      Container(width: 60, height: 60, decoration: d),
    Container(
      width: 60,
      height: 60,
      color: const Color(0xFFC9BFA8),
      foregroundDecoration: GameDecorations.cellCorrect,
    ),
    CustomPaint(
      foregroundPainter: GameDecorations.cellWrongOutline,
      child: Container(
        width: 60,
        height: 60,
        color: const Color(0xFFA89F8E),
        foregroundDecoration: GameDecorations.cellWrong,
      ),
    ),
    // Maskot, halqa, fon.
    for (final p in SunPose.values) SunMascot(pose: p, size: 92),
    const SunburstDisc(size: 96),
    SunburstDisc(size: 96, flat: true, reduceMotion: reduced),
    if (endless || reduced)
      SunburstDisc(
        size: 128,
        rotating: true,
        reduceMotion: reduced,
        child: const SunMascot.cheer(),
      ),
    for (final style in SkyStyle.values)
      SizedBox(width: 200, height: 120, child: SkyBackground(style: style)),
    SizedBox(
      width: 200,
      height: 80,
      child: MediaQuery(
        data: const MediaQueryData(viewPadding: EdgeInsets.only(bottom: 24)),
        child: Stack(
          children: [
            const SkyBackground(),
            const NavBarFade(),
            const NavBarFade(parent: true),
          ],
        ),
      ),
    ),
    const _ConfettiHost(),
    // Təbriklər (kart özü; route və overlay ayrıca testlərdədir).
    CelebrationCard.small(reduceMotion: reduced),
    CelebrationCard.small(
      message: 'Pazl tamamlandı!',
      action: CelebrationAction(
        label: 'Yenidən',
        icon: Icons.refresh_rounded,
        onPressed: noop,
      ),
      reduceMotion: reduced,
    ),
    if (endless || reduced)
      Padding(
        padding: const EdgeInsets.only(top: 80),
        child: CelebrationCard.big(
          title: 'Tam ulduz!',
          message: 'Qarışqayeyən haqqında hər şeyi öyrəndin!',
          action: CelebrationAction(
            label: 'Yaşa!',
            icon: Icons.thumb_up_rounded,
            onPressed: noop,
          ),
          reduceMotion: reduced,
        ),
      ),
    // Valideyn sahəsi.
    ParentDialog(
      icon: Icons.warning_rounded,
      title: 'Bütün ulduzlar silinsin?',
      body: 'Yığılmış 41 ulduz və tamamlanmış bütün bölmələr silinəcək.',
      actions: [
        TextButton(
          style: ParentButtonStyles.text,
          onPressed: noop,
          child: const Text('Ləğv et'),
        ),
        FilledButton(
          style: ParentButtonStyles.destructive,
          onPressed: noop,
          child: const Text('Bəli, sil'),
        ),
      ],
    ),
    SizedBox(
      height: 260,
      child: ParentDialog(
        title: 'Səs mənbələri',
        scrollableContent: true,
        content: Text('Mətn\n' * 30),
        actions: [
          FilledButton(
            style: ParentButtonStyles.filled,
            onPressed: noop,
            child: const Text('Bağla'),
          ),
        ],
      ),
    ),
    const ParentSectionHeader('Səs', first: true),
    ParentGroup(
      children: [
        SwitchTheme(
          data: ElifbaSwitchTheme.data,
          child: SwitchListTile(
            value: true,
            onChanged: (_) {},
            title: const Text('Bütün səslər'),
          ),
        ),
        const ListTile(title: Text('Səs mənbələri')),
      ],
    ),
  ];
}

Future<void> _pumpAt(
  WidgetTester tester,
  double width,
  List<Widget> children, {
  ThemeData? theme,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 1600);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? ElifbaTheme.light(),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
          child: Wrap(
            spacing: 16,
            runSpacing: 20,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: children,
          ),
        ),
      ),
    ),
  );
}

Widget _app(Widget home) =>
    MaterialApp(theme: ElifbaTheme.light(), home: Scaffold(body: home));

void main() {
  final settings = AppSettings.instance;
  setUp(() => settings.restoreFromJson(null));
  tearDown(() => settings.restoreFromJson(null));

  group('kataloq', () {
    for (final width in _widths) {
      for (final reduced in [false, true]) {
        testWidgets('${width.toInt()} dp, reduced=$reduced: istisna və '
            'daşma yoxdur', (tester) async {
          await _pumpAt(
            tester,
            width,
            _catalogue(reduced: reduced, endless: true),
          );
          await tester.pump(const Duration(milliseconds: 400));
          await tester.pump(const Duration(milliseconds: 900));
          expect(tester.takeException(), isNull);
          // Sonsuz animasiyaları söndürüb ağacı söküb qurtarırıq.
          await tester.pumpWidget(const SizedBox());
        });
      }
    }

    testWidgets('səs söndürüləndə mute düyməsi də daşmır', (tester) async {
      settings.masterSound = false;
      for (final width in _widths) {
        await _pumpAt(tester, width, const [MuteButton()]);
        await tester.pump();
        expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);
        expect(find.byTooltip('Səsi aç'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('tema olmadan (çılpaq MaterialApp) da qurulur', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 1600);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Wrap(children: _catalogue(reduced: true, endless: false)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('boş vəziyyətdə pumpAndSettle bitir', (tester) async {
      await _pumpAt(tester, 360, _catalogue(reduced: false, endless: false));
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.takeException(), isNull);
    });
  });

  group('Squishy', () {
    testWidgets('hər Squishy-də dəqiq bir AnimatedContainer var', (
      tester,
    ) async {
      await _pumpAt(tester, 412, _catalogue(reduced: true, endless: false));
      await tester.pumpAndSettle();

      final squishies = find.byType(Squishy).evaluate().toList();
      expect(squishies, isNotEmpty);
      for (final e in squishies) {
        expect(
          find.descendant(
            of: find.byWidget(e.widget),
            matching: find.byType(AnimatedContainer),
          ),
          findsOneWidget,
        );
      }
      // Squishy-dən kənarda heç bir ortaq widget AnimatedContainer qurmur.
      expect(
        find.byType(AnimatedContainer).evaluate().length,
        squishies.length,
      );
    });

    testWidgets('kartın adı ilə ulduzları bir çərçivədədir (test qarmağı)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Center(
            child: SizedBox(
              width: 158,
              height: 196,
              child: Squishy(
                onTap: () {},
                color: ElifbaPalette.surface,
                borderRadius: BorderRadius.circular(28),
                edge: 6,
                edgeColor: ElifbaPalette.outline,
                ringWidth: 2,
                ringColor: ElifbaPalette.outlineVariant,
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                child: const Column(
                  children: [
                    Expanded(child: AnimalStage(child: ImagePlaceholder())),
                    Text('Ayı'),
                    StarRow(filled: 1, size: 20, spacing: 1),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        find.ancestor(
          of: find.text('Ayı'),
          matching: find.byType(AnimatedContainer),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('qısa toxunuş tam basışı göstərir, sonra buraxılır', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          Center(
            child: Squishy(
              onTap: () => taps++,
              color: ElifbaPalette.primary,
              edge: 5,
              edgeColor: ElifbaPalette.primaryEdge,
              padding: const EdgeInsets.all(20),
              child: const Text('Bas'),
            ),
          ),
        ),
      );
      double dy() =>
          tester
              .widget<AnimatedContainer>(find.byType(AnimatedContainer))
              .transform!
              .getTranslation()
              .y;
      ShapeDecoration deco() =>
          tester
                  .widget<AnimatedContainer>(find.byType(AnimatedContainer))
                  .decoration!
              as ShapeDecoration;

      expect(dy(), 0);
      await tester.tap(find.text('Bas'));
      expect(taps, 1, reason: 'əməliyyat buraxılan anda dərhal işləyir');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 90));
      expect(dy(), closeTo(5, 0.01), reason: 'tam 90 ms basış');
      expect(deco().shadows!.first.offset.dy, closeTo(0, 0.01));
      await tester.pumpAndSettle();
      expect(dy(), closeTo(0, 0.001));
      expect(deco().shadows!.first.offset.dy, closeTo(5, 0.001));
      expect(tester.takeException(), isNull);
    });

    testWidgets('sürüşdürmə basışı dərhal buraxır', (tester) async {
      await tester.pumpWidget(
        _app(
          Center(
            child: Squishy(
              onTap: () {},
              color: ElifbaPalette.primary,
              edge: 5,
              padding: const EdgeInsets.all(20),
              child: const Text('Bas'),
            ),
          ),
        ),
      );
      final g = await tester.startGesture(tester.getCenter(find.text('Bas')));
      await tester.pump(const Duration(milliseconds: 150));
      await g.moveBy(const Offset(0, 80));
      await g.up();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<AnimatedContainer>(find.byType(AnimatedContainer))
            .transform!
            .getTranslation()
            .y,
        closeTo(0, 0.001),
      );
    });

    testWidgets('qeyri-aktiv: toxunuş işləmir, semantika enabled=false', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        _app(
          Center(
            child: Squishy(
              onTap: () => taps++,
              enabled: false,
              color: ElifbaPalette.primary,
              edge: 5,
              tooltip: 'Növbəti səhifə',
              padding: const EdgeInsets.all(20),
              child: const Icon(Icons.arrow_forward_rounded),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(Squishy), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(taps, 0);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Növbəti səhifə')),
        containsSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      handle.dispose();
    });
  });

  group('StarRow / StarGlyph', () {
    testWidgets('semantika etiketi və kəsmə', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          const Column(
            children: [StarRow(filled: 2), StarRow(filled: 99, total: 3)],
          ),
        ),
      );
      expect(find.bySemanticsLabel('3 ulduzdan 2'), findsOneWidget);
      expect(find.bySemanticsLabel('3 ulduzdan 3'), findsOneWidget);
      final glyphs = tester.widgetList<StarGlyph>(find.byType(StarGlyph));
      expect(glyphs.where((g) => g.filled).length, 5);
      expect(glyphs.where((g) => !g.filled).length, 1);
      expect(find.byType(AnimatedContainer), findsNothing);
      handle.dispose();
    });

    testWidgets('ElifbaStar StarGlyph-in özüdür', (tester) async {
      await tester.pumpWidget(_app(const ElifbaStar(filled: true, size: 34)));
      expect(find.byType(StarGlyph), findsOneWidget);
      expect(tester.getSize(find.byType(StarGlyph)), const Size(34, 34));
    });
  });

  group('səs düymələri', () {
    testWidgets('söndürülmüş düymə basılmır və semantikada qeyri-aktivdir', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              AudioButton(
                state: AudioButtonState.muted,
                onPressed: () => taps++,
              ),
              AudioButton(
                state: AudioButtonState.muted,
                tone: AudioTone.animal,
                size: 48,
                onPressed: () => taps++,
              ),
              AudioPillButton(
                state: AudioButtonState.muted,
                onPressed: () => taps++,
              ),
            ],
          ),
        ),
      );
      for (final s in find.byType(Squishy).evaluate().toList()) {
        await tester.tap(find.byWidget(s.widget), warnIfMissed: false);
      }
      await tester.pumpAndSettle();
      expect(taps, 0);
      expect(find.byIcon(Icons.volume_off_rounded), findsNWidgets(3));
      for (final label in ['Səs söndürülüb', 'Heyvan səsləri söndürülüb']) {
        expect(
          tester.getSemantics(find.bySemanticsLabel(label).first),
          containsSemantics(
            isButton: true,
            hasEnabledState: true,
            isEnabled: false,
          ),
        );
      }
      handle.dispose();
    });

    testWidgets('oxuyanda halqa nəbz edir, dayananda ticker qalmır', (
      tester,
    ) async {
      var state = AudioButtonState.playing;
      late StateSetter set;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, s) {
              set = s;
              return Center(child: AudioButton(state: state, onPressed: () {}));
            },
          ),
        ),
      );
      double ring() =>
          (tester
                      .widget<AnimatedContainer>(find.byType(AnimatedContainer))
                      .decoration!
                  as ShapeDecoration)
              .shadows![1]
              .spreadRadius;

      await tester.pump(const Duration(milliseconds: 600));
      expect(ring(), closeTo(6, 0.05));
      expect(find.byIcon(Icons.stop_rounded), findsOneWidget);
      expect(tester.binding.hasScheduledFrame, isTrue);

      set(() => state = AudioButtonState.ready);
      await tester.pumpAndSettle();
      expect(ring(), 0);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('azaldılmış hərəkətdə halqa sabitdir və settle bitir', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const Column(
            children: [
              AudioButton(
                state: AudioButtonState.playing,
                onPressed: null,
                reduceMotion: true,
              ),
              AudioPillButton(
                state: AudioButtonState.playing,
                onPressed: null,
                reduceMotion: true,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      final rings =
          tester
              .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
              .map((c) => (c.decoration! as ShapeDecoration).shadows![1])
              .toList();
      // onPressed null olduğu üçün düymə qeyri-aktiv görünür, halqa çəkilmir;
      // aktiv variantı yoxlayaq.
      expect(rings.every((s) => s.spreadRadius == 0), isTrue);

      await tester.pumpWidget(
        _app(
          Column(
            children: [
              AudioButton(
                state: AudioButtonState.playing,
                onPressed: () {},
                reduceMotion: true,
              ),
              AudioPillButton(
                state: AudioButtonState.playing,
                onPressed: () {},
                reduceMotion: true,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      final spreads =
          tester
              .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
              .map(
                (c) =>
                    (c.decoration! as ShapeDecoration).shadows![1].spreadRadius,
              )
              .toList();
      expect(spreads, [
        ElifbaMotion.audioRingStatic,
        ElifbaMotion.audioRingStaticPill,
      ]);
    });

    testWidgets('mute düyməsi master açarı çevirir', (tester) async {
      await tester.pumpWidget(_app(const Center(child: MuteButton())));
      expect(find.byTooltip('Səsi söndür'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.volume_up_rounded));
      await tester.pumpAndSettle();
      expect(settings.masterSound, isFalse);
      expect(find.byTooltip('Səsi aç'), findsOneWidget);
    });
  });

  group('tablar', () {
    testWidgets('seçilmiş və tamamlanmış tab semantikası', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          Row(
            children: [
              PillTab(
                label: 'Məlumat',
                icon: Icons.auto_stories_rounded,
                onTap: () {},
                selected: true,
              ),
              PillTab(
                label: 'Qidalar',
                icon: Icons.restaurant_rounded,
                onTap: () {},
                done: true,
              ),
            ],
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Məlumat')),
        containsSemantics(isSelected: true, isInMutuallyExclusiveGroup: true),
      );
      expect(find.bySemanticsLabel('Qidalar, tamamlandı'), findsOneWidget);
      expect(find.byType(CheckBadge), findsOneWidget);
      handle.dispose();
    });

    testWidgets('seçilmiş tab onTap: null ilə boz olmur; seçilməmiş olur', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          const Row(
            children: [
              PillTab(
                label: 'Məlumat',
                icon: Icons.auto_stories_rounded,
                onTap: null,
                selected: true,
              ),
              PillTab(
                label: 'Pazl',
                icon: Icons.extension_rounded,
                onTap: null,
              ),
            ],
          ),
        ),
      );
      ShapeDecoration decoOf(String label) =>
          tester
                  .widget<AnimatedContainer>(
                    find.ancestor(
                      of: find.text(label),
                      matching: find.byType(AnimatedContainer),
                    ),
                  )
                  .decoration!
              as ShapeDecoration;
      Color textColor(String label) =>
          tester.widget<Text>(find.text(label)).style!.color!;

      expect(decoOf('Məlumat').color, ElifbaPalette.secondary);
      expect(decoOf('Məlumat').shadows!.first.offset.dy, ElifbaEdge.e4);
      expect(textColor('Məlumat'), ElifbaPalette.onSecondary);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Məlumat')),
        containsSemantics(isSelected: true, isEnabled: true),
      );

      expect(decoOf('Pazl').color, ElifbaPalette.surfaceContainerHigh);
      expect(textColor('Pazl'), ElifbaPalette.onMuted);
      expect(
        tester.widget<Icon>(find.byIcon(Icons.extension_rounded)).color,
        ElifbaPalette.onMuted,
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Pazl')),
        containsSemantics(hasEnabledState: true, isEnabled: false),
      );
      handle.dispose();
    });

    testWidgets('seçim rəngi 140 ms-də keçir; ikon rəngi dəyişə bilir', (
      tester,
    ) async {
      var selected = false;
      late StateSetter set;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, s) {
              set = s;
              return Center(
                child: PillTab(
                  label: 'Bax',
                  icon: Icons.visibility_rounded,
                  onTap: () {},
                  selected: selected,
                  unselectedIconColor: ElifbaPalette.onSurfaceVariant,
                ),
              );
            },
          ),
        ),
      );
      Color face() =>
          (tester
                      .widget<AnimatedContainer>(find.byType(AnimatedContainer))
                      .decoration!
                  as ShapeDecoration)
              .color!;
      Color icon() =>
          tester.widget<Icon>(find.byIcon(Icons.visibility_rounded)).color!;

      expect(face(), ElifbaPalette.surface);
      expect(icon(), ElifbaPalette.onSurfaceVariant);
      set(() => selected = true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(face(), isNot(ElifbaPalette.surface), reason: 'keçid gedir');
      expect(face(), isNot(ElifbaPalette.secondary), reason: 'hələ bitməyib');
      await tester.pump(ElifbaMotion.selection);
      expect(face(), ElifbaPalette.secondary);
      expect(icon(), ElifbaPalette.onSecondary);
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  group('düymələr və ölçülər', () {
    testWidgets('44 enli ox 48 × 48 toxunma qutusu tutur', (tester) async {
      await tester.pumpWidget(
        _app(
          Center(
            child: ToolbarChevron(
              forward: true,
              onPressed: () {},
              tooltip: 'Növbəti heyvan',
              width: 44,
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(ToolbarChevron)), const Size(48, 48));
    });

    testWidgets('«Yenidən başla» dar yerdə üç nöqtə yox, kiçilir', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        _app(
          Center(
            child: SizedBox(
              width: 158,
              child: PillButton(
                label: 'Yenidən başla',
                icon: Icons.refresh_rounded,
                onPressed: () {},
                variant: PillButtonVariant.secondary,
                size: PillButtonSize.small,
                expand: true,
              ),
            ),
          ),
        ),
      );
      expect(
        find.descendant(
          of: find.byType(PillButton),
          matching: find.byType(FittedBox),
        ),
        findsOneWidget,
      );
      expect(tester.widget<Text>(find.text('Yenidən başla')).overflow, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tooltip 28 dp hündürlükdədir (DS)', (tester) async {
      await tester.pumpWidget(_app(const Center(child: MuteButton())));
      await tester.longPress(find.byType(MuteButton));
      await tester.pump(const Duration(milliseconds: 200));
      final box = find.ancestor(
        of: find.text('Səsi söndür'),
        matching: find.byType(DecoratedBox),
      );
      expect(tester.getSize(box.first).height, 28);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    });

    test('valideyn seqmenti: 8 dp yan boşluq, 18 dp ikon', () {
      final style = ElifbaSegmentedTheme.data.style!;
      expect(
        style.padding!.resolve({}),
        const EdgeInsets.symmetric(horizontal: 8),
      );
      expect(style.iconSize!.resolve({}), 18);
      expect(style.tapTargetSize, MaterialTapTargetSize.padded);
      expect(
        ParentButtonStyles.textCompact.padding!.resolve({}),
        const EdgeInsets.symmetric(horizontal: 16),
      );
      expect(
        ParentButtonStyles.text.padding!.resolve({}),
        const EdgeInsets.symmetric(horizontal: 18),
      );
    });

    testWidgets('yuvarlaq düzbucaqlının halqası CSS kimi r + spread-dir', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          Center(
            child: SizedBox(
              width: 56,
              height: 64,
              child: DecoratedBox(decoration: GameDecorations.tileCorrect),
            ),
          ),
        ),
      );
      final box = tester.renderObject<RenderBox>(find.byType(DecoratedBox));
      final rect = Offset.zero & box.size; // paints: lokal koordinatlar
      final face = RRect.fromRectAndRadius(
        rect,
        const Radius.circular(ElifbaRadius.r14),
      );
      expect(
        box,
        paints
          ..rrect(rrect: face.inflate(3), color: ElifbaPalette.correct)
          ..rrect(rrect: face, color: ElifbaPalette.correctContainer),
      );
      expect(face.inflate(3).tlRadiusX, ElifbaRadius.r14 + 3);
    });

    testWidgets('səhnə təpəsiz də qurulur; qida diski bütövlükdə solur', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const Column(
            children: [
              SizedBox(
                width: 142,
                height: 122,
                child: AnimalStage(
                  hill: StageHill.none,
                  child: ImagePlaceholder(),
                ),
              ),
              FoodChip(
                name: 'Quru yem',
                imagePath: 'assets/foods/quru_yem.webp',
                fed: false,
                onTap: null,
                cacheWidth: 256,
                imageHidden: true,
              ),
              SizedBox(width: 200, child: ElifbaProgressBar(value: 0.3)),
            ],
          ),
        ),
      );
      final ovals = find.descendant(
        of: find.byType(AnimalStage),
        matching: find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              w.decoration is ShapeDecoration &&
              (w.decoration as ShapeDecoration).shape is OvalBorder,
        ),
      );
      expect(ovals, findsNothing);

      final dim = tester.widget<Opacity>(
        find.descendant(
          of: find.byType(FoodChip),
          matching: find.byType(Opacity),
        ),
      );
      expect(dim.opacity, 0.35);
      final disc = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byWidget(dim),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect((disc.decoration as BoxDecoration).shape, BoxShape.circle);

      final fill = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(ElifbaProgressBar),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect(
        (fill.decoration as BoxDecoration).borderRadius,
        const BorderRadius.all(Radius.circular(3)),
      );
    });

    testWidgets('buludlar status bar-ın altından ölçülür', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 640),
            viewPadding: EdgeInsets.only(top: 30),
            padding: EdgeInsets.only(top: 30),
          ),
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: SkyBackground(style: SkyStyle.skyWithClouds),
          ),
        ),
      );
      final tops =
          tester
              .widgetList<Positioned>(
                find.descendant(
                  of: find.byType(SkyBackground),
                  matching: find.byType(Positioned),
                ),
              )
              .map((p) => p.top)
              .whereType<double>()
              .toSet();
      expect(tops, {30 + 76.0, 30 + 50.0});
    });
  });

  group('oyun rəyi', () {
    test('söz kafelinin ölçüsü 44 dp-dən kiçilmir', () {
      expect(wordTileWidth(3, 360 - 56), 56);
      expect(wordTileWidth(12, 360 - 56), 45);
      expect(wordTileHeight(45), 52);
      expect(wordTileHeight(56), 64);
      expect(wordTileWidth(12, 412 - 56), 54);
      expect(wordTileHeight(54), 62);
      expect(wordTileWidth(12, 200), ElifbaSize.minTile);
      expect(ElifbaTextStyles.tileGlyphFor(45).fontSize, 24);
      expect(ElifbaTextStyles.tileGlyphFor(56).fontSize, 26);
    });

    test('6 hərfli ad bir sətirdə qalır; dar ekranda sətir azalır', () {
      // animal.md §8.3 cədvəli: 304 = 360 dp, 356 = 412 dp kartın içi.
      final cases = <(int, double), (double, double, int)>{
        (5, 304): (56, 64, 5),
        (6, 304): (45, 52, 6),
        (12, 304): (45, 52, 6),
        (5, 356): (56, 64, 5),
        (6, 356): (54, 62, 6),
        (12, 356): (54, 62, 6),
      };
      cases.forEach((input, want) {
        final l = wordTileLayout(input.$1, input.$2);
        expect((l.tile, l.tileHeight, l.perRow), want, reason: '$input');
        expect(l.rowMax, lessThanOrEqualTo(input.$2), reason: '$input');
        expect(l.rowMax, wordRowMax(l.perRow, l.tile));
      });
      // 6 kafel 6 dp aralıqla tam sığır (5 + 1 sınmır).
      expect(wordRowMax(6, 45), 300);
      // ~350 dp-dən dar ekran (320 → 264): 44 dp-lik 6 kafel sığmır.
      final narrow = wordTileLayout(6, 264);
      expect(narrow.tile, ElifbaSize.minTile);
      expect(narrow.perRow, 5);
      expect(narrow.rowMax, lessThanOrEqualTo(264));
      expect(wordTileLayout(5, 264).perRow, 4);
      expect(wordTilesPerRow(0, 56, 304), 1, reason: 'boş sözdə mənfi en yox');
    });

    test('silkələnmənin amplitudası dəyişə bilir (yazı kartı 8 dp)', () {
      const t = 1 / 6; // sin(π/2) = 1
      expect(dampedShakeOffset(0), 0);
      expect(dampedShakeOffset(t), closeTo(6 * (1 - t), 1e-9));
      expect(
        dampedShakeOffset(t, ElifbaMotion.traceShakeAmplitude),
        closeTo(8 * (1 - t), 1e-9),
      );
    });

    testWidgets('sürüklənən kafel azaldılmış hərəkətdə əyilmir, böyümür', (
      tester,
    ) async {
      Future<int> transforms({required bool reduced}) async {
        await tester.pumpWidget(
          _app(
            Center(
              child: WordTileFace(
                state: WordTileState.dragging,
                glyph: 'A',
                width: 56,
                height: 64,
                reduceMotion: reduced,
              ),
            ),
          ),
        );
        return find
            .descendant(
              of: find.byType(WordTileFace),
              matching: find.byType(Transform),
            )
            .evaluate()
            .length;
      }

      expect(await transforms(reduced: false), 2, reason: '−5° + 1.12');
      expect(await transforms(reduced: true), 0);
      // Səhv kafelin −5°-si formadır — azaldılmışda da qalır.
      await tester.pumpWidget(
        _app(
          const Center(
            child: WordTileFace(
              state: WordTileState.wrong,
              glyph: 'A',
              width: 56,
              height: 64,
              reduceMotion: true,
            ),
          ),
        ),
      );
      expect(
        find.descendant(
          of: find.byType(WordTileFace),
          matching: find.byType(Transform),
        ),
        findsOneWidget,
      );
      // Hover slotu: #E4DEFF üz, hərf göstərilmir.
      await tester.pumpWidget(
        _app(
          const Center(
            child: WordTileFace(
              state: WordTileState.hover,
              glyph: 'A',
              width: 56,
              height: 64,
            ),
          ),
        ),
      );
      expect(find.text('A'), findsNothing);
      expect(
        tester
            .widget<Container>(
              find.descendant(
                of: find.byType(WordTileFace),
                matching: find.byType(Container),
              ),
            )
            .decoration,
        GameDecorations.slotHover,
      );
    });

    testWidgets('lövhə və bitmiş lövhə eyni layout boşluğunu saxlayır', (
      tester,
    ) async {
      expect(GameDecorations.board.padding, GameDecorations.boardDone.padding);
      expect(
        GameDecorations.boardContainerPadding +
            GameDecorations.board.padding.horizontal / 2,
        GameDecorations.boardPadding,
      );
    });

    testWidgets('pop və silkələnmə tetikdə oynayır, azaldılmışda yox', (
      tester,
    ) async {
      Object? trigger;
      bool reduced = false;
      late StateSetter set;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, s) {
              set = s;
              return Column(
                children: [
                  PopOnTrigger(
                    trigger: trigger,
                    reduceMotion: reduced,
                    child: const CheckBadge(),
                  ),
                  ShakeOnTrigger(
                    trigger: trigger,
                    reduceMotion: reduced,
                    child: const CrossBadge(),
                  ),
                ],
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      double scale() =>
          tester
              .widget<ScaleTransition>(
                find.descendant(
                  of: find.byType(PopOnTrigger),
                  matching: find.byType(ScaleTransition),
                ),
              )
              .scale
              .value;
      double shift() =>
          tester
              .widget<Transform>(
                find.descendant(
                  of: find.byType(ShakeOnTrigger),
                  matching: find.byType(Transform),
                ),
              )
              .transform
              .getTranslation()
              .x;
      expect(scale(), 1);
      expect(shift(), 0);

      set(() => trigger = 1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(scale(), greaterThan(1), reason: 'pop gedir');
      expect(shift(), isNot(0), reason: 'silkələnmə gedir');
      await tester.pumpAndSettle();
      expect(scale(), 1);
      expect(shift(), 0);

      set(() {
        reduced = true;
        trigger = 2;
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(scale(), 1, reason: 'azaldılmış hərəkətdə pop yoxdur');
      expect(shift(), 0, reason: 'azaldılmış hərəkətdə silkələnmə yoxdur');
      expect(tester.takeException(), isNull);
    });
  });

  group('təbriklər', () {
    testWidgets('səhifə içi böyük kart bir pump-dan sonra ağacdadır', (
      tester,
    ) async {
      var shown = true;
      var closed = 0;
      late StateSetter set;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, s) {
              set = s;
              return Stack(
                children: [
                  const Center(child: Text('Səhifə')),
                  if (shown)
                    Positioned.fill(
                      child: CelebrationOverlay(
                        onDismiss:
                            () => set(() {
                              shown = false;
                              closed++;
                            }),
                        card: CelebrationCard.big(
                          title: 'Tam ulduz!',
                          message: 'Ayı haqqında hər şeyi öyrəndin!',
                          action: CelebrationAction(
                            label: 'Yaşa!',
                            icon: Icons.thumb_up_rounded,
                            onPressed: () => set(() => shown = false),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Tam ulduz!'), findsOneWidget);
      expect(find.text('Ayı haqqında hər şeyi öyrəndin!'), findsOneWidget);
      // Giriş bitsin (şüalar fırlanır — pumpAndSettle YOX).
      await tester.pump(const Duration(milliseconds: 900));
      expect(
        find.descendant(
          of: find.byType(SunburstDisc),
          matching: find.byType(RotationTransition),
        ),
        findsOneWidget,
      );
      // Scrim-ə toxunmaq bağlayır.
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      expect(closed, 1);
      expect(find.text('Tam ulduz!'), findsNothing);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('kartın 10 dp yanındakı scrim zolağı da bağlayır', (
      tester,
    ) async {
      var closed = 0;
      for (final big in [false, true]) {
        closed = 0;
        await tester.pumpWidget(
          _app(
            CelebrationOverlay(
              onDismiss: () => closed++,
              card:
                  big
                      ? CelebrationCard.big(
                        title: 'Tam ulduz!',
                        message: 'Ayı haqqında hər şeyi öyrəndin!',
                        reduceMotion: true,
                        action: CelebrationAction(
                          label: 'Yaşa!',
                          icon: Icons.thumb_up_rounded,
                          onPressed: () {},
                        ),
                      )
                      : const CelebrationCard.small(reduceMotion: true),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final card = tester.getRect(find.byType(CelebrationCard));
        // Kartın özü bağlamır…
        await tester.tapAt(card.center);
        expect(closed, 0, reason: 'big=$big');
        // …kənarındakı boşluq (scroll view-in padding-i) bağlayır.
        await tester.tapAt(Offset(card.left - 10, card.center.dy));
        expect(closed, 1, reason: 'big=$big');
      }
    });

    testWidgets('route: kartın yanındakı zolaq da bağlayır', (tester) async {
      await tester.pumpWidget(
        _app(
          Builder(
            builder:
                (context) => Center(
                  child: TextButton(
                    onPressed:
                        () => showSmallWinCelebration(
                          context,
                          message: 'Pazl tamamlandı!',
                          playConfetti: false,
                        ),
                    child: const Text('Aç'),
                  ),
                ),
          ),
        ),
      );
      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();
      final card = tester.getRect(find.byType(CelebrationCard));
      await tester.tapAt(Offset(card.right + 10, card.center.dy));
      await tester.pumpAndSettle();
      expect(find.text('Pazl tamamlandı!'), findsNothing);
    });

    testWidgets('söz tapmaca kartı istənilən yerə toxunanda bağlanır', (
      tester,
    ) async {
      var closed = 0;
      await tester.pumpWidget(
        _app(
          CelebrationOverlay(
            dismissOnTapAnywhere: true,
            onDismiss: () => closed++,
            card: const CelebrationCard.small(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Təbriklər!'));
      expect(closed, 1);
    });

    testWidgets('azaldılmış hərəkətdə böyük kart sabitdir, settle bitir', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          CelebrationOverlay(
            onDismiss: () {},
            card: CelebrationCard.big(
              title: 'A hərfi tamam!',
              message: 'Yaxşı!',
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
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(SunburstDisc),
          matching: find.byType(RotationTransition),
        ),
        findsNothing,
      );
      expect(find.text('A hərfi tamam!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('route: «Yenidən» əvvəl bağlayır, sonra işləyir', (
      tester,
    ) async {
      final events = <String>[];
      await tester.pumpWidget(
        _app(
          Builder(
            builder:
                (context) => Center(
                  child: TextButton(
                    onPressed: () async {
                      await showSmallWinCelebration(
                        context,
                        message: 'Pazl tamamlandı!',
                        playConfetti: false,
                        action: CelebrationAction(
                          label: 'Yenidən',
                          icon: Icons.refresh_rounded,
                          onPressed: () => events.add('reset'),
                        ),
                      );
                      events.add('closed');
                    },
                    child: const Text('Aç'),
                  ),
                ),
          ),
        ),
      );
      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();
      expect(find.text('Pazl tamamlandı!'), findsOneWidget);
      await tester.tap(find.text('Yenidən'));
      await tester.pumpAndSettle();
      expect(find.text('Pazl tamamlandı!'), findsNothing);
      expect(events, ['reset', 'closed']);
    });

    testWidgets('route: scrim bağlayır; azaldılmış böyük təbrik', (
      tester,
    ) async {
      settings.reduceMotion = true;
      await tester.pumpWidget(
        _app(
          Builder(
            builder:
                (context) => Center(
                  child: TextButton(
                    onPressed:
                        () => showBigWinCelebration(
                          context,
                          title: 'B hərfi tamam!',
                          message: 'Bu hərflə bağlı hər şeyi etdin.',
                        ),
                    child: const Text('Aç'),
                  ),
                ),
          ),
        ),
      );
      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();
      expect(find.text('B hərfi tamam!'), findsOneWidget);
      expect(find.byType(ConfettiWidget), findsOneWidget);
      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();
      expect(find.text('B hərfi tamam!'), findsNothing);

      // «Yaşa!» da bağlayır.
      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yaşa!'));
      await tester.pumpAndSettle();
      expect(find.text('B hərfi tamam!'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('valideyn sahəsi', () {
    testWidgets('snackbar 52 dp, mətn və ✓ ilə', (tester) async {
      await tester.pumpWidget(
        _app(
          Builder(
            builder:
                (context) => Center(
                  child: TextButton(
                    onPressed:
                        () =>
                            showElifbaSnackBar(context, 'Progres sıfırlandı.'),
                    child: const Text('Göstər'),
                  ),
                ),
          ),
        ),
      );
      await tester.tap(find.text('Göstər'));
      await tester.pumpAndSettle();
      expect(find.text('Progres sıfırlandı.'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      // SnackBar-ın öz ölçüsünə 16 dp alt kənar boşluğu da daxildir.
      expect(
        tester
            .getSize(
              find
                  .descendant(
                    of: find.byType(SnackBar),
                    matching: find.byType(Material),
                  )
                  .first,
            )
            .height,
        52,
      );
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('dialoq çılpaq MaterialApp-də də düzgün enlidir', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 640);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder:
                (context) => Center(
                  child: TextButton(
                    onPressed:
                        () => showParentDialog<void>(
                          context,
                          builder:
                              (_) => const ParentDialog(
                                title: 'Bütün ulduzlar silinsin?',
                                icon: Icons.warning_rounded,
                                body: 'Bu addımı geri qaytarmaq mümkün deyil.',
                                maxWidth: ElifbaSize.gateMaxWidth,
                              ),
                        ),
                    child: const Text('Aç'),
                  ),
                ),
          ),
        ),
      );
      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();
      expect(
        tester
            .getSize(
              find
                  .descendant(
                    of: find.byType(Dialog),
                    matching: find.byType(Material),
                  )
                  .first,
            )
            .width,
        312,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('tokenlər və tema', () {
    test('lowerOf: açıq cədvəl, I → ı, İ → i', () {
      expect(AppConfig.lowerOf('I'), 'ı');
      expect(AppConfig.lowerOf('İ'), 'i');
      expect(AppConfig.lowerOf('Ə'), 'ə');
      final lowers = AppConfig.alphabet.map(AppConfig.lowerOf).toSet();
      expect(lowers.length, 32, reason: 'hər hərfin öz kiçik forması var');
      for (final l in AppConfig.alphabet) {
        expect(AppConfig.lowerOf(l), isNot(l));
        expect(AppConfig.lowerOf(l).length, 1);
      }
    });

    test('hərf dəstləri: letters[i % 6] və tam bitmiş üz', () {
      expect(ElifbaPalette.letterSetFor('A').name, 'Lavanda');
      expect(ElifbaPalette.letterSetFor('B').name, 'Çəhrayı');
      expect(ElifbaPalette.letterSetFor('Ç').name, 'Səma');
      expect(ElifbaPalette.letterSetFor('Q').name, 'Nanə');
      expect(ElifbaPalette.letterSetFor('E').name, 'Şaftalı');
      expect(ElifbaPalette.letterSetFor('Z').name, 'Çəhrayı');
      final done = ElifbaColors.light.letterSetFor('A', complete: true);
      expect(done.tint, ElifbaPalette.complete);
      expect(done.edge, ElifbaPalette.completeEdge);
      expect(done.deep, ElifbaPalette.letterSets[0].deep);
    });

    testWidgets('ElifbaColors.of temasız da işləyir', (tester) async {
      late ElifbaColors bare;
      late ElifbaColors themed;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (c) {
              bare = ElifbaColors.of(c);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (c) {
              themed = ElifbaColors.of(c);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(bare, same(ElifbaColors.light));
      expect(themed.star, ElifbaPalette.star);
      final copy = themed.copyWith(star: const Color(0xFF000000));
      expect(copy.star, const Color(0xFF000000));
      expect(copy.skyTop, themed.skyTop);
      expect(themed.lerp(copy, 1).star, const Color(0xFF000000));
      expect(themed.lerp(null, 0.5), same(themed));
    });

    test('ElifbaTheme.light: açıq rollar, şəffaf tint, sıfır hərf aralığı', () {
      final t = ElifbaTheme.light();
      expect(t.colorScheme.surfaceTint, const Color(0x00000000));
      expect(t.colorScheme.primary, ElifbaPalette.primary);
      expect(t.extension<ElifbaColors>(), isNotNull);
      expect(t.textTheme.displayLarge!.fontFamily, 'Comfortaa');
      expect(t.textTheme.bodyLarge!.fontFamily, 'Andika');
      for (final s in [
        t.textTheme.bodyLarge,
        t.textTheme.labelLarge,
        t.textTheme.labelSmall,
        t.textTheme.titleMedium,
      ]) {
        expect(s!.letterSpacing, 0);
        expect(s.leadingDistribution, TextLeadingDistribution.even);
      }
      expect(
        t.appBarTheme.systemOverlayStyle!.statusBarIconBrightness,
        Brightness.dark,
      );
      expect(t.dialogTheme.barrierColor, ElifbaPalette.scrim55);
    });

    test('ElifbaMotion.reduced ayarı oxuyur', () {
      final s = AppSettings.instance;
      expect(ElifbaMotion.reduced, isFalse);
      s.reduceMotion = true;
      expect(ElifbaMotion.reduced, isTrue);
      expect(ElifbaMotion.isReduced(false), isFalse);
      s.reduceMotion = false;
      expect(ElifbaMotion.isReduced(), isFalse);
    });

    testWidgets('tətbiq mətn miqyasını 1.3-ə qədər kəsir', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(const MyApp());
      await tester.pump();
      final context = tester.element(find.byType(Scaffold).first);
      expect(MediaQuery.textScalerOf(context).scale(10), closeTo(13, 0.001));
    });
  });
}
