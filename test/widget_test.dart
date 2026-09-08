// Əlifba kitabının smoke testləri.
//
// DİQQƏT — `just_audio` test mühitində platforma kanalına cavab almır:
//   * heç bir `AudioPlayer` metodunu `await` etməyin — test 10 dəqiqə asılır;
//   * `AudioPlayer` quran səhifədə `tester.runAsync` ÇAĞIRMAYIN — real event
//     loop işə düşən kimi `MissingPluginException` testi uğursuz edir.
// Bu qaydalara riayət edildikdə `pumpWidget(MyApp())` təmiz keçir: səhifə
// qurularkən başlayan `setAsset` sadəcə heç vaxt tamamlanmır və səssiz qalır.
import 'package:elifba/core/config.dart';
import 'package:elifba/core/letter_strokes.dart';
import 'package:elifba/main.dart';
import 'package:elifba/pages/alphabet_page.dart';
import 'package:elifba/pages/animal_detail_page.dart';
import 'package:elifba/pages/animal_list_page.dart';
import 'package:elifba/pages/letter_writing_page.dart';
import 'package:elifba/widgets/parental_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Heyvan siyahısı səhifəsini kitabı vərəqləmədən birbaşa qurur.
/// [key] verilsə kök widget-in açarı dəyişir və ağac SIFIRDAN qurulur.
///
/// Bu, eyni testdə səhifəni təkrar-təkrar açanda lazımdır: açarsız
/// `pumpWidget` mövcud `MaterialApp`-i YENİLƏYİR, ona görə əvvəlki dövrədə
/// push edilmiş marşrut (məsələn `AnimalDetailPage`) Navigator-da qalır və
/// siyahı səhifəsini offstage edir. `find.text` offstage widget-ləri
/// saymadığı üçün finder sıfır nəticə verir.
Future<void> _pumpAnimalList(
  WidgetTester tester,
  String letter, {
  Key? key,
}) async {
  await tester.pumpWidget(
    MaterialApp(key: key, home: AnimalListPage(letter: letter)),
  );
  await tester.pump();
}

/// Marşrut keçidini bitirir. `pumpAndSettle` QƏSDƏN işlədilmir: açılan
/// `LetterWritingPage`-in nəbz animasiyası sonsuz təkrarlanır, settle isə heç
/// vaxt qayıtmazdı.
Future<void> _settleRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

/// Qrid xanasını (kartın çərçivəsini) mətninə görə tapır.
Finder _cardOf(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(AnimatedContainer));

/// Yazı kartının çərçivəsini tapır.
///
/// Kartda MƏTN YOXDUR — hərfin özü cızılmamış qlif kimi çəkilir, ona görə
/// `find.text` ilə tapmaq mümkün deyil. Sabit tutacaq əlçatanlıq etiketidir;
/// `_WriteLetterCard` private olduğu üçün tipə görə də axtarıla bilməz.
Finder _writeCardOf(String letter) => find.descendant(
  of: find.bySemanticsLabel('$letter hərfini yaz'),
  matching: find.byType(AnimatedContainer),
);

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

  testWidgets('səs mənbələri dialoqu valideyn qapısının arxasındadır', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    // Kitab səhifəsində artıq birbaşa keçid yoxdur.
    expect(find.byIcon(Icons.info_outline), findsNothing);

    await openSettingsThroughGate(tester);
    expect(find.text('Ayarlar'), findsOneWidget);

    // "Məlumat" bölməsi siyahının sonundadır; 800x600 test səthində ekrandan
    // aşağıda qalır və `find.text` offstage widget-ləri saymır.
    await tester.scrollUntilVisible(find.text('Səs mənbələri'), 200);
    await tester.tap(find.text('Səs mənbələri'));
    await tester.pumpAndSettle();

    expect(find.textContaining('bigsoundbank.com'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 30)));

  testWidgets('qapı yarımçıq buraxılsa ayarlar açılmır', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    // Müddətin yarısını saxlayıb barmağı qaldırmaq kifayət etmir.
    final gesture = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.touch_app_outlined)),
    );
    await tester.pump();
    await tester.pump(kParentalGateHold ~/ 2);
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Valideynlər üçün'), findsOneWidget);
    expect(find.text('Ayarlar'), findsNothing);

    await tester.tap(find.text('Ləğv et'));
    await tester.pumpAndSettle();
    expect(find.text('Valideynlər üçün'), findsNothing);
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

  testWidgets('yazı kartı qridin ilk xanasıdır və LetterWritingPage açır', (
    tester,
  ) async {
    const letter = 'A';
    final animals = AppConfig.animalsByLetter[letter]!;
    expect(LetterStrokes.has(letter), isTrue);

    await _pumpAnimalList(tester, letter);

    // Qriddə heyvanların sayından bir çox xana var — artıq olan yazı kartıdır.
    final grid = tester.widget<GridView>(find.byType(GridView));
    expect(grid.semanticChildCount, animals.length + 1);

    final writeCard = find.descendant(
      of: find.byType(GridView),
      matching: _writeCardOf(letter),
    );
    expect(writeCard, findsOneWidget);

    // İlk xana = sol sütun, birinci sətir: yazı kartı ilk heyvanın solunda və
    // onunla eyni sətirdə durur.
    final writeTopLeft = tester.getTopLeft(writeCard);
    final firstAnimalTopLeft = tester.getTopLeft(_cardOf(animals.first));
    expect(
      writeTopLeft.dx,
      lessThan(firstAnimalTopLeft.dx),
      reason: 'yazı kartı ilk heyvandan əvvəl, sol sütunda olmalıdır',
    );
    expect(
      writeTopLeft.dy,
      moreOrLessEquals(firstAnimalTopLeft.dy, epsilon: 0.5),
      reason: 'yazı kartı qridin birinci sətirindədir',
    );

    await tester.tap(writeCard);
    await _settleRoute(tester);

    expect(find.byType(LetterWritingPage), findsOneWidget);
    expect(
      tester.widget<LetterWritingPage>(find.byType(LetterWritingPage)).letter,
      letter,
      reason: 'səhifəyə əsl hərf ötürülməlidir (normalizasiya edilmiş yox)',
    );
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 30)));

  testWidgets('AppBar-da artıq yazı ikonu yoxdur', (tester) async {
    await _pumpAnimalList(tester, 'A');

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.draw_outlined),
      ),
      findsNothing,
    );
    expect(find.byIcon(Icons.draw_outlined), findsNothing);
    // Yazı girişi yoxa çıxmayıb, sadəcə qridə köçüb.
    expect(
      find.descendant(
        of: find.byType(GridView),
        matching: find.byIcon(Icons.history_edu),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(seconds: 30)));

  testWidgets('heyvanı olmayan hərfdə yazı kartı qalır, səhifə boş qalmır', (
    tester,
  ) async {
    for (final letter in const ['Ğ', 'I', 'Ü']) {
      expect(
        AppConfig.animalsByLetter[letter] ?? const <String>[],
        isEmpty,
        reason: '$letter hərfinin heyvanı olmamalıdır',
      );

      await _pumpAnimalList(tester, letter);

      expect(
        find.text('Bu hərflə başlayan heyvan yoxdur.'),
        findsNothing,
        reason: '$letter: səhifə tamamilə boş qalmamalıdır',
      );
      expect(
        find.byType(GridView),
        findsOneWidget,
        reason: '$letter: qrid tək yazı kartı ilə də qurulmalıdır',
      );
      expect(
        find.descendant(
          of: find.byType(GridView),
          matching: _writeCardOf(letter),
        ),
        findsOneWidget,
        reason: '$letter: yazı kartı görünməlidir',
      );
      expect(
        find.text('Bu hərflə başlayan heyvan yoxdur, amma hərfi yaza bilərsən!'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('heyvan kartı detal səhifəsini DÜZGÜN indekslə açır', (
    tester,
  ) async {
    const letter = 'A';
    final animals = AppConfig.animalsByLetter[letter]!;

    // Yazı kartı qrid indeksini bir sürüşdürür: qriddəki 1-ci xana 0-cı
    // heyvandır. Həm ilk, həm də ikinci heyvan yoxlanılır ki, sürüşmə
    // təsadüfən doğru çıxmasın.
    for (final animal in [animals[0], animals[1]]) {
      final expectedIndex = animals.indexOf(animal);

      // Hər dövrədə təmiz ağac: əks halda əvvəlki heyvanın detal səhifəsi
      // açıq qalır və siyahı offstage olur.
      await _pumpAnimalList(tester, letter, key: ValueKey(animal));

      // `ensureVisible` QƏSDƏN işlədilmir: qrid tənbəl qurulur və test
      // ekranında (800x600) başlıq kartı + irəliləyiş sətri qalanda cəmi BİR
      // heyvan xanası qurulur, ona görə ikinci heyvanın widget-i hələ ağacda
      // olmur və `ensureVisible` "No element" atır. `scrollUntilVisible`
      // tapana qədər sürüşdürür və artıq görünəni olduğu kimi saxlayır.
      await tester.scrollUntilVisible(
        find.text(animal),
        120,
        scrollable: find.descendant(
          of: find.byType(GridView),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pump();
      await tester.tap(find.text(animal));
      await _settleRoute(tester);

      expect(find.byType(AnimalDetailPage), findsOneWidget);
      final page = tester.widget<AnimalDetailPage>(
        find.byType(AnimalDetailPage),
      );
      expect(page.animal, animal);
      expect(
        page.currentIndex,
        expectedIndex,
        reason:
            'detal səhifəsinə qrid indeksi yox, sürüşdürülməmiş heyvan indeksi '
            'ötürülməlidir',
      );
      expect(page.animals[page.currentIndex], animal);
      expect(page.animals, animals);
      // Səhifə həqiqətən həmin heyvanı göstərir.
      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text(animal)),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
  }, timeout: const Timeout(Duration(seconds: 60)));
}

/// Valideyn qapısını keçib ayarlar səhifəsini açır.
///
/// Qapı 3 saniyəlik basıb-saxlamadır: barmaq qaldırılsa tərəqqi sıfırlanır,
/// ona görə jest müddət bitənə qədər basılı saxlanılır.
Future<void> openSettingsThroughGate(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.settings_outlined));
  await tester.pumpAndSettle();

  final gesture = await tester.startGesture(
    tester.getCenter(find.byIcon(Icons.touch_app_outlined)),
  );
  await tester.pump(); // basma qeydə alınsın
  await tester.pump(kParentalGateHold + const Duration(milliseconds: 100));
  await gesture.up();
  await tester.pumpAndSettle();
}
