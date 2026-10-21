import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/search_provider.dart';
import '../../domain/models/api_card.dart';
import '../../domain/models/api_set.dart';
import '../../domain/services/offline_sync_service.dart';
import '../cards/card_detail_screen.dart';
import '../inventory/inventory_bottom_sheet.dart';
import '../widgets/card_image_widget.dart';

// Filter enum for card ownership status
enum OwnershipFilter { all, owned, missing }

class SetDetailScreen extends ConsumerStatefulWidget {
  final ApiSet set;

  const SetDetailScreen({super.key, required this.set});

  @override
  ConsumerState<SetDetailScreen> createState() => _SetDetailScreenState();
}

class _SetDetailScreenState extends ConsumerState<SetDetailScreen> {
  final Set<String> _selectedRarities = {};
  bool _showStandardSetOnly = false;
  bool _isRaritiesExpanded = false;

  OwnershipFilter _ownershipFilter = OwnershipFilter.all;

  // Search state variables (including expanded status)
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = "";
  bool _isSearchExpanded = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Observe cards provider (Riverpod caches query results)
    final cardsAsync = ref.watch(cardsForSetProvider(widget.set.id));
    final syncProgress = ref.watch(offlineSyncProgressProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.set.nameDe ?? widget.set.name),
        centerTitle: true,
        actions: [
          IconButton(
            icon: syncProgress.isSyncing && syncProgress.currentTask == (widget.set.nameDe ?? widget.set.name)
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent),
                  )
                : const Icon(Icons.download_for_offline_outlined),
            tooltip: "Set für Offline-Nutzung herunterladen",
            onPressed: syncProgress.isSyncing
                ? null
                : () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Lade Kartenbilder für '${widget.set.nameDe ?? widget.set.name}' herunter..."),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    await ref.read(offlineSyncProgressProvider.notifier).syncSet(
                          widget.set.id,
                          widget.set.nameDe ?? widget.set.name,
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Alle Bilder für '${widget.set.nameDe ?? widget.set.name}' sind jetzt offline verfügbar!"),
                          backgroundColor: Colors.green[700],
                        ),
                      );
                    }
                  },
          ),
        ],
      ),
      body: cardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Fehler: $err')),
        data: (rawCards) {
          if (rawCards.isEmpty) {
            return const Center(child: Text("Keine Karten gefunden."));
          }

          final List<ApiCard> allCards = rawCards;

          // 1. Filter visible cards
          List<ApiCard> visibleCards = allCards;

          if (_showStandardSetOnly) {
            visibleCards = visibleCards.where((c) {
              final num = int.tryParse(c.number);
              return num != null && num <= widget.set.printedTotal;
            }).toList();
          }

          if (_selectedRarities.isNotEmpty) {
            visibleCards = visibleCards.where((c) {
              final r = c.rarity.isEmpty ? 'Others' : c.rarity;
              return _selectedRarities.contains(r);
            }).toList();
          }

          if (_ownershipFilter == OwnershipFilter.owned) {
            visibleCards = visibleCards.where((c) => c.isOwned).toList();
          } else if (_ownershipFilter == OwnershipFilter.missing) {
            visibleCards = visibleCards.where((c) => !c.isOwned).toList();
          }

          // Text search filter
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            visibleCards = visibleCards.where((c) {
              final nameMatch = c.name.toLowerCase().contains(query);
              final nameDeMatch =
                  c.nameDe?.toLowerCase().contains(query) ?? false;
              final numberMatch = c.number.toLowerCase().contains(query);
              return nameMatch || nameDeMatch || numberMatch;
            }).toList();
          }

          // 2. Aggregate values
          double totalSetVal = 0.0;
          double userOwnedVal = 0.0;

          for (var card in allCards) {
            double price = card.cardmarket?.trendPrice ??
                card.tcgplayer?.prices?.normal?.market ??
                card.tcgplayer?.prices?.holofoil?.market ??
                card.tcgplayer?.prices?.reverseHolofoil?.market ??
                0.0;

            totalSetVal += price;
            if (card.isOwned) userOwnedVal += price;
          }

          return Column(
            children: [
              // Sticky header including set statistics, search bar, and filter options
              _buildHeader(context, allCards, totalSetVal, userOwnedVal),
              const Divider(height: 1),

              Expanded(
                child: visibleCards.isEmpty
                    ? const Center(
                        child: Text("Keine Karten für diesen Filter."))
                    : GridView.builder(
                        padding: const EdgeInsets.only(
                            left: 8, top: 8, right: 8, bottom: 100),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.70,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: visibleCards.length,
                        itemBuilder: (context, index) {
                          return _buildCardItem(
                              visibleCards[index], visibleCards[index].isOwned);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // UI sub-widgets

  Widget _buildHeader(BuildContext context, List<ApiCard> allCards,
      double totalValue, double ownedValue) {
    // Calculate set ownership statistics
    final int userOwnedMaster = allCards.where((c) => c.isOwned).length;
    final int totalCards = allCards.length;
    final double progress =
        totalCards > 0 ? (userOwnedMaster / totalCards) : 0.0;

    final int standardTotal = widget.set.printedTotal;
    final int userOwnedStandard = allCards.where((c) {
      final num = int.tryParse(c.number);
      return c.isOwned && num != null && num <= standardTotal;
    }).length;

    // Rarity frequency counts
    final Map<String, int> totalRarityCounts = {};
    final Map<String, int> ownedRarityCounts = {};

    for (var card in allCards) {
      final r = card.rarity.isEmpty ? 'Others' : card.rarity;
      totalRarityCounts[r] = (totalRarityCounts[r] ?? 0) + 1;
      if (card.isOwned) {
        ownedRarityCounts[r] = (ownedRarityCounts[r] ?? 0) + 1;
      }
    }

    // Sort rarities by configured rarity weight
    final sortedRarities = totalRarityCounts.keys.toList()
      ..sort((a, b) => _getRarityWeight(a).compareTo(_getRarityWeight(b)));

    final bool isMasterActive =
        !_showStandardSetOnly && _selectedRarities.isEmpty;
    final bool isStandardActive = _showStandardSetOnly;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final logoUrl = widget.set.logoUrlDe ?? widget.set.logoUrl;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: isDark
          ? const Color(0xFF1E293B)
          : Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.3),
      child: Column(
        children: [
          // 1. Logo & Progress
          Row(
            children: [
              if (logoUrl != null)
                SizedBox(
                  height: 45,
                  width: 80,
                  child: CachedNetworkImage(
                    imageUrl: logoUrl,
                    memCacheHeight: 200,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const SizedBox(),
                    errorWidget: (_, __, ___) => const SizedBox(),
                  ),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Gesammelt: $userOwnedMaster / $totalCards",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12)),
                        Text("${(progress * 100).toStringAsFixed(1)}%",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                                fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: isDark ? const Color(0xFF334155) : null,
                          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 2. Werte
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.savings_outlined, size: 14, color: Colors.green[700]),
              const SizedBox(width: 4),
              Text("Mein Wert: ",
                  style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF94A3B8) : Colors.grey[700])),
              Text("${ownedValue.toStringAsFixed(2)} €",
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.greenAccent : Colors.green[800])),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text("|",
                      style: TextStyle(
                          color: isDark ? const Color(0xFF475569) : Colors.grey[400],
                          fontSize: 12))),
              Icon(Icons.assessment_outlined,
                  size: 14,
                  color: isDark ? const Color(0xFF94A3B8) : Colors.grey[700]),
              const SizedBox(width: 4),
              Text("Gesamt: ",
                  style: TextStyle(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF94A3B8) : Colors.grey[700])),
              Text("${totalValue.toStringAsFixed(2)} €",
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87)),
            ],
          ),

          const SizedBox(height: 12),

          // 3. SET FILTER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFilterButton(
                label: "Master Set",
                countText: "$userOwnedMaster / $totalCards",
                isActive: isMasterActive,
                onTap: () => setState(() {
                  _selectedRarities.clear();
                  _showStandardSetOnly = false;
                }),
              ),
              _buildFilterButton(
                label: "Standard Set",
                countText: "$userOwnedStandard / ${widget.set.printedTotal}",
                isActive: isStandardActive,
                onTap: () => setState(() {
                  _selectedRarities.clear();
                  _showStandardSetOnly = true;
                }),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 4. Ownership filter and animated search bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: 32,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildToggleOption("Alle", OwnershipFilter.all),
                    _buildToggleOption("Im Besitz", OwnershipFilter.owned),
                    _buildToggleOption("Fehlend", OwnershipFilter.missing),
                  ],
                ),
              ),

              // Animated compact search trigger
              _buildCompactSearch(allCards),
            ],
          ),

          const SizedBox(height: 4),

          // 5. RARITÄTEN FILTER
          TextButton.icon(
            onPressed: () =>
                setState(() => _isRaritiesExpanded = !_isRaritiesExpanded),
            icon: Icon(
                _isRaritiesExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: 16,
                color: isDark ? const Color(0xFF94A3B8) : Colors.grey[700]),
            label: Text(
              _isRaritiesExpanded
                  ? "Weniger Filter"
                  : _selectedRarities.isEmpty
                      ? "Raritäten (${totalRarityCounts.length})"
                      : "Raritäten (${_selectedRarities.length} aktiv)",
              style: TextStyle(
                  color: isDark ? const Color(0xFFCBD5E1) : Colors.grey[800],
                  fontSize: 11),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),

          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isRaritiesExpanded
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      alignment: WrapAlignment.center,
                      children: sortedRarities.map((rarityName) {
                        final total = totalRarityCounts[rarityName] ?? 0;
                        final owned = ownedRarityCounts[rarityName] ?? 0;
                        final isSelected =
                            _selectedRarities.contains(rarityName);
                        final baseColor = _getRarityColor(rarityName);

                        return ActionChip(
                          label: Text('$rarityName: $owned/$total'),
                          visualDensity:
                              const VisualDensity(horizontal: -4, vertical: -4),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          labelPadding:
                              const EdgeInsets.symmetric(horizontal: 6),
                          padding: EdgeInsets.zero,
                          backgroundColor: isSelected
                              ? baseColor
                              : (isDark
                                  ? baseColor.withValues(alpha: 0.22)
                                  : baseColor.withValues(alpha: 0.12)),
                          side: BorderSide(
                            color: isSelected
                                ? (isDark ? Colors.white : baseColor)
                                : baseColor.withValues(alpha: isDark ? 0.7 : 0.45),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                          labelStyle: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? const Color(0xFFF1F5F9)
                                    : const Color(0xFF0F172A)),
                          ),
                          onPressed: () {
                            setState(() {
                              _showStandardSetOnly = false;
                              if (_selectedRarities.contains(rarityName)) {
                                _selectedRarities.remove(rarityName);
                              } else {
                                _selectedRarities.add(rarityName);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String text, OwnershipFilter value) {
    final bool isSelected = _ownershipFilter == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _ownershipFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF334155) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: isSelected
              ? [const BoxShadow(color: Colors.black12, blurRadius: 2)]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? (isDark ? Colors.white : Colors.black)
                : (isDark ? const Color(0xFF94A3B8) : Colors.grey[700]),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(
      {required String label,
      required String countText,
      required bool isActive,
      required VoidCallback onTap}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? primaryColor.withValues(alpha: 0.15) : null,
          border: isActive
              ? Border.all(color: primaryColor)
              : Border.all(color: Colors.transparent),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(countText,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isActive ? primaryColor : (isDark ? Colors.white : Colors.black))),
            Text(label,
                style: TextStyle(
                    color: isActive ? primaryColor : (isDark ? const Color(0xFF94A3B8) : Colors.grey[600]),
                    fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildCardItem(ApiCard card, bool isOwned) {
    double? displayPrice = card.cardmarket?.trendPrice;
    if (displayPrice == null || displayPrice == 0) {
      displayPrice = card.tcgplayer?.prices?.normal?.market ??
          card.tcgplayer?.prices?.holofoil?.market ??
          card.tcgplayer?.prices?.reverseHolofoil?.market;
    }

    return RepaintBoundary(
      child: InkWell(
        onTap: () {
          Navigator.push(context,
                  MaterialPageRoute(builder: (_) => CardDetailScreen(card: card)))
              .then((_) => ref.invalidate(cardsForSetProvider(widget.set.id)));
        },
        onLongPress: () async {
          await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => InventoryBottomSheet(card: card));
          ref.invalidate(cardsForSetProvider(widget.set.id));
          ref.invalidate(allSetStatsProvider);
        },
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              tween: Tween<double>(begin: 0, end: isOwned ? 1.0 : 0.0),
              builder: (context, saturation, child) {
                return ColorFiltered(
                  colorFilter: ColorFilter.matrix(<double>[
                    0.2126 + 0.7874 * saturation,
                    0.7152 - 0.7152 * saturation,
                    0.0722 - 0.0722 * saturation,
                    0,
                    0,
                    0.2126 - 0.2126 * saturation,
                    0.7152 + 0.2848 * saturation,
                    0.0722 - 0.0722 * saturation,
                    0,
                    0,
                    0.2126 - 0.2126 * saturation,
                    0.7152 - 0.7152 * saturation,
                    0.0722 + 0.9278 * saturation,
                    0,
                    0,
                    0,
                    0,
                    0,
                    1,
                    0,
                  ]),
                  child: Opacity(opacity: isOwned ? 1.0 : 0.6, child: child),
                );
              },
              child: CardImageWidget.fromApiCard(
                card: card,
                memCacheHeight: 200,
                memCacheWidth: 160,
                fit: BoxFit.cover,
                placeholder: Container(color: Colors.grey[200]),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black.withValues(alpha: 0.7),
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(card.number,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                    if (displayPrice != null && displayPrice > 0)
                      Text('${displayPrice.toStringAsFixed(2)}€',
                          style: const TextStyle(
                              color: Colors.lightGreenAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            if (!isOwned)
              Positioned.fill(
                  child: Center(
                      child: Icon(Icons.lock_outline,
                          color: Colors.white.withValues(alpha: 0.5),
                          size: 32))),
          ],
        ),
      ),
    ),
  );
}

  // --- Helper (lokal) ---
  int _getRarityWeight(String rarity) {
    final r = rarity.toLowerCase();
    if (r == 'common') return 1;
    if (r == 'uncommon') return 2;
    if (r == 'rare') return 3;
    if (r.contains('holo rare')) return 4;
    if (r.contains('double rare')) return 5;
    if (r == 'ultra rare') return 6;
    if (r.contains('illustration rare')) return 7;
    if (r.contains('special illustration')) return 8;
    if (r.contains('secret')) return 9;
    if (r.contains('hyper')) return 10;
    return 50;
  }

  Color _getRarityColor(String rarity) {
    final r = rarity.toLowerCase();
    if (r.contains('secret') || r.contains('hyper') || r.contains('rainbow')) {
      return const Color(0xFFF59E0B); // Amber / Gold
    }
    if (r.contains('special illustration') || r.contains('illustration')) {
      return const Color(0xFFEC4899); // Vibrant Pink / Magenta
    }
    if (r.contains('ultra') || r.contains('shiny') || r.contains('ace')) {
      return const Color(0xFF06B6D4); // Vibrant Cyan / Teal
    }
    if (r.contains('double')) {
      return const Color(0xFF8B5CF6); // Vibrant Purple / Violet
    }
    if (r.contains('rare')) {
      return const Color(0xFF3B82F6); // Vibrant Blue
    }
    if (r.contains('uncommon')) {
      return const Color(0xFF64748B); // Slate
    }
    return const Color(0xFF94A3B8); // Light Slate / Common
  }

  // Compact animated search widget
  Widget _buildCompactSearch(List<ApiCard> cards) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      // Collapsed: 32px icon button; Expanded: 160px text field
      width: _isSearchExpanded ? 160 : 32,
      height: 32,
      child: _isSearchExpanded
          ? LayoutBuilder(
              builder: (context, constraints) => RawAutocomplete<String>(
                textEditingController: _searchController,
                focusNode: _searchFocusNode,
                optionsBuilder: (TextEditingValue textEditingValue) {
                  final query = textEditingValue.text.trim().toLowerCase();
                  if (query.isEmpty) return const Iterable<String>.empty();

                  final Set<String> results = {};
                  for (var card in cards) {
                    if (card.nameDe != null &&
                        card.nameDe!.toLowerCase().contains(query)) {
                      results.add(card.nameDe!);
                    } else if (card.name.toLowerCase().contains(query)) {
                      results.add(card.name);
                    }
                    if (card.number.toLowerCase().contains(query)) {
                      results.add(card.number);
                    }
                  }
                  return results.take(5);
                },
                onSelected: (String selection) {
                  setState(() => _searchQuery = selection);
                  _searchFocusNode.unfocus();
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    autofocus: true,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: "Suchen...",
                      prefixIcon: Icon(Icons.search,
                          size: 16,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF94A3B8)
                              : Colors.grey),
                      suffixIcon: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.close,
                            size: 16,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF94A3B8)
                                : Colors.grey),
                        onPressed: () {
                          setState(() {
                            _isSearchExpanded = false;
                            _searchQuery = '';
                            controller.clear();
                          });
                          focusNode.unfocus();
                        },
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      isDense: true,
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF0F172A)
                          : Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
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
                      color: Theme.of(context).cardColor,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                            maxHeight: 200, maxWidth: constraints.maxWidth),
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: Theme.of(context).dividerColor),
                          itemBuilder: (context, index) {
                            final option = options.elementAt(index);
                            return ListTile(
                              title: Text(option,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
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
            )
          : InkWell(
              onTap: () {
                setState(() => _isSearchExpanded = true);
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF0F172A)
                      : Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search,
                  size: 18,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF94A3B8)
                      : Colors.black87,
                ),
              ),
            ),
    );
  }
}
