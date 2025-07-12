import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:just_audio/just_audio.dart';

class AnimalWordPuzzle extends StatefulWidget {
  final String word;
  final VoidCallback? onWin;
  const AnimalWordPuzzle({required this.word, this.onWin, super.key});

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
  late AudioPlayer _clickPlayer;
  late AudioPlayer _winPlayer;

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
    _initAudio();
  }

  Future<void> _initAudio() async {
    _clickPlayer = AudioPlayer();
    _winPlayer = AudioPlayer();
    await _clickPlayer.setAsset('assets/audios/click.mp3');
    await _winPlayer.setAsset('assets/audios/win.mp3');
  }

  Future<void> _playClickSound() async {
    try {
      await _clickPlayer.seek(Duration.zero);
      await _clickPlayer.play();
    } catch (e) {
      debugPrint('Səs oynatma xətası: $e');
    }
  }

  Future<void> _playWinSound() async {
    try {
      await _winPlayer.seek(Duration.zero);
      await _winPlayer.play();
    } catch (e) {
      debugPrint('Səs oynatma xətası: $e');
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _clickPlayer.dispose();
    _winPlayer.dispose();
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
      _playWinSound();
      Future.delayed(const Duration(milliseconds: 800), () {
        widget.onWin?.call();
      });
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
              LayoutBuilder(
                builder: (context, constraints) {
                  // Ekranın eni və hərf sayı əsasında ölçü hesabla
                  final maxWidth = constraints.maxWidth;
                  final letterCount = letters.length;
                  // Minimum və maksimum ölçü limitləri
                  double boxWidth = 48;
                  double boxHeight = 60;
                  double minBoxWidth = 28;
                  double minBoxHeight = 38;
                  double spacing = 8;
                  // Hesablanmış ölçü
                  double totalWidth =
                      letterCount * boxWidth + (letterCount - 1) * spacing;
                  if (totalWidth > maxWidth) {
                    // Sığmırsa, ölçünü kiçilt
                    boxWidth = ((maxWidth - (letterCount - 1) * spacing) /
                            letterCount)
                        .clamp(minBoxWidth, boxWidth);
                    boxHeight = (boxHeight * boxWidth / 48).clamp(
                      minBoxHeight,
                      boxHeight,
                    );
                  }
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
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
                                bgColor = Colors.redAccent.withAlpha(
                                  (0.7 * 255).toInt(),
                                );
                              }
                              return Container(
                                width: boxWidth,
                                height: boxHeight,
                                margin: EdgeInsets.all(spacing / 2),
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
                                  showCorrect
                                      ? letters[i]
                                      : (placedLetters[i] ?? ''),
                                  style: TextStyle(
                                    fontSize: boxWidth * 0.65,
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
                              _playClickSound();
                              checkCompleted();
                            },
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              // Səpələnmiş hərflər (draggable) - AŞAĞIDA
              LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth = constraints.maxWidth;
                  final letterCount = shuffledLetters.length;
                  double boxWidth = 48;
                  double boxHeight = 60;
                  double minBoxWidth = 28;
                  double minBoxHeight = 38;
                  double spacing = 8;
                  double totalWidth =
                      letterCount * boxWidth + (letterCount - 1) * spacing;
                  if (totalWidth > maxWidth) {
                    boxWidth = ((maxWidth - (letterCount - 1) * spacing) /
                            letterCount)
                        .clamp(minBoxWidth, boxWidth);
                    boxHeight = (boxHeight * boxWidth / 48).clamp(
                      minBoxHeight,
                      boxHeight,
                    );
                  }
                  return Wrap(
                    alignment: WrapAlignment.center,
                    spacing: spacing,
                    runSpacing: 12,
                    children: List.generate(shuffledLetters.length, (i) {
                      final letter = shuffledLetters[i];
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
                          child: _buildLetter(
                            letter,
                            dragging: true,
                            width: boxWidth,
                            height: boxHeight,
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.3,
                          child: _buildLetter(
                            letter,
                            width: boxWidth,
                            height: boxHeight,
                          ),
                        ),
                        onDragStarted: _playClickSound,
                        child: _buildLetter(
                          letter,
                          width: boxWidth,
                          height: boxHeight,
                        ),
                      );
                    }),
                  );
                },
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

  Widget _buildLetter(
    String letter, {
    bool dragging = false,
    double? width,
    double? height,
  }) {
    final boxWidth = width ?? 48.0;
    final boxHeight = height ?? 60.0;
    return Container(
      width: boxWidth,
      height: boxHeight,
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
        style: TextStyle(
          fontSize: boxWidth * 0.65,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
