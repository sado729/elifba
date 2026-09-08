// Əlifba kitabının smoke testləri.
//
// DİQQƏT — `just_audio` test mühitində platforma kanalına cavab almır:
//   * heç bir `AudioPlayer` metodunu `await` etməyin — test 10 dəqiqə asılır;
//   * `AudioPlayer` quran səhifədə `tester.runAsync` ÇAĞIRMAYIN — real event
//     loop işə düşən kimi `MissingPluginException` testi uğursuz edir.
// Bu qaydalara riayət edildikdə `pumpWidget(MyApp())` təmiz keçir: səhifə
// qurularkən başlayan `setAsset` sadəcə heç vaxt tamamlanmır və səssiz qalır.
import 'package:elifba/core/config.dart';
import 'package:elifba/main.dart';
import 'package:elifba/pages/alphabet_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('kitab açılır və ilk səhifədə A ilə B görünür', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Əlifba'), findsOneWidget);
    expect(find.byType(AlphabetPage), findsOneWidget);
    expect(find.byType(PageView), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    // İkinci səhifə hələ qurulmayıb.
    expect(find.text('C'), findsNothing);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 30)));

  testWidgets('irəli oxu növbəti hərf cütünü gətirir', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.byIcon(Icons.arrow_forward_ios));
    await tester.pumpAndSettle();

    expect(find.text('C'), findsOneWidget);
    expect(find.text('Ç'), findsOneWidget);
    expect(find.text('A'), findsNothing);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 30)));

  testWidgets('kitabı sona qədər vərəqləyəndə 32 hərfin hamısı çıxır', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    final seen = <String>[];
    for (var spread = 0; spread < (AppConfig.alphabet.length / 2).ceil(); spread++) {
      for (final letter in AppConfig.alphabet) {
        if (find.text(letter).evaluate().isNotEmpty && !seen.contains(letter)) {
          seen.add(letter);
        }
      }
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();
    }

    expect(
      seen,
      AppConfig.alphabet,
      reason: 'hərflər əlifba sırası ilə görünməlidir (X H-dan, Q K-dan sonra)',
    );
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('səs mənbələri dialoqu açılır', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Səs mənbələri'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 30)));

  testWidgets('hərfə toxunanda heyvan siyahısı açılır', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('A hərfi'), findsOneWidget);
    expect(find.text('Heyvanlar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 30)));
}
