// Ayarlar səhifəsinin vizual yoxlaması (əl ilə, dizayn renderləri ilə yan-yana).
//
// `test/`-də DEYİL, ona görə adi `flutter test` onu işlətmir. Belə işlədin:
//
//   flutter test tool/settings_screens_test.dart
//
// Real şriftləri (Comfortaa/Andika, Flutter SDK-dan MaterialIcons, Windows-da
// Consolas «monospace» kimi) yükləyir, səhifəni hər dizayn vəziyyətində
// 360 × 640 və 412 × 915 dp-də qurur və PNG-ləri `SCREENS_OUT` qovluğuna
// (yoxdursa `build/settings_screens/`) yazır. Maketdəki kimi yuxarıda 24 dp
// status bar, aşağıda 24 dp jest nav bar-ı inseti verilir.
//
// Ayarlar səhifəsi `GatedPlayer` qurmur, ona görə `tester.runAsync`
// təhlükəsizdir (just_audio platformasını saxtalaşdırmaq lazım deyil).

import 'dart:io';
import 'dart:ui' as ui;

import 'package:elifba/core/config.dart';
import 'package:elifba/core/progress.dart';
import 'package:elifba/core/settings.dart';
import 'package:elifba/pages/settings_page.dart';
import 'package:elifba/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

String get _outDir {
  final env = Platform.environment['SCREENS_OUT'];
  if (env != null && env.isNotEmpty) return env;
  return 'build/settings_screens';
}

/// Flutter SDK-nın kökü: `FLUTTER_ROOT`, yoxdursa test icraçısının yolundan.
String? _flutterRoot() {
  final env = Platform.environment['FLUTTER_ROOT'];
  if (env != null && env.isNotEmpty) return env;
  var dir = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 8; i++) {
    final probe = Directory(
      '${dir.path}${Platform.pathSeparator}bin${Platform.pathSeparator}cache',
    );
    if (probe.existsSync()) return dir.path;
    dir = dir.parent;
  }
  return null;
}

Future<ByteData> _bytes(String path) async =>
    ByteData.sublistView(await File(path).readAsBytes());

Future<void> _loadFonts() async {
  await (FontLoader('Comfortaa')
    ..addFont(_bytes('assets/fonts/Comfortaa-Bold.ttf'))).load();
  await (FontLoader('Andika')
        ..addFont(_bytes('assets/fonts/Andika-Regular.ttf'))
        ..addFont(_bytes('assets/fonts/Andika-Bold.ttf')))
      .load();
  final root = _flutterRoot();
  if (root != null) {
    final sep = Platform.pathSeparator;
    final icons = File(
      '$root${sep}bin${sep}cache${sep}artifacts${sep}material_fonts$sep'
      'materialicons-regular.otf',
    );
    if (icons.existsSync()) {
      await (FontLoader('MaterialIcons')..addFont(_bytes(icons.path))).load();
    }
  }
  // Android `'monospace'`-i sistem mono şriftinə açır; burada Consolas.
  final mono = File(r'C:\Windows\Fonts\consola.ttf');
  if (mono.existsSync()) {
    await (FontLoader('monospace')..addFont(_bytes(mono.path))).load();
  }
}

final _rootKey = GlobalKey();

/// Maketlərdəki ulduz sayı: «Yığılmış 41 ulduz».
void _seedStars(ProgressStore store, int target) {
  for (final letter in AppConfig.alphabet) {
    if (store.totalStars >= target) return;
    if (store.totalStars + 3 <= target) {
      for (final animal in AppConfig.animalsByLetter[letter] ?? const []) {
        for (final task in store.tasksOf(animal)) {
          store.markDone(animal, task);
        }
        for (final food in AppConfig.animalFoods[animal] ?? const []) {
          store.markFoodFed(animal, food);
        }
      }
      store.markWritten(letter);
    } else if ((AppConfig.animalsByLetter[letter] ?? const []).isNotEmpty) {
      // Bir tapşırıq = 1 ulduz (yalnız heyvanı olan hərfdə; heyvansız hərfdə
      // yazı yeganə tapşırıqdır və birdən 3 ulduz verir).
      store.markWritten(letter);
    }
  }
}

/// [elifbaTheme] `false` → testlərdəki kimi defolt tema (səhifə ondan
/// asılı olmamalıdır). [textScale] → tətbiqin ən böyük icazəli şrifti 1.3.
Future<void> _pumpPage(
  WidgetTester tester,
  Size size, {
  bool elifbaTheme = true,
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  const insets = FakeViewPadding(top: 24, bottom: 24);
  tester.view.padding = insets;
  tester.view.viewPadding = insets;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _rootKey,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: elifbaTheme ? ElifbaTheme.light() : null,
        home: const SettingsPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _capture(WidgetTester tester, String name) async {
  final boundary =
      tester.renderObject(find.byKey(_rootKey)) as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final ui.Image image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final dir = Directory(_outDir)..createSync(recursive: true);
    File(
      '${dir.path}${Platform.pathSeparator}$name.png',
    ).writeAsBytesSync(data!.buffer.asUint8List());
  });
  expect(tester.takeException(), isNull);
}

/// Səhifənin öz siyahısı (dialoqdakı `Scrollable` deyil).
ScrollPosition _pagePosition(WidgetTester tester) =>
    tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byType(SettingsPage),
            matching: find.byType(Scrollable),
          ),
        )
        .position;

/// Sətrə qədər sürüşdürüb toxunur, sonra siyahını yenidən yuxarı qaytarır
/// (maketlərdə dialoqlar sürüşdürülməmiş siyahının üstündədir).
Future<void> _openFromRow(WidgetTester tester, String row) async {
  await tester.scrollUntilVisible(find.text(row), 200);
  await tester.ensureVisible(find.text(row));
  await tester.pumpAndSettle();
  await tester.tap(find.text(row));
  await tester.pump();
  _pagePosition(tester).jumpTo(0);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(_loadFonts);

  final settings = AppSettings.instance;
  final store = ProgressStore.instance;

  // Maketin vəziyyəti: nəqletmə və effektlər açıq, heyvan səsləri bağlı,
  // titrəmə açıq, animasiya azaldılmayıb, pazl 3 × 3.
  // (`restoreFromJson` `@visibleForTesting`-dir və `tool/`-dan çağırıla
  // bilməz, ona görə dəyərlər bir-bir yazılır.)
  void designDefaults({bool animalSound = false}) {
    settings
      ..masterSound = true
      ..narrationSound = true
      ..animalSound = animalSound
      ..effectSound = true
      ..haptics = true
      ..reduceMotion = false
      ..puzzleGridSize = 3;
  }

  setUp(designDefaults);
  tearDown(() async {
    designDefaults(animalSound: true);
    await store.reset();
  });

  testWidgets('360 defolt tema (testlərdəki kimi)', (tester) async {
    await _pumpPage(tester, const Size(360, 640), elifbaTheme: false);
    await _capture(tester, 'x_360_default-theme_main-list');
    await _openFromRow(tester, 'Progresi sıfırla');
    await _capture(tester, 'x_360_default-theme_reset-confirm');
  });

  testWidgets('360 şrift 1.3', (tester) async {
    _seedStars(store, 41);
    await _pumpPage(tester, const Size(360, 640), textScale: 1.3);
    await _capture(tester, 'x_360_text1.3_main-list');
    _pagePosition(tester).jumpTo(_pagePosition(tester).maxScrollExtent);
    await tester.pumpAndSettle();
    await _capture(tester, 'x_360_text1.3_main-list-bottom');
    await _openFromRow(tester, 'Progresi sıfırla');
    await _capture(tester, 'x_360_text1.3_reset-confirm');
    await tester.tap(find.text('Ləğv et'));
    await tester.pumpAndSettle();
    await _openFromRow(tester, 'Tətbiq haqqında');
    await _capture(tester, 'x_360_text1.3_about-dialog');
    await tester.tap(find.text('Bağla'));
    await tester.pumpAndSettle();
    await _openFromRow(tester, 'Səs mənbələri');
    await _capture(tester, 'x_360_text1.3_sound-credits-dialog');
  });

  for (final (size, tag) in const [
    (Size(360, 640), '360'),
    (Size(412, 915), '412'),
  ]) {
    testWidgets('$tag əsas siyahı', (tester) async {
      await _pumpPage(tester, size);
      await _capture(tester, '${tag}_01_main-list');

      // Siyahının sonu: «Valideyn» və «Məlumat» kartları, alt boşluq.
      _pagePosition(tester).jumpTo(_pagePosition(tester).maxScrollExtent);
      await tester.pumpAndSettle();
      await _capture(tester, '${tag}_01b_main-list-bottom');
    });

    testWidgets('$tag bütün səslər söndürülüb', (tester) async {
      settings.masterSound = false;
      await _pumpPage(tester, size);
      await _capture(tester, '${tag}_02_all-sound-off');
    });

    testWidgets('$tag pazl 5 × 5 seçilib', (tester) async {
      settings.puzzleGridSize = 5;
      await _pumpPage(tester, size);
      _pagePosition(tester).jumpTo(260);
      await tester.pumpAndSettle();
      await _capture(tester, '${tag}_02b_puzzle-5x5');
    });

    testWidgets('$tag sıfırlama təsdiqi', (tester) async {
      _seedStars(store, 41);
      expect(store.totalStars, 41);
      await _pumpPage(tester, size);
      await _openFromRow(tester, 'Progresi sıfırla');
      expect(find.text('Bütün ulduzlar silinsin?'), findsOneWidget);
      await _capture(tester, '${tag}_03_reset-confirm');
    });

    testWidgets('$tag snackbar', (tester) async {
      _seedStars(store, 41);
      await _pumpPage(tester, size);
      await _openFromRow(tester, 'Progresi sıfırla');
      await tester.tap(find.text('Bəli, sil'));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(store.totalStars, 0);
      expect(find.text('Progres sıfırlandı.'), findsOneWidget);
      await _capture(tester, '${tag}_04_snackbar-progress-reset');
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });

    testWidgets('$tag səs mənbələri', (tester) async {
      await _pumpPage(tester, size);
      await _openFromRow(tester, 'Səs mənbələri');
      expect(find.textContaining('bigsoundbank.com'), findsOneWidget);
      await _capture(tester, '${tag}_05_sound-credits-dialog');

      // Dialoqun sonu: «Bağla» və son qeyd.
      final dialogScroll = tester.state<ScrollableState>(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(Scrollable),
        ),
      );
      dialogScroll.position.jumpTo(dialogScroll.position.maxScrollExtent);
      await tester.pumpAndSettle();
      await _capture(tester, '${tag}_05b_sound-credits-dialog-end');
    });

    testWidgets('$tag tətbiq haqqında', (tester) async {
      await _pumpPage(tester, size);
      await _openFromRow(tester, 'Tətbiq haqqında');
      await _capture(tester, '${tag}_06_about-dialog');
    });
  }
}
