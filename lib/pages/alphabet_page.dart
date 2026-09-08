import 'package:flutter/material.dart';
import 'animal_list_page.dart';
import '../core/config.dart';
import '../core/progress.dart';
import '../widgets/star_row.dart';
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
  void initState() {
    super.initState();
    // Ulduzlar hərf səhifələrində qazanılır; kitaba qayıdanda hər hərfin
    // ulduzu və başlıqdaki ümumi sayğac təzə dəyəri göstərsin.
    ProgressStore.instance.addListener(_onProgressChanged);
    _preloadFlipSound();
    // Şəkil faylını öncədən yüklə
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage('assets/images/book_cover.webp'), context);
    });
  }

  void _onProgressChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _preloadFlipSound() async {
    try {
      await _audioPlayer.setAsset('assets/audios/page_flip.mp3');
    } catch (e) {
      // Səs yüklənməsə də kitab işləməlidir.
      debugPrint('Səhifə çevirmə səsi yüklənmədi: $e');
    }
  }

  @override
  void dispose() {
    ProgressStore.instance.removeListener(_onProgressChanged);
    _audioPlayer.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _playPageFlipSound() async {
    try {
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Səhifə çevirmə səsi oxunmadı: $e');
    }
  }

  void _showSoundCredits() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Səs mənbələri'),
            content: const SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tətbiqdəki heyvan səsləri açıq lisenziyalı mənbələrdən '
                    'istifadə olunub:',
                  ),
                  SizedBox(height: 12),
                  Text('• bigsoundbank.com — CC0 (Public Domain)'),
                  SizedBox(height: 6),
                  Text('• soundbible.com — Public Domain və CC BY 3.0'),
                  SizedBox(height: 6),
                  Text('• fws.gov, nps.gov — Public Domain arxivləri'),
                  SizedBox(height: 16),
                  Text(
                    'CC BY 3.0 müəllifləri:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Mike Koenig, Daniel Simon, J Dawg, Mark Mattingly, '
                    'Cat Stevens',
                  ),
                ],
              ),
            ),
            actions: [
              // Valideyn üçün: yığılmış ulduzları silir. Uşaq təsadüfən basa
              // bilməsin deyə ikinci, açıq-aşkar təsdiq addımı var.
              //
              // Yeri müvəqqətidir: `docs/superpowers/specs/2026-09-08-ayarlar-
              // valideyn-bolmesi-design.md` bu dialoqu valideyn qapısı arxasındaki
              // ayarlar səhifəsinə köçürür — sıfırlama da onunla birlikdə gedəcək.
              TextButton(
                onPressed: () => _confirmResetProgress(context),
                child: const Text('Progresi sıfırla'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Bağla'),
              ),
            ],
          ),
    );
  }

  /// Sıfırlamanın ikinci addımı. `dialogContext` — səs mənbələri dialoqunun
  /// konteksti; təsdiq gələndə onu da bağlayırıq ki, uşaq silinmiş sayğaca
  /// baxarkən köhnə dialoq arxada qalmasın.
  Future<void> _confirmResetProgress(BuildContext dialogContext) async {
    final store = ProgressStore.instance;
    final confirmed = await showDialog<bool>(
      context: dialogContext,
      builder:
          (context) => AlertDialog(
            icon: const Icon(Icons.warning_amber_rounded, size: 40),
            title: const Text('Bütün ulduzlar silinsin?'),
            content: Text(
              'Yığılmış ${store.totalStars} ulduz və tamamlanmış bütün bölmələr '
              'silinəcək. Bu addımı geri qaytarmaq mümkün deyil.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Ləğv et'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Bəli, sil'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;
    await store.reset();
    if (!dialogContext.mounted) return;
    Navigator.of(dialogContext).pop();
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    _TotalStarsBadge(),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Əlifba',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(color: Colors.black26, blurRadius: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.info_outline,
                        color: Colors.white.withAlpha((0.8 * 255).toInt()),
                      ),
                      tooltip: 'Səs mənbələri',
                      onPressed: _showSoundCredits,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: (alphabet.length / 2).ceil(),
                      itemBuilder: (context, i) {
                        return _BookPage(
                          firstLetter: alphabet[i * 2],
                          secondLetter:
                              i * 2 + 1 < alphabet.length
                                  ? alphabet[i * 2 + 1]
                                  : null,
                          pageNumber: i + 1,
                          onTap: (letter) => _openAnimalList(context, letter),
                        );
                      },
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
                        color: Colors.white.withAlpha((0.8 * 255).toInt()),
                      ),
                      onPressed: _previousPage,
                    ),
                    Icon(
                      Icons.menu_book,
                      color: Colors.white.withAlpha((0.8 * 255).toInt()),
                      size: 28,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withAlpha((0.8 * 255).toInt()),
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
          image: AssetImage('assets/images/book_cover.webp'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.2 * 255).toInt()),
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
    final store = ProgressStore.instance;
    final stars = store.starsOf(letter);
    final complete = stars >= ProgressStore.maxStarsPerLetter;
    return GestureDetector(
      onTap: () => onTap(letter),
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha((0.1 * 255).toInt()),
          borderRadius: BorderRadius.circular(8),
          // Tam bitmiş hərf kitab səhifəsində uzaqdan seçilsin: qızılı çərçivə
          // və yumşaq işıq. Yarımçıq hərfdə çərçivə yoxdur ki, səhifə
          // kələ-kötür görünməsin.
          border:
              complete
                  ? Border.all(color: kStarGold, width: 2.5)
                  : null,
          boxShadow:
              complete
                  ? [
                    BoxShadow(
                      color: kStarGold.withAlpha(110),
                      blurRadius: 16,
                    ),
                  ]
                  : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Qlif `Flexible` + `FittedBox` içindədir: ulduz sırası əlavə
            // olunduqdan sonra alçaq ekranlarda 72 px hərf sığmaya bilər.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  letter,
                  style: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: 'Baloo2',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Kitab səhifəsi açıq rəngdədir, ona görə boş ulduz ağ deyil,
            // tünd-şəffaf olur.
            StarRow(
              filled: stars,
              size: 20,
              spacing: 1,
              emptyColor: Colors.black26,
            ),
          ],
        ),
      ),
    );
  }
}

/// Başlıqdaki ümumi ulduz sayğacı: `⭐ 41/96`.
///
/// Store-a özü qoşulmur — [_AlphabetPageState] dinləyici saxlayır və dəyişəndə
/// bütün başlığı yenidən qurur.
class _TotalStarsBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final store = ProgressStore.instance;
    return Semantics(
      label:
          '${store.maxTotalStars} ulduzdan ${store.totalStars} ulduz yığılıb',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(28),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kStarGold.withAlpha(120), width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, color: kStarGold, size: 20),
            const SizedBox(width: 4),
            Text(
              '${store.totalStars}/${store.maxTotalStars}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
