import 'package:flutter/material.dart';
import 'animal_detail_page.dart';
import '../core/utils.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AnimalListPage extends StatelessWidget {
  final String letter;
  final List<String> animals;
  const AnimalListPage({
    super.key,
    required this.letter,
    required this.animals,
  });

  static const Map<String, String> letterInfo = {
    'A':
        'A yaxud a — çağdaş Azərbaycan əlifbası kimi Yer üzündəki bir çox dildə işlədilən latın əlifbasının ilk hərfi.Azərbaycan dilində hərfə a adı verilib.Hərfin böyük versiyasının görünüşü ortasından üfüqi xətt keçən bir nöqtədən çəkilmiş iki əyri xətt kimidir. Kiçik a hərfi isə iki cür yazılır: ikiqatlı a və birqatlı ɑ. Birinci görünüş, əsasən, çap yazısında, ikincisi isə, əsasən, əl yazısında və əl yazısı əsaslı şriftlərdə istifadə olunmaqdadır.',
    'B': 'B hərfi əlifbanın ikinci hərfidir.',
    'C': 'C hərfi əlifbanın üçüncü hərfidir.',
    'Ç': 'Ç hərfi əlifbanın dördüncü hərfidir.',
    'D': 'D hərfi əlifbanın beşinci hərfidir.',
    'E': 'E hərfi əlifbanın altıncı hərfidir.',
    'Ə': 'Ə hərfi əlifbanın yeddinci hərfidir.',
    'F': 'F hərfi əlifbanın səkkizinci hərfidir.',
    'G': 'G hərfi əlifbanın doqquzuncu hərfidir.',
    'Ğ': 'Ğ hərfi əlifbanın onuncu hərfidir.',
    'H': 'H hərfi əlifbanın on birinci hərfidir.',
    'X': 'X hərfi əlifbanın on ikinci hərfidir.',
    'I': 'I hərfi əlifbanın on üçüncü hərfidir.',
    'İ': 'İ hərfi əlifbanın on dördüncü hərfidir.',
    'J': 'J hərfi əlifbanın on beşinci hərfidir.',
    'K': 'K hərfi əlifbanın on altıncı hərfidir.',
    'Q': 'Q hərfi əlifbanın on yeddinci hərfidir.',
    'L': 'L hərfi əlifbanın on səkkizinci hərfidir.',
    'M': 'M hərfi əlifbanın on doqquzuncu hərfidir.',
    'N': 'N hərfi əlifbanın iyirminci hərfidir.',
    'O': 'O hərfi əlifbanın iyirmi birinci hərfidir.',
    'Ö': 'Ö hərfi əlifbanın iyirmi ikinci hərfidir.',
    'P': 'P hərfi əlifbanın iyirmi üçüncü hərfidir.',
    'R': 'R hərfi əlifbanın iyirmi dördüncü hərfidir.',
    'S': 'S hərfi əlifbanın iyirmi beşinci hərfidir.',
    'Ş': 'Ş hərfi əlifbanın iyirmi altıncı hərfidir.',
    'T': 'T hərfi əlifbanın iyirmi yeddinci hərfidir.',
    'U': 'U hərfi əlifbanın iyirmi səkkizinci hərfidir.',
    'Ü': 'Ü hərfi əlifbanın iyirmi doqquzuncu hərfidir.',
    'V': 'V hərfi əlifbanın otuzuncu hərfidir.',
    'Y': 'Y hərfi əlifbanın otuz birinci hərfidir.',
    'Z': 'Z hərfi əlifbanın otuz ikinci hərfidir.',
  };

  @override
  Widget build(BuildContext context) {
    final info = letterInfo[letter] ?? '$letter hərfi haqqında məlumat yoxdur.';
    final tts = FlutterTts();
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
                    child: _SoundButton(info: info, tts: tts),
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
                        ? Center(
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
                            final animalLetter = getFirstLetter(animal);
                            final animalName = normalizeFileName(animal);
                            final imageAsset =
                                'animals/$animalLetter/$animalName.png';
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
                    fit: BoxFit.cover,
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
  final FlutterTts tts;
  const _SoundButton({required this.info, required this.tts});

  @override
  State<_SoundButton> createState() => _SoundButtonState();
}

class _SoundButtonState extends State<_SoundButton> {
  bool _hovered = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    widget.tts.setCompletionHandler(() {
      setState(() {
        _isPlaying = false;
      });
    });
    widget.tts.setCancelHandler(() {
      setState(() {
        _isPlaying = false;
      });
    });
    widget.tts.setErrorHandler((msg) {
      setState(() {
        _isPlaying = false;
      });
    });
    widget.tts.setPauseHandler(() {
      setState(() {
        _isPlaying = false;
      });
    });
  }

  Future<void> _handleTap() async {
    if (_isPlaying) {
      await widget.tts.stop();
      setState(() {
        _isPlaying = false;
      });
    } else {
      await widget.tts.setLanguage('az-AZ');
      await widget.tts.speak(widget.info);
      setState(() {
        _isPlaying = true;
      });
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
                  .withOpacity(0.25),
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
          onPressed: _handleTap,
          splashRadius: 20,
          tooltip: _isPlaying ? 'Dayandır' : 'Səsləndir',
        ),
      ),
    );
  }
}
