// Yazı oyununun (LetterWritingPage) dizayn vəziyyətlərinin ekran şəkilləri —
// ScreenTrace renderləri ilə gözlə müqayisə üçün.
//
// `test/`-də DEYİL, ona görə adi `flutter test` onu işlətmir. Belə işlədin:
//
//   flutter test tool/trace_screens_test.dart
//
// PNG-lər `TRACE_SCREENS_OUT` qovluğuna (yoxdursa `build/trace_screens/`)
// yazılır. Real şriftlər (Comfortaa, Andika, MaterialIcons) yüklənir.
//
// Səhifə `GatedPlayer` → `AudioPlayer` qurur. Şəkli çəkmək üçün
// `tester.runAsync` lazımdır, real event loop isə `just_audio`-nu platformaya
// çıxarar (MissingPluginException). Ona görə burada saxta `just_audio`
// platforması və `audio_session` / `path_provider` kanallarının cavabları
// quraşdırılır. Səhifədə asset şəkli yoxdur — precache lazım deyil.

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:elifba/core/letter_strokes.dart';
import 'package:elifba/core/progress.dart';
import 'package:elifba/core/settings.dart';
import 'package:elifba/core/stroke_tracker.dart';
import 'package:elifba/pages/letter_writing_page.dart';
import 'package:elifba/theme/theme.dart';
import 'package:elifba/widgets/tracing_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

String get _outDir {
  final env = Platform.environment['TRACE_SCREENS_OUT'];
  if (env != null && env.isNotEmpty) return env;
  return 'build/trace_screens';
}

// --------------------------------------------------------------- şriftlər

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
  final andika = FontLoader('Andika')
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

// ------------------------------------------------- saxta səs platforması

// `tool/` analizatorun gözündə test qovluğu deyil.
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
  Stream<PlaybackEventMessage> get playbackEventMessageStream =>
      _events.stream;

  @override
  Future<LoadResponse> load(LoadRequest request) async =>
      LoadResponse(duration: const Duration(milliseconds: 300));

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

void _installFakeAudio(Directory tmp) {
  JustAudioPlatform.instance = _FakeJustAudio();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final name in const [
    'com.ryanheise.audio_session',
    'com.ryanheise.android_audio_manager',
    'com.ryanheise.av_audio_session',
  ]) {
    messenger.setMockMethodCallHandler(
      MethodChannel(name),
      (call) async => call.method == 'setActive' ? true : null,
    );
  }
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (call) async => tmp.path,
  );
}

// ---------------------------------------------------------------- köməkçilər

final _rootKey = GlobalKey();

/// Status bar və jest paneli (dizayndakı kimi 24 + 24 dp).
const double _bar = 24;

Future<ProgressStore> _pump(
  WidgetTester tester, {
  required Size screen,
  String letter = 'B',
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = screen;
  tester.view.padding = const FakeViewPadding(top: _bar, bottom: _bar);
  tester.view.viewPadding = const FakeViewPadding(top: _bar, bottom: _bar);
  addTearDown(tester.view.reset);

  // Dizayndakı sayğac: 12 hərf artıq yazılıb (B yox).
  // ignore: invalid_use_of_visible_for_testing_member
  final store = ProgressStore.forTesting();
  for (final l in const ['A', 'C', 'Ç', 'D', 'E', 'Ə', 'F', 'G', 'H', 'X',
    'K', 'L']) {
    store.markWritten(l);
  }

  await tester.pumpWidget(
    RepaintBoundary(
      key: _rootKey,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ElifbaTheme.light(),
        home: LetterWritingPage(letter: letter, store: store),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  return store;
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

Future<void> _finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}

/// Qutu koordinatını qlobal ekran koordinatına çevirir.
Offset _global(WidgetTester tester, Offset box) {
  final f = find.byType(TracingCanvas);
  final size = tester.getSize(f);
  final s = glyphScale(size);
  return tester.getTopLeft(f) + glyphOrigin(size, s) + box * s;
}

List<TraceUnit> get _b => LetterStrokes.unitsFor('B')!;

/// Ştrixi [to] qədər (0..1) cızır. [lift] false olanda barmaq ekranda qalır.
Future<TestGesture> _trace(
  WidgetTester tester,
  TraceUnit u, {
  double to = 1,
  bool lift = true,
}) async {
  final end = (to * u.lastIndex).round();
  final g = await tester.startGesture(_global(tester, u.points.first));
  for (var i = 2; i < end; i += 2) {
    await g.moveTo(_global(tester, u.points[i]));
  }
  await g.moveTo(_global(tester, u.points[end]));
  if (lift) await g.up();
  await tester.pump();
  return g;
}

/// Bütün hərfi cızır. Bitişik ştrixlərdə (ucu növbətinin başlanğıcıdır)
/// barmaq qalxmır — tracker onları zəncirləyir, qaldırıb yenidən başlamaq
/// isə irəliləmiş yerdən uzaqda rədd edilərdi.
Future<void> _traceAll(WidgetTester tester, List<TraceUnit> units) async {
  TestGesture? g;
  for (var k = 0; k < units.length; k++) {
    final u = units[k];
    g ??= await tester.startGesture(_global(tester, u.points.first));
    for (var i = 2; i < u.lastIndex; i += 2) {
      await g.moveTo(_global(tester, u.points[i]));
    }
    await g.moveTo(_global(tester, u.end));
    final joined =
        k + 1 < units.length && (units[k + 1].start - u.end).distance < 0.5;
    if (!joined) {
      await g.up();
      g = null;
    }
    await tester.pump();
  }
}

/// Konfeti paketi addımı real saatla ölçür: hər kadr arasında real gecikmə.
Future<void> _realFrames(WidgetTester tester, int frames) async {
  for (var i = 0; i < frames; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 17)),
    );
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  late Directory tmp;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFonts();
    tmp = Directory.systemTemp.createTempSync('elifba_trace_');
    _installFakeAudio(tmp);
  });

  tearDownAll(() {
    try {
      tmp.deleteSync(recursive: true);
    } catch (_) {}
  });

  const sizes = {'360': Size(360, 640), '412': Size(412, 915)};

  for (final e in sizes.entries) {
    final w = e.key;
    final screen = e.value;

    testWidgets('01 start $w', (tester) async {
      await _pump(tester, screen: screen);
      await _capture(tester, 'trace_01_start_$w');
      await _finish(tester);
    });

    testWidgets('02 mid-stroke $w', (tester) async {
      await _pump(tester, screen: screen);
      await _trace(tester, _b[0]);
      final g = await _trace(tester, _b[1], to: 0.55, lift: false);
      await tester.pump(const Duration(milliseconds: 100));
      await _capture(tester, 'trace_02_mid-stroke_$w');
      await g.up();
      await _finish(tester);
    });

    testWidgets('03 wrong-touch shake $w', (tester) async {
      await _pump(tester, screen: screen);
      await _trace(tester, _b[0]);
      await _trace(tester, _b[1], to: 0.2);
      // Dizayndakı ✕ yeri: viewBox (190, 236) → kətanın sağ-aşağısı.
      final canvas = find.byType(TracingCanvas);
      final size = tester.getSize(canvas);
      await tester.tapAt(
        tester.getTopLeft(canvas) +
            Offset(size.width * 0.857, size.height * 0.874),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 140));
      await _capture(tester, 'trace_03_wrong-touch-shake_$w');
      await _finish(tester);
    });

    testWidgets('03b wrong-touch reduced motion $w', (tester) async {
      AppSettings.instance.reduceMotion = true;
      addTearDown(() => AppSettings.instance.reduceMotion = false);
      await _pump(tester, screen: screen);
      await _trace(tester, _b[0]);
      await _trace(tester, _b[1], to: 0.2);
      final canvas = find.byType(TracingCanvas);
      final size = tester.getSize(canvas);
      await tester.tapAt(
        tester.getTopLeft(canvas) +
            Offset(size.width * 0.857, size.height * 0.874),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      await _capture(tester, 'trace_03b_wrong-touch-reduced_$w');
      await _finish(tester);
    });

    testWidgets('04 watch demo $w', (tester) async {
      await _pump(tester, screen: screen);
      await tester.tap(find.text('Bax'));
      await tester.pump();
      // Düymənin basışı (90 ms) bitsin və buraxılsın (140 ms) — sonra şəkil.
      // 3 ştrix x 900 ms; 2-ci ştrixin 60 %-i = 1.6 x 900 ms = 300 + 1140.
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 1140));
      await _capture(tester, 'trace_04_watch-demo_$w');
      await _finish(tester);
    });

    testWidgets('05 faded $w', (tester) async {
      await _pump(tester, screen: screen);
      await tester.tap(find.text('Təkrarla'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await _capture(tester, 'trace_05_repeat-faded-outline_$w');
      await _finish(tester);
    });

    testWidgets('06 done $w', (tester) async {
      await _pump(tester, screen: screen);
      await _traceAll(tester, _b);
      await _realFrames(tester, 14);
      await _capture(tester, 'trace_06_done-star-confetti_$w');
      await _finish(tester);
    });

    testWidgets('07 fallback $w', (tester) async {
      await _pump(tester, screen: screen, letter: 'W');
      await _capture(tester, 'trace_07_fallback-no-data_$w');
      await _finish(tester);
    });
  }
}
