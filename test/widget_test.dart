import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miply/core/app_colors.dart';
import 'package:miply/core/formatting.dart';
import 'package:miply/models/playlist.dart';
import 'package:miply/models/song.dart';
import 'package:miply/widgets/empty_state.dart';

void main() {
  group('formatDuration', () {
    test('formatiert Sekunden zweistellig', () {
      expect(formatDuration(const Duration(seconds: 7)), '0:07');
      expect(formatDuration(const Duration(seconds: 187)), '3:07');
      expect(formatDuration(Duration.zero), '0:00');
    });
  });

  group('songCountLabel', () {
    test('nutzt Einzahl bei genau einem Titel', () {
      expect(songCountLabel(1), '1 Titel');
      expect(songCountLabel(0), '0 Titel');
      expect(songCountLabel(12), '12 Titel');
    });
  });

  group('AppColors.forKey', () {
    test('ist stabil fuer denselben Schluessel', () {
      expect(AppColors.forKey('song-a'), AppColors.forKey('song-a'));
    });

    test('faellt bei leerem Schluessel auf die erste Farbe zurueck', () {
      expect(AppColors.forKey(''), AppColors.covers.first);
    });
  });

  group('Models', () {
    test('Song ohne Cover meldet hasCover false', () {
      const song = Song(id: '1', title: 'T', artist: 'A');
      expect(song.hasCover, isFalse);
      expect(song.album, '');
    });

    test('Playlist zaehlt Titel und erkennt Cover', () {
      final playlist = Playlist(
        id: 'p1',
        title: 'Mix',
        songs: const ['a', 'b'],
        cover: '/tmp/x.png',
      );

      expect(playlist.songCount, 2);
      expect(playlist.hasCover, isTrue);
    });
  });

  testWidgets('EmptyState zeigt Titel und Untertitel', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.search_off_rounded,
            title: 'Nichts gefunden',
            subtitle: 'Versuche es anders.',
          ),
        ),
      ),
    );

    expect(find.text('Nichts gefunden'), findsOneWidget);
    expect(find.text('Versuche es anders.'), findsOneWidget);
  });
}
