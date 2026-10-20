// Hərf səhifəsinin (AnimalListPage) vizual yoxlaması — əl ilə müqayisə üçün.
//
// `test/`-də DEYİL, ona görə adi `flutter test` onu işlətmir. Belə işlədin:
//
//   flutter test tool/letter_screens_test.dart
//
// Hər dizayn vəziyyətini (ScreenLetter renders) 360x640 və 412x915-də qurur
// və PNG kimi `SCREENS_OUT` qovluğuna (yoxdursa `build/letter_screens/`)
// yazır. Real şriftlər (Comfortaa, Andika, MaterialIcons) yüklənir.
//
// Səhifə `GatedPlayer` → `AudioPlayer` qurur. `tester.runAsync` (şəkillərin
// dekodu və PNG) real event loop-u işə saldığı üçün `just_audio` platforması
// saxta ilə əvəz olunur — əks halda `MissingPluginException` testi yıxardı.
// Heyvan şəkilləri səhifədəki eyni `ResizeImage` eni ilə qabaqcadan yüklənir
// (gotcha 8), ona görə `Image.asset` onları sinxron tapır.
//
// `tool/` analizatorun gözündə "test" qovluğu deyil, ona görə saxta
// platformaların `MockPlatformInterfaceMixin`-i burada xəbərdarlıq verir.
// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:elifba/core/config.dart';
import 'package:elifba/core/progress.dart';
import 'package:elifba/core/settings.dart';
import 'package:elifba/pages/animal_list_page.dart';
import 'package:elifba/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

String get _outDir {
  final env = Platform.environment['SCREENS_OUT'];
  if (env != null && env.isNotEmpty) return env;
  return 'build/letter_screens';
}

// ------------------------------------------------------------ saxta audio

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

/// Heç nə çalmır və heç vaxt `completed` vermir: "oxuyur" vəziyyəti qalır.
class _FakePlayer extends AudioPlayerPlatform {
  _FakePlayer(super.id);

  final _events = StreamController<PlaybackEventMessage>.broadcast();

  @override
  Stream<PlaybackEventMessage> get playbackEventMessageStream => _events.stream;

  @override
  Stream<PlayerDataMessage> get playerDataMessageStream =>
      const Stream<PlayerDataMessage>.empty();

  @override
  Future<LoadResponse> load(LoadRequest request) async =>
      LoadResponse(duration: const Duration(seconds: 5));

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

  @override
  Future<ConcatenatingInsertAllResponse> concatenatingInsertAll(
    ConcatenatingInsertAllRequest request,
  ) async => ConcatenatingInsertAllResponse();

  @override
  Future<ConcatenatingRemoveRangeResponse> concatenatingRemoveRange(
    ConcatenatingRemoveRangeRequest request,
  ) async => ConcatenatingRemoveRangeResponse();

  @override
  Future<ConcatenatingMoveResponse> concatenatingMove(
    ConcatenatingMoveRequest request,
  ) async => ConcatenatingMoveResponse();
}

/// `just_audio` aktivləri müvəqqəti qovluğa köçürür; qovluq build/-dadır.
class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<String?> getTemporaryPath() async =>
      Directory('build/letter_screens_tmp').absolute.path;
}

// ---------------------------------------------------------------- şriftlər

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

// ---------------------------------------------------------------- progres

final _store = ProgressStore.instance;

/// Heyvana [stars] ulduz verən minimum bölmələri qeyd edir.
void _giveStars(String animal, int stars) {
  final tasks = _store.tasksOf(animal);
  if (stars <= 0 || tasks.isEmpty) return;
  void doTask(Activity a) {
    if (a == Activity.foods) {
      for (final f in AppConfig.animalFoods[animal] ?? const <String>[]) {
        _store.markFoodFed(animal, f);
      }
    } else {
      _store.markDone(animal, a);
    }
  }

  final need =
      stars >= 3
          ? tasks.length
          : stars == 2
          ? (tasks.length * 2 / 3).ceil()
          : 1;
  for (final a in tasks.take(need)) {
    doTask(a);
  }
}

void _completeLetter(String letter, {bool written = true}) {
  for (final a in AppConfig.animalsByLetter[letter] ?? const <String>[]) {
    _giveStars(a, 3);
  }
  if (written) _store.markWritten(letter);
}

/// ScreenLetter-dəki B: ilk heyvan tam, sonrakılar qismən, hərf yazılıb.
void _progressB() {
  final b = AppConfig.animalsByLetter['B']!;
  _giveStars(b[0], 3);
  _giveStars(b[1], 2);
  _giveStars(b[2], 1);
  _giveStars(b[3], 1);
  _store.markWritten('B');
}

/// ScreenLetter-dəki Q: 1-ci və 5-ci tam, 2-ci və 3-cü bir ulduz.
void _progressQ() {
  final q = AppConfig.animalsByLetter['Q']!;
  _giveStars(q[0], 3);
  _giveStars(q[1], 1);
  _giveStars(q[2], 1);
  _giveStars(q[4], 3);
}

// ----------------------------------------------------------------- çəkiliş

final _shotKey = GlobalKey();

Future<void> _pumpPage(
  WidgetTester tester,
  String letter, {
  required Size size,
  double textScale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  // Maketlərdəki 24 dp status bar və 24 dp jest zolağı.
  tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
  tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ElifbaTheme.light(),
      builder:
          (context, child) => RepaintBoundary(
            key: _shotKey,
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.3,
              child: child!,
            ),
          ),
      home: AnimalListPage(letter: letter),
    ),
  );

  final context = tester.element(find.byType(AnimalListPage));
  await tester.runAsync(() async {
    for (final a in AppConfig.findLetter(letter)?.animals ?? const []) {
      await precacheImage(
        ResizeImage(AssetImage(a.imagePath), width: kAnimalThumbDecodeWidth),
        context,
      );
    }
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _capture(WidgetTester tester, String name) async {
  final boundary =
      tester.renderObject(find.byKey(_shotKey)) as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final ui.Image image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final dir = Directory(_outDir)..createSync(recursive: true);
    File(
      '${dir.path}${Platform.pathSeparator}$name.png',
    ).writeAsBytesSync(data!.buffer.asUint8List());
  });
  expect(tester.takeException(), isNull, reason: name);
}

/// Səhifəni ağacdan çıxarır ki, pleyerlər dispose olunsun.
Future<void> _done(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 3));
}

Finder get _scrollable => find.descendant(
  of: find.byKey(const ValueKey('letterPageScroll')),
  matching: find.byType(Scrollable),
);

Future<void> _openInfo(WidgetTester tester, String letter) async {
  await tester.tap(find.text('$letter hərfi haqqında oxu'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _playNarration(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Səsləndir'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Real axın: hər şey bitib, yalnız yazı qalıb → yazı oyununa gir, hərfi yaz,
/// qayıt → təbrik route-u.
Future<void> _celebrate(WidgetTester tester, String letter) async {
  await tester.tap(find.bySemanticsLabel('$letter hərfini yaz'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  _store.markWritten(letter);
  tester.state<NavigatorState>(find.byType(Navigator)).pop();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
  // Təbrikin girişi (800 ms) bitsin.
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

const _small = Size(360, 640);
const _large = Size(412, 915);

void main() {
  setUpAll(() async {
    JustAudioPlatform.instance = _FakeJustAudio();
    PathProviderPlatform.instance = _FakePathProvider();
    // `just_audio` yükləmədə `AudioSession.instance`-ı gözləyir; kanal cavab
    // verməsə saxta zamanda `setAsset`/`stop` heç vaxt bitmir.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.ryanheise.audio_session'),
          (call) async => null,
        );
    await _loadFonts();
  });

  setUp(() {
    AppSettings.instance
      ..masterSound = true
      ..narrationSound = true
      ..reduceMotion = false;
  });

  tearDown(() async {
    await _store.reset();
  });

  testWidgets('01 Q · 11 heyvan · sürüşdürülüb · 360', (tester) async {
    _progressQ();
    await _pumpPage(tester, 'Q', size: _small);
    tester.state<ScrollableState>(_scrollable).position.jumpTo(330);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await _capture(tester, 'letter_01_q-scrolled_360');
    await _done(tester);
  });

  testWidgets('02 E · 1 heyvan · 360', (tester) async {
    await _pumpPage(tester, 'E', size: _small);
    await _capture(tester, 'letter_02_e-1-animal_360');
    await _done(tester);
  });

  testWidgets('03 Ğ · heyvan yoxdur · 360', (tester) async {
    await _pumpPage(tester, 'Ğ', size: _small);
    await _capture(tester, 'letter_03_g-breve_360');
    await _done(tester);
  });

  testWidgets('04 B · məlumat açıq · 360', (tester) async {
    _progressB();
    await _pumpPage(tester, 'B', size: _small);
    await _openInfo(tester, 'B');
    await _capture(tester, 'letter_04_b-info-open_360');
    await _done(tester);
  });

  testWidgets('05 A · tamam · 360', (tester) async {
    _completeLetter('A');
    await _pumpPage(tester, 'A', size: _small);
    await _capture(tester, 'letter_05_a-complete_360');
    await _done(tester);
  });

  testWidgets('06 A · təbrik · 360', (tester) async {
    _completeLetter('A', written: false);
    await _pumpPage(tester, 'A', size: _small);
    await _celebrate(tester, 'A');
    await _capture(tester, 'letter_06_a-celebrate_360');
    await _done(tester);
  });

  testWidgets('06r A · təbrik · azaldılmış hərəkət · 360', (tester) async {
    AppSettings.instance.reduceMotion = true;
    _completeLetter('A', written: false);
    await _pumpPage(tester, 'A', size: _small);
    await _celebrate(tester, 'A');
    await _capture(tester, 'letter_06r_a-celebrate-reduced_360');
    await _done(tester);
  });

  testWidgets('07 B · nəqletmə oxuyur · 360', (tester) async {
    // Azaldılmış hərəkətdə halqa sabit 5 dp-dir — maketin özü.
    AppSettings.instance.reduceMotion = true;
    _progressB();
    await _pumpPage(tester, 'B', size: _small);
    await _playNarration(tester);
    expect(find.byTooltip('Dayandır'), findsOneWidget);
    await _capture(tester, 'letter_07_b-playing_360');
    await _done(tester);
  });

  testWidgets('07p B · oxuyur, nəbz · 360', (tester) async {
    _progressB();
    await _pumpPage(tester, 'B', size: _small);
    await _playNarration(tester);
    // Nəbz 0 → 6 dp (600 ms); ~420 ms-də ≈ 5 dp.
    await tester.pump(const Duration(milliseconds: 120));
    await _capture(tester, 'letter_07p_b-playing-pulse_360');
    // Stop: nəbz dayanır. `stop()` real I/O-nu gözləyə bilər — qısa real
    // fasilə verilir.
    await tester.tap(find.byTooltip('Dayandır'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byTooltip('Səsləndir'), findsOneWidget);
    await _done(tester);
  });

  testWidgets('08 B · nəqletmə söndürülüb · 360', (tester) async {
    AppSettings.instance.narrationSound = false;
    _progressB();
    await _pumpPage(tester, 'B', size: _small);
    // Söndürülmüş düyməyə toxunmaq kartı açmır.
    await tester.tap(find.byTooltip('Səs söndürülüb'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('B hərfi haqqında oxu'), findsOneWidget);
    await _capture(tester, 'letter_08_b-muted_360');
    await _done(tester);
  });

  testWidgets('09 Q · 412', (tester) async {
    _progressQ();
    await _pumpPage(tester, 'Q', size: _large);
    await _capture(tester, 'letter_09_q_412');
    await _done(tester);
  });

  testWidgets('10 B · açıq + oxuyur · 412', (tester) async {
    AppSettings.instance.reduceMotion = true;
    _progressB();
    await _pumpPage(tester, 'B', size: _large);
    await _openInfo(tester, 'B');
    await _playNarration(tester);
    await _capture(tester, 'letter_10_b-info-open-playing_412');
    await _done(tester);
  });

  testWidgets('11 Ğ · 412', (tester) async {
    await _pumpPage(tester, 'Ğ', size: _large);
    await _capture(tester, 'letter_11_g-breve_412');
    await _done(tester);
  });

  testWidgets('12 A · təbrik · 412', (tester) async {
    _completeLetter('A', written: false);
    await _pumpPage(tester, 'A', size: _large);
    await _celebrate(tester, 'A');
    await _capture(tester, 'letter_12_a-celebrate_412');
    await _done(tester);
  });

  // ---------------------------------------------- əlavə: daşma yoxlamaları

  testWidgets('13 B · açıq · mətn 1.3x · 360', (tester) async {
    _progressB();
    await _pumpPage(tester, 'B', size: _small, textScale: 1.3);
    await _openInfo(tester, 'B');
    await _capture(tester, 'letter_13_b-open-textscale_360');
    tester.state<ScrollableState>(_scrollable).position.jumpTo(600);
    await tester.pump();
    await _capture(tester, 'letter_13b_b-open-textscale-scrolled_360');
    await _done(tester);
  });

  testWidgets('14 Ğ · mətn 1.3x · 360', (tester) async {
    await _pumpPage(tester, 'Ğ', size: _small, textScale: 1.3);
    await _capture(tester, 'letter_14_g-breve-textscale_360');
    await _done(tester);
  });

  testWidgets('15 A · test səthi 800x600', (tester) async {
    _progressB();
    await _pumpPage(tester, 'A', size: const Size(800, 600));
    await _capture(tester, 'letter_15_a_800x600');
    await _done(tester);
  });

  testWidgets('16 Z · son hərf, növbəti söndürülüb · 360', (tester) async {
    await _pumpPage(tester, 'Z', size: _small);
    final next = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.chevron_right_rounded),
        matching: find.byType(IconButton),
      ),
    );
    expect(next.onPressed, isNull);
    await _capture(tester, 'letter_16_z_360');
    await _done(tester);
  });
}
