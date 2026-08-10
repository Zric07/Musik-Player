class AudioFormats {
  AudioFormats._();

  static const List<String> extensions = [
    '.mp3',
    '.wav',
    '.m4a',
    '.aac',
    '.flac',
    '.ogg',
    '.opus',
    '.wma',
  ];

  static bool supports(String extension) {
    return extensions.contains(extension.toLowerCase());
  }

  static String label(String extension) {
    final clean = extension.toLowerCase().replaceAll('.', '');
    return clean.toUpperCase();
  }
}
