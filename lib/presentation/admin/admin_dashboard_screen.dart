import 'dart:io';
import 'package:flutter/material.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';

import '../../data/database/app_database.dart' as db; 
import '../../data/database/database_provider.dart';
import '../../data/sync/pokedex_importer.dart';

// ==========================================
// MODELLE
// ==========================================

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

  void dispose() => controller.dispose();
}

class CardEditorItem {
  final db.Card card;
  final TextEditingController imgEnCtrl;
  final TextEditingController artistCtrl;
  String? cmUrl; 

  CardEditorItem({required this.card, this.cmUrl}) 
    : imgEnCtrl = TextEditingController(text: card.imageUrl),
      artistCtrl = TextEditingController(text: card.artist);

  void dispose() {
    imgEnCtrl.dispose();
    artistCtrl.dispose();
  }
}

// ==========================================
// SCREEN
// ==========================================

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  // --- Translator State ---
  bool _isLoadingTranslator = false;
  String _statusTranslator = "Bereit.";
  List<TranslationProposal> _proposals = [];
  bool _isSafeExpanded = false;  
  bool _isReviewExpanded = true; 

  // --- Image Manager State ---
  bool _isLoadingEditor = false;
  List<CardEditorItem> _editorItems = [];
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _newNumberCtrl = TextEditingController();
  final TextEditingController _newNameEnCtrl = TextEditingController();
  final TextEditingController _newNameDeCtrl = TextEditingController();
  final TextEditingController _newImgCtrl = TextEditingController();
  final TextEditingController _newArtistCtrl = TextEditingController();
  String? _newSelectedSetId;
  List<dynamic> _availableSets = [];

  @override
  void initState() {
    super.initState();
    _loadMissingImages();
    // Falls du den Namen-Gruppierer aus der letzten Nachricht nutzt:
    // _loadMissingTranslations(); 
    _loadSetsForDropdown(); // <--- NEU
  }

  Future<void> _loadSetsForDropdown() async {
    final dbase = ref.read(databaseProvider);
    // Lade alle Sets sortiert nach Release-Datum (Neueste zuerst)
    final sets = await (dbase.select(dbase.cardSets)
      ..orderBy([(t) => drift.OrderingTerm(expression: t.releaseDate, mode: drift.OrderingMode.desc)])
    ).get();
    
    if (mounted) {
      setState(() {
        _availableSets = sets;
      });
    }
  }

  @override
  void dispose() {
    _clearProposals();
    _clearEditorItems();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _clearProposals() {
    for (var p in _proposals) { p.dispose(); }
    _proposals.clear();
  }

  void _clearEditorItems() {
    for (var i in _editorItems) { i.dispose(); }
    _editorItems.clear();
  }

  // ==========================================
  // TAB 1: ÜBERSETZER 
  // ==========================================
  
  Future<void> _buildDictionary() async {
    setState(() { _isLoadingTranslator = true; _statusTranslator = "Starte Wörterbuch..."; });
    final database = ref.read(databaseProvider);
    final importer = PokedexImporter(database);
    await importer.buildTranslationDictionary(onProgress: (status) => setState(() => _statusTranslator = status));
    setState(() { _isLoadingTranslator = false; });
  }

  Future<void> _generateProposals() async {
    setState(() { _isLoadingTranslator = true; _statusTranslator = "Analysiere..."; _clearProposals(); });
    final dbase = ref.read(databaseProvider);
    final dex = await (dbase.select(dbase.pokedex)..where((t) => t.nameDe.isNotNull() & t.nameDe.isNotValue(''))).get();
    dex.sort((a, b) => b.name.length.compareTo(a.name.length));
    final cards = await (dbase.select(dbase.cards)..where((t) => t.nameDe.isNull() | t.nameDe.equals('') | t.nameDe.equalsExp(t.name))).get();

    List<TranslationProposal> newProposals = [];
    final Map<String, String> trainerDict = {
      "Brock's": "Rockos", "Misty's": "Mistys", "Lt. Surge's": "Major Bobs",
      "Erika's": "Erikas", "Koga's": "Kogas", "Sabrina's": "Sabrinas",
      "Blaine's": "Pyros", "Giovanni's": "Giovannis", "Rocket's": "Rockets", 
      "Lance's": "Siegfrieds", "Falkner's": "Falks", "Bugsy's": "Kais",
      "Whitney's": "Biankas", "Morty's": "Jens'", "Jasmine's": "Jasmins",
      "Chuck's": "Hartwigs", "Pryce's": "Norberts", "Clair's": "Sandras",
      "Professor Oak's": "Professor Eichs", "Team Aqua's": "Team Aquas",
      "Team Magma's": "Team Magmas", "Team Plasma's": "Team Plasmas",
    };

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

        String searchPattern = RegExp.escape(p.name).replaceAll(r'\-', r'[\s-]+');
        final regExp = RegExp(r'\b' + searchPattern + r'\b', caseSensitive: false);
        
        if (regExp.hasMatch(engName)) {
          String translatedName = engName.replaceAllMapped(regExp, (match) => p.nameDe!);

          trainerDict.forEach((engTrainer, gerTrainer) {
            translatedName = translatedName.replaceAll(RegExp(RegExp.escape(engTrainer), caseSensitive: false), gerTrainer);
          });

          translatedName = translatedName.replaceAll(RegExp(r'\bDark\b', caseSensitive: false), 'Dunkles');
          translatedName = translatedName.replaceAll(RegExp(r'\bLight\b', caseSensitive: false), 'Helles');
          translatedName = translatedName.replaceAll(RegExp(r'\bShining\b', caseSensitive: false), 'Schimmerndes');
          translatedName = translatedName.replaceAll(RegExp(r'\bRadiant\b', caseSensitive: false), 'Strahlendes');
          translatedName = translatedName.replaceAll(RegExp(r'\bShadow\b', caseSensitive: false), 'Crypto');
          
          translatedName = translatedName.replaceAllMapped(RegExp(r'[\s-]+Spirit Link\b', caseSensitive: false), (match) => '-Geisterbund');
          
          translatedName = translatedName.replaceAll(RegExp(r'\bAlolan\b', caseSensitive: false), 'Alola');
          translatedName = translatedName.replaceAll(RegExp(r'\bGalarian\b', caseSensitive: false), 'Galar');
          translatedName = translatedName.replaceAll(RegExp(r'\bHisuian\b', caseSensitive: false), 'Hisui');
          translatedName = translatedName.replaceAll(RegExp(r'\bPaldean\b', caseSensitive: false), 'Paldea');
          
          translatedName = translatedName.replaceAllMapped(RegExp(r"\b([A-Za-z]+)'s\b", caseSensitive: false), (match) {
            String base = match.group(1)!;
            return "${base[0].toUpperCase()}${base.substring(1).toLowerCase()}s";
          });

          translatedName = translatedName.replaceAllMapped(RegExp(r'\b(Mega)[\s-]+', caseSensitive: false), (match) => 'Mega-');
          translatedName = translatedName.replaceAllMapped(RegExp(r'[\s-]+(ex|gx|v|vmax|vstar|break)\b', caseSensitive: false), (match) {
            String suffix = match.group(1)!.toUpperCase();
            if (suffix == 'BREAK') suffix = 'TURBO';
            return '-$suffix';
          });
          
          foundGermanBase = translatedName;
          break; 
        }
      }

      if (foundGermanBase != null && foundGermanBase.toLowerCase() != engName.toLowerCase()) {
        newProposals.add(TranslationProposal(card: card, proposedNameDe: foundGermanBase, isSafe: isExactMatch));
      }
    }

    setState(() { _proposals = newProposals; _isLoadingTranslator = false; _statusTranslator = "${newProposals.length} Vorschläge gefunden!"; });
  }

  Future<void> _saveProposals() async {
    final selected = _proposals.where((p) => p.isSelected).toList();
    if (selected.isEmpty) return;

    setState(() { _isLoadingTranslator = true; _statusTranslator = "Speichere ${selected.length} Übersetzungen..."; });
    final dbase = ref.read(databaseProvider);
    
    await dbase.batch((batch) {
      for (var prop in selected) {
        batch.update(dbase.cards, 
          db.CardsCompanion(nameDe: drift.Value(prop.controller.text), hasManualTranslations: const drift.Value(true)),
          where: (t) => t.id.equals(prop.card.id)
        );
      }
    });

    setState(() {
      for (var p in selected) { p.dispose(); } 
      _proposals.removeWhere((p) => p.isSelected);
      _isLoadingTranslator = false;
      _statusTranslator = "Erfolgreich gespeichert!";
    });
  }

  Future<void> _confirmAndResetTranslations() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Notfall Reset", style: TextStyle(color: Colors.red)),
        content: const Text("Möchtest du wirklich ALLE manuellen Übersetzungen löschen?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Abbrechen")),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(ctx, true), child: const Text("Ja, alles löschen")),
        ],
      )
    );

    if (confirm != true) return;

    setState(() { _isLoadingTranslator = true; _statusTranslator = "Lösche manuelle Übersetzungen..."; _clearProposals(); });
    final dbase = ref.read(databaseProvider);
    final updatedRows = await (dbase.update(dbase.cards)..where((t) => t.hasManualTranslations.equals(true)))
        .write(const db.CardsCompanion(nameDe: drift.Value(null), hasManualTranslations: drift.Value(false)));

    setState(() { _isLoadingTranslator = false; _statusTranslator = "✅ Reset erfolgreich! ($updatedRows Karten zurückgesetzt)"; });
  }


  // ==========================================
  // TAB 2: BILDER & DATEN EDITOR (Nur EN Bilder)
  // ==========================================

  Future<void> _loadMissingImages() async {
    setState(() { _isLoadingEditor = true; _clearEditorItems(); });
    final dbase = ref.read(databaseProvider);

    // Lädt max 100 Karten, denen das ENGLISCHE Bild fehlt
    final cards = await (dbase.select(dbase.cards)
      ..where((t) => t.imageUrl.equals('') | t.imageUrl.isNull())
      ..limit(100)
    ).get();

    await _populateEditorItems(cards, dbase);
  }

  Future<void> _searchCardsToEdit(String query) async {
    if (query.isEmpty) return;
    setState(() { _isLoadingEditor = true; _clearEditorItems(); });
    final dbase = ref.read(databaseProvider);

    final cards = await (dbase.select(dbase.cards)
      ..where((t) => t.name.like('%$query%') | t.nameDe.like('%$query%'))
      ..limit(100)
    ).get();

    await _populateEditorItems(cards, dbase);
  }

  Future<void> _populateEditorItems(List<db.Card> cards, db.AppDatabase dbase) async {
    List<CardEditorItem> newItems = [];
    
    for (var c in cards) {
      final cmPrice = await (dbase.select(dbase.cardMarketPrices)
        ..where((t) => t.cardId.equals(c.id))
        ..orderBy([(t) => drift.OrderingTerm(expression: t.fetchedAt, mode: drift.OrderingMode.desc)])
        ..limit(1)
      ).getSingleOrNull();

      newItems.add(CardEditorItem(card: c, cmUrl: cmPrice?.url));
    }

    setState(() {
      _editorItems = newItems;
      _isLoadingEditor = false;
    });
  }

  Future<void> _saveEditorItem(CardEditorItem item) async {
    final dbase = ref.read(databaseProvider);
    
    await (dbase.update(dbase.cards)..where((t) => t.id.equals(item.card.id))).write(
      db.CardsCompanion(
        imageUrl: drift.Value(item.imgEnCtrl.text.trim()),
        artist: drift.Value(item.artistCtrl.text.trim()),
        hasManualImages: const drift.Value(true), 
        hasManualStats: const drift.Value(true),  
      )
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Karte gespeichert!"), backgroundColor: Colors.green, duration: Duration(seconds: 1))
    );
  }

  void _openCardmarket(CardEditorItem item) async {
    String url = item.cmUrl ?? "";
    if (url.isEmpty) {
      url = 'https://www.cardmarket.com/de/Pokemon/Products/Search?searchString=${Uri.encodeComponent(item.card.name)}';
    }
    
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ==========================================
  // UI BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text("Dev Dashboard"), 
          backgroundColor: Colors.deepPurple, 
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorColor: Colors.orange,
            tabs: [
              Tab(icon: Icon(Icons.translate), text: "Übersetzer"),
              Tab(icon: Icon(Icons.image_search), text: "Bilder & Daten"),
              Tab(icon: Icon(Icons.add_card), text: "Neue Karte")
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTranslatorTab(),
            _buildImageManagerTab(),
            _buildCreateCardTab(),
          ],
        ),
      ),
    );
  }

  // --- TAB 1 UI ---
  Widget _buildTranslatorTab() {
    final safeProposals = _proposals.where((p) => p.isSafe).toList();
    final reviewProposals = _proposals.where((p) => !p.isSafe).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("Status: $_statusTranslator", style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: FilledButton.icon(onPressed: _isLoadingTranslator ? null : _buildDictionary, icon: const Icon(Icons.book), label: const Text("1. Pokedex"))),
                  const SizedBox(width: 8),
                  Expanded(child: FilledButton.icon(onPressed: _isLoadingTranslator ? null : _generateProposals, icon: const Icon(Icons.translate), label: const Text("2. Übersetzen"), style: FilledButton.styleFrom(backgroundColor: Colors.orange[700]))),
                ],
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _isLoadingTranslator ? null : _confirmAndResetTranslations, 
                icon: const Icon(Icons.warning_amber, color: Colors.red), 
                label: const Text("Notfall: Alle Übersetzungen zurücksetzen", style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
              ),
              if (_isLoadingTranslator) ...[const SizedBox(height: 16), const LinearProgressIndicator()],
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
                FilledButton.icon(onPressed: _isLoadingTranslator ? null : _saveProposals, icon: const Icon(Icons.save), label: const Text("Speichern"), style: FilledButton.styleFrom(backgroundColor: Colors.green))
              ],
            ),
          ),
          
          Expanded(
            child: CustomScrollView(
              slivers: [
                if (safeProposals.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      title: "✅ Exakte Treffer (${safeProposals.length})", color: Colors.green, sectionProposals: safeProposals,
                      isExpanded: _isSafeExpanded, onToggleExpand: () => setState(() => _isSafeExpanded = !_isSafeExpanded),
                    ),
                  ),
                  if (_isSafeExpanded)
                    SliverList(delegate: SliverChildBuilderDelegate((context, index) => _buildProposalItem(safeProposals[index]), childCount: safeProposals.length)),
                ],
                if (reviewProposals.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      title: "⚠️ Zur Überprüfung (${reviewProposals.length})", color: Colors.orange[800]!, sectionProposals: reviewProposals,
                      isExpanded: _isReviewExpanded, onToggleExpand: () => setState(() => _isReviewExpanded = !_isReviewExpanded),
                    ),
                  ),
                  if (_isReviewExpanded)
                    SliverList(delegate: SliverChildBuilderDelegate((context, index) => _buildProposalItem(reviewProposals[index]), childCount: reviewProposals.length)),
                ]
              ],
            ),
          ),
        ] else if (!_isLoadingTranslator) ...[
           const Expanded(child: Center(child: Text("Keine Vorschläge.", style: TextStyle(color: Colors.grey)))),
        ]
      ],
    );
  }

  // --- TAB 2 UI ---
  Widget _buildImageManagerTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // Zieht Buttons auf volle Breite
            children: [
              // --- NEUER SYNC BUTTON ---
              FilledButton.icon(
                onPressed: _isLoadingEditor ? null : _syncApiDatabaseFromPC, 
                icon: const Icon(Icons.sync), 
                label: const Text("API-Datenbank vom PC importieren (.sqlite)"),
                style: FilledButton.styleFrom(backgroundColor: Colors.blue),
              ),
              const SizedBox(height: 12),
              
              // --- ALTER BILDER BUTTON ---
              FilledButton.icon(
                onPressed: _isLoadingEditor ? null : _loadMissingImages, 
                icon: const Icon(Icons.broken_image), 
                label: const Text("Fehlende EN-Bilder laden (Max 100)"),
                style: FilledButton.styleFrom(backgroundColor: Colors.deepPurple),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        labelText: "Manuelle Suche (z.B. Glurak)",
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (val) => _searchCardsToEdit(val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => _searchCardsToEdit(_searchCtrl.text), 
                    icon: const Icon(Icons.search)
                  )
                ],
              ),
              if (_isLoadingEditor) const Padding(padding: EdgeInsets.only(top: 16), child: LinearProgressIndicator())
            ],
          ),
        ),

        Expanded(
          child: _editorItems.isEmpty && !_isLoadingEditor
            ? const Center(child: Text("Keine Karten gefunden.", style: TextStyle(color: Colors.grey)))
            : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _editorItems.length,
                itemBuilder: (context, index) {
                  final item = _editorItems[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Kopfzeile: Name, Info & Cardmarket Link
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.card.nameDe ?? item.card.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text("EN: ${item.card.name}  |  Set: ${item.card.setId.toUpperCase()}  |  Nr: ${item.card.number}", style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                                  ],
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _openCardmarket(item),
                                icon: const Icon(Icons.open_in_browser, size: 16),
                                label: const Text("Cardmarket", style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                  side: BorderSide(color: Colors.blue[700]!),
                                  foregroundColor: Colors.blue[700]
                                ),
                              )
                            ],
                          ),
                          const Divider(),
                          
                          // Editor mit Live-Vorschau
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // VORSCHAU BOX
                              Container(
                                width: 70, height: 100,
                                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                                child: ValueListenableBuilder(
                                  valueListenable: item.imgEnCtrl,
                                  builder: (context, value, _) {
                                    if (value.text.isEmpty) return const Icon(Icons.add_a_photo, color: Colors.grey);
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: CachedNetworkImage(
                                        imageUrl: value.text,
                                        memCacheHeight: 200,
                                        fit: BoxFit.cover,
                                        errorWidget: (_,__,___) => const Icon(Icons.broken_image, color: Colors.red),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              // EINGABE FELDER
                              Expanded(
                                child: Column(
                                  children: [
                                    TextField(
                                      controller: item.imgEnCtrl,
                                      decoration: const InputDecoration(labelText: "Bild URL (Englisch / Fallback)", isDense: true),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: item.artistCtrl,
                                            decoration: const InputDecoration(labelText: "Künstler (Artist)", isDense: true),
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        FilledButton.icon(
                                          onPressed: () => _saveEditorItem(item), 
                                          icon: const Icon(Icons.save, size: 16), 
                                          label: const Text("Speichern"),
                                          style: FilledButton.styleFrom(backgroundColor: Colors.green),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        )
      ],
    );
  }

  // --- UI Hilfs-Widgets (Translator) ---
  Widget _buildSectionHeader({
    required String title, required Color color, required List<TranslationProposal> sectionProposals, required bool isExpanded, required VoidCallback onToggleExpand,
  }) {
    bool allSelected = sectionProposals.every((p) => p.isSelected);
    bool noneSelected = sectionProposals.every((p) => !p.isSelected);
    bool? checkboxState = allSelected ? true : (noneSelected ? false : null);

    return Material(
      color: color.withOpacity(0.1),
      child: InkWell(
        onTap: onToggleExpand,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Checkbox(
                tristate: true, value: checkboxState, activeColor: color,
                onChanged: (val) {
                  setState(() {
                    bool targetState = (checkboxState == null) ? true : (val ?? false);
                    for (var p in sectionProposals) {
                      p.isSelected = targetState;
                    }
                  });
                },
              ),
              Expanded(child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color))),
              Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: color),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProposalItem(TranslationProposal prop) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Checkbox(
              value: prop.isSelected, activeColor: Colors.deepPurple,
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

  Widget _buildCreateCardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Neue Karte manuell anlegen", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Ideal für Promo-Karten. Verwende die exakte Karten-Nummer (z.B. '030' oder '151'), damit sie später nahtlos mit API-Updates verschmilzt!", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),

          // SET DROPDOWN
          DropdownButtonFormField<String>(
            initialValue: _newSelectedSetId,
            decoration: const InputDecoration(labelText: 'Set auswählen (Pflicht)', border: OutlineInputBorder()),
            isExpanded: true,
            items: _availableSets.map((set) {
              return DropdownMenuItem<String>(
                value: set.id,
                child: Text("${set.name} (${set.id})", overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (val) => setState(() => _newSelectedSetId = val),
          ),
          const SizedBox(height: 16),

          // KARTEN NUMMER
          TextField(
            controller: _newNumberCtrl,
            decoration: const InputDecoration(labelText: 'Karten-Nummer (z.B. 030 oder 151)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.tag)),
          ),
          const SizedBox(height: 16),

          // ENGLISCHER NAME
          TextField(
            controller: _newNameEnCtrl,
            decoration: const InputDecoration(labelText: 'Name (Englisch) (Pflicht)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),

          // DEUTSCHER NAME
          TextField(
            controller: _newNameDeCtrl,
            decoration: const InputDecoration(labelText: 'Name (Deutsch) (Optional)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),

          // BILD URL
          TextField(
            controller: _newImgCtrl,
            decoration: const InputDecoration(labelText: 'Bild URL (.png/.jpg) (Optional aber empfohlen)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.image)),
          ),
          const SizedBox(height: 16),

          // KÜNSTLER
          TextField(
            controller: _newArtistCtrl,
            decoration: const InputDecoration(labelText: 'Künstler (Optional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.brush)),
          ),
          const SizedBox(height: 24),

          // SPEICHERN BUTTON
          FilledButton.icon(
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.green),
            onPressed: _createNewCard,
            icon: const Icon(Icons.save),
            label: const Text("Karte in Datenbank speichern", style: TextStyle(fontSize: 16)),
          )
        ],
      ),
    );
  }

  // ==========================================
  // API DATENBANK VOM PC SYNCHRONISIEREN
  // ==========================================
  Future<void> _syncApiDatabaseFromPC() async {
    try {
      // 1. Datei-Picker öffnen
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);

      // 2. Warn-Dialog & Bestätigung
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("API-Datenbank synchronisieren?"),
          content: const Text(
            "WICHTIG: Erstelle VORHER ein JSON-Backup deiner Nutzerdaten über das Seitenmenü!\n\n"
            "Diese Aktion kopiert alle Karten, Sets und Preise aus der gewählten PC-Datei in deine App.\n"
            "Deine Sammlung bleibt erhalten, aber manuelle Änderungen an Karten (Bilder, Namen) werden durch den PC-Stand überschrieben. Lade danach einfach dein JSON-Backup, um diese manuellen Änderungen wiederherzustellen!"
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Abbrechen")),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () => Navigator.pop(ctx, true), 
              child: const Text("Sync starten")
            ),
          ],
        )
      );

      if (confirm != true) return;

      setState(() { _isLoadingEditor = true; _statusTranslator = "Synchronisiere Datenbank..."; });
      final dbase = ref.read(databaseProvider);

      // --- DIE SQLITE MAGIC ---
      
      // A) Foreign Keys kurz aus, damit beim REPLACE von Karten nicht aus Versehen Inventar gelöscht wird!
      await dbase.customStatement('PRAGMA foreign_keys = OFF;');

      // B) PC Datenbank ankoppeln
      await dbase.customStatement("ATTACH DATABASE '${file.path}' AS pc_db;");

      // C) Tabellen in einem Rutsch auf C++ Ebene kopieren (Dauert Millisekunden!)
      await dbase.transaction(() async {
         await dbase.customStatement("REPLACE INTO card_sets SELECT * FROM pc_db.card_sets;");
         await dbase.customStatement("REPLACE INTO cards SELECT * FROM pc_db.cards;");
         await dbase.customStatement("REPLACE INTO pokedex SELECT * FROM pc_db.pokedex;");
         await dbase.customStatement("REPLACE INTO set_mappings SELECT * FROM pc_db.set_mappings;");
         
         // Bei Preisen löschen wir die alten restlos, da die PC-DB die aktuellsten hat
         await dbase.customStatement("DELETE FROM card_market_prices;");
         await dbase.customStatement("INSERT INTO card_market_prices SELECT * FROM pc_db.card_market_prices;");
         
         await dbase.customStatement("DELETE FROM tcg_player_prices;");
         await dbase.customStatement("INSERT INTO tcg_player_prices SELECT * FROM pc_db.tcg_player_prices;");
      });

      // D) Datenbank abkoppeln und Foreign Keys wieder an
      await dbase.customStatement("DETACH DATABASE pc_db;");
      await dbase.customStatement('PRAGMA foreign_keys = ON;');

      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Datenbank erfolgreich vom PC synchronisiert!"), backgroundColor: Colors.green)
         );
      }
    } catch (e) {
      // Fallback: Sicherstellen, dass die DB bei einem Fehler wieder abgekoppelt wird
      try {
         final dbase = ref.read(databaseProvider);
         await dbase.customStatement("DETACH DATABASE pc_db;");
         await dbase.customStatement('PRAGMA foreign_keys = ON;');
      } catch (_) {}
      
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Fehler beim Sync: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoadingEditor = false);
    }
  }

  Future<void> _createNewCard() async {
    final setId = _newSelectedSetId;
    final number = _newNumberCtrl.text.trim();
    final nameEn = _newNameEnCtrl.text.trim();
    final nameDe = _newNameDeCtrl.text.trim();
    final imgUrl = _newImgCtrl.text.trim();
    final artist = _newArtistCtrl.text.trim();

    if (setId == null || number.isEmpty || nameEn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("❌ Set, Nummer und EN-Name sind Pflichtfelder!"), backgroundColor: Colors.red));
      return;
    }

    // 1. Konstruiere die exakte TCGdex ID (z.B. "sve-017")
    final String cardId = "$setId-$number".toLowerCase();

    // --- NEU: Wir filtern alle Buchstaben raus, damit aus "017" die echte Zahl 17 wird! ---
    int sortNum = int.tryParse(number.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    final dbase = ref.read(databaseProvider);

    try {
      // 2. Karte in die Datenbank hämmern (JETZT MIT UPDATE-FUNKTION & SORTIERUNG)
      await dbase.into(dbase.cards).insertOnConflictUpdate(
        db.CardsCompanion.insert(
          id: cardId,
          setId: setId,
          name: nameEn,
          number: number,
          sortNumber: drift.Value(sortNum), // <--- HIER IST DER FIX FÜR DIE REIHENFOLGE!
          imageUrl: imgUrl,
          nameDe: nameDe.isNotEmpty ? drift.Value(nameDe) : const drift.Value.absent(),
          artist: artist.isNotEmpty ? drift.Value(artist) : const drift.Value.absent(),
          hasNormal: const drift.Value(true),
          hasHolo: const drift.Value(true),
          hasReverse: const drift.Value(true),
          hasWPromo: const drift.Value(true), 
          hasManualImages: const drift.Value(true),
          hasManualTranslations: const drift.Value(true),
          hasManualStats: const drift.Value(true),
          hasManualVariants: const drift.Value(true),
        )
      );

      // 3. UI aufräumen
      setState(() {
        _newNumberCtrl.clear();
        _newNameEnCtrl.clear();
        _newNameDeCtrl.clear();
        _newImgCtrl.clear();
        _newArtistCtrl.clear();
      });

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("✅ Karte $cardId erfolgreich gespeichert!"), backgroundColor: Colors.green));

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Fehler: $e"), backgroundColor: Colors.red));
    }
  }
}