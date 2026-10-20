import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/progress.dart';
import 'core/settings.dart';
import 'pages/alphabet_page.dart';
import 'theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Android 16 (API 36) forces edge-to-edge and cannot be opted out of. Turn it on
  // everywhere so older Android versions render the same way. Every page now sits
  // on a light sky, so the system bar icons are dark (`kElifbaSystemUiStyle`);
  // `AppBarTheme` and the AppBar-less pages repeat the same style.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(kElifbaSystemUiStyle);
  // Saxlanmış progres ilk kadrdan ƏVVƏL oxunur: əks halda səhifələr 0 ulduzla
  // qurulur, yaddaş gələndə isə ulduzlar birdən "tullanır".
  await ProgressStore.instance.load();
  // Ayarlar da ilk kadrdan əvvəl oxunur: əks halda səs söndürülmüş olsa belə
  // açılışdakı ilk səs (səhifə çevirmə) ayar gəlməmişdən çalına bilər.
  // Hər iki `load()` eyni `SharedPreferences` nüsxəsini alır, ikincisi ucuzdur.
  await AppSettings.instance.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Əlifba',
      debugShowCheckedModeBanner: false,
      theme: ElifbaTheme.light(),
      // Böyük sistem şrifti 48–64 dp-lik pill-ləri daşırmasın: mətn ən çox
      // 1.3 dəfə böyüyür.
      builder: (context, child) =>
          MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3, child: child!),
      home: const AlphabetPage(),
    );
  }
}
