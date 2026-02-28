import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:drift/drift.dart' as drift;
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
        backgroundColor: Color(widget.binder.color),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context, asyncData.asData?.value),
          ),
        ],
      ),
      // --- FLOATING ACTION BUTTON ZUM HINZUFÜGEN ---
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMenu(context),
        backgroundColor: Color(widget.binder.color),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Tausch-Banner
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
            
          // Liste
          Expanded(
            child: asyncData.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text("Fehler: $e")),
              data: (state) {
                if (state.slots.isEmpty) {
                  return const Center(
                    child: Text("Box ist leer.\nTippe auf + um Karten oder Trenner hinzuzufügen.", 
                      textAlign: TextAlign.center, 
                      style: TextStyle(color: Colors.grey)
                    )
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

  // --- WIDGET FÜR EIN LISTEN-ELEMENT (KARTE ODER TRENNER) ---
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

    // Normale Karte
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
            // Bild
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
            // Info
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
            // Preis
            Text("${slot.marketPrice.toStringAsFixed(2)} €", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        ),
      ),
    );
  }

  // --- LOGIK ---

  String _getSlotName(BinderSlotData slot) {
    if (slot.binderCard.isPlaceholder && (slot.binderCard.placeholderLabel?.startsWith("DIVIDER:") ?? false)) {
      return "Trenner: ${slot.binderCard.placeholderLabel!.replaceAll('DIVIDER:', '')}";
    }
    return slot.card?.nameDe ?? slot.card?.name ?? "Karte";
  }

  void _showAddMenu(BuildContext context) {
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
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Verschoben!")));
       }
       return;
    }
    
    // Normaler Tap -> Menü (Ähnlich wie im Buch)
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
              title: const Text("Verschieben (Tauschen)"),
              subtitle: const Text("Tippe danach auf die neue Position"),
              onTap: () {
                Navigator.pop(ctx);
                setState(() { _isSwapMode = true; _slotToSwap = slot; });
              },
            ),

            ListTile(
              leading: const Icon(Icons.arrow_upward, color: Colors.purple),
              title: const Text("Eins nach oben"),
              onTap: () async {
                Navigator.pop(ctx);
                final db = ref.read(databaseProvider);
                await BinderService(db).moveSlotLeft(widget.binder.id, slot.binderCard.id); // Left = Up in 1D List
                if (mounted) ref.invalidate(binderDetailProvider(widget.binder.id));
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.arrow_downward, color: Colors.purple),
              title: const Text("Eins nach unten"),
              onTap: () async {
                Navigator.pop(ctx);
                final db = ref.read(databaseProvider);
                await BinderService(db).moveSlotRight(widget.binder.id, slot.binderCard.id); // Right = Down in 1D List
                if (mounted) ref.invalidate(binderDetailProvider(widget.binder.id));
              },
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text("Löschen", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
        // Scrollt die Liste sanft zu dem gefundenen Element
        _scrollController.animateTo(
          index * 80.0, // Geschätzte Höhe eines List-Items
          duration: const Duration(milliseconds: 500), 
          curve: Curves.easeInOut
        );
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gefunden!")));
      }
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nichts gefunden.")));
    }
  }
}