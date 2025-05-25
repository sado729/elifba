import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../core/utils.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

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
  OverlayEntry? _imageOverlayEntry;

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
    final animalName = normalizeFileName(animal);
    final imageAsset =
        'animals/$animalLetter/$animalName/${animalName}_puzzle.jpg';
    return Stack(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTapDown:
                          (_) => _showFullImageOverlay(context, imageAsset),
                      onTapUp: (_) => _removeFullImageOverlay(),
                      onTapCancel: () => _removeFullImageOverlay(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.deepPurple.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepPurple.withAlpha(
                                (255 * 0.08).round(),
                              ),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.visibility,
                              color: Colors.deepPurple,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Şəkli göstər',
                              style: TextStyle(
                                color: Colors.deepPurple.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                  ],
                ),
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
              child: GridView.builder(
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
                                    Future.delayed(
                                      const Duration(milliseconds: 1500),
                                      () {
                                        if (mounted && completed) {
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
                                                    TextButton(
                                                      onPressed:
                                                          () =>
                                                              Navigator.of(
                                                                context,
                                                              ).pop(),
                                                      child: const Text(
                                                        'Bağla',
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
                          } else if (pieceIndex == null &&
                              fromIndex.data >= slots.length) {
                            int pieceIdx =
                                pieces[fromIndex.data - slots.length];
                            slots[i] = pieceIdx;
                            pieces.removeAt(fromIndex.data - slots.length);
                          }
                          if (!completed && _isCompleted()) {
                            completed = true;
                            _confettiController.play();
                            Future.delayed(
                              const Duration(milliseconds: 1500),
                              () {
                                if (mounted && completed) {
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
                                            TextButton(
                                              onPressed:
                                                  () =>
                                                      Navigator.of(
                                                        context,
                                                      ).pop(),
                                              child: const Text('Bağla'),
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
            borderRadius: borderRadius,
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
              color: Colors.black.withAlpha((255 * 0.45).round()),
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
