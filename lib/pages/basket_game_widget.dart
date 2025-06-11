import 'package:flutter/material.dart';
import 'dart:math' as math;

const String basketImageUrl = 'assets/basket.png';
const String ballImageUrl = 'assets/ball.webp';

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
    // Oyun avtomatik başlamasın deyə, burada heç bir oyun başlatma funksiyası çağırmıram.
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

  Future<void> resetGame() async {
    setState(() {
      ballIndex = 1; // Top həmişə ortadakı səbətdə başlayır
      selectedBasket = null;
      shuffled = false;
      showResult = false;
      win = false;
      shuffleOrder = [0, 1, 2];
      shuffleSteps = [];
      shuffleStep = 0;
      isShuffling = false;
      phase = BasketGamePhase.showBall;
      selectedBasketIdx = null;
      isCorrect = null;
      basketsDropHandled = false;
    });
    await Future.delayed(const Duration(milliseconds: 1000));
    setState(() {
      phase = BasketGamePhase.basketsDrop;
    });
    await Future.delayed(const Duration(milliseconds: 1000));
    await animateShuffle();
    setState(() {
      gameStarted = true;
    });
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
        while (b == a) {
          b = math.Random().nextInt(3);
        }
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
          Image.asset(
            ballImageUrl,
            width: 48,
            height: 48,
            fit: BoxFit.contain,
            errorBuilder:
                (context, error, stackTrace) => const Icon(
                  Icons.sports_basketball,
                  size: 32,
                  color: Colors.orange,
                ),
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
          children: [
            Expanded(
              child: SingleChildScrollView(
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
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 180,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          double basketWidth = 56;
                          double spacing =
                              (constraints.maxWidth - basketWidth * 3) / 4;
                          // Topun animasiyası və fazalara görə göstərilməsi
                          Widget ballWidget = const SizedBox.shrink();
                          if (!gameStarted) {
                            if (phase == BasketGamePhase.showBall ||
                                phase == BasketGamePhase.basketsDrop) {
                              // Ortadakı səbət yuxarıda olanda top tam görünməlidir
                              bool hideBall = false;
                              double topPos =
                                  20 +
                                  basketWidth; // səbət yuxarıda olanda topun mövqeyi
                              if (phase == BasketGamePhase.basketsDrop &&
                                  basketsDropHandled) {
                                hideBall = true;
                              } else if (phase == BasketGamePhase.showBall) {
                                hideBall = false;
                                topPos =
                                    20 +
                                    basketWidth; // səbət yuxarıda olanda topun mövqeyi
                              } else {
                                topPos = 60; // default mövqe
                              }
                              ballWidget = Positioned(
                                top: topPos,
                                left: constraints.maxWidth / 2 - 24,
                                child: Opacity(
                                  opacity:
                                      (hideBallDuringShuffle || hideBall)
                                          ? 0.0
                                          : 1.0,
                                  child: buildBall(widget.letter),
                                ),
                              );
                            }
                          } else if (phase == BasketGamePhase.result &&
                              selectedBasket != null) {
                            // Seçimdən sonra yalnız seçilmiş səbətin altında top
                            int realIdx = ballIndex;
                            int pos = shuffleOrder.indexOf(realIdx);
                            if (selectedBasket == pos) {
                              double left =
                                  spacing + pos * (basketWidth + spacing);
                              ballWidget = Positioned(
                                top: 50 + basketWidth,
                                left: left + basketWidth / 2 - 24,
                                child: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Image.asset(
                                    ballImageUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.sports_basketball,
                                              size: 32,
                                              color: Colors.orange,
                                            ),
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
                                            (gameStarted &&
                                                selectedBasketIdx == null))
                                        ? 0.0
                                        : 1.0,
                                child: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Image.asset(
                                    ballImageUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.sports_basketball,
                                              size: 32,
                                              color: Colors.orange,
                                            ),
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
                                double left =
                                    spacing + pos * (basketWidth + spacing);
                                Widget basketImg = Image.asset(
                                  basketImageUrl,
                                  width: basketWidth,
                                  height: basketWidth,
                                  fit: BoxFit.contain,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          const Icon(
                                            Icons.shopping_basket,
                                            size: 32,
                                            color: Colors.brown,
                                          ),
                                );
                                // Səbətlərin yuxarıdan aşağı düşməsi animasiyası
                                double basketDropTop = 50;
                                if (realIdx == 1) {
                                  if (phase == BasketGamePhase.showBall) {
                                    basketDropTop = 20;
                                  } else if (phase ==
                                      BasketGamePhase.basketsDrop) {
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
                                  onEnd:
                                      realIdx == 1
                                          ? () {
                                            if (phase ==
                                                    BasketGamePhase
                                                        .basketsDrop &&
                                                !basketsDropHandled) {
                                              setState(() {
                                                basketsDropHandled = true;
                                              });
                                            }
                                          }
                                          : null,
                                  child: Column(
                                    children: [
                                      GestureDetector(
                                        onTap:
                                            (gameStarted &&
                                                    selectedBasketIdx == null)
                                                ? () {
                                                  setState(() {
                                                    selectedBasketIdx = pos;
                                                    isCorrect =
                                                        (pos ==
                                                            shuffleOrder
                                                                .indexOf(
                                                                  ballIndex,
                                                                ));
                                                    win = isCorrect == true;
                                                    phase =
                                                        BasketGamePhase.result;
                                                  });
                                                }
                                                : null,
                                        child: Transform.scale(
                                          scale: 1.2,
                                          child: Transform.rotate(
                                            angle: math.pi,
                                            child: ColorFiltered(
                                              colorFilter: filter,
                                              child: basketImg,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
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
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width - 48,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color:
                                win ? Colors.green.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: (win ? Colors.green : Colors.red)
                                    .withOpacity(0.12),
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Icon(
                                win
                                    ? Icons.emoji_events
                                    : Icons.sentiment_dissatisfied,
                                color: win ? Colors.green : Colors.red,
                                size: 28,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  win
                                      ? 'Təbriklər, doğru səbəti tapdın!'
                                      : 'Təəssüf, səhv səbət seçdin.',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: win ? Colors.green : Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (!gameStarted)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: ElevatedButton(
                          key: const ValueKey('startBtn'),
                          onPressed: () async {
                            await resetGame();
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
                  ],
                ),
              ),
            ),
            if (phase == BasketGamePhase.result)
              SafeArea(
                child: ElevatedButton.icon(
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
              ),
          ],
        ),
      ),
    );
  }
}
