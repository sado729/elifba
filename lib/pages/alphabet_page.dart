import 'package:flutter/material.dart';
import 'animal_list_page.dart';

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

class _AnimatedLetterCard extends StatefulWidget {
  final String letter;
  const _AnimatedLetterCard({required this.letter});

  @override
  State<_AnimatedLetterCard> createState() => _AnimatedLetterCardState();
}

class _AnimatedLetterCardState extends State<_AnimatedLetterCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  bool _selected = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        // Hərf seçimi və ya səhifəyə keçid
        final parent =
            context.findAncestorWidgetOfExactType<AlphabetPage>()
                as AlphabetPage?;
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
              color: Colors.deepPurple.withOpacity(0.10),
              blurRadius: _pressed ? 18 : 10,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: Colors.deepPurple.shade200, width: 2),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Hərf
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
