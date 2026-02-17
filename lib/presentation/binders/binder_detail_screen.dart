import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:page_flip/page_flip.dart'; // <--- WICHTIG: Neues Import
import '../../data/database/app_database.dart';
import 'binder_detail_provider.dart';
import 'widgets/binder_page_widget.dart';
import '../../domain/logic/binder_service.dart';
import '../search/card_search_screen.dart';
import '../../data/database/database_provider.dart';
import '../../domain/models/api_card.dart';
import 'package:drift/drift.dart' as drift;

class BinderDetailScreen extends ConsumerStatefulWidget {
  final Binder binder;
  const BinderDetailScreen({super.key, required this.binder});

  @override
  ConsumerState<BinderDetailScreen> createState() => _BinderDetailScreenState();
}

class _BinderDetailScreenState extends ConsumerState<BinderDetailScreen> {
  // Key für das neue Paket
  final _pageFlipKey = GlobalKey<PageFlipWidgetState>();
  final _searchController = TextEditingController();

  int _rebuildKey = 0;

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(binderDetailProvider(widget.binder.id));

    return Scaffold(
      backgroundColor: Colors.grey[800], // Tisch-Hintergrund
      appBar: AppBar(
        title: Text(widget.binder.name),
        backgroundColor: Color(widget.binder.color),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context, asyncData.asData?.value),
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () => _showStats(context, asyncData.asData?.value),
          ),
        ],
      ),
      body: asyncData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Fehler: $e")),
        data: (state) {
          if (state.slots.isEmpty) return const Center(child: Text("Binder ist leer."));

          // Seiten berechnen (Code bleibt gleich)
          final int itemsPerPage = widget.binder.rowsPerPage * widget.binder.columnsPerPage;
          final int totalPages = (state.slots.length / itemsPerPage).ceil();

          List<Widget> pages = [];
          for (int i = 0; i < totalPages; i++) {
            final start = i * itemsPerPage;
            final end = (start + itemsPerPage < state.slots.length) 
                ? start + itemsPerPage 
                : state.slots.length;
            
            final pageSlots = state.slots.sublist(start, end);

            pages.add(
              RepaintBoundary(
                key: ValueKey('page_$i'), 
                child: Container(
                  color: const Color(0xFFFDFDFD), 
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 3.0,
                    panEnabled: true, 
                    child: BinderPageWidget(
                      slots: pageSlots,
                      rows: widget.binder.rowsPerPage,
                      cols: widget.binder.columnsPerPage,
                      pageNumber: i,
                      totalPages: totalPages, // <--- Übergeben
                      onSlotTap: (slot) => _handleSlotTap(slot),
                      
                      // --- NAVIGATION STEUERUNG ---
                      onNextPage: () {
                        // Tastatur weg, falls noch offen
                        FocusScope.of(context).unfocus();
                        _pageFlipKey.currentState?.nextPage();
                      },
                      onPrevPage: () {
                        FocusScope.of(context).unfocus();
                        _pageFlipKey.currentState?.previousPage();
                      },
                    ),
                  ),
                ),
              ),
            );
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0), // Etwas Abstand oben/unten
              child: AspectRatio(
                // FIX: 0.65 ist deutlich höher (wie ein A4 Blatt). 
                // Das gibt dem 4x4 Grid genug Platz nach unten.
                aspectRatio: 0.65, 
                child: PageFlipWidget(
                  key: ValueKey("binder_view_$_rebuildKey"),
                  backgroundColor: Colors.grey[800]!,
                  lastPage: Container(
                      color: Colors.white, 
                      child: const Center(child: Text("Ende des Binders"))
                  ),
                  children: pages,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleSlotTap(BinderSlotData slot) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(slot.binderCard.placeholderLabel ?? "Slot"),
              subtitle: Text(slot.binderCard.isPlaceholder ? "Leer (Platzhalter)" : "Befüllt"),
            ),
            const Divider(),
            
            // 1. BEFÜLLEN (Nur wenn Platzhalter)
            if (slot.binderCard.isPlaceholder)
              ListTile(
                leading: const Icon(Icons.add_photo_alternate, color: Colors.green),
                title: const Text("Karte aus Inventar hinzufügen"),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickCardForSlot(slot, onlyOwned: true);
                },
              ),

            // 2. KONFIGURIEREN (Platzhalter ändern)
            if (slot.binderCard.isPlaceholder)
               ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text("Platzhalter ändern (Suchen)"),
                onTap: () {
                  Navigator.pop(ctx);
                  // Suche ALLE Karten, nicht nur eigene
                  _pickCardForSlot(slot, onlyOwned: false); 
                },
              ),
              
            // 3. ENTFERNEN / ÄNDERN (Wenn befüllt)
            if (!slot.binderCard.isPlaceholder) ...[
              ListTile(
                leading: const Icon(Icons.change_circle, color: Colors.orange),
                title: const Text("Karte austauschen"),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickCardForSlot(slot, onlyOwned: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.remove_circle_outline, color: Colors.red),
                title: const Text("Entfernen (wieder Platzhalter)"),
                onTap: () async {
                  Navigator.pop(ctx);
                  final db = ref.read(databaseProvider);
                  await BinderService(db).clearSlot(slot.binderCard.id);
                  setState(() { _rebuildKey++; }); // UI Refresh
                },
              ),
            ]
          ],
        ),
      ),
    );
  }

 Future<void> _pickCardForSlot(BinderSlotData slot, {required bool onlyOwned}) async {
    String initialQuery = slot.binderCard.placeholderLabel ?? "";
    if (initialQuery.contains(" ")) {
        initialQuery = initialQuery.split(" ").sublist(1).join(" ");
    }

    // Wir erwarten jetzt ein ApiCard Objekt zurück, keinen String
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CardSearchScreen(
            initialQuery: initialQuery, 
            pickerMode: true, 
            onlyOwned: onlyOwned 
        ), 
      ),
    );

    // FIX: Check auf ApiCard Typ
    if (result != null && result is ApiCard) { 
      final ApiCard pickedCard = result;
      final db = ref.read(databaseProvider);
      final service = BinderService(db);
      
      try {
        // --- SCHRITT A: Karte in lokaler DB sichern ---
        // Falls die Karte aus der API kommt und noch nicht in der DB ist, speichern wir sie jetzt.
        // Das ist entscheidend, damit der Binder das Bild laden kann!
        
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
            // Wir importieren hier nur die Basics, damit die Anzeige funktioniert
          )
        );

        // --- SCHRITT B: Binder Slot updaten ---
        if (onlyOwned) {
           if (await service.isCardAvailable(pickedCard.id)) {
             await service.fillSlot(slot.binderCard.id, pickedCard.id);
             if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Karte hinzugefügt!")));
             }
           } else {
             _showSwapDialog(slot.binderCard.id, pickedCard.id); 
           }
        } else {
           // Platzhalter konfigurieren
           String label = pickedCard.nameDe ?? pickedCard.name;
           await service.configureSlot(slot.binderCard.id, pickedCard.id, label);
        }
        
        // --- SCHRITT C: Refresh ---
        // Provider invalidieren
        ref.invalidate(binderDetailProvider(widget.binder.id));
        
        // Widget komplett neu bauen (zwingt Bilder zum Neuladen)
        setState(() { _rebuildKey++; }); 
        
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Fehler: $e")));
        }
      }
    }
  }

  void _showSwapDialog(int slotId, String cardId) {
     showDialog(
       context: context, 
       builder: (ctx) => AlertDialog(
         title: const Text("Keine Karte verfügbar"),
         content: const Text("Du hast alle Exemplare dieser Karte bereits in anderen Bindern verwendet. Möchtest du sie hier nutzen und dort entfernen? (Auto-Swap Logik hier einfügen)"),
         actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
       )
     );
     // Anmerkung: Echter Swap ist komplexer, da wir wissen müssen WO sie ist. 
     // Fürs Erste reicht die Info, dass es nicht geht.
  }

  // --- STATISTIK & SUCHE ---

  void _showStats(BuildContext context, BinderDetailState? state) {
    if (state == null) return;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Optionen & Statistik", style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            
            // Statistik
            ListTile(
              leading: const Icon(Icons.euro, color: Colors.green),
              title: const Text("Gesamtwert"),
              trailing: Text("${state.totalValue.toStringAsFixed(2)} €", 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ListTile(
              leading: const Icon(Icons.pie_chart, color: Colors.blue),
              title: const Text("Vervollständigung"),
              trailing: Text("${state.filledSlots} / ${state.totalSlots}"),
              subtitle: LinearProgressIndicator(
                value: state.filledSlots / (state.totalSlots == 0 ? 1 : state.totalSlots)
              ),
            ),
            
            const Divider(),
            
            // --- LÖSCHEN BUTTON ---
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text("Binder löschen", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: () {
                // Dialog schließen
                Navigator.pop(ctx);
                // Bestätigung anzeigen
                _confirmDelete(context); 
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Binder löschen?"),
        content: Text("Möchtest du '${widget.binder.name}' wirklich löschen? Alle Slots und Sortierungen gehen verloren. Deine Karten bleiben im Inventar."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text("Abbrechen")
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              // 1. Löschen
              final db = ref.read(databaseProvider);
              final service = BinderService(db);
              await service.deleteBinder(widget.binder.id);
              
              if (ctx.mounted) {
                // 2. Dialog schließen
                Navigator.pop(ctx); 
                // 3. Zurück zur Liste (Screen schließen)
                Navigator.pop(context); 
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Binder gelöscht."))
                );
              }
            }, 
            child: const Text("Löschen"),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context, BinderDetailState? state) {
    if (state == null) return;
    
    // --- FIX: Suche leeren bevor der Dialog aufgeht ---
    _searchController.clear(); 
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Im Binder suchen"),
        content: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(hintText: "z.B. Glurak"),
          onSubmitted: (query) {
             _performSearch(query, state);
             Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Abbrechen")),
          FilledButton(onPressed: () {
            _performSearch(_searchController.text, state);
            Navigator.pop(ctx);
          }, child: const Text("Suchen")),
        ],
      ),
    );
  }

  void _performSearch(String query, BinderDetailState state) async { // <--- async hinzufügen
    if (query.isEmpty) return;
    
    final qLower = query.toLowerCase();
    
    final index = state.slots.indexWhere((s) {
      final label = s.binderCard.placeholderLabel?.toLowerCase() ?? "";
      final cardName = s.card?.name.toLowerCase() ?? "";
      final cardNameDe = s.card?.nameDe?.toLowerCase() ?? "";
      
      return label.contains(qLower) || cardName.contains(qLower) || cardNameDe.contains(qLower);
    });

    if (index != -1) {
      final int itemsPerPage = widget.binder.rowsPerPage * widget.binder.columnsPerPage;
      final int targetPage = (index / itemsPerPage).floor();

      // WICHTIG: Tastatur ausblenden (falls sie noch offen ist)
      FocusScope.of(context).unfocus();

      // WICHTIG: Kurze Pause, damit der Dialog erst schließen kann
      await Future.delayed(const Duration(milliseconds: 300));

      // Jetzt erst springen
      _pageFlipKey.currentState?.goToPage(targetPage);
      
      await Future.delayed(const Duration(milliseconds: 150));

      if (mounted) {
        setState(() {
          // Leeres setState triggert einen neuen Frame
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gefunden auf Seite ${targetPage + 1}!"),
            duration: const Duration(milliseconds: 1500),
          )
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Nichts gefunden."))
        );
      }
    }
  }
}