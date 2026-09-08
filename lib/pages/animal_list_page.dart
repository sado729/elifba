import 'package:flutter/material.dart';
import 'animal_detail_page.dart';
import 'letter_writing_page.dart';
import '../core/config.dart';
import '../core/letter_strokes.dart';
import 'package:just_audio/just_audio.dart';

/// Qrid xanasındaki heyvan şəkli üçün dekod eni. Bütün heyvan şəkilləri
/// 400x400 WebP-dir və xana ~160 px göstərilir; `cacheWidth` şəkli böyütmür,
/// ona görə bu dəyər mənbə ölçüsü ilə eynidir və detal səhifəsindəki hero ilə
/// eyni image-cache açarını paylaşır (iki ayrı dekod yaranmır).
const int kAnimalThumbDecodeWidth = 400;

class AnimalListPage extends StatefulWidget {
  final String letter;
  const AnimalListPage({super.key, required this.letter});

  @override
  State<AnimalListPage> createState() => _AnimalListPageState();
}

class _AnimalListPageState extends State<AnimalListPage> {
  /// Hərf haqqında mətn ilk açılışda gizlidir; başlığa toxunanda açılır.
  bool _infoExpanded = false;

  @override
  void initState() {
    super.initState();
    // Şəkilləri qabaqcadan yüklə. Ölçü qridd-dəki `cacheWidth` ilə eyni olmalıdır,
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

  @override
  Widget build(BuildContext context) {
    // Android 16 (API 36) forces edge-to-edge, so the system bars overlay the
    // body: inset the content by the window's view padding manually.
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final letter = widget.letter;
    final info =
        AppConfig.findLetter(letter)?.description ??
        '$letter hərfi haqqında məlumat yoxdur.';
    final animalObjects = AppConfig.findLetter(letter)?.animals ?? [];
    final animals = animalObjects.map((a) => a.name).toList();
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
          // Yazı oyunu buradan açılır: bu səhifə əsl hərfi (Ə, Ş...) bilir, ona
          // görə diakritikanı normalizasiyadan yenidən çıxarmaq lazım gəlmir.
          if (LetterStrokes.has(letter))
            IconButton(
              icon: const Icon(Icons.draw_outlined),
              tooltip: '$letter hərfini yaz',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LetterWritingPage(letter: letter),
                ),
              ),
            ),
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
          padding: EdgeInsets.fromLTRB(
            16 + viewPadding.left,
            18,
            16 + viewPadding.right,
            18 + viewPadding.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hərf haqqında məlumat üçün dekorativ kart və səsləndirmə düyməsi.
              // Mətn ilk açılışda bağlıdır: yalnız başlıq görünür, uşaq istəsə
              // ona toxunub açır. Beləcə ekranın böyük hissəsi heyvanlara qalır.
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Şəffaf Material olmasa dalğa effekti gradient
                        // Container-in altında, Scaffold-un Material-ində qalır.
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap:
                                () => setState(() {
                                  _infoExpanded = !_infoExpanded;
                                }),
                            child: Padding(
                              padding: EdgeInsets.only(
                                // Səsləndirmə düyməsi kartın sol yuxarı küncünü
                                // örtür; başlıq onun altında qalmasın.
                                left: AppConfig.hasLetterAudio(letter) ? 26 : 0,
                                top: 2,
                                bottom: 2,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _infoExpanded
                                          ? '$letter hərfi haqqında'
                                          : '$letter hərfi haqqında oxu',
                                      style: const TextStyle(
                                        color: Colors.yellowAccent,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  AnimatedRotation(
                                    turns: _infoExpanded ? 0.5 : 0,
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeInOut,
                                    child: const Icon(
                                      Icons.expand_more,
                                      color: Colors.yellowAccent,
                                      size: 26,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        AnimatedCrossFade(
                          firstChild: const SizedBox(
                            width: double.infinity,
                            height: 0,
                          ),
                          secondChild: Padding(
                            padding: const EdgeInsets.only(top: 10),
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
                          crossFadeState:
                              _infoExpanded
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 250),
                          sizeCurve: Curves.easeInOut,
                        ),
                      ],
                    ),
                  ),
                  // Səs faylı olmayan hərfdə düyməni ümumiyyətlə göstərmirik:
                  // 32 hərfdən yalnız A, B, C-nin tələffüz səsi var.
                  if (AppConfig.hasLetterAudio(letter))
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

  Future<void> _playLetterSound() async {
    final audioPath = AppConfig.letterAudioPath(widget.letter);
    setState(() {
      _isPlaying = true;
    });
    try {
      await _playSound(audioPath);
    } catch (e) {
      // Fayl yoxdursa və ya oxunmursa düymə "dayandır" vəziyyətində ilişməsin.
      debugPrint('Hərf səsi oxunmadı ($audioPath): $e');
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    }
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
              await _playLetterSound();
            }
          },
          splashRadius: 20,
          tooltip: _isPlaying ? 'Dayandır' : 'Səsləndir',
        ),
      ),
    );
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
