import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pages/alphabet_page.dart';

void main() {
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
