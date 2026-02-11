import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart'; // Für groupBy

import '../../data/api/search_provider.dart';
import '../../domain/models/api_card.dart';
import '../cards/card_detail_screen.dart';
import 'inventory_bottom_sheet.dart';

// NEU: Provider für den Suchtext im Inventar
final inventorySearchProvider = StateProvider<String>((ref) => '');

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryProvider);
    final sortMode = ref.watch(inventorySortProvider);
    final groupBySet = ref.watch(inventoryGroupBySetProvider);
    final searchText = ref.watch(inventorySearchProvider); // Suchtext lesen

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mein Inventar"),
      ),
      body: inventoryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Fehler: $err')),
        data: (allItems) {
          
          // 1. FILTERN (Suche)
          var filteredItems = allItems;
          if (searchText.isNotEmpty) {
            filteredItems = allItems.where((item) {
              return item.card.name.toLowerCase().contains(searchText.toLowerCase()) ||
                     item.set.name.toLowerCase().contains(searchText.toLowerCase());
            }).toList();
          }

          if (allItems.isEmpty) {
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

          // 2. STATISTIK (Basierend auf ALLEM, oder gefiltert? Meistens will man Summe von allem sehen)
          // Ich lasse hier die Gesamtsumme (ungefiltert), damit man immer seinen "Account Wert" sieht.
          final int totalCards = allItems.fold(0, (sum, item) => sum + item.quantity);
          final double totalValue = allItems.fold(0.0, (sum, item) => sum + item.totalValue);

          // 3. SORTIEREN (der gefilterten Liste)
          final sortedItems = List<InventoryItem>.from(filteredItems);
          sortedItems.sort((a, b) {
            switch (sortMode) {
              case InventorySort.value:
                return b.totalValue.compareTo(a.totalValue);
              case InventorySort.name:
                return a.card.name.compareTo(b.card.name);
              case InventorySort.rarity:
                return b.card.rarity.compareTo(a.card.rarity); 
              case InventorySort.type:
                final typeA = a.card.types.firstOrNull ?? 'ZZ';
                final typeB = b.card.types.firstOrNull ?? 'ZZ';
                return typeA.compareTo(typeB);
              case InventorySort.number:
                 final intA = int.tryParse(a.card.number) ?? 9999;
                 final intB = int.tryParse(b.card.number) ?? 9999;
                 return intA.compareTo(intB);
            }
          });

          return Column(
            children: [
              // Header Stats
              _buildHeaderStats(context, totalCards, totalValue),
              
              // Suchleiste
              _buildSearchBar(context, ref, searchText),

              // Filter Leiste
              _buildFilterBar(context, ref, sortMode, groupBySet),
              
              const Divider(height: 1),

              // Inhalt
              Expanded(
                child: sortedItems.isEmpty 
                  ? const Center(child: Text("Keine Ergebnisse für deine Suche."))
                  : groupBySet 
                      ? _buildGroupedList(sortedItems)
                      : _buildGrid(sortedItems),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildHeaderStats(BuildContext context, int count, double value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Text("Karten", style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text("$count", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          Container(width: 1, height: 30, color: Colors.grey[400]),
          Column(
            children: [
              const Text("Gesamtwert", style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text("${value.toStringAsFixed(2)} €", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green[700])),
            ],
          ),
        ],
      ),
    );
  }

  // NEU: Suchleiste
  Widget _buildSearchBar(BuildContext context, WidgetRef ref, String currentText) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: TextField(
        controller: TextEditingController(text: currentText)..selection = TextSelection.fromPosition(TextPosition(offset: currentText.length)),
        decoration: InputDecoration(
          hintText: 'Inventar durchsuchen...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: currentText.isNotEmpty 
            ? IconButton(icon: const Icon(Icons.clear), onPressed: () => ref.read(inventorySearchProvider.notifier).state = '')
            : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
        onChanged: (val) => ref.read(inventorySearchProvider.notifier).state = val,
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, WidgetRef ref, InventorySort currentSort, bool groupBySet) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: Row(
        children: [
          const Icon(Icons.sort, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          DropdownButton<InventorySort>(
            value: currentSort,
            underline: const SizedBox(),
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
            items: const [
              DropdownMenuItem(value: InventorySort.value, child: Text("Wert")),
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
        childAspectRatio: 0.70, // Standard TCG Format
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _InventoryCardTile(item: items[index]),
    );
  }

  Widget _buildGroupedList(List<InventoryItem> items) {
    final grouped = groupBy(items, (item) => item.set.id);
    
    final sortedKeys = grouped.keys.toList()..sort((a, b) {
      final dateA = grouped[a]!.first.set.releaseDate;
      final dateB = grouped[b]!.first.set.releaseDate;
      return dateB.compareTo(dateA); 
    });

    return ListView.builder(
      itemCount: sortedKeys.length,
      padding: const EdgeInsets.only(bottom: 20),
      itemBuilder: (context, index) {
        final setId = sortedKeys[index];
        final setCards = grouped[setId]!;
        final apiSet = setCards.first.set;

        final setTotalCount = setCards.fold(0, (sum, i) => sum + i.quantity);
        final setTotalValue = setCards.fold(0.0, (sum, i) => sum + i.totalValue);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
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
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.70,
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

// DAS KARTEN-TILE (Design angepasst wie gewünscht)
class _InventoryCardTile extends ConsumerWidget {
  final InventoryItem item;

  const _InventoryCardTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Prüfen, ob wir den Effekt brauchen
    final bool isReverseHolo = item.variant == 'Reverse Holo';
    final bool isHolo = item.variant == 'Holo';
    final bool showEffect = isReverseHolo || isHolo;

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
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. DAS BILD (Mit Logik für den Effekt)
            Builder(
              builder: (context) {
                // Das Basis-Bild
                Widget imageWidget = CachedNetworkImage(
                  imageUrl: item.card.smallImageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                );

                // Wenn Effekt gewünscht, wickeln wir es ein
                if (showEffect) {
                  return HoloEffect(
                    isReverse: isReverseHolo,
                    child: imageWidget,
                  );
                }
                
                return imageWidget;
              },
            ),
            
            // 2. MENGE BADGE (Oben rechts)
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

            // 3. DUNKLER BALKEN (Unten)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                color: Colors.black.withOpacity(0.7),
                padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Links: Variante (kurz) mit Icon falls Holo
                    Row(
                      children: [
                        if (showEffect) 
                          const Padding(
                            padding: EdgeInsets.only(right: 2.0),
                          ),
                        Text(
                          _getVariantAbbreviation(item.variant),
                          style: TextStyle(
                            color: showEffect ? Colors.white70 : Colors.white70, // Text wird Gold bei Holo
                            fontSize: 9,
                            fontWeight: showEffect ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    // Rechts: Preis (Summe)
                    Text(
                      "${item.totalValue.toStringAsFixed(2)}€",
                      style: const TextStyle(color: Colors.lightGreenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
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
    if (variant == '1st Edition') return '1.Ed';
    return variant;
  }
}

// --- NEU: HOLO / GLITZER EFFEKT WIDGET ---
class HoloEffect extends StatefulWidget {
  final Widget child;
  final bool isReverse; // Unterscheidung für später (optional)

  const HoloEffect({super.key, required this.child, this.isReverse = false});

  @override
  State<HoloEffect> createState() => _HoloEffectState();
}

class _HoloEffectState extends State<HoloEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Langsame Animation für das Schimmern (Endlosschleife)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Das Originalbild
        widget.child,

        // 2. Der Holo-Layer (wird darübergelegt)
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  // Der Gradient bewegt sich durch die Animation
                  transform: GradientRotation(_controller.value * 2 * 3.14159), 
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.1),
                    Colors.purple.withOpacity(0.15), // Lila Schimmer
                    Colors.blue.withOpacity(0.15),   // Blauer Schimmer
                    Colors.white.withOpacity(0.2),   // Heller Reflex
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 0.45, 0.55, 0.7, 1.0],
                ),
                // Overlay sorgt dafür, dass es wie Licht auf dem Bild wirkt
                backgroundBlendMode: BlendMode.overlay, 
              ),
            );
          },
        ),
        
        // 3. Zusätzliches "Glitzer" (optional, statisches Rauschen für Reverse Holo Look)
        if (widget.isReverse)
          Opacity(
            opacity: 0.15,
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.3, -0.5),
                  radius: 1.2,
                  colors: [
                    Colors.white,
                    Colors.transparent,
                  ],
                ),
                backgroundBlendMode: BlendMode.hardLight,
              ),
            ),
          ),
      ],
    );
  }
}

// Helper für die Rotation des Gradients
class GradientRotation extends GradientTransform {
  final double radians;
  const GradientRotation(this.radians);
  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.rotationZ(radians);
  }
}