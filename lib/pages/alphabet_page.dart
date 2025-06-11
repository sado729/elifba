import 'package:flutter/material.dart';
import 'animal_list_page.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../core/config.dart';

class AlphabetPage extends StatelessWidget {
  const AlphabetPage({super.key});

  static const List<String> alphabet = AppConfig.alphabet;
  static const Map<String, List<String>> animalsByLetter = {};

  void _openAnimalList(BuildContext context, String letter) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AnimalListPage(letter: letter)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 32),
              Text(
                'Əlifba',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  color: Colors.yellowAccent,
                  letterSpacing: 2,
                  shadows: [Shadow(color: Colors.black26, blurRadius: 8)],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 18,
                    childAspectRatio: 1,
                  ),
                  itemCount: alphabet.length,
                  itemBuilder: (context, index) {
                    final letter = alphabet[index];
                    return _AnimatedLetterCard(letter: letter);
                  },
                ),
              ),
              // Dekorativ ulduzlar və planetlər üçün placeholder
              Padding(
                padding: const EdgeInsets.only(bottom: 16, top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, color: Colors.yellow.shade200, size: 32),
                    const SizedBox(width: 12),
                    Icon(Icons.circle, color: Colors.blue.shade200, size: 22),
                    const SizedBox(width: 12),
                    Icon(Icons.star, color: Colors.pink.shade100, size: 28),
                    const SizedBox(width: 12),
                    Icon(Icons.circle, color: Colors.green.shade200, size: 18),
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

class _AnimatedLetterCard extends StatefulWidget {
  final String letter;
  const _AnimatedLetterCard({required this.letter});

  @override
  State<_AnimatedLetterCard> createState() => _AnimatedLetterCardState();
}

class _AnimatedLetterCardState extends State<_AnimatedLetterCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  bool? _hasImage;

  @override
  void initState() {
    super.initState();
    _checkAsset();
  }

  Future<void> _checkAsset() async {
    final letterConfig = AppConfig.findLetter(widget.letter);
    final assetPath = letterConfig?.imagePath ?? '';
    final exists = await AssetChecker.hasAsset(assetPath);
    if (mounted) {
      setState(() {
        _hasImage = exists;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final letterConfig = AppConfig.findLetter(widget.letter);
    final assetPath = letterConfig?.imagePath ?? '';
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        final parent = context.findAncestorWidgetOfExactType<AlphabetPage>();
        if (parent != null) {
          parent._openAnimalList(context, widget.letter);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: _pressed ? Colors.deepPurple.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withAlpha(26),
              blurRadius: _pressed ? 18 : 10,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: Colors.deepPurple.shade200, width: 2),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_hasImage == null)
              const CircularProgressIndicator(strokeWidth: 2)
            else if (_hasImage == true)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder:
                      (context, error, stackTrace) => Text(
                        widget.letter,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.shade800,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(color: Colors.black12, blurRadius: 4),
                          ],
                        ),
                      ),
                ),
              )
            else
              Text(
                widget.letter,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade800,
                  letterSpacing: 1.5,
                  shadows: [Shadow(color: Colors.black12, blurRadius: 4)],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
