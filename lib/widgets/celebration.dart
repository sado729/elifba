import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../core/settings.dart';
import '../theme/theme.dart';
import 'elifba_confetti.dart';
import 'pill_button.dart';
import 'squishy.dart';
import 'star_row.dart';
import 'sun_mascot.dart';
import 'sunburst.dart';

/// Təbrikin səviyyəsi (DS §5 "Təbrik ailəsi"): bir kart, iki səviyyə.
enum CelebrationLevel {
  /// Söz tapmaca, şəkil pazlı.
  small,

  /// «Tam ulduz!», «… hərfi tamam!».
  big,
}

/// Kartın düyməsi.
class CelebrationAction {
  const CelebrationAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
}

/// Təbrik kartı. Mətnlər ilk kadrdan ağacdadır (yalnız şəffaflıq və miqyas
/// animasiya olunur), ona görə testdə bir `pump()` tapmaq üçün kifayətdir;
/// başlıq və mətn hərəsi DƏQİQ bir `Text`-dir (`star_ui_test`
/// `findsOneWidget`). Mərhələlər bir `AnimationController` + `Interval`-larla
/// qurulur — `Timer`/`Future.delayed` yoxdur.
///
/// **Kiçik** (280 dp-ə qədər): statik günəş halqası + kubok, 40 dp ulduz,
/// başlıq, istəyə görə mətn və «Yenidən» düyməsi. Giriş: 0.85 → 1 + şəffaflıq,
/// 320 ms easeOutBack. Azaldılmış: 200 ms şəffaflıq, halqa düz.
///
/// **Böyük** (300 dp-ə qədər): kartın üstündən çıxan sevinən günəş (128 dp
/// halqada, şüalar 8 s-də bir fırlanır), 44 / 56 / 44 ulduz, başlıq, mətn,
/// «Yaşa!». Giriş (800 ms): kart 0–320 ms; günəş +40 dp → 0, 0–400 ms;
/// ulduzlar 200 / 320 / 440 ms-də bir-bir "pop". Azaldılmış: hamısı bir
/// 250 ms şəffaflıqla, ulduzlar birlikdə, halqa düz və fırlanmır.
///
/// ⚠️ Böyük kart açıq və hərəkət azaldılmayıbsa şüalar sonsuz fırlanır —
/// testdə `pumpAndSettle` ETMƏYİN.
class CelebrationCard extends StatefulWidget {
  const CelebrationCard.small({
    super.key,
    this.title = 'Təbriklər!',
    this.message,
    this.action,
    this.animateEntrance = true,
    this.reduceMotion,
  }) : level = CelebrationLevel.small;

  const CelebrationCard.big({
    super.key,
    required this.title,
    required String this.message,
    required CelebrationAction this.action,
    this.animateEntrance = true,
    this.reduceMotion,
  }) : level = CelebrationLevel.big;

  final CelebrationLevel level;
  final String title;
  final String? message;
  final CelebrationAction? action;

  /// `false` → kartın özü miqyas/şəffaflıq etmir (route keçidi edir). Günəşin
  /// və ulduzların girişi yenə oynayır.
  final bool animateEntrance;

  /// Testlər üçün `AppSettings.reduceMotion`-u əvəz edir.
  final bool? reduceMotion;

  @override
  State<CelebrationCard> createState() => _CelebrationCardState();
}

class _CelebrationCardState extends State<CelebrationCard>
    with SingleTickerProviderStateMixin {
  /// Kart açılan anda bir dəfə oxunur.
  late final bool _reduced = ElifbaMotion.isReduced(widget.reduceMotion);
  bool get _big => widget.level == CelebrationLevel.big;

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration:
        _reduced
            ? (_big
                ? ElifbaMotion.celebrationEnterReducedBig
                : ElifbaMotion.celebrationEnterReducedSmall)
            : (_big ? ElifbaMotion.bigIntro : ElifbaMotion.celebrationEnter),
  );

  @override
  void initState() {
    super.initState();
    _intro.forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  /// [ms] anını controller-in 0..1 vaxtına çevirir.
  double _t(int ms) {
    final total = _intro.duration!.inMilliseconds;
    return (ms / total).clamp(0.0, 1.0);
  }

  Animation<double> _interval(int fromMs, int toMs, Curve curve) =>
      CurvedAnimation(
        parent: _intro,
        curve: Interval(_t(fromMs), _t(toMs), curve: curve),
      );

  @override
  Widget build(BuildContext context) {
    final card = _big ? _buildBig() : _buildSmall();
    Widget result = Material(type: MaterialType.transparency, child: card);
    if (!widget.animateEntrance) return result;
    if (_reduced) {
      return FadeTransition(opacity: _intro, child: result);
    }
    final enterMs = ElifbaMotion.celebrationEnter.inMilliseconds;
    result = ScaleTransition(
      scale: Tween(
        begin: ElifbaMotion.celebrationEnterFromScale,
        end: 1.0,
      ).animate(_interval(0, enterMs, ElifbaMotion.celebrationEnterCurve)),
      child: result,
    );
    return FadeTransition(
      opacity: _interval(0, (enterMs * 0.4).round(), Curves.linear),
      child: result,
    );
  }

  Widget _frame({
    required double maxWidth,
    required EdgeInsets padding,
    required Widget child,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints.tightFor(width: maxWidth),
      child: DecoratedBox(
        decoration: squishyDecoration(
          color: ElifbaPalette.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(ElifbaRadius.r32)),
          ),
          edge: ElifbaEdge.e8,
          edgeColor: ElifbaPalette.outline,
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }

  Widget _title() => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(
      widget.title,
      textAlign: TextAlign.center,
      maxLines: 1,
      style: ElifbaTextStyles.celebrationTitle.copyWith(
        color: ElifbaPalette.onSurface,
      ),
    ),
  );

  Widget _message() => Text(
    widget.message!,
    textAlign: TextAlign.center,
    style: ElifbaTextStyles.celebrationBody.copyWith(
      color: ElifbaPalette.onSurfaceVariant,
    ),
  );

  Widget _buildSmall() {
    final action = widget.action;
    return _frame(
      maxWidth: ElifbaSize.celebrationSmallMaxWidth,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SunburstDisc(
            size: 96,
            flat: _reduced,
            reduceMotion: _reduced,
            child: const _Trophy(),
          ),
          const SizedBox(height: 10),
          const StarGlyph(filled: true, size: 40, strokeWidth: 1.4),
          const SizedBox(height: 10),
          _title(),
          if (widget.message != null) ...[
            const SizedBox(height: 10),
            _message(),
          ],
          if (action != null) ...[
            const SizedBox(height: 16),
            PillButton(
              label: action.label,
              icon: action.icon,
              onPressed: action.onPressed,
              size: PillButtonSize.medium,
              padding: const EdgeInsetsDirectional.only(start: 20, end: 26),
              labelStyle: ElifbaTextStyles.buttonMCelebration,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBig() {
    final action = widget.action!;
    final reduced = _reduced;

    Widget sun = SunburstDisc(
      size: 128,
      rotating: !reduced,
      flat: reduced,
      reduceMotion: reduced,
      child: const SunMascot.cheer(size: 100),
    );
    if (!reduced) {
      final rise = _interval(
        0,
        ElifbaMotion.sunRise.inMilliseconds,
        Curves.easeOutBack,
      );
      sun = FadeTransition(
        opacity: _interval(
          0,
          ElifbaMotion.sunFadeIn.inMilliseconds,
          Curves.linear,
        ),
        child: AnimatedBuilder(
          animation: rise,
          child: sun,
          builder:
              (context, child) => Transform.translate(
                offset: Offset(
                  0,
                  ElifbaMotion.sunRiseOffset * (1 - rise.value),
                ),
                child: child,
              ),
        ),
      );
    }

    Widget star(int i, double size) {
      Widget s = StarGlyph(filled: true, size: size, strokeWidth: 1.4);
      if (!reduced) {
        final start = ElifbaMotion.starPopStartsMs[i];
        s = ScaleTransition(
          scale: TweenSequence<double>([
            TweenSequenceItem(
              tween: Tween(
                begin: 0.0,
                end: ElifbaMotion.correctPopScale,
              ).chain(CurveTween(curve: Curves.easeOut)),
              weight: 60,
            ),
            TweenSequenceItem(
              tween: Tween(
                begin: ElifbaMotion.correctPopScale,
                end: 1.0,
              ).chain(CurveTween(curve: Curves.easeOutBack)),
              weight: 40,
            ),
          ]).animate(
            _interval(
              start,
              start + ElifbaMotion.starPop.inMilliseconds,
              Curves.linear,
            ),
          ),
          child: s,
        );
      }
      return s;
    }

    return _frame(
      maxWidth: ElifbaSize.celebrationBigMaxWidth,
      padding: const EdgeInsets.fromLTRB(20, 78, 20, 22),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Transform.translate(
                    offset: const Offset(0, 6),
                    child: star(0, 44),
                  ),
                  const SizedBox(width: 4),
                  star(1, 56),
                  const SizedBox(width: 4),
                  Transform.translate(
                    offset: const Offset(0, 6),
                    child: star(2, 44),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _title(),
              const SizedBox(height: 10),
              _message(),
              const SizedBox(height: 16),
              PillButton(
                label: action.label,
                icon: action.icon,
                onPressed: action.onPressed,
                size: PillButtonSize.large,
                padding: const EdgeInsets.symmetric(horizontal: 32),
              ),
            ],
          ),
          // Günəş kartın yuxarı kənarından 64 dp çıxır (padding 78-in içində
          // 128 dp halqa: −64 − 78 = kartın üst xəttindən −64).
          Positioned(
            top: -78 - 64,
            left: 0,
            right: 0,
            child: Center(child: sun),
          ),
        ],
      ),
    );
  }
}

/// Kiçik təbrikin kuboku: 68 dp narıncı dairə, 5 dp kənar.
class _Trophy extends StatelessWidget {
  const _Trophy();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: squishyDecoration(
        color: ElifbaPalette.primary,
        shape: const CircleBorder(),
        edge: ElifbaEdge.e5,
        edgeColor: ElifbaPalette.primaryEdge,
      ),
      child: const SizedBox.square(
        dimension: 68,
        child: Icon(
          Icons.emoji_events_rounded,
          size: 38,
          color: ElifbaPalette.onPrimary,
        ),
      ),
    );
  }
}

/// Səhifənin içində (route olmadan) göstərilən təbrik: söz tapmaca və «Tam
/// ulduz!». Səhifənin kök `Stack`-inə `Positioned.fill` kimi qoyulur və
/// `showCongrats` true olduğu kadrda ağacdadır (`star_ui_test` buna
/// söykənir).
///
/// Qatlar: scrim (55 %, 200 ms-də görünür) → konfeti (scrim-in üstündə,
/// kartın ALTINDA) → kart. Scrim-ə toxunmaq [onDismiss]-dir;
/// [dismissOnTapAnywhere] → ekranın istənilən yeri (söz tapmaca).
class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({
    super.key,
    required this.card,
    required this.onDismiss,
    this.dismissOnTapAnywhere = false,
    this.confetti,
  });

  /// `CelebrationCard.small(...)` və ya `.big(...)`.
  final CelebrationCard card;
  final VoidCallback onDismiss;
  final bool dismissOnTapAnywhere;

  /// Səhifənin `ElifbaConfetti`-si (controller səhifədədir) və ya null.
  final Widget? confetti;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scrim = AnimationController(
    vsync: this,
    duration: ElifbaMotion.scrimFade,
  )..forward();

  @override
  void dispose() {
    _scrim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final big = widget.card.level == CelebrationLevel.big;
    final pad = big ? 20.0 : 24.0;
    Widget body = Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onDismiss,
          child: FadeTransition(
            opacity: _scrim,
            child: const ColoredBox(color: ElifbaPalette.scrim55),
          ),
        ),
        if (widget.confetti != null)
          Align(
            alignment: Alignment.topCenter,
            child: IgnorePointer(child: widget.confetti),
          ),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              // Kartın ətrafındakı boşluq da scrim-dir: toxunuş scrim-ə
              // keçsin (defolt `opaque` onu udardı).
              hitTestBehavior: HitTestBehavior.deferToChild,
              padding: EdgeInsets.fromLTRB(pad, pad + (big ? 64 : 0), pad, pad),
              child: widget.card,
            ),
          ),
        ),
      ],
    );
    if (widget.dismissOnTapAnywhere) {
      body = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onDismiss,
        child: body,
      );
    }
    return Material(type: MaterialType.transparency, child: body);
  }
}

/// Route ilə göstərilən təbrik: şəkil pazlı (kiçik, bitəndən 1.5 s sonra)
/// və hərfin tam bitməsi (böyük). Kart bağlananda qayıdır.
///
/// * Scrim-ə toxunmaq və geri düyməsi yalnız bağlayır ([barrierDismissible]).
/// * [action]-ın `onPressed`-i `Navigator.pop`-dan SONRA çağırılır.
/// * Keçid: 0.85 → 1 + şəffaflıq, 320 ms; azaldılmış hərəkətdə yalnız
///   şəffaflıq (kiçik 200, böyük 250 ms).
/// * [playConfetti] → route öz konfetisini açılışdan sonrakı kadrda
///   `if (!AppSettings.instance.reduceMotion)` ilə oynadır (gotcha 16-dakı
///   YENİ `play()` yeri). Pazl öz konfetisini bitəndə artıq atdığı üçün
///   orada `false` verilir.
/// * İki route təbriki üst-üstə açmayın: səviyyəni route-dan əvvəl seçin.
Future<void> showCelebration(
  BuildContext context, {
  required CelebrationLevel level,
  required String title,
  String? message,
  CelebrationAction? action,
  bool barrierDismissible = true,
  bool playConfetti = true,
}) {
  assert(
    level == CelebrationLevel.small || (message != null && action != null),
    'Böyük təbrikin mətni və düyməsi olmalıdır.',
  );
  final reduced = ElifbaMotion.reduced;
  final big = level == CelebrationLevel.big;
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: ElifbaPalette.scrim55,
    transitionDuration:
        reduced
            ? (big
                ? ElifbaMotion.celebrationEnterReducedBig
                : ElifbaMotion.celebrationEnterReducedSmall)
            : ElifbaMotion.celebrationEnter,
    transitionBuilder: (context, animation, secondary, child) {
      if (reduced) return FadeTransition(opacity: animation, child: child);
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: const Interval(0, 0.4),
        ),
        child: ScaleTransition(
          scale: Tween(
            begin: ElifbaMotion.celebrationEnterFromScale,
            end: 1.0,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: ElifbaMotion.celebrationEnterCurve,
            ),
          ),
          child: child,
        ),
      );
    },
    pageBuilder:
        (context, animation, secondary) => _CelebrationRouteBody(
          level: level,
          title: title,
          message: message,
          action: action,
          playConfetti: playConfetti,
          reduceMotion: reduced,
        ),
  );
}

/// Hərfin tam bitməsi: böyük kart, «Yaşa!» (və ya [actionLabel]) yalnız
/// bağlayır.
Future<void> showBigWinCelebration(
  BuildContext context, {
  required String title,
  required String message,
  String actionLabel = 'Yaşa!',
}) => showCelebration(
  context,
  level: CelebrationLevel.big,
  title: title,
  message: message,
  action: CelebrationAction(
    label: actionLabel,
    icon: Icons.thumb_up_rounded,
    onPressed: () {},
  ),
);

/// Kiçik route təbriki (pazl: `message: 'Pazl tamamlandı!'`, «Yenidən»
/// düyməsi, `playConfetti: false`).
Future<void> showSmallWinCelebration(
  BuildContext context, {
  String title = 'Təbriklər!',
  String? message,
  CelebrationAction? action,
  bool playConfetti = true,
}) => showCelebration(
  context,
  level: CelebrationLevel.small,
  title: title,
  message: message,
  action: action,
  playConfetti: playConfetti,
);

class _CelebrationRouteBody extends StatefulWidget {
  const _CelebrationRouteBody({
    required this.level,
    required this.title,
    required this.message,
    required this.action,
    required this.playConfetti,
    required this.reduceMotion,
  });

  final CelebrationLevel level;
  final String title;
  final String? message;
  final CelebrationAction? action;
  final bool playConfetti;
  final bool reduceMotion;

  @override
  State<_CelebrationRouteBody> createState() => _CelebrationRouteBodyState();
}

class _CelebrationRouteBodyState extends State<_CelebrationRouteBody> {
  bool get _big => widget.level == CelebrationLevel.big;
  ConfettiPreset get _preset =>
      _big ? ConfettiPreset.big : ConfettiPreset.small;
  late final ConfettiController _confetti = _preset.createController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.playConfetti && !AppSettings.instance.reduceMotion) {
        _confetti.play();
      }
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.action;
    final action =
        a == null
            ? null
            : CelebrationAction(
              label: a.label,
              icon: a.icon,
              onPressed: () {
                Navigator.of(context).pop();
                a.onPressed();
              },
            );
    final card =
        _big
            ? CelebrationCard.big(
              title: widget.title,
              message: widget.message!,
              action: action!,
              animateEntrance: false,
              reduceMotion: widget.reduceMotion,
            )
            : CelebrationCard.small(
              title: widget.title,
              message: widget.message,
              action: action,
              animateEntrance: false,
              reduceMotion: widget.reduceMotion,
            );
    final pad = _big ? 20.0 : 24.0;
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: IgnorePointer(
              child: ElifbaConfetti(controller: _confetti, preset: _preset),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                // Kartın ətrafındakı boşluğa toxunuş barrier-ə keçsin.
                hitTestBehavior: HitTestBehavior.deferToChild,
                padding: EdgeInsets.fromLTRB(
                  pad,
                  pad + (_big ? 64 : 0),
                  pad,
                  pad,
                ),
                child: card,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
