import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'dart:math' as math; 

import '../../data/api/search_provider.dart';
import '../cards/card_detail_screen.dart';
import 'inventory_bottom_sheet.dart';


final inventorySearchProvider = StateProvider<String>((ref) => '');

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

          // 2. KARTEN ZUSAMMENFASSEN
          if (groupMode != InventoryGroupMode.byBinder) {
            final Map<String, InventoryItem> mergedMap = {};
            
            for (final item in filteredItems) {
              final company = item.userCard.gradingCompany ?? 'none';
              final score = item.userCard.gradingScore ?? 'none';
              final cPrice = item.userCard.customPrice?.toStringAsFixed(2) ?? 'none';
              
              final key = "${item.card.id}_${item.variant}_${company}_${score}_$cPrice";
              
              if (mergedMap.containsKey(key)) {
                final existing = mergedMap[key]!;
                mergedMap[key] = InventoryItem(
                  card: existing.card,
                  set: existing.set,
                  quantity: existing.quantity + item.quantity,
                  variant: existing.variant,
                  totalValue: existing.totalValue + item.totalValue,
                  binderName: null,
                  userCard: existing.userCard, 
                  // --- FIX: Performance addieren! ---
                  performance: existing.performance + item.performance, 
                );
              } else {
                mergedMap[key] = InventoryItem(
                  card: item.card,
                  set: item.set,
                  quantity: item.quantity,
                  variant: item.variant,
                  totalValue: item.totalValue,
                  binderName: null, 
                  userCard: item.userCard,
                  // --- FIX: Performance übernehmen! ---
                  performance: item.performance, 
                );
              }
            }
            filteredItems = mergedMap.values.toList();
          }

          // 3. STATISTIK (Gesamt)
          final int totalCards = filteredItems.fold(0, (sum, item) => sum + item.quantity);
          final double totalValue = filteredItems.fold(0.0, (sum, item) => sum + item.totalValue);

          // 4. SORTIEREN (Mit Aufsteigend/Absteigend Logik)
          final isAscending = ref.watch(inventorySortAscendingProvider);
          final sortedItems = List<InventoryItem>.from(filteredItems);
          
          sortedItems.sort((a, b) {
            int comp = 0;
            switch (sortMode) {
              case InventorySort.value:
                comp = a.totalValue.compareTo(b.totalValue);
                break;
              case InventorySort.performance:
                comp = a.performance.compareTo(b.performance);
                break;
              case InventorySort.dateAdded:
                comp = a.userCard.createdAt.compareTo(b.userCard.createdAt);
                break;
              case InventorySort.name:
                comp = (a.card.nameDe ?? a.card.name).compareTo(b.card.nameDe ?? b.card.name);
                break;
              case InventorySort.rarity:
                comp = (a.card.rarity ?? '').compareTo(b.card.rarity ?? ''); 
                break;
              case InventorySort.type:
                final tA = a.card.cardType ?? 'ZZZ'; 
                final tB = b.card.cardType ?? 'ZZZ';
                comp = tA.compareTo(tB);
                if (comp == 0) comp = (a.card.nameDe ?? a.card.name).compareTo(b.card.nameDe ?? b.card.name);
                break;
            }
            
            // Standardmäßig wollen wir das Beste/Neueste ganz oben sehen (Absteigend -> -comp).
            // Wenn der Nutzer den Pfeil klickt, drehen wir es um (Aufsteigend -> comp).
            return isAscending ? comp : -comp;
          });

          return Column(
            children: [
              _buildHeaderStats(context, totalCards, totalValue),
              _buildSearchBar(context, ref, searchText),
              _buildFilterBar(context, ref, sortMode, groupMode),
              const Divider(height: 1),

              // 5. ANZEIGEN JE NACH MODUS
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
    return _buildGrid(items); 
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
      child: LayoutBuilder(
        builder: (context, constraints) => RawAutocomplete<String>(
          initialValue: TextEditingValue(text: currentText),
          optionsBuilder: (TextEditingValue textEditingValue) {
            final query = textEditingValue.text.trim().toLowerCase();
            if (query.length < 2) return const Iterable<String>.empty();
            
            final inventory = ref.read(inventoryProvider).valueOrNull ?? [];
            final Set<String> results = {};
            
            for (var item in inventory) {
              if (item.card.nameDe != null && item.card.nameDe!.toLowerCase().contains(query)) {
                results.add(item.card.nameDe!);
              } else if (item.card.name.toLowerCase().contains(query)) {
                results.add(item.card.name);
              }
            }
            return results.take(8);
          },
          onSelected: (String selection) {
            ref.read(inventorySearchProvider.notifier).state = selection;
            FocusScope.of(context).unfocus();
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: 'Suche Karte in Inventar...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: controller.text.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear), 
                      onPressed: () {
                         controller.clear();
                         ref.read(inventorySearchProvider.notifier).state = '';
                         focusNode.unfocus();
                      }
                    )
                  : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (val) => ref.read(inventorySearchProvider.notifier).state = val,
              onSubmitted: (_) {
                focusNode.unfocus();
                onFieldSubmitted();
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 250, maxWidth: constraints.maxWidth),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12),
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        leading: const Icon(Icons.search, size: 18, color: Colors.grey),
                        title: Text(option, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        visualDensity: VisualDensity.compact,
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, WidgetRef ref, InventorySort currentSort, InventoryGroupMode currentGroup) {
    final isAscending = ref.watch(inventorySortAscendingProvider);

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
              DropdownMenuItem(value: InventorySort.dateAdded, child: Text("Erhalten am")),
              DropdownMenuItem(value: InventorySort.value, child: Text("Wert")),
              DropdownMenuItem(value: InventorySort.performance, child: Text("Performance")),
              DropdownMenuItem(value: InventorySort.name, child: Text("Name")),
              DropdownMenuItem(value: InventorySort.rarity, child: Text("Seltenheit")),
              DropdownMenuItem(value: InventorySort.type, child: Text("Element")),
            ],
            onChanged: (val) {
              if (val != null && val != currentSort) {
                // Wenn eine neue Kategorie gewählt wird, setzen wir wieder auf "Absteigend" (Pfeil runter) zurück
                ref.read(inventorySortProvider.notifier).state = val;
                ref.read(inventorySortAscendingProvider.notifier).state = false;
              }
            },
          ),
          
          // --- DER NEUE PFEIL ZUM UMKEHREN DER SORTIERUNG ---
          InkWell(
            onTap: () {
              // Dreht true zu false und false zu true
              ref.read(inventorySortAscendingProvider.notifier).state = !isAscending;
            },
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(
                isAscending ? Icons.arrow_upward : Icons.arrow_downward, 
                size: 16, 
                color: Colors.blue[800]
              ),
            ),
          ),
          
          const Spacer(),
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

  Widget _buildGroupedByBinder(List<InventoryItem> items) {
    final grouped = groupBy(items, (item) => item.binderName ?? "Nicht im Binder");
    
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
          elevation: isLoose ? 0 : 2, 
          color: isLoose ? Colors.grey[50] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isLoose ? BorderSide(color: Colors.grey[300]!) : BorderSide.none,
          ),
          child: ExpansionTile(
            initiallyExpanded: !isLoose, 
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

// --- DAS MINIMALISTISCHE KARTEN-TILE (Clean & Edel!) ---
class _InventoryCardTile extends ConsumerWidget {
  final InventoryItem item;

  const _InventoryCardTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isReverseHolo = item.variant == 'Reverse Holo';
    final bool isHolo = item.variant == 'Holo';
    final bool showEffect = isReverseHolo || isHolo;

    final bool isGraded = item.userCard.gradingCompany != null && item.userCard.gradingCompany != 'Kein Grading';

    final displayImage = item.card.displayImage;

    // --- Preise und Performance ---
    final double singlePrice = item.totalValue / (item.quantity > 0 ? item.quantity : 1);
    final double singlePerformance = item.performance / (item.quantity > 0 ? item.quantity : 1);
    
    final bool hasSpecificPrice = item.userCard.customPrice != null && item.userCard.customPrice! > 0;
    final bool isNeutral = singlePerformance.abs() < 0.01;
    final bool isPositive = singlePerformance > 0;
    
    final Color perfColor = isNeutral ? Colors.grey[400]! : (isPositive ? Colors.greenAccent : Colors.redAccent);
    final IconData perfIcon = isNeutral ? Icons.remove : (isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down);

    // --- Daten für die Anzeige ---
    final String dateStr = DateFormat('dd.MM.yy').format(item.userCard.createdAt);
    final String variantStr = _getVariantAbbreviation(item.variant);
    final String conditionStr = _getConditionAbbreviation(item.userCard.condition);
    final Color conditionColor = _getConditionColor(item.userCard.condition);

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
        elevation: isGraded ? 6 : 2, 
        shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(12),
           side: isGraded ? BorderSide(color: Colors.orange[400]!, width: 1.5) : BorderSide.none
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Das Kartenbild (Hintergrund)
            Builder(
              builder: (context) {
                Widget imageWidget = CachedNetworkImage(
                  imageUrl: displayImage,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Container(color: Colors.grey[200]),
                  errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                );
                if (showEffect) return HoloEffect(isReverse: isReverseHolo, child: imageWidget);
                return imageWidget;
              },
            ),

            // --- 2. OBERER BEREICH (Sanfter Gradient + Name & Variante) ---
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                    stops: const [0.0, 1.0],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // --- NEU: KARTEN-NAME MIT TRADING CARD OUTLINE ---
                    Expanded(
                      child: Stack(
                        children: [
                          // 1. Die weiße, dicke Kontur (Outline)
                          Text(
                            item.card.nameDe ?? item.card.name,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900, // Extra fett
                              foreground: Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = 1.0 // Dicke der Umrandung
                                ..color = Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // 2. Die schwarze Füllung
                          Text(
                            item.card.nameDe ?? item.card.name,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      variantStr,
                      style: TextStyle(
                        color: showEffect ? Colors.amberAccent : Colors.white70, 
                        fontSize: 9, 
                        fontWeight: showEffect ? FontWeight.bold : FontWeight.normal
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Grading Score (PSA)
            if (isGraded)
              Positioned(
                top: 30, left: 4, 
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(color: Colors.orange[800], borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    "${item.userCard.gradingCompany} ${item.userCard.gradingScore ?? ''}".trim(), 
                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)
                  ),
                ),
              ),

            // Anzahl Badge (3x)
            Positioned(
              top: 30, right: 4, 
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.blue[800], borderRadius: BorderRadius.circular(10)),
                child: Text(
                  "${item.quantity}x", 
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                ),
              ),
            ),

            // --- NEU: ZUSTANDS BADGE (Schwebend über dem unteren Balken) ---
            Positioned(
              bottom: 20, left: 4, 
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: conditionColor, 
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 2, offset: const Offset(0, 1))],
                ),
                child: Text(
                  conditionStr, 
                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)
                ),
              ),
            ),

            // --- 3. UNTERER BEREICH (Sanfter Gradient + Preis/Performance gestapelt) ---
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                    stops: const [0.0, 1.0],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(6, 16, 6, 6), 
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Datum (Links, unten ausgerichtet)
                    Expanded(
                      child: Text(
                        "Am: $dateStr",
                        style: const TextStyle(color: Colors.white70, fontSize: 9),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const SizedBox(width: 4),
                    
                    // Performance OBERHALB des Preises
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!hasSpecificPrice)
                          Row(
                            children: [
                              Icon(perfIcon, color: perfColor, size: 12),
                              Text(
                                "${singlePerformance.abs().toStringAsFixed(2)}€",
                                style: TextStyle(color: perfColor, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        if (!hasSpecificPrice) const SizedBox(height: 2),
                        
                        Row(
                          children: [
                            if (hasSpecificPrice) const Icon(Icons.star, color: Colors.amber, size: 10),
                            if (hasSpecificPrice) const SizedBox(width: 2),
                            Text(
                              "${singlePrice.toStringAsFixed(2)}€",
                              style: TextStyle(
                                color: hasSpecificPrice ? Colors.amberAccent : Colors.greenAccent, 
                                fontSize: 11, 
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ],
                        ),
                      ],
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

  // --- HILFSFUNKTIONEN FÜR ABKÜRZUNGEN UND FARBEN ---

  String _getVariantAbbreviation(String variant) {
    if (variant == 'Reverse Holo') return 'Rev.';
    if (variant == 'Normal') return 'Norm.';
    if (variant == 'Holo') return 'Holo';
    if (variant == '1st Edition') return '1.Ed';
    return variant;
  }

  String _getConditionAbbreviation(String condition) {
    switch (condition) {
      case 'Mint': return 'MINT';
      case 'Near Mint': return 'NM';
      case 'Excellent': return 'EX';
      case 'Good': return 'GD';
      case 'Light Played': return 'LP';
      case 'Played': return 'PL';
      case 'Poor': return 'POOR';
      default: return condition;
    }
  }

  Color _getConditionColor(String condition) {
    switch (condition) {
      case 'Mint':
      case 'Near Mint': 
        return Colors.green[700]!;
      case 'Excellent': 
      case 'Good': 
        return Colors.blue[700]!;
      case 'Light Played': 
      case 'Played': 
        return Colors.orange[700]!;
      case 'Poor': 
        return Colors.red[700]!;
      default: 
        return Colors.grey[700]!;
    }
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
                  // Wir nutzen Flutters natives GradientRotation (kein import dart:math nötig)
                  transform: GradientRotation(_controller.value * 2 * 3.1415926535), 
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