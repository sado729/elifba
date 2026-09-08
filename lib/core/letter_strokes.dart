import 'dart:ui';

import 'package:path_drawing/path_drawing.dart';

import 'stroke_tracker.dart';

/// Hərflərin cızma (ştrix) datası.
///
/// Bütün koordinatlar 100x104 qutusundadır və `tracing_canvas.dart`-dakı
/// [kGlyphBox] ilə eyni olmalıdır. Qutunun sətirləri:
///
/// ```
///   y = 2..17    yuxarı diakritik zonası (breve, umlaut nöqtələri)
///   y = 20       cap line — böyük hərfin zirvəsi
///   y = 54       orta xətt
///   y = 88       əsas sətir (baseline) — hərfin dibi
///   y = 88..101  aşağı diakritik zonası (sedil)
///   x = 22..80   hərfin əsas eni
/// ```
///
/// Şrift qlifindən kontur çıxarmaq Flutter-də etibarlı yol deyil, üstəlik
/// kontur yazı istiqamətini bilmir — ona görə data əl ilə yazılıb.
///
/// Ştrix sırası məktəb yazı qaydasına tabedir: yuxarıdan aşağı, soldan sağa,
/// şaquli gövdə birinci, diakritik həmişə sonuncu. Törəmə hərflər baza hərfin
/// ştrixlərini eyni sabitdən götürür, ona görə "Ç ilə C-nin qövsü fərqlənir"
/// tipli uyğunsuzluq strukturca mümkün deyil. "Yuxarıdan aşağı" qaydasının
/// yeganə istisnası M-in 3-cü ştrixidir — səbəbi öz yerində yazılıb.
///
/// Datanın bütövlüyünü `test/letter_strokes_test.dart` yoxlayır: hədlər,
/// sintaksis, degenerativ ştrix, en ardıcıllığı və törəmə zəncirləri.
class LetterStrokes {
  const LetterStrokes._();

  /// Sedil — Ç və Ş hərflərinin sonuncu ştrixi.
  static const String cedilla = 'M50 88 Q53 96 44 100';

  /// Breve — Ğ hərfinin sonuncu ştrixi.
  static const String breve = 'M34 6 Q50 17 66 6';

  /// Umlaut — Ö və Ü hərflərinin iki nöqtəsi.
  static const List<Offset> umlaut = [Offset(37, 10), Offset(63, 10)];

  // --- Paylaşılan formalar ------------------------------------------------
  // Bunlar bir neçə hərfdə təkrarlanır; sabit kimi saxlanması həm faylı
  // qısaldır, həm də hərflərin nisbətlərini bir-birinə bağlayır.

  /// Sol tərəfdəki şaquli gövdə — B D E F H K L M N P R hərflərində eynidir.
  static const String _stem = 'M30 20 L30 88';

  static const List<String> _c = [
    'M77 34 Q69 20 50 20 Q23 20 23 54 Q23 88 50 88 Q69 88 77 74',
  ];

  static const List<String> _g = [
    'M77 34 Q69 20 50 20 Q23 20 23 54 Q23 88 50 88 Q77 88 77 64',
    'M77 64 L58 64',
  ];

  static const List<String> _o = [
    'M50 20 Q23 20 23 54 Q23 88 50 88 Q77 88 77 54 Q77 20 50 20',
  ];

  static const List<String> _s = [
    'M75 33 Q73 20 50 20 Q23 20 23 37 Q23 51 50 54 '
        'Q77 57 77 71 Q77 88 50 88 Q27 88 25 75',
  ];

  static const List<String> _u = [
    'M23 20 L23 62 Q23 88 50 88 Q77 88 77 62 L77 20',
  ];

  static const List<String> _i = ['M50 20 L50 88'];

  /// P — gövdə + tək bowl. R bunun üstünə ayaq əlavə edir.
  static const List<String> _p = [
    _stem,
    'M30 20 L56 20 Q76 20 76 37 Q76 54 56 54 L30 54',
  ];

  /// F — gövdə + iki üfüqi xətt. E bunun üstünə alt xətti əlavə edir.
  static const List<String> _f = [_stem, 'M30 20 L72 20', 'M30 54 L64 54'];

  /// Böyük hərflərin ştrixləri, cızma sırası ilə. Açarlar `AppConfig.alphabet`
  /// ilə eyni olmalıdır.
  static const Map<String, List<String>> upper = {
    'A': ['M50 20 L22 88', 'M50 20 L78 88', 'M31 66 L69 66'],
    'B': [
      _stem,
      'M30 20 L56 20 Q76 20 76 37 Q76 54 56 54 L30 54',
      'M30 54 L59 54 Q80 54 80 71 Q80 88 59 88 L30 88',
    ],
    'C': _c,
    'Ç': [..._c, cedilla],
    'D': [_stem, 'M30 20 L52 20 Q80 20 80 54 Q80 88 52 88 L30 88'],
    'E': [..._f, 'M30 88 L72 88'],
    // Ə çevrilmiş "e"-dir: açıqlığı yuxarı-soldadır. Qələm açıqlığın yuxarı
    // dodağından (24,42) başlayır, təpədən keçib sağ tərəfdən aşağı enir,
    // dibi dolanır və orta xəttin sol ucunda (23,62) dayanır — orta xətt elə
    // oradan sağa çəkilir. Yəni əyri bitdiyi yerdə xətt başlayır, qələm boş
    // yol getmir.
    'Ə': [
      'M24 42 Q28 20 50 20 Q77 20 77 54 Q77 88 50 88 Q26 88 23 62',
      'M23 62 L77 62',
    ],
    'F': _f,
    'G': _g,
    'Ğ': [..._g, breve],
    'H': [_stem, 'M70 20 L70 88', 'M30 54 L70 54'],
    'X': ['M22 20 L78 88', 'M78 20 L22 88'],
    'I': _i,
    'İ': _i,
    'J': ['M60 20 L60 70 Q60 88 44 88 Q32 88 32 76'],
    'K': [_stem, 'M78 20 L30 54', 'M30 54 L78 88'],
    'Q': [..._o, 'M60 71 Q72 80 80 97'],
    'L': [_stem, 'M30 88 L72 88'],
    // M-in 3-cü ştrixi qəsdən aşağıdan yuxarı gedir — faylın "həmişə
    // yuxarıdan aşağı" qaydasının yeganə istisnası. 2-ci ştrix V-nin dibinə
    // (50,74) enir, 3-cü elə oradan yuxarı-sağa qalxır: qələm boş yol getmir,
    // V hissəsi tək axıcı hərəkətlə yazılır. 4-cü ştrix yenə yuxarıdan aşağı.
    'M': [_stem, 'M30 20 L50 74', 'M50 74 L70 20', 'M70 20 L70 88'],
    'N': [_stem, 'M30 20 L70 88', 'M70 20 L70 88'],
    'O': _o,
    'Ö': _o,
    'P': _p,
    'R': [..._p, 'M48 54 L78 88'],
    'S': _s,
    'Ş': [..._s, cedilla],
    'T': ['M50 20 L50 88', 'M22 20 L78 20'],
    'U': _u,
    'Ü': _u,
    'V': ['M22 20 L50 88', 'M78 20 L50 88'],
    'Y': ['M22 20 L50 54', 'M78 20 L50 54', 'M50 54 L50 88'],
    'Z': ['M22 20 L78 20', 'M78 20 L22 88', 'M22 88 L78 88'],
  };

  /// Toxunuşla tamamlanan nöqtələr — cızılmır, üstünə toxunulur.
  ///
  /// `I` hərfinin nöqtəsi YOXDUR: Azərbaycan dilində `I` və `İ` ayrı hərflərdir.
  static const Map<String, List<Offset>> dots = {
    'İ': [Offset(50, 12)],
    'Ö': umlaut,
    'Ü': umlaut,
  };

  /// Parse nəticəsi keşlənir: eyni hərf üçün HƏMİŞƏ eyni siyahı qaytarılır ki,
  /// `TracingCanvas.didUpdateWidget` `identical()` ilə dəyişikliyi tuta bilsin.
  static final Map<String, List<TraceUnit>> _cache = {};

  /// Hərfin datası varmı.
  static bool has(String letter) => upper.containsKey(letter);

  /// Hərfin cızma vahidləri: əvvəl ştrixlər, sonra nöqtələr.
  /// Datası olmayan hərf üçün `null` qaytarır.
  static List<TraceUnit>? unitsFor(String letter) {
    final cached = _cache[letter];
    if (cached != null) return cached;

    final strokes = upper[letter];
    if (strokes == null) return null;

    final units = <TraceUnit>[
      for (final d in strokes) TraceUnit.stroke(parseSvgPathData(d)),
      for (final o in dots[letter] ?? const <Offset>[]) TraceUnit.dot(o),
    ];
    _cache[letter] = units;
    return units;
  }
}
