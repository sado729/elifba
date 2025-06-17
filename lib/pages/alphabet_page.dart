import 'package:flutter/material.dart';
import 'animal_list_page.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../core/config.dart';
import 'package:just_audio/just_audio.dart';

class AlphabetPage extends StatefulWidget {
  const AlphabetPage({super.key});

  @override
  State<AlphabetPage> createState() => _AlphabetPageState();
}

class _AlphabetPageState extends State<AlphabetPage> {
  static const List<String> alphabet = AppConfig.alphabet;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _audioPlayer.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _playPageFlipSound() async {
    await _audioPlayer.setAsset('assets/audios/page_flip.mp3');
    await _audioPlayer.play();
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
          const curve = Curves.easeInOutCubic;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < (alphabet.length / 2).ceil() - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
      _playPageFlipSound();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
      _playPageFlipSound();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(color: Colors.deepPurple.shade700),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 32),
              Text(
                'Əlifba',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                  shadows: [Shadow(color: Colors.black26, blurRadius: 8)],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      children: [
                        for (int i = 0; i < (alphabet.length / 2).ceil(); i++)
                          _BookPage(
                            firstLetter: alphabet[i * 2],
                            secondLetter:
                                i * 2 + 1 < alphabet.length
                                    ? alphabet[i * 2 + 1]
                                    : null,
                            pageNumber: i + 1,
                            onTap: (letter) => _openAnimalList(context, letter),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16, top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      onPressed: _previousPage,
                    ),
                    Icon(
                      Icons.menu_book,
                      color: Colors.white.withOpacity(0.8),
                      size: 28,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      onPressed: _nextPage,
                    ),
                  ],
                ),
              ),
            ],
          ),
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
    await _loadAssets();
    return _assets!.contains(assetPath);
  }
}

class _BookPage extends StatelessWidget {
  final String firstLetter;
  final String? secondLetter;
  final int pageNumber;
  final Function(String) onTap;

  const _BookPage({
    required this.firstLetter,
    this.secondLetter,
    required this.pageNumber,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/images/book_cover.png'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildLetter(firstLetter)),
          if (secondLetter != null)
            Expanded(child: _buildLetter(secondLetter!)),
        ],
      ),
    );
  }

  Widget _buildLetter(String letter) {
    return GestureDetector(
      onTap: () => onTap(letter),
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            letter,
            style: const TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Baloo 2',
            ),
          ),
        ),
      ),
    );
  }
}
