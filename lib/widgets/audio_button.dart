import 'package:flutter/material.dart';

import '../core/settings.dart';
import '../theme/theme.dart';
import 'squishy.dart';

/// Səs düyməsinin üç vəziyyəti (DS "Səs düyməsi · 3 vəziyyət").
enum AudioButtonState { ready, playing, muted }

/// Səhifənin öz bayraqlarından vəziyyət. **Söndürülmüş oxumağı üstələyir** —
/// bu günkü sıra: `muted ? … : isPlaying ? … : …`.
AudioButtonState audioStateOf({required bool muted, required bool playing}) =>
    muted
        ? AudioButtonState.muted
        : (playing ? AudioButtonState.playing : AudioButtonState.ready);

/// Düymənin rəngi: nəqletmə (bənövşəyi) və ya heyvanın öz səsi (çəhrayı).
enum AudioTone { narration, animal }

/// "Oxuyur" nəbzi: halqa 0 ↔ 6 dp, 600 ms hər tərəfə, easeInOut.
///
/// Controller YALNIZ `playing` + azaldılmamış hərəkətdə işləyir; vəziyyətdən
/// çıxanda dayandırılıb sıfırlanır — hazır/söndürülmüş ekranda heç bir ticker
/// qalmır, `pumpAndSettle` bitir. Azaldılmış hərəkətdə halqa sabitdir.
mixin _PulseRing<T extends StatefulWidget> on State<T>, TickerProvider {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: ElifbaMotion.audioPulseHalf,
  );
  late final CurvedAnimation _pulseCurve = CurvedAnimation(
    parent: _pulse,
    curve: ElifbaMotion.audioPulseCurve,
  );

  bool get _playing;
  bool? get _reduceOverride;
  bool get _reduced => ElifbaMotion.isReduced(_reduceOverride);

  @override
  void initState() {
    super.initState();
    // Valideyn "Hərəkəti azalt"-ı oxuma vaxtı dəyişə bilər.
    AppSettings.instance.addListener(_syncPulse);
    _syncPulse();
  }

  @override
  void dispose() {
    AppSettings.instance.removeListener(_syncPulse);
    _pulseCurve.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _syncPulse() {
    if (_playing && !_reduced) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else if (_pulse.isAnimating || _pulse.value != 0) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  /// Halqanın indiki qalınlığı.
  double _ring(double reducedRing) {
    if (!_playing) return 0;
    if (_reduced) return reducedRing;
    return ElifbaMotion.audioRingMax * _pulseCurve.value;
  }
}

/// Dairəvi səs düyməsi: nəqletmə (56 dp; hərf məlumat kartında 48) və ya
/// heyvanın səsi (48, üst paneldə adın yanında).
///
/// **Yalnız görünüşdür.** `GatedPlayer`, "oxuyur" bayrağı və `onCompleted`
/// dinləyicisi səhifədə qalır (CLAUDE.md gotcha 5, 6, 15). Səhifə
/// `AnimatedBuilder(animation: AppSettings.instance)` ilə yenidən qurur və
/// vəziyyəti [audioStateOf] ilə verir. `muted` vəziyyətində widget
/// [onPressed]-i özü null edir: düymə boz, `volume_off`, basılmır,
/// `Semantics(enabled: false)`; tooltip yenə uzun basanda səbəbi deyir.
///
/// | vəziyyət | üz      | halqa / kənar                      | ikon (56 / 48)          | tooltip          |
/// |----------|---------|------------------------------------|-------------------------|------------------|
/// | ready    | #7C63D9 | — / #5C45B5 (5 / 4)                | play_arrow 32 / 30      | «Səsləndir»      |
/// | playing  | #7C63D9 | #E4DEFF nəbz 0↔6 / #C6B8F5         | stop 28 / 26            | «Dayandır»       |
/// | muted    | #ECE8F6 | — / —                              | volume_off 26 / 24      | «Səs söndürülüb» |
///
/// Heyvan səsinin dayandır vəziyyəti yoxdur (bu günkü kimi hər toxunuş
/// çalır): `playing` hazır kimi görünür. Hazır: #FFE0EC üz, 4 #F5B3CE kənar,
/// `pets_rounded` 24 #B03A6E, «Heyvanın səsi»; söndürülüb: «Heyvan səsləri
/// söndürülüb».
class AudioButton extends StatefulWidget {
  const AudioButton({
    super.key,
    required this.state,
    required this.onPressed,
    this.tone = AudioTone.narration,
    this.size = ElifbaSize.audioL,
    this.reduceMotion,
  });

  final AudioButtonState state;
  final VoidCallback? onPressed;
  final AudioTone tone;

  /// 56 və ya 48 dp.
  final double size;

  /// Testlər üçün `AppSettings.reduceMotion`-u əvəz edir.
  final bool? reduceMotion;

  @override
  State<AudioButton> createState() => _AudioButtonState();
}

class _AudioButtonState extends State<AudioButton>
    with SingleTickerProviderStateMixin, _PulseRing<AudioButton> {
  @override
  bool get _playing =>
      widget.tone == AudioTone.narration &&
      widget.state == AudioButtonState.playing;

  @override
  bool? get _reduceOverride => widget.reduceMotion;

  @override
  void didUpdateWidget(covariant AudioButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  @override
  Widget build(BuildContext context) {
    final small = widget.size < ElifbaSize.audioL;
    final muted = widget.state == AudioButtonState.muted;
    final edge = small ? ElifbaEdge.e4 : ElifbaEdge.e5;

    if (widget.tone == AudioTone.animal) {
      return Squishy(
        onTap: muted ? null : widget.onPressed,
        tooltip: muted ? 'Heyvan səsləri söndürülüb' : 'Heyvanın səsi',
        shape: const CircleBorder(),
        color: ElifbaPalette.tertiaryContainer,
        edge: ElifbaEdge.e4,
        edgeColor: ElifbaPalette.tertiaryEdge,
        width: widget.size,
        height: widget.size,
        alignment: Alignment.center,
        child: Icon(
          muted ? Icons.volume_off_rounded : Icons.pets_rounded,
          size: 24,
          color: muted ? ElifbaPalette.onMuted : ElifbaPalette.tertiary,
        ),
      );
    }

    final (icon, iconSize, tooltip) = switch (widget.state) {
      AudioButtonState.ready => (
        Icons.play_arrow_rounded,
        small ? 30.0 : 32.0,
        'Səsləndir',
      ),
      AudioButtonState.playing => (
        Icons.stop_rounded,
        small ? 26.0 : 28.0,
        'Dayandır',
      ),
      AudioButtonState.muted => (
        Icons.volume_off_rounded,
        small ? 24.0 : 26.0,
        'Səs söndürülüb',
      ),
    };
    final iconWidget = Icon(
      icon,
      size: iconSize,
      color: muted ? ElifbaPalette.onMuted : ElifbaPalette.onSecondary,
    );

    return AnimatedBuilder(
      animation: _pulseCurve,
      child: iconWidget,
      builder: (context, child) {
        final playing = _playing;
        return Squishy(
          onTap: muted ? null : widget.onPressed,
          tooltip: tooltip,
          shape: const CircleBorder(),
          color: ElifbaPalette.secondary,
          edge: edge,
          edgeColor:
              playing ? ElifbaPalette.playingEdge : ElifbaPalette.secondaryEdge,
          ringColor: playing ? ElifbaPalette.playingRing : null,
          ringWidth: _ring(ElifbaMotion.audioRingStatic),
          width: widget.size,
          height: widget.size,
          alignment: Alignment.center,
          child: child!,
        );
      },
    );
  }
}

/// Heyvan səhifəsinin Məlumat kartındakı «Dinlə» pill-i (yalnız nəqletmə).
/// 48 dp, boşluq 10 / 16, ikon 26 + Comfortaa 15.
///
/// | vəziyyət | üz      | halqa / kənar              | ikon       | yazı             |
/// |----------|---------|----------------------------|------------|------------------|
/// | ready    | #7C63D9 | — / 4 #5C45B5              | play_arrow | «Dinlə»          |
/// | playing  | #7C63D9 | #E4DEFF nəbz 0↔6 / #C6B8F5 | stop       | «Dayandır»       |
/// | muted    | #ECE8F6 | —                          | volume_off | «Səs söndürülüb» |
///
/// Yazı görünür, ona görə ayrıca tooltip yoxdur — semantik etiket yazının
/// özüdür. Azaldılmış hərəkətdə halqa sabit 4 dp.
class AudioPillButton extends StatefulWidget {
  const AudioPillButton({
    super.key,
    required this.state,
    required this.onPressed,
    this.reduceMotion,
  });

  final AudioButtonState state;
  final VoidCallback? onPressed;
  final bool? reduceMotion;

  @override
  State<AudioPillButton> createState() => _AudioPillButtonState();
}

class _AudioPillButtonState extends State<AudioPillButton>
    with SingleTickerProviderStateMixin, _PulseRing<AudioPillButton> {
  @override
  bool get _playing => widget.state == AudioButtonState.playing;

  @override
  bool? get _reduceOverride => widget.reduceMotion;

  @override
  void didUpdateWidget(covariant AudioPillButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  @override
  Widget build(BuildContext context) {
    final muted = widget.state == AudioButtonState.muted;
    final (icon, label) = switch (widget.state) {
      AudioButtonState.ready => (Icons.play_arrow_rounded, 'Dinlə'),
      AudioButtonState.playing => (Icons.stop_rounded, 'Dayandır'),
      AudioButtonState.muted => (Icons.volume_off_rounded, 'Səs söndürülüb'),
    };
    final fg = muted ? ElifbaPalette.onMuted : ElifbaPalette.onSecondary;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 26, color: fg),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: ElifbaTextStyles.counter.copyWith(color: fg),
          ),
        ),
      ],
    );
    return AnimatedBuilder(
      animation: _pulseCurve,
      child: content,
      builder: (context, child) {
        final playing = _playing;
        return Squishy(
          onTap: muted ? null : widget.onPressed,
          color: ElifbaPalette.secondary,
          edge: ElifbaEdge.e4,
          edgeColor:
              playing ? ElifbaPalette.playingEdge : ElifbaPalette.secondaryEdge,
          ringColor: playing ? ElifbaPalette.playingRing : null,
          ringWidth: _ring(ElifbaMotion.audioRingStaticPill),
          height: 48,
          padding: const EdgeInsetsDirectional.only(start: 10, end: 16),
          child: child!,
        );
      },
    );
  }
}
