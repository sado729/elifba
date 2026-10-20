import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Ekran spesifikasiyalarındakı ad (home.md, animal.md).
typedef SquishyButton = Squishy;

/// Bir element üçün tək `ShapeDecoration`; blur heç vaxt yoxdur.
///
/// Kölgələrin sırası vacibdir: `[edge, ring]` — kənar əvvəl (altda), halqa
/// üstdə çəkilir. Bu CSS `box-shadow: <ring>, <edge>` ilə eynidir (CSS-də ilk
/// yazılan kölgə üstdə olur). Halqa varsa kənar da onun qədər enlənir
/// (CSS `0 5px 0 2px`).
///
/// HƏMİŞƏ iki kölgə qaytarılır (olmayan şəffaf): belə olanda
/// `ShapeDecoration.lerp` basış zamanı kölgəni "əridib yox etmir".
///
/// CSS → Flutter:
/// * `box-shadow: 0 5px 0 C` → `edge: 5, edgeColor: C`;
/// * `box-shadow: 0 0 0 2px R, 0 5px 0 2px C` → `ringWidth: 2, ringColor: R,
///   edge: 5, edgeColor: C`.
///
/// `RoundedRectangleBorder` formasında kölgənin künc radiusu CSS-dəki kimi
/// `r + spread` olur (bax [_CssShapeDecoration]); halqa hər yerdə eyni
/// qalınlıqdadır. Dairə və stadion onsuz da düzgün böyüyür.
ShapeDecoration squishyDecoration({
  required Color color,
  ShapeBorder shape = const StadiumBorder(),
  double edge = 0,
  Color? edgeColor,
  double ringWidth = 0,
  Color? ringColor,
}) {
  final hasRing = ringWidth > 0 && ringColor != null;
  return _CssShapeDecoration(
    color: color,
    shape: shape,
    shadows: [
      BoxShadow(
        color:
            (edge > 0 && edgeColor != null)
                ? edgeColor
                : ElifbaPalette.transparent,
        offset: Offset(0, edge),
        spreadRadius: hasRing ? ringWidth : 0,
      ),
      BoxShadow(
        color: hasRing ? ringColor : ElifbaPalette.transparent,
        spreadRadius: hasRing ? ringWidth : 0,
      ),
    ],
  );
}

/// `ShapeDecoration`, amma `RoundedRectangleBorder` üçün kölgələr CSS
/// `box-shadow` kimi çəkilir: `RRect.inflate(spread)` künc radiusunu da
/// `spread` qədər böyüdür.
///
/// Flutter-in öz `ShapeDecoration`-ı (və `BoxDecoration`-ı) şişirdilmiş
/// düzbucaqlıya EYNİ radiusu verir: 3 dp halqa 45°-də 4.2 dp olur, xarici
/// künclər kvadratlaşır. Tip yenə `ShapeDecoration`-dır (`shadows`, `shape`,
/// `color` oxunur), `lerp` nəticəsi də bu sinifdir.
class _CssShapeDecoration extends ShapeDecoration {
  const _CssShapeDecoration({
    super.color,
    super.gradient,
    super.image,
    super.shadows,
    required super.shape,
  });

  static ShapeDecoration? _wrap(ShapeDecoration? d) =>
      d == null || d is _CssShapeDecoration
          ? d
          : _CssShapeDecoration(
            color: d.color,
            gradient: d.gradient,
            image: d.image,
            shadows: d.shadows,
            shape: d.shape,
          );

  @override
  ShapeDecoration? lerpFrom(Decoration? a, double t) =>
      _wrap(super.lerpFrom(a, t));

  @override
  ShapeDecoration? lerpTo(Decoration? b, double t) => _wrap(super.lerpTo(b, t));

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    if (shape is RoundedRectangleBorder && gradient == null && image == null) {
      return _CssRRectPainter(this, onChanged);
    }
    return super.createBoxPainter(onChanged);
  }
}

class _CssRRectPainter extends BoxPainter {
  _CssRRectPainter(this._decoration, super.onChanged);

  final _CssShapeDecoration _decoration;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final rect = offset & configuration.size!;
    final textDirection = configuration.textDirection;
    final shape = _decoration.shape as RoundedRectangleBorder;
    final rrect = shape.borderRadius.resolve(textDirection).toRRect(rect);
    for (final s in _decoration.shadows ?? const <BoxShadow>[]) {
      if (s.color.a == 0) continue;
      canvas.drawRRect(
        rrect.shift(s.offset).inflate(s.spreadRadius),
        s.blurRadius == 0 ? (Paint()..color = s.color) : s.toPaint(),
      );
    }
    final color = _decoration.color;
    if (color != null) canvas.drawRRect(rrect, Paint()..color = color);
    shape.paint(canvas, rect, textDirection: textDirection);
  }
}

/// Basılan hər uşaq səthinin primitivi ("squishy" düymə, DS §3 "KƏNAR").
///
/// Görünüş:
/// * **sakit:** üz [color], altda [edge] dp qalınlığında düz kənar, istəyə
///   görə [ringWidth] halqa;
/// * **basılı:** üz [pressDepth] qədər aşağı düşür, kənar o qədər qısalır
///   (kənarın ALT xətti yerində qalır, üz onun içinə batır), üz
///   [pressedColor] olur; halqa üzlə birgə hərəkət edir;
/// * **qeyri-aktiv** ([onTap] null və ya [enabled] false): üz
///   [disabledColor], halqa və kənar yoxdur, jest yoxdur,
///   `Semantics(enabled: false)`. Məzmunun #A9A2C6 rəngini uşaq widget verir.
///
/// Qaydalar (hər biri nəyəsə bağlıdır):
/// * **Hər `Squishy`-də DƏQİQ bir `AnimatedContainer` var və o, çərçivədir.**
///   `widget_test`-in `_cardOf` / `_writeCardOf` köməkçiləri buna söykənir:
///   kartın içində (ulduz, nişan, səhnə, şəkil) başqa `AnimatedContainer`
///   olmamalıdır, səhifə də kartları ona bükməməlidir.
/// * Basış öz `AnimationController`-i ilə idarə olunur (90 ms easeOut, 140 ms
///   easeOutBack), çərçivə isə `Duration.zero` ilə hər kadrda o dəyəri alır.
///   Belə olanda halqanın qalınlığı da kadr-kadr dəyişə bilir (səsin "oxuyur"
///   nəbzi) və basış animasiyasını pozmur.
/// * Çox qısa toxunuş da tam 90 ms basışı göstərir, sonra buraxılır. `Timer`
///   yoxdur — `pumpAndSettle` 230 ms-də bitir.
/// * Sürüşdürmə (`onTapCancel`) dərhal buraxır.
/// * Yerdəyişmə `GestureDetector`-un İÇİNDƏdir: toxunma sahəsi yerindən
///   tərpənmir.
/// * Kənar və halqa layout qutusundan KƏNARDA çəkilir (CSS `box-shadow` kimi):
///   kəsən valideyn (`ClipRRect`, scroll) son elementin altında ən azı [edge]
///   dp boşluq saxlamalıdır.
/// * Azaldılmış hərəkət bunu söndürmür — birbaşa toxunuş cavabıdır.
/// * Hover və dalğa (ripple) yoxdur.
///
/// Sürüklənən kafel və pazl parçaları `Squishy` DEYİL (drag tanıyıcısı
/// toxunuşu oğurlayardı) — onlar `GameDecorations`-dan statik üz alır.
class Squishy extends StatefulWidget {
  const Squishy({
    super.key,
    required this.child,
    required this.onTap,
    required this.color,
    this.pressedColor,
    this.shape = const StadiumBorder(),
    this.borderRadius,
    this.edge = 0,
    this.edgeColor,
    this.pressDepth,
    this.ringColor,
    this.ringWidth = 0,
    this.enabled = true,
    this.disabledColor = ElifbaPalette.surfaceContainerHigh,
    this.width,
    this.height,
    this.padding,
    this.alignment,
    this.tooltip,
    this.semanticLabel,
    this.excludeChildSemantics = false,
    this.selected,
    this.inMutuallyExclusiveGroup = false,
  });

  final Widget child;

  /// `null` → qeyri-aktiv. Toxunuş buraxılan anda dərhal çağırılır.
  final VoidCallback? onTap;

  /// Üzün rəngi.
  final Color color;

  /// Basılı üz; yoxdursa [color].
  final Color? pressedColor;

  /// `CircleBorder` / `StadiumBorder` / `RoundedRectangleBorder`.
  final ShapeBorder shape;

  /// Rahatlıq üçün: verilibsə forma `RoundedRectangleBorder(borderRadius)` olur.
  final BorderRadius? borderRadius;

  /// Kənarın hündürlüyü, dp: 3 / 4 / 5 / 6 / 8 (`ElifbaEdge`).
  final double edge;
  final Color? edgeColor;

  /// Basanda nə qədər enir; defolt [edge]. Kitab səhifəsi: kənar 8, basış 4;
  /// yazı kartı: kənar 0, basış 3.
  final double? pressDepth;

  final Color? ringColor;
  final double ringWidth;

  /// [onTap] verilsə belə söndürmək üçün.
  final bool enabled;

  /// Qeyri-aktiv üz (#ECE8F6).
  final Color disabledColor;

  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry? alignment;

  /// Uzun basanda göstərilir və semantik etiket olur (iki dəfə oxunmur).
  final String? tooltip;

  /// Semantik etiket; defolt [tooltip].
  final String? semanticLabel;

  /// `true` → uşağın öz semantikası (mətni) atılır, yalnız [semanticLabel]
  /// oxunur. Etiketin iki dəfə səslənməməsi üçün (tab: "Qidalar, tamamlandı").
  final bool excludeChildSemantics;

  /// Tab / rejim düyməsi kimi seçilə bilən elementlər üçün.
  final bool? selected;

  /// Radio qrupu (tablar): ekran oxuyucusu "1-dən biri seçilib" deyə bilsin.
  final bool inMutuallyExclusiveGroup;

  @override
  State<Squishy> createState() => _SquishyState();
}

class _SquishyState extends State<Squishy> with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: ElifbaMotion.pressIn,
    reverseDuration: ElifbaMotion.release,
  )..addStatusListener(_onStatus);

  late final CurvedAnimation _v = CurvedAnimation(
    parent: _press,
    curve: ElifbaMotion.pressInCurve,
    reverseCurve: ElifbaMotion.releaseCurveReversed,
  );

  /// Toxunuş basış bitməmiş buraxıldı — basış sona çatanda buraxılacaq.
  bool _releaseQueued = false;

  bool get _on => widget.enabled && widget.onTap != null;

  @override
  void didUpdateWidget(covariant Squishy oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Basılı halda söndürülsə (məs. səs kanalı bağlandı) dərhal sakit vəziyyət.
    if (!_on && _press.value != 0) {
      _releaseQueued = false;
      _press.value = 0;
    }
  }

  @override
  void dispose() {
    _v.dispose();
    _press.dispose();
    super.dispose();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _releaseQueued) {
      _releaseQueued = false;
      _press.reverse();
    }
  }

  void _down(TapDownDetails _) {
    _releaseQueued = false;
    _press.forward();
  }

  void _up(TapUpDetails _) {
    if (_press.status == AnimationStatus.completed) {
      _press.reverse();
    } else {
      _releaseQueued = true;
    }
  }

  void _cancel() {
    _releaseQueued = false;
    _press.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final on = _on;
    final shape =
        widget.borderRadius != null
            ? RoundedRectangleBorder(borderRadius: widget.borderRadius!)
            : widget.shape;
    final depth = widget.pressDepth ?? widget.edge;

    Widget frame = AnimatedBuilder(
      animation: _v,
      child: widget.child,
      builder: (context, child) {
        // Buraxılışda easeOutBack bir az mənfiyə aşır: üz ~10 % yuxarı qalxır.
        final v = on ? _v.value : 0.0;
        final face =
            widget.pressedColor == null
                ? widget.color
                : Color.lerp(
                  widget.color,
                  widget.pressedColor,
                  v.clamp(0.0, 1.0),
                )!;
        return AnimatedContainer(
          // Çərçivə animasiyanı özü etmir — dəyəri controller-dən alır.
          duration: Duration.zero,
          width: widget.width,
          height: widget.height,
          padding: widget.padding,
          alignment: widget.alignment,
          // HƏMİŞƏ null deyil: null-a keçmək ağaca `Transform` əlavə edib
          // çıxarar və uşağın vəziyyətini sıfırlayardı.
          transform: Matrix4.translationValues(0, depth * v, 0),
          decoration: squishyDecoration(
            color: on ? face : widget.disabledColor,
            shape: shape,
            edge:
                on
                    ? (widget.edge - depth * v).clamp(0.0, widget.edge + 1)
                    : 0.0,
            edgeColor: widget.edgeColor,
            ringWidth: on ? math.max(0.0, widget.ringWidth) : 0.0,
            ringColor: widget.ringColor,
          ),
          child: child,
        );
      },
    );

    frame = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: on ? _down : null,
      onTapUp: on ? _up : null,
      onTapCancel: on ? _cancel : null,
      onTap: on ? widget.onTap : null,
      child: frame,
    );

    if (widget.tooltip != null) {
      frame = Tooltip(
        message: widget.tooltip!,
        excludeFromSemantics: true,
        child: frame,
      );
    }

    return Semantics(
      container: true,
      button: true,
      enabled: on,
      selected: widget.selected,
      inMutuallyExclusiveGroup: widget.inMutuallyExclusiveGroup ? true : null,
      label: widget.semanticLabel ?? widget.tooltip,
      excludeSemantics: widget.excludeChildSemantics,
      // Uşaq semantikası atılanda jestin "tap" əməliyyatı da gedir — burada
      // qaytarılır.
      onTap: widget.excludeChildSemantics && on ? widget.onTap : null,
      child: frame,
    );
  }
}
