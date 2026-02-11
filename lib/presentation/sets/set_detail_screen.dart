import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api/search_provider.dart';
import '../../domain/models/api_card.dart';
import '../../domain/models/api_set.dart';
import '../cards/card_detail_screen.dart';
import '../inventory/inventory_bottom_sheet.dart';

// Enum für den Besitz-Filter
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

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(cardsForSetProvider(widget.set.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.set.name),
        centerTitle: true,
      ),
      body: cardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Fehler: $err')),
        data: (rawCards) {
          if (rawCards.isEmpty) return const Center(child: Text("Keine Karten gefunden."));

          // 1. SORTIEREN
          final List<ApiCard> allSortedCards = List.from(rawCards);
          allSortedCards.sort((a, b) => _compareCardNumbers(a.number, b.number));

          // 2. FILTERN
          List<ApiCard> visibleCards = allSortedCards;

          // A) Standard vs Master Set
          if (_showStandardSetOnly) {
            visibleCards = visibleCards.where((c) {
              final num = int.tryParse(c.number);
              return num != null && num <= widget.set.printedTotal;
            }).toList();
          }

          // B) Raritäten
          if (_selectedRarities.isNotEmpty) {
            visibleCards = visibleCards.where((c) {
              final r = c.rarity.isEmpty ? 'Others' : c.rarity;
              return _selectedRarities.contains(r);
            }).toList();
          }

          // C) Besitz-Filter
          if (_ownershipFilter == OwnershipFilter.owned) {
            visibleCards = visibleCards.where((c) => c.isOwned).toList();
          } else if (_ownershipFilter == OwnershipFilter.missing) {
            visibleCards = visibleCards.where((c) => !c.isOwned).toList();
          }

          // 3. WERTE BERECHNEN (Auf Basis aller Karten)
          double totalSetVal = 0.0;
          double userOwnedVal = 0.0;

          for (var card in allSortedCards) {
            // HIER IST DIE LOGIK AUCH WICHTIG FÜR DIE GESAMT-BERECHNUNG:
            double price = card.cardmarket?.trendPrice ?? 0.0;
            if (price == 0) {
               // Fallback auf TCGPlayer
               price = card.tcgplayer?.prices?.normal?.market ??
                       card.tcgplayer?.prices?.holofoil?.market ??
                       card.tcgplayer?.prices?.reverseHolofoil?.market ?? 0.0;
            }

            totalSetVal += price;
            if (card.isOwned) userOwnedVal += price;
          }

          return Column(
            children: [
              _buildHeader(context, allSortedCards, totalSetVal, userOwnedVal),
              const Divider(height: 1),
              Expanded(
                child: visibleCards.isEmpty 
                  ? const Center(child: Text("Keine Karten für diesen Filter."))
                  : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.70,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: visibleCards.length,
                    itemBuilder: (context, index) {
                      final card = visibleCards[index];
                      return _buildCardItem(card, card.isOwned);
                    },
                  ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- UI KOMPONENTEN ---

  Widget _buildHeader(BuildContext context, List<ApiCard> allCards, double totalValue, double ownedValue) {
    final int userOwnedMaster = allCards.where((c) => c.isOwned).length;
    final int totalCards = allCards.length;
    final double progress = totalCards > 0 ? (userOwnedMaster / totalCards) : 0.0;
    
    final int standardTotal = widget.set.printedTotal;
    final int userOwnedStandard = allCards.where((c) {
      final num = int.tryParse(c.number);
      return c.isOwned && num != null && num <= standardTotal;
    }).length;

    final Map<String, int> totalRarityCounts = {};
    final Map<String, int> ownedRarityCounts = {};

    for (var card in allCards) {
      final r = card.rarity.isEmpty ? 'Others' : card.rarity;
      totalRarityCounts[r] = (totalRarityCounts[r] ?? 0) + 1;
      if (card.isOwned) {
        ownedRarityCounts[r] = (ownedRarityCounts[r] ?? 0) + 1;
      }
    }
    final sortedRarities = totalRarityCounts.keys.toList()
      ..sort((a, b) => _getRarityWeight(a).compareTo(_getRarityWeight(b)));

    final bool isMasterActive = !_showStandardSetOnly && _selectedRarities.isEmpty;
    final bool isStandardActive = _showStandardSetOnly;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      child: Column(
        children: [
          // 1. Logo & Progress
          Row(
            children: [
              SizedBox(
                height: 45, width: 80,
                child: CachedNetworkImage(imageUrl: widget.set.logoUrl, fit: BoxFit.contain),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Gesammelt: $userOwnedMaster / $totalCards", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text("${(progress * 100).toStringAsFixed(1)}%", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(value: progress, minHeight: 8, borderRadius: BorderRadius.circular(8)),
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
              Text("Mein Wert: ", style: TextStyle(fontSize: 11, color: Colors.grey[700])),
              Text("${ownedValue.toStringAsFixed(2)} €", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green[800])),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 12.0), child: Text("|", style: TextStyle(color: Colors.grey[400], fontSize: 12))),
              Icon(Icons.assessment_outlined, size: 14, color: Colors.grey[700]),
              const SizedBox(width: 4),
              Text("Gesamt: ", style: TextStyle(fontSize: 11, color: Colors.grey[700])),
              Text("${totalValue.toStringAsFixed(2)} €", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),

          const SizedBox(height: 12),
          
          // 3. SET FILTER (Master vs Standard)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFilterButton(
                label: "Master Set",
                countText: "$userOwnedMaster / $totalCards",
                isActive: isMasterActive,
                onTap: () => setState(() { _selectedRarities.clear(); _showStandardSetOnly = false; }),
              ),
              _buildFilterButton(
                label: "Standard Set",
                countText: "$userOwnedStandard / ${widget.set.printedTotal}",
                isActive: isStandardActive,
                onTap: () => setState(() { _selectedRarities.clear(); _showStandardSetOnly = true; }),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 4. BESITZ FILTER
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey[200],
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
          
          // 5. RARITÄTEN FILTER
          TextButton.icon(
            onPressed: () => setState(() => _isRaritiesExpanded = !_isRaritiesExpanded),
            icon: Icon(_isRaritiesExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 16, color: Colors.grey[700]),
            label: Text(
              _isRaritiesExpanded 
                  ? "Weniger Filter" 
                  : _selectedRarities.isEmpty 
                      ? "Raritäten (${totalRarityCounts.length})"
                      : "Raritäten (${_selectedRarities.length} aktiv)",
              style: TextStyle(color: Colors.grey[800], fontSize: 11),
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
                      final isSelected = _selectedRarities.contains(rarityName);
                      
                      return ActionChip(
                        label: Text('$rarityName: $owned/$total'), 
                        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                        padding: EdgeInsets.zero,
                        backgroundColor: isSelected 
                            ? _getRarityColor(rarityName)?.withOpacity(0.8) 
                            : _getRarityColor(rarityName),
                        side: isSelected 
                            ? const BorderSide(color: Colors.black54, width: 1.0) 
                            : BorderSide.none,
                        labelStyle: TextStyle(
                          fontSize: 9, 
                          fontWeight: FontWeight.bold, 
                          color: isSelected ? Colors.black : Colors.black87
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
    return GestureDetector(
      onTap: () => setState(() => _ownershipFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: isSelected ? [const BoxShadow(color: Colors.black12, blurRadius: 2)] : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.black : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton({required String label, required String countText, required bool isActive, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.blueAccent.withOpacity(0.1) : null,
          border: isActive ? Border.all(color: Colors.blueAccent) : Border.all(color: Colors.transparent),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(countText, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isActive ? Colors.blueAccent : Colors.black)),
            Text(label, style: TextStyle(color: isActive ? Colors.blueAccent : Colors.grey[600], fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // --- PREIS-PRIORITÄT HIER ---
  Widget _buildCardItem(ApiCard card, bool isOwned) {
    // 1. Cardmarket Trend
    double? displayPrice = card.cardmarket?.trendPrice;
    
    // 2. Fallback: TCGPlayer (Normal -> Holo -> Reverse)
    if (displayPrice == null || displayPrice == 0) {
      final tcg = card.tcgplayer?.prices;
      if (tcg != null) {
        displayPrice = tcg.normal?.market ?? 
                       tcg.holofoil?.market ?? 
                       tcg.reverseHolofoil?.market;
      }
    }

    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => CardDetailScreen(card: card)))
          .then((_) => ref.refresh(cardsForSetProvider(widget.set.id))); 
      },
      onLongPress: () async {
        await showModalBottomSheet(
          context: context, 
          isScrollControlled: true,
          builder: (_) => InventoryBottomSheet(card: card)
        );
        ref.invalidate(cardsForSetProvider(widget.set.id));
        ref.invalidate(setStatsProvider(widget.set.id)); // Auch Set-Liste updaten
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
                    0.2126 + 0.7874 * saturation, 0.7152 - 0.7152 * saturation, 0.0722 - 0.0722 * saturation, 0, 0,
                    0.2126 - 0.2126 * saturation, 0.7152 + 0.2848 * saturation, 0.0722 - 0.0722 * saturation, 0, 0,
                    0.2126 - 0.2126 * saturation, 0.7152 - 0.7152 * saturation, 0.0722 + 0.9278 * saturation, 0, 0,
                    0, 0, 0, 1, 0,
                  ]),
                  child: Opacity(opacity: isOwned ? 1.0 : 0.5, child: child),
                );
              },
              child: CachedNetworkImage(imageUrl: card.smallImageUrl, fit: BoxFit.cover, placeholder: (context, url) => Container(color: Colors.grey[200]), errorWidget: (context, url, error) => const Icon(Icons.broken_image)),
            ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Opacity(
                opacity: isOwned ? 1.0 : 0.7,
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(card.number, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      // ANZEIGE DES BERECHNETEN PREISES
                      if (displayPrice != null && displayPrice > 0)
                        Text('${displayPrice.toStringAsFixed(2)}€', style: const TextStyle(color: Colors.lightGreenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            if (!isOwned)
              Positioned.fill(child: Center(child: Icon(Icons.lock_outline, color: Colors.white.withOpacity(0.5), size: 32))),
          ],
        ),
      ),
    );
  }

  int _compareCardNumbers(String a, String b) {
    final intA = int.tryParse(a);
    final intB = int.tryParse(b);
    if (intA != null && intB != null) return intA.compareTo(intB);
    return a.compareTo(b);
  }

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

  Color? _getRarityColor(String rarity) {
    final r = rarity.toLowerCase();
    if (r.contains('secret') || r.contains('hyper')) return Colors.amber.withOpacity(0.4);
    if (r.contains('illustration')) return Colors.pinkAccent.withOpacity(0.2);
    if (r.contains('ultra')) return Colors.cyan.withOpacity(0.2);
    if (r.contains('double')) return Colors.indigo.withOpacity(0.2);
    if (r.contains('rare')) return Colors.blue.withOpacity(0.2);
    if (r.contains('uncommon')) return Colors.grey.withOpacity(0.3);
    if (r.contains('common')) return Colors.grey.withOpacity(0.1);
    return Colors.grey.withOpacity(0.1);
  }
}