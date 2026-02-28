import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift; 
import '../../data/database/app_database.dart';
import '../../data/database/database_provider.dart';
import '../../domain/logic/binder_service.dart';
import '../../domain/models/api_card.dart'; 
import 'binder_detail_provider.dart'; 
import 'widgets/binder_page_widget.dart';
import '../search/card_search_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class BinderDetailScreen extends ConsumerStatefulWidget {
  final Binder binder;
  const BinderDetailScreen({super.key, required this.binder});

  @override
  ConsumerState<BinderDetailScreen> createState() => _BinderDetailScreenState();
}

class _BinderDetailScreenState extends ConsumerState<BinderDetailScreen> {
  late PageController _pageController;
  final _searchController = TextEditingController();
  
  int _currentIndex = 0;
  
  // --- NEU: Tausch-Modus Variablen ---
  bool _isSwapMode = false;
  BinderSlotData? _slotToSwap;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(binderDetailProvider(widget.binder.id));

    return Scaffold(
      backgroundColor: Colors.grey[800], 
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
      body: Column(
        children: [
          // --- NEU: Der Tausch-Modus Banner ---
          if (_isSwapMode && _slotToSwap != null)
            Container(
              width: double.infinity,
              color: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.swap_horiz, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Wähle den Ziel-Slot, um '${_slotToSwap!.binderCard.placeholderLabel ?? 'Slot'}' zu tauschen...",
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
            
          // --- Der eigentliche Binder ---
          Expanded(
            child: asyncData.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text("Fehler: $e")),
              data: (state) {
                if (state.slots.isEmpty) return const Center(child: Text("Binder ist leer.", style: TextStyle(color: Colors.white)));

                int itemsPerPage = widget.binder.rowsPerPage * widget.binder.columnsPerPage;
                if (itemsPerPage <= 0) itemsPerPage = 9; 

                final int totalPages = (state.slots.length / itemsPerPage).ceil();

                List<Widget> pages = [];
                for (int i = 0; i < totalPages; i++) {
                  final start = i * itemsPerPage;
                  final end = (start + itemsPerPage < state.slots.length) 
                      ? start + itemsPerPage 
                      : state.slots.length;
                  
                  final pageSlots = state.slots.sublist(start, end);

                  pages.add(
                    Container(
                      color: const Color(0xFFFDFDFD), 
                      child: BinderPageWidget(
                        slots: pageSlots,
                        rows: widget.binder.rowsPerPage,
                        cols: widget.binder.columnsPerPage,
                        pageNumber: i,
                        totalPages: totalPages, 
                        onSlotTap: (slot) => _handleSlotTap(slot),
                        onSlotLongPress: (slot) => _handleSlotLongPress(slot), 
                        // --- NEU: Wir übergeben den Swap-State ans Widget ---
                        isSwapMode: _isSwapMode,
                        slotToSwapId: _slotToSwap?.binderCard.id,
                        onNextPage: () {
                          FocusScope.of(context).unfocus();
                          if (_currentIndex < totalPages - 1) {
                            _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                          }
                        },
                        onPrevPage: () {
                          FocusScope.of(context).unfocus();
                          if (_currentIndex > 0) {
                            _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                          }
                        },
                      ),
                    ),
                  );
                }

                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0), 
                    child: AspectRatio(
                      aspectRatio: 0.65, 
                      child: PageView(
                        controller: _pageController,
                        scrollBehavior: ScrollConfiguration.of(context).copyWith(
                          dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
                        ),
                        onPageChanged: (index) {
                          _currentIndex = index;
                        },
                        children: [
                          ...pages,
                          Container(
                            color: Colors.white, 
                            child: const Center(child: Text("Ende des Binders"))
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleSlotTap(BinderSlotData slot) async {
    // --- NEU: Wenn wir im Tausch-Modus sind, wird jetzt getauscht! ---
    if (_isSwapMode && _slotToSwap != null) {
       final db = ref.read(databaseProvider);
       await BinderService(db).swapTwoSlots(widget.binder.id, _slotToSwap!.binderCard.id, slot.binderCard.id);
       
       if (mounted) {
         setState(() {
           _isSwapMode = false;
           _slotToSwap = null;
         });
         ref.invalidate(binderDetailProvider(widget.binder.id));
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Slots getauscht!")));
       }
       return;
    }

    // --- NORMALES MENÜ ---
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
            
            if (slot.binderCard.isPlaceholder) ...[
              ListTile(
                leading: const Icon(Icons.add_photo_alternate, color: Colors.green),
                title: const Text("Karte aus Inventar hinzufügen"),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickCardForSlot(slot, onlyOwned: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text("Platzhalter ändern (Suchen)"),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickCardForSlot(slot, onlyOwned: false); 
                },
              ),
            ],
              
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
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Karte entfernt.")));
                    ref.invalidate(binderDetailProvider(widget.binder.id));
                  }
                },
              ),
            ]
          ],
        ),
      ),
    );
  }

  void _handleSlotLongPress(BinderSlotData slot) {
    if (_isSwapMode) return; // Wenn wir schon tauschen, kein langes Drücken

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("Slot Layout bearbeiten", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(slot.binderCard.placeholderLabel ?? "Leer"),
            ),
            const Divider(),
            
            // --- NEU: TAUSCH MODUS STARTEN ---
            ListTile(
              leading: const Icon(Icons.find_replace, color: Colors.orange),
              title: const Text("Mit einem anderen Slot tauschen"),
              subtitle: const Text("Tippe auf den Slot, mit dem du tauschen möchtest"),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _isSwapMode = true;
                  _slotToSwap = slot;
                });
              },
            ),

            ListTile(
              leading: const Icon(Icons.arrow_back, color: Colors.purple),
              title: const Text("Slot nach links verschieben"),
              onTap: () async {
                Navigator.pop(ctx);
                final db = ref.read(databaseProvider);
                await BinderService(db).moveSlotLeft(widget.binder.id, slot.binderCard.id);
                if (mounted) ref.invalidate(binderDetailProvider(widget.binder.id));
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.arrow_forward, color: Colors.purple),
              title: const Text("Slot nach rechts verschieben"),
              onTap: () async {
                Navigator.pop(ctx);
                final db = ref.read(databaseProvider);
                await BinderService(db).moveSlotRight(widget.binder.id, slot.binderCard.id);
                if (mounted) ref.invalidate(binderDetailProvider(widget.binder.id));
              },
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.add_to_photos, color: Colors.blue),
              title: const Text("Leeren Slot danach einfügen"),
              subtitle: const Text("Alle nachfolgenden Slots rücken auf"),
              onTap: () async {
                Navigator.pop(ctx);
                final db = ref.read(databaseProvider);
                await BinderService(db).addSlotRight(widget.binder.id, slot.binderCard.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Slot erfolgreich hinzugefügt.")));
                  ref.invalidate(binderDetailProvider(widget.binder.id));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep, color: Colors.red),
              title: const Text("Diesen Slot löschen", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              subtitle: const Text("Alle nachfolgenden Slots rücken zurück"),
              onTap: () async {
                Navigator.pop(ctx);
                final db = ref.read(databaseProvider);
                await BinderService(db).deleteSlotAndShift(widget.binder.id, slot.binderCard.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Slot komplett gelöscht.")));
                  ref.invalidate(binderDetailProvider(widget.binder.id));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

 Future<void> _pickCardForSlot(BinderSlotData slot, {required bool onlyOwned}) async {
    String initialQuery = slot.binderCard.placeholderLabel ?? "";

    if (initialQuery == "Leerer Slot") {
      initialQuery = ""; 
    } else if (initialQuery.contains(" ")) {
      final parts = initialQuery.split(" ");
      if (parts.first.startsWith("#") || parts.first.startsWith("✨")) {
        initialQuery = parts.sublist(1).join(" ");
      } 
    }

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

        if (onlyOwned) {
           final availableVariants = await service.getAvailableVariantsForCard(pickedCard.id);

           if (availableVariants.isEmpty) {
             _showSwapDialog(slot.binderCard.id, pickedCard.id); 
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
                   children: availableVariants.map((variant) => ListTile(
                     leading: const Icon(Icons.style, color: Colors.blueAccent),
                     title: Text(variant, style: const TextStyle(fontWeight: FontWeight.bold)),
                     onTap: () => Navigator.pop(ctx, variant),
                   )).toList(),
                 ),
                 actions: [TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text("Abbrechen"))],
               ),
             );
             if (selectedVariant == null) return; 
           }

           await service.fillSlot(slot.binderCard.id, pickedCard.id, variant: selectedVariant);
           if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$selectedVariant Karte hinzugefügt!")));
        } else {
           String label = pickedCard.nameDe ?? pickedCard.name;
           await service.configureSlot(slot.binderCard.id, pickedCard.id, label);
        }
        
        if (mounted) ref.invalidate(binderDetailProvider(widget.binder.id));
        
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Fehler: $e")));
      }
    }
  }

  void _showSwapDialog(int slotId, String cardId) {
     showDialog(
       context: context, 
       builder: (ctx) => AlertDialog(
         title: const Text("Keine Karte verfügbar"),
         content: const Text("Du hast alle Exemplare dieser Karte bereits in anderen Bindern verwendet."),
         actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
       )
     );
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
        child: _BinderStatsContent(binderId: widget.binder.id, currentState: state, onDelete: () {
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
        title: const Text("Binder löschen?"),
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

  void _showSearchDialog(BuildContext context, BinderDetailState? state) {
    if (state == null) return;
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
      final int itemsPerPage = widget.binder.rowsPerPage * widget.binder.columnsPerPage;
      final int targetPage = (index / itemsPerPage).floor();

      FocusScope.of(context).unfocus();

      if (mounted) {
        _pageController.animateToPage(targetPage, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gefunden auf Seite ${targetPage + 1}!"), duration: const Duration(seconds: 1))
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nichts gefunden.")));
      }
    }
  }
}

class _BinderStatsContent extends ConsumerWidget {
  final int binderId;
  final BinderDetailState currentState;
  final VoidCallback onDelete;

  const _BinderStatsContent({required this.binderId, required this.currentState, required this.onDelete});

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
                 
                 if (prev > 0) {
                   percent = (change / prev) * 100;
                 } else if (change > 0) {
                   percent = 100.0; 
                 }
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
          leading: const Icon(Icons.pie_chart, color: Colors.blue),
          title: const Text("Vervollständigung"),
          trailing: Text("${currentState.filledSlots} / ${currentState.totalSlots}"),
          subtitle: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: currentState.filledSlots / (currentState.totalSlots == 0 ? 1 : currentState.totalSlots),
              minHeight: 8,
            ),
          ),
        ),

        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: const Text("Binder löschen", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
      if (minY == 0) {
        maxY = 10; 
      } else {
        minY = minY * 0.8;
        maxY = maxY * 1.2;
      }
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
        gridData: FlGridData(
          show: true, 
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey[200], strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: yInterval, 
              getTitlesWidget: (val, _) {
                if (val < 0) return const SizedBox();
                return Text(
                  "${val.toInt()}€", 
                  style: TextStyle(color: Colors.grey[400], fontSize: 10),
                  textAlign: TextAlign.right,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: xInterval, 
              getTitlesWidget: (val, _) {
                final date = DateTime.fromMillisecondsSinceEpoch(val.toInt());
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(DateFormat('dd.MM').format(date), style: TextStyle(color: Colors.grey[400], fontSize: 10)),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blueAccent,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue.withOpacity(0.2), Colors.blue.withOpacity(0.0)],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueGrey,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final date = DateTime.fromMillisecondsSinceEpoch(spot.x.toInt());
                return LineTooltipItem(
                  "${DateFormat('dd.MM').format(date)}\n${spot.y.toStringAsFixed(2)} €",
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}