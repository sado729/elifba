import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import '../core/stroke_tracker.dart';
import '../widgets/tracing_canvas.dart';
import 'animal_detail_page.dart';
import 'letter_writing_page.dart';
import '../core/config.dart';
import '../core/letter_strokes.dart';
import '../core/progress.dart';
import '../widgets/star_row.dart';
import 'package:just_audio/just_audio.dart';

/// Qrid xanasındaki heyvan şəkli üçün dekod eni. Bütün heyvan şəkilləri
/// 400x400 WebP-dir və xana ~160 px göstərilir; `cacheWidth` şəkli böyütmür,
/// ona görə bu dəyər mənbə ölçüsü ilə eynidir və detal səhifəsindəki hero ilə
/// eyni image-cache açarını paylaşır (iki ayrı dekod yaranmır).
const int kAnimalThumbDecodeWidth = 400;

class AnimalListPage extends StatefulWidget {
  final String letter;
  const AnimalListPage({super.key, required this.letter});

  @override
  State<AnimalListPage> createState() => _AnimalListPageState();
}

class _AnimalListPageState extends State<AnimalListPage> {
  /// Hərf haqqında mətn ilk açılışda gizlidir; başlığa toxunanda açılır.
  bool _infoExpanded = false;

  ProgressStore get _store => ProgressStore.instance;

  /// Alt səhifədən (heyvan detalı və ya yazı oyunu) qayıdanda hərfin tamamlanıb
  /// tamamlanmadığını yoxlayır.
  ///
  /// Təbrik store dinləyicisindən deyil, məhz QAYIDIŞDA göstərilir: son bölmə
  /// alt səhifədə bitir və dinləyici ilə dialoq həmin səhifənin ÜSTÜNDƏ açılardı.
  /// `takeLetterCelebration` özü bir dəfəlikdir, ona görə təkrar açılmır.
  Future<void> _maybeCelebrateLetter() async {
    if (!mounted) return;
    if (!_store.takeLetterCelebration(widget.letter)) return;
    await showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            icon: const StarRow(
              filled: ProgressStore.maxStarsPerLetter,
              size: 42,
              spacing: 2,
              emptyColor: Colors.black12,
            ),
            title: Text('${widget.letter} hərfi tamam!'),
            content: Text(
              'Bu hərflə bağlı hər şeyi etdin — heyvanları, tapmacaları və '
              'hərfi yazmağı. ${ProgressStore.maxStarsPerLetter} ulduz sənindir!',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Yaşa!'),
              ),
            ],
          ),
    );
  }

  void _onProgressChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _store.removeListener(_onProgressChanged);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Ulduzlar alt səhifədə (heyvan detalı, yazı oyunu) qazanılır; qayıdanda
    // qrid və hərf sayğacı təzə dəyərləri göstərsin.
    _store.addListener(_onProgressChanged);
    // Şəkilləri qabaqcadan yüklə. Ölçü qridd-dəki `cacheWidth` ilə eyni olmalıdır,
    // əks halda image cache-də hər şəkil üçün ikinci nüsxə yaranır.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final animals = AppConfig.findLetter(widget.letter)?.animals ?? [];
      for (final animal in animals) {
        if (animal.imagePath.isEmpty) continue;
        precacheImage(
          ResizeImage(
            AssetImage(animal.imagePath),
            width: kAnimalThumbDecodeWidth,
          ),
          context,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Android 16 (API 36) forces edge-to-edge, so the system bars overlay the
    // body: inset the content by the window's view padding manually.
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final letter = widget.letter;
    final info =
        AppConfig.findLetter(letter)?.description ??
        '$letter hərfi haqqında məlumat yoxdur.';
    final animalObjects = AppConfig.findLetter(letter)?.animals ?? [];
    final animals = animalObjects.map((a) => a.name).toList();
    // Yazı kartı yalnız cizgiləri təsvir olunmuş hərflərdə görünür. Bu səhifə
    // əsl hərfi (Ə, Ş...) bilir, ona görə diakritikanı normalizasiyadan
    // yenidən çıxarmaq lazım gəlmir.
    final showWrite = LetterStrokes.has(letter);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$letter hərfi',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          _LetterArrowAppBarButton(
            direction: ArrowDirection.left,
            currentLetter: letter,
          ),
          _LetterArrowAppBarButton(
            direction: ArrowDirection.right,
            currentLetter: letter,
          ),
        ],
      ),
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
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16 + viewPadding.left,
            18,
            16 + viewPadding.right,
            18 + viewPadding.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hərf haqqında məlumat üçün dekorativ kart və səsləndirmə düyməsi.
              // Mətn ilk açılışda bağlıdır: yalnız başlıq görünür, uşaq istəsə
              // ona toxunub açır. Beləcə ekranın böyük hissəsi heyvanlara qalır.
              const SizedBox(height: 10),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: [
                          Colors.deepPurple.shade400,
                          Colors.deepPurple.shade700,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withAlpha(46),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.yellowAccent.withAlpha(77),
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Şəffaf Material olmasa dalğa effekti gradient
                        // Container-in altında, Scaffold-un Material-ində qalır.
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap:
                                () => setState(() {
                                  _infoExpanded = !_infoExpanded;
                                }),
                            child: Padding(
                              padding: EdgeInsets.only(
                                // Səsləndirmə düyməsi kartın sol yuxarı küncünü
                                // örtür; başlıq onun altında qalmasın.
                                left: AppConfig.hasLetterAudio(letter) ? 26 : 0,
                                top: 2,
                                bottom: 2,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _infoExpanded
                                          ? '$letter hərfi haqqında'
                                          : '$letter hərfi haqqında oxu',
                                      style: const TextStyle(
                                        color: Colors.yellowAccent,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  AnimatedRotation(
                                    turns: _infoExpanded ? 0.5 : 0,
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeInOut,
                                    child: const Icon(
                                      Icons.expand_more,
                                      color: Colors.yellowAccent,
                                      size: 26,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        AnimatedCrossFade(
                          firstChild: const SizedBox(
                            width: double.infinity,
                            height: 0,
                          ),
                          secondChild: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              info,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          crossFadeState:
                              _infoExpanded
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 250),
                          sizeCurve: Curves.easeInOut,
                        ),
                      ],
                    ),
                  ),
                  // Səs faylı olmayan hərfdə düyməni ümumiyyətlə göstərmirik:
                  // 32 hərfdən yalnız A, B, C-nin tələffüz səsi var.
                  if (AppConfig.hasLetterAudio(letter))
                    Positioned(
                      top: -16,
                      left: -16,
                      child: _SoundButton(info: info, letter: letter),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              // Başlıq və dekorativ xətt
              Row(
                children: [
                  const Text(
                    'Heyvanlar',
                    style: TextStyle(
                      color: Colors.yellowAccent,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      shadows: [Shadow(color: Colors.black26, blurRadius: 8)],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Dekorativ xəttin yerini hərfin tərəqqisi tutur: səhifəyə
                  // YENİ şaquli blok əlavə etmək olmur — sabit hündürlük
                  // `Expanded`-dəki qridi sıxır və alçaq ekranda daşma yaranır.
                  Expanded(child: _LetterProgressBar(letter: letter)),
                ],
              ),
              const SizedBox(height: 18),
              // Heyvanlar gridi. Yazı oyunu AppBar ikonundan buraya, qridin ilk
              // xanasına köçürüldü: AppBar-da üç ağ ikon (yazı + iki ox)
              // yan-yana dururdu, yazı oyunu naviqasiya oxları ilə eyni çəkidə
              // görünürdü və 24 dp-lik qlif uşaq barmağı üçün kiçik hədəf idi.
              // Kart şəklində o, ekranın ilk gördüyü, ən böyük hədəfdir.
              Expanded(
                child:
                    (animals.isEmpty && !showWrite)
                        ? const Center(
                          child: Text(
                            'Bu hərflə başlayan heyvan yoxdur.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                        : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Ğ, I, Ü hərflərinin heyvanı yoxdur: qriddə tək
                            // yazı kartı qalır, uşaq isə niyəsini bilməlidir.
                            if (animals.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 14),
                                child: Text(
                                  'Bu hərflə başlayan heyvan yoxdur, amma hərfi yaza bilərsən!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: GridView.builder(
                                padding: const EdgeInsets.only(top: 4),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 24,
                                      crossAxisSpacing: 24,
                                      childAspectRatio: 0.95,
                                    ),
                                itemCount: animals.length + (showWrite ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (showWrite && index == 0) {
                                    return _WriteLetterCard(
                                      letter: letter,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => LetterWritingPage(
                                                  letter: letter,
                                                ),
                                          ),
                                        ).then((_) {
                                          _maybeCelebrateLetter();
                                        });
                                      },
                                    );
                                  }
                                  // Yazı kartı qridin başına əlavə olunduğu
                                  // üçün heyvan indeksi bir sürüşür.
                                  // AnimalDetailPage-ə MÜTLƏQ sürüşdürülməmiş
                                  // heyvan indeksi verilməlidir, yoxsa detal
                                  // səhifəsindəki irəli/geri naviqasiya səhv
                                  // heyvandan başlayır.
                                  final animalIndex =
                                      showWrite ? index - 1 : index;
                                  final animal = animals[animalIndex];
                                  final animalInfo = AppConfig.findAnimal(
                                    letter,
                                    animal,
                                  );
                                  final imageAsset =
                                      animalInfo?.imagePath ?? '';
                                  return _ModernAnimalCard(
                                    animal: animal,
                                    imageAsset: imageAsset,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => AnimalDetailPage(
                                                animal: animal,
                                                animals: animals,
                                                currentIndex: animalIndex,
                                              ),
                                        ),
                                      ).then((_) {
                                        _maybeCelebrateLetter();
                                      });
                                    },
                                  );
                                },
                              ),
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

// Müasir heyvan kartı
class _ModernAnimalCard extends StatefulWidget {
  final String animal;
  final String imageAsset;
  final VoidCallback onTap;
  const _ModernAnimalCard({
    required this.animal,
    required this.imageAsset,
    required this.onTap,
  });

  @override
  State<_ModernAnimalCard> createState() => _ModernAnimalCardState();
}

class _ModernAnimalCardState extends State<_ModernAnimalCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: _hovered ? Colors.deepPurple.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withAlpha(
                  _hovered ? (0.22 * 255).toInt() : (0.10 * 255).toInt(),
                ),
                blurRadius: _hovered ? 28 : 14,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color:
                  _hovered ? Colors.orangeAccent : Colors.deepPurple.shade100,
              width: 2.2,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    widget.imageAsset,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.contain,
                    cacheWidth: kAnimalThumbDecodeWidth,
                    frameBuilder: (
                      context,
                      child,
                      frame,
                      wasSynchronouslyLoaded,
                    ) {
                      if (wasSynchronouslyLoaded) return child;
                      return AnimatedOpacity(
                        opacity: frame == null ? 0 : 1,
                        duration: const Duration(milliseconds: 400),
                        child: child,
                      );
                    },
                    errorBuilder:
                        (context, error, stackTrace) => Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.pets,
                            size: 60,
                            color: Colors.deepPurple,
                          ),
                        ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.deepPurple.shade100,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withAlpha((0.06 * 255).toInt()),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.animal,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade700,
                        letterSpacing: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 3),
                    // Ulduzlar adın ALTINDA, kartın öz qutusunun içindədir:
                    // şəklin üstündə üzən nişan heyvanı örtürdü, burada isə
                    // uşaq adı və qazandığı ulduzu bir yerdə görür. Ağ kartda
                    // boş ulduz açıq bənövşəyi olur (tünd fondaki ağ deyil).
                    StarRow(
                      filled: ProgressStore.instance.animalStars(
                        widget.animal,
                      ),
                      size: 15,
                      spacing: 1,
                      emptyColor: Colors.deepPurple.shade100,
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

/// Qridin ilk xanası: hərfi yazma oyununa giriş.
///
/// Formaca `_ModernAnimalCard` ilə eynidir (18 radius, eyni kölgə quruluşu,
/// 200 ms hover animasiyası, eyni padding), amma rəngcə qəsdən ayrılır:
/// heyvan kartları ağ fondadır, bu kart isə səhifədə onsuz da işlənən
/// sarı-narıncı (yellowAccent → orangeAccent) qradiyentlə isti görünür, ona
/// görə uşaq onu heyvanla qarışdırmır.
/// Yazı oyununun qrid xanası.
///
/// Söz yazılmır: kartın ÖZÜ hərfin cızılmamış halıdır — qalın solğun "yol",
/// üstündə kəsik orta xətt və birinci ştrixin başlanğıcında sarı nöqtə. Uşaq
/// oyunda məhz bunu görəcək, ona görə kart nə vəd etdiyini mətnsiz anladır.
///
/// Ağ heyvan kartlarının arasında qəsdən tərsinə boyanıb (səhifənin öz bənövşəyi
/// qradiyenti) — beləcə heyvan sayılmır və AppBar-dakı kiçik ikondan fərqli
/// olaraq gözdən qaçmır.
class _WriteLetterCard extends StatefulWidget {
  final String letter;
  final VoidCallback onTap;
  const _WriteLetterCard({required this.letter, required this.onTap});

  @override
  State<_WriteLetterCard> createState() => _WriteLetterCardState();
}

class _WriteLetterCardState extends State<_WriteLetterCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final units = LetterStrokes.unitsFor(widget.letter);
    return Semantics(
      button: true,
      label: '${widget.letter} hərfini yaz',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple.shade500,
                  Colors.deepPurple.shade800,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.yellowAccent.withAlpha(_hovered ? 150 : 60),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(_hovered ? 90 : 55),
                  blurRadius: _hovered ? 26 : 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Küncdəki kiçik lələk nişanı: mətn olmadan "bu, yazı işidir"
                // deyən yeganə əlavə. Hərfin özünə yer qalsın deyə kiçikdir.
                Align(
                  alignment: Alignment.topRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Yazma tək tapşırıqdır, ona görə üç ulduz yerinə bir
                      // ulduz: dolu = hərf yazılıb.
                      Icon(
                        ProgressStore.instance.isWritten(widget.letter)
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 20,
                        color:
                            ProgressStore.instance.isWritten(widget.letter)
                                ? Colors.white
                                : Colors.white54,
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.history_edu,
                        size: 18,
                        color: Colors.yellowAccent.withAlpha(
                          _hovered ? 235 : 165,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: units == null
                      // Ştrix datası olmayan hərf üçün ehtiyat: sadəcə hərfin
                      // özü. Praktikada bura düşülmür — kart yalnız
                      // `LetterStrokes.has()` doğru olanda qurulur.
                      ? Center(
                          child: Text(
                            widget.letter,
                            style: const TextStyle(
                              fontFamily: 'Baloo2',
                              fontSize: 56,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.only(top: 2, bottom: 4),
                          child: CustomPaint(
                            painter: _TraceGlyphPainter(
                              units: units,
                              road: Colors.white.withAlpha(56),
                              ink: Colors.white.withAlpha(_hovered ? 235 : 195),
                              accent: Colors.yellowAccent,
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Hərfi "hələ cızılmamış" halda çəkir: qalın yol + kəsik orta xətt + başlanğıc
/// nöqtəsi. `TracingCanvas`-ın kiçildilmiş, statik variantıdır — eyni
/// [LetterStrokes] datasından qidalanır, ona görə kartda görünən forma oyunda
/// görünənlə həmişə eyni olur.
class _TraceGlyphPainter extends CustomPainter {
  const _TraceGlyphPainter({
    required this.units,
    required this.road,
    required this.ink,
    required this.accent,
  });

  final List<TraceUnit> units;
  final Color road;
  final Color ink;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (units.isEmpty) return;

    // Qutu (100x104) xanaya sığdırılır, nisbət qorunur və mərkəzləşdirilir.
    final scale = math.min(
      size.width / kGlyphBox.width,
      size.height / kGlyphBox.height,
    );
    canvas.save();
    canvas.translate(
      (size.width - kGlyphBox.width * scale) / 2,
      (size.height - kGlyphBox.height * scale) / 2,
    );
    canvas.scale(scale);

    final roadPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = road;

    final inkPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = ink;

    for (final u in units) {
      if (u.kind == TraceUnitKind.stroke) {
        canvas.drawPath(u.partialPath(1), roadPaint);
      } else {
        canvas.drawCircle(u.start, 6, Paint()..color = road);
      }
    }

    for (final u in units) {
      if (u.kind == TraceUnitKind.stroke) {
        canvas.drawPath(
          dashPath(
            u.partialPath(1),
            dashArray: CircularIntervalList<double>(const [5, 4.5]),
          ),
          inkPaint,
        );
      } else {
        canvas.drawCircle(u.start, 2.6, Paint()..color = ink);
      }
    }

    // Birinci ştrixin başlanğıcı: "buradan başla".
    for (final u in units) {
      if (u.kind != TraceUnitKind.stroke) continue;
      canvas.drawCircle(u.start, 4.4, Paint()..color = accent);
      break;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_TraceGlyphPainter old) =>
      old.units != units ||
      old.road != road ||
      old.ink != ink ||
      old.accent != accent;
}

// Səsləndirmə düyməsi üçün xüsusi widget
class _SoundButton extends StatefulWidget {
  final String info;
  final String letter;
  const _SoundButton({required this.info, required this.letter});

  @override
  State<_SoundButton> createState() => _SoundButtonState();
}

class _SoundButtonState extends State<_SoundButton> {
  bool _hovered = false;
  bool _isPlaying = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();

    // Səs bitdikdə _isPlaying-i false et
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playSound(String audioPath) async {
    await _audioPlayer.setAsset(audioPath);
    await _audioPlayer.play();
  }

  Future<void> _playLetterSound() async {
    final audioPath = AppConfig.letterAudioPath(widget.letter);
    setState(() {
      _isPlaying = true;
    });
    try {
      await _playSound(audioPath);
    } catch (e) {
      // Fayl yoxdursa və ya oxunmursa düymə "dayandır" vəziyyətində ilişməsin.
      debugPrint('Hərf səsi oxunmadı ($audioPath): $e');
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Colors.yellowAccent, Colors.orangeAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: (_hovered ? Colors.deepPurple : Colors.yellowAccent)
                  .withAlpha((0.25 * 255).toInt()),
              blurRadius: 12,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.all(1),
        child: IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder:
                (child, anim) => ScaleTransition(scale: anim, child: child),
            child:
                _isPlaying
                    ? Icon(
                      Icons.stop,
                      key: const ValueKey('stop'),
                      color: Colors.deepPurple,
                      size: 22,
                    )
                    : Icon(
                      Icons.volume_up,
                      key: const ValueKey('play'),
                      color: Colors.deepPurple,
                      size: 22,
                    ),
          ),
          onPressed: () async {
            if (_isPlaying) {
              await _audioPlayer.stop();
              setState(() {
                _isPlaying = false;
              });
            } else {
              await _playLetterSound();
            }
          },
          splashRadius: 20,
          tooltip: _isPlaying ? 'Dayandır' : 'Səsləndir',
        ),
      ),
    );
  }
}

// Ox düymələri üçün əlavə widget və enum

enum ArrowDirection { left, right }

class _LetterArrowAppBarButton extends StatelessWidget {
  final ArrowDirection direction;
  final String currentLetter;
  const _LetterArrowAppBarButton({
    required this.direction,
    required this.currentLetter,
  });

  @override
  Widget build(BuildContext context) {
    final alphabet = AppConfig.alphabet;
    final currentIndex = alphabet.indexOf(currentLetter);
    final isLeft = direction == ArrowDirection.left;
    final isDisabled =
        isLeft ? currentIndex == 0 : currentIndex == alphabet.length - 1;
    final nextIndex = isLeft ? currentIndex - 1 : currentIndex + 1;
    return IconButton(
      icon: Icon(
        isLeft ? Icons.navigate_before : Icons.navigate_next,
        color: isDisabled ? Colors.white24 : Colors.white,
        size: 22,
      ),
      tooltip: isLeft ? 'Əvvəlki hərf' : 'Növbəti hərf',
      onPressed:
          isDisabled
              ? null
              : () {
                final nextLetter = alphabet[nextIndex];
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder:
                        (context, animation, secondaryAnimation) =>
                            AnimalListPage(letter: nextLetter),
                    transitionsBuilder: (
                      context,
                      animation,
                      secondaryAnimation,
                      child,
                    ) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.easeInOutCubic;
                      var tween = Tween(
                        begin: isLeft ? const Offset(-1.0, 0.0) : begin,
                        end: end,
                      ).chain(CurveTween(curve: curve));
                      var offsetAnimation = animation.drive(tween);
                      return SlideTransition(
                        position: offsetAnimation,
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 500),
                  ),
                );
              },
    );
  }
}

/// Hərfin ümumi tərəqqisi: zolaq + ulduzlar + "n/m".
///
/// "Heyvanlar" başlığının sağındaki dekorativ xəttin yerində durur, ona görə
/// QƏSDƏN nazikdir (ən hündür elementi 18 px ulduzdur) — başlıq sətrindən
/// hündür olsa səhifə uzanır və qrid sıxılır.
///
/// Store-a özü qoşulmur — valideyn [AnimalListPage] `ProgressStore`-u dinləyir
/// və dəyişəndə bütün alt ağacı yenidən qurur. Beləcə səhifədə tək bir dinləyici
/// olur, hər kart üçün ayrı-ayrı deyil.
class _LetterProgressBar extends StatelessWidget {
  const _LetterProgressBar({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    final store = ProgressStore.instance;
    final total = store.letterTotal(letter);
    // Əlifbada olmayan hərf (praktikada baş vermir) — "0/0" yazmaq yerinə
    // köhnə dekorativ xətt kimi sadəcə boşluq qalır.
    if (total <= 0) return const SizedBox.shrink();
    final done = store.letterDone(letter);
    final complete = done >= total;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: done / total,
              minHeight: 6,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(
                complete ? kStarGold : Colors.yellowAccent,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        StarRow(filled: store.starsOf(letter), size: 18, spacing: 1),
        const SizedBox(width: 6),
        Text(
          complete ? 'Tamam!' : '$done/$total',
          style: TextStyle(
            color: complete ? kStarGold : Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
