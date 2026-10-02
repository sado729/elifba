// `normalizeFileName` / `getFirstLetter` davranışının vahid testləri.
//
// Bu iki funksiya bütün asset yollarının açarıdır, ona görə davranışları —
// bilinən məhdudiyyətləri də daxil olmaqla — burada sənədləşdirilir.
import 'package:elifba/core/config.dart';
import 'package:elifba/core/utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeFileName', () {
    test('Azərbaycan diakritiklərini sadələşdirir', () {
      expect(AppConfig.normalizeFileName('Əqrəb'), 'eqreb');
      expect(AppConfig.normalizeFileName('Çita'), 'cita');
      expect(AppConfig.normalizeFileName('Şir'), 'sir');
      expect(AppConfig.normalizeFileName('Ördək'), 'ordek');
      expect(AppConfig.normalizeFileName('Ağacdələn'), 'agacdelen');
      expect(AppConfig.normalizeFileName('Buqələmun'), 'buqelemun');
      expect(AppConfig.normalizeFileName('Qırqovul'), 'qirqovul');
      expect(AppConfig.normalizeFileName('Zürafə'), 'zurafe');
    });

    test('boşluğu alt xətt edir', () {
      expect(AppConfig.normalizeFileName('Ağac qabığı'), 'agac_qabigi');
    });

    test('yeni adların fayl adları', () {
      // Adlar standart Azərbaycan yazılışına keçəndə assetlər də bu adlarla
      // yenidən adlandırıldı (məs. Hamster -> Dağsiçanı -> `dagsicani`).
      expect(AppConfig.normalizeFileName('Qızılqaz'), 'qizilqaz');
      expect(AppConfig.normalizeFileName('Dağsiçanı'), 'dagsicani');
      expect(AppConfig.normalizeFileName('Maralöküz'), 'maralokuz');
      expect(AppConfig.normalizeFileName('Leylək'), 'leylek');
    });
  });

  group('getFirstLetter', () {
    test('normalizə olunmuş ilk hərfi qaytarır', () {
      expect(getFirstLetter('Əqrəb'), 'e');
      expect(getFirstLetter('Çaqqal'), 'c');
      expect(getFirstLetter('Ördək'), 'o');
      expect(getFirstLetter('Şir'), 's');
      expect(getFirstLetter('At'), 'a');
    });

    test('boş mətndə boş sətir qaytarır', () {
      expect(getFirstLetter(''), '');
    });
  });

  group('hərf -> qovluq uyğunluğu (bilinən məhdudiyyət)', () {
    test('I və İ eyni `i` qovluğuna düşür', () {
      // Dart-ın `toLowerCase()` metodu hər iki hərfi tək `i` koduna çevirir,
      // ona görə nöqtəsiz `I` səhifəsi `İ`-nin assetlərini istəyir və
      // `assets/images/ı/` qovluğuna heç vaxt müraciət olunmur.
      // Düzəlişi hərf -> qovluq cədvəlini açıq yazmaqdır.
      expect('I'.toLowerCase(), 'i');
      expect('İ'.toLowerCase(), 'i');
      expect('I'.toLowerCase().codeUnits, [105]);
    });

    test('digər diakritik hərflər öz qovluğunu saxlayır', () {
      expect('Ə'.toLowerCase(), 'ə');
      expect('Ç'.toLowerCase(), 'ç');
      expect('Ğ'.toLowerCase(), 'ğ');
      expect('Ö'.toLowerCase(), 'ö');
      expect('Ş'.toLowerCase(), 'ş');
      expect('Ü'.toLowerCase(), 'ü');
    });
  });

  group('hərf səsi köməkçiləri', () {
    test('hasLetterAudio böyük/kiçik hərfə həssas deyil', () {
      expect(AppConfig.hasLetterAudio('A'), isTrue);
      expect(AppConfig.hasLetterAudio('a'), isTrue);
      expect(AppConfig.hasLetterAudio('W'), isFalse);
    });

    test('I və İ hərf səsi ayrı qovluqlara düşür', () {
      expect(
        AppConfig.letterAudioPath('I'),
        'assets/audios/ı/ı_info_sound.mp3',
      );
      expect(
        AppConfig.letterAudioPath('İ'),
        'assets/audios/i/i_info_sound.mp3',
      );
    });

    test('letterAudioPath gözlənilən yolu qurur', () {
      expect(
        AppConfig.letterAudioPath('A'),
        'assets/audios/a/a_info_sound.mp3',
      );
      expect(
        AppConfig.letterAudioPath('Ə'),
        'assets/audios/ə/ə_info_sound.mp3',
      );
    });
  });
}
