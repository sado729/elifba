import 'dart:ui';

import 'package:elifba/core/stroke_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

/// Düz xətt yolu — testlərdə hərf datasından asılı olmamaq üçün.
Path _line(Offset a, Offset b) =>
    Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy);

/// U formalı yol: aşağı, sağa, yuxarı. Başlanğıcdan sona düz tullanış bu yolun
/// üstündən keçmir — sürətli barmağın "kəsmə" cəhdini yoxlamaq üçün.
Path _uShape() =>
    Path()
      ..moveTo(20, 20)
      ..lineTo(20, 80)
      ..lineTo(80, 80)
      ..lineTo(80, 20);

/// Barmağı `from`-dan `to`-ya kiçik addımlarla sürüşdürür.
void _drag(StrokeTracker t, Offset from, Offset to, {int steps = 40}) {
  t.down(from);
  for (var i = 1; i <= steps; i++) {
    final k = i / steps;
    t.move(
      Offset(from.dx + (to.dx - from.dx) * k, from.dy + (to.dy - from.dy) * k),
    );
  }
  t.up();
}

/// Barmağı QALDIRMADAN sürüşdürür (nə `down`, nə `up`) və hər hərəkətin
/// nəticəsini qaytarır — zəncirləmə testləri üçün.
List<TraceResult> _slide(
  StrokeTracker t,
  Offset from,
  Offset to, {
  int steps = 40,
}) {
  final out = <TraceResult>[];
  for (var i = 1; i <= steps; i++) {
    final k = i / steps;
    out.add(
      t.move(
        Offset(from.dx + (to.dx - from.dx) * k, from.dy + (to.dy - from.dy) * k),
      ),
    );
  }
  return out;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TraceUnit', () {
    test('yolu bərabər aralıqlarla sample-layır', () {
      final u = TraceUnit.stroke(_line(const Offset(50, 20), const Offset(50, 88)));

      expect(u.kind, TraceUnitKind.stroke);
      expect(u.length, closeTo(68, 0.5));
      expect(u.points.length, greaterThan(50));
      expect(u.start.dy, closeTo(20, 0.5));
      expect(u.end.dy, closeTo(88, 0.5));

      // Qonşu sample-lar arasındakı məsafə hər yerdə eyni olmalıdır.
      for (var i = 1; i < u.points.length; i++) {
        expect((u.points[i] - u.points[i - 1]).distance, closeTo(1.2, 0.35));
      }
    });

    test('uzunluğu olmayan yol nöqtə vahidinə çevrilir', () {
      final u = TraceUnit.stroke(_line(const Offset(50, 12), const Offset(50, 12)));
      expect(u.kind, TraceUnitKind.dot);
    });

    test('partialPath irəliləyişlə uzanır', () {
      final u = TraceUnit.stroke(_line(const Offset(20, 20), const Offset(80, 20)));

      double lengthOf(double p) {
        var total = 0.0;
        for (final m in u.partialPath(p).computeMetrics()) {
          total += m.length;
        }
        return total;
      }

      expect(lengthOf(0), closeTo(0, 0.01));
      expect(lengthOf(0.5), closeTo(30, 1));
      expect(lengthOf(1), closeTo(60, 1));
    });

    test('angleAt yolun istiqamətini verir', () {
      final down = TraceUnit.stroke(_line(const Offset(50, 20), const Offset(50, 88)));
      // y aşağı artır, ona görə aşağı istiqamət +pi/2-dir.
      expect(down.angleAt(0.2), closeTo(3.14159 / 2, 0.05));
    });
  });

  group('StrokeTracker — başlanğıc', () {
    late StrokeTracker tracker;

    setUp(() {
      tracker = StrokeTracker(
        units: [TraceUnit.stroke(_line(const Offset(50, 20), const Offset(50, 88)))],
      );
    });

    test('uzaq toxunuş rədd edilir', () {
      final r = tracker.down(const Offset(20, 60));
      expect(r.rejected, isTrue);
      expect(tracker.isDrawing, isFalse);
      expect(tracker.unitProgress, 0);
    });

    test('başlanğıca yaxın toxunuş qəbul edilir', () {
      final r = tracker.down(const Offset(53, 23));
      expect(r.rejected, isFalse);
      expect(tracker.isDrawing, isTrue);
    });

    test('toxunmadan hərəkət nəzərə alınmır', () {
      tracker.move(const Offset(50, 50));
      expect(tracker.unitProgress, 0);
    });
  });

  group('StrokeTracker — irəliləyiş', () {
    StrokeTracker lineTracker() => StrokeTracker(
      units: [TraceUnit.stroke(_line(const Offset(50, 20), const Offset(50, 88)))],
    );

    test('yol boyu cızmaq ştrixi tamamlayır', () {
      final t = lineTracker();
      _drag(t, const Offset(50, 20), const Offset(50, 88));
      expect(t.isComplete, isTrue);
      expect(t.overallProgress, 1);
    });

    test('indeks geri getmir', () {
      final t = lineTracker();
      t.down(const Offset(50, 20));
      t.move(const Offset(50, 60));
      final mid = t.pointIndex;
      expect(mid, greaterThan(0));

      // Barmağı geri sürüşdür — irəliləyiş qalmalıdır.
      t.move(const Offset(50, 40));
      t.move(const Offset(50, 25));
      expect(t.pointIndex, mid);
    });

    test('yoldan çıxmaq irəliləyişi dayandırır və sayılır', () {
      final t = lineTracker();
      t.down(const Offset(50, 20));
      t.move(const Offset(50, 50)); // yolun ortasına qədər normal cız
      final mid = t.pointIndex;

      t.move(const Offset(95, 50)); // sonra kəskin sağa, yoldan kənara
      // Tolerans dairəsi qədər cüzi sürüşmə qaçılmazdır (barmaq hələ də
      // irəlidəki bir neçə sample-a yaxındır), amma irəliləyiş dayanır.
      expect(
        t.pointIndex - mid,
        lessThanOrEqualTo((t.tolerance / TraceUnit.sampleStep).ceil() + 1),
      );
      expect(t.offTrackCount, greaterThan(0));
    });

    test('kifayət qədər yoldan çıxma ipucu tələb edir', () {
      final t = lineTracker();
      t.down(const Offset(50, 20));
      for (var i = 0; i < StrokeTracker.hintThreshold + 2; i++) {
        t.move(Offset(95, 20 + i.toDouble()));
      }
      expect(t.needsHint, isTrue);
    });

    test('sürətli barmaq ilişmir — aralıq nöqtələr doldurulur', () {
      final t = lineTracker();
      // Bir hadisədə bütün yolu keçmək: interpolyasiya olmasa irəliləyiş 0 qalardı.
      t.down(const Offset(50, 20));
      t.move(const Offset(50, 88));
      expect(t.isComplete, isTrue);
    });

    test('yolu kəsmək işləmir', () {
      final t = StrokeTracker(units: [TraceUnit.stroke(_uShape())]);
      // U-nun başından sonuna düz tullanış yolun üstündən keçmir.
      t.down(const Offset(20, 20));
      t.move(const Offset(80, 20));
      expect(t.isComplete, isFalse);
      expect(t.unitProgress, lessThan(0.3));
    });

    test('barmaq qalxsa irəliləyiş qalır və davam etmək olur', () {
      final t = lineTracker();
      t.down(const Offset(50, 20));
      t.move(const Offset(50, 55));
      final mid = t.pointIndex;
      t.up();
      expect(t.isDrawing, isFalse);
      expect(t.pointIndex, mid);

      // Qaldığı yerdən yenidən başlamaq mümkündür...
      expect(t.down(const Offset(50, 56)).rejected, isFalse);
      // ...amma tamam başqa yerdən yox.
      t.up();
      expect(t.down(const Offset(50, 20)).rejected, isTrue);
    });

    test('yoxlama nöqtələri keçilir', () {
      final t = lineTracker();
      t.down(const Offset(50, 20));
      var checkpoints = 0;
      for (var y = 21.0; y <= 88; y += 1) {
        if (t.move(Offset(50, y)).checkpoint) checkpoints++;
      }
      expect(checkpoints, greaterThanOrEqualTo(StrokeTracker.checkpointCount - 2));
    });
  });

  group('StrokeTracker — nöqtə vahidi', () {
    test('nöqtəyə toxunmaq onu tamamlayır', () {
      final t = StrokeTracker(units: [TraceUnit.dot(const Offset(50, 12))]);
      final r = t.down(const Offset(52, 14));
      expect(r.unitCompleted, isTrue);
      expect(r.letterCompleted, isTrue);
      expect(t.isComplete, isTrue);
    });

    test('nöqtədən uzaq toxunuş rədd edilir', () {
      final t = StrokeTracker(units: [TraceUnit.dot(const Offset(50, 12))]);
      expect(t.down(const Offset(50, 60)).rejected, isTrue);
      expect(t.isComplete, isFalse);
    });
  });

  group('StrokeTracker — çoxştrixli hərf', () {
    StrokeTracker iTracker() => StrokeTracker(
      units: [
        TraceUnit.stroke(_line(const Offset(50, 28), const Offset(50, 88))),
        TraceUnit.dot(const Offset(50, 12)),
      ],
    );

    test('ştrixlər sırayla tamamlanır', () {
      final t = iTracker();
      expect(t.unitIndex, 0);

      _drag(t, const Offset(50, 28), const Offset(50, 88));
      expect(t.unitIndex, 1);
      expect(t.isComplete, isFalse);
      expect(t.overallProgress, closeTo(0.5, 0.01));

      final r = t.down(const Offset(50, 12));
      expect(r.letterCompleted, isTrue);
      expect(t.overallProgress, 1);
    });

    test('sıra pozula bilmir — nöqtəyə əvvəlcədən toxunmaq olmaz', () {
      final t = iTracker();
      expect(t.down(const Offset(50, 12)).rejected, isTrue);
      expect(t.unitIndex, 0);
    });

    test('progressOf hər vahid üçün doğru dəyər verir', () {
      final t = iTracker();
      t.down(const Offset(50, 28));
      t.move(const Offset(50, 58));

      // Barmaq yolun yarısındadır, amma tolerans dairəsi irəlidəki sample-ları
      // da əhatə edir — ona görə irəliləyiş yarıdan bir qədər çox olur.
      // Bu qəsdəndir: uşaq ştrixi tam sona qədər "sürtməli" deyil.
      expect(t.progressOf(0), inInclusiveRange(0.45, 0.75));
      expect(t.progressOf(1), 0);

      _drag(t, const Offset(50, 58), const Offset(50, 88));
      expect(t.progressOf(0), 1);
    });

    test('reset hər şeyi sıfırlayır', () {
      final t = iTracker();
      _drag(t, const Offset(50, 28), const Offset(50, 88));
      t.reset();
      expect(t.unitIndex, 0);
      expect(t.pointIndex, 0);
      expect(t.offTrackCount, 0);
      expect(t.overallProgress, 0);
    });

    test('seek nümayiş rejimi üçün irəliləyişi təyin edir', () {
      final t = iTracker();
      t.seek(unit: 0, progress: 0.5);
      expect(t.unitProgress, closeTo(0.5, 0.02));

      t.seek(unit: 2, progress: 0);
      expect(t.isComplete, isTrue);
      expect(t.overallProgress, 1);
    });
  });

  group('StrokeTracker — tolerans', () {
    test('kiçik tolerans yoldan kənarı rədd edir, böyük tolerans qəbul edir', () {
      Path path() => _line(const Offset(50, 20), const Offset(50, 88));

      final strict = StrokeTracker(units: [TraceUnit.stroke(path())], tolerance: 4);
      strict.down(const Offset(50, 20));
      strict.move(const Offset(56, 30));
      final strictProgress = strict.unitProgress;

      final loose = StrokeTracker(units: [TraceUnit.stroke(path())], tolerance: 14);
      loose.down(const Offset(50, 20));
      loose.move(const Offset(56, 30));

      expect(loose.unitProgress, greaterThan(strictProgress));
    });

    test('tolerans sıfıra düşmür', () {
      final t = StrokeTracker(
        units: [TraceUnit.stroke(_line(const Offset(50, 20), const Offset(50, 88)))],
      );
      t.tolerance = -5;
      expect(t.tolerance, greaterThan(0));
    });
  });

  group('StrokeTracker — zəncirləmə (barmaq qaldırmadan)', () {
    /// `M`-in V-si: 2-ci ştrix dibə enir, 3-cü ELƏ ORADAN yuxarı qalxır.
    StrokeTracker vTracker() => StrokeTracker(
      units: [
        TraceUnit.stroke(_line(const Offset(30, 20), const Offset(50, 74))),
        TraceUnit.stroke(_line(const Offset(50, 74), const Offset(70, 20))),
      ],
    );

    test('bitişik ştrixlər barmaq qaldırmadan yazılır', () {
      final t = vTracker();
      t.down(const Offset(30, 20));

      final first = _slide(t, const Offset(30, 20), const Offset(50, 74));
      expect(t.unitIndex, 1, reason: 'birinci ştrix bitməlidir');
      expect(t.isDrawing, isTrue, reason: 'zəncir qırılmamalıdır');

      // Çağırana zəncir görünmür: adi ştrix tamamlanması kimidir.
      final done = first.where((e) => e.unitCompleted).toList();
      expect(done, hasLength(1));
      expect(done.single.advanced, isTrue);
      expect(done.single.letterCompleted, isFalse);

      // Barmaq eyni hərəkətlə yuxarı qalxır — ikinci ştrix irəliləyir.
      final second = _slide(t, const Offset(50, 74), const Offset(70, 20));
      expect(t.isComplete, isTrue);
      expect(second.any((e) => e.letterCompleted), isTrue);
    });

    test('uzaq ştrixlərdə zəncir olmur — yenidən toxunmaq lazımdır', () {
      final t = StrokeTracker(
        units: [
          TraceUnit.stroke(_line(const Offset(30, 20), const Offset(50, 74))),
          TraceUnit.stroke(_line(const Offset(85, 20), const Offset(85, 74))),
        ],
      );
      t.down(const Offset(30, 20));
      _slide(t, const Offset(30, 20), const Offset(50, 74));
      expect(t.unitIndex, 1);
      expect(t.isDrawing, isFalse, reason: 'ştrixlər bitişik deyil');

      // Barmaq boşluqla ikinci ştrixin başına sürüşür — heç nə baş vermir.
      final events = _slide(t, const Offset(50, 74), const Offset(85, 20));
      expect(events.every((e) => e == TraceResult.none), isTrue);
      expect(t.progressOf(1), 0);

      // Yalnız yeni toxunuş ikinci ştrixi başladır.
      expect(t.down(const Offset(85, 20)).rejected, isFalse);
      _slide(t, const Offset(85, 20), const Offset(85, 74));
      expect(t.isComplete, isTrue);
    });

    test('yaxın, amma bitişik olmayan ştrixlər zəncirlənmir (R hərfi)', () {
      // `R`: ovalın alt xətti sağdan sola gəlib (30,54)-də bitir, ayaq isə
      // (48,54)-dən başlayır — aralarında 18 vahid var, yəni ştrixlər
      // bitişik DEYİL.
      //
      // Tələ: ştrix son nöqtəyə tam çatmamış, barmaq ondan `tolerance` (9)
      // qədər aralıda ikən tamamlanır. Həmin an barmaq təxminən (39,54)-dədir
      // və ayağın başlanğıcına cəmi 9 vahid qalır — yalnız barmağın mövqeyinə
      // baxsaydıq zəncir yaranardı. Ona görə sürüşmənin SONUNU yox, bitmə
      // anındakı vəziyyəti yoxlamaq lazımdır: `isDrawing`.
      final t = StrokeTracker(
        units: [
          TraceUnit.stroke(_line(const Offset(56, 54), const Offset(30, 54))),
          TraceUnit.stroke(_line(const Offset(48, 54), const Offset(78, 88))),
        ],
      );
      t.down(const Offset(56, 54));
      _slide(t, const Offset(56, 54), const Offset(30, 54));

      expect(t.unitIndex, 1, reason: 'oval bitməlidir');
      expect(
        t.isDrawing,
        isFalse,
        reason: 'ayaq ayrı ştrixdir — barmaq qaldırılmalıdır',
      );
      expect(t.progressOf(1), 0, reason: 'ayaq təsadüfən başlamamalıdır');

      // Ayaq yalnız yeni toxunuşla başlayır.
      expect(t.down(const Offset(48, 54)).rejected, isFalse);
      _slide(t, const Offset(48, 54), const Offset(78, 88));
      expect(t.isComplete, isTrue);
    });

    test('növbəti vahid nöqtədirsə zəncir olmur', () {
      final t = StrokeTracker(
        units: [
          TraceUnit.stroke(_line(const Offset(50, 28), const Offset(50, 88))),
          // Qəsdən elə ştrixin ucunda: məsafə deyil, vahidin NÖVÜ saxlayır.
          TraceUnit.dot(const Offset(50, 88)),
        ],
      );
      t.down(const Offset(50, 28));
      _slide(t, const Offset(50, 28), const Offset(50, 88));

      expect(t.unitIndex, 1);
      expect(t.isDrawing, isFalse);
      expect(t.isComplete, isFalse, reason: 'nöqtə sürüşdürmə ilə bitməz');

      // Nöqtə yalnız toxunuşla tamamlanır.
      expect(t.down(const Offset(50, 88)).letterCompleted, isTrue);
    });

    test('son ştrix bitəndə letterCompleted qalır və zəncir yaranmır', () {
      final t = StrokeTracker(
        units: [TraceUnit.stroke(_line(const Offset(50, 20), const Offset(50, 88)))],
      );
      t.down(const Offset(50, 20));
      final events = _slide(t, const Offset(50, 20), const Offset(50, 88));

      final done = events.where((e) => e.unitCompleted).toList();
      expect(done, hasLength(1));
      expect(done.single.letterCompleted, isTrue);
      expect(t.isComplete, isTrue);
      expect(t.isDrawing, isFalse);
    });
  });
}
