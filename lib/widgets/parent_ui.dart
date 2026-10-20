import 'package:flutter/material.dart';

import '../theme/theme.dart';

// Valideyn sahəsi sakitdir: düz #F8F5FF, squish yoxdur, maskot yoxdur, eyni
// şriftlər və rənglər (DS + ScreenSettings). Bu fayldakı hər rəng və üslub
// AÇIQ verilir: ayarlar testləri səhifəni defolt temalı çılpaq `MaterialApp`
// ilə qurur, orada `ElifbaTheme` yoxdur.

/// Valideyn dialoqlarını açır: scrim #2E2A55 55 %, `showDialog`-un qalan
/// defoltları (scrim-ə toxunmaq bağlayır, `useSafeArea`, 150 ms fade).
Future<T?> showParentDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) => showDialog<T>(
  context: context,
  barrierColor: ElifbaPalette.scrim55,
  barrierDismissible: barrierDismissible,
  builder: builder,
);

/// Valideyn dialoqunun qabığı: #FFFDFB, radius 28, kölgə və çalar yoxdur,
/// en ən çox [maxWidth] (`DialogThemeData`-da en məhdudiyyəti yoxdur).
/// Məzmun tam azaddır — qapı (`parental_gate.dart`) və xüsusi dialoqlar
/// bunu işlədir; adi dialoq üçün [ParentDialog].
class ParentDialogFrame extends StatelessWidget {
  const ParentDialogFrame({
    super.key,
    required this.child,
    this.maxWidth = ElifbaSize.dialogMaxWidth,
    this.insetPadding = const EdgeInsets.all(24),
    this.semanticLabel,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets insetPadding;

  /// Ekran oxuyucusu üçün dialoqun adı (adətən başlıq).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ElifbaPalette.surface,
      surfaceTintColor: ElifbaPalette.transparent,
      shadowColor: ElifbaPalette.transparent,
      elevation: 0,
      insetPadding: insetPadding,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(ElifbaRadius.r28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        scopesRoute: true,
        namesRoute: semanticLabel != null,
        explicitChildNodes: true,
        label: semanticLabel,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}

/// Adi valideyn dialoqu: istəyə görə mərkəzdə ikon (32 dp), başlıq
/// (Comfortaa 20/26), mətn (Andika 15/22 #5E5888) və ya istənilən
/// [content], sağda düymələr ([ParentButtonStyles] ilə).
///
/// [scrollableContent] → sürüşən dialoq (səs mənbələri): başlıq sabit,
/// [content] yuxarı/aşağı 1 dp #ECE8F6 xətlər arasında sürüşür, düymələr
/// sabit altda. Bu halda `insetPadding` defoltu 40 / 20, en 340.
///
/// Düymələr `OverflowBar`-dadır: böyük şriftdə daşmır, alt-alta düzülür.
class ParentDialog extends StatelessWidget {
  const ParentDialog({
    super.key,
    required this.title,
    this.icon,
    this.iconColor = ElifbaPalette.error,
    this.iconSize = 32,
    this.titleStyle,
    this.body,
    this.content,
    this.actions = const [],
    this.maxWidth,
    this.insetPadding,
    this.padding,
    this.semanticLabel,
    this.scrollableContent = false,
  });

  final String title;

  /// Sıfırlama: `Icons.warning_rounded` #DD4A5A; qapı: `Icons.lock_rounded`
  /// 30 #8A84AE.
  final IconData? icon;
  final Color iconColor;
  final double iconSize;

  /// Defolt `ElifbaTextStyles.dialogTitle`; qapı `gateTitle` (Andika) verir.
  final TextStyle? titleStyle;

  /// Sadə mətn; [content] verilibsə ondan sonra gəlir.
  final String? body;
  final Widget? content;
  final List<Widget> actions;
  final double? maxWidth;
  final EdgeInsets? insetPadding;

  /// Məzmunun boşluğu; defolt `fromLTRB(20, 24, 20, 12)`.
  final EdgeInsetsGeometry? padding;
  final String? semanticLabel;
  final bool scrollableContent;

  @override
  Widget build(BuildContext context) {
    final titleText = Text(
      title,
      textAlign: icon != null ? TextAlign.center : TextAlign.start,
      style: (titleStyle ?? ElifbaTextStyles.dialogTitle).copyWith(
        color: ElifbaPalette.onSurface,
      ),
    );
    final bodyText =
        body == null
            ? null
            : Text(
              body!,
              style: ElifbaTextStyles.dialogBody.copyWith(
                color: ElifbaPalette.onSurfaceVariant,
              ),
            );
    final actionBar =
        actions.isEmpty
            ? null
            : OverflowBar(
              alignment: MainAxisAlignment.end,
              overflowAlignment: OverflowBarAlignment.end,
              spacing: 6,
              children: actions,
            );

    if (scrollableContent) {
      return ParentDialogFrame(
        maxWidth: maxWidth ?? ElifbaSize.creditsMaxWidth,
        insetPadding:
            insetPadding ??
            const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        semanticLabel: semanticLabel ?? title,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
              child: titleText,
            ),
            Flexible(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  border: Border.symmetric(
                    horizontal: BorderSide(
                      color: ElifbaPalette.surfaceContainerHigh,
                    ),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 4, 22, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (bodyText != null) bodyText,
                      if (content != null) content!,
                    ],
                  ),
                ),
              ),
            ),
            if (actionBar != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: actionBar,
              ),
          ],
        ),
      );
    }

    return ParentDialogFrame(
      maxWidth: maxWidth ?? ElifbaSize.dialogMaxWidth,
      insetPadding: insetPadding ?? const EdgeInsets.all(24),
      semanticLabel: semanticLabel ?? title,
      child: Padding(
        padding: padding ?? const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (icon != null) ...[
              Center(child: Icon(icon, size: iconSize, color: iconColor)),
              const SizedBox(height: 14),
            ],
            titleText,
            if (bodyText != null || content != null) const SizedBox(height: 14),
            if (bodyText != null) bodyText,
            if (bodyText != null && content != null) const SizedBox(height: 10),
            if (content != null) content!,
            if (actionBar != null) ...[const SizedBox(height: 20), actionBar],
          ],
        ),
      ),
    );
  }
}

/// Ayarların sətir qrupu: #FFFDFB, radius 20, halqa və kənar yoxdur, sətirlər
/// arasında 1 dp #ECE8F6 xətt. Sətirlərin M3 mürəkkəbi küncə kəsilir.
class ParentGroup extends StatelessWidget {
  const ParentGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ElifbaPalette.surface,
      surfaceTintColor: ElifbaPalette.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(ElifbaRadius.r20)),
      ),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 1,
                color: ElifbaPalette.surfaceContainerHigh,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Ayar bölməsinin başlığı: cümlə registri («Səs», «Oyun», «Valideyn»,
/// «Məlumat»), Andika 700 14 #5C45B5. `toUpperCase()` YOXDUR — köhnə
/// `'i' → 'İ'` hiyləsi onunla birgə getdi.
class ParentSectionHeader extends StatelessWidget {
  const ParentSectionHeader(this.title, {super.key, this.first = false});

  final String title;

  /// Siyahının ilk başlığı yuxarıda 12, qalanları 16 dp boşluq alır.
  final bool first;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4, first ? 12 : 16, 4, 4),
      child: Semantics(
        header: true,
        child: Text(title, style: ElifbaTextStyles.sectionLabel),
      ),
    );
  }
}

/// Dizayna uyğun snackbar: üzən, #2E2A55, radius 16, 52 dp, solda ✓
/// #A0D9C3, yanlardan və nav bar-dan 16 dp aralı, defolt 4 s.
///
/// `await`-dən əvvəl tutulmuş `ScaffoldMessenger` ilə göstərmək üçün
/// (`messenger.showSnackBar(elifbaSnackBar(...))`).
SnackBar elifbaSnackBar(
  String message, {
  IconData icon = Icons.check_circle_rounded,
  Duration duration = const Duration(seconds: 4),
}) => SnackBar(
  behavior: SnackBarBehavior.floating,
  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
  // Açıq `padding` SnackBar-ın öz 14 dp şaquli boşluğunu götürür: hündürlük
  // dəqiq 52 olur.
  padding: const EdgeInsetsDirectional.only(start: 14, end: 18),
  backgroundColor: ElifbaPalette.inverseSurface,
  elevation: 0,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(ElifbaRadius.r16)),
  ),
  duration: duration,
  content: ConstrainedBox(
    constraints: const BoxConstraints(minHeight: ElifbaSize.snackbar),
    child: Row(
      children: [
        Icon(icon, size: 22, color: ElifbaPalette.snackIcon),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: ElifbaTextStyles.snackbar.copyWith(
              color: ElifbaPalette.onInverseSurface,
            ),
          ),
        ),
      ],
    ),
  ),
);

/// [elifbaSnackBar]-ı yaxındakı `ScaffoldMessenger`-də göstərir.
void showElifbaSnackBar(
  BuildContext context,
  String message, {
  IconData icon = Icons.check_circle_rounded,
}) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(elifbaSnackBar(message, icon: icon));
}
