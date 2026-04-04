import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../admin/admin_dashboard_screen.dart';
import '../../data/database/database_provider.dart';
import '../../data/api/search_provider.dart'; // Für den Provider-Refresh

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
            accountEmail: const Text("Tester-Modus"),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.catching_pokemon, size: 40, color: Colors.red),
            ),
          ),
          
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text("Nutzerdaten löschen", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            subtitle: const Text("Inventar, Binder & Graphen leeren"),
            onTap: () => _confirmReset(context, ref),
          ),
          
          ListTile(
            leading: const Icon(Icons.developer_board, color: Colors.deepPurple),
            title: const Text("Dev Dashboard", style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context); // Schließt den Drawer
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => const AdminDashboardScreen())
              );
            },
          ),
          
          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("App Version 1.0.0", style: TextStyle(color: Colors.grey, fontSize: 12)),
          )
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Alles löschen?"),
        content: const Text(
          "Bist du sicher? Dein komplettes Inventar, alle deine Binder, Preisverläufe und angepasste Preise werden unwiderruflich gelöscht!\n\n"
          "Die heruntergeladenen Kartendaten und Sets bleiben erhalten."
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Abbrechen"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx); // Dialog schließen
              
              final db = ref.read(databaseProvider);
              
              // --- DIE MAGIE: ALLES LEEREN ---
              await db.delete(db.userCards).go();
              await db.delete(db.binderCards).go();
              await db.delete(db.binders).go();
              await db.delete(db.customCardPrices).go();
              await db.delete(db.portfolioHistory).go(); // <--- NEU: Historie löschen!

              // --- UI SOFORT AKTUALISIEREN ---
              ref.invalidate(inventoryProvider);
              ref.invalidate(portfolioHistoryProvider);
              ref.invalidate(top10CardsProvider);
              ref.invalidate(top10GainersProvider);
              ref.invalidate(top10LosersProvider);

              if (context.mounted) {
                Navigator.pop(context); // Drawer schließen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("✅ Nutzerdaten restlos gelöscht!"),
                    backgroundColor: Colors.green,
                    duration: Duration(milliseconds: 500),
                  )
                );
              }
            },
            child: const Text("Ja, alles löschen"),
          ),
        ],
      ),
    );
  }
}