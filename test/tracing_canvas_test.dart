import 'package:elifba/core/stroke_tracker.dart';
import 'package:elifba/widgets/tracing_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Kətanı 200x208 ölçüdə qurur — qutu 100x104 olduğu üçün miqyas dəqiq 2.0
/// olur. `startGesture` qlobal koordinat gözlədiyi üçün kətanın sol-üst
/// küncünü də əlavə etmək lazımdır.
const double _scale = 2;

Offset _screen(WidgetTester tester, Offset box) =>
    tester.getTopLeft(find.byType(TracingCanvas)) +
    Offset(box.dx * _scale, box.dy * _scale);

Path _line(Offset a, Offset b) =>
    Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy);

void main() {
  Future<void> pumpCanvas(
    WidgetTester tester, {
    required List<TraceUnit> units,
    required List<TraceResult> events,
    TracingMode mode = TracingMode.guided,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              height: 208,
              child: TracingCanvas(
                units: units,
                mode: mode,
                onEvent: events.add,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// Barmağı qutu koordinatları ilə addım-addım sürüşdürür.
  Future<void> trace(
    WidgetTester tester,
    List<Offset> boxPoints, {
    bool lift = true,
  }) async {
    final gesture = await tester.startGesture(_screen(tester, boxPoints.first));
    for (final p in boxPoints.skip(1)) {
      await gesture.moveTo(_screen(tester, p));
      await tester.pump(const Duration(milliseconds: 16));
    }
    if (lift) await gesture.up();
    await tester.pump();
  }

  testWidgets('yol boyu cızmaq hərfi tamamlayır', (tester) async {
    final events = <TraceResult>[];
    await pumpCanvas(
      tester,
      units: [TraceUnit.stroke(_line(const Offset(50, 20), const Offset(50, 88)))],
      events: events,
    );

    await trace(tester, [
      for (var y = 20.0; y <= 88; y += 4) Offset(50, y),
    ]);

    expect(events.where((e) => e.letterCompleted), isNotEmpty);
  });

  testWidgets('səhv yerdən başlamaq rədd edilir', (tester) async {
    final events = <TraceResult>[];
    await pumpCanvas(
      tester,
      units: [TraceUnit.stroke(_line(const Offset(50, 20), const Offset(50, 88)))],
      events: events,
    );

    // Ştrixin SONUNDAN başlamağa cəhd.
    await trace(tester, [const Offset(50, 88), const Offset(50, 60)]);

    expect(events.any((e) => e.rejected), isTrue);
    expect(events.any((e) => e.letterCompleted), isFalse);
  });

  testWidgets('nöqtə toxunuşla tamamlanır və sıra gözlənilir', (tester) async {
    final events = <TraceResult>[];
    await pumpCanvas(
      tester,
      units: [
        TraceUnit.stroke(_line(const Offset(50, 28), const Offset(50, 88))),
        TraceUnit.dot(const Offset(50, 12)),
      ],
      events: events,
    );

    // Əvvəlcə nöqtəyə toxunmaq işləməməlidir — ştrix hələ cızılmayıb.
    await tester.tapAt(_screen(tester, const Offset(50, 12)));
    await tester.pump();
    expect(events.any((e) => e.rejected), isTrue);
    expect(events.any((e) => e.letterCompleted), isFalse);

    // Ştrixi cız, sonra nöqtəyə toxun.
    await trace(tester, [
      for (var y = 28.0; y <= 88; y += 4) Offset(50, y),
    ]);
    expect(events.any((e) => e.unitCompleted), isTrue);

    await tester.tapAt(_screen(tester, const Offset(50, 12)));
    await tester.pump();
    expect(events.any((e) => e.letterCompleted), isTrue);
  });

  testWidgets('"Bax" rejimi toxunuşu qəbul etmir və özü tamamlayır', (
    tester,
  ) async {
    final events = <TraceResult>[];
    await pumpCanvas(
      tester,
      units: [TraceUnit.stroke(_line(const Offset(50, 20), const Offset(50, 88)))],
      events: events,
      mode: TracingMode.watch,
    );

    // Nümayiş rejimində barmaq hadisələri bağlıdır.
    await trace(tester, [const Offset(95, 95), const Offset(96, 96)]);
    expect(events.any((e) => e.rejected), isFalse);

    // Animasiya öz-özünə hərfi bitirir.
    await tester.pump(const Duration(milliseconds: 1200));
    expect(events.any((e) => e.letterCompleted), isTrue);

    // Təkrarlanan nəbz animasiyası testi asılı qoymasın.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('kətan barmaq hərəkətində valideyni yenidən qurmur', (
    tester,
  ) async {
    var builds = 0;
    final units = [
      TraceUnit.stroke(_line(const Offset(50, 20), const Offset(50, 88))),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              builds++;
              return Center(
                child: SizedBox(
                  width: 200,
                  height: 208,
                  child: TracingCanvas(units: units, mode: TracingMode.guided),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    final before = builds;

    await trace(tester, [
      for (var y = 20.0; y <= 88; y += 2) Offset(50, y),
    ]);

    // Bütün irəliləyiş `repaint` notifier-i ilə getdiyi üçün valideyn
    // `build()` bir dəfə də olsun yenidən çağırılmamalıdır.
    expect(builds, before);
  });
}
