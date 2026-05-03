import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// WICHTIG: 'hide Card' verhindert Konflikte mit dem Flutter Card-Widget!
import '../../data/database/app_database.dart' hide Card; 
import '../../data/database/app_database.dart' as db_models;
import 'package:drift/drift.dart' hide Column;

import '../../data/database/database_provider.dart';
import '../../data/api/search_provider.dart'; 
import '../../domain/logic/binder_service.dart'; // Für die Live-Neuberechnung!

import '../admin/admin_dashboard_screen.dart'; 

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
            accountName: const Text("TCG Collector", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            accountEmail: const Text("Sammlung verwalten"),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.catching_pokemon, size: 40, color: Colors.red),
            ),
          ),
          
          ListTile(
            leading: const Icon(Icons.upload_file, color: Colors.blue),
            title: const Text("Backup erstellen (Export)"),
            subtitle: const Text("Sammlung als Datei speichern"),
            onTap: () => _exportData(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.file_download, color: Colors.green),
            title: const Text("Backup laden (Import)"),
            subtitle: const Text("Sammlung wiederherstellen"),
            onTap: () => _importData(context, ref),
          ),
          
          const Divider(),
          
          ListTile(
            leading: const Icon(Icons.developer_board, color: Colors.deepPurple),
            title: const Text("Dev Dashboard", style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context); 
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
            },
          ),
          
          const Spacer(),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text("Nutzerdaten löschen", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () => _confirmReset(context, ref),
          ),
          
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("App Version 1.0.0", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          const SizedBox(height: 100), // Platzhalter für die Bottom Bar
        ],
      ),
    );
  }

  // ==========================================
  // 1. EXPORT LOGIK (Jetzt 100% vollständig)
  // ==========================================
  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    try {
      final db = ref.read(databaseProvider);
      final prefs = await SharedPreferences.getInstance(); 
      
      // 1. App-Einstellungen sichern (Darkmode, Preis-Quellen etc.)
      final Map<String, dynamic> settingsData = {};
      for (String key in prefs.getKeys()) {
        settingsData[key] = prefs.get(key);
      }

      // 2. Suche ALLE Karten, an denen der Nutzer manuell etwas geändert hat!
      final editedCardsList = await (db.select(db.cards)..where((t) => 
          t.hasManualTranslations.equals(true) | 
          t.hasManualImages.equals(true) | 
          t.hasManualStats.equals(true) | 
          t.hasManualVariants.equals(true) |
          t.preferredPriceSource.isNotValue('cardmarket') // Sichert Custom-Preis Flags!
      )).get();

      // 3. Alles zusammenpacken
      final exportData = {
        'settings': settingsData,
        'editedCards': editedCardsList.map((e) => e.toJson()).toList(), // Die modifizierten Karten
        'userCards': (await db.select(db.userCards).get()).map((e) => e.toJson()).toList(),
        'binderCards': (await db.select(db.binderCards).get()).map((e) => e.toJson()).toList(),
        'binders': (await db.select(db.binders).get()).map((e) => e.toJson()).toList(),
        'customCardPrices': (await db.select(db.customCardPrices).get()).map((e) => e.toJson()).toList(),
        'portfolioHistory': (await db.select(db.portfolioHistory).get()).map((e) => e.toJson()).toList(),
        'binderHistory': (await db.select(db.binderHistory).get()).map((e) => e.toJson()).toList(), // NEU!
      };

      final jsonString = jsonEncode(exportData);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/tcg_collector_backup.json');
      await file.writeAsString(jsonString);

      final xFile = XFile(file.path);
      await Share.shareXFiles([xFile], text: 'Mein TCG Collector Backup');
      
      if (context.mounted) Navigator.pop(context); 
      
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Fehler: $e"), backgroundColor: Colors.red));
    }
  }

  // ==========================================
  // 2. IMPORT LOGIK
  // ==========================================
  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      if (result == null || result.files.single.path == null) return; 

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      if (!context.mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Backup wiederherstellen?"),
          content: const Text("Achtung: Deine aktuelle Sammlung und alle Binder werden gelöscht und durch die Daten aus dem Backup ersetzt!"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Abbrechen")),
            FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.orange), onPressed: () => Navigator.pop(ctx, true), child: const Text("Ja, überschreiben")),
          ],
        ),
      );

      if (confirm != true) return;

      // 1. App Einstellungen wiederherstellen
      final settings = data['settings'] as Map<String, dynamic>? ?? {}; 
      final prefs = await SharedPreferences.getInstance();
      for (var entry in settings.entries) {
        final val = entry.value;
        if (val is String) {
          await prefs.setString(entry.key, val);
        } else if (val is int) await prefs.setInt(entry.key, val);
        else if (val is double) await prefs.setDouble(entry.key, val);
        else if (val is bool) await prefs.setBool(entry.key, val);
      }

      // 2. Datenbank Modelle parsen (Noch ungefiltert)
      final editedCards = (data['editedCards'] as List?)?.map((e) => db_models.Card.fromJson(e)).toList() ?? [];
      final userCards = (data['userCards'] as List?)?.map((e) => UserCard.fromJson(e)).toList() ?? [];
      final binderCards = (data['binderCards'] as List?)?.map((e) => BinderCard.fromJson(e)).toList() ?? [];
      final binders = (data['binders'] as List?)?.map((e) => Binder.fromJson(e)).toList() ?? [];
      final customPrices = (data['customCardPrices'] as List?)?.map((e) => CustomCardPrice.fromJson(e)).toList() ?? [];
      final portfolioHistory = (data['portfolioHistory'] as List?)?.map((e) => PortfolioHistoryData.fromJson(e)).toList() ?? [];
      final binderHistory = (data['binderHistory'] as List?)?.map((e) => db_models.BinderHistoryData.fromJson(e)).toList() ?? [];

      final db = ref.read(databaseProvider);

      // --- NEU: DER SCHMUTZFILTER (Behebt den Foreign Key Error!) ---
      // Wir holen uns blitzschnell alle existierenden Karten-IDs aus der Datenbank
      final validCardIdsQuery = await db.customSelect('SELECT id FROM cards').get();
      final validCardIds = validCardIdsQuery.map((row) => row.read<String>('id')).toSet();

      // Wir filtern das Inventar: Nur Karten behalten, die auch wirklich noch existieren
      final safeUserCards = userCards.where((c) => validCardIds.contains(c.cardId)).toList();
      final safeCustomPrices = customPrices.where((c) => validCardIds.contains(c.cardId)).toList();
      final safeEditedCards = editedCards.where((c) => validCardIds.contains(c.id)).toList();

      // Binder-Karten reparieren (Wenn eine Karte gelöscht wurde, wird der Slot wieder leer!)
      final safeBinderCards = binderCards.map((c) {
        if (c.cardId != null && !validCardIds.contains(c.cardId)) {
          // Geisterkarte entdeckt -> Verwandle Slot in leeren Platzhalter
          return BinderCard(
            id: c.id,
            binderId: c.binderId,
            pageIndex: c.pageIndex,
            slotIndex: c.slotIndex,
            isPlaceholder: true, // Wieder leer!
            cardId: null,
            userCardId: null,
            variant: null,
          );
        }
        return c;
      }).toList();
      // -------------------------------------------------------------

      // 3. Batch Insert (Jetzt mit den SAFE-Listen!)
      await db.batch((batch) {
        batch.deleteAll(db.binderCards);
        batch.deleteAll(db.binderHistory); 
        batch.deleteAll(db.binders);       
        batch.deleteAll(db.userCards);     
        batch.deleteAll(db.customCardPrices);
        batch.deleteAll(db.portfolioHistory);

        batch.insertAllOnConflictUpdate(db.cards, safeEditedCards); // <-- safeList
        batch.insertAll(db.userCards, safeUserCards);               // <-- safeList
        batch.insertAll(db.binders, binders);     
        batch.insertAll(db.binderCards, safeBinderCards);           // <-- safeList
        batch.insertAll(db.binderHistory, binderHistory);
        batch.insertAll(db.customCardPrices, safeCustomPrices);     // <-- safeList
        batch.insertAll(db.portfolioHistory, portfolioHistory);
      });

      // 4. DER WICHTIGSTE SCHRITT FÜR DEN 900€ FIX: Alles Live neu durchrechnen!
      await BinderService(db).recalculateAllBinders();

      // 5. UI Aktualisieren
      ref.invalidate(inventoryProvider);
      ref.invalidate(portfolioHistoryProvider);
      ref.invalidate(top10CardsProvider);
      ref.invalidate(top10GainersProvider);
      ref.invalidate(top10LosersProvider);

      if (context.mounted) {
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Backup 100% erfolgreich geladen!"), backgroundColor: Colors.green));
      }

    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Fehler beim Import: $e"), backgroundColor: Colors.red));
    }
  }

  // ==========================================
  // 3. LÖSCH LOGIK
  // ==========================================
  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Alles löschen?", style: TextStyle(color: Colors.red)),
        content: const Text("Bist du sicher? Dein komplettes Inventar, alle deine Binder, Preisverläufe und angepasste Preise werden unwiderruflich gelöscht!\n\nDie heruntergeladenen Kartendaten und Sets bleiben erhalten."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Abbrechen")),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx); 
              
              final db = ref.read(databaseProvider);
              await db.delete(db.userCards).go();
              await db.delete(db.binderCards).go();
              await db.delete(db.binders).go();
              await db.delete(db.customCardPrices).go();
              await db.delete(db.portfolioHistory).go(); 

              ref.invalidate(inventoryProvider);
              ref.invalidate(portfolioHistoryProvider);
              ref.invalidate(top10CardsProvider);
              ref.invalidate(top10GainersProvider);
              ref.invalidate(top10LosersProvider);

              if (context.mounted) {
                Navigator.pop(context); 
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Nutzerdaten restlos gelöscht!"), backgroundColor: Colors.green));
              }
            },
            child: const Text("Ja, alles löschen"),
          ),
        ],
      ),
    );
  }
}