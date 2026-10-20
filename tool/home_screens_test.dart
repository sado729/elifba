// Ana səhifənin (əlifba kitabı) vizual yoxlaması — dizayn render-ləri ilə
// gözlə müqayisə üçün PNG-lər.
//
// `test/`-də DEYİL, ona görə adi `flutter test` onu işlətmir. Belə işlədin:
//
//   flutter test tool/home_screens_test.dart
//
// PNG-lər `HOME_SCREENS_OUT` qovluğuna (yoxdursa `build/home_screens/`)
// yazılır, 1 dp = 1 px: 360x640 və 412x915 maketləri ilə eyni ölçüdə. Maket
// çərçivələrinin 24 dp status bar-ı və 24 dp nav bar-ı `FakeViewPadding` ilə
// təqlid olunur (ikonlar çəkilmir).
//
// Real şriftlər (Comfortaa, Andika, MaterialIcons) `FontLoader` ilə yüklənir.
// Səhifə `GatedPlayer` qurur və şəkil çəkmək `tester.runAsync` tələb edir —
// real event loop-da `just_audio` platformaya getməsin deyə saxta
// `JustAudioPlatform` və `path_provider` kanalı qoşulur (CLAUDE.md gotcha 11).

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:elifba/core/config.dart';
import 'package:elifba/core/progress.dart';
import 'package:elifba/core/settings.dart';
import 'package:elifba/pages/alphabet_page.dart';
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
  final env = Platform.environment['HOME_SCREENS_OUT'];
  if (env != null && env.isNotEmpty) return env;
  return 'build/home_screens';
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

// ------------------------------------------------- saxta just_audio platforması

// `tool/` analizatorun gözündə test qovluğu deyil, mixin isə yalnız testlər
// üçün açıqdır.
// ignore: invalid_use_of_visible_for_testing_member
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

class _FakePlayer extends AudioPlayerPlatform {
  _FakePlayer(super.id);

  final _events = StreamController<PlaybackEventMessage>.broadcast();

  @override
  Stream<PlaybackEventMessage> get playbackEventMessageStream => _events.stream;

  @override
  Future<LoadResponse> load(LoadRequest request) async =>
      LoadResponse(duration: const Duration(milliseconds: 500));

  @override
  Future<PlayResponse> play(PlayRequest request) async => PlayResponse();

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
  Future<SetAutomaticallyWaitsToMinimizeStallingResponse>
  setAutomaticallyWaitsToMinimizeStalling(
    SetAutomaticallyWaitsToMinimizeStallingRequest request,
  ) async => SetAutomaticallyWaitsToMinimizeStallingResponse();

  @override
  Future<SetCanUseNetworkResourcesForLiveStreamingWhilePausedResponse>
  setCanUseNetworkResourcesForLiveStreamingWhilePaused(
    SetCanUseNetworkResourcesForLiveStreamingWhilePausedRequest request,
  ) async => SetCanUseNetworkResourcesForLiveStreamingWhilePausedResponse();

  @override
  Future<SetPreferredPeakBitRateResponse> setPreferredPeakBitRate(
    SetPreferredPeakBitRateRequest request,
  ) async => SetPreferredPeakBitRateResponse();

  @override
  Future<SetAllowsExternalPlaybackResponse> setAllowsExternalPlayback(
    SetAllowsExternalPlaybackRequest request,
  ) async => SetAllowsExternalPlaybackResponse();

  @override
  Future<SeekResponse> seek(SeekRequest request) async => SeekResponse();

  @override
  Future<SetAndroidAudioAttributesResponse> setAndroidAudioAttributes(
    SetAndroidAudioAttributesRequest request,
  ) async => SetAndroidAudioAttributesResponse();

  @override
  Future<DisposeResponse> dispose(DisposeRequest request) async {
    await _events.close();
    return DisposeResponse();
  }
}

// ---------------------------------------------------------------- vəziyyətlər

/// Maketin `PROG` cədvəli (ScreenHome.dc.html): cəmi 41 ulduz.
const List<int> _designProgress = [
  3, 1, 2, 2, 2, 3, 3, 2, 1, 3, 1, 2, 0, 1, 0, 2, //
  1, 1, 2, 1, 0, 1, 1, 0, 2, 1, 0, 1, 0, 1, 1, 0,
];

/// Hər hərfə maketdəki qədər ulduz verir: 3 = hər şey, 2 = heyvanlar (yazı
/// yox), 1 = yalnız yazı.
void _applyProgress(List<int> prog) {
  final store = ProgressStore.instance;
  for (var i = 0; i < AppConfig.alphabet.length; i++) {
    final letter = AppConfig.alphabet[i];
    final n = prog[i];
    if (n == 0) continue;
    if (n >= 2) {
      for (final animal in AppConfig.animalsByLetter[letter] ?? const []) {
        for (final task in store.tasksOf(animal)) {
          store.markDone(animal, task);
        }
      }
    }
    if (n != 2) store.markWritten(letter);
    expect(store.starsOf(letter), n, reason: '$letter hərfinin ulduzu');
  }
}

final _shotKey = GlobalKey();

Future<void> _shot(
  WidgetTester tester,
  String name,
  Size size, {
  int spread = 0,
  List<int>? progress,
  bool muted = false,
  double inset = 24,
  Future<void> Function()? beforeCapture,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.view.padding = FakeViewPadding(top: inset, bottom: inset);
  tester.view.viewPadding = FakeViewPadding(top: inset, bottom: inset);
  addTearDown(tester.view.reset);

  AppSettings.instance.masterSound = !muted;
  if (progress != null) _applyProgress(progress);

  await tester.pumpWidget(
    RepaintBoundary(
      key: _shotKey,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ElifbaTheme.light(),
        builder:
            (context, child) => MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.3,
              child: child!,
            ),
        home: const AlphabetPage(),
      ),
    ),
  );
  await tester.pump();
  if (spread > 0) {
    tester
        .widget<PageView>(find.byType(PageView))
        .controller!
        .jumpToPage(spread);
    await tester.pump();
  }
  await tester.pumpAndSettle();
  if (beforeCapture != null) await beforeCapture();

  final boundary =
      tester.renderObject(find.byKey(_shotKey)) as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final ui.Image image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final dir = Directory(_outDir)..createSync(recursive: true);
    File(
      '${dir.path}${Platform.pathSeparator}$name.png',
    ).writeAsBytesSync(data!.buffer.asUint8List());
  });
  expect(tester.takeException(), isNull);
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

void main() {
  late Directory tmp;

  setUpAll(() async {
    await _loadFonts();
    JustAudioPlatform.instance = _FakeJustAudio();
    tmp = Directory.systemTemp.createTempSync('home_screens_');
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => tmp.path,
        );
  });

  tearDownAll(() {
    try {
      tmp.deleteSync(recursive: true);
    } catch (_) {}
  });

  Future<void> reset() async {
    AppSettings.instance
      ..masterSound = true
      ..reduceMotion = false;
    await ProgressStore.instance.reset();
  }

  setUp(reset);
  tearDown(reset);

  const small = Size(360, 640);
  const large = Size(412, 915);

  testWidgets('home_01 ilk açılış · A–B · 0 ulduz · 360', (tester) async {
    await _shot(tester, 'home_01_first-open-a-b-0stars_360', small);
  });

  testWidgets('home_02 orta · Ə–F · Ə tamam · 360', (tester) async {
    await _shot(
      tester,
      'home_02_middle-e-f-e-done_360',
      small,
      spread: 3,
      progress: _designProgress,
    );
    expect(ProgressStore.instance.totalStars, 41);
  });

  testWidgets('home_03 son · Y–Z · irəli disabled · 360', (tester) async {
    await _shot(
      tester,
      'home_03_last-y-z-next-disabled_360',
      small,
      spread: 15,
      progress: _designProgress,
    );
  });

  testWidgets('home_04 səs söndürülüb · 360', (tester) async {
    await _shot(
      tester,
      'home_04_sound-muted_360',
      small,
      spread: 3,
      progress: _designProgress,
      muted: true,
    );
  });

  testWidgets('home_05 ilk açılış · 412', (tester) async {
    await _shot(tester, 'home_05_first-open_412', large);
  });

  testWidgets('home_06 orta · 412', (tester) async {
    await _shot(
      tester,
      'home_06_middle_412',
      large,
      spread: 3,
      progress: _designProgress,
    );
  });

  testWidgets('home_07 son · 412', (tester) async {
    await _shot(
      tester,
      'home_07_last_412',
      large,
      spread: 15,
      progress: _designProgress,
    );
  });

  testWidgets('home_08 səs söndürülüb · 412', (tester) async {
    await _shot(
      tester,
      'home_08_sound-muted_412',
      large,
      spread: 3,
      progress: _designProgress,
      muted: true,
    );
  });

  // Maketdə olmayan, amma yoxlanmalı hallar.

  testWidgets('x_pressed · Ə səhifəsi və «irəli» basılı · 360', (tester) async {
    TestGesture? card;
    TestGesture? arrow;
    await _shot(
      tester,
      'x_pressed-card-and-arrow_360',
      small,
      spread: 3,
      progress: _designProgress,
      beforeCapture: () async {
        // İki barmaq: kart (üz 4 dp enir, kənar 8 → 4) və ox (maketin
        // style-active-i: translateY 5, kənar 5 → 0).
        card = await tester.startGesture(tester.getCenter(find.text('Ə')));
        arrow = await tester.startGesture(
          tester.getCenter(find.byTooltip('Növbəti səhifə')),
        );
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pump(const Duration(milliseconds: 150));
      },
    );
    await card?.cancel();
    await arrow?.cancel();
  });

  testWidgets('x_midswipe · Ə–F → G–Ğ yarı yolda · 360', (tester) async {
    TestGesture? g;
    await _shot(
      tester,
      'x_midswipe-gap-between-spreads_360',
      small,
      spread: 3,
      progress: _designProgress,
      beforeCapture: () async {
        g = await tester.startGesture(tester.getCenter(find.byType(PageView)));
        await g!.moveBy(const Offset(-190, 0));
        await tester.pump();
      },
    );
    await g?.cancel();
  });

  testWidgets('x_spread7 · I–İ · 360', (tester) async {
    await _shot(tester, 'x_spread7-i-dotless-dotted_360', small, spread: 6);
  });

  testWidgets('x_landscape · 640x360', (tester) async {
    await _shot(
      tester,
      'x_landscape_640x360',
      const Size(640, 360),
      inset: 0,
      progress: _designProgress,
    );
  });

  testWidgets('x_test_surface · 800x600', (tester) async {
    await _shot(
      tester,
      'x_test-surface_800x600',
      const Size(800, 600),
      inset: 0,
      progress: _designProgress,
    );
  });
}
