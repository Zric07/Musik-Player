import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_text.dart';

class PlaylistNameDialog extends StatefulWidget {
  final String title;
  final String confirmLabel;
  final String initialValue;

  const PlaylistNameDialog({
    super.key,
    required this.title,
    required this.confirmLabel,
    this.initialValue = '',
  });

  @override
  State<PlaylistNameDialog> createState() => _PlaylistNameDialogState();
}

class _PlaylistNameDialogState extends State<PlaylistNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void initState() {
    super.initState();
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(context, _controller.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        style: AppText.itemTitle.copyWith(fontWeight: FontWeight.w500),
        cursorColor: AppColors.accent,
        decoration: const InputDecoration(hintText: 'Name der Playlist'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}
