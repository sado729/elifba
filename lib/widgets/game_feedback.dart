import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'badges.dart';
import 'elifba_card.dart';
import 'squishy.dart';

// DS qaydası: doğru = dairə halqası + ✓ + pop; səhv = qırıq çərçivə + ✕ +
// −5° əyilmə + silkələnmə. Rəng heç vaxt tək siqnal deyil. Söz tapmaca
// `animal_detail_page.dart`-da inline qalır (gotcha 3) — yeni widget sinfi
// yox, bu bəzəkləri işlədir.

/// Söz tapmaca və pazl üçün statik bəzəklər. Sürüklənən kafel `Squishy`
/// deyil (drag tanıyıcısı toxunuşu oğurlayardı), üzünü buradan alır.
abstract final class GameDecorations {
  static const ShapeBorder _tileShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(ElifbaRadius.r14)),
  );

  /// Kafellər arası üfüqi boşluq (sətirdə).
  static const double wordGap = 6;

  /// Kafel sətirləri arası boşluq.
  static const double wordRunGap = 10;

  /// Sətirdə ən çox kafel.
  static const int wordMaxPerRow = 6;

  /// Boş slot: #F8F5FF üz + [slotEmptyBorder] (qırıq 2.5 #C6B8F5).
  static const ShapeDecoration slotEmpty = ShapeDecoration(
    color: ElifbaPalette.surfaceContainerLow,
    shape: _tileShape,
  );
  static const DashedRRectPainter slotEmptyBorder = DashedRRectPainter(
    color: ElifbaPalette.playingEdge,
    strokeWidth: ElifbaRing.dashed,
    radius: ElifbaRadius.r14,
  );

  /// Boş slotun üstündə hərf gəzir (`candidateData.isNotEmpty`; dizaynda
  /// yoxdur, animal.md §8.4-dən törədilib): #E4DEFF üz + [slotHoverBorder]
  /// (qırıq 2.5 #7C63D9).
  static const ShapeDecoration slotHover = ShapeDecoration(
    color: ElifbaPalette.secondaryContainer,
    shape: _tileShape,
  );
  static const DashedRRectPainter slotHoverBorder = DashedRRectPainter(
    color: ElifbaPalette.secondary,
    strokeWidth: ElifbaRing.dashed,
    radius: ElifbaRadius.r14,
  );

  /// Səbətdəki kafel: ağ üz, 2 dp halqa + 4 dp kənar #D2C8F2, hərf #2E2A55.
  static final ShapeDecoration tileRest = squishyDecoration(
    color: ElifbaPalette.surface,
    shape: _tileShape,
    edge: ElifbaEdge.e4,
    edgeColor: ElifbaPalette.outline,
    ringWidth: ElifbaRing.normal,
    ringColor: ElifbaPalette.outline,
  );

  /// Sürüklənən kafel (`Draggable.feedback`): 2 dp #7C63D9 halqa + 8 dp
  /// #C6B8F5 kənar; 1.12 böyüyür, −5° əyilir. `Material(transparency)` ilə
  /// bükün.
  static final ShapeDecoration tileDragging = squishyDecoration(
    color: ElifbaPalette.surface,
    shape: _tileShape,
    edge: ElifbaEdge.e8,
    edgeColor: ElifbaPalette.playingEdge,
    ringWidth: ElifbaRing.normal,
    ringColor: ElifbaPalette.secondary,
  );
  static const double tileDraggingScale = 1.12;

  /// Doğru yerə düşən kafel: #DDF2E4, 3 dp #2E9460 halqa, kənar yox; hərf
  /// #1A5A39; `CheckBadge(22)`; pop.
  static final ShapeDecoration tileCorrect = squishyDecoration(
    color: ElifbaPalette.correctContainer,
    shape: _tileShape,
    ringWidth: ElifbaRing.strong,
    ringColor: ElifbaPalette.correct,
  );

  /// Səhv yerə düşən kafel: #FCE1E4 üz + [tileWrongBorder] (qırıq 3
  /// #DD4A5A); hərf #A12838; −5°; `CrossBadge(22)`; silkələnmə.
  static const ShapeDecoration tileWrong = ShapeDecoration(
    color: ElifbaPalette.errorContainer,
    shape: _tileShape,
  );
  static const DashedRRectPainter tileWrongBorder = DashedRRectPainter(
    color: ElifbaPalette.error,
    strokeWidth: ElifbaRing.strong,
    radius: ElifbaRadius.r14,
  );

  /// Kafel hərfinin rəngi vəziyyətə görə.
  static const Color tileGlyphRest = ElifbaPalette.onSurface;
  static const Color tileGlyphCorrect = ElifbaPalette.onCorrectContainer;
  static const Color tileGlyphWrong = ElifbaPalette.onErrorContainer;

  /// Nişanların yeri (kafelin sağ yuxarı küncündən).
  static const double tileCheckOffset = -9;
  static const double tileCrossOffset = -11;
  static const double tileBadgeSize = ElifbaSize.badgeL;

  // ----------------------------------------------------------------- pazl

  /// Boş lövhə xanası: #F8F5FF, içəridə 1.5 #E6E1F5, r6.
  static const BoxDecoration cellEmpty = BoxDecoration(
    color: ElifbaPalette.surfaceContainerLow,
    border: Border.fromBorderSide(
      BorderSide(
        color: ElifbaPalette.outlineVariant,
        width: ElifbaRing.hairline,
      ),
    ),
    borderRadius: BorderRadius.all(Radius.circular(ElifbaRadius.r6)),
  );

  /// Boş xananın üstündə parça gəzir (dizaynda yoxdur, animal.md §9.4-dən
  /// törədilib): #E4DEFF, içəridə 2 #7C63D9, r6.
  static const BoxDecoration cellHover = BoxDecoration(
    color: ElifbaPalette.secondaryContainer,
    border: Border.fromBorderSide(
      BorderSide(color: ElifbaPalette.secondary, width: ElifbaRing.normal),
    ),
    borderRadius: BorderRadius.all(Radius.circular(ElifbaRadius.r6)),
  );

  /// Doğru parça — şəklin ÜSTÜNDƏ (`foregroundDecoration`): içəridə 3
  /// #2E9460; `CheckBadge(18, ringWidth: 0)`; lövhə bitəndə nişan gizlənir.
  static const BoxDecoration cellCorrect = BoxDecoration(
    border: Border.fromBorderSide(
      BorderSide(color: ElifbaPalette.correct, width: ElifbaRing.strong),
    ),
    borderRadius: BorderRadius.all(Radius.circular(ElifbaRadius.r6)),
  );

  /// Səhv parça — şəklin üstündə: içəridə 3 #DD4A5A + [cellWrongOutline];
  /// `CrossBadge(18, ringWidth: 0)`.
  static const BoxDecoration cellWrong = BoxDecoration(
    border: Border.fromBorderSide(
      BorderSide(color: ElifbaPalette.error, width: ElifbaRing.strong),
    ),
    borderRadius: BorderRadius.all(Radius.circular(ElifbaRadius.r6)),
  );
  static const DashedRRectPainter cellWrongOutline = DashedRRectPainter(
    color: ElifbaPalette.error,
    strokeWidth: 2,
    radius: ElifbaRadius.r6,
    outset: 2,
  );

  /// Xana nişanının ölçüsü və yeri (`bottom 3, right 3`).
  static const double cellBadgeSize = ElifbaSize.badgeS;
  static const double cellBadgeInset = 3;

  /// Lövhə: #ECE8F6, içəridə 2 #D2C8F2, r16; içəri boşluq 3, xanalar arası 2.
  ///
  /// ⚠️ `Container`/`AnimatedContainer` dekorasiyanın 2 dp çərçivəsini öz
  /// `padding`-inə ƏLAVƏ edir ([boardDone]-da da eyni 2 dp var, ona görə
  /// keçid zamanı məzmun tərpənmir). Xanalar [boardPadding] (3) içəridə
  /// olsun deyə `padding: EdgeInsets.all(boardContainerPadding)` verin; ya da
  /// `DecoratedBox` + `Padding(boardPadding)` işlədin.
  static const BoxDecoration board = BoxDecoration(
    color: ElifbaPalette.surfaceContainerHigh,
    border: Border.fromBorderSide(
      BorderSide(color: ElifbaPalette.outline, width: ElifbaRing.normal),
    ),
    borderRadius: BorderRadius.all(Radius.circular(ElifbaRadius.r16)),
  );
  static const double boardPadding = 3;
  static const double boardGap = 2;

  /// `Container(padding:)` üçün: [boardPadding] − çərçivənin 2 dp-si.
  static const double boardContainerPadding = boardPadding - ElifbaRing.normal;

  /// Bitmiş lövhə: #DDF2E4, xaricdə 3 dp #2E9460 halqa (künc radiusu
  /// 16 + 3, CSS kimi). İçəridəki 2 dp çərçivə üzlə eyni rəngdədir — görünmür,
  /// yalnız [board] ilə eyni layout boşluğunu saxlayır.
  static final ShapeDecoration boardDone = squishyDecoration(
    color: ElifbaPalette.correctContainer,
    shape: const RoundedRectangleBorder(
      side: BorderSide(
        color: ElifbaPalette.correctContainer,
        width: ElifbaRing.normal,
      ),
      borderRadius: BorderRadius.all(Radius.circular(ElifbaRadius.r16)),
    ),
    ringWidth: ElifbaRing.strong,
    ringColor: ElifbaPalette.correct,
  );

  /// Səbətdəki pazl parçası: şəkil üstündə, 3 dp #D2C8F2 kənar, r8. Ölçü
  /// `min(64, xana)`.
  static final ShapeDecoration trayPiece = squishyDecoration(
    color: ElifbaPalette.surfaceContainerHigh,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(ElifbaRadius.r8)),
    ),
    edge: ElifbaEdge.e3,
    edgeColor: ElifbaPalette.outline,
  );

  /// Sürüklənən pazl parçası: 3 dp #7C63D9 halqa + 6 dp #C6B8F5 kənar,
  /// 4 dp yuxarı, 1.06 böyük.
  static final ShapeDecoration trayPieceDragging = squishyDecoration(
    color: ElifbaPalette.surfaceContainerHigh,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(ElifbaRadius.r8)),
    ),
    edge: ElifbaEdge.e6,
    edgeColor: ElifbaPalette.playingEdge,
    ringWidth: ElifbaRing.strong,
    ringColor: ElifbaPalette.secondary,
  );
  static const double trayPieceDraggingScale = 1.06;
  static const double trayPieceDraggingLift = -4;
}

/// Söz kafelinin eni (DS: "Kafel heç vaxt 44 dp-dən kiçilmir"; animal.md
/// §8.3). 5 hərfə qədər 56; 6 və daha çox hərfdə sətirdə 6 kafel, 6 dp
/// aralıqla, 44..56 arası — 6 hərfli ad (Pələng, Dovşan) bir sətirdə qalır.
/// [cardInnerWidth] = ekran eni − 2·16 − 2·12 (360 → 304, 412 → 356).
///
/// | hərf | 360 dp  | 412 dp  |
/// |------|---------|---------|
/// | ≤ 5  | 56 × 64 | 56 × 64 |
/// | ≥ 6  | 45 × 52 | 54 × 62 |
double wordTileWidth(int letters, double cardInnerWidth) =>
    letters <= 5
        ? ElifbaSize.maxTile
        : ((cardInnerWidth -
                    (GameDecorations.wordMaxPerRow - 1) *
                        GameDecorations.wordGap) /
                GameDecorations.wordMaxPerRow)
            .floorToDouble()
            .clamp(ElifbaSize.minTile, ElifbaSize.maxTile)
            .toDouble();

/// Kafelin hündürlüyü: 56 → 64, 45 → 52, 54 → 62.
double wordTileHeight(double width) => (width * 1.15).roundToDouble();

/// Sətirdə neçə kafel: ən çox 6; ~350 dp-dən dar ekranda sığan qədər.
int wordTilesPerRow(int letters, double tile, double cardInnerWidth) {
  const gap = GameDecorations.wordGap;
  var n = math.max(1, math.min(letters, GameDecorations.wordMaxPerRow));
  if (n * tile + (n - 1) * gap > cardInnerWidth) {
    n = math.max(1, ((cardInnerWidth + gap) / (tile + gap)).floor());
  }
  return n;
}

/// [perRow] kafellik sətrin eni. `Wrap`-ı `ConstrainedBox(maxWidth:
/// rowMax + 0.5)` ilə bükün (0.5 — tam sətir float xətasından sınmasın).
double wordRowMax(int perRow, double tile) =>
    perRow * tile + (perRow - 1) * GameDecorations.wordGap;

/// Söz tapmacanın bütün ölçüləri bir yerdə (animal.md §8.3).
typedef WordTileLayout =
    ({double tile, double tileHeight, int perRow, double rowMax});

/// [letters] hərfli söz, kartın içi [cardInnerWidth] enində.
WordTileLayout wordTileLayout(int letters, double cardInnerWidth) {
  final tile = wordTileWidth(letters, cardInnerWidth);
  final perRow = wordTilesPerRow(letters, tile, cardInnerWidth);
  return (
    tile: tile,
    tileHeight: wordTileHeight(tile),
    perRow: perRow,
    rowMax: wordRowMax(perRow, tile),
  );
}

/// Söz kafelinin görünüş vəziyyəti.
enum WordTileState {
  /// Boş slot (qırıq #C6B8F5).
  empty,

  /// Boş slotun üstündə hərf gəzir (qırıq #7C63D9, #E4DEFF üz).
  hover,

  /// Səbətdəki kafel.
  rest,

  /// `Draggable.feedback`.
  dragging,

  /// Doğru yerdə: halqa + ✓.
  correct,

  /// Səhv yerdə: qırıq çərçivə + ✕ + −5°.
  wrong,
}

/// Söz tapmaca kafelinin hazır üzü: vəziyyətə görə bəzək, qırıq çərçivə,
/// əyilmə və ✓/✕ nişanı. Hərəkəti (pop, silkələnmə) çağıran
/// [PopOnTrigger] / [ShakeOnTrigger] ilə əlavə edir. Ölçü [wordTileWidth] /
/// [wordTileHeight] ilə hesablanır; hərf 52 dp-dən dar kafeldə 24 sp.
///
/// İstəyə bağlıdır — səhifə eyni nəticəni [GameDecorations] ilə özü də qura
/// bilər. İçində `AnimatedContainer` yoxdur.
///
/// `dragging`-in −5° əyilməsi və 1.12 böyüməsi hərəkətdir: azaldılmış
/// hərəkətdə ([reduceMotion]) olmur, halqa və kənar qalır. `wrong`-un −5°-si
/// isə formadır və həmişə qalır.
class WordTileFace extends StatelessWidget {
  const WordTileFace({
    super.key,
    required this.state,
    required this.width,
    required this.height,
    this.glyph = '',
    this.reduceMotion,
  });

  final WordTileState state;
  final double width;
  final double height;

  /// Kafeldəki hərf (boş slotda göstərilmir).
  final String glyph;

  /// Testlər üçün `AppSettings.reduceMotion`-u əvəz edir.
  final bool? reduceMotion;

  @override
  Widget build(BuildContext context) {
    final empty = state == WordTileState.empty || state == WordTileState.hover;
    final (
      Decoration decoration,
      CustomPainter? dashed,
      Color ink,
    ) = switch (state) {
      WordTileState.empty => (
        GameDecorations.slotEmpty,
        GameDecorations.slotEmptyBorder,
        GameDecorations.tileGlyphRest,
      ),
      WordTileState.hover => (
        GameDecorations.slotHover,
        GameDecorations.slotHoverBorder,
        GameDecorations.tileGlyphRest,
      ),
      WordTileState.rest => (
        GameDecorations.tileRest,
        null,
        GameDecorations.tileGlyphRest,
      ),
      WordTileState.dragging => (
        GameDecorations.tileDragging,
        null,
        GameDecorations.tileGlyphRest,
      ),
      WordTileState.correct => (
        GameDecorations.tileCorrect,
        null,
        GameDecorations.tileGlyphCorrect,
      ),
      WordTileState.wrong => (
        GameDecorations.tileWrong,
        GameDecorations.tileWrongBorder,
        GameDecorations.tileGlyphWrong,
      ),
    };

    Widget tile = CustomPaint(
      foregroundPainter: dashed,
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: decoration,
        child:
            empty
                ? null
                : Text(
                  glyph,
                  maxLines: 1,
                  textScaler: TextScaler.noScaling,
                  style: ElifbaTextStyles.tileGlyphFor(
                    width,
                  ).copyWith(color: ink),
                ),
      ),
    );

    if (state == WordTileState.correct || state == WordTileState.wrong) {
      final correct = state == WordTileState.correct;
      final offset =
          correct
              ? GameDecorations.tileCheckOffset
              : GameDecorations.tileCrossOffset;
      tile = Stack(
        clipBehavior: Clip.none,
        children: [
          tile,
          Positioned(
            top: offset,
            right: offset,
            child:
                correct
                    ? const CheckBadge(size: GameDecorations.tileBadgeSize)
                    : const CrossBadge(size: GameDecorations.tileBadgeSize),
          ),
        ],
      );
    }

    final dragging = state == WordTileState.dragging;
    final moving = dragging && !ElifbaMotion.isReduced(reduceMotion);
    if (state == WordTileState.wrong || moving) {
      tile = Transform.rotate(
        angle: ElifbaMotion.wrongTiltDegrees * math.pi / 180,
        child: tile,
      );
    }
    if (moving) {
      tile = Transform.scale(
        scale: GameDecorations.tileDraggingScale,
        child: tile,
      );
    }
    if (dragging) {
      tile = Material(type: MaterialType.transparency, child: tile);
    }
    return tile;
  }
}

/// Doğru cavabın "pop"-u: 1 → 1.12 → 1, 240 ms (40 % easeOut, 60 %
/// easeOutBack). [trigger] YENİ, null olmayan dəyərə dəyişəndə təkrarlanır;
/// [animateOnMount] → ilk qurulanda da (trigger null deyilsə).
///
/// Öz `AnimationController`-i var, taymer yoxdur. Azaldılmış hərəkətdə pop
/// olmur — halqa və ✓ qalır.
class PopOnTrigger extends StatefulWidget {
  const PopOnTrigger({
    super.key,
    required this.trigger,
    required this.child,
    this.animateOnMount = false,
    this.reduceMotion,
  });

  final Object? trigger;
  final Widget child;
  final bool animateOnMount;
  final bool? reduceMotion;

  @override
  State<PopOnTrigger> createState() => _PopOnTriggerState();
}

class _PopOnTriggerState extends State<PopOnTrigger>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: ElifbaMotion.correctPop,
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: ElifbaMotion.correctPopScale,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: ElifbaMotion.correctPopScale,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 60,
    ),
  ]).animate(_c);

  @override
  void initState() {
    super.initState();
    if (widget.animateOnMount && widget.trigger != null) _play();
  }

  @override
  void didUpdateWidget(covariant PopOnTrigger oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != null && widget.trigger != oldWidget.trigger) _play();
  }

  void _play() {
    if (ElifbaMotion.isReduced(widget.reduceMotion)) return;
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _scale, child: widget.child);
}

/// Sönən silkələnmənin yerdəyişməsi, `t ∈ [0, 1]` (xətti):
/// `dx = sin(3πt) · amplitude · (1 − t)` — `TracingCanvas`-dakı sinus.
/// Öz controller-i olan səhifə üçün (yazı oyununun kartı: amplitude
/// `ElifbaMotion.traceShakeAmplitude` = 8).
double dampedShakeOffset(
  double t, [
  double amplitude = ElifbaMotion.wrongShakeAmplitude,
]) => t == 0 ? 0 : math.sin(t * math.pi * 3) * amplitude * (1 - t);

/// Səhv cavabın silkələnməsi: [dampedShakeOffset], 280 ms. Qaydalar
/// [PopOnTrigger] kimidir; azaldılmış hərəkətdə silkələnmə olmur, qırıq
/// çərçivə, əyilmə və ✕ qalır.
class ShakeOnTrigger extends StatefulWidget {
  const ShakeOnTrigger({
    super.key,
    required this.trigger,
    required this.child,
    this.animateOnMount = false,
    this.reduceMotion,
    this.amplitude = ElifbaMotion.wrongShakeAmplitude,
  });

  final Object? trigger;
  final Widget child;
  final bool animateOnMount;
  final bool? reduceMotion;

  /// Ən böyük yerdəyişmə, dp: 6 (kafel, pazl), 8 (yazı kartı).
  final double amplitude;

  @override
  State<ShakeOnTrigger> createState() => _ShakeOnTriggerState();
}

class _ShakeOnTriggerState extends State<ShakeOnTrigger>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: ElifbaMotion.wrongShake,
  );

  @override
  void initState() {
    super.initState();
    if (widget.animateOnMount && widget.trigger != null) _play();
  }

  @override
  void didUpdateWidget(covariant ShakeOnTrigger oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != null && widget.trigger != oldWidget.trigger) _play();
  }

  void _play() {
    if (ElifbaMotion.isReduced(widget.reduceMotion)) return;
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder:
          (context, child) => Transform.translate(
            offset: Offset(dampedShakeOffset(_c.value, widget.amplitude), 0),
            child: child,
          ),
    );
  }
}
