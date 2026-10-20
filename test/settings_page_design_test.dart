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
import 'package:elifba/widgets/parent_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

    testWidgets('sətir yeri 64 dp (xətt daxil), pazl seqmentləri 48 dp', (
      tester,
    ) async {
      await pumpSettings(tester);

      // Maket: `min-height: 64px; box-sizing: border-box`, sonrakı sətirlərin
      // 1 px `border-top`-u 64-ün içindədir. 800 dp endə alt mətnlər sarılmır.
      // Kartın ilk sətri 64, xəttdən sonrakılar 63 + 1 dp xətt.
      for (final (title, height) in const [
        ('Bütün səslər', 64.0),
        ('Titrəmə', 64.0),
        ('Heyvan səsləri', 63.0),
        ('Effektlər', 63.0),
      ]) {
        expect(
          tester.getSize(find.widgetWithText(SwitchListTile, title)).height,
          height,
          reason: '"$title" sətri',
        );
      }
      // «Səs» kartı maketdəki kimi 4 × 64.
      expect(tester.getSize(find.byType(ParentGroup).first).height, 4 * 64);
      // Başlıq ilə altyazı arasında maketin 1 dp-si.
      final title = tester.getRect(find.text('Bütün səslər'));
      final subtitle = tester.getRect(
        find.text('Tətbiqdəki bütün səsləri susdurur'),
      );
      expect(subtitle.top - title.bottom, 1);

      await tester.scrollUntilVisible(find.text('5 × 5'), 200);
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(SegmentedButton<int>)).height, 48);
      for (final label in const ['3 × 3', '4 × 4', '5 × 5']) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('bölmə başlığının sətir qutusu 22 dp (line-height normal)', (
      tester,
    ) async {
      await pumpSettings(tester);

      expect(tester.getSize(find.text('Səs')).height, closeTo(22, 0.001));
      // Səs başlığı: siyahının 4 + 12 dp üst boşluğu; kart 4 + 8 dp sonra.
      final header = tester.getRect(find.text('Səs'));
      final card = tester.getRect(find.byType(ParentGroup).first);
      expect(card.top - header.bottom, 12);
    });

    testWidgets('seçilmiş seqment: ✓ etiketdə, 6 dp aralıq, M3 konturu yox', (
      tester,
    ) async {
      settings.puzzleGridSize = 4;
      await pumpSettings(tester);
      await tester.scrollUntilVisible(find.text('5 × 5'), 200);
      await tester.pumpAndSettle();

      final segmented = find.byType(SegmentedButton<int>);
      final check = find.descendant(
        of: segmented,
        matching: find.byIcon(Icons.check_rounded),
      );
      expect(check, findsOneWidget);
      expect(
        tester.getTopLeft(find.text('4 × 4')).dx -
            tester.getTopRight(check).dx,
        6,
      );
      // Kontur seqmentlərin altında əl ilə çəkilir (seçilmiş seqmentin fonu
      // onu örtsün); M3-ün üstdən çəkdiyi kontur söndürülüb.
      final button = tester.widget<SegmentedButton<int>>(segmented);
      expect(button.showSelectedIcon, isFalse);
      expect(button.style?.side?.resolve(const {}), BorderSide.none);
      expect(
        find.ancestor(of: segmented, matching: find.byType(CustomPaint)),
        findsWidgets,
      );
    });

    testWidgets('yan insetlər: kartlar landşaftda nav bar-ın altına girmir', (
      tester,
    ) async {
      // `FakeViewPadding` fiziki pikseldir: DPR 1 → dp ilə eyni.
      const insets = FakeViewPadding(left: 32, top: 24, right: 48);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 600);
      tester.view.padding = insets;
      tester.view.viewPadding = insets;
      addTearDown(tester.view.reset);
      await pumpSettings(tester);

      final card = tester.getRect(find.byType(ParentGroup).first);
      expect(card.left, 32 + 16);
      expect(card.right, 800 - 48 - 16);
      // Toolbar da eyni insetdədir (SafeArea): geri düyməsi 32 + 8-dən.
      expect(tester.getRect(find.byTooltip('Geri')).left, 32 + 8);
    });

    testWidgets('«Ayarlar» ekranın adıdır (AppBar kimi namesRoute)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpSettings(tester);

      expect(
        tester.getSemantics(find.text('Ayarlar')),
        containsSemantics(label: 'Ayarlar', isHeader: true, namesRoute: true),
      );
      handle.dispose();
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

    // Reqressiya: `ParentDialog`-un sürüşməyən `Column`-u landşaftda böyük
    // şriftlə daşırdı və düymələr ekrandan çıxırdı (640 × 360, 1.3: 84 dp).
    // Oriyentasiya kilidlənməyib, tətbiq şrifti 1.3-ə qədər buraxır.
    for (final (size, insets) in const [
      (Size(640, 360), FakeViewPadding(top: 24, bottom: 24)),
      (Size(640, 360), FakeViewPadding(top: 24, right: 48)),
      (Size(568, 320), FakeViewPadding(top: 24, bottom: 24)),
    ]) {
      testWidgets(
        'landşaft ${size.width.toInt()} × ${size.height.toInt()}, şrift 1.3: '
        'təsdiq düymələri görünür və işləyir',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          tester.view.padding = insets;
          tester.view.viewPadding = insets;
          tester.platformDispatcher.textScaleFactorTestValue = 1.3;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          store.markWritten('Ğ');
          await pumpSettings(tester);
          await openRow(tester, 'Progresi sıfırla');

          expect(tester.takeException(), isNull);
          expect(find.text('Bütün ulduzlar silinsin?'), findsOneWidget);
          // Dialoqda hələ də `Scrollable` yoxdur (B11).
          expect(find.byType(Scrollable), findsOneWidget);
          for (final label in const ['Ləğv et', 'Bəli, sil']) {
            final rect = tester.getRect(find.text(label));
            expect(rect.top, greaterThanOrEqualTo(insets.top), reason: label);
            expect(
              rect.bottom,
              lessThanOrEqualTo(size.height - insets.bottom),
              reason: label,
            );
          }

          await tester.tap(find.text('Bəli, sil'));
          await tester.pumpAndSettle();
          expect(store.totalStars, 0);
          await tester.pump(const Duration(seconds: 5));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('yer çatmayanda mətn tam sətirlərlə «…» ilə qısalır', (
      tester,
    ) async {
      // Test şrifti enlidir (hər simvol 1 em): 800 × 600-də, 1.3-də mətn
      // dialoqa sığmır, amma bir neçə tam sətrə yer qalır.
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpSettings(tester);
      await openRow(tester, 'Progresi sıfırla');
      expect(tester.takeException(), isNull);

      final body = find.textContaining('Yığılmış');
      expect(tester.widget<Text>(body).overflow, TextOverflow.ellipsis);
      expect(
        tester.renderObject<RenderParagraph>(body).didExceedMaxLines,
        isTrue,
      );
      // Mətn sətrin ortasından kəsilmir: qutusu düymələrdən 20 dp yuxarıda
      // bitir (maketin 14 + 6 dp-si).
      final buttonsTop = tester.getRect(
        find.widgetWithText(TextButton, 'Ləğv et'),
      ).top;
      expect(
        tester.getRect(body).bottom,
        lessThanOrEqualTo(buttonsTop - 20 + 0.01),
      );
    });

    testWidgets('portretdə mətn qısalmır', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 640);
      addTearDown(tester.view.reset);
      await pumpSettings(tester);
      await openRow(tester, 'Progresi sıfırla');

      final body = find.textContaining('Yığılmış');
      final paragraph = tester.renderObject<RenderParagraph>(body);
      expect(paragraph.didExceedMaxLines, isFalse);
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
