import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../core/config.dart';
import '../core/progress.dart';
import '../core/settings.dart';
import '../core/sound.dart';
import '../core/utils.dart';
import '../theme/theme.dart';
import '../widgets/audio_button.dart';
import '../widgets/celebration.dart';
import '../widgets/elifba_card.dart';
import '../widgets/elifba_confetti.dart';
import '../widgets/food_chip.dart';
import '../widgets/game_feedback.dart';
import '../widgets/icon_buttons.dart';
import '../widgets/pill_button.dart';
import '../widgets/pill_tab.dart';
import '../widgets/sky_background.dart';
import '../widgets/squishy.dart';
import '../widgets/star_row.dart';
import 'puzzle_page.dart';

/// Şəkil dekod ölçüləri. Mənbə fayllar 256–600 px arasındadır: heyvan şəkilləri
/// 400x400 WebP, yem şəkilləri 256x256 WebP, pazl kəsikləri 600x600 JPEG (ən
/// böyüyü ~1.4 MB RAM). `cacheWidth` şəkli böyütmür, yalnız lazımsız böyükləri
/// kiçildir — mənbədən böyük dəyər faydasızdır, üstəlik ayrıca image-cache
/// açarı yaradır.
///
/// Yem şəkilləri üç yerdə (çipin diski, uçan disk, heyvanın üstündəki "pop")
/// göstərilir — hamısı EYNİ ölçü ilə dekod olunur ki, image cache-də hər yem
/// üçün bir dəfə saxlanılsın.
// Heyvan şəkilləri 400x400-dür: 800 heç vaxt çatmır (cacheWidth böyütmür), amma
// qrid xanası (400) ilə fərqli image-cache açarı yaradıb eyni şəkli iki dəfə
// saxlayırdı.
const int kAnimalHeroDecodeWidth = 400;
// Yem şəkilləri 256 px WebP-dir; ən böyük göstərim 44 dp x 1.15 miqyas, yəni 3x
// sıxlıqda ~150 fiziki px — 256 tam örtür.
const int kFoodDecodeWidth = 256;

/// Pazl şəklinin böyük baxışı (miniatürü basıb saxlayanda), yalnız dekod
/// olunmuş `ui.Image` hələ hazır deyilsə işlənir (`puzzle_page.dart`).
const int kPuzzlePreviewDecodeWidth = 700;

/// Səhifənin bölmələri. Tablar radio qrupudur: həmişə dəqiq biri seçilidir.
enum _Section { info, foods, word, puzzle }

class AnimalDetailPage extends StatefulWidget {
  final String animal;
  final List<String> animals;
  final int currentIndex;

  /// Progres store-u. Defolt qlobal [ProgressStore.instance]-dır; widget
  /// testləri buraya `ProgressStore.forTesting()` verib singleton-un vəziyyətini
  /// çirkləndirmədən yoxlaya bilir (`LetterWritingPage` ilə eyni pattern).
  final ProgressStore? store;

  const AnimalDetailPage({
    super.key,
    required this.animal,
    required this.animals,
    required this.currentIndex,
    this.store,
  });

  @override
  State<AnimalDetailPage> createState() => _AnimalDetailPageState();
}

class _AnimalDetailPageState extends State<AnimalDetailPage>
    with TickerProviderStateMixin {
  // İzah və heyvan səsi AYRI pleyerlərdədir. İki səbəb: fərqli səs kanallarına
  // aiddirlər (biri "İzah", digəri "Heyvan səsləri" ayarı ilə söndürülür), və
  // ayrı pleyer sayəsində heyvan səsinə basmaq artıq izahı yarıda kəsmir.
  final GatedPlayer _infoPlayer = GatedPlayer(SoundChannel.narration);
  final GatedPlayer _animalPlayer = GatedPlayer(SoundChannel.animal);
  bool isPlayingInfo = false;

  /// Açıq bölmə. Defolt "Məlumat"-dır; seçilməmiş bölmənin widget-i qurulmur
  /// (söz tapmaca və pazl hər açılışda yenidən qarışdırılır — bu günkü kimi).
  _Section _section = _Section.info;

  /// Səhnə + yapışqan tablar + bölmə bir `CustomScrollView`-dadır.
  final ScrollController _scroll = ScrollController();

  /// Tab zolağı üfüqi sürüşür (360 dp-də, uzun etiketlərdə 412-də də): seçilmiş
  /// tab həmişə görünən yerə gətirilir, yoxsa uşaq hansının seçildiyini görmür.
  final ScrollController _tabScroll = ScrollController();
  final Map<_Section, GlobalKey> _tabKeys = {};

  /// Söz tapmaca qələbəsi (1.2 s) və "Tam ulduz!" (2 s) konfetiləri.
  final ConfettiController _smallConfetti =
      ConfettiPreset.small.createController();
  final ConfettiController _bigConfetti = ConfettiPreset.big.createController();

  // --- Qidalandırma animasiyası ---
  final Map<String, GlobalKey> _foodKeys = {};
  final GlobalKey _animalImageKey = GlobalKey();
  OverlayEntry? _foodOverlayEntry;
  bool _foodEffectActive = false;

  /// Uçuş (900 ms) və çatma (400 ms; azaldılmış hərəkətdə 600 ms) State-in
  /// özünə məxsusdur və `dispose()`-da atılır: səhifə uçuşun ortasında
  /// bağlansa "aktiv Ticker" xətası olmasın, overlay qalmasın.
  late final AnimationController _flightCtrl;
  late final AnimationController _arrivalCtrl;

  /// Şəkli uçan (və ya azaldılmış hərəkətdə heyvanın üstündə görünən) qida —
  /// onun çipindəki disk solğun göstərilir.
  String? _dimmedFood;

  /// Heyvanın üstündə "pop" edən qidanın şəkli və diskinin rəngi.
  String? _arrivalImage;
  Color _arrivalTint = ElifbaPalette.foodDiscTints.first;
  bool _arrivalReduced = false;

  bool showCongrats = false;

  /// Təbrik pəncərəsi "tam ulduz" mesajını göstərsinmi (söz tapmacası qalibiyyəti
  /// deyil, heyvanın BÜTÜN bölmələrinin bitməsi).
  bool _congratsIsFullStar = false;

  /// Bu səhifə açıq olduğu müddətdə tam-ulduz təbriki bir dəfə göstərilir.
  bool _fullStarShown = false;

  ProgressStore get _store => widget.store ?? ProgressStore.instance;

  /// Bölməni qeyd edir və səhifəni yeniləyir.
  ///
  /// Bu səhifə store-a `AnimatedBuilder` ilə qoşulmur: bütün qeydlər səhifənin
  /// ÖZ callback-lərindən gəlir, ona görə adi `setState` kifayətdir və tablar
  /// (build içində qurulur) təzə dəyərlərlə yenidən yaranır.
  void _mark(Activity activity) {
    _store.markDone(widget.animal, activity);
    if (!mounted) return;
    setState(() {});
    _maybeCelebrateFullStar();
  }

  /// Heyvanın bütün bölmələri bitibsə tam-ulduz təbrikini göstərir.
  void _maybeCelebrateFullStar() {
    if (_fullStarShown) return;
    final total = _store.animalTotal(widget.animal);
    if (total <= 0 || _store.animalDone(widget.animal) < total) return;
    _fullStarShown = true;
    setState(() {
      _congratsIsFullStar = true;
      showCongrats = true;
    });
    if (!AppSettings.instance.reduceMotion) {
      _bigConfetti.play();
    }
  }

  /// Təbriki bağlayır. Konfeti controller-ləri də dayandırılır: əks halda
  /// `playing` vəziyyətində qalır və növbəti təbrikin `ConfettiWidget`-i
  /// (məsələn "Hərəkəti azalt" artıq açıq olanda) özbaşına oynayardı.
  void _closeCongrats() {
    _smallConfetti.stop();
    _bigConfetti.stop();
    setState(() => showCongrats = false);
  }

  @override
  void initState() {
    super.initState();
    _flightCtrl = AnimationController(
      vsync: this,
      duration: ElifbaMotion.foodFlight,
    );
    _arrivalCtrl = AnimationController(
      vsync: this,
      duration: ElifbaMotion.foodArrival,
    );

    // Heyvan ƏVVƏLKİ baxışlarda artıq tamamlanıbsa təbrik göstərilmir: əks halda
    // bitmiş heyvanı hər açanda "Tam ulduz!" pəncərəsi qarşıya çıxır, çünki
    // `Activity.info` ilk kadrda yenidən qeyd olunur. Təbrik yalnız bu baxışda
    // son bölmə bitəndə görünür.
    final total = _store.animalTotal(widget.animal);
    _fullStarShown = total > 0 && _store.animalDone(widget.animal) >= total;

    // Səs bitdikdə isPlayingInfo-nu false et
    _infoPlayer.onCompleted.listen((_) {
      if (mounted) setState(() => isPlayingInfo = false);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // "Məlumat" bölməsi defolt açıq qurulur, yəni heyvanı açmaq həmin
      // bölməyə keçmək deməkdir — ilk kadrdan sonra onu tamamlanmış sayırıq.
      // Qulaq asmaq tələb olunmur (səs ulduza daxil deyil).
      // Qeyd ilk kadrdan SONRA edilir: `markDone` `notifyListeners()` çağırır və
      // valideyn siyahı səhifəsindəki `AnimatedBuilder` build fazasında
      // `setState` almasın.
      _mark(Activity.info);

      final animalLetter = getFirstLetter(widget.animal);
      final animalData = AppConfig.findAnimal(animalLetter, widget.animal);
      final imageAsset = animalData?.imagePath ?? '';
      if (imageAsset.isNotEmpty) {
        precacheImage(
          ResizeImage(AssetImage(imageAsset), width: kAnimalHeroDecodeWidth),
          context,
        );
      }
      final foods = animalData?.foods ?? [];
      for (final food in foods) {
        precacheImage(
          ResizeImage(
            AssetImage(_foodImagePath(food)),
            width: kFoodDecodeWidth,
          ),
          context,
        );
      }
    });
  }

  @override
  void dispose() {
    _removeFoodOverlay();
    _flightCtrl.dispose();
    _arrivalCtrl.dispose();
    _scroll.dispose();
    _tabScroll.dispose();
    _infoPlayer.dispose();
    _animalPlayer.dispose();
    _smallConfetti.dispose();
    _bigConfetti.dispose();
    super.dispose();
  }

  static String _foodImagePath(String food) =>
      'assets/foods/${AppConfig.normalizeFileName(food)}.webp';

  /// Heyvanın öz səsi — izahdan AYRI pleyerdə, ona görə izahı kəsmir.
  Future<void> _playAnimalSound(String audioAsset) async {
    try {
      await _animalPlayer.setAsset(audioAsset);
      await _animalPlayer.play();
    } catch (e) {
      debugPrint('Heyvan səsi oxunmadı ($audioAsset): $e');
    }
  }

  void _toggleAnimalInfo(String animal) async {
    final animalLetter = getFirstLetter(animal);
    final animalInfo = AppConfig.findAnimal(animalLetter, animal);
    if (animalInfo == null) return;
    final audioAsset = animalInfo.audioPath;

    if (isPlayingInfo) {
      setState(() => isPlayingInfo = false);
      await _infoPlayer.stop();
      return;
    }

    // Susdurulmuş kanalda bayrağı QALDIRMIRIQ: heç nə çalınmadığı üçün
    // `completed` hadisəsi gəlməyəcək və düymə əbədi "Dayandır" qalardı.
    // Düymə onsuz da sönük göstərilir, bura yalnız təhlükəsizlik qatıdır.
    if (_infoPlayer.isMuted) return;

    setState(() => isPlayingInfo = true);
    await _infoPlayer.stop();
    try {
      await _infoPlayer.setAsset(audioAsset);
      final started = await _infoPlayer.play();
      if (!started && mounted) setState(() => isPlayingInfo = false);
    } catch (e) {
      // Səs faylı tapılmadısa isPlayingInfo-nu false et
      if (mounted) setState(() => isPlayingInfo = false);
      debugPrint('Səs faylı oxunma xətası: $e');
    }
  }

  void _removeFoodOverlay() {
    // `OverlayEntry` ChangeNotifier-dir: çıxarılandan sonra atılmalıdır.
    _foodOverlayEntry
      ?..remove()
      ..dispose();
    _foodOverlayEntry = null;
  }

  /// Qida çipdən heyvana qövs üzrə uçur (900 ms), heyvanın üstündə "pop" edir
  /// və sarı parıltı sönür (400 ms). Azaldılmış hərəkətdə uçuş yoxdur: qida
  /// heyvanın üstündə 200 ms görünür, 200 ms qalır, 200 ms itir.
  ///
  /// Qida yalnız effekt BİTƏNDƏN sonra sayılır. Effekt gedərkən başqa çipə
  /// toxunmaq nəzərə alınmır (`_foodEffectActive`).
  void _animateFoodToAnimal(
    String food,
    String foodImagePath,
    Color tint,
  ) async {
    if (_foodEffectActive) return;
    final discBox =
        _foodKeys[food]?.currentContext?.findRenderObject() as RenderBox?;
    final animalBox =
        _animalImageKey.currentContext?.findRenderObject() as RenderBox?;
    if (discBox == null || animalBox == null) return;
    _foodEffectActive = true;
    // Ayar toxunuş anında oxunur.
    final reduced = ElifbaMotion.reduced;

    if (!reduced) {
      final overlay = Overlay.of(context);
      final overlayBox = overlay.context.findRenderObject() as RenderBox?;
      Offset toOverlay(Offset global) =>
          overlayBox == null ? global : overlayBox.globalToLocal(global);
      final start = discBox.localToGlobal(discBox.size.center(Offset.zero));
      var end = animalBox.localToGlobal(animalBox.size.center(Offset.zero));
      // Səhnə qismən yuxarı sürüşübsə (heyvanın mərkəzi üst panelin altında
      // gizlənib) qida yenə görünən yerə — sürüşən sahənin yuxarı kənarına,
      // heyvanın yaxınlığına enir. Əvvəlcədən sürüşdürmə yoxdur.
      final viewport =
          _scroll.hasClients
              ? _scroll.position.context.storageContext.findRenderObject()
              : null;
      if (viewport is RenderBox && viewport.attached) {
        final minY =
            viewport.localToGlobal(Offset.zero).dy + ElifbaSize.chipImage / 2;
        if (end.dy < minY) end = Offset(end.dx, minY);
      }
      setState(() => _dimmedFood = food);
      _foodOverlayEntry = OverlayEntry(
        builder:
            (context) => _FoodFlyer(
              animation: _flightCtrl,
              start: toOverlay(start),
              end: toOverlay(end),
              imagePath: foodImagePath,
              tint: tint,
            ),
      );
      overlay.insert(_foodOverlayEntry!);
      // Səhifə uçuş zamanı bağlansa controller `dispose()`-da atılır və bu
      // gözləmə heç vaxt bitmir — qida sayılmır.
      await _flightCtrl.forward(from: 0);
      _removeFoodOverlay();
      if (!mounted) return;
    }

    _arrivalCtrl.duration =
        reduced ? ElifbaMotion.foodReducedTotal : ElifbaMotion.foodArrival;
    setState(() {
      _dimmedFood = reduced ? food : null;
      _arrivalImage = foodImagePath;
      _arrivalTint = tint;
      _arrivalReduced = reduced;
    });
    await _arrivalCtrl.forward(from: 0);
    _foodEffectActive = false;
    // Qida yalnız heyvana ÇATANDAN sonra sayılır — animasiya yarıda kəsilsə
    // (səhifə bağlanıb) qeyd edilmir.
    if (!mounted) return;
    setState(() {
      _dimmedFood = null;
      _arrivalImage = null;
    });
    _store.markFoodFed(widget.animal, food);
    setState(() {});
    _maybeCelebrateFullStar();
  }

  /// Səhnənin hündürlüyü: 16:9, ən çox 320 dp (eni planşet/landşaftda
  /// səhnə bütün ekranı tutmasın). Səhnənin şaquli boşluğu yoxdur.
  ///
  /// Üstəlik sürüşən sahənin (üst paneldən aşağı) yapışqan tablardan sonra
  /// qalan hissəsinin ən çox 60 %-i, ən azı 120 dp. Landşaft telefonda
  /// (640x360) 16:9 səhnə bütün sahəni tuturdu: tablar, ulduz nişanı və
  /// bölmə ekrandan kənarda qalırdı, uşağın isə sürüşdürmək üçün heç bir
  /// işarəsi yox idi. 360x640 və 412x915-də heç nə dəyişmir (189 / 218 dp);
  /// 800x600 test səthində 320 → 280 dp.
  double _stageHeight(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final vp = MediaQuery.viewPaddingOf(context);
    final width = size.width - vp.left - vp.right - 24;
    final viewport = size.height - vp.top - vp.bottom - ElifbaSize.toolbar;
    final byHeight = math.max(120.0, (viewport - _TabsHeader.extent) * 0.6);
    return math.max(0, math.min(math.min(width * 9 / 16, 320), byHeight));
  }

  /// Tab seçimi. Radio qaydası: seçilmiş taba yenidən toxunmaq heç nə etmir.
  /// Səhifə səhnədən aşağı sürüşdürülübsə yeni bölmə yapışqan tabların
  /// düz altından başlayır.
  void _select(_Section section) {
    if (section == _section) return;
    final stageExtent = _stageHeight(context);
    setState(() => _section = section);
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealTab(section));
    if (_scroll.hasClients && _scroll.offset > stageExtent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scroll.hasClients) return;
        final position = _scroll.position;
        _scroll.jumpTo(math.min(stageExtent, position.maxScrollExtent));
      });
    }
  }

  /// Seçilmiş tabı zolağın ortasına (kənarlarda kənara) sürüşdürür. Yalnız
  /// üfüqi zolaq hərəkət edir — səhifənin şaquli sürüşməsinə toxunulmur.
  void _revealTab(_Section section) {
    final box = _tabKeys[section]?.currentContext?.findRenderObject();
    if (!mounted || box == null || !_tabScroll.hasClients) return;
    _tabScroll.position.ensureVisible(
      box,
      alignment: 0.5,
      duration:
          ElifbaMotion.reduced
              ? Duration.zero
              : const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Android 16 (API 36) edge-to-edge məcbur edir: sistem panelləri gövdənin
    // üstünə düşür. Fon (qradiyent) panellərin altında da çəkilir, məzmun isə
    // pəncərənin view padding-i qədər içəri çəkilir.
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final animalLetter = getFirstLetter(widget.animal);
    final animalData = AppConfig.findAnimal(animalLetter, widget.animal);
    final imageAsset = animalData?.imagePath ?? '';
    final info =
        animalData?.description ?? 'Bu heyvan haqqında məlumat yoxdur.';
    final foods = animalData?.foods ?? [];
    final hasSound = animalData?.hasSound ?? false;
    final hasPuzzle = animalData?.hasPuzzle ?? false;

    final animalsList = widget.animals;
    final currentIndex = widget.currentIndex;
    final normalizedAnimalName = AppConfig.normalizeFileName(widget.animal);
    final animalSoundAsset =
        'assets/audios/${animalLetter.toLowerCase()}/${normalizedAnimalName}_sound.mp3';

    final tabs = <_TabDef>[
      _TabDef(
        section: _Section.info,
        icon: Icons.auto_stories_rounded,
        label: 'Məlumat',
        done: _store.isDone(widget.animal, Activity.info),
      ),
      if (foods.isNotEmpty)
        _TabDef(
          section: _Section.foods,
          icon: Icons.restaurant_rounded,
          label: 'Qidalar',
          done: _store.isDone(widget.animal, Activity.foods),
        ),
      _TabDef(
        section: _Section.word,
        icon: Icons.abc_rounded,
        label: 'Söz tapmaca',
        done: _store.isDone(widget.animal, Activity.wordPuzzle),
      ),
      // Pazl tabı yalnız map-da true olan heyvanlar üçün.
      if (hasPuzzle)
        _TabDef(
          section: _Section.puzzle,
          icon: Icons.extension_rounded,
          label: 'Pazl',
          done: _store.isDone(widget.animal, Activity.tilePuzzle),
        ),
    ];

    final stageHeight = _stageHeight(context);

    final scaffold = Scaffold(
      backgroundColor: ElifbaPalette.transparent,
      appBar: AppBar(
        toolbarHeight: ElifbaSize.toolbar,
        backgroundColor: ElifbaPalette.transparent,
        surfaceTintColor: ElifbaPalette.transparent,
        foregroundColor: ElifbaPalette.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        forceMaterialTransparency: true,
        notificationPredicate: (_) => false,
        systemOverlayStyle: kElifbaSystemUiStyle,
        automaticallyImplyLeading: false,
        leadingWidth: 58,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ToolbarBackButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        ),
        titleSpacing: 6,
        centerTitle: false,
        titleTextStyle: _titleStyle,
        title: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  widget.animal,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: _titleStyle,
                ),
              ),
              if (hasSound) ...[
                const SizedBox(width: 6),
                // Heyvan səsi kanalı söndürülübsə düymə sönük olur — işləməyən
                // parlaq düymə uşağı çaşdırar.
                AnimatedBuilder(
                  animation: AppSettings.instance,
                  builder: (context, _) {
                    final muted = _animalPlayer.isMuted;
                    return AudioButton(
                      tone: AudioTone.animal,
                      size: ElifbaSize.audioM,
                      state:
                          muted
                              ? AudioButtonState.muted
                              : AudioButtonState.ready,
                      onPressed:
                          muted
                              ? null
                              : () => _playAnimalSound(animalSoundAsset),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
        // Dizayn: 10 dp kənar, 44 dp qutular, aralarında 6 dp. 44 dp-lik
        // chevron 48 dp toxunuş sahəsinə genişlənir (hər tərəfdən 2 dp), ona
        // görə kənar 8, ara 2 — mərkəzlər dizayndakı kimi (360-da 278 və 328).
        actionsPadding: const EdgeInsets.only(right: 8),
        actions: [
          ToolbarChevron(
            forward: false,
            width: 44,
            tooltip: 'Əvvəlki heyvan',
            onPressed:
                currentIndex > 0
                    ? () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => AnimalDetailPage(
                                animal: animalsList[currentIndex - 1],
                                animals: animalsList,
                                currentIndex: currentIndex - 1,
                              ),
                        ),
                      );
                    }
                    : null,
          ),
          const SizedBox(width: 2),
          ToolbarChevron(
            forward: true,
            width: 44,
            tooltip: 'Növbəti heyvan',
            onPressed:
                currentIndex < animalsList.length - 1
                    ? () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => AnimalDetailPage(
                                animal: animalsList[currentIndex + 1],
                                animals: animalsList,
                                currentIndex: currentIndex + 1,
                              ),
                        ),
                      );
                    }
                    : null,
          ),
        ],
      ),
      // Yalnız üst panel sürüşən sahədən kənardadır: səhnə yuxarı sürüşüb
      // gedir, tablar yuxarıda yapışıb qalır, bölmə onların altından axır.
      // Sabit hündürlüklü heç bir sətir scrollable-ın üstündə deyil
      // (gotcha 13) — qısa ekranda daşma yoxdur.
      body: CustomScrollView(
        key: const ValueKey('animalPageScroll'),
        controller: _scroll,
        slivers: [
          SliverToBoxAdapter(
            child: _buildStage(context, imageAsset, stageHeight),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabsHeader(
              child: _buildTabs(context, tabs, viewPadding),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              16 + viewPadding.left,
              4,
              16 + viewPadding.right,
              48 + viewPadding.bottom,
            ),
            sliver: SliverToBoxAdapter(
              child: _buildSection(info: info, foods: foods),
            ),
          ),
        ],
      ),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        // Qradiyent status və nav bar-ın da arxasındadır (gotcha 10).
        SkyBackground(child: scaffold),
        const NavBarFade(),
        // Təbrik üst paneli də örtür, ona görə Scaffold-un üstündədir. Bayraq
        // true olduğu kadrda ağacdadır (giriş yalnız animasiyadır).
        if (showCongrats)
          Positioned.fill(
            child: CelebrationOverlay(
              key: ValueKey<bool>(_congratsIsFullStar),
              card:
                  _congratsIsFullStar
                      ? CelebrationCard.big(
                        title: 'Tam ulduz!',
                        message: '${widget.animal} haqqında hər şeyi öyrəndin!',
                        action: CelebrationAction(
                          label: 'Yaşa!',
                          icon: Icons.thumb_up_rounded,
                          onPressed: _closeCongrats,
                        ),
                      )
                      : const CelebrationCard.small(),
              onDismiss: _closeCongrats,
              // Söz tapmacanın kiçik təbriki istənilən yerə toxunanda bağlanır.
              dismissOnTapAnywhere: !_congratsIsFullStar,
              confetti: ElifbaConfetti(
                controller: _congratsIsFullStar ? _bigConfetti : _smallConfetti,
                preset:
                    _congratsIsFullStar
                        ? ConfettiPreset.big
                        : ConfettiPreset.small,
              ),
            ),
          ),
      ],
    );
  }

  static final TextStyle _titleStyle = ElifbaTypography.textTheme.titleLarge!
      .copyWith(color: ElifbaPalette.onSurface);

  // ------------------------------------------------------------------ səhnə

  Widget _buildStage(BuildContext context, String imageAsset, double height) {
    final vp = MediaQuery.viewPaddingOf(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final stageWidth = math.max(0.0, screenWidth - vp.left - vp.right - 24);
    // Heyvanın qutusu: 150 dp (412-də 180); planşetdə səhnənin hündürlüyü
    // qədər.
    final double picBox =
        screenWidth >= 600
            ? math.max(0.0, height - 22)
            : (screenWidth < ElifbaLayout.largeBreakpoint ? 150 : 180);
    final done = _store.animalDone(widget.animal);
    final total = _store.animalTotal(widget.animal);
    final arrival = _arrivalImage;

    return Padding(
      padding: EdgeInsets.fromLTRB(12 + vp.left, 0, 12 + vp.right, 0),
      child: SizedBox(
        height: height,
        child: AnimalStage(
          radius: ElifbaRadius.r32,
          hill: StageHill.hero,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Qidalandırma parıltısı — heyvanın ARXASINDA.
              if (arrival != null)
                Positioned(
                  left: stageWidth / 2 - 110,
                  top: height / 2 - 110,
                  width: 220,
                  height: 220,
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _arrivalCtrl,
                      builder:
                          (context, child) => Opacity(
                            opacity: _arrivalOpacity(glow: true),
                            child: child,
                          ),
                      child: DecoratedBox(decoration: _glowDecoration),
                    ),
                  ),
                ),
              // Heyvan təpənin üstündə dayanır (qutunun alt mərkəzi). Qutunun
              // açarı uçuşun hədəfidir.
              Positioned(
                top: 12,
                bottom: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    key: _animalImageKey,
                    width: picBox,
                    height: double.infinity,
                    child: Image.asset(
                      imageAsset,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                      cacheWidth: kAnimalHeroDecodeWidth,
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
                          (context, error, stackTrace) =>
                              const ImagePlaceholder(),
                    ),
                  ),
                ),
              ),
              // Çatan qida heyvanın üstündə "pop" edir.
              if (arrival != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _arrivalCtrl,
                        builder:
                            (context, child) => Opacity(
                              opacity: _arrivalOpacity(glow: false),
                              child: Transform.scale(
                                scale: _arrivalScale(),
                                child: child,
                              ),
                            ),
                        child: _FoodDisc(
                          imagePath: arrival,
                          tint: _arrivalTint,
                          ring: 3,
                        ),
                      ),
                    ),
                  ),
                ),
              // Ulduz nişanı layout hündürlüyü tutmur (gotcha 13).
              Positioned(
                right: 10,
                bottom: 10,
                child: IgnorePointer(
                  child: _StarPill(
                    stars: _store.animalStars(widget.animal),
                    done: done,
                    total: total,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Qidalandırma parıltısı: #FFD98A (burst) 85 % → 0, radiusun 70 %-ində
  /// (ScreenAnimal).
  static final BoxDecoration _glowDecoration = BoxDecoration(
    shape: BoxShape.circle,
    gradient: RadialGradient(
      colors: [
        ElifbaPalette.burst.withAlpha(0xD9),
        ElifbaPalette.burst.withAlpha(0),
      ],
      stops: const [0, 0.7],
    ),
  );

  /// Yapışqan tab zolağının fonu: 80 %-ə qədər #F1ECFF, sonra şəffaf —
  /// altından keçən məzmun yumşaq itir.
  static final BoxDecoration _tabStripDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        ElifbaPalette.skyMid,
        ElifbaPalette.skyMid,
        ElifbaPalette.skyMid.withAlpha(0),
      ],
      stops: const [0, 0.8, 1],
    ),
  );

  /// Çatmanın şəffaflığı. Normal: parıltı 1 → 0 (easeOut, bütün 400 ms);
  /// qida ilk 240 ms tam görünür, son 160 ms-də itir. Azaldılmış: hər ikisi
  /// 200 ms görünür, 200 ms qalır, 200 ms itir.
  double _arrivalOpacity({required bool glow}) {
    final t = _arrivalCtrl.value;
    if (_arrivalReduced) {
      final o = t < 1 / 3 ? t * 3 : (t < 2 / 3 ? 1.0 : (1 - t) * 3);
      return o.clamp(0.0, 1.0);
    }
    if (glow) return 1 - Curves.easeOut.transform(t);
    if (t < _popEnd) return 1.0;
    return (1 - (t - _popEnd) / (1 - _popEnd)).clamp(0.0, 1.0);
  }

  double _arrivalScale() =>
      _arrivalReduced ? 1.0 : _popScale.transform(_arrivalCtrl.value);

  /// Uçan disk 0.6-da bitir — "pop" oradan başlayır: 0.6 → 1.15 → 1.
  static final double _popEnd =
      ElifbaMotion.foodArrivalPop.inMilliseconds /
      ElifbaMotion.foodArrival.inMilliseconds;
  static final Animatable<double> _popScale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: ElifbaMotion.foodFlightEndScale,
        end: ElifbaMotion.foodArrivalPopScale,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 50,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: ElifbaMotion.foodArrivalPopScale,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 50,
    ),
  ]).chain(CurveTween(curve: Interval(0, _popEnd)));

  // ------------------------------------------------------------------ tablar

  Widget _buildTabs(
    BuildContext context,
    List<_TabDef> tabs,
    EdgeInsets viewPadding,
  ) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: DecoratedBox(
        decoration: _tabStripDecoration,
        child: SingleChildScrollView(
          controller: _tabScroll,
          scrollDirection: Axis.horizontal,
          // Yuxarıdakı 12 dp ✓ nişanına, aşağıdakı 10 dp seçilmiş tabın 4 dp
          // kənarına yer saxlayır.
          padding: EdgeInsets.fromLTRB(
            12 + viewPadding.left,
            12,
            12 + viewPadding.right,
            10,
          ),
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                PillTab(
                  key: _tabKeys.putIfAbsent(tabs[i].section, GlobalKey.new),
                  label: tabs[i].label,
                  icon: tabs[i].icon,
                  selected: tabs[i].section == _section,
                  done: tabs[i].done,
                  onTap:
                      tabs[i].section == _section
                          ? null
                          : () => _select(tabs[i].section),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- bölmələr

  Widget _buildSection({required String info, required List<String> foods}) {
    switch (_section) {
      case _Section.info:
        return _buildInfoCard(info);
      case _Section.foods:
        if (foods.isEmpty) return const SizedBox.shrink();
        return _buildFoodCard(foods);
      case _Section.word:
        return AnimalWordPuzzle(
          word: widget.animal,
          onWin: () {
            setState(() {
              _congratsIsFullStar = false;
              showCongrats = true;
            });
            if (!AppSettings.instance.reduceMotion) {
              _smallConfetti.play();
            }
            // Qeyd təbrikdən SONRA: bu heyvanın son bölməsi idisə `_mark`
            // üstündən tam-ulduz təbriki göstərəcək və sadə "Təbriklər"-i
            // əvəz edəcək.
            _mark(Activity.wordPuzzle);
          },
        );
      case _Section.puzzle:
        return PuzzlePage(
          animal: widget.animal,
          onCompleted: () => _mark(Activity.tilePuzzle),
        );
    }
  }

  Widget _buildInfoCard(String info) {
    // Təsvirlərdə abzaslar `\n` ilə ayrılır.
    final paragraphs =
        info
            .split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
    final bodyStyle = ElifbaTypography.textTheme.bodyLarge!.copyWith(
      color: ElifbaPalette.onSurface,
    );
    return ElifbaCard.section(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Məlumat:',
                  style: ElifbaTypography.textTheme.titleMedium!.copyWith(
                    color: ElifbaPalette.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // İzah kanalı söndürülübsə düymə sönür və nə üçün işləmədiyini
              // özü deyir.
              AnimatedBuilder(
                animation: AppSettings.instance,
                builder: (context, _) {
                  final muted = _infoPlayer.isMuted;
                  return AudioPillButton(
                    state: audioStateOf(muted: muted, playing: isPlayingInfo),
                    onPressed:
                        muted ? null : () => _toggleAnimalInfo(widget.animal),
                  );
                },
              ),
            ],
          ),
          if (paragraphs.isNotEmpty) ...[
            const SizedBox(height: 12),
            // `stretch` sıx en verir və `ConstrainedBox` onu aşa bilmir —
            // `Align` eni boşaldır, sonra sətir 34 em-ə (612 dp) qədər
            // məhdudlaşır və başlanğıca yapışır (CSS `max-width: 34em`).
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: ElifbaTextStyles.maxLineWidth(bodyStyle),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < paragraphs.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      Text(paragraphs[i], style: bodyStyle),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFoodCard(List<String> foods) {
    final fedFoods = _store.fedFoods(widget.animal);
    return ElifbaCard.section(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Dizayn başlığı `font: 700 18px Comfortaa` ilə verir — CSS-in
          // "normal" sətri (~20 dp), DS-in 24 dp-si yox. 24 ilə çiplər 4 dp
          // aşağı düşürdü (Məlumat kartında başlığı 48 dp-lik sətir saxlayır).
          Text(
            'Qidaları:',
            style: ElifbaTypography.textTheme.titleMedium!.copyWith(
              color: ElifbaPalette.onSurface,
              height: 20 / 18,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < foods.length; i++)
                _buildFoodChip(foods[i], i, fedFoods.contains(foods[i])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFoodChip(String food, int index, bool fed) {
    final key = _foodKeys.putIfAbsent(food, () => GlobalKey());
    final path = _foodImagePath(food);
    final tint = ElifbaPalette.foodDiscTint(index);
    // "Qidalar" bölməsi yalnız HAMISI verildikdə bağlanır, ona görə uşaq
    // hansını verdiyini görməlidir — əks halda 6 qidalı heyvanda qaldığını
    // tapmaq yaddaş oyununa çevrilir. Təkrar vermək qadağan deyil, sadəcə ✓
    // ilə işarələnir.
    return FoodChip(
      name: food,
      imagePath: path,
      fed: fed,
      cacheWidth: kFoodDecodeWidth,
      imageTint: tint,
      imageHidden: _dimmedFood == food,
      imageKey: key,
      onTap: () => _animateFoodToAnimal(food, path, tint),
    );
  }
}

/// Bir tabın təsviri.
class _TabDef {
  const _TabDef({
    required this.section,
    required this.icon,
    required this.label,
    required this.done,
  });

  final _Section section;
  final IconData icon;
  final String label;

  /// Bölmə tamamlanıbmı — tabın küncündə ✓ nişanı.
  final bool done;
}

/// Yapışqan tab zolağı: 12 + 48 + 10 = 70 dp.
class _TabsHeader extends SliverPersistentHeaderDelegate {
  _TabsHeader({required this.child});

  final Widget child;
  static const double extent = 70;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => SizedBox.expand(child: child);

  // Seçilmiş/✓ vəziyyəti dəyişir — həmişə yenidən qurulur.
  @override
  bool shouldRebuild(covariant _TabsHeader oldDelegate) => true;
}

/// Səhnənin sağ-alt küncündəki ulduz nişanı: «★★☆ 2/4».
///
/// Sayğac DƏQİQ bir `Text('$done/$total')`-dir (`star_ui_test` onu
/// `findsOneWidget` ilə axtarır).
class _StarPill extends StatelessWidget {
  const _StarPill({
    required this.stars,
    required this.done,
    required this.total,
  });

  final int stars;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$total tapşırıqdan $done',
      child: ExcludeSemantics(
        child: Container(
          height: ElifbaSize.heroBadgeHeight,
          padding: const EdgeInsetsDirectional.only(start: 6, end: 10),
          decoration: squishyDecoration(
            color: ElifbaPalette.surface,
            edge: ElifbaEdge.e2,
            edgeColor: ElifbaPalette.outline,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StarRow(filled: stars, size: 18, spacing: 0),
              const SizedBox(width: 4),
              Text(
                '$done/$total',
                maxLines: 1,
                textScaler: TextScaler.noScaling,
                style: ElifbaTextStyles.heroCount.copyWith(
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

/// Qidanın 44 dp dairəvi diski: uçan nüsxə və heyvanın üstündəki "pop".
/// Şəkil 4 dp içəridədir (36 dp, spec §7.2/§7.4) — diskin kənarından
/// çıxmasın. Dekod eni çipdəki ilə eynidir (gotcha 8).
class _FoodDisc extends StatelessWidget {
  const _FoodDisc({required this.imagePath, required this.tint, this.ring = 0});

  final String imagePath;
  final Color tint;
  final double ring;

  static const double _inset = 4;
  static const double _art = ElifbaSize.chipImage - 2 * _inset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ElifbaSize.chipImage,
      height: ElifbaSize.chipImage,
      padding: const EdgeInsets.all(_inset),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tint,
        boxShadow: [
          if (ring > 0)
            BoxShadow(color: ElifbaPalette.surface, spreadRadius: ring),
        ],
      ),
      child: Image.asset(
        imagePath,
        width: _art,
        height: _art,
        fit: BoxFit.contain,
        cacheWidth: kFoodDecodeWidth,
        errorBuilder:
            (context, error, stackTrace) => const ImagePlaceholder(size: _art),
      ),
    );
  }
}

/// Çipdən heyvana uçan qida (overlay-də, qlobal koordinatlarla).
///
/// ScreenAnimal keyframe-ləri: X xətti, Y və miqyas `Cubic(.2, .9, .35, 1)` —
/// qövs buradan alınır; miqyas 1 → 0.6.
class _FoodFlyer extends StatelessWidget {
  const _FoodFlyer({
    required this.animation,
    required this.start,
    required this.end,
    required this.imagePath,
    required this.tint,
  });

  final Animation<double> animation;
  final Offset start;
  final Offset end;
  final String imagePath;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    const half = ElifbaSize.chipImage / 2;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = animation.value;
        final ty = ElifbaMotion.foodFlightCurve.transform(t);
        final x = lerpDouble(start.dx, end.dx, t)!;
        final y = lerpDouble(start.dy, end.dy, ty)!;
        final s = lerpDouble(1.0, ElifbaMotion.foodFlightEndScale, ty)!;
        return Positioned(
          left: x - half,
          top: y - half,
          child: IgnorePointer(child: Transform.scale(scale: s, child: child)),
        );
      },
      child: _FoodDisc(imagePath: imagePath, tint: tint, ring: 3),
    );
  }
}

/// Söz tapmaca: heyvanın adını hərflərdən yığmaq. Bu faylda inline qalır
/// (CLAUDE.md gotcha 3).
class AnimalWordPuzzle extends StatefulWidget {
  final String word;
  final VoidCallback onWin;

  const AnimalWordPuzzle({super.key, required this.word, required this.onWin});

  @override
  State<AnimalWordPuzzle> createState() => _AnimalWordPuzzleState();
}

class _AnimalWordPuzzleState extends State<AnimalWordPuzzle> {
  late List<String> letters;
  late List<String> shuffledLetters;
  late List<String?> currentWord;
  late List<bool> correct;
  late ConfettiController _confettiController;
  final GatedPlayer _clickPlayer = GatedPlayer(SoundChannel.effect);
  final GatedPlayer _winPlayer = GatedPlayer(SoundChannel.effect);

  /// Slota hərf DÜŞƏN anın sayğacı: doğru düşəndə "pop", səhv düşəndə
  /// silkələnmə yalnız o anda oynayır — adi yenidən qurulmada yox.
  late List<int?> _popTrigger;
  late List<int?> _shakeTrigger;
  int _dropCount = 0;

  @override
  void initState() {
    super.initState();
    _setupPuzzle();
    _confettiController = ConfettiPreset.small.createController();
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

  Future<void> _playClickSound() => _clickPlayer.replay();

  Future<void> _playWinSound() => _winPlayer.replay();

  @override
  void dispose() {
    _confettiController.dispose();
    _clickPlayer.dispose();
    _winPlayer.dispose();
    super.dispose();
  }

  void _setupPuzzle() {
    setState(() {
      letters = widget.word.split('');
      shuffledLetters = List.from(letters)..shuffle();
      currentWord = List.filled(letters.length, null);
      correct = List.filled(letters.length, false);
      _popTrigger = List.filled(letters.length, null);
      _shakeTrigger = List.filled(letters.length, null);
    });
  }

  void _checkWin() {
    bool allCorrect = true;
    for (int i = 0; i < letters.length; i++) {
      if (currentWord[i] != letters[i]) {
        allCorrect = false;
        break;
      }
    }
    if (allCorrect && !currentWord.contains(null)) {
      if (!AppSettings.instance.reduceMotion) {
        _confettiController.play();
      }
      _playWinSound();
      widget.onWin();
    }
  }

  void _addLetter(String letter, int fromIndex, int toIndex) {
    setState(() {
      currentWord[toIndex] = letter;
      shuffledLetters[fromIndex] = '';
      correct[toIndex] = (letter == letters[toIndex]);
      _dropCount++;
      if (correct[toIndex]) {
        _popTrigger[toIndex] = _dropCount;
      } else {
        _shakeTrigger[toIndex] = _dropCount;
      }
    });
    _playClickSound();
    _checkWin();
  }

  void _removeLetter(int index) {
    if (currentWord[index] != null) {
      final letter = currentWord[index]!;
      setState(() {
        for (int i = 0; i < shuffledLetters.length; i++) {
          if (shuffledLetters[i] == '') {
            shuffledLetters[i] = letter;
            break;
          }
        }
        currentWord[index] = null;
        correct[index] = false;
      });
      _playClickSound();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ElifbaCard.section(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // ≥ 44 dp kafel, sətirdə ən çox 6: uzun adlar iki sətrə düzülür.
              final layout = wordTileLayout(
                letters.length,
                constraints.maxWidth,
              );
              final rowWidth = layout.rowMax + 0.5;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Heyvanın adını düzgün doldur',
                    textAlign: TextAlign.center,
                    style: ElifbaTextStyles.wordHeading.copyWith(
                      color: ElifbaPalette.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: rowWidth),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: GameDecorations.wordGap,
                      runSpacing: GameDecorations.wordRunGap,
                      children: [
                        for (var i = 0; i < currentWord.length; i++)
                          _buildSlot(i, layout.tile, layout.tileHeight),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(
                    width: double.infinity,
                    height: 2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: ElifbaPalette.surfaceContainer,
                        borderRadius: BorderRadius.all(Radius.circular(1)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Səbət yalnız boş olmayan hərfləri çəkir; model öz
                  // boşluqlarını saxlayır.
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: rowWidth,
                      minHeight: layout.tileHeight,
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: GameDecorations.wordGap,
                      runSpacing: GameDecorations.wordRunGap,
                      children: [
                        for (var i = 0; i < shuffledLetters.length; i++)
                          if (shuffledLetters[i].isNotEmpty)
                            _buildTrayTile(i, layout.tile, layout.tileHeight),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  PillButton(
                    label: 'Yenidən başla',
                    icon: Icons.refresh_rounded,
                    variant: PillButtonVariant.secondary,
                    size: PillButtonSize.medium,
                    onPressed: () {
                      _setupPuzzle();
                      _playClickSound();
                    },
                  ),
                ],
              );
            },
          ),
        ),
        // Daxili konfeti ağacda qalır (gotcha 16).
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Center(
            child: IgnorePointer(
              child: ElifbaConfetti(controller: _confettiController),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlot(int index, double tile, double tileHeight) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (data) => currentWord[index] == null,
      onAcceptWithDetails: (details) {
        final fromIndex = shuffledLetters.indexOf(details.data);
        if (fromIndex != -1) {
          _addLetter(details.data, fromIndex, index);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final letter = currentWord[index];
        final WordTileState state;
        final String label;
        if (letter == null) {
          state =
              candidateData.isNotEmpty
                  ? WordTileState.hover
                  : WordTileState.empty;
          label = 'boş';
        } else if (correct[index]) {
          state = WordTileState.correct;
          label = '$letter, doğru';
        } else {
          state = WordTileState.wrong;
          label = '$letter, səhv';
        }
        // Struktur bütün vəziyyətlərdə eynidir: pop/silkələnmənin vəziyyəti
        // (State) yenidən qurulmada itmir.
        return Semantics(
          label: label,
          button: letter != null,
          // Uşaq semantikası atılır — toxunub hərfi geri qaytarmaq burada
          // yenidən verilir.
          onTap: letter != null ? () => _removeLetter(index) : null,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: () => _removeLetter(index),
            child: ShakeOnTrigger(
              trigger: _shakeTrigger[index],
              child: PopOnTrigger(
                trigger: _popTrigger[index],
                child: WordTileFace(
                  state: state,
                  width: tile,
                  height: tileHeight,
                  glyph: letter ?? '',
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrayTile(int index, double tile, double tileHeight) {
    final letter = shuffledLetters[index];
    return Draggable<String>(
      key: ValueKey<int>(index),
      data: letter,
      feedback: WordTileFace(
        state: WordTileState.dragging,
        width: tile,
        height: tileHeight,
        glyph: letter,
      ),
      // Sürüklənərkən yer boş qalır — səbət yarı yolda yenidən düzülmür.
      childWhenDragging: SizedBox(width: tile, height: tileHeight),
      onDragStarted: _playClickSound,
      child: WordTileFace(
        state: WordTileState.rest,
        width: tile,
        height: tileHeight,
        glyph: letter,
      ),
    );
  }
}
