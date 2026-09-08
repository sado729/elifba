import 'dart:math' as math;
import 'dart:ui';

/// Cızma vahidinin növü.
enum TraceUnitKind {
  /// Barmaqla izlənən yol.
  stroke,

  /// Toxunuşla tamamlanan nöqtə — İ, Ö, Ü hərflərinin nöqtələri.
  /// Uzunluğu sıfır olan bir yolu cızmaq mümkün olmadığı üçün ayrı haldır.
  dot,
}

/// Bir cızma vahidinin bərabər aralıqlı nöqtələri.
///
/// `Path.computeMetrics()` yolu qövs uzunluğuna görə ölçür, ona görə
/// `getTangentForOffset()` ilə alınan nöqtələr əyrinin sıxlığından asılı
/// olmayaraq bərabər məsafədə düşür. Bu vacibdir: toleransın yolun düz
/// hissəsində və kəskin döngəsində eyni mənaya gəlməsi buna bağlıdır.
class TraceUnit {
  TraceUnit._({
    required this.kind,
    required this.points,
    required this.length,
    required this.metrics,
    this.path,
  });

  /// İki sample arasındakı məsafə — qutu vahidi ilə (hərflər 100x104 qutusunda).
  static const double sampleStep = 1.2;

  final TraceUnitKind kind;

  /// Yolun bərabər aralıqlı nöqtələri. Nöqtə vahidində tək element olur.
  final List<Offset> points;

  /// Yolun tam uzunluğu (qutu vahidi). Nöqtə vahidində 0.
  final double length;

  /// Çəkiliş zamanı `extractPath` üçün saxlanılır — hər kadrda yenidən
  /// hesablamamaq üçün. Yol dəyişməz olduğu üçün təhlükəsizdir.
  final List<PathMetric> metrics;

  /// Nöqtə vahidində null.
  final Path? path;

  /// İzlənən yolun başlanğıcı (nöqtə vahidində nöqtənin özü).
  Offset get start => points.first;

  /// İzlənən yolun sonu.
  Offset get end => points.last;

  /// `points` massivinin son indeksi.
  int get lastIndex => points.length - 1;

  /// Yolu bərabər aralıqlarla sample-layaraq izlənə bilən vahid qurur.
  factory TraceUnit.stroke(Path path) {
    final metrics = path.computeMetrics().toList(growable: false);
    var total = 0.0;
    for (final m in metrics) {
      total += m.length;
    }

    // Uzunluğu olmayan yol (məsələn eyni nöqtədən eyni nöqtəyə) cızıla bilməz;
    // onu nöqtə kimi qəbul etmək donmuş vəziyyətdən yaxşıdır.
    if (metrics.isEmpty || total <= 0) {
      final at = metrics.isEmpty
          ? Offset.zero
          : (metrics.first.getTangentForOffset(0)?.position ?? Offset.zero);
      return TraceUnit.dot(at);
    }

    final count = math.max(1, (total / sampleStep).ceil());
    final points = <Offset>[
      for (var i = 0; i <= count; i++) _pointAt(metrics, total * i / count),
    ];

    return TraceUnit._(
      kind: TraceUnitKind.stroke,
      points: points,
      length: total,
      metrics: metrics,
      path: path,
    );
  }

  /// Toxunuşla tamamlanan nöqtə vahidi.
  factory TraceUnit.dot(Offset centre) => TraceUnit._(
    kind: TraceUnitKind.dot,
    points: <Offset>[centre],
    length: 0,
    metrics: const <PathMetric>[],
  );

  static Offset _pointAt(List<PathMetric> metrics, double distance) {
    var remaining = distance;
    for (var i = 0; i < metrics.length; i++) {
      final m = metrics[i];
      final isLast = i == metrics.length - 1;
      if (remaining <= m.length || isLast) {
        final clamped = remaining.clamp(0.0, m.length);
        return m.getTangentForOffset(clamped)?.position ?? Offset.zero;
      }
      remaining -= m.length;
    }
    return Offset.zero;
  }

  /// Yolun `progress` (0..1) qədər hissəsi. Uşağın əyri cızığı yox, məhz bu
  /// çəkilir — nəticə həmişə səliqəli hərf kimi görünsün deyə.
  Path partialPath(double progress) {
    final out = Path();
    if (kind != TraceUnitKind.stroke || metrics.isEmpty) return out;
    var wanted = (progress.clamp(0.0, 1.0)) * length;
    for (final m in metrics) {
      if (wanted <= 0) break;
      final take = math.min(wanted, m.length);
      out.addPath(m.extractPath(0, take), Offset.zero);
      wanted -= take;
    }
    return out;
  }

  /// Yolun `at` (0..1) mövqeyindəki istiqaməti — istiqamət oxunu döndərmək üçün.
  double angleAt(double at) {
    if (kind != TraceUnitKind.stroke || points.length < 2) return 0;
    final i = (at.clamp(0.0, 1.0) * lastIndex).round();
    final a = points[math.min(i, lastIndex - 1)];
    final b = points[math.min(i + 1, lastIndex)];
    return math.atan2(b.dy - a.dy, b.dx - a.dx);
  }
}

/// Bir barmaq hərəkətinin nəticəsi. Widget bunu səsə, haptikaya və konfetiyə
/// çevirir; mühərrikin özü heç bir yan effekt yaratmır.
class TraceResult {
  const TraceResult({
    this.advanced = false,
    this.checkpoint = false,
    this.unitCompleted = false,
    this.letterCompleted = false,
    this.rejected = false,
  });

  /// İrəliləyiş oldu.
  final bool advanced;

  /// Növbəti yoxlama nöqtəsi keçildi — yüngül haptika üçün.
  final bool checkpoint;

  /// Cari ştrix (və ya nöqtə) tamamlandı.
  final bool unitCompleted;

  /// Hərfin bütün ştrixləri bitdi.
  final bool letterCompleted;

  /// Toxunuş qəbul edilmədi — barmaq başlanğıc nöqtəsindən uzaqdır.
  final bool rejected;

  static const TraceResult none = TraceResult();
}

/// Hərf cızma mühərriki.
///
/// Bütün koordinatlar hərfin öz qutusundadır (100x104), ekran piksellərində
/// deyil — kətan barmağın mövqeyini bu qutuya çevirib ötürür. Beləliklə
/// tolerans ekran ölçüsündən asılı olmur.
///
/// Dörd qayda alqoritmin özəyidir:
///  1. İndeks yalnız irəli gedir. Geri-irəli cızmaq irəliləyiş saymır, amma
///     cəza da vermir — uşaq tərəddüd edə bilər.
///  2. İrəli baxış pəncərəsi: növbəti [lookAhead] sample içində tolerans
///     daxilində olan ən uzaq nöqtəyə tullanılır ki, sürətli barmaq ilişməsin.
///  3. İki pointer hadisəsi arası interpolyasiya olunur — əks halda sürətli
///     hərəkətdə yol qırılır.
///  4. Zəncirləmə: ştrix bitəndə barmaq növbəti ştrixin başlanğıcındadırsa,
///     cızma qaldırmadan davam edir (bax [_completeUnit]).
class StrokeTracker {
  StrokeTracker({required this.units, double tolerance = defaultTolerance})
    : _tolerance = tolerance;

  /// Barmağın yoldan neçə vahid kənara çıxa biləcəyi (qutu vahidi).
  /// Yolun görünən eni bunun iki mislidir.
  static const double defaultTolerance = 9.0;

  /// Bir hərəkətdə neçə sample irəli tullanmağa icazə verilir.
  static const int lookAhead = 26;

  /// Başlanğıc nöqtəsinə toxunuş toleransı bir qədər səxavətlidir.
  static const double startFactor = 1.4;

  /// Bundan uzaq toxunuş "yoldan çıxma" sayılır.
  static const double offTrackFactor = 1.9;

  /// Bir ştrix boyunca neçə haptika nöqtəsi olsun.
  static const int checkpointCount = 8;

  /// İki ştrixin "bitişik" sayılması üçün uc-başlanğıc məsafəsi (qutu vahidi).
  /// `letter_strokes.dart`-da həqiqi bitişik ştrixlərin ucları tam üst-üstə
  /// düşür (məsafə 0), ona görə bu hədd qəsdən çox kiçikdir — yaxın, amma
  /// qəsdən ayrı ştrixlər (`R`) zəncirlənməsin.
  static const double joinEpsilon = 2.0;

  /// Bu qədər yoldan çıxmadan sonra ipucu göstərmək məsləhətdir.
  static const int hintThreshold = 14;

  final List<TraceUnit> units;

  double _tolerance;
  int _unitIndex = 0;
  int _pointIndex = 0;
  int _offTrack = 0;
  bool _drawing = false;
  Offset? _last;

  double get tolerance => _tolerance;
  set tolerance(double value) => _tolerance = math.max(0.5, value);

  int get unitIndex => _unitIndex;
  int get pointIndex => _pointIndex;
  int get offTrackCount => _offTrack;
  bool get isDrawing => _drawing;
  bool get isComplete => _unitIndex >= units.length;
  bool get needsHint => _offTrack >= hintThreshold;

  TraceUnit? get currentUnit => isComplete ? null : units[_unitIndex];

  /// Cari ştrixin nə qədəri cızılıb (0..1).
  double get unitProgress {
    final u = currentUnit;
    if (u == null) return 1;
    if (u.kind == TraceUnitKind.dot || u.lastIndex <= 0) return 0;
    return _pointIndex / u.lastIndex;
  }

  /// Bütün hərfin nə qədəri cızılıb (0..1).
  double get overallProgress {
    if (units.isEmpty || isComplete) return 1;
    return (_unitIndex + unitProgress) / units.length;
  }

  /// `index`-ci vahidin nə qədərinin çəkilməli olduğu — kətan bunu işlədir.
  double progressOf(int index) {
    if (index < _unitIndex) return 1;
    if (index > _unitIndex) return 0;
    return unitProgress;
  }

  void reset() {
    _unitIndex = 0;
    _pointIndex = 0;
    _offTrack = 0;
    _drawing = false;
    _last = null;
  }

  /// Nümayiş ("Bax") rejimi üçün: irəliləyişi kənardan təyin edir.
  void seek({required int unit, required double progress}) {
    _unitIndex = unit.clamp(0, units.length);
    _drawing = false;
    _last = null;
    final u = currentUnit;
    _pointIndex = (u == null || u.lastIndex <= 0)
        ? 0
        : (progress.clamp(0.0, 1.0) * u.lastIndex).round();
  }

  /// Barmaq toxundu. Cari ştrixin başlanğıcına (və ya barmağın qaldırıldığı
  /// yerə) yaxındırsa cızma başlayır; nöqtə vahidində isə dərhal tamamlanır.
  TraceResult down(Offset p) {
    final u = currentUnit;
    if (u == null) return TraceResult.none;

    if (u.kind == TraceUnitKind.dot) {
      if ((p - u.start).distance <= _tolerance * startFactor) {
        return _completeUnit();
      }
      return const TraceResult(rejected: true);
    }

    // `_pointIndex` sıfır olmaya bilər: uşaq ştrixin ortasında barmağını
    // qaldırıbsa, qaldığı yerdən davam etməsinə icazə veririk.
    if ((p - u.points[_pointIndex]).distance <= _tolerance * startFactor) {
      _drawing = true;
      _last = p;
      return const TraceResult();
    }
    return const TraceResult(rejected: true);
  }

  /// Barmaq hərəkət etdi.
  TraceResult move(Offset p) {
    if (!_drawing) return TraceResult.none;
    final u = currentUnit;
    if (u == null || u.kind != TraceUnitKind.stroke) return TraceResult.none;

    final from = _last ?? p;
    final before = _pointIndex;

    // Hadisələr arası boşluğu doldur — 60 Hz-də sürətli barmaq bir kadrda
    // yolun yarısını keçə bilər və aralıq nöqtələr olmadan irəliləyiş dayanır.
    final gap = (p - from).distance;
    final steps = (gap / math.max(0.001, _tolerance * 0.5)).ceil().clamp(1, 64);
    for (var i = 1; i <= steps; i++) {
      final t = i / steps;
      _advance(
        Offset(from.dx + (p.dx - from.dx) * t, from.dy + (p.dy - from.dy) * t),
        u,
      );
    }
    _last = p;

    // Barmaq hələ ekrandadır: bitişik növbəti ştrix qaldırmadan başlasın.
    if (_pointIndex >= u.lastIndex) return _completeUnit(at: p);

    final advanced = _pointIndex > before;
    return TraceResult(
      advanced: advanced,
      checkpoint:
          advanced && _crossedCheckpoint(before, _pointIndex, u.lastIndex),
    );
  }

  /// Barmaq qalxdı. İrəliləyiş SAXLANILIR — uşaq davam edə bilsin deyə.
  TraceResult up() {
    _drawing = false;
    _last = null;
    return TraceResult.none;
  }

  void _advance(Offset q, TraceUnit u) {
    var best = _pointIndex;
    final end = math.min(_pointIndex + lookAhead, u.lastIndex);
    for (var j = _pointIndex + 1; j <= end; j++) {
      if ((q - u.points[j]).distance <= _tolerance) best = j;
    }
    if (best > _pointIndex) {
      _pointIndex = best;
    } else if ((q - u.points[_pointIndex]).distance >
        _tolerance * offTrackFactor) {
      _offTrack++;
    }
  }

  bool _crossedCheckpoint(int before, int after, int lastIndex) {
    if (lastIndex <= 0) return false;
    final a = (before / lastIndex * checkpointCount).floor();
    final b = (after / lastIndex * checkpointCount).floor();
    return b > a;
  }

  /// Cari vahidi bitirib növbətisinə keçir.
  ///
  /// [at] yalnız [move] yolundan verilir və barmağın həmin andakı faktiki
  /// mövqeyidir — yəni barmaq hələ ekrandadır. Növbəti vahid ştrixdirsə və
  /// barmaq onun başlanğıcına kifayət qədər yaxındırsa cızma **qaldırmadan**
  /// davam edir (zəncirləmə): `_drawing` sönmür, `_last` barmaqda qalır.
  ///
  /// İKİ şərt birlikdə tələb olunur: (1) datada bitən ştrixin ucu ilə növbəti
  /// ştrixin başlanğıcı üst-üstə düşməlidir ([joinEpsilon]), (2) barmaq həmin
  /// başlanğıcın yaxınlığında olmalıdır. Yalnız barmağın mövqeyinə baxmaq
  /// azdır — ştrix son nöqtəyə tam çatmamış tamamlandığı üçün barmaq növbəti
  /// başlanğıca ştrixlərin özündən yaxın düşə bilir.
  ///
  /// Nəticədə zəncir yalnız `M`-in V-si (2-ci ştrix (50,74)-də bitir, 3-cü elə
  /// oradan qalxır), `Ə`-nin əyri→orta xətt keçidi və eyni şəkildə `B`, `K`,
  /// `Y` hərflərində işə düşür. `A`-nın ştrixləri uzaqdır, `R`-in ayağı isə
  /// ovalın ucundan 18 vahid aralıdır → hər ikisində uşaq barmağını qaldırıb
  /// yenidən toxunur.
  ///
  /// Nöqtə vahidinə heç vaxt zəncirlənmir: nöqtə toxunuş tələb edir, təsadüfi
  /// sürüşdürmə ilə tamamlanmamalıdır.
  ///
  /// [at] verilmirsə ([down] yolu — nöqtəyə toxunuş) davranış əvvəlki kimidir:
  /// `_drawing = false`, `_last = null`.
  TraceResult _completeUnit({Offset? at}) {
    final finished = currentUnit;
    _unitIndex++;
    _pointIndex = 0;

    final next = currentUnit;
    final chained =
        at != null &&
        next != null &&
        next.kind == TraceUnitKind.stroke &&
        finished != null &&
        finished.kind == TraceUnitKind.stroke &&
        // Datada həqiqi bitişiklik: bitən ştrixin ucu növbəti ştrixin
        // başlanğıcı olmalıdır. Tək barmaq mövqeyi yetmir — ştrix son
        // nöqtəyə tam çatmamış (təxminən `tolerance` qədər əvvəl) tamamlanır,
        // ona görə barmaq növbəti başlanğıca ştrixlərin özündən daha yaxın
        // ola bilər. Onsuz `R` (ovalın ucu (30,54) → ayağın başlanğıcı
        // (48,54), aralarında 18 vahid) təsadüfən zəncirlənirdi.
        (finished.points[finished.lastIndex] - next.points[0]).distance <=
            joinEpsilon &&
        (at - next.points[0]).distance <= _tolerance * startFactor;

    _drawing = chained;
    _last = chained ? at : null;

    return TraceResult(
      advanced: true,
      unitCompleted: true,
      letterCompleted: _unitIndex >= units.length,
    );
  }
}
