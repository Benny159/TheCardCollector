import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_preview/device_preview.dart'; // <--- HIER: Das Paket importieren

// Deine Datenbank Imports
import 'data/database/app_database.dart';
import 'data/database/database_provider.dart';

// Dein Screen Import
import 'presentation/main_screen.dart'; // <--- HIER: MainScreen Importieren

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
void main() {
  // 1. Datenbank initialisieren
  final database = AppDatabase();

  runApp(
    // 2. Die ganze App wird in "DevicePreview" eingepackt
    DevicePreview(
      enabled: true, // Auf 'false' setzen, wenn du es deaktivieren willst (z.B. für Release)
      
      // Hier drin bauen wir unsere App wie gewohnt
      builder: (context) => ProviderScope(
        // Wir geben die Datenbank an Riverpod weiter
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
      // Das sagt der App: "Benutze nicht die Windows-Größe, sondern die Handy-Größe"
      useInheritedMediaQuery: true, 
      // Das stellt die Sprache/Region des simulierten Handys ein
      locale: DevicePreview.locale(context), 
      // Das baut den Rahmen (iPhone, Android) um die App herum
      builder: DevicePreview.appBuilder, 
      // ----------------------------------

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
        useMaterial3: true,
      ),
      navigatorObservers: [routeObserver],
      home: const MainScreen(),
    );
  }
}