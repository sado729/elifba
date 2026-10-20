import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'animal_list_page.dart';
import 'settings_page.dart';
import '../core/config.dart';
import '../core/progress.dart';
import '../core/sound.dart';
import '../theme/theme.dart';
import '../widgets/badges.dart';
import '../widgets/elifba_wordmark.dart';
import '../widgets/icon_buttons.dart';
import '../widgets/mute_button.dart';
import '../widgets/parental_gate.dart';
import '../widgets/sky_background.dart';
import '../widgets/squishy.dart';
import '../widgets/star_row.dart';
import '../widgets/sun_mascot.dart';
import '../widgets/sunburst.dart';

/// Ana səhifə: əlifba kitabı (ScreenHome, home.md).
///
/// Kitab tamamilə kodla çəkilir — iki rəngli hərf səhifəsi, aralarında krem
/// cild zolağı, üstündən baxan günəş, arxada buludlar və ağ təpə. Bitmap yoxdur.
class AlphabetPage extends StatefulWidget {
  const AlphabetPage({super.key});

  @override
  State<AlphabetPage> createState() => _AlphabetPageState();
}

class _AlphabetPageState extends State<AlphabetPage> {
  static const List<String> alphabet = AppConfig.alphabet;

  /// Kitabın səhifə cütlərinin sayı (32 hərf → 16).
  static final int _spreadCount = (alphabet.length / 2).ceil();

  final GatedPlayer _audioPlayer = GatedPlayer(SoundChannel.effect);
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // Ulduzlar hərf səhifələrində qazanılır; kitaba qayıdanda hər hərfin
    // ulduzu və başlıqdaki ümumi sayğac təzə dəyəri göstərsin.
    ProgressStore.instance.addListener(_onProgressChanged);
    _preloadFlipSound();
  }

  void _onProgressChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _preloadFlipSound() async {
    try {
      await _audioPlayer.setAsset('assets/audios/page_flip.mp3');
    } catch (e) {
      // Səs yüklənməsə də kitab işləməlidir.
      debugPrint('Səhifə çevirmə səsi yüklənmədi: $e');
    }
  }

  @override
  void dispose() {
    ProgressStore.instance.removeListener(_onProgressChanged);
    _audioPlayer.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _playPageFlipSound() => _audioPlayer.replay();

  Future<void> _openSettings() async {
    if (!await showParentalGate(context)) return;
    if (!mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
  }

  void _openAnimalList(BuildContext context, String letter) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) =>
                AnimalListPage(letter: letter),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = ElifbaMotion.routeSlideCurve;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: ElifbaMotion.routeSlide,
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _spreadCount - 1) {
      _pageController.nextPage(
        duration: ElifbaMotion.bookFlip,
        curve: ElifbaMotion.bookFlipCurve,
      );
      _playPageFlipSound();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: ElifbaMotion.bookFlip,
        curve: ElifbaMotion.bookFlipCurve,
      );
      _playPageFlipSound();
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ProgressStore.instance;
    final big = ElifbaLayout.isLarge(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: kElifbaSystemUiStyle,
      child: Scaffold(
        backgroundColor: ElifbaPalette.skyBottom,
        body: Stack(
          children: [
            // Fon status və nav bar-ın da arxasındadır (gotcha 10); bütün
            // interaktiv məzmun isə SafeArea-nın içindədir.
            const Positioned.fill(
              child: SkyBackground(style: SkyStyle.skyWithClouds),
            ),
            SafeArea(
              child: Column(
                children: [
                  SizedBox(
                    height: ElifbaSize.toolbar,
                    child: MediaQuery.withClampedTextScaling(
                      maxScaleFactor: 1.3,
                      child: _Header(
                        totalStars: store.totalStars,
                        maxTotalStars: store.maxTotalStars,
                        onOpenSettings: _openSettings,
                      ),
                    ),
                  ),
                  Expanded(child: _buildBook(big)),
                  SizedBox(
                    height: 96,
                    child: MediaQuery.withClampedTextScaling(
                      maxScaleFactor: 1.3,
                      child: _BottomBar(
                        page: _currentPage + 1,
                        total: _spreadCount,
                        onPrevious: _currentPage > 0 ? _previousPage : null,
                        onNext:
                            _currentPage < _spreadCount - 1 ? _nextPage : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Səhifə cütünün hər yanındakı boşluq: sürüşdürəndə iki cütün arasında
  /// 2 × 7 = 14 dp qalır, kartlar bir-birinə yapışmır (köhnə `_BookPage`-in
  /// `margin`-i kimi).
  static const double _spreadGap = 7;

  /// Kitab sahəsi: yuxarıdan 28, yanlardan 14 dp boşluq, hündürlük 420 / 560
  /// dp ilə məhdud (+8 dp səhifənin alt kənarı üçün), ortada.
  ///
  /// `PageView` kart sırasından hər yana [_spreadGap] qədər enlidir, hər cüt
  /// də o qədər içəri çəkilir: sakit vəziyyətdə kartlar maketdəki yerindədir.
  /// `PageView` tam en DEYİL: `widget_test`-in −400 dp sürüşdürməsi 574 dp-lik
  /// səhifənin ~70 %-idir və səhifə irəli keçir; tam endə (800 dp) 47 %
  /// olardı və geri qayıdardı.
  Widget _buildBook(bool big) {
    final bookMax = big ? 560.0 : 420.0;
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 4),
      child: LayoutBuilder(
        builder: (context, c) {
          final boxH = math.min(c.maxHeight, bookMax + ElifbaEdge.e8);
          final rowW = math.max(0.0, math.min(c.maxWidth - 28, 560.0));
          return Center(
            child: SizedBox(
              width: rowW + 2 * _spreadGap,
              height: boxH,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Günəş kartlardan ƏVVƏL çəkilir: sağ səhifə onun alt 24
                  // dp-ni örtür və o, kitabın üstündən "baxır".
                  const Positioned(
                    top: -36,
                    right: 20 + _spreadGap,
                    width: 60,
                    height: 60,
                    child: IgnorePointer(child: SunMascot(size: 60)),
                  ),
                  Positioned.fill(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: _spreadCount,
                      itemBuilder: (context, i) {
                        return Padding(
                          // Səhifənin 8 dp alt kənarı kəsilməsin; yanlarda
                          // cütlər arası boşluq.
                          padding: const EdgeInsets.fromLTRB(
                            _spreadGap,
                            0,
                            _spreadGap,
                            ElifbaEdge.e8,
                          ),
                          child: _Spread(
                            leftIndex: i * 2,
                            rightIndex:
                                i * 2 + 1 < alphabet.length ? i * 2 + 1 : null,
                            big: big,
                            onTap: (letter) => _openAnimalList(context, letter),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Başlıq (64 dp): ümumi ulduz sayğacı, loqo, sürətli səs açarı, ayarlar.
class _Header extends StatelessWidget {
  const _Header({
    required this.totalStars,
    required this.maxTotalStars,
    required this.onOpenSettings,
  });

  final int totalStars;
  final int maxTotalStars;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _TotalStarsPill(total: totalStars, max: maxTotalStars),
          const SizedBox(width: 2),
          // Başlıq yazı deyil, brendin konturlu loqosudur (heç vaxt `Text`).
          // Fon açıq səma olduğu üçün açıq fon variantı işlədilir; 37 dp =
          // maketdəki 28 px Comfortaa × 1.32.
          //
          // Maketdə başlıq canlı mətndir: 28 dp-lik sətir qutusu ortalanır,
          // hərflər isə onun yuxarısında oturur (y 43–64). Loqonun qutusunda
          // günəşə yer var, ortalananda hərflər 7 dp aşağı düşürdü — alt
          // boşluq 14 dp qutunu 7 dp qaldırır, hərflərin xətti maketlə üst-üstə
          // düşür.
          const Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 14),
                child: ElifbaWordmark(
                  height: 37,
                  colors: ElifbaWordmarkColors.light,
                ),
              ),
            ),
          ),
          const SizedBox(width: 2),
          // Səsi susdurmaq qapısızdır — təcili ehtiyacdır.
          const MuteButton(),
          const SizedBox(width: 2),
          // Ayarlar isə valideyn qapısının arxasındadır: sakit, fonsuz dişli.
          QuietIconButton(onPressed: onOpenSettings),
        ],
      ),
    );
  }
}

/// Başlıqdaki ümumi ulduz sayğacı: `⭐ 41/96` (düymə deyil, basılmır).
///
/// Dəyəri [_AlphabetPageState] ötürür — o, store-u dinləyir və dəyişəndə
/// bütün səhifəni yenidən qurur.
class _TotalStarsPill extends StatelessWidget {
  const _TotalStarsPill({required this.total, required this.max});

  final int total;
  final int max;

  @override
  Widget build(BuildContext context) {
    final label = '$max ulduzdan $total ulduz yığılıb';
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Semantics(
        label: label,
        excludeSemantics: true,
        child: Container(
          height: ElifbaSize.totalStarsHeight,
          padding: const EdgeInsets.only(left: 9, right: 14),
          decoration: squishyDecoration(
            color: ElifbaPalette.surface,
            edge: ElifbaEdge.e3,
            edgeColor: ElifbaPalette.outline,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tək `StarGlyph`, `StarRow` DEYİL: kitab testi səhifədə dəqiq
              // iki `StarRow` sayır.
              const StarGlyph(filled: true, size: 24),
              const SizedBox(width: 5),
              Text(
                '$total/$max',
                style: ElifbaTextStyles.counter.copyWith(
                  height: 1.0,
                  color: ElifbaPalette.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bir səhifə cütü: iki hərf səhifəsi və ortada cild zolağı.
class _Spread extends StatelessWidget {
  const _Spread({
    required this.leftIndex,
    required this.rightIndex,
    required this.big,
    required this.onTap,
  });

  final int leftIndex;
  final int? rightIndex;
  final bool big;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Sol səhifə əvvəl qurulur: `star_ui_test` `StarRow`-ları ağac
        // sırası ilə oxuyur (birinci A, ikinci B).
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _LetterPage(index: leftIndex, big: big, onTap: onTap),
            ),
            const SizedBox(width: 8),
            Expanded(
              child:
                  rightIndex == null
                      ? const SizedBox.shrink()
                      : _LetterPage(index: rightIndex!, big: big, onTap: onTap),
            ),
          ],
        ),
        // Cild zolağı kartların ÜSTÜNDƏ çəkilir, amma toxunuşu buraxır.
        // `Padding` hündürlüyü mənfiyə düşürmür (çox alçaq ekranda zolaq
        // sadəcə yox olur).
        const Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: _BindingStrip()),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Kitabın krem cildi: 14 dp en, 2 dp #D2C8F2 halqa.
class _BindingStrip extends StatelessWidget {
  const _BindingStrip();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 14,
      height: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ElifbaPalette.surface,
          borderRadius: BorderRadius.all(Radius.circular(7)),
          boxShadow: [
            BoxShadow(
              color: ElifbaPalette.outline,
              spreadRadius: ElifbaRing.normal,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bir hərf səhifəsi: rəngli "squishy" kart, ağ diskdə «Aa», altında ulduzlar.
///
/// Tam bitmiş hərf yalnız rənglə seçilmir: qızılı üz + günəş şüaları + ✓.
class _LetterPage extends StatelessWidget {
  const _LetterPage({
    required this.index,
    required this.big,
    required this.onTap,
  });

  final int index;
  final bool big;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final letter = AppConfig.alphabet[index];
    final stars = ProgressStore.instance.starsOf(letter);
    final complete = stars >= ProgressStore.maxStarsPerLetter;
    final set = ElifbaPalette.letterSetAt(index);
    final face = complete ? set.asComplete() : set;
    // `MergeSemantics`: TalkBack "A hərfi, 3 ulduzdan 0, düymə" oxuyur.
    return MergeSemantics(
      child: Squishy(
        semanticLabel: complete ? '$letter hərfi, tamamlanıb' : '$letter hərfi',
        borderRadius: BorderRadius.circular(ElifbaRadius.r32),
        color: face.tint,
        edge: ElifbaEdge.e8,
        edgeColor: face.edge,
        // Üz 4 dp enir, kənar 8 → 4 qısalır: səhifənin altı yerində qalır.
        pressDepth: ElifbaEdge.e4,
        onTap: () => onTap(letter),
        child: Stack(
          children: [
            // Alçaq ekranda (landşaft) məzmun kiçilir, heç vaxt daşmır.
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  // Diskin 6 dp halqasına yer.
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LetterDisc(
                        letter: letter,
                        color: set.deep,
                        complete: complete,
                        big: big,
                      ),
                      const SizedBox(height: 22),
                      _StarPill(stars: stars),
                    ],
                  ),
                ),
              ),
            ),
            if (complete)
              const Positioned(
                top: 14,
                left: 14,
                child: CheckBadge(
                  size: ElifbaSize.badgeBook,
                  ringWidth: ElifbaRing.strong,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Hərfin diski: 136 / 156 dp ağ dairə (tam bitmiş hərfdə günəş şüaları),
/// 6 dp 70 % ağ halqa, içində böyük və kiçik hərf.
class _LetterDisc extends StatelessWidget {
  const _LetterDisc({
    required this.letter,
    required this.color,
    required this.complete,
    required this.big,
  });

  final String letter;
  final Color color;
  final bool complete;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final glyph = (big
            ? ElifbaTextStyles.bookGlyphLarge
            : ElifbaTextStyles.bookGlyph)
        .copyWith(color: color);
    return SizedBox.square(
      dimension: big ? 156 : 136,
      // Kəsilmir: Ö, Ü, İ-nin işarələri 1.0 sətirdən bir az yuxarı çıxır.
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: complete ? null : ElifbaPalette.surface,
          boxShadow: const [
            BoxShadow(color: ElifbaPalette.discRing, spreadRadius: 6),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Ana səhifədə şüalar statikdir — fırlanma yalnız böyük təbrikdə.
            if (complete) const SunburstDisc(),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: ExcludeSemantics(
                    // İki ayrı `Text`: testlər `find.text('A')` ilə hərfi tapır
                    // və ona toxunur. Kiçik hərf açıq cədvəldən gəlir
                    // (`I → ı`, `İ → i`), heç vaxt `toLowerCase()`-dən yox.
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          letter,
                          style: glyph,
                          textScaler: TextScaler.noScaling,
                        ),
                        Text(
                          AppConfig.lowerOf(letter),
                          style: glyph,
                          textScaler: TextScaler.noScaling,
                        ),
                      ],
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
}

/// Diskin altındaki ağ pill: üç ulduz, 26 dp (102 × 38).
class _StarPill extends StatelessWidget {
  const _StarPill({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const ShapeDecoration(
        color: ElifbaPalette.surface,
        shape: StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        child: StarRow(filled: stars, size: 26, spacing: 2),
      ),
    );
  }
}

/// Alt panel (96 dp): əvvəlki səhifə, «N / 16» nişanı, növbəti səhifə.
///
/// Kitabın əvvəlində «geri», sonunda «irəli» qeyri-aktivdir: boz üz, kənar
/// yox, `Semantics(enabled: false)`, toxunuş heç nə etmir.
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.page,
    required this.total,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final int total;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ElifbaSpace.gutter),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          NavRoundButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Əvvəlki səhifə',
            onPressed: onPrevious,
          ),
          _PageChip(page: page, total: total),
          NavRoundButton(
            icon: Icons.arrow_forward_rounded,
            tooltip: 'Növbəti səhifə',
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

/// «4 / 16» səhifə nişanı (basılmır). Mətndə slash-ın ətrafında boşluq var —
/// ulduz sayğacında («41/96») isə yoxdur.
class _PageChip extends StatelessWidget {
  const _PageChip({required this.page, required this.total});

  final int page;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Səhifə $page / $total',
      excludeSemantics: true,
      child: Container(
        height: ElifbaSize.pageChipHeight,
        padding: const EdgeInsets.only(left: 12, right: 16),
        decoration: squishyDecoration(
          color: ElifbaPalette.surface,
          ringWidth: ElifbaRing.normal,
          ringColor: ElifbaPalette.outline,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.menu_book_rounded,
              size: 22,
              color: ElifbaPalette.secondary,
            ),
            const SizedBox(width: 8),
            Text(
              '$page / $total',
              style: ElifbaTextStyles.counter.copyWith(
                color: ElifbaPalette.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
