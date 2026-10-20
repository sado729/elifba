// Ortaq dizayn təməlinin vizual kataloqu (əl ilə yoxlama üçün).
//
// `test/`-də DEYİL, ona görə adi `flutter test` onu işlətmir. Belə işlədin:
//
//   flutter test tool/foundation_gallery_test.dart
//
// Real şriftləri (assets/fonts Comfortaa/Andika və Flutter SDK-dan
// MaterialIcons) yükləyir və hər bölməni 360 dp endə PNG kimi
// `GALLERY_OUT` qovluğuna (yoxdursa `build/foundation_gallery/`) yazır.
// Nəticə dizayn sisteminin komponent vərəqi ilə gözlə müqayisə edilir.
// Bu harness `AudioPlayer` qurmur, ona görə `tester.runAsync` təhlükəsizdir.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:elifba/theme/theme.dart';
import 'package:elifba/widgets/audio_button.dart';
import 'package:elifba/widgets/badges.dart';
import 'package:elifba/widgets/celebration.dart';
import 'package:elifba/widgets/elifba_card.dart';
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
import 'package:elifba/core/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_drawing/path_drawing.dart';

const double _width = 360;
const double _pixelRatio = 2;

String get _outDir {
  final env = Platform.environment['GALLERY_OUT'];
  if (env != null && env.isNotEmpty) return env;
  return 'build/foundation_gallery';
}

/// Flutter SDK-nın kökü: `FLUTTER_ROOT`, yoxdursa test icraçısının yolundan.
String? _flutterRoot() {
  final env = Platform.environment['FLUTTER_ROOT'];
  if (env != null && env.isNotEmpty) return env;
  var dir = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 8; i++) {
    final probe = Directory(
      '${dir.path}${Platform.pathSeparator}bin${Platform.pathSeparator}cache',
    );
    if (probe.existsSync()) return dir.path;
    dir = dir.parent;
  }
  return null;
}

Future<ByteData> _bytes(String path) async =>
    ByteData.sublistView(await File(path).readAsBytes());

Future<void> _loadFonts() async {
  final comfortaa = FontLoader('Comfortaa')
    ..addFont(_bytes('assets/fonts/Comfortaa-Bold.ttf'));
  final andika =
      FontLoader('Andika')
        ..addFont(_bytes('assets/fonts/Andika-Regular.ttf'))
        ..addFont(_bytes('assets/fonts/Andika-Bold.ttf'));
  await comfortaa.load();
  await andika.load();
  final root = _flutterRoot();
  if (root == null) return;
  final sep = Platform.pathSeparator;
  final icons = File(
    '$root${sep}bin${sep}cache${sep}artifacts${sep}material_fonts$sep'
    'materialicons-regular.otf',
  );
  if (icons.existsSync()) {
    await (FontLoader('MaterialIcons')..addFont(_bytes(icons.path))).load();
  }
}

/// Bölmənin başlığı (DS vərəqindəki kimi kiçik monospace yox — Andika).
class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: 'Andika',
        fontSize: 11,
        height: 14 / 11,
        color: ElifbaPalette.onSurfaceVariant,
      ),
    ),
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 10),
    child: Text(
      text,
      style: ElifbaTypography.textTheme.titleMedium!.copyWith(
        color: ElifbaPalette.onSurface,
      ),
    ),
  );
}

/// Bir nümunə + altında etiket.
Widget _sample(String label, Widget child) =>
    Column(mainAxisSize: MainAxisSize.min, children: [child, _Label(label)]);

Widget _wrap(List<Widget> children, {double spacing = 14}) => Wrap(
  spacing: spacing,
  runSpacing: 18,
  crossAxisAlignment: WrapCrossAlignment.end,
  children: children,
);

final _sectionKey = GlobalKey();

Future<void> _render(
  WidgetTester tester,
  String name,
  Widget body, {
  double height = 2400,
  Future<void> Function()? beforeCapture,
  List<String> precache = const [],
  Color background = const Color(0xFFFFFDFB),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(_width, height);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ElifbaTheme.light(),
      home: Scaffold(
        backgroundColor: background,
        // Hündürlük məhdud deyil: bölmə öz məzmunu qədər olsun.
        body: SingleChildScrollView(
          child: RepaintBoundary(
            key: _sectionKey,
            child: ColoredBox(
              color: background,
              child: SizedBox(
                width: _width,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: body,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  if (precache.isNotEmpty) {
    final context = tester.element(find.byKey(_sectionKey));
    await tester.runAsync(() async {
      for (final p in precache) {
        final parts = p.split('@');
        final provider = ResizeImage(
          AssetImage(parts[0]),
          width: int.parse(parts[1]),
        );
        await precacheImage(provider, context);
      }
    });
  }
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1000));
  if (beforeCapture != null) await beforeCapture();

  final boundary =
      tester.renderObject(find.byKey(_sectionKey)) as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final ui.Image image = await boundary.toImage(pixelRatio: _pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final dir = Directory(_outDir)..createSync(recursive: true);
    File(
      '${dir.path}${Platform.pathSeparator}$name.png',
    ).writeAsBytesSync(data!.buffer.asUint8List());
  });
  expect(tester.takeException(), isNull);
  await tester.pumpWidget(const SizedBox());
}

/// Bir elementi "basılı" saxlayır (toxunuş buraxılmır), şəkil çəkilir.
Future<TestGesture> _hold(WidgetTester tester, Finder f) async {
  final g = await tester.startGesture(tester.getCenter(f));
  await tester.pump(const Duration(milliseconds: 150));
  await tester.pump(const Duration(milliseconds: 150));
  return g;
}

/// DS kartındakı «B» yazı nümunəsi (yazı kartı üçün).
class _BGlyph extends CustomPainter {
  static final Path _b = parseSvgPathData(
    'M38 18V100M38 18H60Q78 18 78 37Q78 56 60 56H38M38 56H64Q84 56 84 78Q84 '
    '100 64 100H38',
  );

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 110, size.height / 120);
    final road =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 18
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = ElifbaPalette.surface;
    canvas.drawPath(_b, road);
    canvas.drawPath(
      dashPath(_b, dashArray: CircularIntervalList<double>([4, 5])),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = ElifbaPalette.traceCentre,
    );
    canvas.drawCircle(
      const Offset(38, 18),
      9,
      Paint()..color = ElifbaPalette.correct,
    );
  }

  @override
  bool shouldRepaint(_BGlyph old) => false;
}

void main() {
  setUpAll(_loadFonts);
  void resetSettings() {
    AppSettings.instance
      ..masterSound = true
      ..reduceMotion = false;
  }

  setUp(resetSettings);
  tearDown(resetSettings);

  testWidgets('01 düymələr', (tester) async {
    final pressedPrimary = GlobalKey();
    final pressedSecondary = GlobalKey();
    TestGesture? g1;
    TestGesture? g2;
    await _render(
      tester,
      '01_buttons',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Heading('Əsas · primary'),
          _wrap([
            _sample(
              'L default',
              PillButton(
                label: 'Yaşa!',
                icon: Icons.thumb_up_rounded,
                size: PillButtonSize.large,
                onPressed: () {},
              ),
            ),
            _sample(
              'L pressed',
              PillButton(
                key: pressedPrimary,
                label: 'Yaşa!',
                icon: Icons.thumb_up_rounded,
                size: PillButtonSize.large,
                onPressed: () {},
              ),
            ),
            _sample(
              'M disabled',
              const PillButton(
                label: 'Yenidən',
                icon: Icons.refresh_rounded,
                onPressed: null,
              ),
            ),
          ]),
          const _Heading('İkinci · secondary'),
          _wrap([
            _sample(
              'M default',
              PillButton(
                label: 'Yenidən başla',
                icon: Icons.refresh_rounded,
                variant: PillButtonVariant.secondary,
                onPressed: () {},
              ),
            ),
            _sample(
              'M pressed',
              PillButton(
                key: pressedSecondary,
                label: 'Yenidən başla',
                icon: Icons.refresh_rounded,
                variant: PillButtonVariant.secondary,
                onPressed: () {},
              ),
            ),
          ]),
          const _Heading('S · tonal · selected'),
          _wrap([
            _sample(
              'S secondary',
              PillButton(
                label: 'Yenidən başla',
                icon: Icons.refresh_rounded,
                variant: PillButtonVariant.secondary,
                size: PillButtonSize.small,
                onPressed: () {},
              ),
            ),
            _sample(
              'S expand 158 · scaleDown',
              SizedBox(
                width: 158,
                child: PillButton(
                  label: 'Yenidən başla',
                  icon: Icons.refresh_rounded,
                  variant: PillButtonVariant.secondary,
                  size: PillButtonSize.small,
                  expand: true,
                  onPressed: () {},
                ),
              ),
            ),
            _sample(
              'S tonal',
              PillButton(
                label: 'İpucu',
                icon: Icons.lightbulb_rounded,
                variant: PillButtonVariant.tonal,
                size: PillButtonSize.small,
                onPressed: () {},
              ),
            ),
            _sample(
              'M selected',
              PillButton(
                label: 'Seçilib',
                variant: PillButtonVariant.selected,
                onPressed: () {},
              ),
            ),
          ]),
          const _Heading('Valideyn · text / filled / destructive'),
          _wrap(spacing: 8, [
            TextButton(
              style: ParentButtonStyles.text,
              onPressed: () {},
              child: const Text('Ləğv et'),
            ),
            FilledButton(
              style: ParentButtonStyles.filled,
              onPressed: () {},
              child: const Text('Bağla'),
            ),
            FilledButton.icon(
              style: ParentButtonStyles.destructive,
              onPressed: () {},
              icon: const Icon(Icons.delete_rounded, size: 20),
              label: const Text('Bəli, sil'),
            ),
          ]),
        ],
      ),
      beforeCapture: () async {
        g1 = await _hold(tester, find.byKey(pressedPrimary));
        g2 = await _hold(tester, find.byKey(pressedSecondary));
      },
    );
    await g1?.up();
    await g2?.up();
  });

  testWidgets('02 ikon düymələri', (tester) async {
    await _render(
      tester,
      '02_icon_buttons',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Heading('İkon düymələri'),
          _wrap(spacing: 18, [
            _sample(
              'nav 64 · default',
              NavRoundButton(
                icon: Icons.arrow_forward_rounded,
                onPressed: () {},
                tooltip: 'Növbəti səhifə',
              ),
            ),
            _sample(
              'nav 64 · disabled',
              const NavRoundButton(
                icon: Icons.arrow_back_rounded,
                onPressed: null,
                tooltip: 'Əvvəlki səhifə',
              ),
            ),
            _sample('toolbar 48 · Geri', const ToolbarBackButton()),
            _sample(
              'toolbar · disabled',
              const ToolbarChevron(
                forward: true,
                onPressed: null,
                tooltip: 'Növbəti hərf',
              ),
            ),
            _sample(
              'chevron',
              ToolbarChevron(
                forward: false,
                onPressed: () {},
                tooltip: 'Əvvəlki hərf',
              ),
            ),
            _sample('mute · səs açıq', const MuteButton()),
            _sample('Ayarlar (sakit)', QuietIconButton(onPressed: () {})),
            _sample('parent · Geri', const ParentBackButton()),
          ]),
        ],
      ),
    );
    AppSettings.instance.masterSound = false;
    await _render(
      tester,
      '02b_mute_off',
      _wrap([_sample('mute · söndürülüb', const MuteButton())]),
    );
  });

  testWidgets('03 səs düymələri', (tester) async {
    await _render(
      tester,
      '03_audio',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Heading('Səs düyməsi · 3 vəziyyət (56)'),
          _wrap(spacing: 18, [
            _sample(
              'ready',
              AudioButton(state: AudioButtonState.ready, onPressed: () {}),
            ),
            _sample(
              'playing (azaldılmış: 5)',
              AudioButton(
                state: AudioButtonState.playing,
                onPressed: () {},
                reduceMotion: true,
              ),
            ),
            _sample(
              'muted',
              AudioButton(state: AudioButtonState.muted, onPressed: () {}),
            ),
            _sample(
              'heyvan · ready',
              AudioButton(
                state: AudioButtonState.ready,
                tone: AudioTone.animal,
                size: 48,
                onPressed: () {},
              ),
            ),
            _sample(
              'heyvan · muted',
              AudioButton(
                state: AudioButtonState.muted,
                tone: AudioTone.animal,
                size: 48,
                onPressed: () {},
              ),
            ),
          ]),
          const _Heading('48 dp (hərf kartı)'),
          _wrap(spacing: 22, [
            for (final s in AudioButtonState.values)
              _sample(
                s.name,
                AudioButton(
                  state: s,
                  size: 48,
                  onPressed: () {},
                  reduceMotion: true,
                ),
              ),
          ]),
          const _Heading('«Dinlə» pill'),
          _wrap(spacing: 18, [
            for (final s in AudioButtonState.values)
              _sample(
                s.name,
                AudioPillButton(state: s, onPressed: () {}, reduceMotion: true),
              ),
          ]),
        ],
      ),
    );
  });

  testWidgets('04 tablar və çiplər', (tester) async {
    final pressedChip = GlobalKey();
    TestGesture? g;
    await _render(
      tester,
      '04_tabs_chips',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Heading('Pill tablar'),
          _wrap(spacing: 8, [
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
            PillTab(
              label: 'Söz tapmaca',
              icon: Icons.abc_rounded,
              onTap: () {},
            ),
            PillTab(label: 'Pazl', icon: Icons.extension_rounded, onTap: () {}),
            PillTab(
              label: 'Qidalar',
              icon: Icons.restaurant_rounded,
              onTap: () {},
              selected: true,
              done: true,
            ),
          ]),
          const _Heading('Səviyyə · rejim (expand)'),
          Row(
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
                    onTap: () {},
                    selected: n == 4,
                    expand: true,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final (i, l, ic) in [
                (0, 'Bax', Icons.visibility_rounded),
                (1, 'İzlə', Icons.touch_app_rounded),
                (2, 'Təkrarla', Icons.edit_rounded),
              ]) ...[
                if (i != 0) const SizedBox(width: 8),
                Expanded(
                  child: PillTab(
                    label: l,
                    icon: ic,
                    onTap: () {},
                    selected: i == 1,
                    expand: true,
                    unselectedIconColor: ElifbaPalette.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          const _Heading('Qida çipi · rest / pressed / uçur / fed'),
          _wrap(spacing: 10, [
            FoodChip(
              name: 'Bal',
              imagePath: 'assets/foods/bal.webp',
              fed: false,
              onTap: () {},
              cacheWidth: 256,
              imageTint: ElifbaPalette.foodDiscTint(0),
            ),
            FoodChip(
              key: pressedChip,
              name: 'Giləmeyvə',
              imagePath: 'assets/foods/gilemeyve.webp',
              fed: false,
              onTap: () {},
              cacheWidth: 256,
              imageTint: ElifbaPalette.foodDiscTint(1),
            ),
            FoodChip(
              name: 'Quru yem',
              imagePath: 'assets/foods/quru_yem.webp',
              fed: false,
              onTap: () {},
              cacheWidth: 256,
              imageTint: ElifbaPalette.foodDiscTint(2),
              imageHidden: true,
            ),
            FoodChip(
              name: 'Balıq',
              imagePath: 'assets/foods/baliq.webp',
              fed: true,
              onTap: () {},
              cacheWidth: 256,
            ),
          ]),
        ],
      ),
      precache: const [
        'assets/foods/bal.webp@256',
        'assets/foods/gilemeyve.webp@256',
        'assets/foods/quru_yem.webp@256',
        'assets/foods/baliq.webp@256',
      ],
      beforeCapture: () async {
        g = await _hold(tester, find.byKey(pressedChip));
      },
    );
    await g?.up();
  });

  testWidgets('05 kartlar', (tester) async {
    Widget animalCard(String name, String image, int stars) {
      final complete = stars == 3;
      return SizedBox(
        width: 158,
        height: 196,
        child: Squishy(
          onTap: () {},
          borderRadius: BorderRadius.circular(28),
          color: complete ? ElifbaPalette.complete : ElifbaPalette.surface,
          ringWidth: 2,
          ringColor:
              complete
                  ? ElifbaPalette.completeEdge
                  : ElifbaPalette.outlineVariant,
          edge: 6,
          edgeColor:
              complete ? ElifbaPalette.completeEdge : ElifbaPalette.outline,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          child: Column(
            children: [
              Expanded(
                child: AnimalStage(
                  complete: complete,
                  hill: image.isEmpty ? StageHill.none : StageHill.card,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
                    child:
                        image.isEmpty
                            ? const ImagePlaceholder()
                            : Image.asset(
                              image,
                              fit: BoxFit.contain,
                              cacheWidth: 400,
                              errorBuilder:
                                  (context, error, stack) =>
                                      const ImagePlaceholder(),
                            ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                maxLines: 1,
                style: ElifbaTextStyles.cardName.copyWith(
                  color: ElifbaPalette.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              StarRow(filled: stars, size: 20, spacing: 1),
            ],
          ),
        ),
      );
    }

    final writeCard = SizedBox(
      width: 158,
      height: 196,
      child: Squishy(
        onTap: () {},
        borderRadius: BorderRadius.circular(28),
        color: ElifbaPalette.secondaryContainer,
        pressDepth: 3,
        child: CustomPaint(
          foregroundPainter: const DashedRRectPainter(
            color: ElifbaPalette.secondary,
            strokeWidth: 2.5,
            radius: 28,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: SizedBox(
                        width: 110,
                        height: 120,
                        child: CustomPaint(painter: _BGlyph()),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const StarGlyph(filled: false, size: 22),
                        const SizedBox(width: 6),
                        Text(
                          'Yaz',
                          style: ElifbaTextStyles.buttonM.copyWith(
                            color: ElifbaPalette.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Positioned(
                top: 10,
                right: 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ElifbaPalette.secondary,
                  ),
                  child: SizedBox.square(
                    dimension: 30,
                    child: Icon(
                      Icons.draw_rounded,
                      size: 18,
                      color: ElifbaPalette.surface,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Widget infoCard({required bool open}) => Stack(
      clipBehavior: Clip.none,
      children: [
        ElifbaCard.section(
          padding: EdgeInsets.fromLTRB(76, 14, 16, open ? 16 : 14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        open ? 'B hərfi haqqında' : 'B hərfi haqqında oxu',
                        style: ElifbaTextStyles.infoCardTitle.copyWith(
                          color: ElifbaPalette.onSurface,
                        ),
                      ),
                    ),
                    Icon(
                      open
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: ElifbaPalette.secondary,
                    ),
                  ],
                ),
                if (open) ...[
                  const SizedBox(height: 8),
                  Text(
                    'B hərfi balaca baloncuklar kimi görünür – böyük B-də iki '
                    'dairə var!',
                    style: ElifbaTypography.textTheme.bodyMedium!.copyWith(
                      color: ElifbaPalette.onSurface,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Positioned(
          left: 10,
          top: 8,
          child: AudioButton(
            state: open ? AudioButtonState.playing : AudioButtonState.ready,
            size: 48,
            onPressed: () {},
            reduceMotion: true,
          ),
        ),
      ],
    );

    await _render(
      tester,
      '05_cards',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Heading('Kartlar'),
          _wrap(spacing: 12, [
            _sample('yazı kartı', writeCard),
            _sample(
              'heyvan kartı · 1 ulduz',
              animalCard('Ayı', 'assets/images/a/ayi.webp', 1),
            ),
            _sample(
              'tam (3 ulduz)',
              animalCard('Zürafə', 'assets/images/z/zurafe.webp', 3),
            ),
            _sample('şəkil yoxdur', animalCard('Pinqvin', '', 0)),
          ]),
          const _Heading('Məlumat kartı · bağlı / açıq + oxuyur'),
          infoCard(open: false),
          const SizedBox(height: 14),
          infoCard(open: true),
          const SizedBox(height: 18),
          const _Heading('Boş hərf kartı'),
          const ElifbaCard(
            radius: 24,
            edge: 0,
            padding: EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: Row(
              children: [
                ImagePlaceholder(size: 72, cloudColor: ElifbaPalette.stageSky),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Bu hərflə başlayan heyvan yoxdur, amma hərfi yaza bilərsən!',
                    style: ElifbaTextStyles.emptyState,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      precache: const [
        'assets/images/a/ayi.webp@400',
        'assets/images/z/zurafe.webp@400',
      ],
    );
  });

  testWidgets('06 ulduzlar və tərəqqi', (tester) async {
    Widget heyvanlar(int done, int total, int stars) {
      final complete = done == total;
      return Row(
        children: [
          Text(
            'Heyvanlar',
            style: ElifbaTypography.textTheme.titleMedium!.copyWith(
              color: ElifbaPalette.onSurface,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElifbaProgressBar(value: done / total, complete: complete),
          ),
          const SizedBox(width: 10),
          StarRow(filled: stars, size: 18),
          const SizedBox(width: 10),
          if (complete) ...[
            const Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: ElifbaPalette.correct,
            ),
            const SizedBox(width: 3),
            Text(
              'Tamam!',
              style: ElifbaTextStyles.counter.copyWith(
                color: ElifbaPalette.onCorrectContainer,
              ),
            ),
          ] else
            Text(
              '$done/$total',
              style: ElifbaTextStyles.counter.copyWith(
                color: ElifbaPalette.onSurfaceVariant,
              ),
            ),
        ],
      );
    }

    await _render(
      tester,
      '06_stars_progress',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Heading('Ulduz sırası'),
          for (var i = 0; i <= 3; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(width: 24, child: Text('$i')),
                  StarRow(filled: i, size: 26, spacing: 4),
                ],
              ),
            ),
          const _Heading('«Heyvanlar» sırası + progres'),
          heyvanlar(9, 30, 1),
          const SizedBox(height: 18),
          heyvanlar(30, 30, 3),
          const _Heading('Tək ulduzlar · nişanlar'),
          _wrap(spacing: 16, [
            _sample('22', const StarGlyph(filled: true, size: 22)),
            _sample('34', const StarGlyph(filled: false, size: 34)),
            _sample(
              '40 · 1.4',
              const StarGlyph(filled: true, size: 40, strokeWidth: 1.4),
            ),
            _sample('✓ 20', const CheckBadge()),
            _sample('✕ 22', const CrossBadge(size: 22)),
            _sample('✓ 32 · 3', const CheckBadge(size: 32, ringWidth: 3)),
            _sample(
              '✓ 18 · 0',
              const ColoredBox(
                color: Color(0xFFC9BFA8),
                child: Padding(
                  padding: EdgeInsets.all(6),
                  child: CheckBadge(size: 18, ringWidth: 0),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  });

  testWidgets('07 oyun rəyi', (tester) async {
    await _render(
      tester,
      '07_game',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Heading('Oyun rəyi · kafel, slot, pazl parçası'),
          _wrap(spacing: 22, [
            _sample(
              'boş slot',
              const WordTileFace(
                state: WordTileState.empty,
                width: 48,
                height: 56,
              ),
            ),
            _sample(
              'hover',
              const WordTileFace(
                state: WordTileState.hover,
                width: 48,
                height: 56,
              ),
            ),
            _sample(
              'kafel',
              const WordTileFace(
                state: WordTileState.rest,
                glyph: 'ı',
                width: 48,
                height: 56,
              ),
            ),
            _sample(
              'sürüklənir',
              const WordTileFace(
                state: WordTileState.dragging,
                glyph: 'y',
                width: 48,
                height: 56,
              ),
            ),
            _sample(
              'doğru',
              const WordTileFace(
                state: WordTileState.correct,
                glyph: 'A',
                width: 48,
                height: 56,
              ),
            ),
            _sample(
              'səhv',
              const WordTileFace(
                state: WordTileState.wrong,
                glyph: 'z',
                width: 48,
                height: 56,
              ),
            ),
          ]),
          const SizedBox(height: 18),
          _wrap(spacing: 22, [
            _sample(
              'pazl · doğru',
              Stack(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Color(0xFFC9BFA8),
                      borderRadius: BorderRadius.all(Radius.circular(6)),
                    ),
                    foregroundDecoration: GameDecorations.cellCorrect,
                  ),
                  const Positioned(
                    right: 3,
                    bottom: 3,
                    child: CheckBadge(size: 18, ringWidth: 0),
                  ),
                ],
              ),
            ),
            _sample(
              'pazl · səhv',
              CustomPaint(
                foregroundPainter: GameDecorations.cellWrongOutline,
                child: Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: Color(0xFFA89F8E),
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                      ),
                      foregroundDecoration: GameDecorations.cellWrong,
                    ),
                    const Positioned(
                      right: 3,
                      bottom: 3,
                      child: CrossBadge(size: 18, ringWidth: 0),
                    ),
                  ],
                ),
              ),
            ),
            _sample(
              'boş xana',
              Container(
                width: 60,
                height: 60,
                decoration: GameDecorations.cellEmpty,
              ),
            ),
            _sample(
              'lövhə · bitdi',
              Container(
                width: 60,
                height: 60,
                decoration: GameDecorations.boardDone,
              ),
            ),
          ]),
          const _Heading('Söz · 6 hərf, 360 dp (bir sətir)'),
          Builder(
            builder: (context) {
              final l = wordTileLayout(6, 360 - 56);
              return ConstrainedBox(
                constraints: BoxConstraints(maxWidth: l.rowMax + 0.5),
                child: Wrap(
                  spacing: GameDecorations.wordGap,
                  runSpacing: GameDecorations.wordRunGap,
                  children: [
                    for (var i = 0; i < 6; i++)
                      WordTileFace(
                        state:
                            i < 2 ? WordTileState.correct : WordTileState.rest,
                        glyph: 'Pələng'[i],
                        width: l.tile,
                        height: l.tileHeight,
                      ),
                  ],
                ),
              );
            },
          ),
          const _Heading('Söz · 12 hərf, 360 dp'),
          Builder(
            builder: (context) {
              final w = wordTileWidth(12, 360 - 56);
              final h = wordTileHeight(w);
              return Wrap(
                spacing: 6,
                runSpacing: 10,
                children: [
                  for (var i = 0; i < 12; i++)
                    WordTileFace(
                      state:
                          i < 3
                              ? WordTileState.correct
                              : (i == 3
                                  ? WordTileState.wrong
                                  : WordTileState.empty),
                      glyph: 'Qarışqayeyən'[i],
                      width: w,
                      height: h,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  });

  testWidgets('08 valideyn', (tester) async {
    await _render(
      tester,
      '08_parent',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ParentSectionHeader('Səs', first: true),
          const SizedBox(height: 8),
          ParentGroup(
            children: [
              SwitchListTile(
                value: true,
                onChanged: (_) {},
                secondary: const Icon(Icons.volume_up_rounded, size: 22),
                title: const Text('Bütün səslər'),
                subtitle: const Text('Tətbiqdəki bütün səsləri susdurur'),
              ),
              SwitchListTile(
                value: false,
                onChanged: (_) {},
                secondary: const Icon(Icons.pets_rounded, size: 22),
                title: const Text('Heyvan səsləri'),
              ),
              SwitchListTile(
                value: true,
                onChanged: null,
                secondary: const Icon(
                  Icons.record_voice_over_outlined,
                  size: 22,
                  color: ElifbaPalette.parentDisabledIcon,
                ),
                title: const Text('İzah və nəqletmə'),
                subtitle: const Text('Hərf və heyvan haqqında danışıq'),
              ),
              SwitchListTile(
                value: false,
                onChanged: null,
                secondary: const Icon(
                  Icons.music_note_outlined,
                  size: 22,
                  color: ElifbaPalette.parentDisabledIcon,
                ),
                title: const Text('Effektlər'),
                subtitle: const Text('Klik, qalibiyyət, səhifə çevirmə'),
              ),
            ],
          ),
          const ParentSectionHeader('Oyun'),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 3, label: Text('3 × 3')),
              ButtonSegment(value: 4, label: Text('4 × 4')),
              ButtonSegment(value: 5, label: Text('5 × 5')),
            ],
            selected: const {3},
            onSelectionChanged: (_) {},
          ),
          const SizedBox(height: 18),
          ColoredBox(
            color: const Color(0xFF8E8AA6),
            child: SizedBox(
              height: 380,
              child: ParentDialog(
                icon: Icons.warning_rounded,
                title: 'Bütün ulduzlar silinsin?',
                body:
                    'Yığılmış 41 ulduz və tamamlanmış bütün bölmələr '
                    'silinəcək. Bu addımı geri qaytarmaq mümkün deyil.',
                maxWidth: ElifbaSize.gateMaxWidth,
                actions: [
                  TextButton(
                    style: ParentButtonStyles.text,
                    onPressed: () {},
                    child: const Text('Ləğv et'),
                  ),
                  FilledButton(
                    style: ParentButtonStyles.destructive,
                    onPressed: () {},
                    child: const Text('Bəli, sil'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 90,
            child: ScaffoldMessenger(
              child: Builder(
                builder:
                    (context) => Scaffold(
                      backgroundColor: ElifbaPalette.surfaceContainerLow,
                      body: Builder(
                        builder: (context) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              elifbaSnackBar('Progres sıfırlandı.'),
                            );
                          });
                          return const SizedBox.expand();
                        },
                      ),
                    ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Builder(
              builder: (context) {
                final t = Theme.of(context).tooltipTheme;
                return ConstrainedBox(
                  constraints: t.constraints!,
                  child: DecoratedBox(
                    decoration: t.decoration!,
                    child: Padding(
                      padding: t.padding!,
                      child: Text('Səsi söndür', style: t.textStyle),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      background: ElifbaPalette.surfaceContainerLow,
    );
  });

  testWidgets('09 təbriklər', (tester) async {
    Widget frame(Widget card, {bool big = false}) => SizedBox(
      width: 156,
      height: 255,
      child: FittedBox(
        child: SizedBox(
          width: 280,
          height: 460,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: SkyBackground.skyGradient,
                  ),
                ),
                const ColoredBox(color: ElifbaPalette.scrim55),
                Center(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, big ? 64 : 0, 16, 0),
                    child: card,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final retry = CelebrationAction(
      label: 'Yenidən',
      icon: Icons.refresh_rounded,
      onPressed: () {},
    );
    final yasa = CelebrationAction(
      label: 'Yaşa!',
      icon: Icons.thumb_up_rounded,
      onPressed: () {},
    );
    await _render(
      tester,
      '09_celebrations',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Heading('Təbrik ailəsi'),
          _wrap(spacing: 16, [
            _sample(
              'Kiçik qələbə',
              frame(
                CelebrationCard.small(
                  message: 'Pazl tamamlandı!',
                  action: retry,
                ),
              ),
            ),
            _sample(
              'Kiçik · azaldılmış',
              frame(
                CelebrationCard.small(
                  message: 'Pazl tamamlandı!',
                  action: retry,
                  reduceMotion: true,
                ),
              ),
            ),
            _sample(
              'Böyük qələbə',
              frame(
                CelebrationCard.big(
                  title: 'Tam ulduz!',
                  message: 'Ayı haqqında hər şeyi öyrəndin!',
                  action: yasa,
                ),
                big: true,
              ),
            ),
            _sample(
              'Böyük · azaldılmış',
              frame(
                CelebrationCard.big(
                  title: 'Tam ulduz!',
                  message: 'Ayı haqqında hər şeyi öyrəndin!',
                  action: yasa,
                  reduceMotion: true,
                ),
                big: true,
              ),
            ),
          ]),
        ],
      ),
    );
  });

  testWidgets('10 maskot, halqa, fon', (tester) async {
    await _render(
      tester,
      '10_mascot_sky',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Heading('Günəş maskotu'),
          _wrap(spacing: 18, [
            _sample('idle 60', const SunMascot(size: 60)),
            _sample('cheer 100', const SunMascot.cheer()),
            _sample('sleepy 92', const SunMascot.sleepy()),
            _sample(
              'sleepy 72 · #ECE7FF',
              const ColoredBox(
                color: ElifbaPalette.surface,
                child: SunMascot.sleepy(
                  size: 72,
                  cloudColor: ElifbaPalette.stageSky,
                ),
              ),
            ),
          ]),
          const _Heading('Günəş halqası'),
          _wrap(spacing: 18, [
            _sample('statik 96', const SunburstDisc(size: 96)),
            _sample('düz 96', const SunburstDisc(size: 96, flat: true)),
            _sample(
              'böyük 128',
              const SunburstDisc(
                size: 128,
                reduceMotion: true,
                child: SunMascot.cheer(),
              ),
            ),
          ]),
          const _Heading('Səma (ana səhifə)'),
          SizedBox(
            width: 328,
            height: 420,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Builder(
                builder:
                    (context) => MediaQuery(
                      data: MediaQuery.of(
                        context,
                      ).copyWith(viewPadding: const EdgeInsets.only(top: 24)),
                      child: const SkyBackground(style: SkyStyle.skyWithClouds),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  });

  testWidgets('11 tipoqrafiya', (tester) async {
    final t = ElifbaTypography.textTheme;
    final rows = <(String, TextStyle, String)>[
      ('displayLarge', t.displayLarge!, 'Bb'),
      ('displayMedium', t.displayMedium!, 'Əə'),
      ('headlineLarge', t.headlineLarge!, 'Təbriklər!'),
      ('headlineSmall', t.headlineSmall!, 'Qarışqayeyən'),
      ('titleLarge', t.titleLarge!, 'B hərfi'),
      ('titleMedium', t.titleMedium!, 'Heyvanlar'),
      ('titleSmall', t.titleSmall!, '41/96 · Tamam!'),
      ('labelLarge', t.labelLarge!, 'Yenidən başla'),
      ('bodyLarge', t.bodyLarge!, 'Ayılar çox güclü heyvanlardır.'),
      ('bodyMedium', t.bodyMedium!, 'B hərfi balaca baloncuklar kimi.'),
      ('bodySmall', t.bodySmall!, 'Tətbiqdəki bütün səsləri susdurur'),
      ('labelMedium', t.labelMedium!, 'Giləmeyvə · Söz tapmaca'),
      ('labelSmall', t.labelSmall!, 'Səsləndir'),
    ];
    await _render(
      tester,
      '11_typography',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (name, style, sample) in rows)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: ElifbaPalette.outlineVariant),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 96,
                    child: Text(
                      '$name\n${style.fontSize!.toInt()}/'
                      '${(style.fontSize! * style.height!).round()}',
                      style: const TextStyle(
                        fontFamily: 'Andika',
                        fontSize: 10,
                        color: ElifbaPalette.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      sample,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: style.copyWith(color: ElifbaPalette.onSurface),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  });

  testWidgets('12 hərf rəngləri', (tester) async {
    await _render(
      tester,
      '12_letter_colors',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Heading('32 hərf · letters[i % 6]'),
          Wrap(
            spacing: 6,
            runSpacing: 10,
            children: [
              for (final l in const [
                'A', 'B', 'C', 'Ç', 'D', 'E', 'Ə', 'F', 'G', 'Ğ', 'H', 'X', //
                'I', 'İ', 'J', 'K', 'Q', 'L', 'M', 'N', 'O', 'Ö', 'P', 'R', //
                'S', 'Ş', 'T', 'U', 'Ü', 'V', 'Y', 'Z',
              ])
                Builder(
                  builder: (context) {
                    final set = ElifbaColors.of(context).letterSetFor(l);
                    return DecoratedBox(
                      decoration: squishyDecoration(
                        color: set.tint,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(13)),
                        ),
                        edge: 3,
                        edgeColor: set.edge,
                      ),
                      child: SizedBox(
                        width: 34,
                        height: 40,
                        child: Center(
                          child: Text(
                            l,
                            style: ElifbaTextStyles.counter.copyWith(
                              fontSize: 19,
                              color: set.deep,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          const _Heading('Tam bitmiş hərf (override)'),
          Builder(
            builder: (context) {
              final set = ElifbaColors.of(
                context,
              ).letterSetFor('Ə', complete: true);
              return DecoratedBox(
                decoration: squishyDecoration(
                  color: set.tint,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  edge: 5,
                  edgeColor: set.edge,
                ),
                child: SizedBox(
                  width: 80,
                  height: 52,
                  child: Center(
                    child: Text(
                      'Əə',
                      style: ElifbaTextStyles.counter.copyWith(
                        fontSize: 24,
                        color: set.deep,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  });
}
