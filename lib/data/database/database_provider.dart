import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_database.dart';

/// Global provider for the singleton [AppDatabase] instance.
///
/// Grants access to the local Drift SQLite database connection across all layers.
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});