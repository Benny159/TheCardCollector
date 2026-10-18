import '../database/app_database.dart';

/// Service responsible for syncing card data and market prices from an external SQLite database.
class DatabaseSyncService {
  final AppDatabase _database;

  const DatabaseSyncService(this._database);

  /// Synchronizes API tables from the external SQLite database at [filePath].
  ///
  /// Disables foreign key checks during replacement to avoid orphaned cascades on inventory tables,
  /// then imports sets, cards, pokedex, set mappings, and current price points.
  Future<void> syncFromExternalDatabase(String filePath) async {
    try {
      // 1. Temporarily disable foreign keys so card replacement does not cascade-delete user inventory.
      await _database.customStatement('PRAGMA foreign_keys = OFF;');

      // 2. Attach external database.
      await _database.customStatement("ATTACH DATABASE '$filePath' AS pc_db;");

      // 3. Replace card catalog tables in a single transaction.
      await _database.transaction(() async {
        await _database.customStatement(
            "REPLACE INTO card_sets SELECT * FROM pc_db.card_sets;");

        await _database.customStatement('''
           REPLACE INTO cards (
             id, set_id, name, number, sort_number, image_url, name_de, artist, 
             has_normal, has_holo, has_reverse, has_w_promo, has_first_edition, 
             has_manual_images, has_manual_translations, has_manual_stats, has_manual_variants
           ) 
           SELECT 
             id, set_id, name, number, sort_number, image_url, name_de, artist, 
             has_normal, has_holo, has_reverse, has_w_promo, has_first_edition, 
             has_manual_images, has_manual_translations, has_manual_stats, has_manual_variants 
           FROM pc_db.cards;
         ''');

        await _database.customStatement(
            "REPLACE INTO pokedex SELECT * FROM pc_db.pokedex;");
        await _database.customStatement(
            "REPLACE INTO set_mappings SELECT * FROM pc_db.set_mappings;");

        // Clear and replace prices with latest external dataset.
        await _database.customStatement("DELETE FROM card_market_prices;");
        await _database.customStatement(
            "INSERT INTO card_market_prices SELECT * FROM pc_db.card_market_prices;");

        await _database.customStatement("DELETE FROM tcg_player_prices;");
        await _database.customStatement(
            "INSERT INTO tcg_player_prices SELECT * FROM pc_db.tcg_player_prices;");
      });
    } finally {
      // 4. Detach external database and re-enable foreign keys.
      try {
        await _database.customStatement("DETACH DATABASE pc_db;");
      } catch (_) {
        // Ignored if already detached
      }
      await _database.customStatement('PRAGMA foreign_keys = ON;');
    }
  }
}
