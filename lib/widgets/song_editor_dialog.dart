import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_spacing.dart';
import '../core/app_text.dart';
import '../data/song_editor.dart';
import '../models/song.dart';
import '../services/image_picker_service.dart';
import 'cover_art.dart';

Future<bool> showSongEditor(BuildContext context, Song song) async {
  final saved = await showDialog<bool>(
    context: context,
    builder: (_) => _SongEditorDialog(song: song),
  );
  return saved ?? false;
}

class _SongEditorDialog extends StatefulWidget {
  final Song song;

  const _SongEditorDialog({super.key, required this.song});

  @override
  State<_SongEditorDialog> createState() => _SongEditorDialogState();
}

class _SongEditorDialogState extends State<_SongEditorDialog> {
  late final _title = TextEditingController(text: widget.song.title);
  late final _artist = TextEditingController(text: widget.song.artist);
  late final _album = TextEditingController(text: widget.song.album);
  late final _lyrics = TextEditingController(text: widget.song.lyrics);

  PickedImage? _cover;
  bool _renameFile = false;
  bool _saving = false;
  String _error = '';

  @override
  void dispose() {
    _title.dispose();
    _artist.dispose();
    _album.dispose();
    _lyrics.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    final picked = await ImagePickerService.pick();
    if (picked == null || !mounted) return;
    setState(() => _cover = picked);
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Der Titel darf nicht leer sein.');
      return;
    }

    setState(() {
      _saving = true;
      _error = '';
    });

    final ok = await SongEditor.saveTags(
      song: widget.song,
      title: title,
      artist: _artist.text.trim(),
      album: _album.text.trim(),
      lyrics: _lyrics.text.trim(),
      cover: _cover?.bytes,
      coverMime: _cover?.mime,
    );

    if (!mounted) return;

    if (!ok) {
      setState(() {
        _saving = false;
        _error = 'Die Datei konnte nicht geschrieben werden.';
      });
      return;
    }

    if (_renameFile) {
      await SongEditor.renameFile(widget.song, title);
    }

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final tagsPossible = SongEditor.supportsTags(widget.song);

    return AlertDialog(
      backgroundColor: AppColors.surfaceHi,
      title: const Text('Titel bearbeiten'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!tagsPossible)
                const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    'Tags lassen sich nur in MP3-Dateien schreiben. '
                    'Umbenennen geht trotzdem.',
                    style: AppText.itemSubtitle,
                  ),
                ),
              Row(
                children: [
                  _buildCover(),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickCover,
                      icon: const Icon(Icons.image_outlined, size: 18),
                      label: const Text('Cover wählen'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildField(_title, 'Titel'),
              _buildField(_artist, 'Interpret'),
              _buildField(_album, 'Album'),
              _buildField(_lyrics, 'Songtext', lines: 5),
              CheckboxListTile(
                value: _renameFile,
                onChanged: (value) =>
                    setState(() => _renameFile = value ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppColors.accent,
                title: const Text(
                  'Datei auch umbenennen',
                  style: AppText.itemSubtitle,
                ),
              ),
              if (_error.isNotEmpty)
                Text(
                  _error,
                  style: AppText.itemSubtitle.copyWith(
                    color: AppColors.danger,
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Abbrechen'),
        ),
        TextButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Speichert …' : 'Speichern'),
        ),
      ],
    );
  }

  Widget _buildCover() {
    final picked = _cover;
    if (picked == null) return CoverArt(song: widget.song, size: 64);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Image.memory(
        Uint8List.fromList(picked.bytes),
        width: 64,
        height: 64,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label, {
    int lines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextField(
        controller: controller,
        maxLines: lines,
        style: AppText.itemTitle,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
