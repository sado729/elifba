import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../core/utils.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'dart:math';
import '../core/config.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';

class PuzzlePage extends StatefulWidget {
  final String animal;
  const PuzzlePage({super.key, required this.animal});

  @override
  State<PuzzlePage> createState() => _PuzzlePageState();
}

class _PuzzlePageState extends State<PuzzlePage> with TickerProviderStateMixin {
  static const double fullSize = 240;
  int gridSize = 3;
  double get tileSize => fullSize / gridSize;
  late List<int?> slots; // griddəki yerlər (null və ya parça indeksi)
  late List<int> pieces; // aşağıda qarışıq parçalar
  bool completed = false;
  late ConfettiController _confettiController;
  OverlayEntry? _imageOverlayEntry;
  late List<String> letters;
  late List<String?> placedLetters;
  late List<Offset> randomOffsets;
  late AudioPlayer _audioPlayer;
  late AudioPlayer _winPlayer;
  bool showHint = false;
  Timer? _hintTimer;

  // Doğru və ya səhv qoyulmuş parçaları izləmək üçün map
  Map<int, bool> slotCorrectMap = {};

  // Hint rejimində saxlanılacaq orijinal vəziyyətlər
  List<int?> _originalSlots = [];
  List<int> _originalPieces = [];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _resetPuzzle();
    letters = widget.animal.split('');
    placedLetters = List.filled(letters.length, null);
    _initAudio();

    // Random yerlər üçün offset-lər
    final rand = Random();
    randomOffsets = List.generate(
      letters.length,
      (_) => Offset(rand.nextDouble() * 200, rand.nextDouble() * 200),
    );
  }

  Future<void> _initAudio() async {
    _audioPlayer = AudioPlayer();
    _winPlayer = AudioPlayer();
    await _audioPlayer.setAsset('assets/audios/click.mp3');
    await _winPlayer.setAsset('assets/audios/win.mp3');
  }

  void _changeGridSize(int size) {
    setState(() {
      gridSize = size;
      _resetPuzzle();
    });
  }

  void _resetPuzzle() {
    slots = List<int?>.filled(gridSize * gridSize, null);
    pieces = List.generate(gridSize * gridSize, (i) => i);
    pieces.shuffle();
    slotCorrectMap = {};
    setState(() {
      completed = false;
      showHint = false;
    });
  }

  void _showHint() {
    // Cari vəziyyəti saxla
    _originalSlots = List.from(slots);
    _originalPieces = List.from(pieces);

    // Düzgün vəziyyət göstər
    setState(() {
      showHint = true;
      slots = List.generate(gridSize * gridSize, (i) => i);
      pieces = [];
    });

    // Timer
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          showHint = false;
          // Əvvəlki vəziyyətə qayıt
          slots = _originalSlots;
          pieces = _originalPieces;
        });
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _audioPlayer.dispose();
    _winPlayer.dispose();
    _hintTimer?.cancel();
    super.dispose();
  }

  Future<void> _playClickSound() async {
    try {
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
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

  bool _isCompleted() {
    for (int i = 0; i < slots.length; i++) {
      if (slots[i] != i) return false;
    }
    if (pieces.isNotEmpty) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final animal = widget.animal;
    final animalLetter = getFirstLetter(animal);
    final animalData = AppConfig.findAnimal(animalLetter, animal);
    final imageAsset =
        animalData?.imagePath.replaceFirst('.png', '_puzzle.jpg') ?? '';
    return Stack(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTapDown:
                            (_) => _showFullImageOverlay(context, imageAsset),
                        onTapUp: (_) => _removeFullImageOverlay(),
                        onTapCancel: () => _removeFullImageOverlay(),
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.deepPurple.shade200,
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              imageAsset,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) => const Icon(
                                    Icons.image,
                                    size: 32,
                                    color: Colors.deepPurple,
                                  ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _resetPuzzle,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Yenidən başla'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _showHint,
                        icon: const Icon(Icons.lightbulb_outline),
                        label: const Text('Hint'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          backgroundColor: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLevelButton(3, 'Asan'),
                      const SizedBox(width: 8),
                      _buildLevelButton(4, 'Orta'),
                      const SizedBox(width: 8),
                      _buildLevelButton(5, 'Çətin'),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: fullSize,
              height: fullSize,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.deepPurple, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  if (showHint)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          imageAsset,
                          fit: BoxFit.cover,
                          opacity: const AlwaysStoppedAnimation(0.3),
                        ),
                      ),
                    ),
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gridSize,
                      mainAxisSpacing: 2,
                      crossAxisSpacing: 2,
                    ),
                    itemCount: gridSize * gridSize,
                    itemBuilder: (context, i) {
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
                                      slotIndex: i,
                                    ),
                                  ),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.3,
                                  child: _buildPuzzlePiece(
                                    imageAsset,
                                    pieceIndex,
                                    gridSize,
                                    slotIndex: i,
                                  ),
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (slots[i] != null) {
                                        pieces.add(slots[i]!);
                                        slots[i] = null;
                                      }
                                      if (!completed && _isCompleted()) {
                                        completed = true;
                                        _confettiController.play();
                                        _playWinSound();
                                        Future.delayed(
                                          const Duration(milliseconds: 1500),
                                          () {
                                            if (mounted &&
                                                completed &&
                                                context.mounted) {
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (context) => AlertDialog(
                                                      title: const Text(
                                                        'Təbriklər!',
                                                      ),
                                                      content: const Text(
                                                        'Puzzle tamamlandı!',
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.of(
                                                              context,
                                                            ).pop();
                                                            _resetPuzzle();
                                                          },
                                                          child: const Text(
                                                            'Yenidən',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                              );
                                            }
                                          },
                                        );
                                      }
                                    });
                                  },
                                  child: _buildPuzzlePiece(
                                    imageAsset,
                                    pieceIndex,
                                    gridSize,
                                    slotIndex: i,
                                  ),
                                ),
                              );
                            } else if (candidateData.isNotEmpty) {
                              BorderRadius borderRadius = BorderRadius.zero;
                              if (i == 0) {
                                borderRadius = const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                );
                              } else if (i == gridSize - 1) {
                                borderRadius = const BorderRadius.only(
                                  topRight: Radius.circular(16),
                                );
                              } else if (i == gridSize * (gridSize - 1)) {
                                borderRadius = const BorderRadius.only(
                                  bottomLeft: Radius.circular(16),
                                );
                              } else if (i == gridSize * gridSize - 1) {
                                borderRadius = const BorderRadius.only(
                                  bottomRight: Radius.circular(16),
                                );
                              }
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.shade100,
                                  borderRadius: borderRadius,
                                  border: Border.all(
                                    color: Colors.deepPurple.shade200,
                                    width: 2,
                                  ),
                                ),
                              );
                            } else {
                              BorderRadius borderRadius = BorderRadius.zero;
                              if (i == 0) {
                                borderRadius = const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                );
                              } else if (i == gridSize - 1) {
                                borderRadius = const BorderRadius.only(
                                  topRight: Radius.circular(16),
                                );
                              } else if (i == gridSize * (gridSize - 1)) {
                                borderRadius = const BorderRadius.only(
                                  bottomLeft: Radius.circular(16),
                                );
                              } else if (i == gridSize * gridSize - 1) {
                                borderRadius = const BorderRadius.only(
                                  bottomRight: Radius.circular(16),
                                );
                              }
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.shade50,
                                  borderRadius: borderRadius,
                                  border: Border.all(
                                    color: Colors.deepPurple.shade200,
                                    width: 2,
                                  ),
                                ),
                              );
                            }
                          },
                          onWillAcceptWithDetails: (data) => true,
                          onAcceptWithDetails: (fromIndex) {
                            setState(() {
                              if (pieceIndex == null &&
                                  fromIndex.data < slots.length &&
                                  slots[fromIndex.data] != null) {
                                slots[i] = slots[fromIndex.data];
                                slots[fromIndex.data] = null;

                                // Doğru yerə qoyulubsa
                                if (slots[i] == i) {
                                  _playClickSound();
                                  slotCorrectMap[i] = true;
                                } else {
                                  slotCorrectMap[i] = false;
                                }
                              } else if (pieceIndex == null &&
                                  fromIndex.data >= slots.length) {
                                int pieceIdx =
                                    pieces[fromIndex.data - slots.length];
                                slots[i] = pieceIdx;
                                pieces.removeAt(fromIndex.data - slots.length);

                                // Doğru yerə qoyulubsa
                                if (slots[i] == i) {
                                  _playClickSound();
                                  slotCorrectMap[i] = true;
                                } else {
                                  slotCorrectMap[i] = false;
                                }
                              }
                              if (!completed && _isCompleted()) {
                                completed = true;
                                _confettiController.play();
                                _playWinSound();
                                Future.delayed(
                                  const Duration(milliseconds: 1500),
                                  () {
                                    if (mounted &&
                                        completed &&
                                        context.mounted) {
                                      showDialog(
                                        context: context,
                                        builder:
                                            (context) => AlertDialog(
                                              title: const Text('Təbriklər!'),
                                              content: const Text(
                                                'Puzzle tamamlandı!',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                    _resetPuzzle();
                                                  },
                                                  child: const Text('Yenidən'),
                                                ),
                                              ],
                                            ),
                                      );
                                    }
                                  },
                                );
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: List.generate(
                  pieces.length,
                  (idx) => Draggable<int>(
                    data: slots.length + idx,
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
                    onDragStarted: _playClickSound,
                    child: SizedBox(
                      width: tileSize,
                      height: tileSize,
                      child: _buildPuzzlePiece(
                        imageAsset,
                        pieces[idx],
                        gridSize,
                        slotIndex: null,
                      ),
                    ),
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
    int? slotIndex,
  }) {
    int row = pieceIndex ~/ gridSize;
    int col = pieceIndex % gridSize;
    BorderRadius borderRadius = BorderRadius.zero;
    if (slotIndex != null) {
      if (slotIndex == 0) {
        borderRadius = const BorderRadius.only(topLeft: Radius.circular(16));
      } else if (slotIndex == gridSize - 1) {
        borderRadius = const BorderRadius.only(topRight: Radius.circular(16));
      } else if (slotIndex == gridSize * (gridSize - 1)) {
        borderRadius = const BorderRadius.only(bottomLeft: Radius.circular(16));
      } else if (slotIndex == gridSize * gridSize - 1) {
        borderRadius = const BorderRadius.only(
          bottomRight: Radius.circular(16),
        );
      }
    }

    // Border rəngini təyin et
    Color borderColor = Colors.deepPurple.shade200;
    if (slotIndex != null) {
      if (slotCorrectMap.containsKey(slotIndex)) {
        borderColor = slotCorrectMap[slotIndex]! ? Colors.green : Colors.red;
      }
    }

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
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: tileSize,
          height: tileSize,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: borderColor, width: 2),
            borderRadius: borderRadius,
            boxShadow:
                shadow
                    ? [
                      const BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(2, 2),
                      ),
                    ]
                    : null,
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: CustomPaint(
              size: Size(tileSize, tileSize),
              painter: PuzzleTilePainter(snapshot.data!, row, col, gridSize),
            ),
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

  void _showFullImageOverlay(BuildContext context, String imageAsset) {
    if (_imageOverlayEntry != null) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    _imageOverlayEntry = OverlayEntry(
      builder:
          (context) => Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.45),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    imageAsset,
                    width: 320,
                    height: 320,
                    fit: BoxFit.contain,
                    errorBuilder:
                        (context, error, stackTrace) => Container(
                          width: 320,
                          height: 320,
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.image,
                            size: 60,
                            color: Colors.deepPurple,
                          ),
                        ),
                  ),
                ),
              ),
            ),
          ),
    );
    overlay.insert(_imageOverlayEntry!);
  }

  void _removeFullImageOverlay() {
    _imageOverlayEntry?.remove();
    _imageOverlayEntry = null;
  }

  Widget _buildLevelButton(int size, String label) {
    final isSelected = size == gridSize;
    return ElevatedButton(
      onPressed: () => _changeGridSize(size),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: isSelected ? Colors.deepPurple : Colors.grey.shade200,
        foregroundColor: isSelected ? Colors.white : Colors.black87,
      ),
      child: Text(label),
    );
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
