import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_drawing/path_drawing.dart';

import '../core/config.dart';
import '../core/letter_strokes.dart';
import '../core/progress.dart';
import '../core/settings.dart';
import '../core/sound.dart';
import '../core/stroke_tracker.dart';
import '../theme/theme.dart';
import '../widgets/audio_button.dart';
import '../widgets/celebration.dart';
import '../widgets/elifba_card.dart';
import '../widgets/icon_buttons.dart';
import '../widgets/progress_bar.dart';
import '../widgets/sky_background.dart';
import '../widgets/squishy.dart';
import '../widgets/star_row.dart';
import '../widgets/sun_mascot.dart';
import '../widgets/tracing_canvas.dart';
import 'animal_detail_page.dart';
import 'letter_writing_page.dart';

/// Qrid xanasındaki heyvan şəkli üçün dekod eni. Bütün heyvan şəkilləri
/// 400x400 WebP-dir və xana ~160 px göstərilir; `cacheWidth` şəkli böyütmür,
/// ona görə bu dəyər mənbə ölçüsü ilə eynidir və detal səhifəsindəki hero ilə
/// eyni image-cache açarını paylaşır (iki ayrı dekod yaranmır).
const int kAnimalThumbDecodeWidth = 400;

/// Heyvan kartının kənarı ilə halqasının qutudan aşağı çıxdığı məsafə:
/// `ElifbaEdge.e6` + `ElifbaRing.normal` (CSS `0 6px 0 2px`).
const double _kCardPaintOverflow = ElifbaEdge.e6 + ElifbaRing.normal;

/// Hərf səhifəsi (ScreenLetter, §7.4): üst panel + TƏK sürüşən sahə — hərf
/// haqqında kart (səs düyməsi içində), «Heyvanlar» sətri və tənbəl qrid
/// (əvvəl yazı kartı, sonra heyvanlar).
///
/// Bütün məzmun bir `CustomScrollView`-dadır: açılan məlumat kartı qridi
/// sıxmır, onu aşağı itələyir. Sabit olan yalnız 64 dp-lik üst paneldir —
/// əvvəlki `AppBar` da 64 dp idi, ona görə qridin üstünə yeni sabit sətir
/// əlavə olunmayıb (CLAUDE.md gotcha 13).
class AnimalListPage extends StatefulWidget {
  final String letter;
  const AnimalListPage({super.key, required this.letter});

  @override
  State<AnimalListPage> createState() => _AnimalListPageState();
}

class _AnimalListPageState extends State<AnimalListPage> {
  /// Hərf haqqında mətn ilk açılışda gizlidir; karta toxunanda açılır.
  bool _infoExpanded = false;

  ProgressStore get _store => ProgressStore.instance;

  /// Alt səhifədən (heyvan detalı və ya yazı oyunu) qayıdanda hərfin tamamlanıb
  /// tamamlanmadığını yoxlayır.
  ///
  /// Təbrik store dinləyicisindən deyil, məhz QAYIDIŞDA göstərilir: son bölmə
  /// alt səhifədə bitir və dinləyici ilə dialoq həmin səhifənin ÜSTÜNDƏ açılardı.
  /// `takeLetterCelebration` özü bir dəfəlikdir, ona görə təkrar açılmır.
  /// Konfetini route özü oynadır, `reduceMotion` yoxlaması ilə (gotcha 16).
  Future<void> _maybeCelebrateLetter() async {
    if (!mounted) return;
    if (!_store.takeLetterCelebration(widget.letter)) return;
    await showBigWinCelebration(
      context,
      title: '${widget.letter} hərfi tamam!',
      message:
          'Bu hərflə bağlı hər şeyi etdin — heyvanları, tapmacaları və '
          'hərfi yazmağı. ${ProgressStore.maxStarsPerLetter} ulduz sənindir!',
      actionLabel: 'Yaşa!',
    );
  }

  void _onProgressChanged() {
    if (mounted) setState(() {});
  }

  void _toggleInfo() => setState(() => _infoExpanded = !_infoExpanded);

  @override
  void dispose() {
    _store.removeListener(_onProgressChanged);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Ulduzlar alt səhifədə (heyvan detalı, yazı oyunu) qazanılır; qayıdanda
    // qrid və hərf sayğacı təzə dəyərləri göstərsin. Səhifədə TƏK dinləyici
    // var — kartlar store-a özləri qoşulmur.
    _store.addListener(_onProgressChanged);
    // Şəkilləri qabaqcadan yüklə. Ölçü qriddəki `cacheWidth` ilə eyni olmalıdır,
    // əks halda image cache-də hər şəkil üçün ikinci nüsxə yaranır.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final animals = AppConfig.findLetter(widget.letter)?.animals ?? [];
      for (final animal in animals) {
        if (animal.imagePath.isEmpty) continue;
        precacheImage(
          ResizeImage(
            AssetImage(animal.imagePath),
            width: kAnimalThumbDecodeWidth,
          ),
          context,
        );
      }
    });
  }

  void _openWriting(String letter) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LetterWritingPage(letter: letter)),
    ).then((_) {
      _maybeCelebrateLetter();
    });
  }

  void _openAnimal(String animal, List<String> animals, int animalIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AnimalDetailPage(
              animal: animal,
              animals: animals,
              currentIndex: animalIndex,
            ),
      ),
    ).then((_) {
      _maybeCelebrateLetter();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Android 16 (API 36) edge-to-edge-i məcbur edir: sistem panelləri gövdənin
    // üstünə düşür. Fon tam ekrandır, məzmun isə view padding qədər içəri
    // çəkilir (gotcha 10).
    final vp = MediaQuery.viewPaddingOf(context);
    final big = ElifbaLayout.isLarge(context);
    // Ekran maketləri (ScreenLetter renders) 360 və 412-də eyni 16 dp kənar
    // işlədir: 412-də kart 184 endədir. letter.md D1-in 20 dp-si (kart 180)
    // QƏSDƏN tətbiq olunmayıb — keyfiyyət ölçüsü maketlərdir.
    const hPad = ElifbaSpace.gutter;
    final cardH = big ? 212.0 : 196.0;

    final letter = widget.letter;
    final letterConfig = AppConfig.findLetter(letter);
    final info =
        letterConfig?.description ?? '$letter hərfi haqqında məlumat yoxdur.';
    final animalObjects = letterConfig?.animals ?? [];
    final animals = animalObjects.map((a) => a.name).toList();
    // Yazı kartı yalnız cizgiləri təsvir olunmuş hərflərdə görünür. Bu səhifə
    // əsl hərfi (Ə, Ş...) bilir, ona görə diakritikanı normalizasiyadan
    // yenidən çıxarmaq lazım gəlmir.
    final showWrite = LetterStrokes.has(letter);
    final itemCount = animals.length + (showWrite ? 1 : 0);
    final gridShown = itemCount > 0;

    final scroll = CustomScrollView(
      key: const ValueKey('letterPageScroll'),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(hPad + vp.left, 6, hPad + vp.right, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LetterInfoCard(
                  letter: letter,
                  description: info,
                  expanded: _infoExpanded,
                  onToggle: _toggleInfo,
                ),
                const SizedBox(height: 14),
                _AnimalsHeadingRow(letter: letter),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ),
        // Qrid tənbəldir (`SliverGrid`): yalnız görünən sətirlər qurulur.
        // Yazı kartı qridin İLK xanasıdır — ekranın ilk gördüyü, ən böyük
        // hədəf; heyvan indeksi buna görə bir sürüşür.
        //
        // Kartın kənarı və halqası (`0 6px 0 2px`) qutudan 8 dp aşağı çəkilir,
        // `SliverGrid` isə xananı yalnız QUTUSU görünəndə çəkir: kart ekranın
        // üstündən çıxan kimi kənarı da yox olardı (maket 01-də o zolaq
        // görünür). Ona görə həmin 8 dp xananın içindədir — xana `cardH + 8`,
        // sətir arası 6: kartların yeri və addımı (cardH + 14) dəyişmir.
        if (gridShown)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(hPad + vp.left, 0, hPad + vp.right, 0),
            sliver: SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14 - _kCardPaintOverflow,
                crossAxisSpacing: 12,
                mainAxisExtent: cardH + _kCardPaintOverflow,
              ),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                final Widget card;
                if (showWrite && index == 0) {
                  card = _WriteLetterCard(
                    letter: letter,
                    written: _store.isWritten(letter),
                    onTap: () => _openWriting(letter),
                  );
                } else {
                  // AnimalDetailPage-ə MÜTLƏQ sürüşdürülməmiş heyvan indeksi
                  // verilməlidir, yoxsa detal səhifəsindəki irəli/geri
                  // naviqasiya səhv heyvandan başlayır.
                  final animalIndex = showWrite ? index - 1 : index;
                  final animal = animals[animalIndex];
                  final imageAsset =
                      AppConfig.findAnimal(letter, animal)?.imagePath ?? '';
                  card = _AnimalCard(
                    animal: animal,
                    imageAsset: imageAsset,
                    stars: _store.animalStars(animal),
                    onTap: () => _openAnimal(animal, animals, animalIndex),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: _kCardPaintOverflow),
                  child: card,
                );
              },
            ),
          ),
        // Ğ, I, Ü, J, R hərflərinin heyvanı yoxdur: qriddə tək yazı kartı
        // qalır, uşaq isə niyəsini bilməlidir.
        if (animals.isEmpty)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              hPad + vp.left,
              // Qridin son 8 dp-si artıq kartın kənarıdır: arada yenə 14.
              gridShown ? 14 - _kCardPaintOverflow : 0,
              hPad + vp.right,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: _EmptyLetterCard(
                message:
                    showWrite
                        ? 'Bu hərflə başlayan heyvan yoxdur, amma hərfi yaza bilərsən!'
                        : 'Bu hərflə başlayan heyvan yoxdur.',
              ),
            ),
          ),
        // Maketin alt boşluğu 40 dp-dir. Qrid sonuncudursa onun son 8 dp-si
        // (kartın kənarı) bu boşluğun bir hissəsidir — sürüşmə uzunluğu
        // maketdəki kimi qalır.
        SliverToBoxAdapter(
          child: SizedBox(
            height:
                (animals.isEmpty ? 40 : 40 - _kCardPaintOverflow) + vp.bottom,
          ),
        ),
      ],
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Açıq ekran, tünd sistem ikonları; `AppBar` olmadığı üçün üslubu səhifə
      // özü verir.
      value: kElifbaSystemUiStyle,
      child: Scaffold(
        backgroundColor: ElifbaPalette.skyMid,
        body: SkyBackground(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Column(
                children: [
                  SizedBox(height: vp.top),
                  _LetterTopBar(letter: letter),
                  Expanded(child: RepaintBoundary(child: scroll)),
                ],
              ),
              const NavBarFade(),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- üst panel

/// 64 dp üst panel: geri · «B hərfi» · ‹ ›. Fonu yoxdur — səma görünür.
class _LetterTopBar extends StatelessWidget {
  const _LetterTopBar({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    final vp = MediaQuery.viewPaddingOf(context);
    return Padding(
      key: const ValueKey('letterTopBar'),
      padding: EdgeInsets.only(left: 10 + vp.left, right: 10 + vp.right),
      child: SizedBox(
        height: ElifbaSize.toolbar,
        child: Row(
          children: [
            const ToolbarBackButton(),
            const SizedBox(width: 6),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                // Köhnə `AppBar` başlığı belə bükürdü: TalkBack səhifə
                // açılanda «A hərfi»-ni ekranın adı kimi oxuyur. iOS-da
                // `AppBar` kimi `namesRoute` verilmir.
                child: Semantics(
                  header: true,
                  namesRoute: switch (Theme.of(context).platform) {
                    TargetPlatform.iOS || TargetPlatform.macOS => null,
                    _ => true,
                  },
                  child: Text(
                    '$letter hərfi',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: ElifbaTypography.textTheme.titleLarge!.copyWith(
                      color: ElifbaPalette.onSurface,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            _LetterArrowButton(
              direction: ArrowDirection.left,
              currentLetter: letter,
            ),
            const SizedBox(width: 6),
            _LetterArrowButton(
              direction: ArrowDirection.right,
              currentLetter: letter,
            ),
          ],
        ),
      ),
    );
  }
}

enum ArrowDirection { left, right }

/// Əvvəlki/növbəti hərf. Əlifbanın sonunda dövrə vurmur (bu yalnız yazı
/// oyunundadır): kənarda düymə söndürülür.
class _LetterArrowButton extends StatelessWidget {
  final ArrowDirection direction;
  final String currentLetter;
  const _LetterArrowButton({
    required this.direction,
    required this.currentLetter,
  });

  @override
  Widget build(BuildContext context) {
    final alphabet = AppConfig.alphabet;
    final currentIndex = alphabet.indexOf(currentLetter);
    final isLeft = direction == ArrowDirection.left;
    final isDisabled =
        isLeft ? currentIndex == 0 : currentIndex == alphabet.length - 1;
    final nextIndex = isLeft ? currentIndex - 1 : currentIndex + 1;
    return ToolbarChevron(
      forward: !isLeft,
      tooltip: isLeft ? 'Əvvəlki hərf' : 'Növbəti hərf',
      onPressed:
          isDisabled
              ? null
              : () {
                final nextLetter = alphabet[nextIndex];
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder:
                        (context, animation, secondaryAnimation) =>
                            AnimalListPage(letter: nextLetter),
                    transitionsBuilder: (
                      context,
                      animation,
                      secondaryAnimation,
                      child,
                    ) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = ElifbaMotion.routeSlideCurve;
                      var tween = Tween(
                        begin: isLeft ? const Offset(-1.0, 0.0) : begin,
                        end: end,
                      ).chain(CurveTween(curve: curve));
                      var offsetAnimation = animation.drive(tween);
                      return SlideTransition(
                        position: offsetAnimation,
                        child: child,
                      );
                    },
                    transitionDuration: ElifbaMotion.routeSlide,
                  ),
                );
              },
    );
  }
}

// ------------------------------------------------------- hərf haqqında kart

/// Açılıb-bağlanan hərf kartı; səsləndirmə düyməsi kartın sol tərəfindədir.
///
/// Toxunma sahələri: bağlı kartın HAMISI, açıq kartın isə yalnız başlığı
/// (mətnə toxunmaq kartı bağlamır). Səs düyməsi heç bir toggle
/// `GestureDetector`-unun İÇİNDƏ deyil — `Stack`-də onların qardaşıdır, ona
/// görə ona (söndürülmüş halda da) toxunmaq kartı açıb-bağlamır.
///
/// Düymə hər iki vəziyyətdə eyni element olaraq qalır: kartı açıb-bağlamaq
/// `GatedPlayer`-i dispose edib nəqli kəsməməlidir.
class _LetterInfoCard extends StatelessWidget {
  const _LetterInfoCard({
    required this.letter,
    required this.description,
    required this.expanded,
    required this.onToggle,
  });

  final String letter;
  final String description;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    // Səs faylı olmayan hərfdə düyməni ümumiyyətlə göstərmirik (gotcha 6).
    final hasAudio = AppConfig.hasLetterAudio(letter);
    final paragraphs =
        description
            .split('\n')
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty)
            .toList();
    final bodyStyle = ElifbaTypography.textTheme.bodyMedium!.copyWith(
      color: ElifbaPalette.onSurface,
    );
    final titleStyle = ElifbaTextStyles.infoCardTitle.copyWith(
      color: ElifbaPalette.onSurface,
    );
    final readLabel = '$letter hərfi haqqında oxu';

    final header = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: expanded ? onToggle : null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _headerMinHeight),
        child: Row(
          children: [
            Expanded(
              child: Text(
                expanded ? '$letter hərfi haqqında' : readLabel,
                style: titleStyle,
              ),
            ),
            AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: ElifbaMotion.expand,
              curve: ElifbaMotion.expandCurve,
              child: const Icon(
                Icons.expand_more_rounded,
                size: _chevronSize,
                color: ElifbaPalette.secondary,
              ),
            ),
          ],
        ),
      ),
    );

    final card = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: expanded ? null : onToggle,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: ElifbaCard.section(
          padding: EdgeInsets.fromLTRB(
            hasAudio ? _padLeftWithAudio : _padSide,
            _padTop,
            _padSide,
            expanded ? 16 : _padTop,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity, height: 0),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < paragraphs.length; i++) ...[
                        if (i > 0) const SizedBox(height: 6),
                        Text(paragraphs[i], style: bodyStyle),
                      ],
                    ],
                  ),
                ),
                crossFadeState:
                    expanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                duration: ElifbaMotion.expand,
                sizeCurve: ElifbaMotion.expandCurve,
              ),
            ],
          ),
        ),
      ),
    );

    if (!hasAudio) return card;
    return LayoutBuilder(
      builder:
          (context, box) => Stack(
            clipBehavior: Clip.none,
            children: [
              card,
              // Açıq kartda düymə yuxarıdan 8 dp-dədir (maket `top: 8px`),
              // bağlı kartda kartın ortasında (`top: 50%`). Hər iki halda
              // EYNİ `AnimatedPositioned`-dir: element (və pleyer) qalır.
              AnimatedPositioned(
                left: 8,
                top:
                    expanded
                        ? 8
                        : _collapsedAudioTop(
                          context,
                          box.maxWidth,
                          readLabel,
                          titleStyle,
                        ),
                duration: ElifbaMotion.expand,
                curve: ElifbaMotion.expandCurve,
                child: _LetterAudioButton(letter: letter),
              ),
            ],
          ),
    );
  }

  static const double _padLeftWithAudio = 72;
  static const double _padSide = 14;
  static const double _padTop = 12;
  static const double _headerMinHeight = 40;
  static const double _chevronSize = 28;

  /// Bağlı kartda düymənin yuxarı kənarı: kartın (= başlığın) ortası − 24.
  ///
  /// Bağlı kartın hündürlüyü başlıqdan asılıdır: 1.3x mətndə «Ğ hərfi
  /// haqqında oxu» iki sətrə düşür və kart 64 deyil, ~82 dp olur. Düyməni
  /// kartın öz hündürlüyünə bağlamaq (`bottom: 8` + `Align`) olmur: bağlanan
  /// anda kart hələ açıq hündürlükdədir və düymə onun ortasına sıçrayardı.
  /// Ona görə başlığın hündürlüyü eyni üslubla ölçülür.
  static double _collapsedAudioTop(
    BuildContext context,
    double cardWidth,
    String label,
    TextStyle style,
  ) {
    const fallback = 8.0;
    final textWidth =
        cardWidth - _padLeftWithAudio - _padSide - _chevronSize;
    if (!textWidth.isFinite || textWidth <= 0) return fallback;
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: DefaultTextStyle.of(context).style.merge(style),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: textWidth);
    final headerH = math.max(_headerMinHeight, painter.height);
    painter.dispose();
    return _padTop + headerH / 2 - ElifbaSize.audioM / 2;
  }
}

/// Hərfin səsləndirmə düyməsi (48 dp, nəqletmə kanalı). Görünüş ortaq
/// [AudioButton]-dandır; pleyer, "oxuyur" bayrağı və `onCompleted` burada
/// qalır (gotcha 5, 6, 15).
class _LetterAudioButton extends StatefulWidget {
  const _LetterAudioButton({required this.letter});

  final String letter;

  @override
  State<_LetterAudioButton> createState() => _LetterAudioButtonState();
}

class _LetterAudioButtonState extends State<_LetterAudioButton> {
  bool _isPlaying = false;
  final GatedPlayer _audioPlayer = GatedPlayer(SoundChannel.narration);
  StreamSubscription<void>? _completed;

  @override
  void initState() {
    super.initState();
    // Səs bitdikdə düymə yenidən "Səsləndir" olsun.
    _completed = _audioPlayer.onCompleted.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  void dispose() {
    _completed?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playLetterSound() async {
    final audioPath = AppConfig.letterAudioPath(widget.letter);
    // Susdurulmuş kanalda `play()` heç nə çalmır — bayrağı qaldırsaydıq
    // `completed` hadisəsi gəlməyəcəyi üçün düymə əbədi "Dayandır" vəziyyətində
    // ilişərdi. Düymə onsuz da sönük göstərilir, bura təhlükəsizlik qatıdır.
    if (_audioPlayer.isMuted) return;
    setState(() => _isPlaying = true);
    try {
      await _audioPlayer.setAsset(audioPath);
      await _audioPlayer.play();
    } catch (e) {
      // Fayl yoxdursa və ya oxunmursa düymə "dayandır" vəziyyətində ilişməsin.
      debugPrint('Hərf səsi oxunmadı ($audioPath): $e');
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  Future<void> _onPressed() async {
    if (_isPlaying) {
      await _audioPlayer.stop();
      if (mounted) setState(() => _isPlaying = false);
    } else {
      await _playLetterSound();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Səs ayarı dəyişəndə düymə də dəyişməlidir: susdurulmuş kanalda işləməyən
    // parlaq düymə uşağı çaşdırır — sönük göstərmək nə üçün səs gəlmədiyini
    // izah edir (gotcha 6-nın mute-a genişləndirilməsi).
    return AnimatedBuilder(
      animation: AppSettings.instance,
      builder:
          (context, _) => AudioButton(
            state: audioStateOf(
              muted: _audioPlayer.isMuted,
              playing: _isPlaying,
            ),
            onPressed: _onPressed,
            size: ElifbaSize.audioM,
          ),
    );
  }
}

// --------------------------------------------------------- «Heyvanlar» sətri

/// «Heyvanlar» + hərfin tərəqqisi (zolaq, ulduzlar, «n/m» / «Tamam!»).
///
/// Hündürlüyü 36 dp-dir (ən hündür element 24 dp-lik başlıqdır). Store-a özü
/// qoşulmur — səhifə store-u dinləyib bütün alt ağacı yenidən qurur.
/// `Text('Heyvanlar')` və sayğac EYNİ `Row`-un birbaşa uşaqlarıdır; dar
/// ekranda da sayğac «Heyvanlar»-ın ilk `Row` əcdadının içindədir
/// (`star_ui_test` buna söykənir).
///
/// Dar ekranda (320 dp — Android «Ekran ölçüsü: böyük» — və 1.3x mətn) sabit
/// elementlər (başlıq, ulduzlar, «Tamam!») sətrə sığmır və zolağa yer qalmır:
/// onda başlıq yuxarı sətrə, tərəqqi aşağı sətrə keçir. Sətir scroll-un
/// içindədir, artıq hündürlük qridi yalnız aşağı itələyir (gotcha 13).
class _AnimalsHeadingRow extends StatelessWidget {
  const _AnimalsHeadingRow({required this.letter});

  final String letter;

  static const double _gap = 10;
  static const double _starSize = 18;
  static const double _checkGap = 3;

  /// Zolağın ən kiçik eni; bundan dar zolaq tərəqqini göstərmir.
  static const double _minBarWidth = 24;

  static double _textWidth(
    BuildContext context,
    String text,
    TextStyle style,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: DefaultTextStyle.of(context).style.merge(style),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  @override
  Widget build(BuildContext context) {
    final store = ProgressStore.instance;
    final total = store.letterTotal(letter);
    final done = store.letterDone(letter);
    final complete = total > 0 && done >= total;
    final titleStyle = ElifbaTypography.textTheme.titleMedium!.copyWith(
      color: ElifbaPalette.onSurface,
    );
    final title = Text('Heyvanlar', style: titleStyle);
    // Əlifbada olmayan hərf (praktikada baş vermir) — "0/0" yazılmır.
    if (total == 0) {
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 36),
        child: Row(children: [title]),
      );
    }

    final counterLabel = complete ? 'Tamam!' : '$done/$total';
    final counterStyle = ElifbaTextStyles.counter.copyWith(
      color:
          complete
              ? ElifbaPalette.onCorrectContainer
              : ElifbaPalette.onSurfaceVariant,
    );
    final counter =
        complete
            ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: _starSize,
                  color: ElifbaPalette.correct,
                ),
                const SizedBox(width: _checkGap),
                Text(counterLabel, style: counterStyle),
              ],
            )
            : Text(counterLabel, style: counterStyle);
    final progress = <Widget>[
      Expanded(
        child: ElifbaProgressBar(value: done / total, complete: complete),
      ),
      const SizedBox(width: _gap),
      StarRow(filled: store.starsOf(letter), size: _starSize),
      const SizedBox(width: _gap),
      counter,
    ];

    return LayoutBuilder(
      builder: (context, box) {
        final fixed =
            _textWidth(context, 'Heyvanlar', titleStyle) +
            _gap * 3 +
            _starSize * ProgressStore.maxStarsPerLetter +
            (complete ? _starSize + _checkGap : 0) +
            _textWidth(context, counterLabel, counterStyle);
        if (box.maxWidth >= fixed + _minBarWidth) {
          return ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36),
            child: Row(
              children: [title, const SizedBox(width: _gap), ...progress],
            ),
          );
        }
        // Dar ekran. Xarici `Row` test tutacağını saxlayır: «Heyvanlar»-ın
        // ilk `Row` əcdadında sayğac da var.
        return Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 36),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: 1,
                      child: title,
                    ),
                  ),
                  Row(children: progress),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ------------------------------------------------------------- heyvan kartı

/// Heyvan kartı: səhnədə şəkil, ad və üç ulduz. Üç ulduzlu kart qızılı olur.
///
/// Çərçivə `Squishy`-nin tək `AnimatedContainer`-idir — kartın içində başqa
/// `AnimatedContainer` olmamalıdır (`widget_test` `_cardOf` buna söykənir).
/// Ad və `StarRow` eyni `Column`-dadır (`star_ui_test`).
class _AnimalCard extends StatelessWidget {
  const _AnimalCard({
    required this.animal,
    required this.imageAsset,
    required this.stars,
    required this.onTap,
  });

  final String animal;
  final String imageAsset;
  final int stars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final complete = stars == ProgressStore.maxStarsPerLetter;
    return Squishy(
      onTap: onTap,
      borderRadius: const BorderRadius.all(Radius.circular(ElifbaRadius.r28)),
      color: complete ? ElifbaPalette.complete : ElifbaPalette.surface,
      ringWidth: ElifbaRing.normal,
      ringColor:
          complete ? ElifbaPalette.completeEdge : ElifbaPalette.outlineVariant,
      edge: ElifbaEdge.e6,
      edgeColor: complete ? ElifbaPalette.completeEdge : ElifbaPalette.outline,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      child: Column(
        children: [
          Expanded(
            // Səhnə tam kartda da lavanda qalır (ScreenLetter); tamamlanma
            // kartın qızılı üzündən və üç ulduzdan bilinir.
            child: AnimalStage(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.contain,
                  cacheWidth: kAnimalThumbDecodeWidth,
                  frameBuilder: (
                    context,
                    child,
                    frame,
                    wasSynchronouslyLoaded,
                  ) {
                    if (wasSynchronouslyLoaded) return child;
                    return AnimatedOpacity(
                      opacity: frame == null ? 0 : 1,
                      duration: ElifbaMotion.imageFadeIn,
                      child: child,
                    );
                  },
                  errorBuilder:
                      (context, error, stackTrace) => const ImagePlaceholder(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: SizedBox(
              height: 22,
              // Uzun adlar (Qarışqayeyən) kəsilmir, kiçilir.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  animal,
                  maxLines: 1,
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: ElifbaTextStyles.cardName.copyWith(
                    color: ElifbaPalette.onSurface,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          StarRow(filled: stars, size: 20, spacing: 1),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- yazı kartı

/// Qridin ilk xanası: hərfi yazma oyununa giriş.
///
/// Söz yazılmır: kartın ÖZÜ hərfin cızılmamış halıdır — ağ "yol", üstündə
/// kəsik orta xətt və birinci ştrixin başlanğıcında nömrəli yaşıl nöqtə. Uşaq
/// oyunda məhz bunu görəcək, ona görə kart nə vəd etdiyini mətnsiz anladır.
/// Bənövşəyi fon və qırıq çərçivə onu heyvan kartlarından ayırır.
///
/// `Semantics` ən xaricidir və uşaq semantikasını atır: etiket DƏQİQ
/// «A hərfini yaz» olur (`widget_test` `_writeCardOf`). Kartda tək
/// `AnimatedContainer` var — `Squishy`-nin çərçivəsi.
class _WriteLetterCard extends StatelessWidget {
  const _WriteLetterCard({
    required this.letter,
    required this.written,
    required this.onTap,
  });

  final String letter;

  /// Yazma tək tapşırıqdır, ona görə üç ulduz yerinə bir ulduz.
  final bool written;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final units = LetterStrokes.unitsFor(letter);
    return Semantics(
      container: true,
      button: true,
      excludeSemantics: true,
      label: '$letter hərfini yaz',
      onTap: onTap,
      child: Squishy(
        onTap: onTap,
        color: ElifbaPalette.secondaryContainer,
        borderRadius: const BorderRadius.all(Radius.circular(ElifbaRadius.r28)),
        pressDepth: 3,
        child: CustomPaint(
          foregroundPainter: const DashedRRectPainter(
            color: ElifbaPalette.secondary,
            strokeWidth: ElifbaRing.dashed,
            radius: ElifbaRadius.r28,
          ),
          // CSS `box-sizing: border-box`: 10 dp boşluq 2.5 dp qırıq xəttin
          // İÇİNDƏN ölçülür, nişan da (`top/right: 10`) xəttin içindən.
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: const EdgeInsets.all(10 + ElifbaRing.dashed),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: SizedBox(
                        width: 110,
                        height: 120,
                        child:
                            units == null
                                // Ştrix datası olmayan hərf üçün ehtiyat:
                                // praktikada bura düşülmür — kart yalnız
                                // `LetterStrokes.has()` doğru olanda qurulur.
                                ? Center(
                                  child: Text(
                                    letter,
                                    style: const TextStyle(
                                      fontFamily: ElifbaTypography.display,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 72,
                                      height: 1,
                                      color: ElifbaPalette.traceCentre,
                                    ),
                                  ),
                                )
                                : CustomPaint(
                                  painter: _TraceGlyphPainter(units: units),
                                ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StarGlyph(filled: written, size: 22),
                        const SizedBox(width: 6),
                        Text(
                          'Yaz',
                          style: ElifbaTypography.textTheme.labelLarge!
                              .copyWith(color: ElifbaPalette.onSurface),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Positioned(
                top: 10 + ElifbaRing.dashed,
                right: 10 + ElifbaRing.dashed,
                child: _DrawBadge(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Yazı kartının küncündəki 30 dp bənövşəyi nişan.
class _DrawBadge extends StatelessWidget {
  const _DrawBadge();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ElifbaPalette.secondary,
      ),
      child: SizedBox.square(
        dimension: 30,
        child: Icon(Icons.draw_rounded, size: 18, color: ElifbaPalette.surface),
      ),
    );
  }
}

/// Hərfi "hələ cızılmamış" halda çəkir: xətt dəftərinin iki sətri, ağ yol,
/// kəsik orta xətt və "1" yazılmış başlanğıc nöqtəsi. `TracingCanvas`-ın
/// kiçildilmiş, statik variantıdır — eyni [LetterStrokes] datasından
/// qidalanır, ona görə kartda görünən forma oyunda görünənlə həmişə eynidir.
///
/// Maketin 110 × 120 qutusunda xətt dəftərinin iki sətri `y = 22` (yuxarı
/// sətir) və `y = 100`-dür (əsas xətt); hərf qutusu (100 × 104) elə
/// miqyaslanır ki, [kCapLine] / [kBaseLine] məhz bu sətirlərə düşsün, və
/// üfüqi mərkəzləşir. Diakritika və quyruqlar ([kDescLine]-ə qədər) yenə
/// qutunun içində qalır.
///
/// Qalınlıqlar dp ilə verilir (`canvas.scale`-dən sonra `/ s`): 78 dp-lik
/// hərfdə yol 17 dp (DS kartı: 82 dp hərfdə 18), nöqtə 8 dp (maket).
///
/// Məlum məhdudiyyət: `İ`-nin nöqtəsi (50, 12) gövdənin başlanğıcına (50, 20)
/// çox yaxındır — gövdənin yuvarlaq ucu nöqtənin mərkəzindən o yana çatır,
/// ona görə nöqtə gövdəyə yapışır və «1» nişanının altında qalır. Nöqtənin
/// radiusunu kiçiltmək arada boşluq açmır; düzəliş [LetterStrokes] datasındadır
/// (oyunla birgə), kartda ayrıca yer dəyişmək kartı oyundan ayırardı.
class _TraceGlyphPainter extends CustomPainter {
  const _TraceGlyphPainter({required this.units});

  final List<TraceUnit> units;

  @override
  void paint(Canvas canvas, Size size) {
    if (units.isEmpty) return;

    // Xətt dəftəri maketdəki yerində: 22 / 120 və 100 / 120.
    final capY = size.height * 22 / 120;
    final baseY = size.height * 100 / 120;
    final s = (baseY - capY) / (kBaseLine - kCapLine);
    final dx = (size.width - kGlyphBox.width * s) / 2;
    final dy = capY - kCapLine * s;

    // 1. Xətt dəftəri: yuxarı sətir və əsas xətt (dp ilə).
    final rule =
        Paint()
          ..isAntiAlias = true
          ..color = ElifbaPalette.playingEdge;
    canvas.drawLine(
      Offset(6, capY),
      Offset(size.width - 6, capY),
      rule..strokeWidth = 1,
    );
    canvas.drawLine(
      Offset(6, baseY),
      Offset(size.width - 6, baseY),
      rule..strokeWidth = 1.5,
    );

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(s);

    // 2. Yol.
    final road =
        Paint()
          ..isAntiAlias = true
          ..style = PaintingStyle.stroke
          ..strokeWidth = 17 / s
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = ElifbaPalette.surface;
    final roadDot =
        Paint()
          ..isAntiAlias = true
          ..color = ElifbaPalette.surface;
    for (final u in units) {
      if (u.kind == TraceUnitKind.stroke) {
        canvas.drawPath(u.partialPath(1), road);
      } else {
        canvas.drawCircle(u.start, 8.5 / s, roadDot);
      }
    }

    // 3. Kəsik orta xətt.
    final centre =
        Paint()
          ..isAntiAlias = true
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 / s
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = ElifbaPalette.traceCentre;
    final centreDot =
        Paint()
          ..isAntiAlias = true
          ..color = ElifbaPalette.traceCentre;
    for (final u in units) {
      if (u.kind == TraceUnitKind.stroke) {
        canvas.drawPath(
          dashPath(
            u.partialPath(1),
            dashArray: CircularIntervalList<double>([4 / s, 5 / s]),
          ),
          centre,
        );
      } else {
        canvas.drawCircle(u.start, 2 / s, centreDot);
      }
    }
    canvas.restore();

    // 4. Birinci ştrixin başlanğıcı: "buradan başla" (dp ilə).
    for (final u in units) {
      if (u.kind != TraceUnitKind.stroke) continue;
      final p = Offset(dx + u.start.dx * s, dy + u.start.dy * s);
      canvas.drawCircle(
        p,
        8,
        Paint()
          ..isAntiAlias = true
          ..color = ElifbaPalette.correct,
      );
      final tp = TextPainter(
        text: const TextSpan(
          text: '1',
          style: TextStyle(
            fontFamily: ElifbaTypography.display,
            fontWeight: FontWeight.w700,
            fontSize: 10,
            height: 1,
            color: ElifbaPalette.surface,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
      tp.dispose();
      break;
    }
  }

  @override
  bool shouldRepaint(_TraceGlyphPainter old) => old.units != units;
}

// ---------------------------------------------------------- boş hərf kartı

/// Heyvanı olmayan hərfin izahı: yatan günəş + mətn. Basılmır, kənarı yoxdur.
class _EmptyLetterCard extends StatelessWidget {
  const _EmptyLetterCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ElifbaCard(
      radius: ElifbaRadius.r24,
      edge: ElifbaEdge.e0,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          const SunMascot.sleepy(size: 72, cloudColor: ElifbaPalette.stageSky),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: ElifbaTextStyles.emptyState.copyWith(
                color: ElifbaPalette.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
