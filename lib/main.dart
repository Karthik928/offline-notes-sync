import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:offline_notes_sync/features/notes/data/services/sync_service.dart';

import 'features/notes/data/services/hive_service.dart';
import 'features/notes/presentation/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveService.init();
  final syncService = SyncService.instance;

  await syncService.startListening();
  await SyncService.instance.sync();

  runApp(const ProviderScope(child: OfflineNotesApp()));
}

class OfflineNotesApp extends StatelessWidget {
  const OfflineNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Offline Notes',
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF7F8FF),
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
        cardTheme: CardThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      ),
      home: const HomeScreen(),
    );
  }
}
