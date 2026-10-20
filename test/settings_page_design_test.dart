// Ayarlar səhifəsinin yeni görünüşünün testləri (dizayn §7.7, ScreenSettings).
//
// `settings_page_test.dart` davranışı (açarlar, seqmentlər) yoxlayır; bu fayl
// görünüşün test edilə bilən qaydalarını bağlayır: ölçülər, dialoqların
// məzmunu, snackbar, geri düyməsi və "səhnədə tək Scrollable" şərti.
//
// Səhifə səs çalmır (`GatedPlayer` qurmur), amma `AppSettings.instance` və
// `ProgressStore.instance` singleton-dur — hər testdən sonra sıfırlanır.

import 'package:elifba/core/config.dart';
import 'package:elifba/core/progress.dart';
import 'package:elifba/core/settings.dart';
import 'package:elifba/pages/settings_page.dart';
import 'package:elifba/widgets/elifba_wordmark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final settings = AppSettings.instance;
  final store = ProgressStore.instance;

  setUp(() => settings.restoreFromJson(null));
  tearDown(() async {
    settings.restoreFromJson(null);
    await store.reset();
  });

  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
    await tester.pumpAndSettle();
  }

  Future<void> openRow(WidgetTester tester, String title) async {
    await tester.scrollUntilVisible(find.text(title), 200);
    await tester.ensureVisible(find.text(title));
    await tester.pumpAndSettle();
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();
  }

  SwitchListTile switchWithTitle(WidgetTester tester, String title) =>
      tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, title));

  group('ölçülər', () {
    testWidgets('toolbar 64 dp, başlıq sola düzlənib, AppBar yoxdur', (
      tester,
    ) async {
      await pumpSettings(tester);

      expect(find.byType(AppBar), findsNothing);
      expect(find.text('Ayarlar'), findsOneWidget);
      // 8 dp boşluq + 48 dp geri düyməsi + 6 dp aralıq.
      expect(tester.getTopLeft(find.text('Ayarlar')).dx, 62);
      final back = tester.getRect(find.byTooltip('Geri'));
      expect(back.size, const Size(48, 48));
      expect(back.center.dy, 32);
    });

    testWidgets('açar sətirləri 64 dp, pazl seqmentləri 48 dp', (tester) async {
      await pumpSettings(tester);

      // 800 dp endə alt mətnlər sarılmır: iki sətirli sətir 2 × 11 + 22 + 20.
      for (final title in const ['Bütün səslər', 'Heyvan səsləri', 'Titrəmə']) {
        expect(
          tester.getSize(find.widgetWithText(SwitchListTile, title)).height,
          64,
          reason: '"$title" sətri',
        );
      }

      await tester.scrollUntilVisible(find.text('5 × 5'), 200);
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(SegmentedButton<int>)).height, 48);
      for (final label in const ['3 × 3', '4 × 4', '5 × 5']) {
        expect(find.text(label), findsOneWidget);
      }
    });
  });

  group('səs bölməsi', () {
    testWidgets('master bağlı olanda kanal açarı DƏYƏRİNİ göstərir', (
      tester,
    ) async {
      settings
        ..animalSound = false
        ..masterSound = false;
      await pumpSettings(tester);

      final animal = switchWithTitle(tester, 'Heyvan səsləri');
      expect(animal.value, isFalse);
      expect(animal.onChanged, isNull);
      final narration = switchWithTitle(tester, 'İzah və nəqletmə');
      expect(narration.value, isTrue, reason: 'master kanal dəyərini silmir');
      expect(narration.onChanged, isNull);
      // Master sətrinin özü heç vaxt qeyri-aktiv olmur.
      expect(switchWithTitle(tester, 'Bütün səslər').onChanged, isNotNull);
      expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);
    });
  });

  group('sıfırlama', () {
    testWidgets('təsdiq dialoqunda Scrollable yoxdur və ulduz sayı görünür', (
      tester,
    ) async {
      store.markWritten('Ğ'); // heyvansız hərf: yazı = 3 ulduz
      await pumpSettings(tester);
      await openRow(tester, 'Progresi sıfırla');

      expect(find.text('Bütün ulduzlar silinsin?'), findsOneWidget);
      expect(find.textContaining('Yığılmış 3 ulduz'), findsOneWidget);
      // Səhifənin siyahısı səhnədəki YEGANƏ Scrollable olaraq qalır.
      expect(find.byType(Scrollable), findsOneWidget);

      // Scrim-ə toxunmaq ləğv deməkdir.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Bütün ulduzlar silinsin?'), findsNothing);
      expect(store.totalStars, 3);
    });

    testWidgets('«Bəli, sil» snackbar-ı ✓ ikonu ilə göstərir', (tester) async {
      store.markWritten('Ğ');
      await pumpSettings(tester);
      await openRow(tester, 'Progresi sıfırla');

      await tester.tap(find.text('Bəli, sil'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(store.totalStars, 0);
      expect(find.text('Progres sıfırlandı.'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Snackbar 4 s sonra öz-özünə sönür.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text('Progres sıfırlandı.'), findsNothing);
    });
  });

  group('məlumat dialoqları', () {
    testWidgets('səs mənbələri real mətni göstərir və «Bağla» ilə bağlanır', (
      tester,
    ) async {
      await pumpSettings(tester);
      await openRow(tester, 'Səs mənbələri');

      expect(find.textContaining('bigsoundbank.com'), findsOneWidget);
      expect(find.textContaining('reinsamba'), findsOneWidget);
      // Maketin placeholder sətirləri köçürülməyib.
      expect(find.textContaining('[Mənbə'), findsNothing);
      expect(find.textContaining('Səs aktyoru'), findsNothing);

      await tester.tap(find.text('Bağla'));
      await tester.pumpAndSettle();
      expect(find.textContaining('bigsoundbank.com'), findsNothing);
    });

    testWidgets('tətbiq haqqında: loqo, versiya və paket adı', (tester) async {
      await pumpSettings(tester);
      await openRow(tester, 'Tətbiq haqqında');

      final dialog = find.byType(Dialog);
      expect(
        find.descendant(of: dialog, matching: find.byType(ElifbaWordmark)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: dialog,
          matching: find.text('Versiya $kAppVersion'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: dialog, matching: find.text(kAppPackageId)),
        findsOneWidget,
      );
      // Ad `Text` kimi yazılmır (brend qaydası).
      expect(find.text('Əlifba'), findsNothing);

      await tester.tap(find.text('Bağla'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
    });
  });

  testWidgets('geri düyməsi («Geri») ayarları bağlayır', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder:
              (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed:
                        () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SettingsPage(),
                          ),
                        ),
                    child: const Text('aç'),
                  ),
                ),
              ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    expect(find.text('Ayarlar'), findsOneWidget);

    await tester.tap(find.byTooltip('Geri'));
    await tester.pumpAndSettle();
    expect(find.text('Ayarlar'), findsNothing);
    expect(find.text('aç'), findsOneWidget);
  });
}
