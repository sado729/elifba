// `AppSettings` modelinin testləri.
//
// Burada UI yoxdur — yalnız açar məntiqi və saxlanma. Səs keçidinin ÖZÜ
// (`GatedPlayer`) qəsdən test edilmir: `AudioPlayer()` qurulması test mühitində
// platforma kanalı tələb edir (CLAUDE.md gotcha #11). Ona görə bütün qərar
// məntiqi `AppSettings.isOn()` saf funksiyasında cəmlənib və burada yoxlanılır.

import 'package:elifba/core/settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('defolt dəyərlər', () {
    test('səs açıqdır, animasiya azaldılmayıb, pazl 3x3-dür', () {
      final s = AppSettings.forTesting();
      expect(s.masterSound, isTrue);
      expect(s.narrationSound, isTrue);
      expect(s.animalSound, isTrue);
      expect(s.effectSound, isTrue);
      expect(s.haptics, isTrue);
      expect(s.reduceMotion, isFalse);
      expect(s.puzzleGridSize, 3);
      for (final c in SoundChannel.values) {
        expect(s.isOn(c), isTrue, reason: '$c defoltda açıq olmalıdır');
      }
    });
  });

  group('isOn məntiqi', () {
    test('master söndürüləndə BÜTÜN kanallar susur', () {
      final s = AppSettings.forTesting();
      s.masterSound = false;
      for (final c in SoundChannel.values) {
        expect(s.isOn(c), isFalse, reason: '$c master ilə susmalıdır');
      }
    });

    test('master söndürülsə də alt açarların dəyəri İTMİR', () {
      final s = AppSettings.forTesting();
      s.narrationSound = false; // istifadəçi nəqletməni özü söndürüb
      s.masterSound = false;
      s.masterSound = true;

      // Master geri açılanda əvvəlki vəziyyət qayıdır: nəqletmə hələ də bağlı,
      // qalanları açıq.
      expect(s.narrationSound, isFalse);
      expect(s.isOn(SoundChannel.narration), isFalse);
      expect(s.isOn(SoundChannel.animal), isTrue);
      expect(s.isOn(SoundChannel.effect), isTrue);
    });

    test('hər kanal yalnız öz açarından asılıdır', () {
      final s = AppSettings.forTesting();
      s.animalSound = false;
      expect(s.isOn(SoundChannel.animal), isFalse);
      expect(s.isOn(SoundChannel.narration), isTrue);
      expect(s.isOn(SoundChannel.effect), isTrue);
    });
  });

  group('bildiriş', () {
    test('yalnız dəyər DƏYİŞƏNDƏ dinləyici xəbərdar olunur', () {
      final s = AppSettings.forTesting();
      var calls = 0;
      s.addListener(() => calls++);

      s.masterSound = false;
      expect(calls, 1);

      s.masterSound = false; // eyni dəyər — bildiriş olmamalıdır
      expect(calls, 1);

      s.masterSound = true;
      expect(calls, 2);
    });

    test('naməlum pazl ölçüsü səssizcə buraxılır', () {
      final s = AppSettings.forTesting();
      var calls = 0;
      s.addListener(() => calls++);

      s.puzzleGridSize = 5;
      expect(s.puzzleGridSize, 3, reason: '5 icazə verilən ölçü deyil');
      expect(calls, 0);

      s.puzzleGridSize = 4;
      expect(s.puzzleGridSize, 4);
      expect(calls, 1);
    });
  });

  group('saxlanma', () {
    test('encode → restore dövrü bütün sahələri qoruyur', () {
      final a = AppSettings.forTesting();
      a.masterSound = false;
      a.narrationSound = false;
      a.animalSound = false;
      a.effectSound = false;
      a.haptics = false;
      a.reduceMotion = true;
      a.puzzleGridSize = 4;

      final b = AppSettings.forTesting()..restoreFromJson(a.encodeState());
      expect(b.masterSound, isFalse);
      expect(b.narrationSound, isFalse);
      expect(b.animalSound, isFalse);
      expect(b.effectSound, isFalse);
      expect(b.haptics, isFalse);
      expect(b.reduceMotion, isTrue);
      expect(b.puzzleGridSize, 4);
    });

    test('boş və ya null JSON defoltları saxlayır', () {
      final s = AppSettings.forTesting()..reduceMotion = true;
      s.restoreFromJson(null);
      expect(s.reduceMotion, isFalse);

      s.reduceMotion = true;
      s.restoreFromJson('');
      expect(s.reduceMotion, isFalse);
    });

    test('zədələnmiş JSON tətbiqi çökdürmür, defoltlara düşür', () {
      final s = AppSettings.forTesting()..masterSound = false;
      s.restoreFromJson('{bu düzgün JSON deyil');
      expect(s.masterSound, isTrue);

      s.masterSound = false;
      s.restoreFromJson('"sadəcə mətn"'); // Map deyil
      expect(s.masterSound, isTrue);
    });

    test('natamam JSON-da olmayan sahələr defoltda qalır', () {
      final s = AppSettings.forTesting();
      s.restoreFromJson('{"v":1,"m":false}');
      expect(s.masterSound, isFalse, reason: 'yazılan sahə oxunmalıdır');
      expect(s.narrationSound, isTrue, reason: 'olmayan sahə defoltda qalır');
      expect(s.puzzleGridSize, 3);
    });

    test('səhv tipli sahə defolta düşür', () {
      final s = AppSettings.forTesting();
      s.restoreFromJson('{"v":1,"m":"bəli","g":9}');
      expect(
        s.masterSound,
        isTrue,
        reason: 'string bool əvəzinə qəbul olunmur',
      );
      expect(s.puzzleGridSize, 3, reason: '9 icazə verilən ölçü deyil');
    });

    test('load() diskdən oxuyur', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final s = AppSettings.forTesting();
      SharedPreferences.setMockInitialValues({
        'settings_v1': '{"v":1,"m":false,"g":4}',
      });

      await s.load();

      expect(s.masterSound, isFalse);
      expect(s.puzzleGridSize, 4);
      expect(s.isOn(SoundChannel.effect), isFalse);
    });

    test('load() saxlanmış dəyər yoxdursa defoltları saxlayır', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      final s = AppSettings.forTesting();

      await s.load();

      expect(s.masterSound, isTrue);
      expect(s.puzzleGridSize, 3);
    });
  });
}
