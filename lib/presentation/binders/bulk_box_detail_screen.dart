import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:drift/drift.dart' as drift;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../data/database/app_database.dart';
import '../../data/database/database_provider.dart';
import '../../domain/logic/binder_service.dart';
import '../../domain/models/api_card.dart';
import '../search/card_search_screen.dart';
import 'binder_detail_provider.dart';

class BulkBoxDetailScreen extends ConsumerStatefulWidget {
  final Binder binder;
  const BulkBoxDetailScreen({super.key, required this.binder});

  @override
  ConsumerState<BulkBoxDetailScreen> createState() => _BulkBoxDetailScreenState();
}

class _BulkBoxDetailScreenState extends ConsumerState<BulkBoxDetailScreen> {
  final _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isSwapMode = false;
  BinderSlotData? _slotToSwap;

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(binderDetailProvider(widget.binder.id));

    return Scaffold(
      backgroundColor: Colors.grey[100], 
      appBar: AppBar(
        title: Text(widget.binder.name),
        backgroundColor: widget.binder.isFull ? Colors.grey[700] : Color(widget.binder.color),
        foregroundColor: Colors.white,
        actions: [
          Row(
            children: [
              const Text("Voll", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Switch(
                value: widget.binder.isFull,
                activeColor: Colors.redAccent,
                onChanged: (val) async {
                  final db = ref.read(databaseProvider);
                  await BinderService(db).toggleBinderFullStatus(widget.binder.id, val);
                  if (mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
          // --- SORTIEREN ---
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortDialog(context),
          ),
          // --- SUCHEN ---
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context, asyncData.asData?.value),
          ),
          // --- GRAPH / STATS ---
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () => _showStats(context, asyncData.asData?.value),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMenu(context),
        backgroundColor: widget.binder.isFull ? Colors.grey : Color(widget.binder.color),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          if (_isSwapMode && _slotToSwap != null)
            Container(
              width: double.infinity,
              color: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.swap_vert, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Wähle das Ziel für '${_getSlotName(_slotToSwap!)}'...",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => setState(() {
                      _isSwapMode = false;
                      _slotToSwap = null;
                    }),
                  )
                ],
              ),
            ),
            
          Expanded(
            child: asyncData.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text("Fehler: $e")),
              data: (state) {
                if (state.slots.isEmpty) {
                  return const Center(
                    child: Text("Box ist leer.\nTippe auf + um Karten oder Trenner hinzuzufügen.", 
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 80, top: 8),
                  itemCount: state.slots.length,
                  itemBuilder: (context, index) {
                    final slot = state.slots[index];
                    final isDivider = slot.binderCard.isPlaceholder && (slot.binderCard.placeholderLabel?.startsWith("DIVIDER:") ?? false);
                    final isHighlighted = _isSwapMode && _slotToSwap?.binderCard.id == slot.binderCard.id;

                    return _buildListItem(slot, isDivider, isHighlighted);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET FÜR EIN LISTEN-ELEMENT ---
  Widget _buildListItem(BinderSlotData slot, bool isDivider, bool isHighlighted) {
    if (isDivider) {
      final title = slot.binderCard.placeholderLabel!.replaceAll("DIVIDER:", "");
      return GestureDetector(
        onTap: () => _handleItemTap(slot),
        onLongPress: () => _handleItemLongPress(slot),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Color(widget.binder.color).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isHighlighted ? Colors.redAccent : Color(widget.binder.color), 
              width: isHighlighted ? 3 : 2
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.label, color: Color(widget.binder.color)),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey[800]))),
            ],
          ),
        ),
      );
    }

    final card = slot.card;
    return GestureDetector(
      onTap: () => _handleItemTap(slot),
      onLongPress: () => _handleItemLongPress(slot),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isHighlighted ? Border.all(color: Colors.redAccent, width: 3) : Border.all(color: Colors.grey[200]!),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 50, height: 70,
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
              child: card != null 
                ? CachedNetworkImage(
                    imageUrl: card.imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const SizedBox(),
                    errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 20, color: Colors.grey),
                  )
                : const Icon(Icons.credit_card, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(card?.nameDe ?? card?.name ?? "Unbekannt", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                        child: Text(slot.binderCard.variant ?? "Normal", style: TextStyle(fontSize: 10, color: Colors.grey[800])),
                      ),
                      const SizedBox(width: 8),
                      Text(card?.number ?? "", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            Text("${slot.marketPrice.toStringAsFixed(2)} €", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        ),
      ),
    );
  }

  String _getSlotName(BinderSlotData slot) {
    if (slot.binderCard.isPlaceholder && (slot.binderCard.placeholderLabel?.startsWith("DIVIDER:") ?? false)) {
      return "Trenner: ${slot.binderCard.placeholderLabel!.replaceAll('DIVIDER:', '')}";
    }
    return slot.card?.nameDe ?? slot.card?.name ?? "Karte";
  }

  void _showSortDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Box sortieren"),
        content: const Text("Wie sollen die Karten (innerhalb ihrer Trenn-Kategorien) sortiert werden?"),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(ctx); _sortBox('type'); },
            child: const Text("Element / Typ"),
          ),
          TextButton(
            onPressed: () { Navigator.pop(ctx); _sortBox('name'); },
            child: const Text("Name (A-Z)"),
          ),
          TextButton(
            onPressed: () { Navigator.pop(ctx); _sortBox('number'); },
            child: const Text("Nummer"),
          ),
          // --- NEU ---
          TextButton(
            onPressed: () { Navigator.pop(ctx); _sortBox('rarity'); },
            child: const Text("Seltenheit"),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Abbrechen", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Future<void> _sortBox(String mode) async {
     final db = ref.read(databaseProvider);
     await BinderService(db).sortBulkBox(widget.binder.id, mode);
     if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Box erfolgreich sortiert!")));
        ref.invalidate(binderDetailProvider(widget.binder.id));
     }
  }

  void _showAddMenu(BuildContext context) {
    if (widget.binder.isFull) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Die Box ist voll!"), backgroundColor: Colors.red));
       return;
    }

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text("Hinzufügen", style: TextStyle(fontWeight: FontWeight.bold))),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add_photo_alternate, color: Colors.green),
              title: const Text("Karte hinzufügen"),
              onTap: () {
                Navigator.pop(ctx);
                _pickCardForBulk(onlyOwned: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.label, color: Colors.orange),
              title: const Text("Trennkarte (Divider) einfügen"),
              onTap: () {
                Navigator.pop(ctx);
                _addDividerDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addDividerDialog() {
    final tc = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Trenner Name"),
        content: TextField(controller: tc, autofocus: true, decoration: const InputDecoration(hintText: "z.B. Holos, Bulk, Feuer Pokémon...")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Abbrechen")),
          FilledButton(onPressed: () async {
            if (tc.text.isNotEmpty) {
              final db = ref.read(databaseProvider);
              await BinderService(db).addBulkDivider(widget.binder.id, tc.text);
              if (mounted) ref.invalidate(binderDetailProvider(widget.binder.id));
            }
            if (ctx.mounted) Navigator.pop(ctx);
          }, child: const Text("Hinzufügen")),
        ],
      ),
    );
  }

  void _handleItemTap(BinderSlotData slot) async {
    if (_isSwapMode && _slotToSwap != null) {
       final db = ref.read(databaseProvider);
       await BinderService(db).swapTwoSlots(widget.binder.id, _slotToSwap!.binderCard.id, slot.binderCard.id);
       if (mounted) {
         setState(() { _isSwapMode = false; _slotToSwap = null; });
         ref.invalidate(binderDetailProvider(widget.binder.id));
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Erfolgreich getauscht!")));
       }
       return;
    }
    _handleItemLongPress(slot);
  }

  void _handleItemLongPress(BinderSlotData slot) {
    if (_isSwapMode) return;
    
    final isDivider = slot.binderCard.isPlaceholder && (slot.binderCard.placeholderLabel?.startsWith("DIVIDER:") ?? false);

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(isDivider ? "Trenner bearbeiten" : "Karte bearbeiten", style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(_getSlotName(slot)),
            ),
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.swap_vert, color: Colors.orange),
              title: const Text("Tauschen / Verschieben"),
              subtitle: const Text("Tippe danach auf die Ziel-Position"),
              onTap: () {
                Navigator.pop(ctx);
                setState(() { _isSwapMode = true; _slotToSwap = slot; });
              },
            ),

            ListTile(
              leading: const Icon(Icons.arrow_upward, color: Colors.purple),
              title: const Text("Eins nach oben rücken"),
              onTap: () async {
                Navigator.pop(ctx);
                final db = ref.read(databaseProvider);
                await BinderService(db).moveSlotLeft(widget.binder.id, slot.binderCard.id); 
                if (mounted) ref.invalidate(binderDetailProvider(widget.binder.id));
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.arrow_downward, color: Colors.purple),
              title: const Text("Eins nach unten rücken"),
              onTap: () async {
                Navigator.pop(ctx);
                final db = ref.read(databaseProvider);
                await BinderService(db).moveSlotRight(widget.binder.id, slot.binderCard.id); 
                if (mounted) ref.invalidate(binderDetailProvider(widget.binder.id));
              },
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text("Aus Box löschen", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: () async {
                Navigator.pop(ctx);
                final db = ref.read(databaseProvider);
                await BinderService(db).deleteSlotAndShift(widget.binder.id, slot.binderCard.id);
                if (mounted) ref.invalidate(binderDetailProvider(widget.binder.id));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCardForBulk({required bool onlyOwned}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CardSearchScreen(initialQuery: "", pickerMode: true, onlyOwned: onlyOwned)),
    );

    if (result != null && result is ApiCard) { 
      final ApiCard pickedCard = result;
      final db = ref.read(databaseProvider);
      final service = BinderService(db);
      
      try {
        await db.into(db.cards).insertOnConflictUpdate(
          CardsCompanion(
            id: drift.Value(pickedCard.id),
            setId: drift.Value(pickedCard.setId),
            name: drift.Value(pickedCard.name),
            nameDe: drift.Value(pickedCard.nameDe),
            number: drift.Value(pickedCard.number),
            imageUrl: drift.Value(pickedCard.smallImageUrl),
            imageUrlDe: drift.Value(pickedCard.imageUrlDe ?? pickedCard.smallImageUrl),
            rarity: drift.Value(pickedCard.rarity),
          )
        );

        final availableVariants = await service.getAvailableVariantsForCard(pickedCard.id);

        if (availableVariants.isEmpty) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Keine freie Karte im Inventar.")));
          return; 
        }

        String? selectedVariant;
        if (availableVariants.length == 1) {
          selectedVariant = availableVariants.first;
        } else {
          if (!mounted) return;
          selectedVariant = await showDialog<String>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Welche Variante?"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: availableVariants.map((v) => ListTile(title: Text(v), onTap: () => Navigator.pop(ctx, v))).toList(),
              ),
            ),
          );
        }

        if (selectedVariant != null) {
          await service.addCardToBulkBox(widget.binder.id, pickedCard.id, selectedVariant);
          if (mounted) ref.invalidate(binderDetailProvider(widget.binder.id));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Fehler: $e")));
      }
    }
  }

  void _showSearchDialog(BuildContext context, BinderDetailState? state) {
    if (state == null) return;
    _searchController.clear(); 
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("In der Box suchen"),
        content: TextField(
          controller: _searchController,
          autofocus: true,
          onSubmitted: (query) {
             _performSearch(query, state);
             Navigator.pop(ctx);
          },
        ),
      ),
    );
  }

  void _performSearch(String query, BinderDetailState state) async {
    if (query.isEmpty) return;
    final qLower = query.toLowerCase();
    
    final index = state.slots.indexWhere((s) {
      final label = s.binderCard.placeholderLabel?.toLowerCase() ?? "";
      final cardName = s.card?.name.toLowerCase() ?? "";
      final cardNameDe = s.card?.nameDe?.toLowerCase() ?? "";
      return label.contains(qLower) || cardName.contains(qLower) || cardNameDe.contains(qLower);
    });

    if (index != -1) {
      FocusScope.of(context).unfocus();
      if (mounted) {
        _scrollController.animateTo(
          index * 80.0, 
          duration: const Duration(milliseconds: 500), 
          curve: Curves.easeInOut
        );
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gefunden!")));
      }
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nichts gefunden.")));
    }
  }

  void _showStats(BuildContext context, BinderDetailState? state) {
    if (state == null) return;
    ref.invalidate(binderHistoryProvider(widget.binder.id));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent, 
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.65, 
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: _BinderStatsContent(binderId: widget.binder.id, currentState: state, isBulkBox: true, onDelete: () {
           Navigator.pop(ctx);
           _confirmDelete(context);
        }),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Box löschen?"),
        content: Text("Möchtest du '${widget.binder.name}' wirklich löschen?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Abbrechen")),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final db = ref.read(databaseProvider);
              await BinderService(db).deleteBinder(widget.binder.id);
              ref.invalidate(binderStatsProvider(widget.binder.id)); 
              if (ctx.mounted) {
                Navigator.pop(ctx); 
                Navigator.pop(context); 
              }
            }, 
            child: const Text("Löschen"),
          ),
        ],
      ),
    );
  }
}

// --- STATS WIDGET (Geteilt mit Buch-Ansicht, leicht angepasst) ---
class _BinderStatsContent extends ConsumerWidget {
  final int binderId;
  final BinderDetailState currentState;
  final VoidCallback onDelete;
  final bool isBulkBox;

  const _BinderStatsContent({required this.binderId, required this.currentState, required this.onDelete, this.isBulkBox = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(binderHistoryProvider(binderId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        
        Text("Statistik & Verlauf", style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 5),
        
        historyAsync.when(
          data: (history) {
             double change = 0;
             double percent = 0;
             final current = currentState.totalValue;
             
             if (history.length >= 2) {
                 final last = history.last.value;
                 final prev = history[history.length - 2].value;
                 change = last - prev;
                 if (prev > 0) percent = (change / prev) * 100;
                 else if (change > 0) percent = 100.0; 
               }

             final isPositive = change >= -0.01;
             final color = isPositive ? Colors.green : Colors.red;
             final sign = isPositive ? "+" : "";

             return Row(
               crossAxisAlignment: CrossAxisAlignment.end,
               children: [
                 Text("${current.toStringAsFixed(2)} €", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                 const SizedBox(width: 10),
                 Padding(
                   padding: const EdgeInsets.only(bottom: 6),
                   child: Container(
                     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                     decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                     child: Text(
                       "$sign${change.toStringAsFixed(2)}€ ($sign${percent.toStringAsFixed(1)}%)",
                       style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
                     ),
                   ),
                 ),
               ],
             );
          },
          loading: () => const Text("Lade Historie...", style: TextStyle(color: Colors.grey)),
          error: (e, s) => const SizedBox(),
        ),

        const SizedBox(height: 20),

        Expanded(
          child: historyAsync.when(
            data: (history) {
              if (history.length < 2) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.show_chart, size: 48, color: Colors.grey[300]),
                      const Text("Zu wenig Daten für einen Graphen", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }
              return _BinderHistoryChart(history: history);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e,s) => Center(child: Text("Fehler beim Laden: $e")),
          ),
        ),

        const SizedBox(height: 20),
        const Divider(),

        ListTile(
          leading: Icon(isBulkBox ? Icons.inventory_2 : Icons.pie_chart, color: Colors.blue),
          title: Text(isBulkBox ? "Karten im Karton" : "Vervollständigung"),
          trailing: Text(isBulkBox ? "${currentState.filledSlots}" : "${currentState.filledSlots} / ${currentState.totalSlots}"),
        ),

        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: Text(isBulkBox ? "Ganze Box löschen" : "Binder löschen", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          onTap: onDelete,
        ),
      ],
    );
  }
}

class _BinderHistoryChart extends StatelessWidget {
  final List<BinderHistoryPoint> history;
  const _BinderHistoryChart({required this.history});

  @override
  Widget build(BuildContext context) {
    List<FlSpot> spots = [];
    Set<double> seenX = {};
    for (var p in history) {
      double x = p.date.millisecondsSinceEpoch.toDouble();
      if (!seenX.contains(x)) {
        spots.add(FlSpot(x, p.value));
        seenX.add(x);
      }
    }

    if (spots.isEmpty) {
      final now = DateTime.now().millisecondsSinceEpoch.toDouble();
      spots = [FlSpot(now - 86400000, 0), FlSpot(now, 0)]; 
    } else if (spots.length == 1) {
      final alone = spots.first;
      spots = [FlSpot(alone.x - 86400000, 0), alone]; 
    }

    double minX = spots.first.x;
    double maxX = spots.last.x;
    if (minX == maxX) {
      minX -= 86400000; 
      maxX += 86400000; 
    }

    double minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    double maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);

    if (minY == maxY) { 
      if (minY == 0) maxY = 10; 
      else { minY = minY * 0.8; maxY = maxY * 1.2; }
    }
    
    final deltaY = maxY - minY;
    minY -= deltaY * 0.1;
    maxY += deltaY * 0.1;
    if (minY < 0) minY = 0;

    double xInterval = (maxX - minX) / 3;
    if (xInterval <= 0) xInterval = 86400000; 

    double yInterval = (maxY - minY) / 4;
    if (yInterval <= 0) yInterval = 1.0; 

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey[200], strokeWidth: 1)),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true, reservedSize: 40, interval: yInterval, 
              getTitlesWidget: (val, _) {
                if (val < 0) return const SizedBox();
                return Text("${val.toInt()}€", style: TextStyle(color: Colors.grey[400], fontSize: 10), textAlign: TextAlign.right);
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true, reservedSize: 22, interval: xInterval, 
              getTitlesWidget: (val, _) {
                final date = DateTime.fromMillisecondsSinceEpoch(val.toInt());
                return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(DateFormat('dd.MM').format(date), style: TextStyle(color: Colors.grey[400], fontSize: 10)));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: minX, maxX: maxX, minY: minY, maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots, isCurved: true, color: Colors.blueAccent, barWidth: 3, isStrokeCapRound: true, dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.blue.withOpacity(0.2), Colors.blue.withOpacity(0.0)])),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueGrey,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                return LineTooltipItem("${DateFormat('dd.MM').format(date)}\n${spot.y.toStringAsFixed(2)} €", const TextStyle(color: Colors.white, fontWeight: FontWeight.bold));
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}