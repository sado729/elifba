import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'badges.dart';
import 'squishy.dart';

/// Uşaq ekranlarının 48 dp pill tabı (DS "Pill tablar"). Heyvan səhifəsinin
/// bölmə tabları, yazı oyununun rejim düymələri («Bax», «İzlə»,
/// «Təkrarla») və pazlın səviyyə düymələri (`GridGlyph` ilə) hamısı budur.
///
/// * **Seçilməyib:** ağ üz, 2 dp #E6E1F5 halqa, kənar YOX; ikon #7C63D9, yazı
///   #5E5888; basanda üz #F8F5FF olur, yerindən tərpənmir.
/// * **Seçilib:** #7C63D9 üz, 4 dp #5C45B5 kənar, ikon və yazı #FFFDFB;
///   basanda 4 dp enir.
/// * **Tamamlanıb** ([done]): hər iki halda `CheckBadge(20)` sağ yuxarıda.
/// * **Seçim dəyişəndə** üz, kənar, halqa, yazı və ikon rəngi 140 ms
///   easeOut ilə keçir (trace.md §2.2; [animateSelection] false → dərhal).
///   `AnimatedContainer` əlavə olunmur — dəyərlər hər kadrda `Squishy`-yə
///   verilir. `leading` widget-inin rəngi çağıranındır (keçmir).
///
/// Tablar radio qrupudur: seçilmiş taba yenidən toxunmaq heç nə etməməlidir
/// (bunu çağıran yoxlayır). Seçilmiş tab üçün `onTap: null` vermək olar — tab
/// boz/qeyri-aktiv OLMUR, sadəcə toxunuş heç nə etmir. Seçilməmiş tabda
/// `onTap: null` qeyri-aktivdir: üz #ECE8F6, yazı və ikon #A9A2C6.
/// Semantika: `selected`, qrup daxilində tək seçim, etiket
/// "$label, tamamlandı".
class PillTab extends StatelessWidget {
  const PillTab({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.leading,
    this.selected = false,
    this.done = false,
    this.expand = false,
    this.unselectedIconColor = ElifbaPalette.secondary,
    this.animateSelection = true,
  });

  final String label;
  final VoidCallback? onTap;

  /// 22 dp ikon; seçilməyəndə [unselectedIconColor].
  final IconData? icon;

  /// İkon yerinə istənilən widget (pazl səviyyəsi üçün `GridGlyph`).
  final Widget? leading;
  final bool selected;
  final bool done;

  /// `Expanded`-in içində işlənir: məzmun mərkəzdə, yan boşluq yoxdur (maket kimi).
  final bool expand;

  /// Seçilməmiş ikonun rəngi: heyvan tabları #7C63D9 (defolt), yazı oyununun
  /// rejim düymələri yazı ilə eyni #5E5888 (`ElifbaPalette.onSurfaceVariant`).
  final Color unselectedIconColor;

  /// `false` → seçim rəngi dərhal dəyişir.
  final bool animateSelection;

  static void _noop() {}

  @override
  Widget build(BuildContext context) {
    final target = selected ? 1.0 : 0.0;
    if (!animateSelection) return _build(target);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: target),
      duration: ElifbaMotion.selection,
      curve: Curves.easeOut,
      builder: (context, t, _) => _build(t),
    );
  }

  /// [t]: 0 = seçilməyib, 1 = seçilib.
  Widget _build(double t) {
    // Seçilmiş tab heç vaxt boz olmur (radio: toxunuş sadəcə heç nə etmir).
    final tap = onTap ?? (selected ? _noop : null);
    final disabled = tap == null;
    final fg =
        disabled
            ? ElifbaPalette.onMuted
            : Color.lerp(
              ElifbaPalette.onSurfaceVariant,
              ElifbaPalette.onSecondary,
              t,
            )!;
    final iconColor =
        disabled
            ? ElifbaPalette.onMuted
            : Color.lerp(unselectedIconColor, ElifbaPalette.onSecondary, t)!;
    final hasLead = icon != null || leading != null;
    final gap = leading != null ? 8.0 : 6.0;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leading != null)
          leading!
        else if (icon != null)
          Icon(icon, size: 22, color: iconColor),
        if (hasLead) SizedBox(width: gap),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: ElifbaTextStyles.tabLabel.copyWith(color: fg),
          ),
        ),
      ],
    );

    final tab = Squishy(
      onTap: tap,
      color: Color.lerp(ElifbaPalette.surface, ElifbaPalette.secondary, t)!,
      pressedColor:
          Color.lerp(
            ElifbaPalette.surfaceContainerLow,
            ElifbaPalette.secondary,
            t,
          )!,
      edge: ElifbaEdge.e4 * t,
      edgeColor: ElifbaPalette.secondaryEdge,
      ringColor: ElifbaPalette.outlineVariant,
      ringWidth: ElifbaRing.normal * (1 - t),
      height: ElifbaSize.tab,
      width: expand ? double.infinity : null,
      alignment: expand ? Alignment.center : null,
      padding:
          expand
              ? EdgeInsets.zero
              : EdgeInsetsDirectional.only(start: hasLead ? 10 : 14, end: 14),
      semanticLabel: done ? '$label, tamamlandı' : label,
      excludeChildSemantics: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: content,
    );

    if (!done) return tab;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        tab,
        const Positioned(top: -6, right: -6, child: CheckBadge(size: 20)),
      ],
    );
  }
}

/// Pazl səviyyəsinin kiçik şəbəkə şəkli — oxuya bilməyən uşaq da düymələri
/// fərqləndirsin (DS "Seqment idarəsi").
///
/// * 3: 3 × 3 kvadrat, hər biri 5 dp, aralıq 2, radius 1 (19 × 19);
/// * 4: 4 × 4 kvadrat, hər biri 4 dp, aralıq 1.5, radius 0 (20.5 × 20.5);
/// * 5: `Icons.grid_on_rounded` 20.
///
/// Rəng: seçilməyəndə #A9A2C6, seçiləndə #FFFDFB.
class GridGlyph extends StatelessWidget {
  const GridGlyph({super.key, required this.n, required this.color});

  final int n;
  final Color color;

  /// Tabın vəziyyətinə görə rəng.
  static Color colorFor({required bool selected}) =>
      selected ? ElifbaPalette.onSecondary : ElifbaPalette.onMuted;

  @override
  Widget build(BuildContext context) {
    if (n >= 5) {
      return ExcludeSemantics(
        child: Icon(Icons.grid_on_rounded, size: 20, color: color),
      );
    }
    final (cell, gap, radius) = n == 3 ? (5.0, 2.0, 1.0) : (4.0, 1.5, 0.0);
    final side = n * cell + (n - 1) * gap;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: side,
        child: CustomPaint(
          painter: _GridGlyphPainter(
            n: n,
            cell: cell,
            gap: gap,
            radius: radius,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _GridGlyphPainter extends CustomPainter {
  _GridGlyphPainter({
    required this.n,
    required this.cell,
    required this.gap,
    required this.radius,
    required this.color,
  });

  final int n;
  final double cell;
  final double gap;
  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        final rect = Rect.fromLTWH(
          c * (cell + gap),
          r * (cell + gap),
          cell,
          cell,
        );
        if (radius > 0) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, Radius.circular(radius)),
            paint,
          );
        } else {
          canvas.drawRect(rect, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_GridGlyphPainter old) => old.n != n || old.color != color;
}
