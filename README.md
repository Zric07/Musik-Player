# Musik

Lokaler Musikplayer. Kein Server, kein Go – alles läuft in Flutter,
in einem einzigen Prozess.

## Loslegen

```
flutter pub get
dart run sqflite_common_ffi_web:setup
flutter run -d <android-geraet>
flutter run -d windows
flutter run -d chrome
```

Der zweite Befehl ist einmalig und legt `sqlite3.wasm` und `sqflite_sw.js`
im `web`-Ordner ab. Ohne diese Dateien startet nur die Browser-Fassung nicht.

## Wo die Musik herkommt

Beim Start werden diese Ordner rekursiv nach `.mp3` durchsucht:

| Android | Windows |
|---|---|
| `/storage/emulated/0/Music` | `%USERPROFILE%\Music` |
| `/storage/emulated/0/Download` | `%USERPROFILE%\Downloads` |
| `/storage/emulated/0/Documents` | `%USERPROFILE%\Documents` |
| `/storage/emulated/0/Podcasts` | `%USERPROFILE%\Desktop` |

Titel, Interpret, Album und das eingebettete Cover kommen aus den ID3-Tags.
Der Parser liegt in `lib/data/id3_parser.dart` und ist selbst geschrieben –
er versteht ID3v2.2, v2.3, v2.4 (Latin-1, UTF-8, UTF-16) und fällt auf
ID3v1 zurück. Cover werden einmalig extrahiert und im App-Ordner abgelegt.

Auf Android fragt die App beim ersten Start `READ_MEDIA_AUDIO` an
(auf Android 12 und älter `READ_EXTERNAL_STORAGE`).

## Wo die Daten liegen

Auf Android und Windows im App-Support-Verzeichnis unter `MusikApp/`:

- `musik.db` – Playlists (SQLite)
- `artwork/` – aus MP3s extrahierte Cover

Im Browser liegt dieselbe Datenbank in IndexedDB. Playlist-Cover werden in
allen Fällen als BLOB in der Datenbank gespeichert, nicht als lose Datei.

## Aufbau

```
lib/
  core/      Farben, Schrift, Abstände, Theme, Breakpoints
  data/      ID3-Parser, Datei-Scanner, SQLite, Pfade
  models/    Song, Playlist
  services/  Wiedergabe, Playlists, Cover, Farbanalyse, Berechtigungen
  pages/     Bildschirme
  widgets/   wiederverwendbare Bausteine
```

## Im Browser anschauen

```
flutter run -d chrome
```

Läuft ohne Visual Studio und ohne Android-SDK. Die App startet leer – im
Browser gibt es kein Dateisystem, das sich durchsuchen ließe. Stattdessen
wählst du deine Musik über den Knopf oben rechts selbst aus. Die Dateien
werden dann genauso behandelt wie auf dem Handy: echte ID3-Tags, echte
Cover, echte Wiedergabe.

| | Android / Windows | Web |
|---|---|---|
| Songs | Ordner werden gescannt | von Hand ausgewählt |
| Tags und Cover | ID3 aus der Datei | ID3 aus der Datei |
| Wiedergabe | Dateipfad | Blob-URL im Browser |
| Playlists | SQLite | SQLite über WASM, bleibt erhalten |

Die Umschaltung passiert über bedingte Importe (`library.dart`,
`playlist_store.dart`, `cover_source.dart`, `permission_service.dart`).
Alle Seiten und Widgets sind auf allen Plattformen identisch.

## Tests

```
flutter test
```

`test/id3_reader_test.dart` baut ID3-Tags byteweise zusammen, schreibt sie in
temporäre Dateien und liest sie zurück – inklusive UTF-16, Cover-Extraktion,
ID3v1-Rückfall und absichtlich kaputtem Tag.

## Unterschied zur Variante mit Go-Backend

Gleiche Oberfläche, gleiche Bedienung. Statt HTTP gegen einen lokalen
Go-Server laufen Dateisuche und Playlists direkt in Dart. Damit entfällt
das Mitliefern und Starten einer Binary komplett.
