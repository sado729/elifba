import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:collection/collection.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Əlifba',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AlphabetPage(),
    );
  }
}

String normalizeFileName(String input) {
  return input
      .toLowerCase()
      .replaceAll(' ', '_')
      .replaceAll('ı', 'i')
      .replaceAll('ə', 'e')
      .replaceAll('ö', 'o')
      .replaceAll('ü', 'u')
      .replaceAll('ç', 'c')
      .replaceAll('ş', 's')
      .replaceAll('ğ', 'g')
      .replaceAll('ə', 'e')
      .replaceAll('â', 'a')
      .replaceAll('î', 'i')
      .replaceAll('ü', 'u')
      .replaceAll('ö', 'o')
      .replaceAll('ş', 's')
      .replaceAll('ç', 'c')
      .replaceAll('ğ', 'g')
      .replaceAll('ı', 'i')
      .replaceAll('İ', 'i')
      .replaceAll('Ə', 'e')
      .replaceAll('Ç', 'c')
      .replaceAll('Ş', 's')
      .replaceAll('Ö', 'o')
      .replaceAll('Ü', 'u')
      .replaceAll('Ğ', 'g');
}

String getFirstLetter(String input) {
  final normalized = normalizeFileName(input);
  return normalized.isNotEmpty ? normalized[0] : '';
}

class AnimalListPage extends StatefulWidget {
  final String letter;
  final List<String> animals;
  const AnimalListPage({
    super.key,
    required this.letter,
    required this.animals,
  });

  @override
  State<AnimalListPage> createState() => _AnimalListPageState();
}

class _AnimalListPageState extends State<AnimalListPage> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.6);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animals = widget.animals;
    if (animals.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('"${widget.letter}" ilə başlayan heyvanlar'),
        ),
        body: const Center(child: Text('Heyvan tapılmadı')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text('"${widget.letter}" ilə başlayan heyvanlar')),
      body: Center(
        child: Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (animals.length > 1 && _currentPage > 0)
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 36),
                    onPressed: () {
                      if (_currentPage > 0) {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease,
                        );
                      }
                    },
                  ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: animals.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentPage = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            final animal = animals[index];
                            final animalLetter = getFirstLetter(animal);
                            final animalName = normalizeFileName(animal);
                            final imageAsset =
                                'animals/$animalLetter/$animalName/$animalName.png';
                            final isCurrent = index == _currentPage;
                            final scale = isCurrent ? 1.0 : 0.7;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.ease,
                              padding: const EdgeInsets.symmetric(
                                vertical: 32,
                                horizontal: 8,
                              ),
                              child: Transform.scale(
                                scale: scale,
                                child: GestureDetector(
                                  onTap:
                                      isCurrent
                                          ? () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) =>
                                                        AnimalDetailPage(
                                                          animal: animal,
                                                          animals: animals,
                                                          currentIndex: index,
                                                        ),
                                              ),
                                            );
                                          }
                                          : null,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          isCurrent ? 32 : 20,
                                        ),
                                        child: Image.asset(
                                          imageAsset,
                                          width: isCurrent ? 220 : 140,
                                          height: isCurrent ? 220 : 140,
                                          fit: BoxFit.contain,
                                          errorBuilder:
                                              (
                                                context,
                                                error,
                                                stackTrace,
                                              ) => Container(
                                                width: isCurrent ? 220 : 140,
                                                height: isCurrent ? 220 : 140,
                                                color: Colors.grey.shade200,
                                                child: const Icon(
                                                  Icons.image_not_supported,
                                                  size: 40,
                                                ),
                                              ),
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      Text(
                                        animal,
                                        style: TextStyle(
                                          fontSize: isCurrent ? 28 : 18,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              isCurrent
                                                  ? Colors.deepPurple
                                                  : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                if (animals.length > 1 && _currentPage < animals.length - 1)
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 36),
                    onPressed: () {
                      if (_currentPage < animals.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease,
                        );
                      }
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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
        'assets/animals/$animalLetter/$animalName/${animalName}_sound.mp3';
    try {
      await audioPlayer.stop();
      await audioPlayer.play(AssetSource(audioAsset));
    } catch (e) {
      // Səs faylı tapılmadı və ya səsləndirilə bilmədi
    }
  }

  void _playAnimalInfo(String animal) async {
    final animalLetter = getFirstLetter(animal);
    final animalName = normalizeFileName(animal);
    final audioAsset =
        'assets/animals/$animalLetter/$animalName/${animalName}_info.mp3';
    try {
      await audioPlayer.stop();
      await audioPlayer.play(AssetSource(audioAsset));
    } catch (e) {
      // Səs faylı tapılmadı və ya səsləndirilə bilmədi
    }
  }

  @override
  Widget build(BuildContext context) {
    final animal = widget.animal;
    final animalLetter = getFirstLetter(animal);
    final animalName = normalizeFileName(animal);
    final imageAsset = 'animals/$animalLetter/$animalName/$animalName.png';
    final info = animalInfo[animal] ?? 'Bu heyvan haqqında məlumat yoxdur.';
    final foods = animalFoods[animal] ?? ['Qida məlumatı yoxdur'];
    final animalsList = widget.animals;
    final currentIndex = widget.currentIndex;
    return Scaffold(
      appBar: AppBar(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Row(
                  children: [
                    const Icon(Icons.home, color: Colors.deepPurple, size: 22),
                    const SizedBox(width: 4),
                    Text(
                      'Əlifba',
                      style: TextStyle(
                        color: Colors.deepPurple.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  Icons.chevron_right,
                  size: 22,
                  color: Colors.deepPurple,
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (animalsList != null && currentIndex != null) {
                    Navigator.of(context).pop();
                  }
                },
                child: CircleAvatar(
                  radius: 13,
                  backgroundColor: Colors.deepPurple.shade100,
                  child: Text(
                    animalLetter.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  Icons.chevron_right,
                  size: 22,
                  color: Colors.deepPurple,
                ),
              ),
              Row(
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: Colors.deepPurple.shade200,
                    child: Icon(Icons.pets, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    animal,
                    style: TextStyle(
                      color: Colors.deepPurple.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
                      IconButton(
                        tooltip: 'Haqqında',
                        icon: const Icon(Icons.info, size: 32),
                        onPressed: () {
                          setState(() {
                            showInfo = !showInfo;
                            showFoods = false;
                            showPuzzle = false;
                          });
                        },
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        tooltip: 'Qidaları',
                        icon: const Icon(Icons.restaurant, size: 32),
                        onPressed: () {
                          setState(() {
                            showFoods = !showFoods;
                            showInfo = false;
                            showPuzzle = false;
                          });
                        },
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        tooltip: 'Heyvanın səsi',
                        icon: const Icon(Icons.volume_up, size: 32),
                        onPressed: () => _playAnimalSound(animal),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        tooltip: 'Puzzle',
                        icon: const Icon(Icons.extension, size: 32),
                        onPressed: () {
                          setState(() {
                            showPuzzle = !showPuzzle;
                            showInfo = false;
                            showFoods = false;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (showPuzzle)
                    Padding(
                      padding: const EdgeInsets.only(top: 24.0),
                      child: PuzzlePage(animal: animal),
                    )
                  else ...[
                    ClipRRect(
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            tooltip: 'Haqqında səsləndir',
                            icon: const Icon(Icons.record_voice_over, size: 28),
                            onPressed: () => _playAnimalInfo(animal),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              info,
                              style: const TextStyle(fontSize: 20),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
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
                              children:
                                  foods.map((food) {
                                    final foodLetter = getFirstLetter(food);
                                    final foodImage =
                                        'foods/${normalizeFileName(food)}.png';
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            child: Image.asset(
                                              foodImage,
                                              width: 64,
                                              height: 64,
                                              fit: BoxFit.contain,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Container(
                                                    width: 64,
                                                    height: 64,
                                                    color: Colors.grey.shade200,
                                                    child: const Icon(
                                                      Icons.fastfood,
                                                      size: 32,
                                                    ),
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          ElevatedButton(
                                            onPressed: () {},
                                            style: ElevatedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: Text(
                                              food,
                                              style: const TextStyle(
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
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
}

class AlphabetPage extends StatelessWidget {
  const AlphabetPage({super.key});

  static const List<String> alphabet = [
    'A',
    'B',
    'C',
    'Ç',
    'D',
    'E',
    'Ə',
    'F',
    'G',
    'Ğ',
    'H',
    'X',
    'I',
    'İ',
    'J',
    'K',
    'Q',
    'L',
    'M',
    'N',
    'O',
    'Ö',
    'P',
    'R',
    'S',
    'Ş',
    'T',
    'U',
    'Ü',
    'V',
    'Y',
    'Z',
  ];

  static const Map<String, List<String>> animalsByLetter = {
    'A': ['At', 'Ayı', 'Ağcaqanad'],
    'B': ['Balıq', 'Bayquş', 'Böcək'],
    'C': ['Ceyran', 'Cücə', 'Cırtdan balıq'],
    'Ç': ['Çalağan', 'Çaylaq'],
    'D': ['Dovşan', 'Dəvə', 'Dəvəquşu'],
    'E': ['Eşşək', 'Eşşəkarısı'],
    'Ə': ['Əqrəb'],
    'F': ['Fil', 'Fərasət quşu'],
    'G': ['Gəmirici', 'Güvən'],
    'Ğ': ['Ğöyərçin'],
    'H': ['Hinduşka', 'Hörümçək'],
    'X': ['Xallı kəpənək'],
    'I': ['Ilbiz'],
    'İ': ['İlan', 'İt'],
    'J': ['Jeyran'],
    'K': ['Kəpənək', 'Kərgədan'],
    'Q': ['Qartal', 'Qurbağa', 'Qurd'],
    'L': ['Ləpirdə', 'Lələ'],
    'M': ['Meymun', 'Marsa quşu'],
    'N': ['Nərə balığı'],
    'O': ['Oğlaq', 'Ordek'],
    'Ö': ['Ördək'],
    'P': ['Pələng', 'Pinqvin'],
    'R': ['Rakun'],
    'S': ['Siçan', 'Sincab'],
    'Ş': ['Şahin', 'Şir'],
    'T': ['Tısbağa', 'Tülkü'],
    'U': ['Ulaq'],
    'Ü': ['Üzgüçü balıq'],
    'V': ['Vaşaq'],
    'Y': ['Yarasa', 'Yaylaq quşu'],
    'Z': ['Zürafə', 'Zebra'],
  };

  void _openAnimalList(BuildContext context, String letter) {
    final animals = animalsByLetter[letter] ?? [];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnimalListPage(letter: letter, animals: animals),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Azərbaycan Əlifbası'),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              itemCount: alphabet.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final letter = alphabet[index];
                return GestureDetector(
                  onTap: () => _openAnimalList(context, letter),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.deepPurple.shade100,
                    child: Text(
                      letter,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Burada əlavə kontent və ya təlimat yerləşdirə bilərsən
        ],
      ),
    );
  }
}

class PuzzlePage extends StatefulWidget {
  final String animal;
  const PuzzlePage({super.key, required this.animal});

  @override
  State<PuzzlePage> createState() => _PuzzlePageState();
}

class _PuzzlePageState extends State<PuzzlePage> {
  static const int gridSize = 3;
  static const double fullSize = 240;
  static const double tileSize = fullSize / gridSize;
  late List<int?> slots; // griddəki yerlər (null və ya parça indeksi)
  late List<int> pieces; // aşağıda qarışıq parçalar
  bool completed = false;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _resetPuzzle();
  }

  void _resetPuzzle() {
    slots = List<int?>.filled(gridSize * gridSize, null);
    pieces = List.generate(gridSize * gridSize, (i) => i);
    pieces.shuffle();
    setState(() {
      completed = false;
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _onPieceDropped(int slotIndex, int pieceIndex) {
    setState(() {
      slots[slotIndex] = pieceIndex;
      pieces.remove(pieceIndex);
      if (_isCompleted()) {
        completed = true;
        _confettiController.play();
        Future.delayed(const Duration(milliseconds: 1500), () {
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Təbriklər!'),
                  content: const Text('Puzzle tamamlandı!'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _resetPuzzle();
                      },
                      child: const Text('Yenidən'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Bağla'),
                    ),
                  ],
                ),
          );
        });
      }
    });
  }

  bool _isCompleted() {
    for (int i = 0; i < slots.length; i++) {
      if (slots[i] != i) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final animal = widget.animal;
    final animalLetter = getFirstLetter(animal);
    final animalName = normalizeFileName(animal);
    final imageAsset =
        'animals/$animalLetter/$animalName/${animalName}_puzzle.jpg';
    return Stack(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Puzzle grid (yuxarıda)
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.deepPurple, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridSize,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 2,
                  ),
                  itemCount: gridSize * gridSize,
                  itemBuilder: (context, i) {
                    int row = i ~/ gridSize;
                    int col = i % gridSize;
                    int? pieceIndex = slots[i];
                    return SizedBox(
                      width: tileSize,
                      height: tileSize,
                      child: DragTarget<int>(
                        builder: (context, candidateData, rejectedData) {
                          if (pieceIndex != null) {
                            return Draggable<int>(
                              data: i, // slot index
                              feedback: Material(
                                color: Colors.transparent,
                                child: SizedBox(
                                  width: tileSize,
                                  height: tileSize,
                                  child: _buildPuzzlePiece(
                                    imageAsset,
                                    pieceIndex,
                                    gridSize,
                                    shadow: true,
                                  ),
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.3,
                                child: _buildPuzzlePiece(
                                  imageAsset,
                                  pieceIndex,
                                  gridSize,
                                ),
                              ),
                              child: _buildPuzzlePiece(
                                imageAsset,
                                pieceIndex,
                                gridSize,
                              ),
                            );
                          } else if (candidateData.isNotEmpty) {
                            return Container(color: Colors.deepPurple.shade100);
                          } else {
                            return Container(color: Colors.deepPurple.shade50);
                          }
                        },
                        onWillAccept: (data) => true,
                        onAccept: (fromIndex) {
                          setState(() {
                            if (pieceIndex == null &&
                                fromIndex is int &&
                                fromIndex < slots.length &&
                                slots[fromIndex] != null) {
                              // slotdan slot-a sürüşdürülür
                              slots[i] = slots[fromIndex];
                              slots[fromIndex] = null;
                            } else if (pieceIndex == null &&
                                fromIndex is int &&
                                fromIndex >= slots.length) {
                              // aşağıdan gridə sürüşdürülür
                              int pieceIdx = pieces[fromIndex - slots.length];
                              slots[i] = pieceIdx;
                              pieces.removeAt(fromIndex - slots.length);
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Puzzle parçaları (aşağıda)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                pieces.length,
                (idx) => Draggable<int>(
                  data: slots.length + idx, // fərqləndirici data
                  feedback: Material(
                    color: Colors.transparent,
                    child: SizedBox(
                      width: tileSize,
                      height: tileSize,
                      child: _buildPuzzlePiece(
                        imageAsset,
                        pieces[idx],
                        gridSize,
                        shadow: true,
                      ),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: SizedBox(
                      width: tileSize,
                      height: tileSize,
                      child: _buildPuzzlePiece(
                        imageAsset,
                        pieces[idx],
                        gridSize,
                      ),
                    ),
                  ),
                  child: SizedBox(
                    width: tileSize,
                    height: tileSize,
                    child: _buildPuzzlePiece(imageAsset, pieces[idx], gridSize),
                  ),
                ),
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            emissionFrequency: 0.08,
            numberOfParticles: 30,
            maxBlastForce: 20,
            minBlastForce: 8,
            gravity: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildPuzzlePiece(
    String imageAsset,
    int pieceIndex,
    int gridSize, {
    bool shadow = false,
  }) {
    int row = pieceIndex ~/ gridSize;
    int col = pieceIndex % gridSize;
    return FutureBuilder<ui.Image>(
      future: _loadImage(imageAsset),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            width: tileSize,
            height: tileSize,
            color: Colors.grey.shade200,
            child: const Icon(Icons.image, size: 40),
          );
        }
        return Container(
          width: tileSize,
          height: tileSize,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.deepPurple.shade200, width: 2),
            boxShadow:
                shadow
                    ? [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(2, 2),
                      ),
                    ]
                    : null,
          ),
          child: CustomPaint(
            size: Size(tileSize, tileSize),
            painter: PuzzleTilePainter(snapshot.data!, row, col, gridSize),
          ),
        );
      },
    );
  }

  Future<ui.Image> _loadImage(String asset) async {
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}

class PuzzleTilePainter extends CustomPainter {
  final ui.Image image;
  final int row, col, gridSize;
  PuzzleTilePainter(this.image, this.row, this.col, this.gridSize);

  @override
  void paint(Canvas canvas, Size size) {
    final tileSize = size.width;
    final srcTileSize = image.width / gridSize;
    final src = Rect.fromLTWH(
      col * srcTileSize,
      row * srcTileSize,
      srcTileSize,
      srcTileSize,
    );
    final dst = Rect.fromLTWH(0, 0, tileSize, tileSize);
    canvas.drawImageRect(image, src, dst, Paint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
