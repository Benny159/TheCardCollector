import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_database.dart';

// Das ist der "Hahn", aus dem die Datenbank fließt.
// Wir nutzen Riverpod, damit wir überall in der App einfach 
// "ref.watch(databaseProvider)" sagen können.
final databaseProvider = Provider<AppDatabase>((ref) {
  // Erstellt die Datenbank-Verbindung
  return AppDatabase();
});