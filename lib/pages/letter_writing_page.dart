import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/config.dart';
import '../core/letter_strokes.dart';
import '../core/progress.dart';
import '../core/settings.dart';
import '../core/sound.dart';
import '../core/stroke_tracker.dart';
import '../theme/theme.dart';
import '../widgets/elifba_card.dart';
import '../widgets/elifba_confetti.dart';
import '../widgets/game_feedback.dart';
import '../widgets/icon_buttons.dart';
import '../widgets/pill_button.dart';
import '../widgets/pill_tab.dart';
import '../widgets/sky_background.dart';
import '../widgets/star_row.dart';
import '../widgets/tracing_canvas.dart';

/// Kartın silkələnməsini (`Transform.translate`) testlərin tapması üçün.
@visibleForTesting
const ValueKey<String> kTraceCardShakeKey = ValueKey<String>('traceCardShake');

/// Pəncərə bundan alçaq və enindən qısa olanda (telefon yan tutulanda)
/// rejimlər sola, sayğac və «Yenidən» sağa keçir — kart bütün hündürlüyü
/// alır. Portret düzülüşündə 640x360-da kətan cəmi 86 dp qalardı (miqyas
/// 0.83). 800x600 test səthi portret düzülüşündə qalır.
const double _kLandscapeMaxHeight = 520;

/// Yan düzülüşdə rejim və alt panel sütunlarının eni (16 dp kənar daxil).
const double _kSideColumnWidth = 184;

/// Rejim düymələri, `TracingMode.values` sırası ilə (Bax · İzlə · Təkrarla).
const Map<TracingMode, ({String label, IconData icon})> _kModes = {
  TracingMode.watch: (label: 'Bax', icon: Icons.visibility_rounded),
  TracingMode.guided: (label: 'İzlə', icon: Icons.touch_app_rounded),
  TracingMode.faded: (label: 'Təkrarla', icon: Icons.edit_rounded),
};

/// Barmaqla hərf yazma oyunu.
///
/// Səhifə əsl hərfi (`Ə`, `Ş` kimi) `letter` parametri ilə alır — diakritikanı
/// normalizasiyadan yenidən çıxarmağa cəhd etmir. Bu, `animal_detail_page`-dəki
/// tələnin təkrarlanmasının qarşısını alır.
///
/// Yazılmış hərflər [ProgressStore]-da saxlanılır — səhifənin öz yaddaş açarı
/// yoxdur, cızma tapşırığı hərfin ulduzlarına daxildir.
class LetterWritingPage extends StatefulWidget {
  const LetterWritingPage({super.key, required this.letter, this.store});

  final String letter;

  /// Progres store-u. Defolt qlobal [ProgressStore.instance]-dır; widget
  /// testləri buraya `ProgressStore.forTesting()` verib singleton-un vəziyyət
  /// sızdırmasının qarşısını alır.
  final ProgressStore? store;

  @override
  State<LetterWritingPage> createState() => _LetterWritingPageState();
}

class _LetterWritingPageState extends State<LetterWritingPage>
    with TickerProviderStateMixin {
  // Pleyerlər sahə elanında qurulur — `_initAudio()` yalnız `setAsset` edir.
  // Bu qayda pozulsa erkən toxunuşda LateInitializationError yaranır.
  final GatedPlayer _clickPlayer = GatedPlayer(SoundChannel.effect);
  final GatedPlayer _winPlayer = GatedPlayer(SoundChannel.effect);

  late final ConfettiController _confetti;

  /// Səhv toxunuşda bütün kartın sağa-sola "yox" silkələnməsi (280 ms).
  late final AnimationController _shake;

  /// Hərf bitəndə başlıqdakı ulduzun "pop"u: 1 → 1.12 → 1 (240 ms).
  late final AnimationController _starPop;
  late final Animation<double> _starScale;

  late String _letter;
  TracingMode _mode = TracingMode.guided;

  /// "Yenidən" düyməsi bunu artırır; kətanın açarı dəyişir və vəziyyət sıfırlanır.
  int _resetToken = 0;

  /// Ekran dönəndə kart portret sütunundan yan sıraya köçür; bu açar onu
  /// yerindən qoparmadan daşıyır ki, yarımçıq cızıq itməsin.
  final GlobalKey _cardKey = GlobalKey(debugLabel: 'traceCard');

  ProgressStore get _store => widget.store ?? ProgressStore.instance;

  @override
  void initState() {
    super.initState();
    _letter = widget.letter;
    _confetti = ConfettiPreset.small.createController();
    _shake = AnimationController(vsync: this, duration: ElifbaMotion.wrongShake);
    _starPop = AnimationController(vsync: this, duration: ElifbaMotion.starPop);
    _starScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: ElifbaMotion.correctPopScale,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: ElifbaMotion.correctPopScale,
          end: 1,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 50,
      ),
    ]).animate(_starPop);
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      await _clickPlayer.setAsset('assets/audios/click.mp3');
      await _winPlayer.setAsset('assets/audios/win.mp3');
    } catch (e) {
      debugPrint('Səs yüklənmə xətası: $e');
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    _shake.dispose();
    _starPop.dispose();
    _clickPlayer.dispose();
    _winPlayer.dispose();
    super.dispose();
  }

  Future<void> _play(GatedPlayer player) => player.replay();

  void _onTraceEvent(TraceResult r) {
    // Səhv toxunuş: kart silkələnir. Azaldılmış hərəkətdə silkələnmə yoxdur —
    // kətanın ✕ nişanı onsuz da görünür.
    if (r.rejected &&
        !AppSettings.instance.reduceMotion &&
        !_shake.isAnimating) {
      _shake.forward(from: 0);
    }
    if (r.letterCompleted) {
      // "Bax" rejimində nümayiş bitəndə uşağa növbəni ver.
      if (_mode == TracingMode.watch) {
        setState(() {
          _mode = TracingMode.guided;
          _resetToken++;
        });
        return;
      }
      _play(_winPlayer);
      if (!AppSettings.instance.reduceMotion) {
        _confetti.play();
        _starPop.forward(from: 0);
      }
      // Store `notifyListeners()` çağırır — ulduz və sayğac AnimatedBuilder ilə
      // özü yenilənir, `setState` lazım deyil.
      _store.markWritten(_letter);
    } else if (r.unitCompleted) {
      _play(_clickPlayer);
    }
  }

  void _setMode(TracingMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _resetToken++;
    });
  }

  void _restart() => setState(() => _resetToken++);

  void _goToLetter(int step) {
    const alphabet = AppConfig.alphabet;
    final i = alphabet.indexOf(_letter);
    if (i < 0) return;
    final next = (i + step + alphabet.length) % alphabet.length;
    setState(() {
      _letter = alphabet[next];
      _mode = TracingMode.guided;
      _resetToken++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final units = LetterStrokes.unitsFor(_letter);
    final card = _buildCard(units);
    final screen = MediaQuery.sizeOf(context);
    final landscape =
        screen.width > screen.height && screen.height < _kLandscapeMaxHeight;

    // Android 16 (API 36) edge-to-edge rejimində sistem panelləri body-nin
    // üstünə düşür. Səma fonu SafeArea-dan KƏNARDA qalır ki, panellərin
    // arxasını da boyasın.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: kElifbaSystemUiStyle,
      child: Scaffold(
        body: SkyBackground(
          child: SizedBox.expand(
            child: SafeArea(
              // [ProgressStore] `ChangeNotifier`-dir: hərf yazılan kimi
              // başlıqdakı ulduz və aşağıdakı sayğac özü yenilənsin deyə ona
              // qoşuluruq. Kart (və kətan) store-dan asılı deyil — `child`
              // kimi ötürülür ki, qeyd dəyişəndə yenidən qurulmasın.
              child: AnimatedBuilder(
                animation: _store,
                child: card,
                builder: (context, child) => landscape
                    ? _buildLandscape(units, child!)
                    : Column(
                        children: [
                          _buildHeader(),
                          if (units != null) _buildModeBar(),
                          Expanded(child: child!),
                          _buildFooter(),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Yan düzülüş (dizaynda kadrı yoxdur): başlıq yuxarıda, altında
  /// rejimlər · kart · sayğac və «Yenidən». Portretdəki eyni widget-lər.
  Widget _buildLandscape(List<TraceUnit>? units, Widget card) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Kart ortada qalsın deyə sol sütun datası olmayan hərfdə də
              // yerini tutur.
              SizedBox(
                width: _kSideColumnWidth,
                child: units == null ? null : _buildModeColumn(),
              ),
              // Kartın 8 dp kənarı alt boşluğa düşür.
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: card,
                ),
              ),
              SizedBox(width: _kSideColumnWidth, child: _buildSideFooter()),
            ],
          ),
        ),
      ],
    );
  }

  /// Üst panel, 64 dp: geri · ‹ · «B hərfini yaz» · › · ulduz.
  Widget _buildHeader() {
    final isWritten = _store.isWritten(_letter);
    return SizedBox(
      height: ElifbaSize.toolbar,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            ToolbarBackButton(onPressed: () => Navigator.of(context).pop()),
            const SizedBox(width: 2),
            ToolbarChevron(
              forward: false,
              tooltip: 'Əvvəlki hərf',
              onPressed: () => _goToLetter(-1),
            ),
            const SizedBox(width: 2),
            Expanded(
              // TalkBack səhifə açılanda başlığı ekranın adı kimi oxusun
              // (`AppBar` kimi; iOS-da `namesRoute` verilmir).
              child: Semantics(
                container: true,
                header: true,
                namesRoute: switch (Theme.of(context).platform) {
                  TargetPlatform.iOS || TargetPlatform.macOS => null,
                  _ => true,
                },
                child: Text(
                  '$_letter hərfini yaz',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ElifbaTextStyles.traceTitle.copyWith(
                    color: ElifbaPalette.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 2),
            ToolbarChevron(
              forward: true,
              tooltip: 'Növbəti hərf',
              onPressed: () => _goToLetter(1),
            ),
            const SizedBox(width: 2),
            SizedBox.square(
              dimension: ElifbaSize.touchMin,
              child: Center(
                child: ScaleTransition(
                  scale: _starScale,
                  // Boş → dolu yalnız 200 ms fade ilə keçir (azaldılmış
                  // hərəkətdə də); "pop" isə yalnız hərf bitəndə.
                  child: AnimatedSwitcher(
                    duration: ElifbaMotion.starFillFade,
                    child: StarRow(
                      key: ValueKey<bool>(isWritten),
                      filled: isWritten ? 1 : 0,
                      total: 1,
                      size: 34,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modePill(TracingMode mode) {
    final m = _kModes[mode]!;
    return PillTab(
      label: m.label,
      icon: m.icon,
      selected: _mode == mode,
      expand: true,
      unselectedIconColor: ElifbaPalette.onSurfaceVariant,
      onTap: () => _setMode(mode),
    );
  }

  /// Üç rejim düyməsi — kətanın ÜSTÜNDƏ, hər biri ekranın üçdə biri.
  Widget _buildModeBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          for (final mode in _kModes.keys) ...[
            if (mode != _kModes.keys.first) const SizedBox(width: 8),
            Expanded(child: _modePill(mode)),
          ],
        ],
      ),
    );
  }

  /// Yan düzülüşdə rejimlər kartın solunda, üst-üstə.
  Widget _buildModeColumn() {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Column(
        children: [
          for (final mode in _kModes.keys) ...[
            if (mode != _kModes.keys.first) const SizedBox(height: 10),
            _modePill(mode),
          ],
        ],
      ),
    );
  }

  /// Yazı lövhəsi: kart (radius 28, kənar 6), içində 12 dp boşluqla kətan,
  /// üstündə kartın içinə kəsilmiş konfeti. Səhv toxunuşda kart bütövlükdə
  /// silkələnir.
  Widget _buildCard(List<TraceUnit>? units) {
    // Kətan kartın içində 12 dp boşluqla durur; ehtiyat mətni isə kartın
    // bütün enini işlədir (öz 24 dp boşluğu var).
    final content = units == null
        ? _buildMissing()
        : Padding(
            padding: const EdgeInsets.all(12),
            child: TracingCanvas(
              key: ValueKey('$_letter-${_mode.name}-$_resetToken'),
              units: units,
              mode: _mode,
              onEvent: _onTraceEvent,
            ),
          );

    return Padding(
      key: _cardKey,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedBuilder(
        animation: _shake,
        child: ElifbaCard(
          clip: true,
          child: Stack(
            fit: StackFit.expand,
            children: [
              content,
              IgnorePointer(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ElifbaConfetti(controller: _confetti),
                ),
              ),
            ],
          ),
        ),
        builder: (context, child) => Transform.translate(
          key: kTraceCardShakeKey,
          offset: Offset(
            dampedShakeOffset(_shake.value, ElifbaMotion.traceShakeAmplitude),
            0,
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildMissing() {
    // Ortada durur; yan düzülüşdə böyük mətnlə kart alçaq qalanda isə
    // daşmaq əvəzinə sürüşür.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.edit_off_rounded,
                    color: ElifbaPalette.onMuted,
                    size: 44,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '"$_letter" hərfi üçün yazı datası hələ hazır deyil.',
                    textAlign: TextAlign.center,
                    // Andika 16/23 — təbrik mətni ilə eyni üslub.
                    style: ElifbaTextStyles.celebrationBody.copyWith(
                      color: ElifbaPalette.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Alt panel, 80 dp: sayğac və «Yenidən».
  Widget _buildFooter() {
    // Alt inset-i səhifənin `SafeArea`-sı verir; burada təkrar əlavə
    // etmirik. Kartın 8 dp kənarı panelin yuxarı boşluğuna düşür.
    return SizedBox(
      height: 80,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: _buildCounter()),
            const SizedBox(width: 12),
            _buildRestart(),
          ],
        ),
      ),
    );
  }

  /// Yan düzülüşdə sayğac və «Yenidən» kartın sağında, aşağıda. Düymənin
  /// üzü kartın üzü ilə eyni xəttdə bitir.
  Widget _buildSideFooter() {
    return Padding(
      padding: const EdgeInsets.only(right: 16, bottom: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildCounter(textAlign: TextAlign.end),
          const SizedBox(height: 12),
          _buildRestart(),
        ],
      ),
    );
  }

  Widget _buildCounter({TextAlign? textAlign}) {
    return Text(
      '${_store.writtenLetterCount} / ${AppConfig.alphabet.length} '
      'hərf yazıldı',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
      style: ElifbaTextStyles.counter.copyWith(
        color: ElifbaPalette.onSurfaceVariant,
      ),
    );
  }

  Widget _buildRestart() {
    return PillButton(
      label: 'Yenidən',
      icon: Icons.refresh_rounded,
      onPressed: _restart,
    );
  }
}
