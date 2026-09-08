import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/stroke_tracker.dart';

/// Cızma rejimləri — çətinlik pillə-pillə artır.
enum TracingMode {
  /// Bax: barmaq avtomatik hərfi cızır, uşaq izləyir.
  watch,

  /// İzlə: qalın yol, nömrələnmiş başlanğıc nöqtəsi, istiqamət oxu.
  guided,

  /// Təkrarla: yalnız nöqtəli kontur qalır — sıra yaddaşdan gəlir.
  faded,
}

/// Hərfin çəkildiyi qutunun ölçüsü. `letter_strokes.dart` ilə eyni olmalıdır.
const Size kGlyphBox = Size(100, 104);

/// Xətt dəftərinin sətirləri (qutu vahidi ilə).
const double kCapLine = 20;
const double kMidLine = 54;
const double kBaseLine = 88;
const double kDescLine = 100;

/// Barmaqla hərf cızma kətanı.
///
/// Uşağın xam cızığı DEYİL, ideal yolun tədricən dolan hissəsi çəkilir — nəticə
/// həmişə səliqəli hərf kimi görünür. Bu, oyunun əsas UX qərarıdır.
///
/// Vacib: bu widget `setState` çağırmır. İrəliləyiş `_repaint` notifier-i ilə
/// yalnız [CustomPainter]-ə çatdırılır, ona görə barmaq hərəkət edərkən nə bu
/// widget, nə də valideyn səhifə yenidən qurulmur.
class TracingCanvas extends StatefulWidget {
  const TracingCanvas({
    super.key,
    required this.units,
    required this.mode,
    this.tolerance = StrokeTracker.defaultTolerance,
    this.onEvent,
    this.inkColor = const Color(0xFFFFD54F),
    this.doneColor = const Color(0xFFFFECB3),
    this.roadColor = const Color(0x33FFFFFF),
    this.guideColor = const Color(0x22FFFFFF),
    this.startColor = const Color(0xFF66BB6A),
  });

  /// Cızılacaq ştrixlər və nöqtələr, sıra ilə.
  final List<TraceUnit> units;

  final TracingMode mode;

  /// Barmağın yoldan neçə qutu vahidi kənara çıxa biləcəyi.
  final double tolerance;

  /// Hər barmaq hadisəsinin nəticəsi — səs, haptika və konfeti üçün.
  final ValueChanged<TraceResult>? onEvent;

  final Color inkColor;
  final Color doneColor;
  final Color roadColor;
  final Color guideColor;
  final Color startColor;

  @override
  State<TracingCanvas> createState() => _TracingCanvasState();
}

class _TracingCanvasState extends State<TracingCanvas>
    with TickerProviderStateMixin {
  late StrokeTracker _tracker;

  /// Barmaq hərəkət etdikcə yalnız bunu artırırıq — `setState` yoxdur.
  final ValueNotifier<int> _repaint = ValueNotifier<int>(0);

  /// Başlanğıc nöqtəsinin nəbzi və nümayiş animasiyası.
  late final AnimationController _pulse;
  late final AnimationController _demo;

  /// Səhv yerə toxunanda kətanın yüngül titrəməsi.
  late final AnimationController _shake;

  /// Nöqtəli konturlar hər kadrda yenidən hesablanmasın deyə keşlənir.
  final List<Path> _dashed = <Path>[];

  int _demoUnit = 0;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _demo = AnimationController(vsync: this)..addListener(_onDemoTick);
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _build();
  }

  @override
  void didUpdateWidget(covariant TracingCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.units, widget.units)) {
      _build();
    } else if (oldWidget.tolerance != widget.tolerance) {
      _tracker.tolerance = widget.tolerance;
      _repaint.value++;
    }
    if (oldWidget.mode != widget.mode) {
      _tracker.reset();
      _repaint.value++;
      _maybeStartDemo();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _demo.dispose();
    _shake.dispose();
    _repaint.dispose();
    super.dispose();
  }

  void _build() {
    _tracker = StrokeTracker(units: widget.units, tolerance: widget.tolerance);
    _dashed
      ..clear()
      ..addAll(
        widget.units.map(
          (u) => u.path == null ? Path() : _dashPath(u.path!),
        ),
      );
    _demoUnit = 0;
    _repaint.value++;
    _maybeStartDemo();
  }

  void _maybeStartDemo() {
    _demo.stop();
    if (widget.mode != TracingMode.watch || widget.units.isEmpty) return;
    _demoUnit = 0;
    _tracker.reset();
    _demo
      ..duration = Duration(milliseconds: 900 * widget.units.length)
      ..forward(from: 0);
  }

  void _onDemoTick() {
    if (widget.units.isEmpty) return;
    final total = widget.units.length;
    final v = _demo.value * total;
    final unit = v.floor().clamp(0, total);
    _tracker.seek(unit: unit, progress: v - unit);
    if (unit != _demoUnit) {
      _demoUnit = unit;
      widget.onEvent?.call(
        TraceResult(
          advanced: true,
          unitCompleted: true,
          letterCompleted: unit >= total,
        ),
      );
    }
    _repaint.value++;
  }

  // --- Barmaq hadisələri -------------------------------------------------

  /// Ekran koordinatını hərf qutusunun koordinatına çevirir.
  Offset _toBox(Offset local, Size size) {
    final s = glyphScale(size);
    final o = glyphOrigin(size, s);
    return Offset((local.dx - o.dx) / s, (local.dy - o.dy) / s);
  }


  void _emit(TraceResult r) {
    if (r.rejected && !_shake.isAnimating) {
      _shake.forward(from: 0);
    }
    if (r.checkpoint || r.unitCompleted) {
      HapticFeedback.selectionClick();
    }
    _repaint.value++;
    if (r != TraceResult.none) widget.onEvent?.call(r);
  }

  bool get _interactive => widget.mode != TracingMode.watch;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return AnimatedBuilder(
          animation: _shake,
          builder: (context, child) {
            final t = _shake.value;
            // Sönən sinusoid — səhv toxunuşda qısa "yox" jesti.
            final dx = t == 0 ? 0.0 : math.sin(t * math.pi * 3) * 6 * (1 - t);
            return Transform.translate(offset: Offset(dx, 0), child: child);
          },
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: !_interactive
                ? null
                : (e) => _emit(_tracker.down(_toBox(e.localPosition, size))),
            onPointerMove: !_interactive
                ? null
                : (e) => _emit(_tracker.move(_toBox(e.localPosition, size))),
            onPointerUp: !_interactive ? null : (e) => _emit(_tracker.up()),
            onPointerCancel: !_interactive ? null : (e) => _emit(_tracker.up()),
            child: CustomPaint(
              size: size,
              painter: _TracingPainter(
                tracker: _tracker,
                dashed: _dashed,
                mode: widget.mode,
                pulse: _pulse,
                repaint: Listenable.merge([_repaint, _pulse]),
                inkColor: widget.inkColor,
                doneColor: widget.doneColor,
                roadColor: widget.roadColor,
                guideColor: widget.guideColor,
                startColor: widget.startColor,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Hərf qutusunu kətana sığdıran miqyas.
double glyphScale(Size size) => math.min(
  size.width / kGlyphBox.width,
  size.height / kGlyphBox.height,
);

/// Miqyaslanmış qutunun kətandakı sol-üst küncü (mərkəzlənmiş).
Offset glyphOrigin(Size size, double scale) => Offset(
  (size.width - kGlyphBox.width * scale) / 2,
  (size.height - kGlyphBox.height * scale) / 2,
);

/// Yolu qısa parçalara bölür — Flutter-də `strokeDashArray` olmadığı üçün.
Path _dashPath(Path source, {double on = 2.2, double off = 2.8}) {
  final out = Path();
  for (final m in source.computeMetrics()) {
    var d = 0.0;
    while (d < m.length) {
      final end = math.min(d + on, m.length);
      out.addPath(m.extractPath(d, end), Offset.zero);
      d = end + off;
    }
  }
  return out;
}

class _TracingPainter extends CustomPainter {
  _TracingPainter({
    required this.tracker,
    required this.dashed,
    required this.mode,
    required this.pulse,
    required Listenable repaint,
    required this.inkColor,
    required this.doneColor,
    required this.roadColor,
    required this.guideColor,
    required this.startColor,
  }) : super(repaint: repaint);

  final StrokeTracker tracker;
  final List<Path> dashed;
  final TracingMode mode;
  final Animation<double> pulse;
  final Color inkColor;
  final Color doneColor;
  final Color roadColor;
  final Color guideColor;
  final Color startColor;

  bool get _showRoad => mode != TracingMode.faded;
  bool get _showHints => mode != TracingMode.faded;

  @override
  void paint(Canvas canvas, Size size) {
    final s = glyphScale(size);
    final origin = glyphOrigin(size, s);

    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(s);

    _paintNotebook(canvas);

    final roadWidth = tracker.tolerance * 2;
    final inkWidth = math.max(3.4, roadWidth * 0.42);

    // 1) Yol — toleransın görünən qarşılığıdır: eni tam olaraq 2 x tolerans.
    if (_showRoad) {
      final road = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = roadWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = roadColor;
      final dotRoad = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = roadColor;
      for (final u in tracker.units) {
        if (u.kind == TraceUnitKind.stroke && u.path != null) {
          canvas.drawPath(u.path!, road);
        } else {
          canvas.drawCircle(u.start, roadWidth / 2, dotRoad);
        }
      }
    }

    // 2) Nöqtəli mərkəz xətti — "faded" rejimində yeganə bələdçi budur.
    final centre = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _showRoad ? 0.6 : 1.2
      ..strokeCap = StrokeCap.round
      ..color = guideColor.withAlpha(_showRoad ? 120 : 210);
    for (var i = 0; i < tracker.units.length; i++) {
      if (tracker.units[i].kind == TraceUnitKind.stroke) {
        canvas.drawPath(dashed[i], centre);
      } else if (!_showRoad) {
        canvas.drawCircle(tracker.units[i].start, roadWidth / 2, centre);
      }
    }

    // 3) Mürəkkəb — uşağın cızığı yox, ideal yolun dolmuş hissəsi.
    for (var i = 0; i < tracker.units.length; i++) {
      final u = tracker.units[i];
      final p = tracker.progressOf(i);
      if (p <= 0) continue;
      final done = i < tracker.unitIndex;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = inkWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = done ? doneColor : inkColor;

      if (u.kind == TraceUnitKind.stroke) {
        canvas.drawPath(u.partialPath(p), paint);
      } else {
        canvas.drawCircle(
          u.start,
          inkWidth * 0.75,
          Paint()..color = done ? doneColor : inkColor,
        );
      }
    }

    // 4) Başlanğıc nöqtəsi, nəbz və istiqamət oxu — yalnız cari ştrix üçün.
    final current = tracker.currentUnit;
    if (_showHints && current != null) {
      final at = current.kind == TraceUnitKind.stroke
          ? current.points[tracker.pointIndex]
          : current.start;

      if (current.kind == TraceUnitKind.stroke &&
          tracker.pointIndex < current.lastIndex) {
        _paintArrow(canvas, current);
      }

      final ring = 4.6 + pulse.value * 4.2;
      canvas.drawCircle(
        at,
        ring,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1
          ..color = startColor.withAlpha(((1 - pulse.value) * 140).toInt()),
      );
      canvas.drawCircle(at, 4.6, Paint()..color = startColor);
    }

    canvas.restore();

    // 5) Ştrix nömrəsi — ekran koordinatında çəkilir ki, kiçik şrift
    //    böyüdüləndə bulanıq görünməsin.
    if (_showHints && current != null) {
      final at = current.kind == TraceUnitKind.stroke
          ? current.points[tracker.pointIndex]
          : current.start;
      _paintNumber(
        canvas,
        Offset(origin.dx + at.dx * s, origin.dy + at.dy * s),
        tracker.unitIndex + 1,
        s,
      );
    }
  }

  /// Xətt dəftərinin dörd sətri — hərfin hündürlüyünü uşağa göstərir.
  void _paintNotebook(Canvas canvas) {
    final solid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = guideColor;
    final faint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = guideColor.withAlpha(140);

    for (final y in const [kCapLine, kMidLine, kDescLine]) {
      canvas.drawPath(
        _dashPath(
          Path()
            ..moveTo(3, y)
            ..lineTo(97, y),
          on: 2.6,
          off: 3,
        ),
        faint,
      );
    }
    canvas.drawLine(const Offset(3, kBaseLine), const Offset(97, kBaseLine), solid);
  }

  void _paintArrow(Canvas canvas, TraceUnit u) {
    // Oxu barmağın olduğu yerdən bir az irəlidə göstər ki, "bura get" desin.
    final ahead = (tracker.unitProgress + 0.12).clamp(0.0, 0.94);
    final at = u.points[(ahead * u.lastIndex).round()];
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(u.angleAt(ahead));
    canvas.drawPath(
      Path()
        ..moveTo(-2.6, -2.9)
        ..lineTo(3.4, 0)
        ..lineTo(-2.6, 2.9)
        ..close(),
      Paint()..color = startColor.withAlpha(200),
    );
    canvas.restore();
  }

  void _paintNumber(Canvas canvas, Offset at, int number, double scale) {
    final tp = TextPainter(
      text: TextSpan(
        text: '$number',
        style: TextStyle(
          color: Colors.white,
          fontSize: 5.4 * scale,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _TracingPainter old) =>
      old.tracker != tracker ||
      old.mode != mode ||
      old.inkColor != inkColor ||
      old.roadColor != roadColor;
}
