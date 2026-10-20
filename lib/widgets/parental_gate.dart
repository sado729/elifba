import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'parent_ui.dart';

/// Qapını açmaq üçün düyməni neçə müddət basıb saxlamaq lazımdır.
///
/// 3 saniyə bilərəkdən seçilib: 2 saniyə 4-5 yaşlı uşağın təsadüfən keçəcəyi
/// qədər qısadır, 5 saniyə isə valideyn üçün əziyyətlidir.
const Duration kParentalGateHold = Duration(seconds: 3);

/// Qapı keçildikdən sonra yaşıl ✓ halının görünmə müddəti (dizayn §7.3:
/// "Tamam · 200 ms sonra ayarlar açılır").
///
/// Keçid qərarı bundan ƏVVƏL, [kParentalGateHold] tam dolan anda verilir —
/// bu, yalnız valideynə görünən təsdiqdir, hədd uzanmır.
const Duration kParentalGateDoneDelay = ElifbaMotion.gateDoneBeat;

/// Valideyn qapısı. `true` qaytarırsa istifadəçi qapını keçib.
///
/// Uşaq tətbiqlərində valideynə yönəlik məzmun (ayarlar, progresin silinməsi)
/// uşağın asanlıqla keçə bilməyəcəyi bir addımın arxasında olmalıdır.
///
/// ⚠️ Basıb-saxlama mövcud variantların **ən zəifidir** — uşaq təkrar cəhdlə
/// keçə bilər. Bu, bilərəkdən qəbul edilmiş seçimdir (bax
/// `docs/superpowers/specs/2026-09-08-ayarlar-valideyn-bolmesi-design.md` §2.1).
/// Ona görə qapının arxasındakı dağıdıcı əməliyyat (progresin sıfırlanması)
/// ƏLAVƏ təsdiq dialoqu ilə də qorunur.
///
/// Görünüş bilərəkdən sakit və neytraldır (boz-lavanda kilid, rəngsiz düymə):
/// maskot, squish, konfetti, səs və titrəmə yoxdur — uşaq üçün maraqlı heç nə
/// olmasın. Yeganə parlaq rəng qapı keçiləndə ✓ ilə gələn yaşıldır.
///
/// Scrim-ə toxunmaq, "Ləğv et" və sistemin "geri"si `false` qaytarır.
Future<bool> showParentalGate(BuildContext context) async {
  final passed = await showParentDialog<bool>(
    context,
    builder: (_) => const _ParentalGateDialog(),
  );
  return passed ?? false;
}

class _ParentalGateDialog extends StatefulWidget {
  const _ParentalGateDialog();

  @override
  State<_ParentalGateDialog> createState() => _ParentalGateDialogState();
}

class _ParentalGateDialogState extends State<_ParentalGateDialog>
    with TickerProviderStateMixin {
  /// Basıb-saxlamanın vaxtı: xətti 0→1, [kParentalGateHold] ərzində.
  ///
  /// `preserve`: sistemin "animasiyaları söndür" bayrağı (Android-in
  /// "Animasiyaları sil" ayarı) adi controller-in müddətini 20 dəfə qısaldır —
  /// 3 s 150 ms olardı. Bu, animasiya yox, qapının həddidir; qısalmamalıdır.
  late final AnimationController _hold = AnimationController(
    vsync: this,
    duration: kParentalGateHold,
    animationBehavior: AnimationBehavior.preserve,
  )..addStatusListener(_onHoldStatus);

  /// Yaşıl ✓ halının 200 ms-i. `Timer` yox, controller: testlərdəki
  /// `pumpAndSettle` onun kadrlarını addımlayır, `Timer`-i isə gözləməzdi.
  /// `preserve` — yuxarıdakı səbəbdən (yoxsa ✓ 10 ms görünərdi).
  late final AnimationController _doneDelay = AnimationController(
    vsync: this,
    duration: kParentalGateDoneDelay,
    animationBehavior: AnimationBehavior.preserve,
  )..addStatusListener(_onDoneStatus);

  /// Halqa tam doldu — qapı keçilib. Geri dönüşü yoxdur: barmağı qaldırmaq,
  /// "Ləğv et", scrim və "geri" artıq heç nəyi dəyişmir.
  bool _done = false;

  /// `pop` artıq çağırılıb (iki dəfə bağlamamaq üçün).
  bool _closed = false;

  void _onHoldStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _done || !mounted) return;
    setState(() => _done = true);
    _doneDelay.forward();
  }

  void _onDoneStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _close(true);
  }

  /// Dialoqu yalnız bir dəfə və yalnız hələ ən üstdədirsə bağlayır. Əks halda
  /// (məs. scrim-lə bağlanma animasiyası gedərkən halqa dolsa) `pop` altdakı
  /// səhifəni — kitabı — bağlayardı.
  void _close(bool result) {
    if (_closed || !mounted) return;
    if (!(ModalRoute.isCurrentOf(context) ?? false)) return;
    _closed = true;
    Navigator.of(context).pop(result);
  }

  void _startHold() {
    if (_done) return;
    _hold.forward();
  }

  /// Barmaq qaldırılanda tərəqqi TAM sıfırlanır — yığıla-yığıla keçmək
  /// mümkün olmasın. Sıfırlanma ani olur (geri animasiya yoxdur). Qapı artıq
  /// keçilibsə (done) heç nə etmir.
  void _cancelHold() {
    if (_done) return;
    _hold.reset();
  }

  void _onCancelPressed() {
    if (_done) return; // keçid artıq qərara alınıb
    _close(false);
  }

  @override
  void dispose() {
    _hold.dispose();
    _doneDelay.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Done halında scrim və sistemin "geri"si dialoqu bağlamır: scrim
    // `Navigator.maybePop` çağırır, o da `PopScope`-a tabedir.
    // `semanticLabel` bilərəkdən verilmir (spec §6): o, marşrutu da
    // "Valideynlər üçün" adlandırardı və ekran oxuyucusu başlıqla birlikdə
    // eyni sözləri iki dəfə deyərdi. Başlıq yeganə belə düyündür.
    return PopScope(
      canPop: !_done,
      child: ParentDialogFrame(
        maxWidth: ElifbaSize.gateMaxWidth,
        child: SizedBox(
          width: double.infinity,
          // Portretdə məzmun sığır və Scrollable heç bir sürüşdürmə tanıyıcısı
          // qeyd etmir — `onTapDown` dərhal gəlir. Yalnız landşaftda və iri
          // şriftdə (məzmun daşanda) sürüşür.
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dizaynda kilid 30 px-lik ikon şriftinin sətridir: sətir
                // qutusu 36 dp-dir (qlifin üstündə və altında 3 dp). Renderlə
                // üst-üstə düşsün deyə qutu da 36 dp-dir — dialoq 362 dp olur.
                const SizedBox(
                  height: 36,
                  child: Center(
                    child: Icon(
                      Icons.lock_rounded,
                      size: 30,
                      color: ElifbaPalette.quietIcon,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Semantics(
                  header: true,
                  child: Text(
                    'Valideynlər üçün',
                    textAlign: TextAlign.center,
                    style: ElifbaTextStyles.gateTitle.copyWith(
                      color: ElifbaPalette.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Davam etmək üçün düyməni 3 saniyə basıb saxlayın.',
                  textAlign: TextAlign.center,
                  style: ElifbaTextStyles.dialogBody.copyWith(
                    color: ElifbaPalette.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                _buildHoldRing(),
                const SizedBox(height: 16),
                TextButton(
                  style: ParentButtonStyles.text,
                  onPressed: _onCancelPressed,
                  child: const Text('Ləğv et'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 112 dp halqa və mərkəzində 72 dp basıb-saxlama düyməsi.
  Widget _buildHoldRing() {
    return SizedBox(
      width: ElifbaSize.gateRingBox,
      height: ElifbaSize.gateRingBox,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Halqa toxunma sahəsinə daxil DEYİL — yalnız göstəricidir.
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _hold,
              builder:
                  (context, _) => CustomPaint(
                    painter: _GateRingPainter(
                      progress: _hold.value,
                      color:
                          _done
                              ? ElifbaPalette.correct
                              : ElifbaPalette.onSurfaceVariant,
                    ),
                  ),
            ),
          ),
          // Toxunma sahəsi bilərəkdən kiçikdir (72 px) və mərkəzdədir:
          // ovucla və ya təsadüfi toxunuşla basılması çətinləşsin. `opaque`
          // bütün 72×72 kvadratı hədəf edir (dairəvi bəzək yalnız daxili
          // dairəni yoxlayardı). InkWell yoxdur: dalğa və ikinci tanıyıcı
          // olmasın; barmaq `kTouchSlop`-dan çox sürüşsə toxunuş ləğv olunur,
          // bu da buraxılış sayılır (sıfırlanma).
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _startHold(),
            onTapUp: (_) => _cancelHold(),
            onTapCancel: _cancelHold,
            child: AnimatedBuilder(
              animation: _hold,
              builder: (context, _) {
                // Hallar arası keçid anidir (dizayn: dəyərlər birbaşa dəyişir).
                final Color background;
                if (_done) {
                  background = ElifbaPalette.correctContainer;
                } else if (_hold.value > 0) {
                  background = ElifbaPalette.surfaceContainerHighest;
                } else {
                  background = ElifbaPalette.surfaceContainer;
                }
                return Container(
                  width: ElifbaSize.gateHold,
                  height: ElifbaSize.gateHold,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: background,
                    // CSS `inset 0 0 0 1.5px` — xətt dairənin içində.
                    border: Border.all(
                      color: ElifbaPalette.outline,
                      width: ElifbaRing.hairline,
                    ),
                  ),
                  // Dizaynda hər iki ikon 32 px-dir, amma Material Symbols-un
                  // ✓-u `check_rounded`-dan incə və kiçikdir: 28-də qutusu
                  // (≈19×15) dizaynınkına (20×14) uyur, 32-də 23×17 olardı.
                  child: Icon(
                    _done ? Icons.check_rounded : Icons.touch_app_outlined,
                    size: _done ? 28 : 32,
                    color:
                        _done
                            ? ElifbaPalette.onCorrectContainer
                            : ElifbaPalette.onSurfaceVariant,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Basıb-saxlama halqası: 6 dp #ECE8F6 iz və saat 12-dən saat əqrəbi
/// istiqamətində dolan qövs (yuvarlaq uclu).
///
/// `CircularProgressIndicator` deyil: o, xətti `strokeWidth / 2` içəri çəkir
/// (radius 50 əvəzinə 53 olardı) və `value: null` olanda fırlanır.
class _GateRingPainter extends CustomPainter {
  const _GateRingPainter({required this.progress, required this.color});

  /// 0 → yalnız iz; 1 → tam dairə.
  final double progress;
  final Color color;

  /// Xəttin orta xəttinə qədər radius (112 dp qutuda, kənardan 3 dp içəri).
  static const double radius = 50;
  static const double strokeWidth = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..color = ElifbaPalette.surfaceContainerHigh;
    canvas.drawCircle(center, radius, paint);

    final p = math.min(progress, 1.0);
    // 0-da yuvarlaq ucun nöqtəsi də çəkilmir.
    if (p <= 0) return;
    paint
      ..color = color
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * p,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_GateRingPainter old) =>
      old.progress != progress || old.color != color;
}
