import 'package:flutter/material.dart';
import 'dart:math' as math;

const String basketImageUrl =
    'https://png.pngtree.com/png-vector/20230903/ourmid/pngtree-empty-red-plastic-cup-isolated-with-reflect-floor-for-mockup-png-image_9950721.png';
const String ballImageUrl =
    'https://static.vecteezy.com/system/resources/thumbnails/022/651/656/small_2x/3d-round-ball-free-png.png';

enum BasketGamePhase { showBall, basketsDrop, shuffle, guess, result }

class BasketGameWidget extends StatefulWidget {
  final String letter;
  const BasketGameWidget({required this.letter, super.key});

  @override
  State<BasketGameWidget> createState() => _BasketGameWidgetState();
}

class _BasketGameWidgetState extends State<BasketGameWidget>
    with TickerProviderStateMixin {
  int ballIndex = 0; // Top hansı səbətdədir (0, 1, 2)
  int? selectedBasket; // İstifadəçi hansı səbəti seçib
  bool shuffled = false;
  bool showResult = false;
  bool win = false;
  late AnimationController _controller;
  late Animation<double> _animation;
  List<int> shuffleOrder = [0, 1, 2];
  List<List<int>> shuffleSteps = [];
  int shuffleStep = 0;
  bool isShuffling = false;
  BasketGamePhase phase = BasketGamePhase.showBall;
  late AnimationController _rotateController;
  late Animation<double> _rotateAnimation;
  bool basketsRotated = false;
  bool dropHandled = false;
  bool basketsDropHandled = false;
  bool gameStarted = false;
  bool? isCorrect;
  int? selectedBasketIdx;
  bool hideBallDuringShuffle = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _rotateAnimation = Tween<double>(begin: 0, end: math.pi).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.easeInOut),
    );
    resetGame();
    WidgetsBinding.instance.addPostFrameCallback((_) => startIntroAnimation());
  }

  @override
  void dispose() {
    _controller.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  Future<void> startIntroAnimation() async {
    setState(() {
      phase = BasketGamePhase.showBall;
      basketsRotated = false;
      dropHandled = false;
      basketsDropHandled = false;
    });
    await Future.delayed(const Duration(milliseconds: 1000));
    setState(() {
      phase = BasketGamePhase.basketsDrop;
    });
    // Qalan faza keçidləri səbət animasiyası bitəndə AnimatedPositioned.onEnd ilə olacaq
  }

  void resetGame() {
    setState(() {
      ballIndex = math.Random().nextInt(3);
      selectedBasket = null;
      shuffled = false;
      showResult = false;
      win = false;
      shuffleOrder = [0, 1, 2];
      shuffleSteps = [];
      shuffleStep = 0;
      isShuffling = false;
      phase = BasketGamePhase.showBall;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => startIntroAnimation());
  }

  Future<void> shuffleBaskets() async {
    setState(() {
      shuffled = false;
      showResult = false;
      selectedBasket = null;
      shuffleSteps = [];
      shuffleStep = 0;
      isShuffling = true;
    });
    // Shuffle addımlarını əvvəlcədən hazırla
    List<int> current = List.from(shuffleOrder);
    for (int i = 0; i < 6; i++) {
      int a = math.Random().nextInt(3);
      int b = math.Random().nextInt(3);
      int tmp = current[a];
      current[a] = current[b];
      current[b] = tmp;
      shuffleSteps.add(List.from(current));
    }
    for (int i = 0; i < shuffleSteps.length; i++) {
      setState(() {
        shuffleOrder = shuffleSteps[i];
        shuffleStep = i;
      });
      await _controller.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 80));
    }
    setState(() {
      shuffled = true;
      isShuffling = false;
    });
  }

  Future<void> animateShuffle() async {
    setState(() {
      hideBallDuringShuffle = true;
    });
    int shuffleCount = 6;
    for (int i = 0; i < shuffleCount; i++) {
      await Future.delayed(const Duration(milliseconds: 400));
      setState(() {
        int a = math.Random().nextInt(3);
        int b = math.Random().nextInt(3);
        while (b == a) b = math.Random().nextInt(3);
        int tmp = shuffleOrder[a];
        shuffleOrder[a] = shuffleOrder[b];
        shuffleOrder[b] = tmp;
      });
    }
    setState(() {
      hideBallDuringShuffle = false;
    });
  }

  void selectBasket(int idx) {
    if (!shuffled || showResult || phase != BasketGamePhase.guess) return;
    setState(() {
      selectedBasket = idx;
      showResult = true;
      win = shuffleOrder[idx] == ballIndex;
      phase = BasketGamePhase.result;
    });
  }

  Widget buildBall(String letter) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.network(
            ballImageUrl,
            width: 48,
            height: 48,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orange,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withAlpha(60),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orange,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withAlpha(60),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 2,
            child: Text(
              letter,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Səbət Oyunu',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Topun üstündəki hərf: ',
              style: TextStyle(fontSize: 18, color: Colors.deepPurple.shade700),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double basketWidth = 56;
                  double spacing = (constraints.maxWidth - basketWidth * 3) / 4;
                  // Topun animasiyası və fazalara görə göstərilməsi
                  Widget ballWidget = const SizedBox.shrink();
                  if (!gameStarted) {
                    if (phase == BasketGamePhase.showBall ||
                        phase == BasketGamePhase.basketsDrop) {
                      // Ortadakı səbət topun üstünə düşəndə top gizlənir
                      bool hideBall = false;
                      if (phase == BasketGamePhase.basketsDrop &&
                          basketsDropHandled) {
                        hideBall = true;
                      }
                      ballWidget = Positioned(
                        top: 60,
                        left: constraints.maxWidth / 2 - 24,
                        child: Opacity(
                          opacity:
                              (hideBallDuringShuffle || hideBall) ? 0.0 : 1.0,
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Image.network(
                              ballImageUrl,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      );
                    }
                  } else if (phase == BasketGamePhase.result &&
                      selectedBasket != null) {
                    // Seçimdən sonra yalnız seçilmiş səbətin altında top
                    int realIdx = ballIndex;
                    int pos = shuffleOrder.indexOf(realIdx);
                    if (selectedBasket == pos) {
                      double left = spacing + pos * (basketWidth + spacing);
                      ballWidget = Positioned(
                        top: 50 + basketWidth,
                        left: left + basketWidth / 2 - 24,
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Image.network(
                            ballImageUrl,
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    }
                  } else {
                    // Shuffle və ya oyun zamanı topu gizlət
                    bool hideBall = false;
                    if (phase == BasketGamePhase.basketsDrop &&
                        basketsDropHandled) {
                      hideBall = true;
                    }
                    ballWidget = Positioned(
                      top: 60,
                      left: constraints.maxWidth / 2 - 24,
                      child: Opacity(
                        opacity:
                            (hideBallDuringShuffle ||
                                    hideBall ||
                                    (gameStarted && selectedBasketIdx == null))
                                ? 0.0
                                : 1.0,
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Image.network(
                            ballImageUrl,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    );
                  }
                  return Stack(
                    children: [
                      // Əvvəlcə top (aşağı layer)
                      ballWidget,
                      // Səbətlər (yuxarı layer)
                      ...List.generate(3, (realIdx) {
                        int pos = shuffleOrder.indexOf(realIdx);
                        double left = spacing + pos * (basketWidth + spacing);
                        Widget basketImg = Image.network(
                          basketImageUrl,
                          width: basketWidth,
                          height: basketWidth,
                          fit: BoxFit.contain,
                        );
                        // Səbətlərin yuxarıdan aşağı düşməsi animasiyası
                        double basketDropTop = 50;
                        if (realIdx == 1) {
                          if (phase == BasketGamePhase.showBall) {
                            basketDropTop = 20;
                          } else if (phase == BasketGamePhase.basketsDrop) {
                            basketDropTop = 50;
                          }
                        } else {
                          basketDropTop = 50;
                        }
                        // Səbət seçimi üçün rəng
                        ColorFilter filter = const ColorFilter.mode(
                          Colors.transparent,
                          BlendMode.dst,
                        );
                        if (selectedBasketIdx != null &&
                            selectedBasketIdx == pos) {
                          filter = ColorFilter.mode(
                            isCorrect == true
                                ? Colors.green.withOpacity(0.3)
                                : Colors.red.withOpacity(0.3),
                            BlendMode.srcATop,
                          );
                        }
                        return AnimatedPositioned(
                          key: ValueKey(realIdx),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeInOut,
                          left: left,
                          top: basketDropTop,
                          width: basketWidth,
                          child: Column(
                            children: [
                              Transform.scale(
                                scale: 1.2,
                                child: Transform.rotate(
                                  angle: math.pi,
                                  child: ColorFiltered(
                                    colorFilter: filter,
                                    child: basketImg,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (gameStarted && selectedBasketIdx == null)
                                SizedBox(
                                  width: 72,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        selectedBasketIdx = pos;
                                        isCorrect =
                                            (pos ==
                                                shuffleOrder.indexOf(
                                                  ballIndex,
                                                ));
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Colors.deepPurple.shade50,
                                      foregroundColor: Colors.deepPurple,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      minimumSize: Size(72, 36),
                                    ),
                                    child: const Text('Seç'),
                                  ),
                                ),
                              if (selectedBasketIdx != null &&
                                  selectedBasketIdx == pos)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    isCorrect == true ? 'Doğru!' : 'Səhv',
                                    style: TextStyle(
                                      color:
                                          isCorrect == true
                                              ? Colors.green
                                              : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            if (phase == BasketGamePhase.result)
              Column(
                children: [
                  const SizedBox(height: 16),
                  Icon(
                    win ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                    color: win ? Colors.green : Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    win
                        ? 'Təbriklər, doğru səbəti tapdın!'
                        : 'Təəssüf, səhv səbət seçdin.',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: win ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Yenidən oynat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                    ),
                    onPressed: resetGame,
                  ),
                ],
              ),
            // Aşağıda "Oyunu başlat" düyməsi
            if (!gameStarted)
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: ElevatedButton(
                  onPressed: () async {
                    selectedBasketIdx = null;
                    isCorrect = null;
                    await animateShuffle();
                    setState(() {
                      gameStarted = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 18,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('Oyunu başlat'),
                ),
              ),
            // Səbət seçilib nəticə göründükdən sonra 'Yenidən başlat' düyməsi
            if (gameStarted && selectedBasketIdx != null)
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Yenidən başlat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () async {
                    setState(() {
                      gameStarted = false;
                      selectedBasketIdx = null;
                      isCorrect = null;
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
