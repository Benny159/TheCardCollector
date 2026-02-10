import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart'; // Für groupBy

import '../../data/api/search_provider.dart';
import '../../domain/models/api_card.dart';
import '../cards/card_detail_screen.dart';
import 'inventory_bottom_sheet.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Da es jetzt ein Stream ist, ist inventoryAsync immer aktuell!
    final inventoryAsync = ref.watch(inventoryProvider);
    final sortMode = ref.watch(inventorySortProvider);
    final groupBySet = ref.watch(inventoryGroupBySetProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mein Inventar"),
        // Kein Refresh-Button mehr nötig, da automatisch!
      ),
      body: inventoryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Fehler: $err')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Dein Inventar ist noch leer.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // 1. STATISTIK
          final int totalCards = items.fold(0, (sum, item) => sum + item.quantity);
          final double totalValue = items.fold(0.0, (sum, item) => sum + item.totalValue);

          // 2. SORTIEREN
          final sortedItems = List<InventoryItem>.from(items);
          sortedItems.sort((a, b) {
            switch (sortMode) {
              case InventorySort.name:
                return a.card.name.compareTo(b.card.name);
              case InventorySort.rarity:
                return b.card.rarity.compareTo(a.card.rarity); 
              case InventorySort.type:
                final typeA = a.card.types.firstOrNull ?? 'ZZ';
                final typeB = b.card.types.firstOrNull ?? 'ZZ';
                return typeA.compareTo(typeB);
              case InventorySort.number:
                 // Versuchen, die Nummern numerisch zu sortieren (1, 2, 10 statt 1, 10, 2)
                 final intA = int.tryParse(a.card.number) ?? 9999;
                 final intB = int.tryParse(b.card.number) ?? 9999;
                 return intA.compareTo(intB);
            }
          });

          return Column(
            children: [
              _buildHeaderStats(context, totalCards, totalValue),
              _buildFilterBar(context, ref, sortMode, groupBySet),
              const Divider(height: 1),
              Expanded(
                child: groupBySet 
                  ? _buildGroupedList(sortedItems)
                  : _buildGrid(sortedItems),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderStats(BuildContext context, int count, double value) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Text("Karten", style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text("$count", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          Container(width: 1, height: 40, color: Colors.grey[400]),
          Column(
            children: [
              const Text("Gesamtwert", style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text("${value.toStringAsFixed(2)} €", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green[700])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, WidgetRef ref, InventorySort currentSort, bool groupBySet) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.sort, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          DropdownButton<InventorySort>(
            value: currentSort,
            underline: const SizedBox(),
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
            items: const [
              DropdownMenuItem(value: InventorySort.name, child: Text("Name")),
              DropdownMenuItem(value: InventorySort.rarity, child: Text("Seltenheit")),
              DropdownMenuItem(value: InventorySort.type, child: Text("Element")),
              DropdownMenuItem(value: InventorySort.number, child: Text("Nummer")),
            ],
            onChanged: (val) {
              if (val != null) ref.read(inventorySortProvider.notifier).state = val;
            },
          ),
          const Spacer(),
          const Text("Nach Sets: ", style: TextStyle(fontSize: 13)),
          Switch(
            value: groupBySet,
            activeColor: Colors.blueAccent,
            onChanged: (val) => ref.read(inventoryGroupBySetProvider.notifier).state = val,
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<InventoryItem> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.65,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _InventoryCardTile(item: items[index]),
    );
  }

  // --- HIER IST DIE NEUE SET-ANSICHT ---
  Widget _buildGroupedList(List<InventoryItem> items) {
    // Wir gruppieren nach der Set-ID
    final grouped = groupBy(items, (item) => item.set.id);
    
    // Sortieren der Sets (neueste oben)
    final sortedKeys = grouped.keys.toList()..sort((a, b) {
      // Wir holen das Datum aus dem ersten Item der Gruppe
      final dateA = grouped[a]!.first.set.releaseDate;
      final dateB = grouped[b]!.first.set.releaseDate;
      return dateB.compareTo(dateA); // Neueste zuerst
    });

    return ListView.builder(
      itemCount: sortedKeys.length,
      padding: const EdgeInsets.only(bottom: 20),
      itemBuilder: (context, index) {
        final setId = sortedKeys[index];
        final setCards = grouped[setId]!;
        
        // Da 'InventoryItem' jetzt das Set-Objekt enthält, können wir direkt zugreifen!
        final apiSet = setCards.first.set;

        // Summen pro Set
        final setTotalCount = setCards.fold(0, (sum, i) => sum + i.quantity);
        final setTotalValue = setCards.fold(0.0, (sum, i) => sum + i.totalValue);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            // --- HEADER MIT LOGO UND ECHTEM NAMEN ---
            leading: SizedBox(
              width: 50, 
              height: 30,
              child: CachedNetworkImage(
                imageUrl: apiSet.logoUrl, 
                fit: BoxFit.contain,
                placeholder: (_,__) => const SizedBox(),
                errorWidget: (_,__,___) => const Icon(Icons.broken_image, size: 20, color: Colors.grey),
              ),
            ),
            title: Text(apiSet.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Text("$setTotalCount Karten • ${setTotalValue.toStringAsFixed(2)} €", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            childrenPadding: const EdgeInsets.only(bottom: 12),
            // --- GRID INHALT ---
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: setCards.length,
                itemBuilder: (context, cardIndex) {
                  return _InventoryCardTile(item: setCards[cardIndex]);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InventoryCardTile extends ConsumerWidget {
  final InventoryItem item;

  const _InventoryCardTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => CardDetailScreen(card: item.card)));
      },
      onLongPress: () async {
        await showModalBottomSheet(
          context: context, 
          isScrollControlled: true,
          builder: (_) => InventoryBottomSheet(card: item.card)
        );
        // Kein manuelles Refresh mehr nötig! Der Stream macht das.
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: item.card.smallImageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.grey[200]),
                  ),
                  Positioned(
                    top: 4, right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.blue[800], borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        "${item.quantity}x", 
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              color: Colors.grey[50],
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.card.name, 
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Variante kurz
                      Text(
                        _getVariantAbbreviation(item.variant),
                        style: TextStyle(fontSize: 9, color: Colors.grey[700]),
                      ),
                      Text(
                        "${item.totalValue.toStringAsFixed(2)}€",
                        style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getVariantAbbreviation(String variant) {
    if (variant == 'Reverse Holo') return 'Rev.';
    if (variant == 'Normal') return 'Norm.';
    if (variant == 'Holo') return 'Holo';
    return variant;
  }
}