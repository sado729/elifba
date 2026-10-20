// Hərf səhifəsinin (AnimalListPage) redizayn testləri: tək scroll, məlumat
// kartı + səs düyməsi, oxlar, ölçülər və qayıdışda hərf təbriki.
//
// CLAUDE.md gotcha 11: just_audio çağırışları `await` edilmir, `runAsync`
// işlədilmir. Store və ayarlar singleton-dur — hər testdən sonra sıfırlanır.

import 'package:elifba/core/config.dart';
import 'package:elifba/core/progress.dart';
import 'package:elifba/core/settings.dart';
import 'package:elifba/pages/animal_list_page.dart';
import 'package:elifba/pages/letter_writing_page.dart';
import 'package:elifba/widgets/progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, String letter) async {
  await tester.pumpWidget(MaterialApp(home: AnimalListPage(letter: letter)));
  await tester.pump();
}

IconButton _chevron(WidgetTester tester, IconData icon) => tester.widget(
  find.ancestor(of: find.byIcon(icon), matching: find.byType(IconButton)),
);

void main() {
  final store = ProgressStore.instance;

  tearDown(() async {
    AppSettings.instance
      ..masterSound = true
      ..narrationSound = true
      ..reduceMotion = false;
    await store.reset();
  });

  testWidgets('bütün məzmun tək scroll-dadır, GridView yoxdur', (tester) async {
    await _pump(tester, 'A');

    expect(find.byType(GridView), findsNothing);
    expect(find.byType(AppBar), findsNothing);
    final scroll = find.byKey(const ValueKey('letterPageScroll'));
    expect(scroll, findsOneWidget);
    for (final f in [
      find.text('A hərfi haqqında oxu'),
      find.text('Heyvanlar'),
      find.byType(SliverGrid),
    ]) {
      expect(find.descendant(of: scroll, matching: f), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  // Real şriftlə (tool/letter_screens_test.dart) qrid y = 222-dən başlayır:
  // 24 + 64 + 6 + 64 + 14 + 36 + 14. Test şriftində başlıq iki sətrə düşür,
  // ona görə burada nisbi ölçülər yoxlanılır.
  testWidgets('360x640: üst panel 64, sətir 36, kart 158x196, boşluqlar 14', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    addTearDown(tester.view.reset);

    await _pump(tester, 'E');

    final bar = find.byKey(const ValueKey('letterTopBar'));
    expect(tester.getSize(bar).height, 64);
    expect(tester.getTopLeft(bar).dy, 24);

    final heading =
        find
            .ancestor(of: find.text('Heyvanlar'), matching: find.byType(Row))
            .first;
    expect(tester.getSize(heading).height, 36);
    expect(tester.getSize(heading).width, 328);

    final card = find.ancestor(
      of: find.text('Eşşək'),
      matching: find.byType(AnimatedContainer),
    );
    final top = tester.getBottomLeft(heading).dy + 14;
    expect(tester.getSize(card), const Size(158, 196));
    expect(tester.getTopLeft(card), Offset(186, top));

    final write = find.descendant(
      of: find.bySemanticsLabel('E hərfini yaz'),
      matching: find.byType(AnimatedContainer),
    );
    expect(tester.getRect(write), Rect.fromLTWH(16, top, 158, 196));
    expect(tester.takeException(), isNull);
  });

  testWidgets('412 enində kart 212 hündürlükdədir', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.reset);

    await _pump(tester, 'E');

    final card = find.ancestor(
      of: find.text('Eşşək'),
      matching: find.byType(AnimatedContainer),
    );
    expect(tester.getSize(card), const Size(184, 212));
    expect(tester.takeException(), isNull);
  });

  testWidgets('səs düyməsi məlumat kartının içindədir', (tester) async {
    await _pump(tester, 'A');

    final audio = find.byTooltip('Səsləndir');
    expect(audio, findsOneWidget);
    final header = find.text('A hərfi haqqında oxu');
    // Düymə kartın sol tərəfində, başlıqla eyni sətirdədir.
    expect(
      tester.getCenter(audio).dy,
      moreOrLessEquals(tester.getCenter(header).dy, epsilon: 1),
    );
    expect(tester.getCenter(audio).dx, lessThan(tester.getTopLeft(header).dx));
    expect(tester.takeException(), isNull);
  });

  testWidgets('kart açılır, mətnə toxunmaq bağlamır, başlıq bağlayır', (
    tester,
  ) async {
    await _pump(tester, 'A');
    final firstLine =
        AppConfig.letterDescriptions['A']!.split('\n').first.trim();

    await tester.tap(find.text('A hərfi haqqında oxu'));
    await tester.pumpAndSettle();
    expect(find.text('A hərfi haqqında'), findsOneWidget);
    expect(find.text(firstLine), findsOneWidget);

    // Abzaslar ayrı-ayrı `Text`-lərdir və toxunanda kart bağlanmır.
    await tester.tap(find.text(firstLine));
    await tester.pumpAndSettle();
    expect(find.text('A hərfi haqqında'), findsOneWidget);

    await tester.tap(find.text('A hərfi haqqında'));
    await tester.pumpAndSettle();
    expect(find.text('A hərfi haqqında oxu'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('söndürülmüş səs düyməsinə toxunmaq kartı açmır', (tester) async {
    AppSettings.instance.narrationSound = false;
    await _pump(tester, 'A');

    final muted = find.byTooltip('Səs söndürülüb');
    expect(muted, findsOneWidget);
    expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);

    await tester.tap(muted, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('A hərfi haqqında oxu'), findsOneWidget);
    expect(find.text('A hərfi haqqında'), findsNothing);

    // Səs geri açılanda düymə yenidən hazırdır.
    AppSettings.instance.narrationSound = true;
    await tester.pump();
    expect(find.byTooltip('Səsləndir'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('kartı açıb-bağlamaq nəqli kəsmir (düymə eyni State-dir)', (
    tester,
  ) async {
    // Azaldılmış hərəkət: "oxuyur" nəbzi sonsuz deyil, pump-lar bitir.
    AppSettings.instance.reduceMotion = true;
    await _pump(tester, 'A');

    // `_isPlaying` toxunuşda sinxron qalxır; just_audio çağırışı gözlənilmir.
    await tester.tap(find.byTooltip('Səsləndir'));
    await tester.pump();
    expect(find.byTooltip('Dayandır'), findsOneWidget);

    // State yenidən yaradılsaydı (açıq/bağlı üçün ayrı alt ağac), bayraq
    // sıfırlanar və düymə yenə «Səsləndir» olardı — pleyer də dispose olardı.
    await tester.tap(find.text('A hərfi haqqında oxu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('A hərfi haqqında'), findsOneWidget);
    expect(find.byTooltip('Dayandır'), findsOneWidget);

    await tester.tap(find.text('A hərfi haqqında'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('A hərfi haqqında oxu'), findsOneWidget);
    expect(find.byTooltip('Dayandır'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bağlı kartda səs düyməsi kartın ortasındadır (1.3x mətn)', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _pump(tester, 'Ğ');

    // Test şriftində başlıq bir neçə sətrə düşür və kart 64-dən hündürdür.
    final audio = find.byTooltip('Səsləndir');
    final header = find.text('Ğ hərfi haqqında oxu');
    expect(tester.getSize(header).height, greaterThan(40));
    expect(
      tester.getCenter(audio).dy,
      moreOrLessEquals(tester.getCenter(header).dy, epsilon: 1),
    );

    // Açıq kartda düymə kartın yuxarısından 8 dp-dədir (maket `top: 8px`).
    await tester.tap(header);
    await tester.pumpAndSettle();
    final card =
        find
            .ancestor(of: audio, matching: find.byType(Stack))
            .first;
    expect(tester.getTopLeft(audio).dy - tester.getTopLeft(card).dy, 8);
    expect(tester.takeException(), isNull);
  });

  testWidgets('320 dp, 1.3x mətn: tam hərfin «Heyvanlar» sətri daşmır', (
    tester,
  ) async {
    // Android «Ekran ölçüsü: böyük» 360 dp telefonu ~320 dp edir; mətn
    // `main.dart`-da 1.3-ə qədər böyüyür.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    for (final animal in AppConfig.animalsByLetter['A']!) {
      for (final task in store.tasksOf(animal)) {
        store.markDone(animal, task);
      }
      for (final food in AppConfig.animalFoods[animal] ?? const <String>[]) {
        store.markFoodFed(animal, food);
      }
    }
    store.markWritten('A');

    await _pump(tester, 'A');

    expect(tester.takeException(), isNull);
    // Dar ekranda da sayğac «Heyvanlar»-ın ilk `Row` əcdadındadır.
    final heading =
        find
            .ancestor(of: find.text('Heyvanlar'), matching: find.byType(Row))
            .first;
    expect(
      find.descendant(of: heading, matching: find.text('Tamam!')),
      findsOneWidget,
    );
    // Zolaq başlığın ALTINDADIR və görünəcək qədər enlidir.
    final bar = find.byType(ElifbaProgressBar);
    expect(
      tester.getTopLeft(bar).dy,
      greaterThan(tester.getBottomLeft(find.text('Heyvanlar')).dy),
    );
    expect(tester.getSize(bar).width, greaterThanOrEqualTo(24));
  });

  testWidgets('üst paneldəki başlıq ekranın adıdır (header, namesRoute)', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, 'A');

    final node = tester.getSemantics(find.text('A hərfi'));
    expect(node.hasFlag(SemanticsFlag.isHeader), isTrue);
    expect(node.hasFlag(SemanticsFlag.namesRoute), isTrue);
    semantics.dispose();
  });

  testWidgets('oxlar: A-da əvvəlki, Z-də növbəti söndürülüb, dövrə yoxdur', (
    tester,
  ) async {
    await _pump(tester, 'A');
    expect(_chevron(tester, Icons.chevron_left_rounded).onPressed, isNull);
    expect(_chevron(tester, Icons.chevron_right_rounded).onPressed, isNotNull);
    expect(find.byTooltip('Əvvəlki hərf'), findsOneWidget);

    await _pump(tester, 'Z');
    expect(_chevron(tester, Icons.chevron_left_rounded).onPressed, isNotNull);
    expect(_chevron(tester, Icons.chevron_right_rounded).onPressed, isNull);
    expect(find.byTooltip('Növbəti hərf'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('növbəti ox səhifəni növbəti hərflə əvəz edir', (tester) async {
    await _pump(tester, 'A');

    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('B hərfi'), findsOneWidget);
    expect(find.text('A hərfi'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hərf qayıdışda bir dəfə təbrik olunur', (tester) async {
    // Azaldılmış hərəkət: şüalar fırlanmır, konfeti yoxdur.
    AppSettings.instance.reduceMotion = true;
    const letter = 'A';
    for (final animal in AppConfig.animalsByLetter[letter]!) {
      for (final task in store.tasksOf(animal)) {
        store.markDone(animal, task);
      }
      for (final food in AppConfig.animalFoods[animal] ?? const <String>[]) {
        store.markFoodFed(animal, food);
      }
    }
    await _pump(tester, letter);
    // Açılışda təbrik yoxdur — yalnız alt səhifədən qayıdanda.
    expect(find.text('A hərfi tamam!'), findsNothing);

    Future<void> writeAndReturn() async {
      await tester.tap(find.bySemanticsLabel('A hərfini yaz'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(LetterWritingPage), findsOneWidget);
      store.markWritten(letter);
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
    }

    await writeAndReturn();
    expect(find.text('A hərfi tamam!'), findsOneWidget);
    expect(find.text('Yaşa!'), findsOneWidget);

    await tester.tap(find.text('Yaşa!'));
    await tester.pumpAndSettle();
    expect(find.text('A hərfi tamam!'), findsNothing);
    expect(find.text('Tamam!'), findsOneWidget);

    // İkinci qayıdış: təbrik təkrarlanmır.
    await writeAndReturn();
    expect(find.text('A hərfi tamam!'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('yazı kartında tək draw nişanı və tək AnimatedContainer var', (
    tester,
  ) async {
    await _pump(tester, 'Ğ');

    final write = find.bySemanticsLabel('Ğ hərfini yaz');
    expect(
      find.descendant(of: write, matching: find.byType(AnimatedContainer)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: write, matching: find.byIcon(Icons.draw_rounded)),
      findsOneWidget,
    );
    expect(
      find.text('Bu hərflə başlayan heyvan yoxdur, amma hərfi yaza bilərsən!'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
