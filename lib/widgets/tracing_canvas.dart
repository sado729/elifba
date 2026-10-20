import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/settings.dart';
import '../core/stroke_tracker.dart';
import '../theme/theme.dart';

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

/// Kətanın rəngləri (ScreenTrace, açıq səma fonu).
///
/// Şəffaf çalarlar burada YOX, kətanda verilir: [start] halqası 20 %,
/// [fingerHalo] 14 % ilə çəkilir — palitra yalnız rolun rəngini daşıyır.
@immutable
class TracingPalette {
  const TracingPalette({
    required this.line,
    required this.midLine,
    required this.descLine,
    required this.road,
    required this.centre,
    required this.ink,
    required this.inkDone,
    required this.letterDone,
    required this.start,
    required this.onStart,
    required this.fingerHalo,
    required this.hand,
    required this.wrong,
    required this.wrongFill,
  });

  /// Cap və əsas sətir: #C6B8F5 (Lavanda dəstinin kənarı).
  final Color line;

  /// Orta sətir (qırıq): #D2C8F2.
  final Color midLine;

  /// Aşağı (diakritik) sətir: #E6E1F5.
  final Color descLine;

  /// Yol: #E9E2FF.
  final Color road;

  /// Mərkəz xətti — qırıq və ya nöqtəli: #A99FE0.
  final Color centre;

  /// Cari ştrixin mürəkkəbi: #7C63D9.
  final Color ink;

  /// Bitmiş ştrixin mürəkkəbi: #9C86E6.
  final Color inkDone;

  /// Bütün hərf bitəndə (qızılı hərf): #FFB547.
  final Color letterDone;

  /// Başlanğıc nöqtəsi, onun halqası (20 %) və istiqamət oxu: #2E9460.
  final Color start;

  /// Başlanğıc nöqtəsindəki ştrix nömrəsi: #FFFDFB.
  final Color onStart;

  /// Barmağın ucundakı halqa (14 % ilə çəkilir): #7C63D9.
  final Color fingerHalo;

  /// «Bax» rejimindəki əl: #5C45B5.
  final Color hand;

  /// Səhv toxunuş nişanının konturu və ✕-i: #DD4A5A.
  final Color wrong;

  /// Səhv toxunuş nişanının üzü: #FCE1E4.
  final Color wrongFill;

  static const TracingPalette light = TracingPalette(
    // Lavanda dəstinin kənarı ilə eyni hex (#C6B8F5).
    line: ElifbaPalette.playingEdge,
    midLine: ElifbaPalette.outline,
    descLine: ElifbaPalette.outlineVariant,
    road: ElifbaPalette.traceRoad,
    centre: ElifbaPalette.traceCentre,
    ink: ElifbaPalette.secondary,
    inkDone: ElifbaPalette.traceInkDone,
    letterDone: ElifbaPalette.primary,
    start: ElifbaPalette.correct,
    onStart: ElifbaPalette.onSecondary,
    fingerHalo: ElifbaPalette.secondary,
    hand: ElifbaPalette.secondaryEdge,
    wrong: ElifbaPalette.error,
    wrongFill: ElifbaPalette.errorContainer,
  );

  @override
  bool operator ==(Object other) =>
      other is TracingPalette &&
      other.line == line &&
      other.midLine == midLine &&
      other.descLine == descLine &&
      other.road == road &&
      other.centre == centre &&
      other.ink == ink &&
      other.inkDone == inkDone &&
      other.letterDone == letterDone &&
      other.start == start &&
      other.onStart == onStart &&
      other.fingerHalo == fingerHalo &&
      other.hand == hand &&
      other.wrong == wrong &&
      other.wrongFill == wrongFill;

  @override
  int get hashCode => Object.hash(
    line,
    midLine,
    descLine,
    road,
    centre,
    ink,
    inkDone,
    letterDone,
    start,
    onStart,
    fingerHalo,
    hand,
    wrong,
    wrongFill,
  );
}

// --- Ölçülər (qutu vahidi) --------------------------------------------------
// Dizayn hərfi `viewBox 220 x 270`-də çəkir; 360 dp ekranda 1 dizayn vahidi
// 0.446 qutu vahidinə bərabərdir (trace.md §3). Mötərizədə dizayn dəyəri.

/// Mürəkkəbin eni toleransa nisbətən: 9 x 1.1 = 9.9 (dizayn 22). Yol
/// isə 2 x toleransdır — görünən yol qəbul edilən zolağın özüdür.
const double _kInkPerTolerance = 1.1;

/// Nöqtə vahidinin mürəkkəb diskinin radiusu mürəkkəb eninə nisbətən.
const double _kDotInkFactor = 0.6;

const double _kCapLineWidth = 0.89; // (2)
const double _kMidLineWidth = 0.67; // (1.5)
const double _kMidLineDash = 2.68; // (6 6)
const double _kDescLineWidth = 0.67; // (1.5)

const double _kCentreWidth = 1.12; // (2.5)
const double _kCentreDash = 2.68; // (6)
const double _kCentreGap = 3.57; // (8)
const double _kDottedWidth = 1.78; // (4)
const double _kDottedOn = 0.045; // (0.1)
const double _kDottedOff = 4.01; // (9)

const double _kStartHalo = 10.26; // (r 23)
const double _kStartHaloBreath = 1.78; // (r 23 → 27)
const int _kStartHaloAlpha = 51; // 20 %
const double _kStartDot = 6.69; // (r 15)
const double _kNumberSize = 6.69; // (15)

const double _kArrowStroke = 1.34; // (3)
const double _kArrowLead = 0.07;
const double _kArrowMinLead = 14;

const double _kFingerHalo = 8.92; // (r 20)
const int _kFingerHaloAlpha = 35; // 14 %

const double _kHandSize = 15.16; // (34)
const Offset _kHandOffset = Offset(-2.68, -1.78); // (−6, −4)

const double _kWrongRadius = 7.14; // (r 16)
const double _kWrongStroke = 1.12; // (2.5)
const double _kWrongDash = 1.78; // (4 4)
const double _kWrongCross = 2.68; // (6)
const double _kWrongCrossWidth = 1.34; // (3)

/// Barmaqla hərf cızma kətanı.
///
/// Uşağın xam cızığı DEYİL, ideal yolun tədricən dolan hissəsi çəkilir — nəticə
/// həmişə səliqəli hərf kimi görünür. Bu, oyunun əsas UX qərarıdır.
///
/// Vacib: bu widget `setState` çağırmır. İrəliləyiş `_repaint` notifier-i ilə
/// yalnız [CustomPainter]-ə çatdırılır, ona görə barmaq hərəkət edərkən nə bu
/// widget, nə də valideyn səhifə yenidən qurulmur.
///
/// Kətan özü titrəmir: səhv toxunuşda bütün kartı səhifə silkələyir (nəticə
/// `onEvent` ilə ona çatır). Kətan isə toxunulan yerdə ✕ nişanı çəkir — o,
/// azaldılmış hərəkətdə də görünür. Kətanın öz kartı, boşluğu, kəsimi yoxdur:
/// bunlar səhifədədir (`tracing_canvas_test` miqyası dəqiq 2.0 gözləyir).
class TracingCanvas extends StatefulWidget {
  const TracingCanvas({
    super.key,
    required this.units,
    required this.mode,
    this.tolerance = StrokeTracker.defaultTolerance,
    this.onEvent,
    this.palette = TracingPalette.light,
  });

  /// Cızılacaq ştrixlər və nöqtələr, sıra ilə.
  final List<TraceUnit> units;

  final TracingMode mode;

  /// Barmağın yoldan neçə qutu vahidi kənara çıxa biləcəyi.
  final double tolerance;

  /// Hər barmaq hadisəsinin nəticəsi — səs, haptika, silkələnmə və konfeti
  /// üçün.
  final ValueChanged<TraceResult>? onEvent;

  final TracingPalette palette;

  @override
  State<TracingCanvas> createState() => _TracingCanvasState();
}

class _TracingCanvasState extends State<TracingCanvas>
    with TickerProviderStateMixin {
  late StrokeTracker _tracker;

  /// Barmaq hərəkət etdikcə yalnız bunu artırırıq — `setState` yoxdur.
  final ValueNotifier<int> _repaint = ValueNotifier<int>(0);

  /// Başlanğıc nöqtəsi halqasının nəfəsi və nümayiş animasiyası.
  late final AnimationController _pulse;
  late final AnimationController _demo;

  /// Səhv toxunuşun ✕ nişanı: yeri (ekran koordinatı) və 900 ms-lik ömrü.
  final ValueNotifier<Offset?> _rejectAt = ValueNotifier<Offset?>(null);
  late final AnimationController _reject;

  /// Mərkəz xəttinin konturları hər kadrda yenidən hesablanmasın deyə
  /// keşlənir: qırıq («Bax», «İzlə») və nöqtəli («Təkrarla»).
  final List<Path> _dashed = <Path>[];
  final List<Path> _dotted = <Path>[];

  int _demoUnit = 0;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: ElifbaMotion.tracePulse,
    );
    // Azaldılmış hərəkətdə halqa nəfəs almır — sabit dizayn ölçüsündə qalır.
    // Valideyn sahəsi bu səhifə açıqkən açıla bilmir, dinləyici lazım deyil.
    if (!AppSettings.instance.reduceMotion) _pulse.repeat();
    _demo = AnimationController(vsync: this)..addListener(_onDemoTick);
    _reject = AnimationController(
      vsync: this,
      duration: ElifbaMotion.traceRejectMarker,
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) _rejectAt.value = null;
    });
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
    _reject.dispose();
    _rejectAt.dispose();
    _repaint.dispose();
    super.dispose();
  }

  void _build() {
    _tracker = StrokeTracker(units: widget.units, tolerance: widget.tolerance);
    _dashed
      ..clear()
      ..addAll(
        widget.units.map(
          (u) => u.path == null
              ? Path()
              : _dashPath(u.path!, on: _kCentreDash, off: _kCentreGap),
        ),
      );
    _dotted
      ..clear()
      ..addAll(
        widget.units.map(
          (u) => u.path == null
              ? Path()
              : _dashPath(u.path!, on: _kDottedOn, off: _kDottedOff),
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
      ..duration = ElifbaMotion.traceDemoPerUnit * widget.units.length
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

  void _down(Offset local, Size size) {
    final r = _tracker.down(_toBox(local, size));
    if (r.rejected) {
      // Yeni səhv toxunuş görünən nişanı yerindən tərpədir və yenidən başladır.
      _rejectAt.value = local;
      _reject.forward(from: 0);
    }
    _emit(r);
  }

  void _emit(TraceResult r) {
    // Titrəmə valideyn ayarından söndürülə bilər.
    if ((r.checkpoint || r.unitCompleted) && AppSettings.instance.haptics) {
      HapticFeedback.selectionClick();
    }
    _repaint.value++;
    if (r != TraceResult.none) widget.onEvent?.call(r);
  }

  bool get _interactive => widget.mode != TracingMode.watch;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AppSettings.instance.reduceMotion;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: !_interactive
              ? null
              : (e) => _down(e.localPosition, size),
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
              dotted: _dotted,
              mode: widget.mode,
              palette: widget.palette,
              pulse: _pulse,
              reject: _reject,
              rejectAt: _rejectAt,
              reduceMotion: reduceMotion,
              repaint: Listenable.merge([_repaint, _pulse, _reject, _rejectAt]),
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
Path _dashPath(Path source, {required double on, required double off}) {
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
    required this.dotted,
    required this.mode,
    required this.palette,
    required this.pulse,
    required this.reject,
    required this.rejectAt,
    required this.reduceMotion,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final StrokeTracker tracker;
  final List<Path> dashed;
  final List<Path> dotted;
  final TracingMode mode;
  final TracingPalette palette;
  final Animation<double> pulse;
  final AnimationController reject;
  final ValueListenable<Offset?> rejectAt;
  final bool reduceMotion;

  /// ✕ nişanının qırıq konturu — öz vahidində, bir dəfə qurulur.
  static final Path _wrongRing = _dashPath(
    Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: _kWrongRadius)),
    on: _kWrongDash,
    off: _kWrongDash,
  );

  bool get _guided => mode == TracingMode.guided;

  @override
  void paint(Canvas canvas, Size size) {
    final s = glyphScale(size);
    if (s <= 0) return;
    final origin = glyphOrigin(size, s);

    final roadWidth = tracker.tolerance * 2;
    final inkWidth = tracker.tolerance * _kInkPerTolerance;
    final dotInk = inkWidth * _kDotInkFactor;

    final current = tracker.currentUnit;
    // Tracker-in qəbul etdiyi yeganə yer: ştrixdə qaldığı nöqtə, nöqtədə
    // nöqtənin özü (`StrokeTracker.down`).
    final Offset? resume = current == null
        ? null
        : current.kind == TraceUnitKind.stroke
        ? current.points[tracker.pointIndex]
        : current.start;
    // Barmaq ştrixin ortasında ekrandadırsa yaşıl nöqtə gizlənir — ucu
    // bənövşəyi barmaq halqası göstərir. Barmaq qalxanda nöqtə ucda çıxır.
    final showStart =
        _guided &&
        current != null &&
        (current.kind == TraceUnitKind.dot ||
            tracker.pointIndex == 0 ||
            !tracker.isDrawing);

    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(s);

    // 1) Xətt dəftəri — kətanın bütün eni boyu.
    _paintRuling(canvas, -origin.dx / s, (size.width - origin.dx) / s);

    // 2) Yol — toleransın görünən qarşılığıdır: eni tam olaraq 2 x tolerans.
    if (mode != TracingMode.faded) _paintRoad(canvas, roadWidth);

    // 3) Mərkəz xətti: qırıq, «Təkrarla»-da nöqtəli (yeganə bələdçi).
    _paintCentre(canvas, dotInk);

    // 4) Mürəkkəb — uşağın cızığı yox, ideal yolun dolmuş hissəsi.
    _paintInk(canvas, inkWidth, dotInk);

    // 5) Başlanğıc halqası və nöqtəsi.
    if (showStart) _paintStart(canvas, resume!);
    canvas.restore();

    // Ştrix nömrəsi ekran koordinatında çəkilir ki, böyüdüləndə bulanmasın.
    if (showStart) {
      _paintNumber(canvas, origin + resume! * s, tracker.unitIndex + 1, s);
    }

    // 6) İstiqamət oxu və barmaq halqası — yalnız ştrixdə.
    if (_guided && current != null && current.kind == TraceUnitKind.stroke) {
      canvas.save();
      canvas.translate(origin.dx, origin.dy);
      canvas.scale(s);
      if (tracker.pointIndex < current.lastIndex) _paintArrow(canvas, current);
      if (tracker.isDrawing && tracker.pointIndex > 0) {
        canvas.drawCircle(
          current.points[tracker.pointIndex],
          _kFingerHalo,
          Paint()..color = palette.fingerHalo.withAlpha(_kFingerHaloAlpha),
        );
      }
      canvas.restore();
    }

    // 7) «Bax» rejimində mürəkkəbin ucunu izləyən əl.
    if (mode == TracingMode.watch && resume != null) {
      _paintHand(canvas, origin + resume * s, s);
    }

    // 8) Səhv toxunuş nişanı — həmişə ən üstdə.
    _paintReject(canvas, size, s);
  }

  /// Xətt dəftərinin dörd sətri — hərfin hündürlüyünü uşağa göstərir.
  void _paintRuling(Canvas canvas, double x0, double x1) {
    final solid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _kCapLineWidth
      ..color = palette.line;
    canvas.drawLine(Offset(x0, kCapLine), Offset(x1, kCapLine), solid);
    canvas.drawLine(Offset(x0, kBaseLine), Offset(x1, kBaseLine), solid);
    canvas.drawPath(
      _dashPath(
        Path()
          ..moveTo(x0, kMidLine)
          ..lineTo(x1, kMidLine),
        on: _kMidLineDash,
        off: _kMidLineDash,
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _kMidLineWidth
        ..color = palette.midLine,
    );
    canvas.drawLine(
      Offset(x0, kDescLine),
      Offset(x1, kDescLine),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _kDescLineWidth
        ..color = palette.descLine,
    );
  }

  void _paintRoad(Canvas canvas, double roadWidth) {
    final road = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = roadWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = palette.road;
    final dotRoad = Paint()..color = palette.road;
    for (final u in tracker.units) {
      if (u.kind == TraceUnitKind.stroke && u.path != null) {
        canvas.drawPath(u.path!, road);
      } else {
        canvas.drawCircle(u.start, roadWidth / 2, dotRoad);
      }
    }
  }

  void _paintCentre(Canvas canvas, double dotInk) {
    final faded = mode == TracingMode.faded;
    final centre = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = faded ? _kDottedWidth : _kCentreWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = palette.centre;
    for (var i = 0; i < tracker.units.length; i++) {
      final u = tracker.units[i];
      if (u.kind == TraceUnitKind.stroke) {
        canvas.drawPath(faded ? dotted[i] : dashed[i], centre);
      } else if (faded) {
        canvas.drawPath(
          _dashPath(
            Path()..addOval(Rect.fromCircle(center: u.start, radius: dotInk)),
            on: _kDottedOn,
            off: _kDottedOff,
          ),
          centre,
        );
      }
    }
  }

  void _paintInk(Canvas canvas, double inkWidth, double dotInk) {
    // Qızılı hərf uşağın öz uğurudur — nümayişin sonunda çəkilmir.
    final letterDone = tracker.isComplete && mode != TracingMode.watch;
    for (var i = 0; i < tracker.units.length; i++) {
      final u = tracker.units[i];
      final p = tracker.progressOf(i);
      if (p <= 0) continue;
      final color = letterDone
          ? palette.letterDone
          : i < tracker.unitIndex
          ? palette.inkDone
          : palette.ink;
      if (u.kind == TraceUnitKind.stroke) {
        canvas.drawPath(
          u.partialPath(p),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = inkWidth
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = color,
        );
      } else {
        canvas.drawCircle(u.start, dotInk, Paint()..color = color);
      }
    }
  }

  void _paintStart(Canvas canvas, Offset at) {
    // Halqa 1600 ms-də bir dəfə r 23 → 27 → 23 (dizayn vahidi) nəfəs alır.
    final c = reduceMotion
        ? 0.0
        : 0.5 - 0.5 * math.cos(2 * math.pi * pulse.value);
    canvas.drawCircle(
      at,
      _kStartHalo + _kStartHaloBreath * c,
      Paint()..color = palette.start.withAlpha(_kStartHaloAlpha),
    );
    canvas.drawCircle(at, _kStartDot, Paint()..color = palette.start);
  }

  void _paintArrow(Canvas canvas, TraceUnit u) {
    // Oxu barmağın olduğu yerdən bir az irəlidə göstər ki, "bura get" desin.
    // Ən azı 14 qutu vahidi: ox başlanğıc nöqtəsinin və barmağın altında
    // qalmasın.
    final lead = math.max(_kArrowLead, _kArrowMinLead / u.length);
    final ahead = (tracker.unitProgress + lead).clamp(0.0, 0.94);
    final at = u.points[(ahead * u.lastIndex).round()];
    final arrow = Path()
      ..moveTo(-4.01, -3.57)
      ..lineTo(3.12, 0)
      ..lineTo(-4.01, 3.57)
      ..close();
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(u.angleAt(ahead));
    canvas.drawPath(arrow, Paint()..color = palette.start);
    // Kontur küncləri yumrulaşdırır (dizayn: stroke-linejoin round).
    canvas.drawPath(
      arrow,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _kArrowStroke
        ..strokeJoin = StrokeJoin.round
        ..color = palette.start,
    );
    canvas.restore();
  }

  void _paintNumber(Canvas canvas, Offset at, int number, double scale) {
    final fontSize = _kNumberSize * scale;
    final tp = TextPainter(
      text: TextSpan(
        text: '$number',
        style: TextStyle(
          fontFamily: ElifbaTypography.display,
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
          height: 1,
          letterSpacing: 0,
          color: palette.onStart,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    // Dizayn: mətnin əsas xətti nöqtənin mərkəzindən şrift ölçüsünün 1/3-i
    // qədər aşağıdadır (font-size 15-də `y + 5`).
    final baseline = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    tp.paint(
      canvas,
      Offset(at.dx - tp.width / 2, at.dy + fontSize / 3 - baseline),
    );
    tp.dispose();
  }

  void _paintHand(Canvas canvas, Offset tip, double scale) {
    // Sabit `IconData` — ikon ağacdan atılmasın (tree-shaking).
    const icon = Icons.pan_tool_alt_rounded;
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          inherit: false,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: _kHandSize * scale,
          height: 1,
          color: palette.hand,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, tip + _kHandOffset * scale);
    tp.dispose();
  }

  void _paintReject(Canvas canvas, Size size, double s) {
    final at = rejectAt.value;
    if (at == null || !reject.isAnimating) return;

    final total = ElifbaMotion.traceRejectMarker.inMilliseconds.toDouble();
    final scaleIn = ElifbaMotion.traceRejectScaleIn.inMilliseconds.toDouble();
    final fadeStart = ElifbaMotion.traceRejectFadeStart.inMilliseconds
        .toDouble();
    final ms = reject.value * total;

    // Azaldılmış hərəkətdə nişan böyümür — dərhal tam ölçüdə görünür.
    var k = 1.0;
    if (!reduceMotion && ms < scaleIn) {
      const from = ElifbaMotion.traceRejectScaleFrom;
      k = from +
          (1 - from) *
              ElifbaMotion.traceRejectScaleInCurve.transform(ms / scaleIn);
    }
    final opacity = ms <= fadeStart
        ? 1.0
        : (1 - (ms - fadeStart) / (total - fadeStart)).clamp(0.0, 1.0);
    if (opacity <= 0) return;

    // Nişan kətanın kənarında kəsilməsin.
    final r = (_kWrongRadius + _kWrongStroke / 2) * s;
    final cx = at.dx.clamp(r + 2, math.max<double>(r + 2, size.width - r - 2));
    final cy = at.dy.clamp(r + 2, math.max<double>(r + 2, size.height - r - 2));

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(s * k);
    if (opacity < 1) {
      canvas.saveLayer(
        Rect.fromCircle(center: Offset.zero, radius: _kWrongRadius + 2),
        Paint()..color = palette.wrong.withAlpha((opacity * 255).toInt()),
      );
    }
    canvas.drawCircle(
      Offset.zero,
      _kWrongRadius,
      Paint()..color = palette.wrongFill,
    );
    canvas.drawPath(
      _wrongRing,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _kWrongStroke
        ..color = palette.wrong,
    );
    final cross = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _kWrongCrossWidth
      ..strokeCap = StrokeCap.round
      ..color = palette.wrong;
    canvas.drawLine(
      const Offset(-_kWrongCross, -_kWrongCross),
      const Offset(_kWrongCross, _kWrongCross),
      cross,
    );
    canvas.drawLine(
      const Offset(_kWrongCross, -_kWrongCross),
      const Offset(-_kWrongCross, _kWrongCross),
      cross,
    );
    if (opacity < 1) canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TracingPainter old) =>
      old.tracker != tracker ||
      old.mode != mode ||
      old.palette != palette ||
      old.reduceMotion != reduceMotion;
}
