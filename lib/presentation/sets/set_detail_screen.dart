import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/api/search_provider.dart';
import '../../domain/models/api_card.dart';
import '../../domain/models/api_set.dart';
import '../cards/card_detail_screen.dart'; // Pfad anpassen falls nötig

class SetDetailScreen extends ConsumerStatefulWidget {
  final ApiSet set;

  const SetDetailScreen({super.key, required this.set});

  @override
  ConsumerState<SetDetailScreen> createState() => _SetDetailScreenState();
}

class _SetDetailScreenState extends ConsumerState<SetDetailScreen> {
  final Set<String> _selectedRarities = {};
  bool _showStandardSetOnly = false;
  
  // NEU: Steuert, ob die Raritäten-Liste sichtbar ist
  bool _isRaritiesExpanded = false;

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
          if (rawCards.isEmpty) {
            return const Center(child: Text("Keine Karten gefunden."));
          }

          // 1. SORTIEREN
          final List<ApiCard> allSortedCards = List.from(rawCards);
          allSortedCards.sort((a, b) => _compareCardNumbers(a.number, b.number));

          // 2. FILTERN
          List<ApiCard> visibleCards = allSortedCards;

          if (_showStandardSetOnly) {
            visibleCards = allSortedCards.where((c) {
              final num = int.tryParse(c.number);
              return num != null && num <= widget.set.printedTotal;
            }).toList();
          } else if (_selectedRarities.isNotEmpty) {
            visibleCards = allSortedCards.where((c) {
              final r = c.rarity.isEmpty ? 'Others' : c.rarity;
              return _selectedRarities.contains(r);
            }).toList();
          }

          // 3. WERTE
          double totalSetVal = 0.0;
          double userOwnedVal = 0.0;

          for (var card in visibleCards) {
            final price = card.priceEur ?? 0.0;
            totalSetVal += price;
            // Platzhalter für Besitz
            bool isOwned = false; 
            if (isOwned) userOwnedVal += price;
          }

          return Column(
            children: [
              // HEADER
              _buildHeader(context, allSortedCards, totalSetVal, userOwnedVal),
              
              const Divider(height: 1),

              // GRID
              Expanded(
                child: visibleCards.isEmpty 
                  ? const Center(child: Text("Keine Karten für diesen Filter."))
                  : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: visibleCards.length,
                    itemBuilder: (context, index) {
                      final card = visibleCards[index];
                      
                      // --- FAKE LOGIK (Später durch Datenbank-Check ersetzen) ---
                      // Jede Karte mit gerader Nummer (0, 2, 4) gehört uns -> Bunt
                      // Die ungeraden gehören uns nicht -> Grau
                      final bool isOwnedFake = false; 
                      
                      // Wir geben "isOwnedFake" an die Funktion weiter
                      return _buildCardItem(card, isOwnedFake);
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
    // Raritäten vorbereiten
    final Map<String, int> totalRarityCounts = {};
    for (var card in allCards) {
      final r = card.rarity.isEmpty ? 'Others' : card.rarity;
      totalRarityCounts[r] = (totalRarityCounts[r] ?? 0) + 1;
    }
    final sortedRarities = totalRarityCounts.keys.toList()
      ..sort((a, b) => _getRarityWeight(a).compareTo(_getRarityWeight(b)));

    const int userOwnedMaster = 0;
    final int totalCards = allCards.length;
    final double progress = totalCards > 0 ? (userOwnedMaster / totalCards) : 0.0;
    final String percentage = (progress * 100).toStringAsFixed(1);

    const int userOwnedStandard = 0;
    final bool isMasterActive = !_showStandardSetOnly && _selectedRarities.isEmpty;
    final bool isStandardActive = _showStandardSetOnly;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      child: Column(
        children: [
          // 1. LOGO (Etwas kleiner)
          SizedBox(
            height: 45, // War vorher 50-60
            child: CachedNetworkImage(
              imageUrl: widget.set.logoUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => const SizedBox(),
              errorWidget: (context, url, error) => const Icon(Icons.broken_image),
            ),
          ),
          
          const SizedBox(height: 8),

          // 2. PROGRESS BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Gesammelt: $userOwnedMaster / $totalCards", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    Text("$percentage%", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6, // Etwas feiner
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 3. WERTE (KOMPAKT & EINZEILIG)
          // Hier ist die große Änderung: Alles in einer Zeile
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Mein Wert
              Icon(Icons.savings_outlined, size: 14, color: Colors.green[700]),
              const SizedBox(width: 4),
              Text(
                "Mein Wert: ", 
                style: TextStyle(fontSize: 11, color: Colors.grey[700]),
              ),
              Text(
                "${ownedValue.toStringAsFixed(2)} €",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green[800]),
              ),

              // Trennstrich
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text("|", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ),

              // Gesamtwert
              Icon(Icons.assessment_outlined, size: 14, color: Colors.grey[700]),
              const SizedBox(width: 4),
              Text(
                "Gesamt: ", 
                style: TextStyle(fontSize: 11, color: Colors.grey[700]),
              ),
              Text(
                "${totalValue.toStringAsFixed(2)} €",
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),

          const SizedBox(height: 12),
          
          // 4. HAUPT-BUTTONS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFilterButton(
                label: "Master Set",
                countText: "$userOwnedMaster / ${allCards.length}",
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
          
          // 5. KLAPP-BUTTON
          TextButton.icon(
            onPressed: () => setState(() => _isRaritiesExpanded = !_isRaritiesExpanded),
            icon: Icon(
              _isRaritiesExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 18,
              color: Colors.grey[700],
            ),
            label: Text(
              _isRaritiesExpanded 
                  ? "Weniger Filter" 
                  : _selectedRarities.isEmpty 
                      ? "Filter (${totalRarityCounts.length})"
                      : "Filter (${_selectedRarities.length} aktiv)",
              style: TextStyle(color: Colors.grey[800], fontSize: 11),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8), // Weniger Padding
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),

          // 6. RARITÄTEN LISTE
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isRaritiesExpanded 
              ? Padding(
                  padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: sortedRarities.map((rarityName) {
                      final count = totalRarityCounts[rarityName];
                      final isSelected = _selectedRarities.contains(rarityName);
                      return ActionChip(
                        label: Text('$rarityName: 0 / $count'), 
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        backgroundColor: isSelected 
                            ? _getRarityColor(rarityName)?.withOpacity(0.8) 
                            : _getRarityColor(rarityName),
                        side: isSelected 
                            ? const BorderSide(color: Colors.black54, width: 1.5) 
                            : BorderSide.none,
                        labelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.black : Colors.black87),
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

  // --- HILFSFUNKTIONEN ---

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

 // Update: Nimmt jetzt 'isOwned' entgegen
  Widget _buildCardItem(ApiCard card, bool isOwned) {
    return InkWell( // <--- HIER UMWICKELN
      onTap: () {
         Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CardDetailScreen(card: card),
          ),
        );
      },
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. DAS BILD (Mit "Ausgegraut"-Effekt, wenn nicht im Besitz)
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              tween: Tween<double>(begin: 0, end: isOwned ? 1.0 : 0.0),
              builder: (context, saturation, child) {
                // Dieser Filter macht das Bild schwarz-weiß, wenn saturation 0 ist
                return ColorFiltered(
                  colorFilter: ColorFilter.matrix(<double>[
                    0.2126 + 0.7874 * saturation, 0.7152 - 0.7152 * saturation, 0.0722 - 0.0722 * saturation, 0, 0,
                    0.2126 - 0.2126 * saturation, 0.7152 + 0.2848 * saturation, 0.0722 - 0.0722 * saturation, 0, 0,
                    0.2126 - 0.2126 * saturation, 0.7152 - 0.7152 * saturation, 0.0722 + 0.9278 * saturation, 0, 0,
                    0, 0, 0, 1, 0,
                  ]),
                  // Zusätzlich machen wir es etwas durchsichtiger, wenn nicht im Besitz
                  child: Opacity(
                    opacity: isOwned ? 1.0 : 0.5, 
                    child: child,
                  ),
                );
              },
              child: CachedNetworkImage(
                imageUrl: card.smallImageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey[200]),
                errorWidget: (context, url, error) => const Icon(Icons.broken_image),
              ),
            ),
            
            // 2. SCHWARZER BALKEN (Nummer & Preis)
            // Den zeigen wir vielleicht auch nur an, wenn man die Karte besitzt?
            // Oder wir lassen ihn, damit man sieht, was sie wert WÄRE.
            // Ich lasse ihn erstmal da, aber mache ihn auch etwas blasser.
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Opacity(
                opacity: isOwned ? 1.0 : 0.7, // Balken auch leicht ausgrauen
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(card.number, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      if (card.priceEur != null)
                        Text('${card.priceEur!.toStringAsFixed(2)}€', style: const TextStyle(color: Colors.lightGreenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),

            // 3. OPTIONAL: Ein Schloss-Icon für nicht-besessene Karten
            if (!isOwned)
              Positioned.fill(
                child: Center(
                  child: Icon(Icons.lock_outline, color: Colors.white.withOpacity(0.5), size: 32),
                ),
              ),
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