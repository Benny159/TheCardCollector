import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_preview/device_preview.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

// Deine Datenbank Imports
import 'data/database/app_database.dart';
import 'data/database/database_provider.dart';
import 'data/database/database_initializer.dart';
import 'presentation/main_screen.dart'; 

// Entry point configured as asynchronous for database initialization.
void main() async {
  // Ensures Flutter widget binding is initialized before asynchronous services start.
  WidgetsFlutterBinding.ensureInitialized(); 

  bool isDesktop = !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  // 1. Initialize local database
  final database = AppDatabase();

  // Seed initial mappings if empty in the background
  final initializer = DatabaseInitializer(database);
  await initializer.seedInitialMappings();
  // Delete legacy sets according to new references
  //await initializer.cleanUpOldSets(['mcd22']);
  // -------------------------------------------------------

  runApp(
    // Wrap application in DevicePreview for desktop simulation
    DevicePreview(
      enabled: isDesktop,
      builder: (context) => ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
        ],
        child: const TcgCollectorApp(),
      ),
    ),
  );
}

class TcgCollectorApp extends StatelessWidget {
  const TcgCollectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TCG Collector',
      debugShowCheckedModeBanner: false,

      // --- Required for DevicePreview simulation ---
      locale: DevicePreview.locale(context), 
      builder: DevicePreview.appBuilder, 
      // ---------------------------------------------

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}