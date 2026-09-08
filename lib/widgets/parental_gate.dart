import 'package:flutter/material.dart';

/// Qapını açmaq üçün düyməni neçə müddət basıb saxlamaq lazımdır.
///
/// 3 saniyə bilərəkdən seçilib: 2 saniyə 4-5 yaşlı uşağın təsadüfən keçəcəyi
/// qədər qısadır, 5 saniyə isə valideyn üçün əziyyətlidir.
const Duration kParentalGateHold = Duration(seconds: 3);

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
Future<bool> showParentalGate(BuildContext context) async {
  final passed = await showDialog<bool>(
    context: context,
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
    with SingleTickerProviderStateMixin {
  late final AnimationController _hold = AnimationController(
    vsync: this,
    duration: kParentalGateHold,
  )..addStatusListener(_onStatus);

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  /// Barmaq qaldırılanda tərəqqi TAM sıfırlanır — yığıla-yığıla keçmək
  /// mümkün olmasın.
  void _cancelHold() => _hold.reset();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.lock_outline, size: 36),
      title: const Text('Valideynlər üçün'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Davam etmək üçün düyməni 3 saniyə basıb saxlayın.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Toxunma sahəsi bilərəkdən kiçikdir (72 px) və mərkəzdədir:
          // ovucla və ya təsadüfi toxunuşla basılması çətinləşsin.
          GestureDetector(
            onTapDown: (_) => _hold.forward(),
            onTapUp: (_) => _cancelHold(),
            onTapCancel: _cancelHold,
            child: SizedBox(
              width: 72,
              height: 72,
              child: AnimatedBuilder(
                animation: _hold,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          // 0 ikən Material sonsuz fırlanma göstərir; basılmamış
                          // halqa hərəkətsiz qalmalıdır.
                          value: _hold.value,
                          strokeWidth: 5,
                        ),
                      ),
                      child!,
                    ],
                  );
                },
                child: const Icon(Icons.touch_app_outlined, size: 30),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Ləğv et'),
        ),
      ],
    );
  }
}
