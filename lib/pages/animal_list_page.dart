import 'package:flutter/material.dart';
import 'animal_detail_page.dart';
import '../core/utils.dart';
import '../core/config.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class AnimalListPage extends StatelessWidget {
  final String letter;
  const AnimalListPage({super.key, required this.letter});

  @override
  Widget build(BuildContext context) {
    final info =
        AppConfig.findLetter(letter)?.description ??
        '$letter hərfi haqqında məlumat yoxdur.';
    final animalObjects = AppConfig.findLetter(letter)?.animals ?? [];
    final animals = animalObjects.map((a) => a.name).toList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final animal in animals) {
        final animalInfo = AppConfig.findAnimal(letter, animal);
        final imageAsset = animalInfo?.imagePath ?? '';
        if (imageAsset.isNotEmpty) {
          precacheImage(AssetImage(imageAsset), context);
        }
      }
    });
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$letter hərfi',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          _LetterArrowAppBarButton(
            direction: ArrowDirection.left,
            currentLetter: letter,
          ),
          _LetterArrowAppBarButton(
            direction: ArrowDirection.right,
            currentLetter: letter,
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2E2B5F), Color(0xFF1B1A3A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hərf haqqında məlumat üçün dekorativ kart və səsləndirmə düyməsi
              const SizedBox(height: 10),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: [
                          Colors.deepPurple.shade400,
                          Colors.deepPurple.shade700,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withAlpha(46),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.yellowAccent.withAlpha(77),
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            info,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: -16,
                    left: -16,
                    child: _SoundButton(info: info, letter: letter),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              // Başlıq və dekorativ xətt
              Row(
                children: [
                  const Text(
                    'Heyvanlar',
                    style: TextStyle(
                      color: Colors.yellowAccent,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      shadows: [Shadow(color: Colors.black26, blurRadius: 8)],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: LinearGradient(
                          colors: [
                            Colors.yellowAccent.withAlpha((0.7 * 255).toInt()),
                            Colors.deepPurple.shade200.withAlpha(
                              (0.3 * 255).toInt(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Heyvanlar gridi
              Expanded(
                child:
                    animals.isEmpty
                        ? const Center(
                          child: Text(
                            'Bu hərflə başlayan heyvan yoxdur.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                        : GridView.builder(
                          padding: const EdgeInsets.only(top: 4),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 24,
                                crossAxisSpacing: 24,
                                childAspectRatio: 0.95,
                              ),
                          itemCount: animals.length,
                          itemBuilder: (context, index) {
                            final animal = animals[index];
                            getFirstLetter(animal);
                            final animalInfo = AppConfig.findAnimal(
                              letter,
                              animal,
                            );
                            final imageAsset = animalInfo?.imagePath ?? '';
                            return _ModernAnimalCard(
                              animal: animal,
                              imageAsset: imageAsset,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => AnimalDetailPage(
                                          animal: animal,
                                          animals: animals,
                                          currentIndex: index,
                                        ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Müasir heyvan kartı
class _ModernAnimalCard extends StatefulWidget {
  final String animal;
  final String imageAsset;
  final VoidCallback onTap;
  const _ModernAnimalCard({
    required this.animal,
    required this.imageAsset,
    required this.onTap,
  });

  @override
  State<_ModernAnimalCard> createState() => _ModernAnimalCardState();
}

class _ModernAnimalCardState extends State<_ModernAnimalCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: _hovered ? Colors.deepPurple.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withAlpha(
                  _hovered ? (0.22 * 255).toInt() : (0.10 * 255).toInt(),
                ),
                blurRadius: _hovered ? 28 : 14,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color:
                  _hovered ? Colors.orangeAccent : Colors.deepPurple.shade100,
              width: 2.2,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    widget.imageAsset,
                    width: double.infinity,
                    height: double.infinity,
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
                    errorBuilder:
                        (context, error, stackTrace) => Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.pets,
                            size: 60,
                            color: Colors.deepPurple,
                          ),
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.deepPurple.shade100,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withAlpha((0.06 * 255).toInt()),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  widget.animal,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade700,
                    letterSpacing: 1.1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Səsləndirmə düyməsi üçün xüsusi widget
class _SoundButton extends StatefulWidget {
  final String info;
  final String letter;
  const _SoundButton({required this.info, required this.letter});

  @override
  State<_SoundButton> createState() => _SoundButtonState();
}

class _SoundButtonState extends State<_SoundButton> {
  bool _hovered = false;
  bool _isPlaying = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();

    // Səs bitdikdə _isPlaying-i false et
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playSound(String audioPath) async {
    await _audioPlayer.setAsset(audioPath);
    await _audioPlayer.play();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Colors.yellowAccent, Colors.orangeAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: (_hovered ? Colors.deepPurple : Colors.yellowAccent)
                  .withAlpha((0.25 * 255).toInt()),
              blurRadius: 12,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.all(1),
        child: IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder:
                (child, anim) => ScaleTransition(scale: anim, child: child),
            child:
                _isPlaying
                    ? Icon(
                      Icons.stop,
                      key: const ValueKey('stop'),
                      color: Colors.deepPurple,
                      size: 22,
                    )
                    : Icon(
                      Icons.volume_up,
                      key: const ValueKey('play'),
                      color: Colors.deepPurple,
                      size: 22,
                    ),
          ),
          onPressed: () async {
            if (_isPlaying) {
              await _audioPlayer.stop();
              setState(() {
                _isPlaying = false;
              });
            } else {
              setState(() {
                _isPlaying = true;
              });
              final letter = widget.letter.toLowerCase();
              final audioPath =
                  'assets/audios/$letter/${letter}_info_sound.mp3';
              await _playSound(audioPath);
            }
          },
          splashRadius: 20,
          tooltip: _isPlaying ? 'Dayandır' : 'Səsləndir',
        ),
      ),
    );
  }
}

// Asset manifesti oxuyub cache-ləyən util sinfi
class AssetChecker {
  static Set<String>? _assets;
  static Future<void> _loadAssets() async {
    if (_assets != null) return;
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = jsonDecode(manifestContent);
    _assets = manifestMap.keys.toSet();
  }

  static Future<bool> hasAsset(String assetPath) async {
    if (_assets == null) {
      await _loadAssets();
    }
    return _assets!.contains(assetPath);
  }
}

// Ox düymələri üçün əlavə widget və enum

enum ArrowDirection { left, right }

class _LetterArrowAppBarButton extends StatelessWidget {
  final ArrowDirection direction;
  final String currentLetter;
  const _LetterArrowAppBarButton({
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
    return IconButton(
      icon: Icon(
        isLeft ? Icons.navigate_before : Icons.navigate_next,
        color: isDisabled ? Colors.white24 : Colors.white,
        size: 22,
      ),
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
                      const curve = Curves.easeInOutCubic;
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
                    transitionDuration: const Duration(milliseconds: 500),
                  ),
                );
              },
    );
  }
}
