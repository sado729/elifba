// Valideyn qapısının vizual yoxlaması (əl ilə, dizayn renderləri ilə yanaşı).
//
// `test/`-də DEYİL, ona görə adi `flutter test` onu işlətmir. Belə işlədin:
//
//   flutter test tool/gate_screens_test.dart
//
// Real tətbiqi (`MyApp`) qurur, ayarlar çarxı ilə qapını açır və dizaynın hər
// halını (gözləyir / 1.5 s basılıb / tamam) 360x640 və 412x915-də PNG kimi
// `GATE_SCREENS_OUT` qovluğuna (yoxdursa `build/gate_screens/`) yazır. Fayl
// adları `design/renders/gate_*.png` ilə eynidir. Əlavə olaraq dizaynda
// olmayan iki hal çəkilir: landşaft (sürüşmə ehtiyatı) və 1.3 şrift miqyası.
//
// Kitab səhifəsi `GatedPlayer` (deməli `AudioPlayer`) qurur. `tester.runAsync`
// içində əsl `just_audio` platforması `MissingPluginException` verərdi, ona
// görə saxta platforma quraşdırılır.

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:elifba/core/settings.dart';
import 'package:elifba/main.dart';
import 'package:elifba/widgets/parental_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

String get _outDir {
  final env = Platform.environment['GATE_SCREENS_OUT'];
  if (env != null && env.isNotEmpty) return env;
  return 'build/gate_screens';
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
  // Kitab səhifəsi (qapının altında) hələ köhnə şriftləri işlədir.
  final noto =
      FontLoader('NotoSans')
        ..addFont(_bytes('assets/fonts/NotoSans-Regular.ttf'))
        ..addFont(_bytes('assets/fonts/NotoSans-Bold.ttf'));
  final baloo =
      FontLoader('Baloo2')
        ..addFont(_bytes('assets/fonts/Baloo2-Regular.ttf'))
        ..addFont(_bytes('assets/fonts/Baloo2-Bold.ttf'))
        ..addFont(_bytes('assets/fonts/Baloo2-ExtraBold.ttf'));
  await Future.wait([comfortaa.load(), andika.load(), noto.load()]);
  await baloo.load();
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

/// Heç nə çalmayan `just_audio` platforması.
// `tool/` analizatorun gözündə "test" deyil; mixin yalnız testlər üçündür.
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
      LoadResponse(duration: const Duration(seconds: 1));

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

final _screenKey = GlobalKey();

enum _GateState { idle, holding, done }

/// Tətbiqi [size]-da qurur, qapını açır, [state]-ə gətirir və çəkir.
Future<void> _capture(
  WidgetTester tester,
  String name, {
  required Size size,
  required _GateState state,
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(
    RepaintBoundary(key: _screenKey, child: const MyApp()),
  );
  final context = tester.element(find.byType(Scaffold).first);
  await tester.runAsync(() async {
    await precacheImage(
      const AssetImage('assets/images/book_cover.webp'),
      context,
    );
  });
  await tester.pumpAndSettle();

  await tester.tap(find.byIcon(Icons.settings_outlined));
  await tester.pumpAndSettle();
  expect(find.text('Valideynlər üçün'), findsOneWidget);

  TestGesture? gesture;
  switch (state) {
    case _GateState.idle:
      break;
    case _GateState.holding:
      gesture = await tester.startGesture(
        tester.getCenter(find.byIcon(Icons.touch_app_outlined)),
      );
      await tester.pump();
      // Landşaftda məzmun sürüşür və `onTapDown` `kPressTimeout` (100 ms)
      // gecikir; ticker-in ilk kadrı başlanğıc sayılır, ona görə arada bir
      // kadr lazımdır, yoxsa 1.5 s-lik tək kadr halqanı 0-da göstərərdi.
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(
        kParentalGateHold ~/ 2 - const Duration(milliseconds: 150),
      );
    case _GateState.done:
      gesture = await tester.startGesture(
        tester.getCenter(find.byIcon(Icons.touch_app_outlined)),
      );
      await tester.pump();
      await tester.pump(kParentalGateHold + const Duration(milliseconds: 16));
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  }

  final boundary =
      tester.renderObject(find.byKey(_screenKey)) as RenderRepaintBoundary;
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

  await gesture?.up();
  await tester.pumpAndSettle();
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUpAll(() async {
    JustAudioPlatform.instance = _FakeJustAudio();
    await _loadFonts();
  });
  setUp(() {
    AppSettings.instance
      ..masterSound = true
      ..reduceMotion = false;
  });

  const small = Size(360, 640);
  const large = Size(412, 915);

  testWidgets('gate_01_idle_360', (tester) async {
    await _capture(
      tester,
      'gate_01_idle_360',
      size: small,
      state: _GateState.idle,
    );
  });

  testWidgets('gate_02_holding-1.5s_360', (tester) async {
    await _capture(
      tester,
      'gate_02_holding-1.5s_360',
      size: small,
      state: _GateState.holding,
    );
  });

  testWidgets('gate_03_done_360', (tester) async {
    await _capture(
      tester,
      'gate_03_done_360',
      size: small,
      state: _GateState.done,
    );
  });

  testWidgets('gate_04_holding_412', (tester) async {
    await _capture(
      tester,
      'gate_04_holding_412',
      size: large,
      state: _GateState.holding,
    );
  });

  testWidgets('gate_05_idle_412', (tester) async {
    await _capture(
      tester,
      'gate_05_idle_412',
      size: large,
      state: _GateState.idle,
    );
  });

  testWidgets('gate_06_done_412', (tester) async {
    await _capture(
      tester,
      'gate_06_done_412',
      size: large,
      state: _GateState.done,
    );
  });

  testWidgets('gate_x1_landscape_640x360 (dizaynda yoxdur)', (tester) async {
    await _capture(
      tester,
      'gate_x1_landscape_640x360',
      size: const Size(640, 360),
      state: _GateState.holding,
    );
  });

  testWidgets('gate_x2_text-1.3_360 (dizaynda yoxdur)', (tester) async {
    await _capture(
      tester,
      'gate_x2_text-1.3_360',
      size: small,
      state: _GateState.holding,
      textScale: 1.3,
    );
  });
}
