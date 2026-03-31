import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_preview/device_preview.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

// Deine Datenbank Imports
import 'data/database/app_database.dart';
import 'data/database/database_provider.dart';
import 'data/database/database_initializer.dart'; // <--- NEU: Der Import für den Initializer

// Dein Screen Import
import 'presentation/main_screen.dart'; 

// --- NEU: Die main() Methode muss jetzt "async" sein ---
void main() async {
  // Das ist zwingend nötig, wenn man vor dem App-Start auf die Datenbank zugreifen will
  WidgetsFlutterBinding.ensureInitialized(); 

  bool isDesktop = !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  // 1. Datenbank initialisieren
  final database = AppDatabase();

  // --- NEU: Mapping-Tabelle füllen, falls sie leer ist ---
  // Das passiert unsichtbar im Hintergrund. Wenn die Tabelle schon voll ist,
  // bricht die Funktion (dank unserer Prüfung) sofort ab und kostet keine Zeit.
  final initializer = DatabaseInitializer(database);
  await initializer.seedInitialMappings();
  // -------------------------------------------------------

  runApp(
    // 2. Die ganze App wird in "DevicePreview" eingepackt
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

      // --- WICHTIG FÜR DEVICE PREVIEW ---
      useInheritedMediaQuery: true, 
      locale: DevicePreview.locale(context), 
      builder: DevicePreview.appBuilder, 
      // ----------------------------------

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}