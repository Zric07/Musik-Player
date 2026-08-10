import 'package:flutter/material.dart';

import 'core/app_theme.dart';
import 'pages/bootstrap_page.dart';
import 'services/media_controls.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MediaControls.init();
  runApp(const MusicApp());
}

class MusicApp extends StatelessWidget {
  const MusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Musik',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const BootstrapPage(),
    );
  }
}
