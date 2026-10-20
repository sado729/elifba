// Heyvan səhifəsinin vizual yoxlaması (əl ilə müqayisə üçün).
//
// `test/`-də DEYİL, ona görə adi `flutter test` onu işlətmir. Belə işlədin:
//
//   flutter test tool/animal_screens_test.dart
//
// Hər dizayn vəziyyətini (ScreenAnimal renderləri, 360x640 və 412x915) real
// şriftlərlə (Comfortaa/Andika + MaterialIcons) qurur və PNG kimi
// `SCREENS_OUT` qovluğuna (yoxdursa `build/animal_screens/`) yazır.
//
// Səhifə `GatedPlayer` → `AudioPlayer` qurur. Şəkil çəkmək üçün
// `tester.runAsync` lazımdır, real event loop isə just_audio-nu platformaya
// göndərərdi (CLAUDE.md gotcha 11). Ona görə burada saxta just_audio
// platforması və `path_provider` / `audio_session` kanallarının cavabları
// quraşdırılır — heç bir səs çalınmır, heç nə platformaya getmir.
//
// Analizator `tool/`-u test kodu saymır, ona görə test üçün nəzərdə tutulmuş
// `ProgressStore.forTesting` və `MockPlatformInterfaceMixin` xəbərdarlıq verir.
// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:elifba/core/config.dart';
import 'package:elifba/core/progress.dart';
import 'package:elifba/core/settings.dart';
import 'package:elifba/core/utils.dart';
import 'package:elifba/pages/animal_detail_page.dart';
import 'package:elifba/pages/puzzle_page.dart';
import 'package:elifba/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

String get _outDir {
  final env = Platform.environment['SCREENS_OUT'];
  if (env != null && env.isNotEmpty) return env;
  return 'build/animal_screens';
}

// ------------------------------------------------------- saxta just_audio

class _FakeJustAudio extends JustAudioPlatform with MockPlatformInterfaceMixin {
  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async =>
      _FakePlayer(request.id);

  @override
  Future<DisposePlayerResponse> disposePlayer(
    DisposePlayerRequest request,
  ) async => DisposePlayerResponse();

  @override
  Future<DisposeAllPlayersResponse> disposeAllPlayers(
    DisposeAllPlayersRequest request,
  ) async => DisposeAllPlayersResponse();
}

/// Heç nə çalmır, heç vaxt `completed` hadisəsi vermir — «Dayandır»
/// vəziyyəti açıq qalır.
class _FakePlayer extends AudioPlayerPlatform {
  _FakePlayer(super.id);

  @override
  Stream<PlaybackEventMessage> get playbackEventMessageStream =>
      const Stream<PlaybackEventMessage>.empty();

  @override
  Future<LoadResponse> load(LoadRequest request) async =>
      LoadResponse(duration: const Duration(seconds: 3));

  @override
  Future<PlayResponse> play(PlayRequest request) =>
      Completer<PlayResponse>().future; // çalınma "davam edir"

  @override
  Future<PauseResponse> pause(PauseRequest request) async => PauseResponse();

  @override
  Future<SetVolumeResponse> setVolume(SetVolumeRequest request) async =>
      SetVolumeResponse();

  @override
  Future<SetSpeedResponse> setSpeed(SetSpeedRequest request) async =>
      SetSpeedResponse();

  @override
  Future<SetPitchResponse> setPitch(SetPitchRequest request) async =>
      SetPitchResponse();

  @override
  Future<SetSkipSilenceResponse> setSkipSilence(
    SetSkipSilenceRequest request,
  ) async => SetSkipSilenceResponse();

  @override
  Future<SetLoopModeResponse> setLoopMode(SetLoopModeRequest request) async =>
      SetLoopModeResponse();

  @override
  Future<SetShuffleModeResponse> setShuffleMode(
    SetShuffleModeRequest request,
  ) async => SetShuffleModeResponse();

  @override
  Future<SetShuffleOrderResponse> setShuffleOrder(
    SetShuffleOrderRequest request,
  ) async => SetShuffleOrderResponse();

  @override
  Future<SeekResponse> seek(SeekRequest request) async => SeekResponse();

  @override
  Future<SetAndroidAudioAttributesResponse> setAndroidAudioAttributes(
    SetAndroidAudioAttributesRequest request,
  ) async => SetAndroidAudioAttributesResponse();

  @override
  Future<DisposeResponse> dispose(DisposeRequest request) async =>
      DisposeResponse();
}

// ------------------------------------------------------------ şriftlər

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
  final comfortaa = FontLoader('Comfortaa')
    ..addFont(_bytes('assets/fonts/Comfortaa-Bold.ttf'));
  final andika =
      FontLoader('Andika')
        ..addFont(_bytes('assets/fonts/Andika-Regular.ttf'))
        ..addFont(_bytes('assets/fonts/Andika-Bold.ttf'));
  await comfortaa.load();
  await andika.load();
  final root = _flutterRoot();
  if (root == null) return;
  final sep = Platform.pathSeparator;
  final icons = File(
    '$root${sep}bin${sep}cache${sep}artifacts${sep}material_fonts$sep'
    'materialicons-regular.otf',
  );
  if (icons.existsSync()) {
    await (FontLoader('MaterialIcons')..addFont(_bytes(icons.path))).load();
  }
}

// ------------------------------------------------------------ köməkçilər

final _shotKey = GlobalKey();

String _letterOf(String animal) => AppConfig.alphabet.firstWhere(
  (l) => (AppConfig.animalsByLetter[l] ?? const []).contains(animal),
);

void _resetSettings() {
  final s = AppSettings.instance;
  s.masterSound = true;
  s.narrationSound = true;
  s.animalSound = true;
  s.effectSound = true;
  s.reduceMotion = false;
  s.puzzleGridSize = 3;
}

void _setSurface(WidgetTester tester, double w, double h) {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = Size(w * 2, h * 2);
  // Maketlər kimi: 24 dp status bar, 24 dp jest zolağı.
  tester.view.padding = const FakeViewPadding(top: 48, bottom: 48);
  tester.view.viewPadding = const FakeViewPadding(top: 48, bottom: 48);
}

/// Real vaxtın keçməsinə imkan verir (dekod, konfeti fizikası).
Future<void> _realFrames(WidgetTester tester, int frames) async {
  for (var i = 0; i < frames; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 16)),
    );
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<void> _precache(WidgetTester tester, String animal) async {
  final data = AppConfig.findAnimal(getFirstLetter(animal), animal)!;
  final context = tester.element(find.byType(AnimalDetailPage));
  final providers = <ImageProvider>[
    ResizeImage(AssetImage(data.imagePath), width: kAnimalHeroDecodeWidth),
    for (final f in data.foods)
      ResizeImage(
        AssetImage('assets/foods/${AppConfig.normalizeFileName(f)}.webp'),
        width: kFoodDecodeWidth,
      ),
    ResizeImage(
      AssetImage(data.imagePath.replaceFirst('.webp', '_puzzle.jpg')),
      width: kPuzzleThumbDecodeWidth,
    ),
  ];
  await tester.runAsync(() async {
    for (final p in providers) {
      await precacheImage(p, context);
    }
  });
}

Future<ProgressStore> _open(
  WidgetTester tester,
  String animal, {
  double w = 360,
  double h = 640,
  void Function(ProgressStore store)? prepare,
}) async {
  _setSurface(tester, w, h);
  addTearDown(tester.view.reset);
  addTearDown(_resetSettings);
  final store = ProgressStore.forTesting();
  addTearDown(store.dispose);
  prepare?.call(store);
  final animals = AppConfig.animalsByLetter[_letterOf(animal)]!;
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ElifbaTheme.light(),
      builder: (context, child) => RepaintBoundary(key: _shotKey, child: child),
      home: AnimalDetailPage(
        animal: animal,
        animals: animals,
        currentIndex: animals.indexOf(animal),
        store: store,
      ),
    ),
  );
  await tester.pump();
  await _precache(tester, animal);
  await _realFrames(tester, 4);
  await tester.pump(const Duration(milliseconds: 500));
  return store;
}

/// Tab zolağının üfüqi `Scrollable`-ı.
final Finder _strip = find.byWidgetPredicate(
  (w) => w is Scrollable && w.axisDirection == AxisDirection.right,
);

Future<void> _tab(WidgetTester tester, String label) async {
  final screenWidth =
      tester.view.physicalSize.width / tester.view.devicePixelRatio;
  final tab = find.text(label);
  var scrolled = false;
  if (tester.getCenter(tab).dx > screenWidth - 24) {
    // 360 dp-də «Pazl» zolağın sonundadır: əvvəlcə zolağı sürüşdür.
    await tester.drag(_strip, const Offset(-400, 0));
    await tester.pump(const Duration(milliseconds: 600));
    scrolled = true;
  }
  await tester.tap(tab);
  // Squish basışı (90 ms) bitəndən sonra buraxılış (140 ms) başlayır.
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  if (scrolled) {
    // Maketdəki kimi zolaq başlanğıca qaytarılır.
    await tester.drag(_strip, const Offset(400, 0));
    await tester.pump(const Duration(milliseconds: 600));
  }
}

/// Pazl şəklinin `ui.Image` dekodunu (real IO) gözləyir.
Future<void> _waitPuzzleImage(WidgetTester tester) async {
  for (var i = 0; i < 60; i++) {
    if (_tilePainters().evaluate().isNotEmpty) break;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 300));
}

Finder _tilePainters() => find.byWidgetPredicate(
  (w) => w is CustomPaint && w.painter is PuzzleTilePainter,
);

Finder _trayPieceOf(int piece, int n) => find.byWidgetPredicate((w) {
  if (w is! CustomPaint || w.painter is! PuzzleTilePainter) return false;
  final p = w.painter as PuzzleTilePainter;
  return p.row == piece ~/ n && p.col == piece % n;
});

Future<void> _drag(WidgetTester tester, Offset from, Offset to) async {
  final g = await tester.startGesture(from);
  await tester.pump();
  await g.moveBy(const Offset(0, -12));
  await tester.pump();
  await g.moveTo(to);
  await tester.pump();
  await g.up();
  await tester.pump();
}

/// [piece] parçasını səbətdən lövhənin [cell] xanasına sürükləyir.
Future<void> _placePiece(
  WidgetTester tester,
  int piece,
  int cell,
  int n,
) async {
  final from = tester.getCenter(_trayPieceOf(piece, n).first);
  final to = tester.getCenter(find.byType(DragTarget<int>).at(cell));
  await _drag(tester, from, to);
}

/// [letter] hərfini səbətdən [slot] slotuna sürükləyir.
Future<void> _placeLetter(WidgetTester tester, String letter, int slot) async {
  final tile = find.descendant(
    of: find.byType(Draggable<String>),
    matching: find.text(letter),
  );
  final from = tester.getCenter(tile.first);
  final to = tester.getCenter(find.byType(DragTarget<String>).at(slot));
  await _drag(tester, from, to);
}

Future<void> _shoot(WidgetTester tester, String name) async {
  final boundary =
      tester.renderObject(find.byKey(_shotKey)) as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final ui.Image image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final file = File('$_outDir${Platform.pathSeparator}$name.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(data!.buffer.asUint8List());
  });
  // Daşma (RenderFlex overflow) və ya başqa xəta olmamalıdır.
  expect(tester.takeException(), isNull, reason: name);
}

void _prepareAllButInfo(ProgressStore store, String animal) {
  for (final task in store.tasksOf(animal)) {
    if (task == Activity.info) continue;
    store.markDone(animal, task);
  }
  for (final food in AppConfig.animalFoods[animal]!) {
    store.markFoodFed(animal, food);
  }
}

// ---------------------------------------------------------------- testlər

void main() {
  setUpAll(() async {
    JustAudioPlatform.instance = _FakeJustAudio();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.ryanheise.audio_session'),
      (call) async => null,
    );
    // Asset-in kopyalanması real IO-dur: saxta async-də heç vaxt bitmir, ona
    // görə `setAsset` asılı qalır və «Dayandır» vəziyyəti dəyişmir.
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => Directory.systemTemp.path,
    );
    await _loadFonts();
  });

  // ----------------------------------------------------------- 360 x 640

  testWidgets('01 info ready 360', (tester) async {
    await _open(tester, 'Ayı');
    await _shoot(tester, 'animal_01_info-ready_360');
  });

  testWidgets('02 info playing, animal sound muted 360', (tester) async {
    AppSettings.instance.animalSound = false;
    await _open(tester, 'Ayı');
    await tester.tap(find.text('Dinlə'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await _shoot(tester, 'animal_02_info-playing-sound-muted_360');
    // Nəbz sonsuzdur — ağacı dayandırıb bitiririk.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('02b narration muted 360', (tester) async {
    AppSettings.instance.narrationSound = false;
    await _open(tester, 'Ayı');
    await _shoot(tester, 'animal_02b_info-narration-muted_360');
  });

  testWidgets('03 food rest 360', (tester) async {
    await _open(tester, 'Ayı');
    await _tab(tester, 'Qidalar');
    await _shoot(tester, 'animal_03_food-rest_360');
  });

  testWidgets('04 food flight + arrival 360', (tester) async {
    await _open(tester, 'Ayı');
    await _tab(tester, 'Qidalar');
    await tester.tap(find.text('Bal'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 420));
    await _shoot(tester, 'animal_04_food-flight_360');
    await tester.pump(const Duration(milliseconds: 520));
    await _shoot(tester, 'animal_04b_food-arrival_360');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 300));
    await _shoot(tester, 'animal_04c_food-after_360');
  });

  testWidgets('04d food reduced motion 360', (tester) async {
    AppSettings.instance.reduceMotion = true;
    await _open(tester, 'Ayı');
    await _tab(tester, 'Qidalar');
    await tester.tap(find.text('Balıq'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await _shoot(tester, 'animal_04d_food-reduced-hold_360');
    await tester.pump(const Duration(milliseconds: 600));
  });

  testWidgets('05 food fed 2/3 360', (tester) async {
    await _open(
      tester,
      'Ayı',
      prepare: (s) {
        s.markFoodFed('Ayı', 'Bal');
        s.markFoodFed('Ayı', 'Balıq');
      },
    );
    await _tab(tester, 'Qidalar');
    await _shoot(tester, 'animal_05_food-fed-2of3_360');
  });

  testWidgets('06 word empty Ayı 360', (tester) async {
    await _open(tester, 'Ayı');
    await _tab(tester, 'Söz tapmaca');
    await _shoot(tester, 'animal_06_word-empty-ayi_360');
  });

  testWidgets('07 word partial Qarışqayeyən 360', (tester) async {
    await _open(tester, 'Qarışqayeyən');
    await _tab(tester, 'Söz tapmaca');
    // Sürükləmə üçün hündür səth (səbətin ikinci sətri də görünsün).
    _setSurface(tester, 360, 1100);
    await tester.pump();
    await _placeLetter(tester, 'Q', 0);
    await _placeLetter(tester, 'a', 1);
    await _placeLetter(tester, 'r', 2);
    await _placeLetter(tester, 'ş', 3);
    _setSurface(tester, 360, 640);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await _shoot(tester, 'animal_07_word-partial-qarisqayeyen_360');
  });

  testWidgets('07b word mid-shake 360', (tester) async {
    await _open(tester, 'Ayı');
    await _tab(tester, 'Söz tapmaca');
    _setSurface(tester, 360, 1000);
    await tester.pump();
    // Səhv hərf → silkələnmə; doğru → pop.
    await _placeLetter(tester, 'ı', 0);
    await tester.pump(const Duration(milliseconds: 60));
    _setSurface(tester, 360, 640);
    await tester.pump();
    await _shoot(tester, 'animal_07b_word-wrong-shake_360');
    await tester.pump(const Duration(milliseconds: 400));
  });

  testWidgets('08 word solved, small win 360', (tester) async {
    await _open(tester, 'Ayı');
    await _tab(tester, 'Söz tapmaca');
    _setSurface(tester, 360, 1000);
    await tester.pump();
    await _placeLetter(tester, 'A', 0);
    await _placeLetter(tester, 'y', 1);
    await _placeLetter(tester, 'ı', 2);
    _setSurface(tester, 360, 640);
    await tester.pump();
    expect(find.text('Təbriklər!'), findsOneWidget);
    await _realFrames(tester, 20);
    await _shoot(tester, 'animal_08_word-solved_360');
  });

  testWidgets('08b word solved, reduced motion 360', (tester) async {
    AppSettings.instance.reduceMotion = true;
    await _open(tester, 'Ayı');
    await _tab(tester, 'Söz tapmaca');
    _setSurface(tester, 360, 1000);
    await tester.pump();
    await _placeLetter(tester, 'A', 0);
    await _placeLetter(tester, 'y', 1);
    await _placeLetter(tester, 'ı', 2);
    _setSurface(tester, 360, 640);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await _shoot(tester, 'animal_08b_word-solved-reduced_360');
  });

  testWidgets('09 all done, full star 360', (tester) async {
    await _open(tester, 'Ayı', prepare: (s) => _prepareAllButInfo(s, 'Ayı'));
    expect(find.text('Tam ulduz!'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 900));
    await _realFrames(tester, 25);
    await _shoot(tester, 'animal_09_all-done-full-star_360');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('09b full star, reduced motion 360', (tester) async {
    AppSettings.instance.reduceMotion = true;
    await _open(tester, 'Ayı', prepare: (s) => _prepareAllButInfo(s, 'Ayı'));
    await tester.pump(const Duration(milliseconds: 400));
    await _shoot(tester, 'animal_09b_full-star-reduced_360');
  });

  testWidgets('10 puzzle 3x3 tray 360', (tester) async {
    AppSettings.instance.puzzleGridSize = 3;
    await _open(tester, 'Ayı');
    await _tab(tester, 'Pazl');
    await _waitPuzzleImage(tester);
    await _shoot(tester, 'animal_10_puzzle-3x3-tray_360');
  });

  Future<void> playing(WidgetTester tester, int n, double w, double h) async {
    AppSettings.instance.puzzleGridSize = n;
    await _open(tester, 'Ayı', w: w, h: h);
    await _tab(tester, 'Pazl');
    await _waitPuzzleImage(tester);
    _setSurface(tester, w, 1600);
    await tester.pump();
    await _placePiece(tester, 0, 0, n);
    await _placePiece(tester, 1, 1, n);
    await _placePiece(tester, n + 1, n + 1, n);
    await _placePiece(tester, 2 * n + 1, n, n); // səhv
    _setSurface(tester, w, h);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('11 puzzle 4x4 right/wrong 360', (tester) async {
    await playing(tester, 4, 360, 640);
    await _shoot(tester, 'animal_11_puzzle-4x4-right-wrong_360');
  });

  testWidgets('12 puzzle 5x5 playing 360', (tester) async {
    await playing(tester, 5, 360, 640);
    await _shoot(tester, 'animal_12_puzzle-5x5-playing_360');
  });

  testWidgets('13 puzzle hint 360', (tester) async {
    AppSettings.instance.puzzleGridSize = 3;
    await _open(tester, 'Ayı');
    await _tab(tester, 'Pazl');
    await _waitPuzzleImage(tester);
    await tester.tap(find.text('İpucu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await _shoot(tester, 'animal_13_puzzle-hint_360');
    // Ipucu ulduz vermir (gotcha 14) və 2 s sonra bitir.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('13b puzzle peek 360', (tester) async {
    AppSettings.instance.puzzleGridSize = 3;
    await _open(tester, 'Ayı');
    await _tab(tester, 'Pazl');
    await _waitPuzzleImage(tester);
    final g = await tester.startGesture(
      tester.getCenter(find.bySemanticsLabel('Basıb saxla')),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await _shoot(tester, 'animal_13b_puzzle-peek_360');
    await g.up();
    await tester.pump();
  });

  testWidgets('14 puzzle done + card 360', (tester) async {
    AppSettings.instance.puzzleGridSize = 3;
    await _open(tester, 'Ayı');
    await _tab(tester, 'Pazl');
    await _waitPuzzleImage(tester);
    _setSurface(tester, 360, 1400);
    await tester.pump();
    for (var i = 0; i < 9; i++) {
      await _placePiece(tester, i, i, 3);
    }
    _setSurface(tester, 360, 640);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await _shoot(tester, 'animal_14a_puzzle-done-board_360');
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Pazl tamamlandı!'), findsOneWidget);
    await _shoot(tester, 'animal_14_puzzle-done-dialog_360');
  });

  testWidgets('19 scrolled, tabs pinned 360', (tester) async {
    await _open(tester, 'Ayı');
    await tester.drag(
      find.byKey(const ValueKey('animalPageScroll')),
      const Offset(0, -300),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await _shoot(tester, 'animal_19_scrolled-tabs-pinned_360');
  });

  // ----------------------------------------------------------- 412 x 915

  testWidgets('15 info 412', (tester) async {
    await _open(tester, 'Ayı', w: 412, h: 915);
    await _shoot(tester, 'animal_15_info_412');
  });

  testWidgets('16 word partial Qarışqayeyən 412', (tester) async {
    await _open(tester, 'Qarışqayeyən', w: 412, h: 915);
    await _tab(tester, 'Söz tapmaca');
    await _placeLetter(tester, 'Q', 0);
    await _placeLetter(tester, 'a', 1);
    await _placeLetter(tester, 'r', 2);
    await _placeLetter(tester, 'ş', 3);
    await tester.pump(const Duration(milliseconds: 400));
    await _shoot(tester, 'animal_16_word-partial-qarisqayeyen_412');
  });

  testWidgets('17 puzzle 5x5 412', (tester) async {
    await playing(tester, 5, 412, 915);
    await _shoot(tester, 'animal_17_puzzle-5x5_412');
  });

  testWidgets('18 food fed 412', (tester) async {
    await _open(
      tester,
      'Ayı',
      w: 412,
      h: 915,
      prepare: (s) {
        s.markFoodFed('Ayı', 'Bal');
        s.markFoodFed('Ayı', 'Balıq');
      },
    );
    await _tab(tester, 'Qidalar');
    await _shoot(tester, 'animal_18_food-fed_412');
  });

  // ------------------------------------------------- daşma yoxlamaları

  testWidgets('20 test surface 800x600, every section', (tester) async {
    await _open(tester, 'Tülkü', w: 800, h: 600);
    await _shoot(tester, 'animal_20a_info_800');
    await _tab(tester, 'Qidalar');
    await _shoot(tester, 'animal_20b_food_800');
    await _tab(tester, 'Söz tapmaca');
    await _shoot(tester, 'animal_20c_word_800');
    await _tab(tester, 'Pazl');
    await _waitPuzzleImage(tester);
    await _shoot(tester, 'animal_20d_puzzle_800');
  });

  testWidgets('21 six foods + 5-letter word 360', (tester) async {
    await _open(tester, 'Tülkü');
    await _tab(tester, 'Qidalar');
    await _shoot(tester, 'animal_21a_tulku-6-foods_360');
    await _tab(tester, 'Söz tapmaca');
    await _shoot(tester, 'animal_21b_tulku-word_360');
  });

  testWidgets('21c long name, no description 360', (tester) async {
    await _open(tester, 'Qarışqayeyən');
    await _shoot(tester, 'animal_21c_qarisqayeyen-info_360');
  });

  testWidgets('21d 6-letter name stays on one row 360', (tester) async {
    await _open(tester, 'Pələng');
    await _tab(tester, 'Söz tapmaca');
    await _shoot(tester, 'animal_21d_peleng-word_360');
  });

  testWidgets('22 feeding while the stage is half scrolled 360', (
    tester,
  ) async {
    await _open(tester, 'Tülkü');
    await _tab(tester, 'Qidalar');
    await tester.drag(
      find.byKey(const ValueKey('animalPageScroll')),
      const Offset(0, -120),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Alma'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 880));
    await _shoot(tester, 'animal_22_feeding-scrolled_360');
    await tester.pump(const Duration(milliseconds: 900));
  });
}
