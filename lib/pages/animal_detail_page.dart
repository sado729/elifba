import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:confetti/confetti.dart';
import '../core/utils.dart';
import '../core/config.dart';
import 'puzzle_page.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:math';
import '../widgets/youtube_video_widget.dart';
import 'animal_word_puzzle.dart';

class AnimalDetailPage extends StatefulWidget {
  final String animal;
  final List<String> animals;
  final int currentIndex;

  const AnimalDetailPage({
    super.key,
    required this.animal,
    required this.animals,
    required this.currentIndex,
  });

  @override
  State<AnimalDetailPage> createState() => _AnimalDetailPageState();
}

class _AnimalDetailPageState extends State<AnimalDetailPage>
    with TickerProviderStateMixin {
  final AudioPlayer audioPlayer = AudioPlayer();
  bool isPlayingInfo = false;
  bool showInfo = true;
  bool showFoods = false;
  bool showPuzzle = false;
  bool showWordPuzzle = false;
  bool showYoutube = false;
  late ConfettiController _confettiController;

  // --- ANİMASİYA üçün əlavə dəyişənlər ---
  final Map<String, GlobalKey> _foodKeys = {};
  final GlobalKey _animalImageKey = GlobalKey();
  OverlayEntry? _foodOverlayEntry;
  bool _foodEffectActive = false;
  bool _showHeart = false;
  double _heartScale = 0.0;
  bool _showFoodEffect = false;
  double _foodEffectScale = 0.0;
  double _foodEffectRotation = 0.0;
  double _foodEffectOpacity = 0.0;
  String? _foodEffectImage;
  bool _showHalo = false;
  double _haloOpacity = 0.0;
  bool showCongrats = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );

    // Səs bitdikdə isPlayingInfo-nu false et
    audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (mounted) {
          setState(() {
            isPlayingInfo = false;
          });
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final animalLetter = getFirstLetter(widget.animal);
      final animalData = AppConfig.findAnimal(animalLetter, widget.animal);
      final imageAsset = animalData?.imagePath ?? '';
      if (imageAsset.isNotEmpty) {
        precacheImage(AssetImage(imageAsset), context);
      }
      final foods = animalData?.foods ?? [];
      for (final food in foods) {
        final foodImagePath =
            'assets/foods/${AppConfig.normalizeFileName(food)}.png';
        precacheImage(AssetImage(foodImagePath), context);
      }
    });
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _playSound(String audioAsset) async {
    await audioPlayer.setAsset(audioAsset);
    await audioPlayer.play();
  }

  void _toggleAnimalInfo(String animal) async {
    final animalLetter = getFirstLetter(animal);
    final animalInfo = AppConfig.findAnimal(animalLetter, animal);
    if (animalInfo == null) return;
    final audioAsset = animalInfo.audioPath;

    setState(() {
      isPlayingInfo = !isPlayingInfo;
    });

    if (isPlayingInfo) {
      await audioPlayer.stop();
      try {
        // Əvvəlcə səs faylını oxut
        await _playSound(audioAsset);
      } catch (e) {
        // Səs faylı tapılmadısa isPlayingInfo-nu false et
        setState(() {
          isPlayingInfo = false;
        });
        debugPrint('Səs faylı oxunma xətası: $e');
      }
    } else {
      await audioPlayer.stop();
    }
  }

  void _showHeartEffect() async {
    setState(() {
      _showHeart = true;
      _heartScale = 0.2;
    });
    await Future.delayed(const Duration(milliseconds: 10));
    setState(() {
      _heartScale = 1.2;
    });
    await Future.delayed(const Duration(milliseconds: 220));
    setState(() {
      _heartScale = 1.0;
    });
    await Future.delayed(const Duration(milliseconds: 200));
    setState(() {
      _heartScale = 0.0;
    });
    await Future.delayed(const Duration(milliseconds: 180));
    setState(() {
      _heartScale = 0.0;
    });
    await Future.delayed(const Duration(milliseconds: 180));
    setState(() {
      _showHeart = false;
    });
  }

  Future<void> _showFoodArrivalEffect(String foodImagePath) async {
    setState(() {
      _showFoodEffect = true;
      _foodEffectScale = 0.2;
      _foodEffectRotation = 0.0;
      _foodEffectOpacity = 1.0;
      _foodEffectImage = foodImagePath;
      _showHalo = true;
      _haloOpacity = 0.0;
    });
    await Future.delayed(const Duration(milliseconds: 10));
    setState(() {
      _foodEffectScale = 1.3;
      _foodEffectOpacity = 1.0;
      _haloOpacity = 0.7;
    });
    await Future.delayed(const Duration(milliseconds: 320));
    setState(() {
      _foodEffectScale = 1.0;
      _foodEffectOpacity = 0.0;
      _haloOpacity = 0.0;
    });
    await Future.delayed(const Duration(milliseconds: 350));
    setState(() {
      _showFoodEffect = false;
      _showHalo = false;
      _foodEffectImage = null;
    });
  }

  void _animateFoodToAnimal(String food, String foodImagePath) async {
    if (_foodEffectActive) return;
    final foodKey = _foodKeys[food];
    if (foodKey == null) return;
    final animalKey = _animalImageKey;
    final foodBox = foodKey.currentContext?.findRenderObject() as RenderBox?;
    final animalBox =
        animalKey.currentContext?.findRenderObject() as RenderBox?;
    if (foodBox == null || animalBox == null) return;
    final foodPos = foodBox.localToGlobal(Offset.zero);
    final animalPos = animalBox.localToGlobal(Offset.zero);
    final overlay = Overlay.of(context);
    final foodSize = foodBox.size;
    final animalSize = animalBox.size;
    final start = foodPos;
    final end =
        animalPos +
        Offset(animalSize.width / 2 - 24, animalSize.height / 2 - 24);
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    final curve = CurvedAnimation(parent: controller, curve: Curves.easeInOut);
    final tween = Tween<Offset>(begin: start, end: end);
    _foodEffectActive = true;
    _foodOverlayEntry = OverlayEntry(
      builder: (context) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final pos = tween.evaluate(curve);
            return Positioned(left: pos.dx, top: pos.dy, child: child!);
          },
          child: SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  foodImagePath,
                  width: 40,
                  height: 40,
                  frameBuilder: (
                    context,
                    child,
                    frame,
                    wasSynchronouslyLoaded,
                  ) {
                    if (wasSynchronouslyLoaded) return child;
                    return AnimatedOpacity(
                      opacity: frame == null ? 0 : 1,
                      duration: const Duration(milliseconds: 400),
                      child: child,
                    );
                  },
                  errorBuilder:
                      (context, error, stackTrace) => const Icon(
                        Icons.fastfood,
                        size: 32,
                        color: Colors.orange,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
    overlay.insert(_foodOverlayEntry!);
    await controller.forward();
    _foodOverlayEntry?.remove();
    _foodOverlayEntry = null;
    controller.dispose();
    // Sonda heyvan şəklinin üzərində qida və halo effekti
    await _showFoodArrivalEffect(foodImagePath);
    _foodEffectActive = false;
  }

  @override
  Widget build(BuildContext context) {
    final animalLetter = getFirstLetter(widget.animal);
    final animalData = AppConfig.findAnimal(animalLetter, widget.animal);
    final imageAsset = animalData?.imagePath ?? '';
    final puzzleAsset = imageAsset.replaceFirst('.png', '_puzzle.jpg');
    final info =
        animalData?.description ?? 'Bu heyvan haqqında məlumat yoxdur.';
    final foods = animalData?.foods ?? [];
    final hasSound = animalData?.hasSound ?? false;
    final hasPuzzle = animalData?.hasPuzzle ?? false;
    final youtubeEmbed = animalData?.youtubeEmbed;

    final animalsList = widget.animals;
    final currentIndex = widget.currentIndex;
    final normalizedAnimalName = AppConfig.normalizeFileName(widget.animal);
    final animalSoundAsset =
        'assets/audios/${animalLetter.toLowerCase()}/${normalizedAnimalName}_sound.mp3';

    final List<_ActionButtonData> actions = [
      _ActionButtonData(
        tooltip: 'Məlumat',
        icon: Icons.info_outline,
        selected: showInfo,
        onTap: () {
          setState(() {
            showInfo = !showInfo;
            showFoods = false;
            showPuzzle = false;
            showWordPuzzle = false;
            showYoutube = false;
          });
        },
        visible: true,
      ),
      _ActionButtonData(
        tooltip: 'Qidalar',
        icon: Icons.restaurant_menu,
        selected: showFoods,
        onTap: () {
          setState(() {
            showFoods = !showFoods;
            showInfo = !showFoods;
            showPuzzle = false;
            showWordPuzzle = false;
            showYoutube = false;
          });
        },
        visible: foods.isNotEmpty,
      ),
      _ActionButtonData(
        tooltip: 'Söz tapmaca',
        icon: Icons.abc,
        selected: showWordPuzzle,
        onTap: () {
          setState(() {
            showWordPuzzle = !showWordPuzzle;
            showInfo = !showWordPuzzle;
            showFoods = false;
            showPuzzle = false;
            showYoutube = false;
          });
        },
        visible: true,
      ),
    ];
    // Puzzle iconunu yalnız map-da true olan heyvanlar üçün əlavə et
    if (hasPuzzle) {
      actions.add(
        _ActionButtonData(
          tooltip: 'Puzzle',
          icon: Icons.extension_rounded,
          selected: showPuzzle,
          onTap: () {
            setState(() {
              showPuzzle = !showPuzzle;
              showInfo = !showPuzzle;
              showFoods = false;
              showWordPuzzle = false;
              showYoutube = false;
            });
          },
          visible: true,
        ),
      );
    }
    // Youtube video iconu yalnız map-da varsa əlavə et
    if (youtubeEmbed != null && youtubeEmbed.isNotEmpty) {
      actions.add(
        _ActionButtonData(
          tooltip: 'Youtube video',
          icon: Icons.smart_display_rounded,
          selected: showYoutube,
          onTap: () {
            setState(() {
              showYoutube = !showYoutube;
              showInfo = !showYoutube;
              showFoods = false;
              showPuzzle = false;
              showWordPuzzle = false;
            });
          },
          visible: true,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.animal),
            if (hasSound) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.volume_up),
                onPressed: () {
                  debugPrint('Heyvan səsi çalınır: $animalSoundAsset');
                  _playSound(animalSoundAsset);
                },
                tooltip: 'Heyvanın səsi',
              ),
            ],
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.navigate_before),
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
          IconButton(
            icon: const Icon(Icons.navigate_next),
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
      body: Stack(
        children: [
          // Əsas gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2E2B5F), Color(0xFF1B1A3A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Column(
            children: [
              // Şəkil dekorativ background-da
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepPurple.shade400,
                      Colors.deepPurple.shade700,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.12),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                padding: const EdgeInsets.only(
                  top: 24,
                  left: 16,
                  right: 16,
                  bottom: 12,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          imageAsset,
                          key: _animalImageKey,
                          fit: BoxFit.contain,
                          frameBuilder: (
                            context,
                            child,
                            frame,
                            wasSynchronouslyLoaded,
                          ) {
                            if (wasSynchronouslyLoaded) return child;
                            return AnimatedOpacity(
                              opacity: frame == null ? 0 : 1,
                              duration: const Duration(milliseconds: 400),
                              child: child,
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    if (_showHeart)
                      AnimatedOpacity(
                        opacity: _heartScale > 0 ? 1 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: AnimatedScale(
                          scale: _heartScale,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.elasticOut,
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 90,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_showHalo)
                      AnimatedOpacity(
                        opacity: _haloOpacity,
                        duration: const Duration(milliseconds: 350),
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.yellow.withOpacity(0.5),
                                Colors.transparent,
                              ],
                              stops: const [0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                    if (_showFoodEffect && _foodEffectImage != null)
                      AnimatedOpacity(
                        opacity: _foodEffectOpacity,
                        duration: const Duration(milliseconds: 220),
                        child: AnimatedScale(
                          scale: _foodEffectScale,
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeInOut,
                          child: Image.asset(
                            _foodEffectImage!,
                            width: 64,
                            height: 64,
                            frameBuilder: (
                              context,
                              child,
                              frame,
                              wasSynchronouslyLoaded,
                            ) {
                              if (wasSynchronouslyLoaded) return child;
                              return AnimatedOpacity(
                                opacity: frame == null ? 0 : 1,
                                duration: const Duration(milliseconds: 400),
                                child: child,
                              );
                            },
                            errorBuilder:
                                (context, error, stackTrace) => const Icon(
                                  Icons.fastfood,
                                  size: 48,
                                  color: Colors.orange,
                                ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Müasir buttonlar bir sıra şəklində
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 8,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:
                        actions
                            .where((action) => action.visible)
                            .map(
                              (action) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        action.selected
                                            ? Colors.yellowAccent
                                            : Colors.deepPurple.shade600,
                                    foregroundColor:
                                        action.selected
                                            ? Colors.deepPurple.shade800
                                            : Colors.white,
                                    elevation: action.selected ? 8 : 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 14,
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  onPressed: action.onTap,
                                  child: Row(
                                    children: [
                                      Icon(action.icon, size: 24),
                                      const SizedBox(width: 8),
                                      Text(action.tooltip),
                                    ],
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ),
              // Alt bölmələr (məlumat, qidalar və s.)
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showInfo)
                          Card(
                            color: Colors.white.withOpacity(0.95),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            margin: const EdgeInsets.only(bottom: 18),
                            child: Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Məlumat:',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2E2B5F),
                                        ),
                                      ),
                                      const Spacer(),
                                      ElevatedButton.icon(
                                        icon: Icon(
                                          isPlayingInfo
                                              ? Icons.stop
                                              : Icons.volume_up,
                                        ),
                                        label: Text(
                                          isPlayingInfo ? 'Dayandır' : 'Dinlə',
                                        ),
                                        onPressed:
                                            () => _toggleAnimalInfo(
                                              widget.animal,
                                            ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              isPlayingInfo
                                                  ? Colors.redAccent
                                                  : Colors.deepPurple.shade400,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
                                          ),
                                          textStyle: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    info,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF1B1A3A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (showFoods && foods.isNotEmpty)
                          Card(
                            color: Colors.white.withOpacity(0.95),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            margin: const EdgeInsets.only(bottom: 18),
                            child: Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Qidaları:',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2E2B5F),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children:
                                        foods.map((food) {
                                          _foodKeys.putIfAbsent(
                                            food,
                                            () => GlobalKey(),
                                          );
                                          final foodImagePath =
                                              'assets/foods/${AppConfig.normalizeFileName(food)}.png';
                                          return GestureDetector(
                                            key: _foodKeys[food],
                                            onTap:
                                                () => _animateFoodToAnimal(
                                                  food,
                                                  foodImagePath,
                                                ),
                                            child: Chip(
                                              label: Text(food),
                                              avatar: Image.asset(
                                                foodImagePath,
                                                width: 32,
                                                height: 32,
                                                frameBuilder: (
                                                  context,
                                                  child,
                                                  frame,
                                                  wasSynchronouslyLoaded,
                                                ) {
                                                  if (wasSynchronouslyLoaded) {
                                                    return child;
                                                  }
                                                  return AnimatedOpacity(
                                                    opacity:
                                                        frame == null ? 0 : 1,
                                                    duration: const Duration(
                                                      milliseconds: 400,
                                                    ),
                                                    child: child,
                                                  );
                                                },
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => const Icon(
                                                      Icons.fastfood,
                                                    ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (showWordPuzzle) ...[
                          const SizedBox(height: 16),
                          AnimalWordPuzzle(
                            word: widget.animal,
                            onWin: () {
                              setState(() {
                                showCongrats = true;
                              });
                              _confettiController.play();
                            },
                          ),
                        ],
                        if (showYoutube && youtubeEmbed != null) ...[
                          const SizedBox(height: 16),
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: YoutubeVideoWidget(embedUrl: youtubeEmbed),
                            ),
                          ),
                        ],
                        if (showPuzzle)
                          showPuzzle
                              ? Padding(
                                padding: const EdgeInsets.only(top: 12.0),
                                child: PuzzlePage(animal: widget.animal),
                              )
                              : Card(
                                color: Colors.white.withOpacity(0.95),
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                margin: const EdgeInsets.only(bottom: 18),
                                child: Padding(
                                  padding: const EdgeInsets.all(18.0),
                                  child: Column(
                                    children: [
                                      const Text(
                                        'Puzzle:',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2E2B5F),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Image.asset(
                                        puzzleAsset,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Container(
                                            height: 200,
                                            color: Colors.grey[300],
                                            child: const Center(
                                              child: Text(
                                                'Puzzle şəkli tapılmadı',
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (showCongrats)
            Positioned.fill(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        showCongrats = false;
                      });
                    },
                    child: Container(color: Colors.black.withOpacity(0.45)),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiWidget(
                      confettiController: _confettiController,
                      blastDirection: -pi / 2,
                      maxBlastForce: 5,
                      minBlastForce: 1,
                      emissionFrequency: 0.05,
                      numberOfParticles: 20,
                      gravity: 0.1,
                    ),
                  ),
                  Center(
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.7,
                        maxWidth: 400,
                      ),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.withOpacity(0.18),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.emoji_events,
                              color: Colors.amber,
                              size: 54,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Təbriklər!',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E2B5F),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionButtonData {
  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;
  final bool visible;

  _ActionButtonData({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onTap,
    required this.visible,
  });
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: selected ? Theme.of(context).primaryColor : Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              color:
                  selected ? Colors.white : Theme.of(context).iconTheme.color,
            ),
          ),
        ),
      ),
    );
  }
}

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
  late AudioPlayer _clickPlayer;
  late AudioPlayer _winPlayer;

  @override
  void initState() {
    super.initState();
    _setupPuzzle();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _initAudio();
  }

  Future<void> _initAudio() async {
    _clickPlayer = AudioPlayer();
    _winPlayer = AudioPlayer();
    await _clickPlayer.setAsset('assets/audios/click.mp3');
    await _winPlayer.setAsset('assets/audios/win.mp3');
  }

  Future<void> _playClickSound() async {
    try {
      await _clickPlayer.seek(Duration.zero);
      await _clickPlayer.play();
    } catch (e) {
      debugPrint('Səs oynatma xətası: $e');
    }
  }

  Future<void> _playWinSound() async {
    try {
      await _winPlayer.seek(Duration.zero);
      await _winPlayer.play();
    } catch (e) {
      debugPrint('Səs oynatma xətası: $e');
    }
  }

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
      _confettiController.play();
      _playWinSound();
      widget.onWin();
    }
  }

  void _addLetter(String letter, int fromIndex, int toIndex) {
    setState(() {
      currentWord[toIndex] = letter;
      shuffledLetters[fromIndex] = '';
      correct[toIndex] = (letter == letters[toIndex]);
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
      children: [
        Column(
          children: [
            const Text(
              'Heyvanın adını düzgün doldur',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    currentWord.length,
                    (index) => DragTarget<String>(
                      onWillAcceptWithDetails:
                          (data) => currentWord[index] == null,
                      onAcceptWithDetails: (details) {
                        final fromIndex = shuffledLetters.indexOf(details.data);
                        if (fromIndex != -1) {
                          _addLetter(details.data, fromIndex, index);
                        }
                      },
                      builder: (context, candidateData, rejectedData) {
                        Color borderColor = Colors.grey;
                        Color fillColor = Colors.white;
                        if (currentWord[index] != null) {
                          if (correct[index]) {
                            borderColor = Colors.green;
                            fillColor = Colors.green.shade100;
                          } else {
                            borderColor = Colors.red;
                            fillColor = Colors.red.shade100;
                          }
                        }
                        return GestureDetector(
                          onTap: () => _removeLetter(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 40,
                            height: 50,
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              border: Border.all(color: borderColor, width: 2),
                              borderRadius: BorderRadius.circular(8),
                              color: fillColor,
                            ),
                            child: Center(
                              child: Text(
                                currentWord[index] ?? '',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: -pi / 2,
                  maxBlastForce: 5,
                  minBlastForce: 1,
                  emissionFrequency: 0.05,
                  numberOfParticles: 20,
                  gravity: 0.1,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                shuffledLetters.length,
                (index) =>
                    shuffledLetters[index].isEmpty
                        ? const SizedBox(width: 40, height: 50)
                        : Draggable<String>(
                          data: shuffledLetters[index],
                          feedback: Material(
                            color: Colors.transparent,
                            child: Container(
                              width: 40,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade200,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 8,
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  shuffledLetters[index],
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          childWhenDragging: const SizedBox(
                            width: 40,
                            height: 50,
                          ),
                          onDragStarted: _playClickSound,
                          child: Container(
                            width: 40,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                shuffledLetters[index],
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                _setupPuzzle();
                _playClickSound();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Yenidən başla'),
            ),
          ],
        ),
      ],
    );
  }
}

class YoutubeVideoWidget extends StatelessWidget {
  final String embedUrl;
  const YoutubeVideoWidget({super.key, required this.embedUrl});

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(
      controller:
          WebViewController()
            ..loadRequest(Uri.parse(embedUrl))
            ..setJavaScriptMode(JavaScriptMode.unrestricted),
    );
  }
}
