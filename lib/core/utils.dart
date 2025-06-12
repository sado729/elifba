import 'config.dart';

String normalizeFileName(String input) {
  return AppConfig.normalizeFileName(input);
}

String getFirstLetter(String input) {
  final normalized = normalizeFileName(input);
  return normalized.isNotEmpty ? normalized[0] : '';
}
