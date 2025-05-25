String normalizeFileName(String input) {
  return input
      .toLowerCase()
      .replaceAll(' ', '_')
      .replaceAll('ı', 'i')
      .replaceAll('ə', 'e')
      .replaceAll('ö', 'o')
      .replaceAll('ü', 'u')
      .replaceAll('ç', 'c')
      .replaceAll('ş', 's')
      .replaceAll('ğ', 'g')
      .replaceAll('ə', 'e')
      .replaceAll('â', 'a')
      .replaceAll('î', 'i')
      .replaceAll('ü', 'u')
      .replaceAll('ö', 'o')
      .replaceAll('ş', 's')
      .replaceAll('ç', 'c')
      .replaceAll('ğ', 'g')
      .replaceAll('ı', 'i')
      .replaceAll('İ', 'i')
      .replaceAll('Ə', 'e')
      .replaceAll('Ç', 'c')
      .replaceAll('Ş', 's')
      .replaceAll('Ö', 'o')
      .replaceAll('Ü', 'u')
      .replaceAll('Ğ', 'g');
}

String getFirstLetter(String input) {
  final normalized = normalizeFileName(input);
  return normalized.isNotEmpty ? normalized[0] : '';
}
