import '../models/song.dart';

enum VoiceAction { play, resume, pause, next, previous, unknown }

class VoiceCommand {
  final VoiceAction action;
  final String query;

  const VoiceCommand(this.action, {this.query = ''});
}

class VoiceCommands {
  VoiceCommands._();

  static const List<String> _playPrefixes = [
    'spiele',
    'spiel',
    'starte',
    'start',
    'play',
    'hoere',
  ];

  static const List<String> _fillers = [
    'lied',
    'das lied',
    'den song',
    'song',
    'titel',
    'den titel',
    'mir',
    'bitte',
  ];

  static const List<String> _resumeWords = [
    'weiterspielen',
    'weiter spielen',
    'weitermachen',
    'weiter machen',
    'fortsetzen',
    'fortfahren',
    'abspielen',
    'wiedergabe',
  ];

  static const List<String> _pauseWords = [
    'pause',
    'pausier',
    'stopp',
    'stop',
    'anhalten',
    'halt an',
    'ruhe',
  ];

  static const List<String> _nextWords = [
    'naechst',
    'weiter',
    'ueberspring',
    'skip',
    'vorwaerts',
    'vor',
  ];

  static const List<String> _previousWords = [
    'zurueck',
    'vorherig',
    'davor',
    'letztes',
    'nochmal',
  ];

  static const List<String> _resumeAfterPrefix = [
    'weiter',
    'weiterspielen',
    'wieder',
    'los',
    'ab',
  ];

  static VoiceCommand parse(String spoken) {
    final text = normalize(spoken);
    if (text.isEmpty) return const VoiceCommand(VoiceAction.unknown);

    if (_hasPlayPrefix(text)) {
      final query = _queryAfterPrefix(text);

      if (query.isEmpty || _resumeAfterPrefix.contains(query)) {
        return const VoiceCommand(VoiceAction.resume);
      }

      return VoiceCommand(VoiceAction.play, query: query);
    }

    final control = _controlOf(text);
    if (control != VoiceAction.unknown) return VoiceCommand(control);

    return const VoiceCommand(VoiceAction.unknown);
  }

  static bool _hasPlayPrefix(String text) {
    for (final prefix in _playPrefixes) {
      if (text == prefix || text.startsWith('$prefix ')) return true;
    }
    return false;
  }

  static VoiceAction _controlOf(String text) {
    if (_hasWord(text, _resumeWords)) return VoiceAction.resume;
    if (_hasWord(text, _pauseWords)) return VoiceAction.pause;
    if (_hasWord(text, _previousWords)) return VoiceAction.previous;
    if (_hasWord(text, _nextWords)) return VoiceAction.next;
    return VoiceAction.unknown;
  }

  static bool _hasWord(String text, List<String> words) {
    for (final word in words) {
      if (text == word) return true;
      if (text.contains(' $word')) return true;
      if (text.startsWith(word)) return true;
    }
    return false;
  }

  static String _queryAfterPrefix(String text) {
    for (final prefix in _playPrefixes) {
      if (!text.startsWith('$prefix ') && text != prefix) continue;

      var rest = text == prefix ? '' : text.substring(prefix.length + 1);
      rest = _stripEnd(rest, ' ab');
      rest = _stripEnd(rest, ' abspielen');
      rest = _stripEnd(rest, ' an');

      for (final filler in _fillers) {
        if (rest == filler) rest = '';
        if (rest.startsWith('$filler ')) {
          rest = rest.substring(filler.length + 1);
        }
      }

      return rest.trim();
    }
    return '';
  }

  static String _stripEnd(String text, String suffix) {
    if (!text.endsWith(suffix)) return text;
    return text.substring(0, text.length - suffix.length).trim();
  }

  static Song? findSong(List<Song> songs, String query) {
    if (songs.isEmpty) return null;

    final needle = normalize(query);
    if (needle.isEmpty) return songs.first;

    var best = songs.first;
    var bestScore = -1.0;

    for (final song in songs) {
      final score = _score(song, needle);
      if (score > bestScore) {
        bestScore = score;
        best = song;
      }
    }

    return best;
  }

  static double _score(Song song, String needle) {
    final title = normalize(song.title);
    final artist = normalize(song.artist);

    if (title == needle) return 1;
    if (title.startsWith(needle)) return 0.96;
    if (title.contains(needle)) return 0.92;
    if (title.isNotEmpty && needle.contains(title)) return 0.88;
    if (artist == needle) return 0.84;
    if (artist.isNotEmpty && artist.contains(needle)) return 0.80;

    final byTitle = similarity(title, needle);
    final byArtist = similarity(artist, needle) * 0.8;
    final byWords = _wordShare(needle, '$title $artist') * 0.75;

    var score = byTitle;
    if (byArtist > score) score = byArtist;
    if (byWords > score) score = byWords;

    return score;
  }

  static double _wordShare(String needle, String haystack) {
    final words = needle.split(' ').where((word) => word.length > 2).toList();
    if (words.isEmpty) return 0;

    var hits = 0;
    for (final word in words) {
      if (haystack.contains(word)) hits++;
    }

    return hits / words.length;
  }

  static double similarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0;
    if (a == b) return 1;

    final left = _bigrams(a);
    final right = _bigrams(b);
    if (left.isEmpty || right.isEmpty) return 0;

    final rest = List.of(right);
    var hits = 0;

    for (final pair in left) {
      final index = rest.indexOf(pair);
      if (index < 0) continue;
      rest.removeAt(index);
      hits++;
    }

    return 2 * hits / (left.length + right.length);
  }

  static List<String> _bigrams(String value) {
    final pairs = <String>[];
    for (var i = 0; i < value.length - 1; i++) {
      final pair = value.substring(i, i + 2);
      if (pair.trim().length == 2) pairs.add(pair);
    }
    return pairs;
  }

  static String normalize(String value) {
    final buffer = StringBuffer();

    for (final rune in value.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      final replacement = _letters[char];

      if (replacement != null) {
        buffer.write(replacement);
      } else if (_isPlain(rune)) {
        buffer.write(char);
      } else {
        buffer.write(' ');
      }
    }

    return buffer.toString().split(' ').where((w) => w.isNotEmpty).join(' ');
  }

  static bool _isPlain(int rune) {
    final isDigit = rune >= 0x30 && rune <= 0x39;
    final isLetter = rune >= 0x61 && rune <= 0x7A;
    return isDigit || isLetter;
  }

  static const Map<String, String> _letters = {
    'ä': 'ae',
    'ö': 'oe',
    'ü': 'ue',
    'ß': 'ss',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'í': 'i',
    'ì': 'i',
    'ó': 'o',
    'ò': 'o',
    'ú': 'u',
    'ù': 'u',
    'ñ': 'n',
    'ç': 'c',
  };
}
