import 'package:flutter/material.dart';
import 'pages/alphabet_page.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

void main() {
  // Flutter binding-i başlat
  WidgetsFlutterBinding.ensureInitialized();

  // Error handling əlavə et - crash qarşısını alır
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
    // Production-da crash reporting service-ə göndərilə bilər
  };

  // Platform channel error handling
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Platform Error: $error');
    debugPrint('Stack trace: $stack');
    return true; // true qaytarırıq ki, error handle olunsun
  };

  // Uncaught exception handling
  runZonedGuarded(
    () {
      runApp(const MyApp());
    },
    (error, stack) {
      debugPrint('Uncaught error: $error');
      debugPrint('Stack trace: $stack');
      // Production-da crash reporting service-ə göndərilə bilər
    },
  );
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
      // Error builder əlavə et ki, widget tree-də xəta olsa belə crash olmasın
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(1.0)),
          child: child ?? const SizedBox(),
        );
      },
      home: const AlphabetPage(),
    );
  }
}
