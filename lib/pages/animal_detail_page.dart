import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import '../core/utils.dart';
import 'puzzle_page.dart';
import 'package:flutter/services.dart';
import 'animal_word_puzzle.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui' as ui;
import 'dart:html' as html;

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
  bool showWordPuzzle = false;
  bool showYoutube = false;
  late ConfettiController _confettiController;

  // --- ANİMASİYA üçün əlavə ---
  final GlobalKey _animalImageKey = GlobalKey();
  final Map<int, GlobalKey> _foodButtonKeys = {};

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

  // --- Əlavə: Səs və puzzle üçün map-lar ---
  static const Map<String, bool> animalHasSound = {
    'At': false,
    'Ayı': true,
    'Ceyran': false,
    'Fil': false,
    'Pələng': false,
    'İlan': false,
    'Qartal': false,
    'Dovşan': false,
    'Balıq': false,
    // ... digər heyvanlar ...
  };

  static const Map<String, bool> animalHasPuzzle = {
    'At': true,
    'Ayı': false,
    'Ceyran': false,
    'Fil': false,
    'Pələng': false,
    'İlan': false,
    'Qartal': false,
    'Dovşan': false,
    'Balıq': false,
    // ... digər heyvanlar ...
  };

  // Youtube embed kodları üçün map
  static const Map<String, String> animalYoutubeEmbeds = {
    'At': 'https://www.youtube.com/embed/24FqPV30Af4',
    // ... digər heyvanlar üçün əlavə edə bilərsən ...
  };

  void _playAnimalSound(String animal) async {
    final animalLetter = getFirstLetter(animal);
    final animalName = normalizeFileName(animal);
    final audioAsset = 'animals/$animalLetter/${animalName}_sound.mp3';
    try {
      await audioPlayer.stop();
      await audioPlayer.play(AssetSource(audioAsset));
    } catch (e) {}
  }

  void _playAnimalInfo(String animal) async {
    final animalLetter = getFirstLetter(animal);
    final animalName = normalizeFileName(animal);
    final audioAsset = 'animals/$animalLetter/${animalName}_info.mp3';
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
    final imageAsset = 'animals/$animalLetter/$animalName.png';
    final puzzleAsset = 'animals/$animalLetter/${animalName}_puzzle.jpg';
    final info = animalInfo[animal] ?? 'Bu heyvan haqqında məlumat yoxdur.';
    final foods = animalFoods[animal] ?? [];
    final animalsList = widget.animals;
    final currentIndex = widget.currentIndex;
    final animalSoundAsset = 'animals/$animalLetter/${animalName}_sound.mp3';

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
            showWordPuzzle = false;
            showYoutube = false;
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
              showWordPuzzle = false;
              showYoutube = false;
            });
          },
          visible: true,
        ),
    ];
    // Səs iconunu yalnız map-da true olan heyvanlar üçün əlavə et
    if (animalHasSound[animal] == true) {
      actions.add(
        _ActionButtonData(
          tooltip: 'Heyvanın səsi',
          icon: Icons.volume_up,
          selected: false,
          onTap: () {
            _playAnimalSound(animal);
            setState(() {
              showYoutube = false;
            });
          },
          visible: true,
        ),
      );
    }
    // Puzzle iconunu yalnız map-da true olan heyvanlar üçün əlavə et
    if (animalHasPuzzle[animal] == true) {
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
              showWordPuzzle = false;
              showYoutube = false;
            });
          },
          visible: true,
        ),
      );
    }
    // Hərf oyunu iconu (ən sağda)
    actions.add(
      _ActionButtonData(
        tooltip: 'Hərf oyunu',
        icon: Icons.spellcheck,
        selected: showWordPuzzle,
        onTap: () {
          setState(() {
            showWordPuzzle = true;
            showInfo = false;
            showFoods = false;
            showPuzzle = false;
            showYoutube = false;
          });
        },
        visible: true,
      ),
    );
    // Youtube video iconu yalnız map-da varsa əlavə et
    if (animalYoutubeEmbeds[animal] != null &&
        animalYoutubeEmbeds[animal]!.isNotEmpty) {
      actions.add(
        _ActionButtonData(
          tooltip: 'Youtube video',
          icon: Icons.ondemand_video,
          selected: showYoutube,
          onTap: () {
            setState(() {
              showYoutube = true;
              showInfo = false;
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
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 26,
          ),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Geri',
        ),
        title: Text(
          animal,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Heyvan şəkli və oxlar bir blokda
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withAlpha(
                            (0.08 * 255).toInt(),
                          ),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.deepPurple.shade50,
                        width: 1.2,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 18,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ClipRRect(
                              key: _animalImageKey,
                              borderRadius: BorderRadius.circular(28),
                              child: Image.asset(
                                imageAsset,
                                width: 180,
                                height: 180,
                                fit: BoxFit.contain,
                                errorBuilder:
                                    (context, error, stackTrace) => Container(
                                      width: 180,
                                      height: 180,
                                      color: Colors.grey.shade200,
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        size: 40,
                                      ),
                                    ),
                              ),
                            ),
                          ],
                        ),
                        // Ortalanmış oxlar
                        if (animalsList != null &&
                            currentIndex != null &&
                            animalsList.length > 1) ...[
                          if (currentIndex > 0)
                            Positioned(
                              left: 0,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Tooltip(
                                  message: 'Əvvəlki',
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.arrow_back_ios,
                                      size: 36,
                                    ),
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => AnimalDetailPage(
                                                animal:
                                                    animalsList[currentIndex -
                                                        1],
                                                animals: animalsList,
                                                currentIndex: currentIndex - 1,
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          if (currentIndex < animalsList.length - 1)
                            Positioned(
                              right: 0,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Tooltip(
                                  message: 'Növbəti',
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 36,
                                    ),
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => AnimalDetailPage(
                                                animal:
                                                    animalsList[currentIndex +
                                                        1],
                                                animals: animalsList,
                                                currentIndex: currentIndex + 1,
                                              ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                  // Şəkil ilə buttonlar arasında məsafə
                  const SizedBox(height: 18),
                  // Action buttonlar ayrıca və ortada
                  Builder(
                    builder: (context) {
                      return FutureBuilder<List<Widget>>(
                        future: _buildVisibleActions(actions),
                        builder: (context, snapshot) {
                          final visibleActions = snapshot.data ?? [];
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: separatedBySpace(visibleActions),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  if (showWordPuzzle) ...[
                    const Text(
                      'Heyvanın adını düzgün yığ!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimalWordPuzzle(word: animal),
                  ],
                  if (showYoutube && animalYoutubeEmbeds[animal] != null) ...[
                    const SizedBox(height: 16),
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.black,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: YoutubeVideoWidget(
                            embedUrl: animalYoutubeEmbeds[animal]!,
                            uniqueKey:
                                'youtube-iframe-${animalYoutubeEmbeds[animal]!}',
                          ),
                        ),
                      ),
                    ),
                  ],
                  Expanded(
                    child: SingleChildScrollView(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child:
                            showPuzzle
                                ? Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: PuzzlePage(animal: animal),
                                )
                                : Column(
                                  children: [
                                    if (showInfo)
                                      Container(
                                        constraints: const BoxConstraints(
                                          maxWidth: 520,
                                        ),
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 22,
                                          vertical: 20,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.deepPurple.shade50,
                                          borderRadius: BorderRadius.circular(
                                            22,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.deepPurple
                                                  .withAlpha(
                                                    (0.08 * 255).toInt(),
                                                  ),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
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
                                                    color:
                                                        Colors
                                                            .deepPurple
                                                            .shade700,
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
                                                  onPressed:
                                                      () => _playAnimalInfo(
                                                        animal,
                                                      ),
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
                                    if (showFoods)
                                      Container(
                                        constraints: const BoxConstraints(
                                          maxWidth: 520,
                                        ),
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 22,
                                          vertical: 20,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.deepPurple.shade50,
                                          borderRadius: BorderRadius.circular(
                                            22,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.deepPurple
                                                  .withAlpha(
                                                    (0.08 * 255).toInt(),
                                                  ),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                                children: List.generate(foods.length, (
                                                  idx,
                                                ) {
                                                  final food = foods[idx];
                                                  final foodImage =
                                                      'foods/${normalizeFileName(food)}.png';
                                                  _foodButtonKeys.putIfAbsent(
                                                    idx,
                                                    () => GlobalKey(),
                                                  );
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6.0,
                                                        ),
                                                    child: Material(
                                                      color: Colors.transparent,
                                                      child: InkWell(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              18,
                                                            ),
                                                        onTap:
                                                            () {}, // gələcəkdə istifadə üçün
                                                        child: AnimatedContainer(
                                                          duration:
                                                              const Duration(
                                                                milliseconds:
                                                                    200,
                                                              ),
                                                          curve:
                                                              Curves.easeInOut,
                                                          decoration: BoxDecoration(
                                                            color: Colors.white,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  18,
                                                                ),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Colors
                                                                    .deepPurple
                                                                    .withAlpha(
                                                                      (0.08 * 255)
                                                                          .toInt(),
                                                                    ),
                                                                blurRadius: 8,
                                                                offset:
                                                                    const Offset(
                                                                      0,
                                                                      2,
                                                                    ),
                                                              ),
                                                            ],
                                                            border: Border.all(
                                                              color:
                                                                  Colors
                                                                      .deepPurple
                                                                      .shade100,
                                                              width: 1.2,
                                                            ),
                                                          ),
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 12,
                                                                vertical: 10,
                                                              ),
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              ClipRRect(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12,
                                                                    ),
                                                                child: Image.asset(
                                                                  foodImage,
                                                                  width: 56,
                                                                  height: 56,
                                                                  fit:
                                                                      BoxFit
                                                                          .contain,
                                                                  errorBuilder:
                                                                      (
                                                                        context,
                                                                        error,
                                                                        stackTrace,
                                                                      ) => Container(
                                                                        width:
                                                                            56,
                                                                        height:
                                                                            56,
                                                                        color:
                                                                            Colors.grey.shade200,
                                                                        child: const Icon(
                                                                          Icons
                                                                              .fastfood,
                                                                          size:
                                                                              28,
                                                                        ),
                                                                      ),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                height: 8,
                                                              ),
                                                              Container(
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          10,
                                                                      vertical:
                                                                          4,
                                                                    ),
                                                                decoration: BoxDecoration(
                                                                  color:
                                                                      Colors
                                                                          .deepPurple
                                                                          .shade100,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        10,
                                                                      ),
                                                                ),
                                                                child: Text(
                                                                  food,
                                                                  style: const TextStyle(
                                                                    fontSize:
                                                                        15,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color:
                                                                        Colors
                                                                            .deepPurple,
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                height: 6,
                                                              ),
                                                              ElevatedButton(
                                                                key:
                                                                    _foodButtonKeys[idx],
                                                                onPressed: () {
                                                                  _animateFoodToAnimal(
                                                                    idx,
                                                                  );
                                                                },
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .white,
                                                                  foregroundColor:
                                                                      Colors
                                                                          .deepPurple,
                                                                  elevation: 0,
                                                                  padding:
                                                                      const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            16,
                                                                        vertical:
                                                                            8,
                                                                      ),
                                                                  shape: RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          12,
                                                                        ),
                                                                    side: BorderSide(
                                                                      color:
                                                                          Colors
                                                                              .deepPurple
                                                                              .shade200,
                                                                    ),
                                                                  ),
                                                                ),
                                                                child: Row(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    const Icon(
                                                                      Icons
                                                                          .favorite,
                                                                      size: 18,
                                                                      color:
                                                                          Colors
                                                                              .pink,
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 6,
                                                                    ),
                                                                    Text(
                                                                      'Qidalandır',
                                                                      style: const TextStyle(
                                                                        fontSize:
                                                                            15,
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
                                      ),
                                  ],
                                ),
                      ),
                    ),
                  ),
                ],
              ),
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

  Future<List<Widget>> _buildVisibleActions(
    List<_ActionButtonData> actions,
  ) async {
    List<Widget> result = [];
    for (final action in actions) {
      if (action.visibleFuture != null) {
        final visible = await action.visibleFuture!;
        if (visible) {
          result.add(_ActionButton(action: action));
        }
      } else if (action.visible) {
        result.add(_ActionButton(action: action));
      }
    }
    return result;
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
                      Colors.pinkAccent.withAlpha((0.7 * 255).toInt()),
                      Colors.pink.withAlpha((0.0 * 255).toInt()),
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
                        color: Colors.deepPurple.withAlpha(
                          (0.10 * 255).toInt(),
                        ),
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

List<Widget> separatedBySpace(List<Widget> widgets, {double space = 10}) {
  final result = <Widget>[];
  for (var i = 0; i < widgets.length; i++) {
    result.add(widgets[i]);
    if (i != widgets.length - 1) {
      result.add(SizedBox(width: space));
    }
  }
  return result;
}

// Youtube universal widget
class YoutubeVideoWidget extends StatefulWidget {
  final String embedUrl;
  final String uniqueKey;
  const YoutubeVideoWidget({
    required this.embedUrl,
    required this.uniqueKey,
    super.key,
  });

  @override
  State<YoutubeVideoWidget> createState() => _YoutubeVideoWidgetState();
}

class _YoutubeVideoWidgetState extends State<YoutubeVideoWidget> {
  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(
        widget.uniqueKey,
        (int viewId) =>
            html.IFrameElement()
              ..width = '100%'
              ..height = '100%'
              ..src = widget.embedUrl
              ..style.border = 'none'
              ..allowFullscreen = true
              ..allow = 'autoplay; encrypted-media',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return HtmlElementView(viewType: widget.uniqueKey);
    } else {
      return Container(
        alignment: Alignment.center,
        child: const Text(
          'Youtube videosu yalnız mobil platformalarda göstərilir.',
          style: TextStyle(color: Colors.white),
        ),
      );
      // Əgər mobil üçün WebView əlavə etmək istəyirsinizsə, aşağıdakı kodu açın:
      // return WebView(
      //   initialUrl: widget.embedUrl,
      //   javascriptMode: JavascriptMode.unrestricted,
      // );
    }
  }
}
