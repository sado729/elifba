import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import '../core/utils.dart';
import 'puzzle_page.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class AnimalDetailPage extends StatefulWidget {
  final String animal;
  final List<String>? animals;
  final int? currentIndex;
  const AnimalDetailPage({
    super.key,
    required this.animal,
    this.animals,
    this.currentIndex,
  });

  @override
  State<AnimalDetailPage> createState() => _AnimalDetailPageState();
}

class _AnimalDetailPageState extends State<AnimalDetailPage> {
  final FlutterTts flutterTts = FlutterTts();
  final AudioPlayer audioPlayer = AudioPlayer();
  bool showInfo = true;
  bool showFoods = false;
  bool showPuzzle = false;
  late ConfettiController _confettiController;

  // --- ANİMASİYA üçün əlavə ---
  final GlobalKey _animalImageKey = GlobalKey();
  final Map<int, GlobalKey> _foodButtonKeys = {};
  OverlayEntry? _flyingEntry;

  static const Map<String, String> animalInfo = {
    'At':
        'At — sürətli və güclü ev heyvanıdır. Minik və yük daşımaq üçün istifadə olunur.',
    'Ayı': 'Ayı — böyük və güclü yırtıcı heyvandır, meşələrdə yaşayır.',
    'Ceyran': 'Ceyran — sürətli və zərif ot yeyən heyvandır.',
    'Fil': 'Fil — dünyanın ən böyük quruda yaşayan heyvanıdır.',
    'Pələng': 'Pələng — böyük və güclü pişik növüdür.',
    'İlan': 'İlan — sürünənlər sinfinə aid heyvandır.',
    'Qartal': 'Qartal — iti görən və güclü qanadlı quşdur.',
    'Dovşan': 'Dovşan — tez qaçan, yumşaq tüklü heyvandır.',
    'Balıq': 'Balıq — suda yaşayan onurğalı heyvandır.',
    // ... digər heyvanlar üçün məlumat əlavə edə bilərsən ...
  };

  static const Map<String, List<String>> animalFoods = {
    'At': ['Ot', 'Yulaf', 'Saman'],
    'Ayı': ['Bal', 'Balıq', 'Giləmeyvə'],
    'Ceyran': ['Ot', 'Yarpaqlar'],
    'Fil': ['Ot', 'Meyvə', 'Yarpaqlar'],
    'Pələng': ['Ət', 'Kiçik heyvanlar'],
    'İlan': ['Siçan', 'Quş', 'Yumurta'],
    'Qartal': ['Balıq', 'Quş', 'Kiçik məməlilər'],
    'Dovşan': ['Ot', 'Kök', 'Yarpaqlar'],
    'Balıq': ['Plankton', 'Kiçik balıqlar'],
    // ... digər heyvanlar üçün qida əlavə edə bilərsən ...
  };

  void _speak(String text) async {
    await flutterTts.setLanguage('az-AZ');
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
  }

  void _playAnimalSound(String animal) async {
    final animalLetter = getFirstLetter(animal);
    final animalName = normalizeFileName(animal);
    final audioAsset =
        'animals/$animalLetter/$animalName/${animalName}_sound.mp3';
    try {
      await audioPlayer.stop();
      await audioPlayer.play(AssetSource(audioAsset));
    } catch (e) {}
  }

  void _playAnimalInfo(String animal) async {
    final animalLetter = getFirstLetter(animal);
    final animalName = normalizeFileName(animal);
    final audioAsset =
        'animals/$animalLetter/$animalName/${animalName}_info.mp3';
    try {
      await audioPlayer.stop();
      await audioPlayer.play(AssetSource(audioAsset));
    } catch (e) {}
  }

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animal = widget.animal;
    final animalLetter = getFirstLetter(animal);
    final animalName = normalizeFileName(animal);
    final imageAsset = 'animals/$animalLetter/$animalName/$animalName.png';
    final puzzleAsset =
        'animals/$animalLetter/$animalName/${animalName}_puzzle.jpg';
    final info = animalInfo[animal] ?? 'Bu heyvan haqqında məlumat yoxdur.';
    final foods = animalFoods[animal] ?? [];
    final animalsList = widget.animals;
    final currentIndex = widget.currentIndex;
    final animalSoundAsset =
        'animals/$animalLetter/$animalName/${animalName}_sound.mp3';

    final List<_ActionButtonData> actions = [
      _ActionButtonData(
        tooltip: 'Haqqında',
        icon: Icons.info,
        selected: showInfo,
        onTap: () {
          setState(() {
            showInfo = true;
            showFoods = false;
            showPuzzle = false;
          });
        },
        visible: true,
      ),
      if (foods.isNotEmpty)
        _ActionButtonData(
          tooltip: 'Qidaları',
          icon: Icons.restaurant,
          selected: showFoods,
          onTap: () {
            setState(() {
              showFoods = true;
              showInfo = false;
              showPuzzle = false;
            });
          },
          visible: true,
        ),
    ];
    // Səs iconu
    actions.add(
      _ActionButtonData(
        tooltip: 'Heyvanın səsi',
        icon: Icons.volume_up,
        selected: false,
        onTap: () => _playAnimalSound(animal),
        visibleFuture: _assetExists(animalSoundAsset),
      ),
    );
    // Puzzle iconu
    actions.add(
      _ActionButtonData(
        tooltip: 'Puzzle',
        icon: Icons.extension,
        selected: showPuzzle,
        onTap: () {
          setState(() {
            showPuzzle = true;
            showInfo = false;
            showFoods = false;
          });
        },
        visibleFuture: _assetExists(puzzleAsset),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: _Breadcrumbs(
          animal: animal,
          animalLetter: animalLetter,
          animalsList: animalsList,
          currentIndex: currentIndex,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurple.withOpacity(0.07),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.deepPurple.shade100,
                            width: 1.1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ...actions
                                .map((action) {
                                  if (action.visibleFuture != null) {
                                    return FutureBuilder<bool>(
                                      future: action.visibleFuture,
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                                ConnectionState.waiting ||
                                            snapshot.data == false) {
                                          return const SizedBox();
                                        }
                                        return _ActionButton(action: action);
                                      },
                                    );
                                  } else if (action.visible) {
                                    return _ActionButton(action: action);
                                  } else {
                                    return const SizedBox();
                                  }
                                })
                                .expand((w) => [w, const SizedBox(width: 8)])
                                .toList()
                              ..removeLast(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (showPuzzle)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 24.0),
                        child: PuzzlePage(animal: animal),
                      ),
                    )
                  else ...[
                    ClipRRect(
                      key: _animalImageKey,
                      borderRadius: BorderRadius.circular(32),
                      child: Image.asset(
                        imageAsset,
                        width: 220,
                        height: 220,
                        fit: BoxFit.contain,
                        errorBuilder:
                            (context, error, stackTrace) => Container(
                              width: 220,
                              height: 220,
                              color: Colors.grey.shade200,
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 40,
                              ),
                            ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      animal,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (showInfo)
                      Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 480),
                          margin: EdgeInsets.symmetric(vertical: 8),
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade50,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.deepPurple.withOpacity(0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.deepPurple.shade100,
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.deepPurple,
                                    size: 26,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Heyvan haqqında',
                                    style: TextStyle(
                                      color: Colors.deepPurple.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    tooltip: 'Haqqında səsləndir',
                                    icon: const Icon(
                                      Icons.record_voice_over,
                                      size: 24,
                                    ),
                                    color: Colors.deepPurple,
                                    onPressed: () => _playAnimalInfo(animal),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                info,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF3D2067),
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (showFoods)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Qidaları:',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(foods.length, (idx) {
                                final food = foods[idx];
                                final foodLetter = getFirstLetter(food);
                                final foodImage =
                                    'foods/${normalizeFileName(food)}.png';
                                _foodButtonKeys.putIfAbsent(
                                  idx,
                                  () => GlobalKey(),
                                );
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6.0,
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(18),
                                      onTap: () {}, // gələcəkdə istifadə üçün
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        curve: Curves.easeInOut,
                                        decoration: BoxDecoration(
                                          color: Colors.deepPurple.shade50,
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.deepPurple
                                                  .withOpacity(0.08),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                          border: Border.all(
                                            color: Colors.deepPurple.shade100,
                                            width: 1.2,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Image.asset(
                                                foodImage,
                                                width: 56,
                                                height: 56,
                                                fit: BoxFit.contain,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => Container(
                                                      width: 56,
                                                      height: 56,
                                                      color:
                                                          Colors.grey.shade200,
                                                      child: const Icon(
                                                        Icons.fastfood,
                                                        size: 28,
                                                      ),
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    Colors.deepPurple.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                food,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.deepPurple,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            ElevatedButton(
                                              key: _foodButtonKeys[idx],
                                              onPressed: () {
                                                _animateFoodToAnimal(idx);
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.white,
                                                foregroundColor:
                                                    Colors.deepPurple,
                                                elevation: 0,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  side: BorderSide(
                                                    color:
                                                        Colors
                                                            .deepPurple
                                                            .shade200,
                                                  ),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.favorite,
                                                    size: 18,
                                                    color: Colors.pink,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'Qidalandır',
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                  ],
                ],
              ),
              if (animalsList != null &&
                  currentIndex != null &&
                  animalsList.length > 1) ...[
                if (currentIndex > 0)
                  Positioned(
                    left: 0,
                    top: MediaQuery.of(context).size.height * 0.25,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios, size: 36),
                      onPressed: () {
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
                      },
                    ),
                  ),
                if (currentIndex < animalsList.length - 1)
                  Positioned(
                    right: 0,
                    top: MediaQuery.of(context).size.height * 0.25,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 36),
                      onPressed: () {
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
                      },
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _animateFoodToAnimal(int foodIdx) async {
    final foodKey = _foodButtonKeys[foodIdx];
    if (foodKey == null) return;
    final animalBox =
        _animalImageKey.currentContext?.findRenderObject() as RenderBox?;
    final foodBox = foodKey.currentContext?.findRenderObject() as RenderBox?;
    if (animalBox == null || foodBox == null) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    final start = foodBox.localToGlobal(foodBox.size.center(Offset.zero));
    final end = animalBox.localToGlobal(animalBox.size.center(Offset.zero));
    OverlayEntry? entry;
    entry = OverlayEntry(
      builder:
          (context) => _FlyingHeartAnimation(
            start: start,
            end: end,
            onArrive: () {
              entry?.remove();
              _showArriveEffect(end, overlay);
            },
          ),
    );
    _flyingEntry = entry;
    overlay.insert(entry);
  }

  void _showArriveEffect(Offset center, OverlayState overlay) {
    final effectEntry = OverlayEntry(
      builder: (context) => _ArriveEffect(center: center),
    );
    overlay.insert(effectEntry);
    Future.delayed(const Duration(seconds: 1), () {
      effectEntry.remove();
    });
  }

  Future<bool> _assetExists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (e) {
      return false;
    }
  }
}

class _FlyingHeartAnimation extends StatefulWidget {
  final Offset start;
  final Offset end;
  final VoidCallback onArrive;
  const _FlyingHeartAnimation({
    required this.start,
    required this.end,
    required this.onArrive,
  });

  @override
  State<_FlyingHeartAnimation> createState() => _FlyingHeartAnimationState();
}

class _FlyingHeartAnimationState extends State<_FlyingHeartAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _position;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _position = Tween<Offset>(begin: widget.start, end: widget.end).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onArrive();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: _position.value.dx - 16,
          top: _position.value.dy - 16,
          child: Opacity(
            opacity: 1 - _controller.value * 0.3,
            child: Icon(Icons.favorite, color: Colors.pink, size: 32),
          ),
        );
      },
    );
  }
}

class _ArriveEffect extends StatefulWidget {
  final Offset center;
  const _ArriveEffect({required this.center});

  @override
  State<_ArriveEffect> createState() => _ArriveEffectState();
}

class _ArriveEffectState extends State<_ArriveEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.center.dx - 32,
      top: widget.center.dy - 32,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 1.0 + 0.7 * _controller.value;
          final opacity = 1.0 - _controller.value;
          return Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.pinkAccent.withOpacity(0.7),
                      Colors.pink.withOpacity(0.0),
                    ],
                    stops: [0.5, 1.0],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.favorite, color: Colors.pink, size: 32),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ActionButtonData {
  final String tooltip;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool visible;
  final Future<bool>? visibleFuture;
  _ActionButtonData({
    required this.tooltip,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.visible = false,
    this.visibleFuture,
  });
}

class _ActionButton extends StatelessWidget {
  final _ActionButtonData action;
  const _ActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: action.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color:
                action.selected
                    ? Colors.deepPurple.shade100
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  action.selected
                      ? Colors.deepPurple
                      : Colors.deepPurple.shade100,
              width: action.selected ? 2 : 1.1,
            ),
            boxShadow:
                action.selected
                    ? [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.10),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : [],
          ),
          child: Tooltip(
            message: action.tooltip,
            child: Icon(
              action.icon,
              size: 28,
              color:
                  action.selected
                      ? Colors.deepPurple
                      : Colors.deepPurple.shade400,
            ),
          ),
        ),
      ),
    );
  }
}

class _Breadcrumbs extends StatelessWidget {
  final String animal;
  final String animalLetter;
  final List<String>? animalsList;
  final int? currentIndex;
  const _Breadcrumbs({
    required this.animal,
    required this.animalLetter,
    this.animalsList,
    this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Əsas səhifə (Əlifba)
          _BreadcrumbCircle(
            icon: Icons.home,
            label: 'Əlifba',
            color: Colors.deepPurple.shade400,
            onTap:
                () => Navigator.of(context).popUntil((route) => route.isFirst),
            selected: false,
          ),
          _BreadcrumbArrow(),
          // Hərf
          _BreadcrumbCircle(
            icon: null,
            label: animalLetter.toUpperCase(),
            color: Colors.deepPurple.shade200,
            onTap:
                (animalsList != null && currentIndex != null)
                    ? () => Navigator.of(context).pop()
                    : null,
            selected: true,
          ),
        ],
      ),
    );
  }
}

class _BreadcrumbCircle extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool selected;
  const _BreadcrumbCircle({
    this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.18) : color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : color.withOpacity(0.4),
            width: selected ? 2 : 1.1,
          ),
          boxShadow:
              selected
                  ? [
                    BoxShadow(
                      color: color.withOpacity(0.13),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) Icon(icon, color: color, size: 20),
            if (icon != null) const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreadcrumbArrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Icon(
        Icons.chevron_right,
        color: Colors.deepPurple.shade300,
        size: 22,
      ),
    );
  }
}
