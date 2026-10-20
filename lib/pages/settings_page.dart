import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/config.dart';
import '../core/progress.dart';
import '../core/settings.dart';
import '../theme/theme.dart';
import '../widgets/elifba_wordmark.dart';
import '../widgets/icon_buttons.dart';
import '../widgets/parent_ui.dart';
import '../widgets/sky_background.dart';

// Valideyn sahəsi sakitdir (dizayn §7.7, ScreenSettings): düz #F8F5FF fon,
// squish yoxdur, maskot yoxdur, kölgə yoxdur. Hər rəng və üslub AÇIQ verilir:
// ayarlar testləri səhifəni defolt temalı çılpaq `MaterialApp` ilə qurur,
// orada `ElifbaTheme` yoxdur və nəticə temadan asılı olmamalıdır.

/// Sətirlərin ortaq ölçüləri (maket: min 64 dp, 10/16 boşluq, 22 dp ikon,
/// 14 dp aralıq). İki sətirli `ListTile` hündürlüyü `2 × 11 + 22 + 20 = 64`
/// verir; 10 olsa sətir 62 dp olardı.
const ListTileThemeData _kRowTileTheme = ListTileThemeData(
  contentPadding: EdgeInsets.symmetric(horizontal: 16),
  minTileHeight: 64,
  minVerticalPadding: 11,
  horizontalTitleGap: 14,
  minLeadingWidth: 22,
  titleAlignment: ListTileTitleAlignment.center,
  visualDensity: VisualDensity.standard,
);

/// Sıfırlama dialoqunun eni (maket: `max-width: 312px`).
const double _kResetDialogMaxWidth = 312;

/// «Ayarlar»: Comfortaa 22/28 (`titleLarge`).
final TextStyle _kToolbarTitle = ElifbaTypography.textTheme.titleLarge!
    .copyWith(color: ElifbaPalette.onSurface);

/// Səs mənbəyinin başlığı: Andika 700 15/21.
const TextStyle _kCreditHeading = TextStyle(
  fontFamily: ElifbaTypography.body,
  fontWeight: FontWeight.w700,
  fontSize: 15,
  height: 21 / 15,
  letterSpacing: 0,
  leadingDistribution: TextLeadingDistribution.even,
  color: ElifbaPalette.onSurface,
);

/// Səs mənbəyinin sətirləri: Andika 14/20, #5E5888.
final TextStyle _kCreditBody = ElifbaTextStyles.listSubtitle.copyWith(
  color: ElifbaPalette.onSurfaceVariant,
);

/// «Versiya 1.4.0»: Andika 15/20, #5E5888.
const TextStyle _kAboutVersion = TextStyle(
  fontFamily: ElifbaTypography.body,
  fontWeight: FontWeight.w400,
  fontSize: 15,
  height: 20 / 15,
  letterSpacing: 0,
  leadingDistribution: TextLeadingDistribution.even,
  color: ElifbaPalette.onSurfaceVariant,
);

/// Paket adı: sistemin monospace şrifti 13/18 (bir sətir üçün şrift
/// gətirmirik; Android-də `'monospace'` sistem mono şriftinə açılır).
const TextStyle _kAboutPackage = TextStyle(
  fontFamily: 'monospace',
  fontWeight: FontWeight.w400,
  fontSize: 13,
  height: 18 / 13,
  letterSpacing: 0,
  leadingDistribution: TextLeadingDistribution.even,
  color: ElifbaPalette.onSurfaceVariant,
);

/// «Məxfilik»: Andika 700 16/22.
final TextStyle _kAboutHeading = ElifbaTextStyles.listTitle.copyWith(
  color: ElifbaPalette.onSurface,
);

/// Məxfilik mətni: Andika 15/22, `onSurface` (`onSurfaceVariant` YOX).
final TextStyle _kAboutBody = ElifbaTextStyles.dialogBody.copyWith(
  color: ElifbaPalette.onSurface,
);

/// Valideyn bölməsi — `showParentalGate()` arxasından açılır.
///
/// Uşağın əlinə keçməməli hər şey buradadır: səs kanalları, titrəmə,
/// animasiya, pazl çətinliyi və progresin silinməsi.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // CLAUDE.md gotcha #10: Android 16 edge-to-edge rejimini məcbur edir, sistem
    // panelləri `body`-nin üstünə düşür. Düz fon (`Scaffold`-un rəngi) hər iki
    // panelin arxasını boyayır; üst panel `SafeArea`-dadır, alt inset isə
    // yalnız siyahının alt boşluğuna əlavə olunur.
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final settings = AppSettings.instance;

    // AppBar yoxdur, ona görə sistem panellərinin tünd ikonlarını səhifə özü
    // elan edir — əks halda əvvəlki marşrutun üslubu qalardı.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: kElifbaSystemUiStyle,
      child: Scaffold(
        backgroundColor: ElifbaPalette.surfaceContainerLow,
        // `expand`: alt inseti olmayan cihazda (və testlərdə) `NavBarFade`
        // mövqesiz boş qutu qaytarır; onsuz `Stack` 0 × 0-a düşüb siyahını
        // gizlədərdi.
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Column(
                children: [
                  const SafeArea(bottom: false, child: _SettingsToolbar()),
                  Expanded(
                    // Açar və seqment görünüşü səhifənin özündədir: testlərdə
                    // tema yoxdur, tətbiqdə isə eyni dəyərlər temadan gəlir.
                    child: SwitchTheme(
                      data: ElifbaSwitchTheme.data,
                      child: SegmentedButtonTheme(
                        data: ElifbaSegmentedTheme.data,
                        child: ListTileTheme(
                          data: _kRowTileTheme,
                          child: AnimatedBuilder(
                            animation: settings,
                            builder:
                                (context, _) =>
                                    _buildList(context, settings, bottomInset),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const NavBarFade(parent: true),
          ],
        ),
      ),
    );
  }

  /// Səhifənin YEGANƏ `Scrollable`-ı. Testlər `scrollUntilVisible`-i
  /// `scrollable:` vermədən çağırır — səhnədə ikinci `Scrollable` olsa
  /// "Too many elements" xətası verərdi.
  Widget _buildList(
    BuildContext context,
    AppSettings settings,
    double bottomInset,
  ) {
    final master = settings.masterSound;
    // Maketdə başlıqlar və kartlar `gap: 8px`-lik şəbəkədədir.
    const gap = SizedBox(height: 8);
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 4, 16, 16 + bottomInset),
      children: [
        const ParentSectionHeader('Səs', first: true),
        gap,
        ParentGroup(
          children: [
            _switchRow(
              icon: master ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              title: 'Bütün səslər',
              subtitle: 'Tətbiqdəki bütün səsləri susdurur',
              value: master,
              onChanged: (v) => settings.masterSound = v,
            ),
            // Master söndürülübsə alt açarlar sönür, amma DƏYƏRLƏRİ qalır —
            // master geri açılanda əvvəlki vəziyyət qayıdır. Ona görə
            // `value` həmişə saxlanmış dəyərdir, heç vaxt `master && …` deyil.
            _switchRow(
              icon: Icons.record_voice_over_rounded,
              title: 'İzah və nəqletmə',
              subtitle: 'Hərf və heyvan haqqında danışıq',
              value: settings.narrationSound,
              onChanged: master ? (v) => settings.narrationSound = v : null,
            ),
            _switchRow(
              icon: Icons.pets_rounded,
              title: 'Heyvan səsləri',
              value: settings.animalSound,
              onChanged: master ? (v) => settings.animalSound = v : null,
            ),
            _switchRow(
              icon: Icons.music_note_rounded,
              title: 'Effektlər',
              subtitle: 'Klik, qalibiyyət, səhifə çevirmə',
              value: settings.effectSound,
              onChanged: master ? (v) => settings.effectSound = v : null,
            ),
          ],
        ),
        gap,
        const ParentSectionHeader('Oyun'),
        gap,
        ParentGroup(
          children: [
            _switchRow(
              icon: Icons.vibration_rounded,
              title: 'Titrəmə',
              subtitle: 'Hərfi cızarkən qısa titrəyiş',
              value: settings.haptics,
              onChanged: (v) => settings.haptics = v,
            ),
            _switchRow(
              icon: Icons.animation_rounded,
              title: 'Animasiyanı azalt',
              subtitle: 'Konfeti və təbrik effektlərini söndürür',
              value: settings.reduceMotion,
              onChanged: (v) => settings.reduceMotion = v,
            ),
            _PuzzleSizeBlock(settings: settings),
          ],
        ),
        gap,
        const ParentSectionHeader('Valideyn'),
        gap,
        ParentGroup(
          children: [
            _navRow(
              icon: Icons.restart_alt_rounded,
              iconColor: ElifbaPalette.error,
              title: 'Progresi sıfırla',
              titleColor: ElifbaPalette.onErrorContainer,
              subtitle: 'Bütün ulduzları və bölmələri silir',
              onTap: () => _confirmResetProgress(context),
            ),
          ],
        ),
        gap,
        const ParentSectionHeader('Məlumat'),
        gap,
        ParentGroup(
          children: [
            _navRow(
              icon: Icons.library_music_rounded,
              title: 'Səs mənbələri',
              onTap: () => _showSoundCredits(context),
            ),
            _navRow(
              icon: Icons.info_outline_rounded,
              title: 'Tətbiq haqqında',
              subtitle: 'Versiya $kAppVersion',
              onTap: () => _showAbout(context),
            ),
          ],
        ),
      ],
    );
  }

  /// Açar sətri. Altı açar bu bir köməkçidən keçir ki, görünüşləri
  /// ayrışmasın. Rənglər `SwitchListTile`-a verilmir: hamısı səhifənin
  /// `SwitchTheme`-indədir (`trackOutlineWidth` və `padding`-i onsuz da
  /// yalnız tema ötürür).
  ///
  /// [onChanged] `null`-dursa sətir qeyri-aktivdir: ikon #C6BFDD, mətn 50 %,
  /// açar öz DƏYƏRİNİ solğun rənglərlə göstərir.
  static Widget _switchRow({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    final enabled = onChanged != null;
    return SwitchListTile(
      controlAffinity: ListTileControlAffinity.trailing,
      secondary: Icon(
        icon,
        size: 22,
        color:
            enabled
                ? ElifbaPalette.onSurfaceVariant
                : ElifbaPalette.parentDisabledIcon,
      ),
      title: Text(
        title,
        style: ElifbaTextStyles.listTitle.copyWith(
          color:
              enabled
                  ? ElifbaPalette.onSurface
                  : ElifbaPalette.onSurface.withAlpha((0.5 * 255).toInt()),
        ),
      ),
      subtitle:
          subtitle == null
              ? null
              : Text(
                subtitle,
                style: ElifbaTextStyles.listSubtitle.copyWith(
                  color:
                      enabled
                          ? ElifbaPalette.onSurfaceVariant
                          : ElifbaPalette.onSurfaceVariant.withAlpha(
                            (0.5 * 255).toInt(),
                          ),
                ),
              ),
      value: value,
      onChanged: onChanged,
    );
  }

  /// Keçid sətri (sıfırlama, səs mənbələri, tətbiq haqqında): sağda chevron.
  static Widget _navRow({
    required IconData icon,
    Color iconColor = ElifbaPalette.onSurfaceVariant,
    required String title,
    Color titleColor = ElifbaPalette.onSurface,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 22, color: iconColor),
      title: Text(
        title,
        style: ElifbaTextStyles.listTitle.copyWith(color: titleColor),
      ),
      subtitle:
          subtitle == null
              ? null
              : Text(
                subtitle,
                style: ElifbaTextStyles.listSubtitle.copyWith(
                  color: ElifbaPalette.onSurfaceVariant,
                ),
              ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 22,
        color: ElifbaPalette.onMuted,
      ),
      onTap: onTap,
    );
  }

  /// Sıfırlamanın ikinci qoruyucu qatı.
  ///
  /// Valideyn qapısı basıb-saxlama olduğuna görə zəifdir (dizayn sənədi §2.1) —
  /// geri qaytarıla bilməyən əməliyyat ona görə ayrıca açıq təsdiq istəyir.
  /// Dialoqda `Scrollable` YOXDUR: o sönərkən test səhifəni sürüşdürür və
  /// səhnədə ikinci `Scrollable` olmamalıdır.
  Future<void> _confirmResetProgress(BuildContext context) async {
    final store = ProgressStore.instance;
    // `await`-dən əvvəl tutulur: dialoq bağlananda `context` artıq etibarlı
    // olmaya bilər. Kök messenger snackbar-ı kitaba da daşıyır.
    final messenger = ScaffoldMessenger.of(context);
    final stars = store.totalStars;
    final confirmed = await showParentDialog<bool>(
      context,
      builder:
          (context) => ParentDialog(
            title: 'Bütün ulduzlar silinsin?',
            icon: Icons.warning_rounded,
            body:
                'Yığılmış $stars ulduz və tamamlanmış bütün bölmələr '
                'silinəcək. Bu addımı geri qaytarmaq mümkün deyil.',
            maxWidth: _kResetDialogMaxWidth,
            actions: [
              TextButton(
                style: ParentButtonStyles.textCompact,
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Ləğv et'),
              ),
              FilledButton(
                style: ParentButtonStyles.destructive,
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Bəli, sil'),
              ),
            ],
          ),
    );
    // Ləğv, scrim-ə toxunuş və sistem "geri"si (`false` / `null`) heç nəyi
    // dəyişmir.
    if (confirmed != true) return;
    await store.reset();
    messenger.showSnackBar(elifbaSnackBar('Progres sıfırlandı.'));
  }

  void _showSoundCredits(BuildContext context) {
    showParentDialog<void>(
      context,
      builder:
          (context) => ParentDialog(
            title: 'Səs mənbələri',
            scrollableContent: true,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < _kSoundCredits.length; i++)
                  Padding(
                    // Maket: elementlər arası 12 + hər elementin 8 dp üst
                    // boşluğu.
                    padding: EdgeInsets.only(top: i == 0 ? 8 : 20),
                    child: _CreditItem(_kSoundCredits[i]),
                  ),
              ],
            ),
            actions: [
              FilledButton(
                style: ParentButtonStyles.filled,
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Bağla'),
              ),
            ],
          ),
    );
  }

  void _showAbout(BuildContext context) {
    showParentDialog<void>(
      context,
      builder:
          (context) => ParentDialogFrame(
            semanticLabel: 'Tətbiq haqqında',
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Böyük şriftdə dialoq ekrana sığmasa mətn sürüşür,
                  // «Bağla» isə həmişə görünür.
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Ad heç vaxt `Text` kimi yazılmır (brend qaydası):
                          // günəşli «ı» ilə kontur loqo. 40 = maketin 30 dp
                          // sətri + günəş üçün 10 dp.
                          const ElifbaWordmark(height: 40),
                          const SizedBox(height: 12),
                          const Text(
                            'Versiya $kAppVersion',
                            style: _kAboutVersion,
                          ),
                          const SizedBox(height: 6),
                          const Text(kAppPackageId, style: _kAboutPackage),
                          const SizedBox(height: 20),
                          Semantics(
                            header: true,
                            child: Text('Məxfilik', style: _kAboutHeading),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Bu tətbiq heç bir şəxsi məlumat toplamır, '
                            'internetə qoşulmur və reklam göstərmir. Bütün '
                            'şəkillər və səslər tətbiqin içindədir; yığılmış '
                            'ulduzlar yalnız bu cihazda saxlanılır.',
                            style: _kAboutBody,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      style: ParentButtonStyles.filled,
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Bağla'),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

/// Üst panel: 64 dp, solda 48 dp düz geri düyməsi, sola düzlənmiş başlıq.
/// Fonu, xətti və kölgəsi yoxdur — `Scaffold`-un #F8F5FF-i görünür.
class _SettingsToolbar extends StatelessWidget {
  const _SettingsToolbar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ElifbaSize.toolbar,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            const ParentBackButton(),
            const SizedBox(width: 6),
            Flexible(
              child: Semantics(
                header: true,
                child: Text(
                  'Ayarlar',
                  style: _kToolbarTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// «Oyun» kartındakı pazl ölçüsü: başlıq sətri və altında 3 × 3 / 4 × 4 /
/// 5 × 5 seqmentləri. `ListTile` deyil, bütövlükdə toxunulmur.
///
/// Oyunun öz «Asan / Orta / Çətin» seçimi də qalır (5 × 5 = «Çətin»);
/// buradakı seçim yadda saxlanır.
class _PuzzleSizeBlock extends StatelessWidget {
  const _PuzzleSizeBlock({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.extension_rounded,
                size: 22,
                color: ElifbaPalette.onSurfaceVariant,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pazl çətinliyi',
                      style: ElifbaTextStyles.listTitle.copyWith(
                        color: ElifbaPalette.onSurface,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Şəkil pazlındaki parça sayı',
                      style: ElifbaTextStyles.listSubtitle.copyWith(
                        color: ElifbaPalette.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            // 22 ikon + 14 aralıq: seqmentlər mətnlə bir xətdə başlayır.
            padding: const EdgeInsets.only(left: 36),
            child: SegmentedButton<int>(
              segments: [
                for (final n in AppSettings.puzzleGridSizes)
                  ButtonSegment(value: n, label: Text('$n × $n')),
              ],
              selected: {settings.puzzleGridSize},
              onSelectionChanged: (s) => settings.puzzleGridSize = s.first,
              // Seqmentlər eni bərabər bölür.
              expandedInsets: EdgeInsets.zero,
              // `SegmentedButton` temadakı `minimumSize`-ı seqmentlərə
              // ötürmür (Flutter 3.32 `segmentStyleFor`): seqment 40 dp
              // çəkilir, `padded` isə yalnız layout-u 48-ə çatdırır. 48 dp
              // pill üçün hündürlük boşluqdan gəlir: 20 dp sətir + 2 × 14.
              // `shrinkWrap` olmasa kontur `fontSize`-a görə hesablanıb 43 dp
              // çəkilərdi.
              style: const ButtonStyle(
                padding: WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Səs mənbəyinin bir elementi: istəyə görə başlıq, sonra sətirlər.
typedef _Credit = ({String? heading, List<String> lines, bool bullets});

/// «Səs mənbələri» dialoqunun REAL mətni. CC BY səsi əlavə edəndə müəllifi
/// buraya bir sətir kimi yazın (CLAUDE.md). Maketdəki `[Səs aktyoru]`,
/// `[Mənbə 1]` sətirləri placeholder-dir — onlar köçürülmür.
const List<_Credit> _kSoundCredits = [
  (
    heading:
        'Tətbiqdəki heyvan səsləri açıq lisenziyalı mənbələrdən istifadə '
        'olunub:',
    bullets: true,
    lines: [
      'bigsoundbank.com — CC0 (Public Domain)',
      'soundbible.com — Public Domain və CC BY 3.0',
      'fws.gov, nps.gov — Public Domain arxivləri',
      'freesound.org, xeno-canto.org — CC0 və CC BY 4.0',
      'commons.wikimedia.org, figshare.com (elmi məqalələrin əlavələri) — '
          'CC BY 4.0',
    ],
  ),
  (
    heading: 'CC BY 3.0 müəllifləri:',
    bullets: false,
    lines: ['Mike Koenig, Daniel Simon, J Dawg, Mark Mattingly, Cat Stevens'],
  ),
  (
    heading: 'CC BY 4.0 müəllifləri (creativecommons.org/licenses/by/4.0):',
    bullets: false,
    lines: [
      'Çəyirtkə — reinsamba (freesound)',
      'Vaşaq — YleArkisto (freesound)',
      'Turac — NikosDemetriou (freesound)',
      'Dələ — Gabriele Vaudano (xeno-canto)',
      'Yaquar — About Zoos (Wikimedia Commons)',
      'Hepard — D. Smirnova, I. Volodin, T. Demina, E. Volodina',
      'Ceyran — I. A. Volodin, O. V. Sibiryakova, N. V. Soldatova, '
          'E. V. Volodina',
      'Zürafə — E. Volodina, I. Volodin, E. Chelysheva, R. Frey',
      'Koala — B. D. Charlton, W. A. H. Ellis, A. J. McKinnon, J. Brumm, '
          'K. Nilsson, W. T. Fitch',
      'Panda — B. D. Charlton, M. S. Martin-Wintle, M. A. Owen, '
          'Zhang Hemin, R. R. Swaisgood',
    ],
  ),
  (
    heading: null,
    bullets: false,
    lines: [
      'Səslər tətbiq üçün qısaldılıb, təmizlənib və səs səviyyəsi '
          'bərabərləşdirilib.',
    ],
  ),
];

/// Bir mənbə: başlıqdan 2 dp sonra sətirlər, sətirlər arası 4 dp. Siyahı
/// sətirləri asılı girintili `•` ilə yazılır.
class _CreditItem extends StatelessWidget {
  const _CreditItem(this.credit);

  final _Credit credit;

  @override
  Widget build(BuildContext context) {
    final heading = credit.heading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (heading != null) ...[
          Text(heading, style: _kCreditHeading),
          const SizedBox(height: 2),
        ],
        for (var i = 0; i < credit.lines.length; i++) ...[
          if (i > 0) const SizedBox(height: 4),
          if (credit.bullets)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 14, child: Text('•', style: _kCreditBody)),
                Expanded(child: Text(credit.lines[i], style: _kCreditBody)),
              ],
            )
          else
            Text(credit.lines[i], style: _kCreditBody),
        ],
      ],
    );
  }
}
