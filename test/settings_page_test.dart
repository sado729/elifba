// Ayarlar səhifəsinin və sürətli mute düyməsinin UI testləri.
//
// `AppSettings.instance` singleton-dur (`ProgressStore.instance` kimi) və
// səhifə birbaşa ondan oxuyur, ona görə hər testdən əvvəl defoltlara qaytarılır
// — əks halda testlər bir-birinə sızar. `_prefs` null olduğu üçün diskə heç nə
// yazılmır.
//
// `AlphabetPage` `GatedPlayer` qurur, ona görə CLAUDE.md gotcha #11-ə uyğun
// olaraq heç bir just_audio çağırışı `await` edilmir və `tester.runAsync`
// istifadə olunmur.

import 'package:elifba/core/settings.dart';
import 'package:elifba/pages/alphabet_page.dart';
import 'package:elifba/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final settings = AppSettings.instance;

  setUp(() => settings.restoreFromJson(null));
  tearDown(() => settings.restoreFromJson(null));

  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
    await tester.pumpAndSettle();
  }

  SwitchListTile switchWithTitle(WidgetTester tester, String title) =>
      tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, title));

  group('səs bölməsi', () {
    testWidgets('master söndürüləndə alt açarlar qeyri-aktiv olur', (
      tester,
    ) async {
      await pumpSettings(tester);

      // Başlanğıcda hamısı aktiv.
      expect(switchWithTitle(tester, 'İzah və nəqletmə').onChanged, isNotNull);

      await tester.tap(find.widgetWithText(SwitchListTile, 'Bütün səslər'));
      await tester.pumpAndSettle();

      expect(settings.masterSound, isFalse);
      for (final title in const [
        'İzah və nəqletmə',
        'Heyvan səsləri',
        'Effektlər',
      ]) {
        expect(
          switchWithTitle(tester, title).onChanged,
          isNull,
          reason: '"$title" master söndürüləndə qeyri-aktiv olmalıdır',
        );
      }
    });

    testWidgets('master söndürülsə də alt açarların DƏYƏRİ qalır', (
      tester,
    ) async {
      await pumpSettings(tester);

      await tester.tap(find.widgetWithText(SwitchListTile, 'Heyvan səsləri'));
      await tester.pumpAndSettle();
      expect(settings.animalSound, isFalse);

      // Master-i söndürüb geri açmaq əvvəlki seçimi POZMAMALIDIR.
      await tester.tap(find.widgetWithText(SwitchListTile, 'Bütün səslər'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(SwitchListTile, 'Bütün səslər'));
      await tester.pumpAndSettle();

      expect(settings.masterSound, isTrue);
      expect(settings.animalSound, isFalse, reason: 'seçim qorunmalıdır');
      expect(settings.narrationSound, isTrue);
      expect(switchWithTitle(tester, 'Heyvan səsləri').value, isFalse);
    });
  });

  group('oyun bölməsi', () {
    testWidgets('titrəmə və animasiya açarları ayara yazılır', (tester) async {
      await pumpSettings(tester);

      await tester.tap(find.widgetWithText(SwitchListTile, 'Titrəmə'));
      await tester.pumpAndSettle();
      expect(settings.haptics, isFalse);

      await tester.tap(
        find.widgetWithText(SwitchListTile, 'Animasiyanı azalt'),
      );
      await tester.pumpAndSettle();
      expect(settings.reduceMotion, isTrue);
    });

    testWidgets('pazl ölçüsü seçilir', (tester) async {
      await pumpSettings(tester);

      // `scrollUntilVisible` widget-i yalnız görünüş sahəsinin KƏNARINA
      // gətirir; mərkəzi hələ ekrandan kənarda qala bilər və toxunuş boşa
      // düşər. `ensureVisible` onu tam görünən yerə çəkir.
      await tester.scrollUntilVisible(find.text('4 × 4'), 200);
      await tester.ensureVisible(find.text('4 × 4'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('4 × 4'));
      await tester.pumpAndSettle();

      expect(settings.puzzleGridSize, 4);
    });
  });

  group('sürətli mute düyməsi', () {
    testWidgets('kitab səhifəsində qapısız işləyir', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AlphabetPage()));
      await tester.pump();

      expect(find.byIcon(Icons.volume_up), findsOneWidget);

      await tester.tap(find.byIcon(Icons.volume_up));
      await tester.pump();

      expect(settings.masterSound, isFalse);
      expect(find.byIcon(Icons.volume_off), findsOneWidget);
      expect(find.byIcon(Icons.volume_up), findsNothing);

      // Geri qaytarmaq da bir toxunuşdur.
      await tester.tap(find.byIcon(Icons.volume_off));
      await tester.pump();
      expect(settings.masterSound, isTrue);
      expect(tester.takeException(), isNull);
    });
  });
}
