import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../core/app_spacing.dart';
import '../core/app_text.dart';
import '../data/favorite_store.dart';
import '../data/settings_store.dart';
import '../services/permission_service.dart';
import '../services/song_service.dart';
import 'app_shell.dart';

class BootstrapPage extends StatefulWidget {
  const BootstrapPage({super.key});

  @override
  State<BootstrapPage> createState() => _BootstrapPageState();
}

class _BootstrapPageState extends State<BootstrapPage> {
  late Future<void> _startup;

  int _found = 0;

  @override
  void initState() {
    super.initState();
    _startup = _prepare();
  }

  void _onProgress(int count) {
    if (!mounted) return;
    if (count == _found) return;
    if (count % 25 != 0) return;

    setState(() => _found = count);
  }

  Future<void> _prepare() async {
    final granted = await LibraryPermission.ensure();
    if (!granted) {
      throw const _PermissionDenied();
    }
    await LibraryPermission.ensureNotifications();
    await SettingsStore.load();
    await FavoriteStore.load();

    await SongService().applySettings();

    final songs = await SongService().refresh(onProgress: _onProgress);
    await SongService().restore(songs);
  }

  void _retry() {
    setState(() {
      _startup = _prepare();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _startup,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _Splash(found: _found);
        }

        if (snapshot.hasError) {
          final denied = snapshot.error is _PermissionDenied;
          return _Failure(
            title: denied ? 'Zugriff nicht erlaubt' : 'Start fehlgeschlagen',
            message: denied
                ? 'Ohne Zugriff auf deine Musikdateien kann die App nichts '
                      'anzeigen.'
                : 'Die Bibliothek konnte nicht gelesen werden.',
            onRetry: _retry,
            onSettings: denied ? LibraryPermission.openSettings : null,
          );
        }

        return const AppShell();
      },
    );
  }
}

class _PermissionDenied implements Exception {
  const _PermissionDenied();
}

class _Splash extends StatelessWidget {
  final int found;

  const _Splash({super.key, this.found = 0});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent,
              ),
              child: const Icon(
                Icons.graphic_eq_rounded,
                size: 32,
                color: AppColors.onAccent,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text('Miply', style: AppText.section),
            const SizedBox(height: AppSpacing.sm),
            Text(
              found == 0
                  ? 'Bibliothek wird gelesen'
                  : '$found Titel gefunden',
              style: AppText.itemSubtitle,
            ),
            const SizedBox(height: AppSpacing.xl),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Failure extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onSettings;

  const _Failure({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
    this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                  ),
                  child: const Icon(
                    Icons.folder_off_outlined,
                    size: 30,
                    color: AppColors.danger,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(title, style: AppText.section, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.sm),
                Text(message, style: AppText.body, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Erneut versuchen'),
                ),
                if (onSettings != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: onSettings,
                    child: const Text('Einstellungen öffnen'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
