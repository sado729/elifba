import 'dart:ui';

import 'package:elifba/core/config.dart';
import 'package:elifba/core/letter_strokes.dart';
import 'package:elifba/core/stroke_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hərf datasının avtomatik yoxlanması.
///
/// Ştrix koordinatları əl ilə yazıldığı üçün bu testlər planın "Dev QA"
/// mərhələsini əvəz edir: səhv qutudan çıxmış, degenerativ və ya baza hərflə
/// uyğunsuz olan qlif cihaza çıxmadan burada tutulur.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Hərfin bütün sample nöqtələrinin əhatə etdiyi düzbucaqlı.
  Rect boundsOf(List<TraceUnit> units) {
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final u in units) {
      for (final p in u.points) {
        minX = p.dx < minX ? p.dx : minX;
        minY = p.dy < minY ? p.dy : minY;
        maxX = p.dx > maxX ? p.dx : maxX;
        maxY = p.dy > maxY ? p.dy : maxY;
      }
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  test('əlifbanın hər 32 hərfi üçün data var', () {
    final missing = AppConfig.alphabet
        .where((l) => !LetterStrokes.has(l))
        .toList();
    expect(missing, isEmpty, reason: 'Datası olmayan hərflər: $missing');
  });

  test('artıq və ya naməlum hərf yoxdur', () {
    final extra = LetterStrokes.upper.keys
        .where((l) => !AppConfig.alphabet.contains(l))
        .toList();
    expect(extra, isEmpty, reason: 'Əlifbada olmayan açarlar: $extra');
  });

  group('path sintaksisi', () {
    test('yalnız mütləq M L Q C komandaları işlədilir', () {
      final bad = <String>[];
      final allowed = RegExp(r'^[MLQC0-9.\- ]+$');
      for (final entry in LetterStrokes.upper.entries) {
        for (final d in entry.value) {
          if (!allowed.hasMatch(d)) bad.add('${entry.key}: $d');
        }
      }
      expect(bad, isEmpty, reason: 'İcazəsiz komanda və ya simvol: $bad');
    });

    test('hər ştrix M ilə başlayır və Z ilə bağlanmır', () {
      for (final entry in LetterStrokes.upper.entries) {
        for (final d in entry.value) {
          expect(d.startsWith('M'), isTrue, reason: '${entry.key}: $d');
          expect(d.toUpperCase().contains('Z'), isFalse, reason: '${entry.key}: $d');
        }
      }
    });

    test('vergül işlədilmir — ayırıcı yalnız boşluqdur', () {
      for (final entry in LetterStrokes.upper.entries) {
        for (final d in entry.value) {
          expect(d.contains(','), isFalse, reason: '${entry.key}: $d');
        }
      }
    });
  });

  group('həndəsə', () {
    test('bütün nöqtələr qutunun içindədir', () {
      for (final letter in LetterStrokes.upper.keys) {
        final units = LetterStrokes.unitsFor(letter)!;
        final b = boundsOf(units);
        expect(b.left, greaterThanOrEqualTo(16), reason: '$letter sola çıxıb');
        expect(b.right, lessThanOrEqualTo(84), reason: '$letter sağa çıxıb');
        expect(b.top, greaterThanOrEqualTo(0), reason: '$letter yuxarı çıxıb');
        expect(b.bottom, lessThanOrEqualTo(102), reason: '$letter aşağı çıxıb');
      }
    });

    test('hər hərf cap line ilə baseline arasını doldurur', () {
      for (final letter in LetterStrokes.upper.keys) {
        final units = LetterStrokes.unitsFor(letter)!;
        final b = boundsOf(units);
        // Diakritiklər daha yuxarı/aşağı gedə bilər, amma hərfin özü bu
        // aralığı əhatə etməlidir.
        expect(b.top, lessThanOrEqualTo(22), reason: '$letter çox alçaqdır');
        expect(b.bottom, greaterThanOrEqualTo(86), reason: '$letter çox qısadır');
      }
    });

    test('degenerativ (uzunluğu olmayan) ştrix yoxdur', () {
      for (final letter in LetterStrokes.upper.keys) {
        final units = LetterStrokes.unitsFor(letter)!;
        final strokes = units.where((u) => u.kind == TraceUnitKind.stroke);
        expect(strokes, isNotEmpty, reason: '$letter yalnız nöqtədən ibarətdir');
        for (final u in strokes) {
          expect(u.length, greaterThan(8), reason: '$letter çox qısa ştrix');
        }
      }
    });

    test('ştrix sayı uşaq üçün münasibdir (ən çoxu 4)', () {
      for (final letter in LetterStrokes.upper.keys) {
        final units = LetterStrokes.unitsFor(letter)!;
        expect(units.length, inInclusiveRange(1, 4), reason: letter);
      }
    });

    test('hərflərin eni bir-birinə yaxındır', () {
      // I və J təbii olaraq dardır; qalanları eyni ölçü hissini paylaşmalıdır.
      const narrow = {'I', 'İ', 'J'};
      for (final letter in LetterStrokes.upper.keys) {
        if (narrow.contains(letter)) continue;
        final b = boundsOf(LetterStrokes.unitsFor(letter)!);
        expect(b.width, inInclusiveRange(38, 62), reason: '$letter eni ${b.width}');
      }
    });
  });

  group('ştrix istiqaməti və axıcılıq', () {
    /// Bir ştrixin bitişi ilə növbəti ştrixin başlanğıcı arasındakı məsafə.
    double gapBetween(List<TraceUnit> units, int from) =>
        (units[from].end - units[from + 1].start).distance;

    test('M-in 3-cü ştrixi aşağıdan yuxarı gedir', () {
      final third = LetterStrokes.unitsFor('M')![2];
      expect(
        third.end.dy,
        lessThan(third.start.dy),
        reason: 'M-in 3-cü ştrixi V-nin dibindən yuxarı-sağa qalxmalıdır',
      );
    });

    test('M-də 2-ci ştrix bitdiyi yerdə 3-cü ştrix başlayır', () {
      final units = LetterStrokes.unitsFor('M')!;
      expect(
        gapBetween(units, 1),
        lessThanOrEqualTo(1),
        reason: 'V hissəsi axıcı olmalıdır — qələm boş yol getməməlidir',
      );
    });

    test('Ə əvvəl əyri, sonra düz orta xətt kimi yazılır', () {
      final strokes = LetterStrokes.upper['Ə']!;
      expect(strokes.length, 2, reason: 'Ə iki ştrixdən ibarətdir');
      expect(
        strokes.first.contains('Q'),
        isTrue,
        reason: 'birinci vahid əyri olmalıdır',
      );
      expect(
        strokes.last.contains('Q') || strokes.last.contains('C'),
        isFalse,
        reason: 'ikinci vahid düz orta xətt olmalıdır',
      );
    });

    test('Ə-də əyri bitdiyi yerdə orta xətt başlayır', () {
      final units = LetterStrokes.unitsFor('Ə')!;
      expect(
        gapBetween(units, 0),
        lessThanOrEqualTo(2),
        reason: 'orta xətt əyrinin bitdiyi nöqtədən çəkilməlidir',
      );
    });
  });

  group('diakritiklər və törəmə hərflər', () {
    /// Törəmə hərfin ilk ştrixləri baza hərflə hərfi eyni olmalıdır.
    void expectDerives(String derived, String base) {
      final b = LetterStrokes.upper[base];
      final d = LetterStrokes.upper[derived];
      if (b == null || d == null) return; // "hamısı var" testi ayrıca tutur
      expect(
        d.take(b.length).toList(),
        equals(b),
        reason: '$derived hərfi $base ştrixlərini eynilə təkrarlamır',
      );
    }

    test('sedilli hərflər C və S-dən törəyir', () {
      expectDerives('Ç', 'C');
      expectDerives('Ş', 'S');
      expect(LetterStrokes.upper['Ç']?.last, LetterStrokes.cedilla);
      expect(LetterStrokes.upper['Ş']?.last, LetterStrokes.cedilla);
    });

    test('Ğ hərfi G + breve-dir', () {
      expectDerives('Ğ', 'G');
      expect(LetterStrokes.upper['Ğ']?.last, LetterStrokes.breve);
    });

    test('nöqtəli hərflər baza ştrixləri paylaşır', () {
      expectDerives('İ', 'I');
      expectDerives('Ö', 'O');
      expectDerives('Ü', 'U');
    });

    test('I nöqtəsizdir, İ bir nöqtəlidir', () {
      expect(LetterStrokes.dots['I'] ?? const <Offset>[], isEmpty);
      expect(LetterStrokes.dots['İ']?.length, 1);
    });

    test('Ö və Ü eyni umlaut koordinatlarını işlədir', () {
      expect(LetterStrokes.dots['Ö'], LetterStrokes.umlaut);
      expect(LetterStrokes.dots['Ü'], LetterStrokes.umlaut);
      expect(LetterStrokes.umlaut.length, 2);
    });

    test('nöqtələr yuxarı diakritik zonasındadır', () {
      for (final entry in LetterStrokes.dots.entries) {
        for (final o in entry.value) {
          expect(o.dy, inInclusiveRange(2, 17), reason: entry.key);
          expect(o.dx, inInclusiveRange(18, 82), reason: entry.key);
        }
      }
    });

    test('nöqtəsi olan hərfdə nöqtə sonuncu vahiddir', () {
      for (final letter in LetterStrokes.dots.keys) {
        final units = LetterStrokes.unitsFor(letter);
        if (units == null) continue;
        expect(units.last.kind, TraceUnitKind.dot, reason: letter);
      }
    });
  });

  test('unitsFor keşlənir — eyni hərf eyni siyahını qaytarır', () {
    final a = LetterStrokes.unitsFor('A');
    final b = LetterStrokes.unitsFor('A');
    expect(identical(a, b), isTrue);
  });

  test('datası olmayan hərf üçün null qaytarılır', () {
    expect(LetterStrokes.unitsFor('W'), isNull);
  });
}
