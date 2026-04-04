import 'package:flutter/material.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../../data/database/app_database.dart' as db; 
import '../../data/database/database_provider.dart';
import '../../data/sync/pokedex_importer.dart';

class TranslationProposal {
  final db.Card card;
  final TextEditingController controller; 
  bool isSelected;
  final bool isSafe; 

  TranslationProposal({
    required this.card, 
    required String proposedNameDe, 
    this.isSelected = true,
    required this.isSafe,
  }) : controller = TextEditingController(text: proposedNameDe);

  void dispose() {
    controller.dispose();
  }
}

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  bool _isLoading = false;
  String _statusText = "Bereit.";
  
  List<TranslationProposal> _proposals = [];

  // --- NEU: Zustand für die einklappbaren Bereiche ---
  bool _isSafeExpanded = false;  // Sichere Treffer klappen wir standardmäßig ein (spart massiv Platz)
  bool _isReviewExpanded = true; // Zu überprüfende klappen wir aus

  @override
  void dispose() {
    _clearProposals();
    super.dispose();
  }

  void _clearProposals() {
    for (var p in _proposals) { p.dispose(); }
    _proposals.clear();
  }

  // --- 1. WÖRTERBUCH AUFBAUEN ---
  Future<void> _buildDictionary() async {
    setState(() { _isLoading = true; _statusText = "Starte Wörterbuch-Download..."; });
    final database = ref.read(databaseProvider);
    final importer = PokedexImporter(database);
    await importer.buildTranslationDictionary(onProgress: (status) => setState(() => _statusText = status));
    setState(() { _isLoading = false; });
  }

  // --- 2. ÜBERSETZUNGS-ALGORITHMUS ---
  Future<void> _generateProposals() async {
    setState(() { _isLoading = true; _statusText = "Analysiere Karten..."; _clearProposals(); });
    
    final dbase = ref.read(databaseProvider);
    
    final dex = await (dbase.select(dbase.pokedex)..where((t) => t.nameDe.isNotNull() & t.nameDe.isNotValue(''))).get();
    dex.sort((a, b) => b.name.length.compareTo(a.name.length));

    final cards = await (dbase.select(dbase.cards)..where((t) => 
        t.nameDe.isNull() | t.nameDe.equals('') | t.nameDe.equalsExp(t.name)
    )).get();

    List<TranslationProposal> newProposals = [];

    for (var card in cards) {
      String engName = card.name;
      String? foundGermanBase;
      bool isExactMatch = false;

      for (var p in dex) {
        if (engName.toLowerCase() == p.name.toLowerCase()) {
           foundGermanBase = p.nameDe;
           isExactMatch = true;
           break;
        }

        final regExp = RegExp(r'\b' + RegExp.escape(p.name) + r'\b', caseSensitive: false);
        if (regExp.hasMatch(engName)) {
          String translatedName = engName.replaceAllMapped(regExp, (match) => p.nameDe!);

          // TCG Wörterbuch
          translatedName = translatedName.replaceAll(RegExp(r'\bDark\b', caseSensitive: false), 'Dunkles');
          translatedName = translatedName.replaceAll(RegExp(r'\bLight\b', caseSensitive: false), 'Helles');
          translatedName = translatedName.replaceAll(RegExp(r'\bShining\b', caseSensitive: false), 'Schimmerndes');
          translatedName = translatedName.replaceAll(RegExp(r'\bRadiant\b', caseSensitive: false), 'Strahlendes');
          translatedName = translatedName.replaceAll(RegExp(r'\bShadow\b', caseSensitive: false), 'Crypto');
          
          translatedName = translatedName.replaceAll(RegExp(r'\bAlolan\b', caseSensitive: false), 'Alola');
          translatedName = translatedName.replaceAll(RegExp(r'\bGalarian\b', caseSensitive: false), 'Galar');
          translatedName = translatedName.replaceAll(RegExp(r'\bHisuian\b', caseSensitive: false), 'Hisui');
          translatedName = translatedName.replaceAll(RegExp(r'\bPaldean\b', caseSensitive: false), 'Paldea');
          
          translatedName = translatedName.replaceAllMapped(RegExp(r"\b([A-Za-z]+)'s\b", caseSensitive: false), (match) {
            String base = match.group(1)!;
            return "${base[0].toUpperCase()}${base.substring(1).toLowerCase()}s";
          });

          translatedName = translatedName.replaceAllMapped(RegExp(r'\b(ex|gx|v|vmax|vstar)\b', caseSensitive: false), (match) {
            return match.group(1)!.toUpperCase();
          });
          
          foundGermanBase = translatedName;
          break; 
        }
      }

      if (foundGermanBase != null && foundGermanBase.toLowerCase() != engName.toLowerCase()) {
        newProposals.add(TranslationProposal(
          card: card, 
          proposedNameDe: foundGermanBase,
          isSafe: isExactMatch,
        ));
      }
    }

    setState(() { 
      _proposals = newProposals;
      _isLoading = false; 
      _statusText = "${newProposals.length} Vorschläge gefunden!"; 
    });
  }

  // --- 3. SPEICHERN ---
  Future<void> _saveProposals() async {
    final selected = _proposals.where((p) => p.isSelected).toList();
    if (selected.isEmpty) return;

    setState(() { _isLoading = true; _statusText = "Speichere ${selected.length} Übersetzungen..."; });
    final dbase = ref.read(databaseProvider);
    
    await dbase.batch((batch) {
      for (var prop in selected) {
        batch.update(dbase.cards, 
          db.CardsCompanion( 
            nameDe: drift.Value(prop.controller.text), 
            hasManualTranslations: const drift.Value(true),
          ),
          where: (t) => t.id.equals(prop.card.id)
        );
      }
    });

    setState(() {
      for (var p in selected) { p.dispose(); } 
      _proposals.removeWhere((p) => p.isSelected);
      _isLoading = false;
      _statusText = "Erfolgreich gespeichert!";
    });
  }

  @override
  Widget build(BuildContext context) {
    final safeProposals = _proposals.where((p) => p.isSafe).toList();
    final reviewProposals = _proposals.where((p) => !p.isSafe).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: const Text("Dev Dashboard"), backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
      body: Column(
        children: [
          // --- HEADER & BUTTONS ---
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text("Status: $_statusText", style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: FilledButton.icon(onPressed: _isLoading ? null : _buildDictionary, icon: const Icon(Icons.book), label: const Text("1. Pokedex"))),
                    const SizedBox(width: 8),
                    Expanded(child: FilledButton.icon(onPressed: _isLoading ? null : _generateProposals, icon: const Icon(Icons.translate), label: const Text("2. Übersetzen"), style: FilledButton.styleFrom(backgroundColor: Colors.orange[700]))),
                  ],
                ),
                if (_isLoading) ...[const SizedBox(height: 16), const LinearProgressIndicator()],
              ],
            ),
          ),
          
          if (_proposals.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.deepPurple.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${_proposals.where((p) => p.isSelected).length} ausgewählt", style: const TextStyle(fontWeight: FontWeight.bold)),
                  FilledButton.icon(onPressed: _isLoading ? null : _saveProposals, icon: const Icon(Icons.save), label: const Text("Speichern"), style: FilledButton.styleFrom(backgroundColor: Colors.green))
                ],
              ),
            ),
            
            // --- DIE GESTAFFELTE LISTE (CustomScrollView) ---
            Expanded(
              child: CustomScrollView(
                slivers: [
                  // 1. Sektion: SICHERE TREFFER
                  if (safeProposals.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _buildSectionHeader(
                        title: "✅ Exakte Treffer (${safeProposals.length})", 
                        color: Colors.green,
                        sectionProposals: safeProposals,
                        isExpanded: _isSafeExpanded,
                        onToggleExpand: () => setState(() => _isSafeExpanded = !_isSafeExpanded),
                      ),
                    ),
                    if (_isSafeExpanded)
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildProposalItem(safeProposals[index]),
                          childCount: safeProposals.length,
                        ),
                      ),
                  ],

                  // 2. Sektion: ZUR ÜBERPRÜFUNG
                  if (reviewProposals.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _buildSectionHeader(
                        title: "⚠️ Zur Überprüfung (${reviewProposals.length})", 
                        color: Colors.orange[800]!,
                        sectionProposals: reviewProposals,
                        isExpanded: _isReviewExpanded,
                        onToggleExpand: () => setState(() => _isReviewExpanded = !_isReviewExpanded),
                      ),
                    ),
                    if (_isReviewExpanded)
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildProposalItem(reviewProposals[index]),
                          childCount: reviewProposals.length,
                        ),
                      ),
                  ]
                ],
              ),
            ),
          ] else if (!_isLoading) ...[
             const Expanded(child: Center(child: Text("Keine Vorschläge.", style: TextStyle(color: Colors.grey)))),
          ]
        ],
      ),
    );
  }

  // --- NEU: Master-Header (Ausklappbar & Master-Checkbox) ---
  Widget _buildSectionHeader({
    required String title, 
    required Color color, 
    required List<TranslationProposal> sectionProposals,
    required bool isExpanded,
    required VoidCallback onToggleExpand,
  }) {
    // Ermittelt den Zustand der Master-Checkbox
    bool allSelected = sectionProposals.every((p) => p.isSelected);
    bool noneSelected = sectionProposals.every((p) => !p.isSelected);
    bool? checkboxState = allSelected ? true : (noneSelected ? false : null);

    return Material(
      color: color.withOpacity(0.1),
      child: InkWell(
        onTap: onToggleExpand, // Klick auf die Leiste klappt auf/zu
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Checkbox(
                tristate: true,
                value: checkboxState,
                activeColor: color,
                onChanged: (val) {
                  setState(() {
                    // Wenn der Zustand vorher "gemischt" (null) war, machen wir bei Klick "Alle an"
                    bool targetState = (checkboxState == null) ? true : (val ?? false);
                    for (var p in sectionProposals) {
                      p.isSelected = targetState;
                    }
                  });
                },
              ),
              Expanded(
                child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              ),
              Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: color),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  // --- Einzelnes Listen-Element ---
  Widget _buildProposalItem(TranslationProposal prop) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Checkbox(
              value: prop.isSelected,
              activeColor: Colors.deepPurple,
              onChanged: (val) => setState(() => prop.isSelected = val ?? false),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Original: ${prop.card.name} (${prop.card.setId.toUpperCase()})", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  TextField(
                    controller: prop.controller,
                    decoration: const InputDecoration(isDense: true, border: InputBorder.none, contentPadding: EdgeInsets.zero),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}