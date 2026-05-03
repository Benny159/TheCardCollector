import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:drift/drift.dart' as drift; 

import '../../data/database/database_provider.dart';
import '../../data/database/app_database.dart'; 
import '../../domain/models/api_card.dart';
import '../../domain/logic/binder_service.dart';

// Wir nutzen denselben Provider für die Vorauswahl wie beim Inventar
import 'inventory_bottom_sheet.dart' show lastSelectedBinderProvider;

class _SlotInfo {
  final BinderCard slot;
  final Binder binder;
  _SlotInfo(this.slot, this.binder);
}

class AssignToBinderSheet extends ConsumerStatefulWidget {
  final ApiCard card;

  const AssignToBinderSheet({super.key, required this.card});

  @override
  ConsumerState<AssignToBinderSheet> createState() => _AssignToBinderSheetState();
}

class _AssignToBinderSheetState extends ConsumerState<AssignToBinderSheet> {
  List<Binder> _availableBinders = [];
  UserCard? _selectedUserCard;
  List<UserCard> _ownedCards = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = ref.read(databaseProvider);
    final binders = await db.select(db.binders).get();
    
    // Lade alle Versionen dieser Karte, die der User besitzt
    final cards = await (db.select(db.userCards)..where((t) => t.cardId.equals(widget.card.id))).get();
    
    if (mounted) {
      setState(() {
        _availableBinders = binders;
        _ownedCards = cards;
        if (_ownedCards.isNotEmpty) {
           _selectedUserCard = _ownedCards.first;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final selectedBinderId = ref.watch(lastSelectedBinderProvider);

    final bool idExists = selectedBinderId == null || 
                          selectedBinderId == -1 || 
                          _availableBinders.any((b) => b.id == selectedBinderId);
                          
    final safeBinderId = idExists ? selectedBinderId : -1;

    if (_ownedCards.isEmpty) {
       return Container(
         padding: const EdgeInsets.all(20),
         decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
         child: const Text("Du besitzt diese Karte noch nicht. Füge sie zuerst über 'Hinzufügen' zu deinem Inventar hinzu!"),
       );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("In Binder sortieren", style: Theme.of(context).textTheme.titleLarge),
              const Icon(Icons.move_to_inbox, color: Colors.blueGrey),
            ],
          ),
          const SizedBox(height: 8),
          Text(widget.card.nameDe ?? widget.card.name, style: const TextStyle(color: Colors.grey)),
          const Divider(height: 24),

          const Text("Welches Exemplar möchtest du einsortieren?", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          
          DropdownButtonFormField<UserCard>(
            initialValue: _selectedUserCard,
            isDense: true,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: _ownedCards.map((uc) {
               String label = "${uc.variant} (${uc.condition} • ${uc.language})";
               return DropdownMenuItem(value: uc, child: Text(label, style: const TextStyle(fontSize: 13)));
            }).toList(),
            onChanged: (val) => setState(() => _selectedUserCard = val),
          ),
          
          const SizedBox(height: 20),
          
          const Text("In welchen Binder?", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: safeBinderId, 
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                items: [
                  const DropdownMenuItem(value: null, child: Text("❌ Abbrechen")),
                  const DropdownMenuItem(value: -1, child: Text("✨ Automatisch (Beliebiger Binder)")),
                  ..._availableBinders.map((b) => DropdownMenuItem(
                    value: b.id, 
                    child: Text("📂 ${b.name}"),
                  )),
                ],
                onChanged: (val) {
                  ref.read(lastSelectedBinderProvider.notifier).state = val;
                },
              ),
            ),
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                  child: const Text("Abbrechen"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text("Einsortieren"),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blueGrey[700],
                    padding: const EdgeInsets.symmetric(vertical: 12)
                  ),
                  onPressed: safeBinderId == null ? null : _sortIntoBinder,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _sortIntoBinder() async {
    final db = ref.read(databaseProvider);
    final binderService = BinderService(db);
    final selectedBinderId = ref.read(lastSelectedBinderProvider);
    
    if (_selectedUserCard == null || selectedBinderId == null) return;

    try {
      String binderMessage = "";
      bool showOrangeBanner = false;

      // --- 1. Check auf Bulk Box ---
      if (selectedBinderId != -1) {
        final targetBinder = await (db.select(db.binders)..where((t) => t.id.equals(selectedBinderId))).getSingleOrNull();
        
        if (targetBinder != null) {
          if (targetBinder.isFull) {
             if (mounted) {
               ScaffoldMessenger.of(context).clearSnackBars();
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Diese Box ist als "Voll" markiert!'), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating, duration: Duration(milliseconds: 500)));
             }
             return; 
          } else if (targetBinder.rowsPerPage == 0) {
             await binderService.addCardToBulkBox(selectedBinderId, widget.card.id, _selectedUserCard!.id, _selectedUserCard!.variant);
             if (mounted) {
               Navigator.pop(context, true);
               ScaffoldMessenger.of(context).clearSnackBars();
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('In die Bulk Box geworfen!'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating, duration: Duration(milliseconds: 500)));
             }
             return; 
          }
        }
      }

      // --- 2. Smarte Suche im ausgewählten Binder ---
      final cardNameDe = (widget.card.nameDe ?? "").toLowerCase();
      final cardNameEn = widget.card.name.toLowerCase();
      
      final ignoreWords = [
        'ex', 'v', 'vmax', 'vstar', 'gx', 'team', 'rocket', "rocket's", 'rockets', 
        'dark', 'dunkles', 'light', 'helles', 'mega', 'm', 'lv', 'x', 'lvx', 'sp'
      ];

      List<String> getCoreWords(String text) {
        if (text.trim().isEmpty) return [];
        String spacedText = text.replaceAll('-', ' ');
        final cleaned = spacedText.replaceAll(RegExp(r'[^a-z0-9äöüß\s]'), '').toLowerCase();
        final words = cleaned.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
        final coreWords = words.where((w) => !ignoreWords.contains(w)).toList();
        return coreWords.isNotEmpty ? coreWords : words;
      }

      bool isFormMismatch(String pLabel) {
         final p = pLabel.toLowerCase();
         bool checkMatch(bool Function(String) condition) {
            bool cardHasIt = condition(cardNameEn) || condition(cardNameDe);
            bool placeholderHasIt = condition(p);
            return cardHasIt != placeholderHasIt;
         }
         if (checkMatch((t) => t.contains('vmax'))) return true;
         if (checkMatch((t) => t.contains('vstar'))) return true;
         if (checkMatch((t) => t.contains('mega') || t.startsWith('m ') || t.contains(' m ') || t.contains('m-') || t.contains('-mega'))) return true;
         if (checkMatch((t) => t.contains('primal') || t.contains('proto'))) return true;
         if (checkMatch((t) => t.contains('alola'))) return true;
         if (checkMatch((t) => t.contains('galar'))) return true;
         if (checkMatch((t) => t.contains('hisui'))) return true;
         if (checkMatch((t) => t.contains('paldea'))) return true;
         return false;
      }

      final query = db.select(db.binderCards).join([
        drift.innerJoin(db.binders, db.binders.id.equalsExp(db.binderCards.binderId))
      ]);

      // --- PERFORMANCE OPTIMIERUNG: Grobe Vorfilterung in der Datenbank ---
      final allCoreWords = {...getCoreWords(cardNameDe), ...getCoreWords(cardNameEn)}.where((w) => w.length > 1).toList();

      drift.Expression<bool> baseWhere;
      if (selectedBinderId != -1) {
        baseWhere = db.binderCards.binderId.equals(selectedBinderId);
      } else {
        baseWhere = db.binders.isFull.equals(false) & db.binders.rowsPerPage.isBiggerThanValue(0); 
      }

      if (allCoreWords.isNotEmpty) {
        final placeholderConditions = allCoreWords
            .map((word) => db.binderCards.placeholderLabel.lower().like('%$word%'))
            .toList();
        var combinedPlaceholderCondition = placeholderConditions.first;
        for (var i = 1; i < placeholderConditions.length; i++) {
            combinedPlaceholderCondition = combinedPlaceholderCondition | placeholderConditions[i];
        }
        query.where(baseWhere & combinedPlaceholderCondition);
      } else {
        query.where(baseWhere);
      }
      // --------------------------------------------------------------------

      final allJoined = await query.get();
      final allSlots = allJoined.map((row) => _SlotInfo(row.readTable(db.binderCards), row.readTable(db.binders))).toList();

      List<_SlotInfo> potentialSlots = allSlots.where((info) {
        final slot = info.slot;
        if (slot.placeholderLabel?.startsWith('DIVIDER:') ?? false) return false;

        String pLabel = slot.placeholderLabel ?? '';
        if (pLabel.contains(" ")) {
          final parts = pLabel.split(" ");
          if (parts.first.startsWith("#") || parts.first.startsWith("✨")) pLabel = parts.sublist(1).join(" ");
        }
        pLabel = pLabel.toLowerCase();
        if (pLabel.isEmpty) return false;

        if (isFormMismatch(pLabel)) return false;
        
        final cWordsDe = getCoreWords(cardNameDe);
        final cWordsEn = getCoreWords(cardNameEn);

        final pWords = getCoreWords(pLabel);
        if (pWords.isEmpty) return false;

        bool matchDe = cWordsDe.isNotEmpty && (pWords.every((w) => cWordsDe.contains(w)) || cWordsDe.every((w) => pWords.contains(w)));
        bool matchEn = cWordsEn.isNotEmpty && (pWords.every((w) => cWordsEn.contains(w)) || cWordsEn.every((w) => pWords.contains(w)));

        return matchDe || matchEn;
      }).toList();

      if (potentialSlots.isNotEmpty) {
        potentialSlots.sort((a, b) {
          if (a.slot.isPlaceholder && !b.slot.isPlaceholder) return -1;
          if (!a.slot.isPlaceholder && b.slot.isPlaceholder) return 1;

          final aLabel = a.slot.placeholderLabel?.toLowerCase() ?? '';
          final bLabel = b.slot.placeholderLabel?.toLowerCase() ?? '';
          
          bool aExact = (cardNameDe.isNotEmpty && aLabel == cardNameDe) || aLabel == cardNameEn;
          bool bExact = (cardNameDe.isNotEmpty && bLabel == cardNameDe) || bLabel == cardNameEn;
          
          if (aExact && !bExact) return -1;
          if (!aExact && bExact) return 1;
          return 0; 
        });

        bool didFill = false;
        
        for (final info in potentialSlots) {
          if (didFill) break; // Wir tauschen nur EINE Karte ein
          
          final slot = info.slot;
          final binder = info.binder;

          final page = slot.pageIndex + 1;
          int row = 1;
          int col = 1;
          
          if (binder.sortOrder == 'topToBottom') {
             row = (slot.slotIndex % binder.rowsPerPage) + 1;
             col = (slot.slotIndex / binder.rowsPerPage).floor() + 1;
          } else {
             row = (slot.slotIndex / binder.columnsPerPage).floor() + 1;
             col = (slot.slotIndex % binder.columnsPerPage) + 1;
          }

          final locationText = "${binder.name}\nSeite $page • Zeile $row • Spalte $col";

          bool? userConfirmed = false;

          // DER SCHÖNE BESTÄTIGUNGSDIALOG
          if (slot.isPlaceholder) {
            if (!mounted) continue;
            userConfirmed = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                title: const Text("Freier Platz gefunden!"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Es gibt einen perfekten, leeren Platzhalter für diese Karte. Möchtest du sie hier ablegen?", style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(child: Text(locationText, style: const TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(slot.placeholderLabel ?? 'Platzhalter', style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 2),
                              const SizedBox(height: 4),
                              Container(
                                height: 110, width: 80,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  border: Border.all(color: Colors.grey, width: 2),
                                  borderRadius: BorderRadius.circular(6)
                                ),
                                child: const Center(child: Icon(Icons.image_not_supported, color: Colors.grey, size: 40)),
                              ),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Icon(Icons.arrow_forward_rounded, color: Colors.green, size: 36),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text("Neu (${_selectedUserCard!.variant})", style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              CachedNetworkImage(
                                imageUrl: widget.card.displayImage, 
                                memCacheHeight: 200,
                                height: 110,
                                placeholder: (_,__) => const SizedBox(height: 110, child: Center(child: CircularProgressIndicator())),
                                errorWidget: (_,__,___) => const Icon(Icons.broken_image, size: 50),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), style: TextButton.styleFrom(foregroundColor: Colors.grey[700]), child: const Text("Überspringen")),
                  FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.green[700]), child: const Text("Einsortieren")),
                ],
              )
            );
          } else {
            final oldCard = slot.cardId != null 
                ? await (db.select(db.cards)..where((tbl) => tbl.id.equals(slot.cardId!))).getSingleOrNull()
                : null;
            final oldVariant = slot.variant ?? "Normal";

            if (!mounted) continue;
            userConfirmed = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                title: const Text("Slot bereits belegt!"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("In diesem Binder-Slot liegt bereits eine Karte. Möchtest du sie durch die ausgewählte Karte ersetzen?", style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(child: Text(locationText, style: const TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text("Aktuell ($oldVariant)", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              const SizedBox(height: 4),
                              if (oldCard != null)
                                CachedNetworkImage(
                                  imageUrl: oldCard.imageUrl,
                                  memCacheHeight: 200, 
                                  height: 110,
                                  placeholder: (_,__) => const SizedBox(height: 110, child: Center(child: CircularProgressIndicator())),
                                  errorWidget: (_,__,___) => const Icon(Icons.broken_image, size: 50),
                                )
                              else
                                const Icon(Icons.broken_image, size: 50),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Icon(Icons.arrow_forward_rounded, color: Colors.blueAccent, size: 36),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text("Neu (${_selectedUserCard!.variant})", style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              CachedNetworkImage(
                                imageUrl: widget.card.displayImage, 
                                memCacheHeight: 200,
                                height: 110,
                                placeholder: (_,__) => const SizedBox(height: 110, child: Center(child: CircularProgressIndicator())),
                                errorWidget: (_,__,___) => const Icon(Icons.broken_image, size: 50),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), style: TextButton.styleFrom(foregroundColor: Colors.grey[700]), child: const Text("Überspringen")),
                  FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.blue[800]), child: const Text("Austauschen")),
                ],
              )
            );
          }

          if (userConfirmed == true) {
            await binderService.fillSlot(slot.id, widget.card.id, _selectedUserCard!.id, variant: _selectedUserCard!.variant);
            binderService.recalculateBinderValue(slot.binderId);
            didFill = true;
            binderMessage = "\nund erfolgreich in Binder-Slot einsortiert!";
          }
        }
        
        if (!didFill) {
          binderMessage = "\n(Sortierung abgebrochen oder übersprungen)";
          showOrangeBanner = true; 
        }
      } else {
        binderMessage = "\n(Kein passender Platz in der Auswahl gefunden)";
        showOrangeBanner = true; 
      }

      if (mounted) {
        Navigator.pop(context, true);
        final bannerColor = showOrangeBanner ? Colors.orange[800]! : Colors.green;
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedUserCard!.variant} verarbeitet!$binderMessage'), 
            backgroundColor: bannerColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          )
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Fehler: $e"), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating, duration: const Duration(milliseconds: 500)));
      }
    }
  }
}