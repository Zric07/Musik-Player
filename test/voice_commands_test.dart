import 'package:flutter_test/flutter_test.dart';
import 'package:miply/models/song.dart';
import 'package:miply/services/voice_commands.dart';

void main() {
  group('parse', () {
    test('erkennt einen Titel mit ab', () {
      final command = VoiceCommands.parse('Spiele Bohemian Rhapsody ab');
      expect(command.action, VoiceAction.play);
      expect(command.query, 'bohemian rhapsody');
    });

    test('entfernt Füllwörter', () {
      final command = VoiceCommands.parse('Starte das Lied Africa');
      expect(command.action, VoiceAction.play);
      expect(command.query, 'africa');
    });

    test('erkennt Pause', () {
      expect(VoiceCommands.parse('Pause').action, VoiceAction.pause);
      expect(VoiceCommands.parse('pausiere bitte').action, VoiceAction.pause);
      expect(VoiceCommands.parse('Stopp').action, VoiceAction.pause);
    });

    test('erkennt weiter als nächsten Titel', () {
      expect(VoiceCommands.parse('Weiter').action, VoiceAction.next);
      expect(VoiceCommands.parse('nächster Titel').action, VoiceAction.next);
    });

    test('erkennt zurück', () {
      expect(VoiceCommands.parse('Zurück').action, VoiceAction.previous);
      expect(
        VoiceCommands.parse('vorheriger Titel').action,
        VoiceAction.previous,
      );
    });

    test('unterscheidet weiterspielen von weiter', () {
      expect(VoiceCommands.parse('Weiterspielen').action, VoiceAction.resume);
      expect(VoiceCommands.parse('spiele weiter').action, VoiceAction.resume);
    });

    test('kennt Unsinn nicht', () {
      expect(VoiceCommands.parse('wie ist das Wetter').action,
          VoiceAction.unknown);
    });
  });

  group('findSong', () {
    final songs = [
      const Song(id: '1', title: 'Bohemian Rhapsody', artist: 'Queen'),
      const Song(id: '2', title: 'Africa', artist: 'Toto'),
      const Song(id: '3', title: 'Über den Wolken', artist: 'Reinhard Mey'),
    ];

    test('findet exakt', () {
      expect(VoiceCommands.findSong(songs, 'africa')?.id, '2');
    });

    test('findet trotz Umlaut', () {
      expect(VoiceCommands.findSong(songs, 'ueber den wolken')?.id, '3');
    });

    test('findet über den Interpreten', () {
      expect(VoiceCommands.findSong(songs, 'queen')?.id, '1');
    });

    test('verzeiht Hörfehler', () {
      expect(VoiceCommands.findSong(songs, 'bohemien rapsodi')?.id, '1');
      expect(VoiceCommands.findSong(songs, 'afrika')?.id, '2');
    });

    test('spielt notfalls den ähnlichsten Titel', () {
      expect(VoiceCommands.findSong(songs, 'zzzz'), isNotNull);
    });

    test('gibt null ohne Musik', () {
      expect(VoiceCommands.findSong(const [], 'africa'), isNull);
    });
  });
}
