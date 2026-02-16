import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:page_flip/page_flip.dart'; // <--- WICHTIG: Neues Import
import '../../data/database/app_database.dart';
import 'binder_detail_provider.dart';
import 'widgets/binder_page_widget.dart';
import '../../domain/logic/binder_service.dart';
import '../../data/database/database_provider.dart';

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
                  key: _pageFlipKey,
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
    // Hier kommt gleich das Hinzufügen-Menü hin
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Slot: ${slot.binderCard.placeholderLabel}"))
    );
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