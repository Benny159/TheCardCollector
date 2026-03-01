import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'dart:math' as math; 

import '../../data/api/search_provider.dart';
import '../cards/card_detail_screen.dart';
import 'inventory_bottom_sheet.dart';

final inventorySearchProvider = StateProvider<String>((ref) => '');

// --- NEU: Ein Enum für die Gruppierung ---
enum InventoryGroupMode { none, bySet, byBinder }
final inventoryGroupModeProvider = StateProvider<InventoryGroupMode>((ref) => InventoryGroupMode.none);

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryProvider);
    final sortMode = ref.watch(inventorySortProvider);
    final groupMode = ref.watch(inventoryGroupModeProvider); 
    final searchText = ref.watch(inventorySearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mein Inventar"),
      ),
      body: inventoryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Fehler: $err')),
        data: (allItems) {
          
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

          // 1. FILTERN (Suche)
          var filteredItems = allItems;
          if (searchText.isNotEmpty) {
            filteredItems = allItems.where((item) {
              final nameMatch = item.card.name.toLowerCase().contains(searchText.toLowerCase());
              final nameDeMatch = item.card.nameDe?.toLowerCase().contains(searchText.toLowerCase()) ?? false;
              final setMatch = item.set.name.toLowerCase().contains(searchText.toLowerCase());
              final binderMatch = (item.binderName ?? '').toLowerCase().contains(searchText.toLowerCase());
              
              return nameMatch || nameDeMatch || setMatch || binderMatch;
            }).toList();
          }

          // --- NEU: KARTEN WIEDER ZUSAMMENFASSEN ---
          // Wenn wir NICHT nach Binder sortieren, verschmelzen wir gesplittete 
          // Karten wieder zu einem einzigen Eintrag.
          if (groupMode != InventoryGroupMode.byBinder) {
            final Map<String, InventoryItem> mergedMap = {};
            
            for (final item in filteredItems) {
              // Der Schlüssel ist Karte + Variante (z.B. Schiggy_Reverse Holo)
              final key = "${item.card.id}_${item.variant}";
              
              if (mergedMap.containsKey(key)) {
                // Karte existiert schon -> Menge und Wert addieren!
                final existing = mergedMap[key]!;
                mergedMap[key] = InventoryItem(
                  card: existing.card,
                  set: existing.set,
                  quantity: existing.quantity + item.quantity,
                  variant: existing.variant,
                  totalValue: existing.totalValue + item.totalValue,
                  binderName: null, // Bindername ist hier egal
                );
              } else {
                // Erste Karte dieser Art -> Einfügen
                mergedMap[key] = InventoryItem(
                  card: item.card,
                  set: item.set,
                  quantity: item.quantity,
                  variant: item.variant,
                  totalValue: item.totalValue,
                  binderName: null, 
                );
              }
            }
            // Wir überschreiben unsere Liste mit den zusammengefassten Karten
            filteredItems = mergedMap.values.toList();
          }

          // 2. STATISTIK (Gesamt)
          final int totalCards = filteredItems.fold(0, (sum, item) => sum + item.quantity);
          final double totalValue = filteredItems.fold(0.0, (sum, item) => sum + item.totalValue);

          // 3. SORTIEREN
          final sortedItems = List<InventoryItem>.from(filteredItems);
          sortedItems.sort((a, b) {
            switch (sortMode) {
              case InventorySort.value:
                return b.totalValue.compareTo(a.totalValue);
              case InventorySort.name:
                return (a.card.nameDe ?? a.card.name).compareTo(b.card.nameDe ?? b.card.name);
              case InventorySort.rarity:
                return (b.card.rarity).compareTo(a.card.rarity); 
              // --- NEU: SORTIERUNG NACH TYP ---
              case InventorySort.type:
                final tA = a.card.cardType ?? 'ZZZ'; // Fallback für Karten ohne Typ (z.B. Energie) rutschen nach hinten
                final tB = b.card.cardType ?? 'ZZZ';
                final typeComp = tA.compareTo(tB);
                if (typeComp != 0) return typeComp;
                // Wenn beide Feuer sind, sortiere intern alphabetisch nach Name
                return (a.card.nameDe ?? a.card.name).compareTo(b.card.nameDe ?? b.card.name);
              // --------------------------------
              default:
                return 0;
            }
          });

          return Column(
            children: [
              _buildHeaderStats(context, totalCards, totalValue),
              _buildSearchBar(context, ref, searchText),
              _buildFilterBar(context, ref, sortMode, groupMode),
              const Divider(height: 1),

              // 4. ANZEIGEN JE NACH MODUS
              Expanded(
                child: sortedItems.isEmpty 
                  ? const Center(child: Text("Keine Ergebnisse für deine Suche."))
                  : _buildContent(sortedItems, groupMode),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildContent(List<InventoryItem> items, InventoryGroupMode mode) {
    if (mode == InventoryGroupMode.bySet) return _buildGroupedBySet(items);
    if (mode == InventoryGroupMode.byBinder) return _buildGroupedByBinder(items);
    return _buildGrid(items); // Flache Liste
  }

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

  Widget _buildSearchBar(BuildContext context, WidgetRef ref, String currentText) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: TextField(
        controller: TextEditingController(text: currentText)..selection = TextSelection.fromPosition(TextPosition(offset: currentText.length)),
        decoration: InputDecoration(
          hintText: 'Suche (Name, Set, Binder)...',
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

  Widget _buildFilterBar(BuildContext context, WidgetRef ref, InventorySort currentSort, InventoryGroupMode currentGroup) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.sort, size: 18, color: Colors.grey),
          const SizedBox(width: 4),
          DropdownButton<InventorySort>(
            value: currentSort,
            underline: const SizedBox(),
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 13),
            items: const [
              DropdownMenuItem(value: InventorySort.value, child: Text("Wert")),
              DropdownMenuItem(value: InventorySort.name, child: Text("Name")),
              DropdownMenuItem(value: InventorySort.rarity, child: Text("Seltenheit")),
              // --- NEU ---
              DropdownMenuItem(value: InventorySort.type, child: Text("Element")),
            ],
            onChanged: (val) {
              if (val != null) ref.read(inventorySortProvider.notifier).state = val;
            },
          ),
          const Spacer(),
          
          // NEU: Segmented Button für 3 Ansichten
          SegmentedButton<InventoryGroupMode>(
            segments: const [
              ButtonSegment(value: InventoryGroupMode.none, icon: Icon(Icons.grid_view, size: 16)),
              ButtonSegment(value: InventoryGroupMode.bySet, icon: Icon(Icons.layers, size: 16)),
              ButtonSegment(value: InventoryGroupMode.byBinder, icon: Icon(Icons.folder_special, size: 16)),
            ],
            selected: {currentGroup},
            onSelectionChanged: (Set<InventoryGroupMode> newSelection) {
              ref.read(inventoryGroupModeProvider.notifier).state = newSelection.first;
            },
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
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
        childAspectRatio: 0.70, 
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _InventoryCardTile(item: items[index]),
    );
  }

  Widget _buildGroupedBySet(List<InventoryItem> items) {
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
              child: apiSet.logoUrl != null 
                ? CachedNetworkImage(
                    imageUrl: apiSet.logoUrl!, 
                    fit: BoxFit.contain,
                    placeholder: (_,__) => const SizedBox(),
                    errorWidget: (_,__,___) => const Icon(Icons.broken_image, size: 20, color: Colors.grey),
                  )
                : const Icon(Icons.image_not_supported, color: Colors.grey),
            ),
            title: Text(apiSet.nameDe ?? apiSet.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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

  // --- NEU: NACH BINDERN GRUPPIERT ---
  Widget _buildGroupedByBinder(List<InventoryItem> items) {
    // Gruppiere nach Binder-Name (null bedeutet "Lose im Inventar")
    final grouped = groupBy(items, (item) => item.binderName ?? "Nicht im Binder");
    
    // Wir sortieren alphabetisch, aber "Nicht im Binder" ganz ans Ende!
    final sortedKeys = grouped.keys.toList()..sort((a, b) {
      if (a == "Nicht im Binder") return 1;
      if (b == "Nicht im Binder") return -1;
      return a.compareTo(b);
    });

    return ListView.builder(
      itemCount: sortedKeys.length,
      padding: const EdgeInsets.only(bottom: 20),
      itemBuilder: (context, index) {
        final binderName = sortedKeys[index];
        final binderCards = grouped[binderName]!;

        final totalCount = binderCards.fold(0, (sum, i) => sum + i.quantity);
        final totalValue = binderCards.fold(0.0, (sum, i) => sum + i.totalValue);
        
        final isLoose = binderName == "Nicht im Binder";

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: isLoose ? 0 : 2, // Binder etwas hervorheben
          color: isLoose ? Colors.grey[50] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isLoose ? BorderSide(color: Colors.grey[300]!) : BorderSide.none,
          ),
          child: ExpansionTile(
            initiallyExpanded: !isLoose, // Binder standardmäßig aufklappen
            leading: CircleAvatar(
              backgroundColor: isLoose ? Colors.grey[300] : Colors.blueAccent.withOpacity(0.2),
              child: Icon(
                isLoose ? Icons.inventory_2 : Icons.menu_book, 
                color: isLoose ? Colors.grey[600] : Colors.blueAccent,
                size: 20,
              ),
            ),
            title: Text(binderName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Text("$totalCount Karten • ${totalValue.toStringAsFixed(2)} €", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
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
                itemCount: binderCards.length,
                itemBuilder: (context, cardIndex) {
                  return _InventoryCardTile(item: binderCards[cardIndex]);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- DAS KARTEN-TILE (Mit Holo Effekt) ---
class _InventoryCardTile extends ConsumerWidget {
  final InventoryItem item;

  const _InventoryCardTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Holo-Check
    final bool isReverseHolo = item.variant == 'Reverse Holo';
    final bool isHolo = item.variant == 'Holo';
    final bool showEffect = isReverseHolo || isHolo;

    final displayImage = item.card.displayImage;

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
            Builder(
              builder: (context) {
                Widget imageWidget = CachedNetworkImage(
                  imageUrl: displayImage,
                  placeholder: (context, url) => Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                );
                if (showEffect) return HoloEffect(isReverse: isReverseHolo, child: imageWidget);
                return imageWidget;
              },
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

            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                color: Colors.black.withOpacity(0.7),
                padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (showEffect) const Padding(padding: EdgeInsets.only(right: 2.0)),
                        Text(
                          _getVariantAbbreviation(item.variant),
                          style: TextStyle(
                            color: showEffect ? Colors.amberAccent : Colors.white70,
                            fontSize: 9,
                            fontWeight: showEffect ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
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

// --- HOLO EFFEKT WIDGET ---
class HoloEffect extends StatefulWidget {
  final Widget child;
  final bool isReverse;

  const HoloEffect({super.key, required this.child, this.isReverse = false});

  @override
  State<HoloEffect> createState() => _HoloEffectState();
}

class _HoloEffectState extends State<HoloEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
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
        widget.child,
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  transform: GradientRotation(_controller.value * 2 * math.pi), 
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.1),
                    Colors.purple.withOpacity(0.15), 
                    Colors.blue.withOpacity(0.15),   
                    Colors.white.withOpacity(0.25),  
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 0.45, 0.55, 0.7, 1.0],
                ),
                backgroundBlendMode: BlendMode.overlay, 
              ),
            );
          },
        ),
        if (widget.isReverse)
          Opacity(
            opacity: 0.1,
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.3, -0.5),
                  radius: 1.0,
                  colors: [Colors.white, Colors.transparent],
                ),
                backgroundBlendMode: BlendMode.screen,
              ),
            ),
          ),
      ],
    );
  }
}

class GradientRotation extends GradientTransform {
  final double radians;
  const GradientRotation(this.radians);
  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.rotationZ(radians);
  }
}