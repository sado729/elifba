import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

class AnimalWordPuzzle extends StatefulWidget {
  final String word;
  const AnimalWordPuzzle({required this.word, super.key});

  @override
  State<AnimalWordPuzzle> createState() => _AnimalWordPuzzleState();
}

class _AnimalWordPuzzleState extends State<AnimalWordPuzzle> {
  late List<String> letters; // doğru ardıcıllıq
  late List<String> shuffledLetters; // ekranda qarışıq göstərilən
  late List<String?> placedLetters;
  bool isCompleted = false;
  late ConfettiController _confettiController;
  bool showCorrect = false;

  @override
  void initState() {
    super.initState();
    letters = widget.word.split('');
    shuffledLetters = List<String>.from(letters);
    shuffledLetters.shuffle();
    placedLetters = List.filled(letters.length, null);
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void checkCompleted() {
    if (List.generate(
      letters.length,
      (i) => placedLetters[i] == letters[i],
    ).every((e) => e)) {
      setState(() {
        isCompleted = true;
      });
      _confettiController.play();
      // Əlavə olaraq istəsəniz, dialog da göstərə bilərsiniz
      /*
      Future.delayed(const Duration(milliseconds: 800), () {
        showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                title: const Text('Təbriklər!'),
                content: const Text('Bütün hərfləri düzgün yerləşdirdin!'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Bağla'),
                  ),
                ],
              ),
        );
      });
      */
    }
  }

  void resetPuzzle() {
    setState(() {
      shuffledLetters = List<String>.from(letters);
      shuffledLetters.shuffle();
      placedLetters = List.filled(letters.length, null);
      isCompleted = false;
      _confettiController.stop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Buttonlar
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.refresh, color: Colors.white),
                      label: const Text('Yenidən başla'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                      ),
                      onPressed: resetPuzzle,
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onLongPressStart: (_) {
                        setState(() {
                          showCorrect = true;
                        });
                      },
                      onLongPressEnd: (_) {
                        setState(() {
                          showCorrect = false;
                        });
                      },
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.emoji_events, color: Colors.white),
                        label: const Text('Düzgün seçimi göstər'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                        ),
                        onPressed:
                            () {}, // klikdə heç nə olmasın, yalnız uzun basılanda işləsin
                      ),
                    ),
                  ],
                ),
              ),
              // Düzgün yerlər (drop target-lər)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(letters.length, (i) {
                  return GestureDetector(
                    onTap: () {
                      if (placedLetters[i] != null) {
                        setState(() {
                          placedLetters[i] = null;
                          isCompleted = false;
                        });
                      }
                    },
                    child: DragTarget<String>(
                      builder: (context, candidate, rejected) {
                        Color bgColor;
                        if (showCorrect) {
                          bgColor = Colors.orangeAccent.withAlpha(180);
                        } else if (placedLetters[i] == null) {
                          bgColor = Colors.white;
                        } else if (placedLetters[i] == letters[i]) {
                          bgColor = Colors.greenAccent;
                        } else {
                          bgColor = Colors.redAccent.withOpacity(0.7);
                        }
                        return Container(
                          width: 48,
                          height: 60,
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: bgColor,
                            border: Border.all(
                              color: Colors.deepPurple,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            showCorrect ? letters[i] : (placedLetters[i] ?? ''),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color:
                                  showCorrect
                                      ? Colors.deepPurple
                                      : Colors.black,
                            ),
                          ),
                        );
                      },
                      onWillAcceptWithDetails:
                          (data) => placedLetters[i] == null,
                      onAcceptWithDetails: (data) {
                        setState(() {
                          placedLetters[i] = data.data;
                        });
                        checkCompleted();
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),
              // Səpələnmiş hərflər (draggable) - AŞAĞIDA
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: List.generate(shuffledLetters.length, (i) {
                  final letter = shuffledLetters[i];
                  // Əgər bu hərf artıq istifadə olunubsa (yəni placedLetters-də neçə dəfə varsa, o qədərini gizlət)
                  int usedCount =
                      placedLetters.where((e) => e == letter).length;
                  int letterCountBefore = 0;
                  for (int j = 0; j < i; j++) {
                    if (shuffledLetters[j] == letter) letterCountBefore++;
                  }
                  if (letterCountBefore < usedCount) {
                    return const SizedBox.shrink();
                  }
                  return Draggable<String>(
                    data: letter,
                    feedback: Material(
                      color: Colors.transparent,
                      child: _buildLetter(letter, dragging: true),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.3,
                      child: _buildLetter(letter),
                    ),
                    child: _buildLetter(letter),
                  );
                }),
              ),
            ],
          ),
        ),
        // Konfet effekti
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

  Widget _buildLetter(String letter, {bool dragging = false}) {
    return Container(
      width: 48,
      height: 60,
      alignment: Alignment.center,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: dragging ? Colors.yellowAccent : Colors.deepPurple.shade100,
        border: Border.all(color: Colors.deepPurple, width: 2),
        borderRadius: BorderRadius.circular(8),
        boxShadow:
            dragging
                ? [
                  BoxShadow(
                    color: Colors.deepPurple.withAlpha(80),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
                : [],
      ),
      child: Text(
        letter,
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
      ),
    );
  }
}
