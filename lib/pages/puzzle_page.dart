import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/config.dart';
import '../core/settings.dart';
import '../core/sound.dart';
import '../core/utils.dart';
import '../theme/theme.dart';
import '../widgets/badges.dart';
import '../widgets/celebration.dart';
import '../widgets/elifba_card.dart';
import '../widgets/elifba_confetti.dart';
import '../widgets/game_feedback.dart';
import '../widgets/pill_button.dart';
import '../widgets/pill_tab.dart';
import '../widgets/star_row.dart';
import 'animal_detail_page.dart' show kPuzzlePreviewDecodeWidth;

class PuzzlePage extends StatefulWidget {
  final String animal;

  /// Pazl ilk dəfə tamamlananda çağırılır (hər `_resetPuzzle`-dən sonra yenidən
  /// tamamlansa yenə çağırılır — progresi qeyd etmək idempotentdir).
  ///
  /// Pazl bu səhifənin özündə deyil, valideyn səhifəsində ulduza çevrilir:
  /// `PuzzlePage` `AnimalDetailPage`-in içində göstərilir və hansı heyvana
  /// aid olduğunu bilən oradır.
  final VoidCallback? onCompleted;

  const PuzzlePage({super.key, required this.animal, this.onCompleted});

  @override
  State<PuzzlePage> createState() => _PuzzlePageState();
}

/// 60x60 önizləmə üçün dekod eni (mənbə 600x600 = ~1.4 MB RAM).
/// 60 dp x 3.0 piksel sıxlığı = 180 fiziki px, ona görə 192.
const int kPuzzleThumbDecodeWidth = 192;

/// Lövhənin ən böyük eni (planşetdə lövhə ekranı tutmasın).
const double _kMaxBoard = 480;

/// Səbətdəki parçanın ən böyük ölçüsü.
const double _kMaxTrayPiece = 64;

class _PuzzlePageState extends State<PuzzlePage> {
  /// Pazl ölçüsü. Başlanğıc dəyər valideyn ayarlarından gəlir; səhifə
  /// içindəki seçici onu dəyişəndə ayar da yenilənir — ölçü üçün iki fərqli
  /// həqiqət mənbəyi olmasın.
  int gridSize = AppSettings.instance.puzzleGridSize;
  late List<int?> slots; // griddəki yerlər (null və ya parça indeksi)
  late List<int> pieces; // aşağıda qarışıq parçalar
  bool completed = false;
  final ConfettiController _confettiController =
      ConfettiPreset.small.createController();
  OverlayEntry? _imageOverlayEntry;
  final GatedPlayer _audioPlayer = GatedPlayer(SoundChannel.effect);
  final GatedPlayer _winPlayer = GatedPlayer(SoundChannel.effect);
  bool showHint = false;
  Timer? _hintTimer;

  /// Tamamlanandan 1.5 s sonra təbrik kartı.
  Timer? _celebrationTimer;

  // Pazl şəkli bir dəfə dekod olunur və bütün xanalar onu paylaşır.
  // Əvvəl hər xana build zamanı `_loadImage()` çağırırdı, yəni 3x3 grid üçün
  // eyni 600x600 şəkil 9 dəfə (~12 MB) dekod olunur və hər setState-də
  // yenidən dekod edilirdi.
  String? _puzzleImageAsset;
  Future<ui.Image>? _puzzleImageFuture;
  ui.Image? _puzzleImage;

  // Hint rejimində saxlanılacaq orijinal vəziyyətlər
  List<int?> _originalSlots = [];
  List<int> _originalPieces = [];

  /// Parça xanaya DÜŞƏN anın sayğacı: doğru düşəndə "pop", səhv düşəndə
  /// silkələnmə yalnız o anda oynayır — ipucu, geri qaytarma və adi yenidən
  /// qurulma onları oynatmır. Doğru/səhv görünüşün özü `slots[i] == i`-dən
  /// hesablanır (ipucu zamanı və ondan sonra da düzgündür).
  late List<int?> _popTrigger;
  late List<int?> _shakeTrigger;
  int _dropCount = 0;

  @override
  void initState() {
    super.initState();
    _resetPuzzle();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      await _audioPlayer.setAsset('assets/audios/click.mp3');
      await _winPlayer.setAsset('assets/audios/win.mp3');
    } catch (e) {
      debugPrint('Səs yüklənmə xətası: $e');
    }
  }

  void _changeGridSize(int size) {
    AppSettings.instance.puzzleGridSize = size;
    setState(() {
      gridSize = size;
      _resetPuzzle();
    });
  }

  void _resetPuzzle() {
    // İpucu gedərkən sıfırlansa taymer köhnə (bəlkə başqa ölçülü) vəziyyəti
    // geri qaytarmasın.
    _hintTimer?.cancel();
    slots = List<int?>.filled(gridSize * gridSize, null);
    pieces = List.generate(gridSize * gridSize, (i) => i);
    pieces.shuffle();
    _popTrigger = List<int?>.filled(gridSize * gridSize, null);
    _shakeTrigger = List<int?>.filled(gridSize * gridSize, null);
    setState(() {
      completed = false;
      showHint = false;
    });
  }

  void _showHint() {
    // İpucu artıq göstərilirsə ikinci toxunuş nəzərə alınmır: əks halda
    // "orijinal" kimi HƏLL OLUNMUŞ lövhə saxlanılar və ipucu bitəndə qalardı
    // (gotcha 14-ün yan qapısı).
    if (showHint) return;

    // Cari vəziyyəti saxla
    _originalSlots = List.from(slots);
    _originalPieces = List.from(pieces);

    // Model həll olunmuş vəziyyətə keçir (gotcha 14: tamamlanma yoxlaması
    // `!showHint` ilə qorunur). Ekran isə bu müddətdə uşağın saxlanmış
    // vəziyyətini və üstündə kölgə şəkli göstərir (`build`).
    setState(() {
      showHint = true;
      slots = List.generate(gridSize * gridSize, (i) => i);
      pieces = [];
    });

    // Timer
    _hintTimer?.cancel();
    _hintTimer = Timer(ElifbaMotion.hint, () {
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
    _removeFullImageOverlay();
    _confettiController.dispose();
    _audioPlayer.dispose();
    _winPlayer.dispose();
    _hintTimer?.cancel();
    _celebrationTimer?.cancel();
    _puzzleImage?.dispose();
    super.dispose();
  }

  Future<void> _playClickSound() => _audioPlayer.replay();

  Future<void> _playWinSound() => _winPlayer.replay();

  bool _isCompleted() => _isSolved(slots, pieces);

  static bool _isSolved(List<int?> slots, List<int> pieces) {
    for (int i = 0; i < slots.length; i++) {
      if (slots[i] != i) return false;
    }
    if (pieces.isNotEmpty) return false;
    return true;
  }

  /// Pazl bitibsə: konfeti, qələbə səsi, ulduz və 1.5 s sonra təbrik kartı.
  ///
  /// ⚠️ `!showHint` şərti gotcha 14-dür: ipucu lövhəyə həll olunmuş vəziyyəti
  /// qoyur və `_isCompleted()` true qaytarır — ipucu ulduz verməməlidir.
  void _checkCompleted() {
    if (!completed && !showHint && _isCompleted()) {
      setState(() => completed = true);
      if (!AppSettings.instance.reduceMotion) {
        _confettiController.play();
      }
      _playWinSound();
      widget.onCompleted?.call();
      _celebrationTimer?.cancel();
      _celebrationTimer = Timer(ElifbaMotion.puzzleDialogDelay, () {
        if (mounted && completed && context.mounted) {
          _showCompletedCard();
        }
      });
    }
  }

  void _showCompletedCard() {
    // Scrim-ə toxunmaq və geri düyməsi yalnız bağlayır; «Yenidən» bağlayıb
    // pazlı yenidən qarışdırır. Konfeti tamamlanma anında artıq atılıb.
    showSmallWinCelebration(
      context,
      message: 'Pazl tamamlandı!',
      playConfetti: false,
      action: CelebrationAction(
        label: 'Yenidən',
        icon: Icons.refresh_rounded,
        onPressed: () {
          if (mounted) _resetPuzzle();
        },
      ),
    );
  }

  /// Xanaya parça düşdü. [pieceIndex] xananın qurulma anındakı dəyəridir —
  /// yalnız boş xana qəbul edir.
  ///
  /// İpucu zamanı lövhə və səbət toxunuşa bağlıdır (`IgnorePointer`); bu
  /// yoxlama ehtiyat üçündür: model o vaxt həll olunmuş vəziyyətdədir, ekran
  /// isə uşağın öz vəziyyətini göstərir, və ipucu zamanı pop/silkələnmə
  /// olmamalıdır (spec §9.4).
  void _onDrop(int i, int? pieceIndex, int from) {
    if (showHint) return;
    setState(() {
      if (pieceIndex == null && from < slots.length && slots[from] != null) {
        slots[i] = slots[from];
        slots[from] = null;
        _markDrop(i);
      } else if (pieceIndex == null && from >= slots.length) {
        int pieceIdx = pieces[from - slots.length];
        slots[i] = pieceIdx;
        pieces.removeAt(from - slots.length);
        _markDrop(i);
      }
    });
    _checkCompleted();
  }

  void _markDrop(int i) {
    _dropCount++;
    // Doğru yerə qoyulubsa
    if (slots[i] == i) {
      _playClickSound();
      _popTrigger[i] = _dropCount;
    } else {
      _shakeTrigger[i] = _dropCount;
    }
  }

  /// Qoyulmuş parçaya toxunmaq onu səbətin sonuna qaytarır.
  void _sendBack(int i) {
    if (showHint) return;
    setState(() {
      if (slots[i] != null) {
        pieces.add(slots[i]!);
        slots[i] = null;
      }
    });
    _checkCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final animal = widget.animal;
    final animalLetter = getFirstLetter(animal);
    final animalData = AppConfig.findAnimal(animalLetter, animal);
    final imageAsset =
        animalData?.imagePath.replaceFirst('.webp', '_puzzle.jpg') ?? '';
    // İpucu zamanı lövhə və səbət uşağın ÖZ vəziyyətini göstərir (dizayn:
    // qoyduğu parçalar ✓/✕ ilə qalır, boş xanalar boş, səbət dolu), üstündə
    // 40 %-lik bütöv şəkil. Model (`slots`/`pieces`) isə ipucu boyu həll
    // olunmuş vəziyyətdədir və 2 s sonra geri qaytarılır — mexanizm və
    // gotcha 14-ün qoruyucusu dəyişməyib.
    final viewSlots = showHint ? _originalSlots : slots;
    final viewPieces = showHint ? _originalPieces : pieces;
    final boardDone = _isSolved(viewSlots, viewPieces);

    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final n = gridSize;
            final board = math.min(constraints.maxWidth, _kMaxBoard);
            final cell =
                (board -
                    2 * GameDecorations.boardPadding -
                    (n - 1) * GameDecorations.boardGap) /
                n;
            final piece = math.min(_kMaxTrayPiece, cell.floorToDouble());
            return FutureBuilder<ui.Image>(
              future: _puzzleImageOf(imageAsset),
              builder: (context, snapshot) {
                final img = snapshot.data;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildControls(imageAsset),
                    const SizedBox(height: 12),
                    _buildLevels(),
                    const SizedBox(height: 12),
                    Center(
                      child: _buildBoard(
                        board,
                        cell,
                        img,
                        viewSlots,
                        boardDone,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTray(piece, img, viewPieces, boardDone),
                  ],
                );
              },
            );
          },
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Center(
            child: IgnorePointer(
              child: ElifbaConfetti(controller: _confettiController),
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------ idarələr

  Widget _buildControls(String imageAsset) {
    return Row(
      children: [
        // Basıb saxlayanda bütöv şəkil görünür. `Tooltip` QƏSDƏN yoxdur: onun
        // uzun-basma tanıyıcısı toxunuşu udub baxışı yarıda bağlayardı.
        Semantics(
          label: 'Basıb saxla',
          button: true,
          child: GestureDetector(
            onTapDown: (_) => _showFullImageOverlay(context, imageAsset),
            onTapUp: (_) => _removeFullImageOverlay(),
            onTapCancel: () => _removeFullImageOverlay(),
            child: Container(
              width: ElifbaSize.puzzleThumb,
              height: ElifbaSize.puzzleThumb,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(
                  Radius.circular(ElifbaRadius.r14),
                ),
                // CSS: `0 0 0 2px #FFFDFB, 0 0 0 4px #D2C8F2` — ağ halqa
                // üstdə, bənövşəyi altda.
                boxShadow: [
                  BoxShadow(color: ElifbaPalette.outline, spreadRadius: 4),
                  BoxShadow(color: ElifbaPalette.surface, spreadRadius: 2),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(
                  Radius.circular(ElifbaRadius.r14),
                ),
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.cover,
                  cacheWidth: kPuzzleThumbDecodeWidth,
                  errorBuilder:
                      (context, error, stackTrace) => const ColoredBox(
                        color: ElifbaPalette.surfaceContainerLow,
                        child: Center(
                          child: Icon(
                            Icons.image_rounded,
                            size: 32,
                            color: ElifbaPalette.onMuted,
                          ),
                        ),
                      ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: PillButton(
            label: 'Yenidən başla',
            icon: Icons.refresh_rounded,
            variant: PillButtonVariant.secondary,
            size: PillButtonSize.small,
            // 360 dp-də yazı sığmayanda kiçilir (üç nöqtə yox).
            expand: true,
            onPressed: _resetPuzzle,
          ),
        ),
        const SizedBox(width: 8),
        // İpucu göstərilərkən düymə söndürülür (ikinci toxunuş nəzərə
        // alınmır).
        PillButton(
          label: 'İpucu',
          icon: Icons.lightbulb_rounded,
          variant: PillButtonVariant.tonal,
          size: PillButtonSize.small,
          onPressed: showHint ? null : _showHint,
        ),
      ],
    );
  }

  Widget _buildLevels() {
    const levels = [(3, 'Asan'), (4, 'Orta'), (5, 'Çətin')];
    return Row(
      children: [
        for (var i = 0; i < levels.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _buildLevelButton(levels[i].$1, levels[i].$2)),
        ],
      ],
    );
  }

  Widget _buildLevelButton(int size, String label) {
    final isSelected = size == gridSize;
    // Seçilmiş səviyyəyə toxunmaq da pazlı yenidən qarışdırır (bu günkü kimi).
    return PillTab(
      label: label,
      expand: true,
      selected: isSelected,
      leading: GridGlyph(
        n: size,
        color: GridGlyph.colorFor(selected: isSelected),
      ),
      onTap: () => _changeGridSize(size),
    );
  }

  // ---------------------------------------------------------------- lövhə

  Widget _buildBoard(
    double board,
    double cell,
    ui.Image? img,
    List<int?> viewSlots,
    bool boardDone,
  ) {
    final n = gridSize;
    return AnimatedContainer(
      duration: ElifbaMotion.boardDone,
      width: board,
      height: board,
      padding: const EdgeInsets.all(GameDecorations.boardContainerPadding),
      decoration: boardDone ? GameDecorations.boardDone : GameDecorations.board,
      child: Stack(
        children: [
          // İpucu zamanı xanalar toxunuşa bağlıdır: göstərilən vəziyyət
          // modeldəki (həll olunmuş) vəziyyət deyil.
          IgnorePointer(
            ignoring: showHint,
            child: Column(
              children: [
                for (var r = 0; r < n; r++) ...[
                  if (r > 0) const SizedBox(height: GameDecorations.boardGap),
                  Row(
                    children: [
                      for (var c = 0; c < n; c++) ...[
                        if (c > 0)
                          const SizedBox(width: GameDecorations.boardGap),
                        _buildCell(
                          r * n + c,
                          viewSlots[r * n + c],
                          cell,
                          img,
                          boardDone,
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          // İpucu: bütöv şəkil 40 % ilə xanaların üstündə (yenidən dekod yox —
          // gotcha 9) və «2 s» nişanı. Toxunuşları buraxır.
          if (showHint && img != null)
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(13)),
                  child: CustomPaint(
                    painter: _FullImagePainter(img, opacity: 0.4),
                  ),
                ),
              ),
            ),
          if (showHint)
            const Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: IgnorePointer(child: Center(child: _HintChip())),
            ),
        ],
      ),
    );
  }

  Widget _buildCell(
    int i,
    int? pieceIndex,
    double size,
    ui.Image? img,
    bool boardDone,
  ) {
    // Pop/silkələnmə xananın ÖZÜNDƏdir: struktur hər vəziyyətdə eynidir, ona
    // görə yalnız düşmə anında (trigger dəyişəndə) oynayır.
    return SizedBox(
      width: size,
      height: size,
      child: ShakeOnTrigger(
        trigger: _shakeTrigger[i],
        child: PopOnTrigger(
          trigger: _popTrigger[i],
          child: DragTarget<int>(
            builder: (context, candidateData, rejectedData) {
              if (pieceIndex == null) {
                return DecoratedBox(
                  decoration:
                      candidateData.isNotEmpty
                          ? GameDecorations.cellHover
                          : GameDecorations.cellEmpty,
                  child: const SizedBox.expand(),
                );
              }
              // Lövhə bitəndə nişan yoxdur — lövhənin halqası vəziyyəti
              // daşıyır. İpucu zamanı uşağın parçaları nişanlarını saxlayır
              // (dizayn), kölgə şəkil onların üstündədir.
              final bool? mark =
                  pieceIndex == i ? (boardDone ? null : true) : false;
              return Draggable<int>(
                data: i, // slot index
                feedback: _liftedPiece(pieceIndex, size, img),
                childWhenDragging: Opacity(
                  opacity: 0.3,
                  child: _boardPiece(pieceIndex, size, img),
                ),
                child: GestureDetector(
                  onTap: () => _sendBack(i),
                  child: _boardPiece(pieceIndex, size, img, mark: mark),
                ),
              );
            },
            onWillAcceptWithDetails: (data) => true,
            onAcceptWithDetails:
                (details) => _onDrop(i, pieceIndex, details.data),
          ),
        ),
      ),
    );
  }

  Widget _pieceFace(int pieceIndex, ui.Image? img) {
    if (img == null) {
      return const ColoredBox(color: ElifbaPalette.surfaceContainerLow);
    }
    return CustomPaint(
      painter: PuzzleTilePainter(
        img,
        pieceIndex ~/ gridSize,
        pieceIndex % gridSize,
        gridSize,
      ),
    );
  }

  /// Lövhədəki parça; [mark]: true → doğru (✓, yaşıl halqa), false → səhv
  /// (✕, qırmızı qırıq xətt), null → işarəsiz.
  Widget _boardPiece(int pieceIndex, double size, ui.Image? img, {bool? mark}) {
    final face = SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(ElifbaRadius.r6)),
        child: _pieceFace(pieceIndex, img),
      ),
    );
    if (mark == null) return face;
    return Semantics(
      label: mark ? 'doğru' : 'səhv',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          face,
          Positioned.fill(
            child: IgnorePointer(
              child:
                  mark
                      ? const DecoratedBox(
                        decoration: GameDecorations.cellCorrect,
                      )
                      : const CustomPaint(
                        painter: GameDecorations.cellWrongOutlineInside,
                      ),
            ),
          ),
          Positioned(
            right: GameDecorations.cellBadgeInset,
            bottom: GameDecorations.cellBadgeInset,
            child:
                mark
                    ? const CheckBadge(
                      size: GameDecorations.cellBadgeSize,
                      ringWidth: 0,
                    )
                    : const CrossBadge(
                      size: GameDecorations.cellBadgeSize,
                      ringWidth: 0,
                    ),
          ),
        ],
      ),
    );
  }

  /// Sürüklənən parça (`Draggable.feedback`): bənövşəyi halqa, 4 dp yuxarı,
  /// 1.06 böyük. Azaldılmış hərəkətdə yalnız halqa və kənar qalır.
  Widget _liftedPiece(int pieceIndex, double size, ui.Image? img) {
    Widget piece = DecoratedBox(
      decoration: GameDecorations.trayPieceDragging,
      child: SizedBox(
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: const BorderRadius.all(
            Radius.circular(ElifbaRadius.r8),
          ),
          child: _pieceFace(pieceIndex, img),
        ),
      ),
    );
    if (!ElifbaMotion.reduced) {
      piece = Transform.translate(
        offset: const Offset(0, GameDecorations.trayPieceDraggingLift),
        child: Transform.scale(
          scale: GameDecorations.trayPieceDraggingScale,
          child: piece,
        ),
      );
    }
    return Material(type: MaterialType.transparency, child: piece);
  }

  // ---------------------------------------------------------------- səbət

  Widget _trayPiece(int pieceIndex, double size, ui.Image? img) {
    return DecoratedBox(
      decoration: GameDecorations.trayPiece,
      child: SizedBox(
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: const BorderRadius.all(
            Radius.circular(ElifbaRadius.r8),
          ),
          child: _pieceFace(pieceIndex, img),
        ),
      ),
    );
  }

  Widget _buildTray(
    double piece,
    ui.Image? img,
    List<int> pieces,
    bool boardDone,
  ) {
    final List<Widget> children;
    if (boardDone && pieces.isEmpty) {
      // Bitdi: ✓ + ulduz. Yalnız lövhə həqiqətən bitəndə (səhv parçalı
      // lövhədə yox). İpucu zamanı səbət uşağın parçalarını göstərir.
      children = [
        Semantics(
          label: 'Pazl tamamlandı',
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 22,
                color: ElifbaPalette.correct,
              ),
              SizedBox(width: 6),
              StarGlyph(filled: true, size: 22),
            ],
          ),
        ),
      ];
    } else {
      children = [
        for (var idx = 0; idx < pieces.length; idx++)
          Draggable<int>(
            key: ValueKey<int>(pieces[idx]),
            data: slots.length + idx,
            feedback: _liftedPiece(pieces[idx], piece, img),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: _trayPiece(pieces[idx], piece, img),
            ),
            onDragStarted: _playClickSound,
            child: _trayPiece(pieces[idx], piece, img),
          ),
      ];
    }
    return ElifbaCard(
      radius: ElifbaRadius.r20,
      edge: 0,
      padding: const EdgeInsets.all(10),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: piece),
        // İpucu zamanı göstərilən parçalar modeldə yoxdur (model həll
        // olunmuş vəziyyətdədir) — sürüklənə bilməzlər.
        child: IgnorePointer(
          ignoring: showHint,
          child: Wrap(
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: children,
          ),
        ),
      ),
    );
  }

  /// Şəkli yalnız bir dəfə dekod edir; sonrakı xanalar hazır Future-u alır.
  Future<ui.Image> _puzzleImageOf(String asset) {
    if (_puzzleImageFuture == null || _puzzleImageAsset != asset) {
      _puzzleImageAsset = asset;
      _puzzleImageFuture = _loadImage(asset);
    }
    return _puzzleImageFuture!;
  }

  Future<ui.Image> _loadImage(String asset) async {
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    _puzzleImage = frame.image;
    return frame.image;
  }

  void _showFullImageOverlay(BuildContext context, String imageAsset) {
    if (_imageOverlayEntry != null) return;
    final overlay = Overlay.of(context, rootOverlay: true);
    final image = _puzzleImage;
    _imageOverlayEntry = OverlayEntry(
      builder:
          (context) => Positioned.fill(
            // Buraxma toxunuşu miniatürün tanıyıcısına çatmalıdır.
            child: IgnorePointer(
              child: ColoredBox(
                color: ElifbaPalette.scrim55,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _kMaxBoard,
                          maxHeight: _kMaxBoard,
                        ),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: DecoratedBox(
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.all(
                                Radius.circular(ElifbaRadius.r24),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: ElifbaPalette.surface,
                                  spreadRadius: 6,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(ElifbaRadius.r24),
                              ),
                              child:
                                  image != null
                                      ? CustomPaint(
                                        painter: _FullImagePainter(image),
                                      )
                                      : Image.asset(
                                        imageAsset,
                                        fit: BoxFit.cover,
                                        cacheWidth: kPuzzlePreviewDecodeWidth,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const ColoredBox(
                                                  color:
                                                      ElifbaPalette
                                                          .surfaceContainerLow,
                                                  child: ImagePlaceholder(),
                                                ),
                                      ),
                            ),
                          ),
                        ),
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
    // `OverlayEntry` ChangeNotifier-dir: çıxarılandan sonra atılmalıdır.
    _imageOverlayEntry
      ?..remove()
      ..dispose();
    _imageOverlayEntry = null;
  }
}

/// İpucu lövhəsindəki «💡 2 s» nişanı (sabit mətn, geri sayım deyil).
class _HintChip extends StatelessWidget {
  const _HintChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsetsDirectional.only(start: 8, end: 12),
      decoration: const ShapeDecoration(
        color: ElifbaPalette.primaryContainer,
        shape: StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.lightbulb_rounded,
            size: 18,
            color: ElifbaPalette.onPrimaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            '2 s',
            textScaler: TextScaler.noScaling,
            style: ElifbaTextStyles.hintChip.copyWith(
              color: ElifbaPalette.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bütöv pazl şəklini (artıq dekod olunmuş `ui.Image`) `cover` ilə çəkir —
/// ipucu kölgəsi (40 %) və böyük baxış üçün. İkinci dekod yoxdur (gotcha 9).
class _FullImagePainter extends CustomPainter {
  _FullImagePainter(this.image, {this.opacity = 1});

  final ui.Image image;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final src = Size(image.width.toDouble(), image.height.toDouble());
    final fitted = applyBoxFit(BoxFit.cover, src, size);
    final srcRect = Alignment.center.inscribe(fitted.source, Offset.zero & src);
    final dstRect = Alignment.center.inscribe(
      fitted.destination,
      Offset.zero & size,
    );
    canvas.drawImageRect(
      image,
      srcRect,
      dstRect,
      Paint()
        ..color = Color.fromRGBO(0, 0, 0, opacity)
        ..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(_FullImagePainter old) =>
      old.image != image || old.opacity != opacity;
}

class PuzzleTilePainter extends CustomPainter {
  final ui.Image image;
  final int row, col, gridSize;
  PuzzleTilePainter(this.image, this.row, this.col, this.gridSize);

  @override
  void paint(Canvas canvas, Size size) {
    final srcTileSize = image.width / gridSize;
    final src = Rect.fromLTWH(
      col * srcTileSize,
      row * srcTileSize,
      srcTileSize,
      srcTileSize,
    );
    final dst = Offset.zero & size;
    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  // Xananın parçası yerində dəyişəndə (ipucu dəyişimi) köhnə kəsik qalmasın.
  @override
  bool shouldRepaint(covariant PuzzleTilePainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.row != row ||
      oldDelegate.col != col ||
      oldDelegate.gridSize != gridSize;
}
