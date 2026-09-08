import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/progress.dart';
import 'core/settings.dart';
import 'pages/alphabet_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Android 16 (API 36) forces edge-to-edge and cannot be opted out of. Turn it on
  // everywhere so older Android versions render the same way, and keep the system
  // bar icons light — every page in this app sits on a dark purple background.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'NotoSans',
      ),
      home: const AlphabetPage(),
    );
  }
}
