import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../core/config.dart';
import '../core/letter_strokes.dart';
import '../core/progress.dart';
import '../core/settings.dart';
import '../core/sound.dart';
import '../core/stroke_tracker.dart';
import '../widgets/tracing_canvas.dart';

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

class _LetterWritingPageState extends State<LetterWritingPage> {
  // Pleyerlər sahə elanında qurulur — `_initAudio()` yalnız `setAsset` edir.
  // Bu qayda pozulsa erkən toxunuşda LateInitializationError yaranır.
  final GatedPlayer _clickPlayer = GatedPlayer(SoundChannel.effect);
  final GatedPlayer _winPlayer = GatedPlayer(SoundChannel.effect);

  late final ConfettiController _confetti;

  late String _letter;
  TracingMode _mode = TracingMode.guided;

  /// "Yenidən" düyməsi bunu artırır; kətanın açarı dəyişir və vəziyyət sıfırlanır.
  int _resetToken = 0;

  ProgressStore get _store => widget.store ?? ProgressStore.instance;

  @override
  void initState() {
    super.initState();
    _letter = widget.letter;
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
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
    _clickPlayer.dispose();
    _winPlayer.dispose();
    super.dispose();
  }

  Future<void> _play(GatedPlayer player) => player.replay();

  void _onTraceEvent(TraceResult r) {
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
    // Android 16 (API 36) edge-to-edge rejimində sistem panelləri body-nin
    // üstünə düşür. Qradiyent SafeArea-dan KƏNARDA qalır ki, panellərin
    // arxasını da boyasın.
    final units = LetterStrokes.unitsFor(_letter);
    final canvas = units == null
        ? _buildMissing()
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Center(
              child: AspectRatio(
                aspectRatio: kGlyphBox.width / kGlyphBox.height,
                child: TracingCanvas(
                  key: ValueKey('$_letter-${_mode.name}-$_resetToken'),
                  units: units,
                  mode: _mode,
                  onEvent: _onTraceEvent,
                ),
              ),
            ),
          );

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2E2B5F), Color(0xFF1B1A3A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              // [ProgressStore] `ChangeNotifier`-dir: hərf yazılan kimi
              // başlıqdakı ulduz və aşağıdakı sayğac özü yenilənsin deyə ona
              // qoşuluruq. Kətan store-dan asılı deyil — `child` kimi ötürülür
              // ki, qeyd dəyişəndə yenidən qurulmasın.
              child: AnimatedBuilder(
                animation: _store,
                child: canvas,
                builder: (context, child) => Column(
                  children: [
                    _buildHeader(),
                    Expanded(child: child!),
                    if (units != null) _buildModeBar(),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                numberOfParticles: 22,
                gravity: 0.28,
                emissionFrequency: 0.06,
                colors: const [
                  Color(0xFFFFD54F),
                  Color(0xFF66BB6A),
                  Color(0xFF64B5F6),
                  Color(0xFFF06292),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isWritten = _store.isWritten(_letter);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            tooltip: 'Geri',
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white70),
                  tooltip: 'Əvvəlki hərf',
                  onPressed: () => _goToLetter(-1),
                ),
                Text(
                  '$_letter hərfini yaz',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white70),
                  tooltip: 'Növbəti hərf',
                  onPressed: () => _goToLetter(1),
                ),
              ],
            ),
          ),
          Icon(
            isWritten ? Icons.star_rounded : Icons.star_outline_rounded,
            color: isWritten ? const Color(0xFFFFD54F) : Colors.white38,
            size: 30,
          ),
        ],
      ),
    );
  }

  Widget _buildMissing() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_off, color: Colors.white38, size: 56),
            const SizedBox(height: 16),
            Text(
              '"$_letter" hərfi üçün yazı datası hələ hazır deyil.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeBar() {
    const modes = <TracingMode, ({String label, IconData icon})>{
      TracingMode.watch: (label: 'Bax', icon: Icons.play_arrow_rounded),
      TracingMode.guided: (label: 'İzlə', icon: Icons.touch_app_rounded),
      TracingMode.faded: (label: 'Təkrarla', icon: Icons.gesture_rounded),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final entry in modes.entries)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _ModePill(
                label: entry.value.label,
                icon: entry.value.icon,
                selected: _mode == entry.key,
                onTap: () => _setMode(entry.key),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    // Alt inset-i səhifənin `SafeArea`-sı verir; burada təkrar əlavə
    // etmirik — yalnız sabit alt boşluq saxlayırıq.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Text(
            '${_store.writtenLetterCount} / ${AppConfig.alphabet.length} '
            'hərf yazıldı',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _restart,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text('Yenidən'),
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? Colors.deepPurple.shade400
          : Colors.white.withAlpha((0.08 * 255).toInt()),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : Colors.white70,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white70,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
