import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_colors.dart';
import '../core/responsive.dart';
import '../models/song.dart';
import '../services/media_controls.dart';
import '../services/song_service.dart';
import '../widgets/app_navigation.dart';
import '../widgets/mini_player.dart';
import 'cardrive_page.dart';
import 'home_page.dart';
import 'library_page.dart';
import 'player_page.dart';
import 'search_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _songService = SongService();

  int _tab = 0;


  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onPause: _songService.persist,
      onDetach: _songService.persist,
      onExitRequested: () async {
        await _songService.persist();
        await MediaControls.clear();
        return AppExitResponse.exit;
      },
    );
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    super.dispose();
  }

  static const _navItems = [
    NavItem(
      label: 'Start',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    NavItem(
      label: 'Suche',
      icon: Icons.search_rounded,
      activeIcon: Icons.search_rounded,
    ),
    NavItem(
      label: 'Bibliothek',
      icon: Icons.library_music_outlined,
      activeIcon: Icons.library_music_rounded,
    ),
    NavItem(
      label: 'Cardrive',
      icon: Icons.directions_car_outlined,
      activeIcon: Icons.directions_car_rounded,
    ),
  ];

  void _openPlayer() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.62),
      constraints: const BoxConstraints(maxWidth: 620),
      builder: (_) => const PlayerPage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final desktop = Responsive.isDesktop(context);

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                if (desktop)
                  AppNavRail(
                    index: _tab,
                    items: _navItems,
                    onChanged: (i) => setState(() => _tab = i),
                  ),
                Expanded(
                  child: IndexedStack(
                    index: _tab,
                    children: [
                      const HomePage(),
                      const SearchPage(),
                      const LibraryPage(),
                      CarDrivePage(active: _tab == 3),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildMiniPlayer(),
          if (!desktop)
            AppBottomNav(
              index: _tab,
              items: _navItems,
              onChanged: (i) => setState(() => _tab = i),
            ),
        ],
      ),
      backgroundColor: AppColors.bg,
    );
  }

  Widget _buildMiniPlayer() {
    return StreamBuilder<List<Song>>(
      stream: _songService.queueStream,
      initialData: _songService.queue,
      builder: (context, _) {
        final song = _songService.current;
        if (song == null) return const SizedBox.shrink();

        return StreamBuilder<bool>(
          stream: _songService.playingStream,
          initialData: _songService.isPlaying,
          builder: (context, playingSnapshot) {
            final isPlaying = playingSnapshot.data ?? false;

            return MiniPlayer(
              song: song,
              isPlaying: isPlaying,
              hasNext: _songService.hasNext,
              hasPrev: _songService.hasPrev,
              onOpen: _openPlayer,
              onNext: _songService.next,
              onPrev: _songService.prev,
              onToggle: () =>
                  isPlaying ? _songService.pause() : _songService.resume(),
            );
          },
        );
      },
    );
  }
}
