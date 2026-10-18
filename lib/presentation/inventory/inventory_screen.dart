import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';

import '../../core/cache/app_image_cache_manager.dart';
import '../../data/api/search_provider.dart';
import 'widgets/inventory_card_tile.dart';

final inventorySearchProvider = StateProvider.autoDispose<String>((ref) => '');

/// Tracks set IDs currently expanded in the grouped-by-set view.
final expandedSetsProvider = StateProvider<Set<String>>((ref) => {});

/// Tracks binder names currently expanded in the grouped-by-binder view.
final expandedBindersProvider = StateProvider<Set<String>>((ref) => {});

/// Computes filtered, aggregated, and sorted inventory items.
final processedInventoryProvider =
    Provider<AsyncValue<List<InventoryItem>>>((ref) {
  // Watch raw inventory dataset and active filter states
  final inventoryAsync = ref.watch(inventoryProvider);
  final searchText = ref.watch(inventorySearchProvider);
  final groupMode = ref.watch(inventoryGroupModeProvider);
  final sortMode = ref.watch(inventorySortProvider);
  final isAscending = ref.watch(inventorySortAscendingProvider);

  return inventoryAsync.whenData((allItems) {
    if (allItems.isEmpty) return [];

    // Filter by search query across card names, set names, and binder assignments
    var filteredItems = allItems;
    if (searchText.isNotEmpty) {
      filteredItems = allItems.where((item) {
        final nameMatch =
            item.card.name.toLowerCase().contains(searchText.toLowerCase());
        final nameDeMatch = item.card.nameDe
                ?.toLowerCase()
                .contains(searchText.toLowerCase()) ??
            false;
        final setMatch =
            item.set.name.toLowerCase().contains(searchText.toLowerCase());
        final binderMatch = (item.binderName ?? '')
            .toLowerCase()
            .contains(searchText.toLowerCase());

        return nameMatch || nameDeMatch || setMatch || binderMatch;
      }).toList();
    }

    // Consolidate card duplicates when not grouped by binder
    if (groupMode != InventoryGroupMode.byBinder) {
      final Map<String, InventoryItem> mergedMap = {};

      for (final item in filteredItems) {
        final company = item.userCard.gradingCompany ?? 'none';
        final score = item.userCard.gradingScore ?? 'none';
        final cPrice = item.userCard.customPrice?.toStringAsFixed(2) ?? 'none';

        final key =
            "${item.card.id}_${item.variant}_${company}_${score}_$cPrice";

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
            performance: item.performance,
          );
        }
      }
      filteredItems = mergedMap.values.toList();
    }

    // Sort cards according to active criterion and direction
    final sortedItems = List<InventoryItem>.from(filteredItems);

    sortedItems.sort((a, b) {
      int comp = 0;
      switch (sortMode) {
        case InventorySort.value:
          final singleValA = a.totalValue / (a.quantity > 0 ? a.quantity : 1);
          final singleValB = b.totalValue / (b.quantity > 0 ? b.quantity : 1);
          comp = singleValA.compareTo(singleValB);
          break;
        case InventorySort.performance:
          final singlePerfA = a.performance / (a.quantity > 0 ? a.quantity : 1);
          final singlePerfB = b.performance / (b.quantity > 0 ? b.quantity : 1);
          comp = singlePerfA.compareTo(singlePerfB);
          break;
        case InventorySort.dateAdded:
          comp = a.userCard.createdAt.compareTo(b.userCard.createdAt);
          break;
        case InventorySort.name:
          comp = (a.card.nameDe ?? a.card.name)
              .compareTo(b.card.nameDe ?? b.card.name);
          break;
        case InventorySort.rarity:
          comp = a.card.rarity.compareTo(b.card.rarity);
          break;
        case InventorySort.type:
          final tA = a.card.cardType ?? 'ZZZ';
          final tB = b.card.cardType ?? 'ZZZ';
          comp = tA.compareTo(tB);
          if (comp == 0) {
            comp = (a.card.nameDe ?? a.card.name)
                .compareTo(b.card.nameDe ?? b.card.name);
          }
          break;
      }
      return isAscending ? comp : -comp;
    });

    return sortedItems;
  });
});

enum InventoryGroupMode { none, bySet, byBinder }

final inventoryGroupModeProvider =
    StateProvider.autoDispose<InventoryGroupMode>(
        (ref) => InventoryGroupMode.none);

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Wir hören JETZT auf den neuen, verarbeiteten Provider!
    final processedInventoryAsync = ref.watch(processedInventoryProvider);

    final sortMode = ref.watch(inventorySortProvider);
    final groupMode = ref.watch(inventoryGroupModeProvider);
    final searchText = ref.watch(inventorySearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mein Inventar"),
      ),
      body: processedInventoryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Fehler: $err')),
        data: (sortedItems) {
          if (sortedItems.isEmpty && searchText.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Dein Inventar ist noch leer.",
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          final int totalCards =
              sortedItems.fold(0, (sum, item) => sum + item.quantity);
          final double totalValue =
              sortedItems.fold(0.0, (sum, item) => sum + item.totalValue);

          return Column(
            children: [
              _buildHeaderStats(context, totalCards, totalValue),
              _buildSearchBar(context, ref, searchText),
              _buildFilterBar(context, ref, sortMode, groupMode),
              const Divider(height: 1),

              // Display cards according to selected grouping mode
              Expanded(
                child: sortedItems.isEmpty
                    ? const Center(
                        child: Text("Keine Ergebnisse für deine Suche."))
                    : _buildContent(sortedItems, groupMode, ref),
              ),
            ],
          );
        },
      ),
    );
  }

  // Sub-widgets

  Widget _buildContent(
      List<InventoryItem> items, InventoryGroupMode mode, WidgetRef ref) {
    if (mode == InventoryGroupMode.bySet) return _buildGroupedBySet(items, ref);
    if (mode == InventoryGroupMode.byBinder) {
      return _buildGroupedByBinder(items, ref);
    }
    return _buildGrid(items);
  }

  Widget _buildHeaderStats(BuildContext context, int count, double value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color:
          Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Text("Karten",
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text("$count",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          Container(width: 1, height: 30, color: Colors.grey[400]),
          Column(
            children: [
              const Text("Gesamtwert",
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text("${value.toStringAsFixed(2)} €",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(
      BuildContext context, WidgetRef ref, String currentText) {
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
              if (item.card.nameDe != null &&
                  item.card.nameDe!.toLowerCase().contains(query)) {
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
                        })
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
              onChanged: (val) =>
                  ref.read(inventorySearchProvider.notifier).state = val,
              onSubmitted: (val) {
                focusNode.unfocus();
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
                  constraints: BoxConstraints(
                      maxHeight: 250, maxWidth: constraints.maxWidth),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Colors.black12),
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        leading: const Icon(Icons.search,
                            size: 18, color: Colors.grey),
                        title: Text(option,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
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

  Widget _buildFilterBar(BuildContext context, WidgetRef ref,
      InventorySort currentSort, InventoryGroupMode currentGroup) {
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
            style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
                fontSize: 13),
            items: const [
              DropdownMenuItem(
                  value: InventorySort.dateAdded, child: Text("Erhalten am")),
              DropdownMenuItem(value: InventorySort.value, child: Text("Wert")),
              DropdownMenuItem(
                  value: InventorySort.performance, child: Text("Performance")),
              DropdownMenuItem(value: InventorySort.name, child: Text("Name")),
              DropdownMenuItem(
                  value: InventorySort.rarity, child: Text("Seltenheit")),
              DropdownMenuItem(
                  value: InventorySort.type, child: Text("Element")),
            ],
            onChanged: (val) {
              if (val != null && val != currentSort) {
                // Reset order to descending when sorting category changes
                ref.read(inventorySortProvider.notifier).state = val;
                ref.read(inventorySortAscendingProvider.notifier).state = false;
              }
            },
          ),

          // Sort direction toggle button
          InkWell(
            onTap: () {
              // Invert sort order direction
              ref.read(inventorySortAscendingProvider.notifier).state =
                  !isAscending;
            },
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(
                  isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                  color: Colors.blue[800]),
            ),
          ),

          const Spacer(),
          SegmentedButton<InventoryGroupMode>(
            segments: const [
              ButtonSegment(
                  value: InventoryGroupMode.none,
                  icon: Icon(Icons.grid_view, size: 16)),
              ButtonSegment(
                  value: InventoryGroupMode.bySet,
                  icon: Icon(Icons.layers, size: 16)),
              ButtonSegment(
                  value: InventoryGroupMode.byBinder,
                  icon: Icon(Icons.folder_special, size: 16)),
            ],
            selected: {currentGroup},
            onSelectionChanged: (Set<InventoryGroupMode> newSelection) {
              ref.read(inventoryGroupModeProvider.notifier).state =
                  newSelection.first;
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
      padding: const EdgeInsets.only(left: 10, top: 10, right: 10, bottom: 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.70,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => InventoryCardTile(item: items[index]),
    );
  }

  Widget _buildGroupedBySet(List<InventoryItem> items, WidgetRef ref) {
    final grouped = groupBy(items, (item) => item.set.id);
    final expandedSets = ref.watch(expandedSetsProvider);

    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final dateA = grouped[a]!.first.set.releaseDate;
        final dateB = grouped[b]!.first.set.releaseDate;
        return dateB.compareTo(dateA);
      });

    return CustomScrollView(
      slivers: [
        const SliverPadding(padding: EdgeInsets.only(top: 8)),
        // Expand sets into header and optional lazy grid
        ...sortedKeys.expand((setId) {
          final setCards = grouped[setId]!;
          final apiSet = setCards.first.set;
          final isExpanded = expandedSets.contains(setId);

          final setTotalCount = setCards.fold(0, (sum, i) => sum + i.quantity);
          final setTotalValue =
              setCards.fold(0.0, (sum, i) => sum + i.totalValue);

          return [
            // 1. Group header item
            SliverToBoxAdapter(
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    // Toggle section expansion state
                    final current = ref.read(expandedSetsProvider);
                    if (isExpanded) {
                      ref.read(expandedSetsProvider.notifier).state = {
                        ...current
                      }..remove(setId);
                    } else {
                      ref.read(expandedSetsProvider.notifier).state = {
                        ...current,
                        setId
                      };
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: SizedBox(
                        width: 50,
                        height: 30,
                        child: apiSet.logoUrl != null
                            ? CachedNetworkImage(
                                cacheManager: AppImageCacheManager.instance,
                                imageUrl: apiSet.logoUrl!,
                                memCacheHeight: 200,
                                fit: BoxFit.contain,
                                placeholder: (_, __) => const SizedBox(),
                                errorWidget: (_, __, ___) => const Icon(
                                    Icons.broken_image,
                                    size: 20,
                                    color: Colors.grey),
                              )
                            : const Icon(Icons.image_not_supported,
                                color: Colors.grey),
                      ),
                      title: Text(apiSet.nameDe ?? apiSet.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      subtitle: Text(
                          "$setTotalCount Karten • ${setTotalValue.toStringAsFixed(2)} €",
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12)),
                      trailing: Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more),
                    ),
                  ),
                ),
              ),
            ),

            // 2. Lazy card grid rendered only when section is expanded
            if (isExpanded)
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.70,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, cardIndex) =>
                        InventoryCardTile(item: setCards[cardIndex]),
                    childCount: setCards.length,
                  ),
                ),
              ),
          ];
        }),
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }

  Widget _buildGroupedByBinder(List<InventoryItem> items, WidgetRef ref) {
    final grouped =
        groupBy(items, (item) => item.binderName ?? "Nicht im Binder");
    final expandedBinders = ref.watch(expandedBindersProvider);

    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        if (a == "Nicht im Binder") return 1;
        if (b == "Nicht im Binder") return -1;
        return a.compareTo(b);
      });

    return CustomScrollView(
      slivers: [
        const SliverPadding(padding: EdgeInsets.only(top: 8)),
        ...sortedKeys.expand((binderName) {
          final binderCards = grouped[binderName]!;
          final isLoose = binderName == "Nicht im Binder";

          // 'Not in binder' group is expanded by default; specific binders are collapsed by default
          final isExpanded = isLoose
              ? !expandedBinders.contains(binderName)
              : expandedBinders.contains(binderName);

          final totalCount = binderCards.fold(0, (sum, i) => sum + i.quantity);
          final totalValue =
              binderCards.fold(0.0, (sum, i) => sum + i.totalValue);

          return [
            SliverToBoxAdapter(
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                elevation: isLoose ? 0 : 2,
                color: isLoose ? Colors.grey[50] : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isLoose
                      ? BorderSide(color: Colors.grey[300]!)
                      : BorderSide.none,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    final current = ref.read(expandedBindersProvider);
                    if (expandedBinders.contains(binderName)) {
                      ref.read(expandedBindersProvider.notifier).state = {
                        ...current
                      }..remove(binderName);
                    } else {
                      ref.read(expandedBindersProvider.notifier).state = {
                        ...current,
                        binderName
                      };
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isLoose
                            ? Colors.grey[300]
                            : Colors.blueAccent.withValues(alpha: 0.2),
                        child: Icon(
                          isLoose ? Icons.inventory_2 : Icons.menu_book,
                          color: isLoose ? Colors.grey[600] : Colors.blueAccent,
                          size: 20,
                        ),
                      ),
                      title: Text(binderName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      subtitle: Text(
                          "$totalCount Karten • ${totalValue.toStringAsFixed(2)} €",
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12)),
                      trailing: Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more),
                    ),
                  ),
                ),
              ),
            ),
            if (isExpanded)
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.70,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, cardIndex) =>
                        InventoryCardTile(item: binderCards[cardIndex]),
                    childCount: binderCards.length,
                  ),
                ),
              ),
          ];
        }),
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }
}
