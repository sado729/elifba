// "Əlifba" loqosu: Dart-dakı kontur brend fayllarından ayrılmasın.
//
// Loqo iki yerdə yaşayır — `lib/widgets/elifba_wordmark.dart` (tətbiq) və
// `branding/wordmark/*.svg` (dizayn, mağaza, sənədlər). Biri dəyişib o biri
// unudulsa, tətbiqdəki loqo brenddən səssizcə ayrılardı.
import 'dart:io';

import 'package:elifba/widgets/elifba_wordmark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// SVG-dəki ilk `<path d="...">`.
String _svgPath(String svg) =>
    RegExp(r'<path [^>]*\bd="([^"]+)"').firstMatch(svg)!.group(1)!;

/// SVG-dəki `fill` rəngləri, sənəddəki sırası ilə (mürəkkəb, halqa?, günəş).
List<Color> _svgFills(String svg) => [
  for (final m in RegExp(r'fill="#([0-9A-Fa-f]{6})"').allMatches(svg))
    Color(int.parse('FF${m.group(1)}', radix: 16)),
];

/// Kök `viewBox`-un eni və hündürlüyü.
Size _svgViewBox(String svg) {
  final m = RegExp(r'viewBox="0 0 ([\d.]+) ([\d.]+)"').firstMatch(svg)!;
  return Size(double.parse(m.group(1)!), double.parse(m.group(2)!));
}

/// Dairələr sənəddəki sırası ilə: (mərkəz, radius).
List<(Offset, double)> _svgCircles(String svg) => [
  for (final m in RegExp(
    r'<circle cx="([\d.]+)" cy="([\d.]+)" r="([\d.]+)"',
  ).allMatches(svg))
    (
      Offset(double.parse(m.group(1)!), double.parse(m.group(2)!)),
      double.parse(m.group(3)!),
    ),
];

void main() {
  const variants = {
    'light': ElifbaWordmarkColors.light,
    'lavender': ElifbaWordmarkColors.lavender,
    'mono': ElifbaWordmarkColors.mono,
    'dark': ElifbaWordmarkColors.dark,
  };

  for (final entry in variants.entries) {
    test('${entry.key} variantı branding SVG-si ilə eynidir', () {
      final file = File('branding/wordmark/elifba_wordmark_${entry.key}.svg');
      expect(file.existsSync(), isTrue, reason: file.path);
      final svg = file.readAsStringSync();

      expect(_svgViewBox(svg), kElifbaWordmarkViewBox);
      expect(_svgPath(svg), kElifbaWordmarkPath);
      final c = entry.value;
      expect(_svgFills(svg), [c.ink, if (c.ring != null) c.ring!, c.sun]);
      // Günəş brendin əsas detalıdır: yeri və ölçüsü də eyni qalmalıdır.
      expect(_svgCircles(svg), [
        if (c.ring != null)
          (kElifbaWordmarkSunCenter, kElifbaWordmarkRingRadius),
        (kElifbaWordmarkSunCenter, kElifbaWordmarkSunRadius),
      ]);
    });
  }

  testWidgets('loqo etiketlə görünür və nisbətini saxlayır', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: ElifbaWordmark(height: 50)),
      ),
    );

    expect(find.bySemanticsLabel('Əlifba'), findsOneWidget);
    final size = tester.getSize(find.byType(ElifbaWordmark));
    expect(size.height, 50);
    expect(size.width, closeTo(50 * kElifbaWordmarkViewBox.aspectRatio, 0.01));
    expect(tester.takeException(), isNull);
  });
}
