import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:url_launcher/url_launcher.dart';

import '../../data/database/app_database.dart' as db;
import '../../data/database/database_provider.dart';
import '../../data/sync/database_sync_service.dart';
import '../../data/sync/pokedex_importer.dart';
import '../../domain/logic/card_translation_service.dart';
import 'models/admin_editor_models.dart';
import 'widgets/card_image_editor_tile.dart';
import 'widgets/manual_card_create_form.dart';
import 'widgets/proposal_item_tile.dart';
import 'widgets/proposal_section_header.dart';

/// Screen providing administrative tools: automated card translation heuristics,
/// missing image/metadata inspection, manual card creation, and external database syncing.
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
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

  // --- Create Card State ---
  final TextEditingController _newNumberCtrl = TextEditingController();
  final TextEditingController _newNameEnCtrl = TextEditingController();
  final TextEditingController _newNameDeCtrl = TextEditingController();
  final TextEditingController _newImgCtrl = TextEditingController();
  final TextEditingController _newArtistCtrl = TextEditingController();
  String? _newSelectedSetId;
  List<db.CardSet> _availableSets = [];

  @override
  void initState() {
    super.initState();
    _loadMissingImages();
    _loadSetsForDropdown();
  }

  /// Loads available card sets ordered by release date descending for dropdown selection.
  Future<void> _loadSetsForDropdown() async {
    final dbase = ref.read(databaseProvider);
    final sets = await (dbase.select(dbase.cardSets)
          ..orderBy([
            (t) => drift.OrderingTerm(
                expression: t.releaseDate, mode: drift.OrderingMode.desc)
          ]))
        .get();

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
    _newNumberCtrl.dispose();
    _newNameEnCtrl.dispose();
    _newNameDeCtrl.dispose();
    _newImgCtrl.dispose();
    _newArtistCtrl.dispose();
    super.dispose();
  }

  void _clearProposals() {
    for (final p in _proposals) {
      p.dispose();
    }
    _proposals.clear();
  }

  void _clearEditorItems() {
    for (final i in _editorItems) {
      i.dispose();
    }
    _editorItems.clear();
  }

  // ==========================================
  // TAB 1: CARD TRANSLATION HEURISTICS
  // ==========================================

  /// Builds the Pokédex English-German dictionary by importing official names.
  Future<void> _buildDictionary() async {
    setState(() {
      _isLoadingTranslator = true;
      _statusTranslator = "Starte Wörterbuch...";
    });
    final database = ref.read(databaseProvider);
    final importer = PokedexImporter(database);
    await importer.buildTranslationDictionary(
      onProgress: (status) {
        if (mounted) setState(() => _statusTranslator = status);
      },
    );
    if (mounted) {
      setState(() {
        _isLoadingTranslator = false;
      });
    }
  }

  /// Generates translation candidates using domain heuristic matching.
  Future<void> _generateProposals() async {
    setState(() {
      _isLoadingTranslator = true;
      _statusTranslator = "Analysiere...";
      _clearProposals();
    });

    final dbase = ref.read(databaseProvider);
    final translationService = CardTranslationService(dbase);
    final domainProposals = await translationService.generateProposals();

    final List<TranslationProposal> newProposals = domainProposals.map((p) {
      return TranslationProposal(
        card: p.card,
        proposedNameDe: p.proposedNameDe,
        isSafe: p.isSafe,
      );
    }).toList();

    if (mounted) {
      setState(() {
        _proposals = newProposals;
        _isLoadingTranslator = false;
        _statusTranslator = "${newProposals.length} Vorschläge gefunden!";
      });
    }
  }

  /// Persists checked translation proposals to the database.
  Future<void> _saveProposals() async {
    final selected = _proposals.where((p) => p.isSelected).toList();
    if (selected.isEmpty) return;

    setState(() {
      _isLoadingTranslator = true;
      _statusTranslator = "Speichere ${selected.length} Übersetzungen...";
    });

    final dbase = ref.read(databaseProvider);
    final translationService = CardTranslationService(dbase);

    final Map<String, String> translationMap = {
      for (final p in selected) p.card.id: p.controller.text.trim()
    };

    await translationService.saveTranslations(translationMap);

    if (mounted) {
      setState(() {
        for (final p in selected) {
          p.dispose();
        }
        _proposals.removeWhere((p) => p.isSelected);
        _isLoadingTranslator = false;
        _statusTranslator = "Erfolgreich gespeichert!";
      });
    }
  }

  /// Prompts confirmation and resets all manual translations in the database.
  Future<void> _confirmAndResetTranslations() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Notfall Reset", style: TextStyle(color: Colors.red)),
        content: const Text(
            "Möchtest du wirklich ALLE manuellen Übersetzungen löschen?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Abbrechen")),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Ja, alles löschen")),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoadingTranslator = true;
      _statusTranslator = "Lösche manuelle Übersetzungen...";
      _clearProposals();
    });

    final dbase = ref.read(databaseProvider);
    final translationService = CardTranslationService(dbase);
    final updatedRows = await translationService.resetManualTranslations();

    if (mounted) {
      setState(() {
        _isLoadingTranslator = false;
        _statusTranslator =
            "✅ Reset erfolgreich! ($updatedRows Karten zurückgesetzt)";
      });
    }
  }

  // ==========================================
  // TAB 2: IMAGE & METADATA EDITOR
  // ==========================================

  /// Loads up to 100 cards missing image URLs.
  Future<void> _loadMissingImages() async {
    setState(() {
      _isLoadingEditor = true;
      _clearEditorItems();
    });
    final dbase = ref.read(databaseProvider);

    final cards = await (dbase.select(dbase.cards)
          ..where((t) => t.imageUrl.equals('') | t.imageUrl.isNull())
          ..limit(100))
        .get();

    await _populateEditorItems(cards, dbase);
  }

  /// Searches cards by name or German name to edit image/artist metadata.
  Future<void> _searchCardsToEdit(String query) async {
    if (query.isEmpty) return;
    setState(() {
      _isLoadingEditor = true;
      _clearEditorItems();
    });
    final dbase = ref.read(databaseProvider);

    final cards = await (dbase.select(dbase.cards)
          ..where((t) => t.name.like('%$query%') | t.nameDe.like('%$query%'))
          ..limit(100))
        .get();

    await _populateEditorItems(cards, dbase);
  }

  /// Enriches cards with Cardmarket URLs and creates editor presentation models.
  Future<void> _populateEditorItems(
      List<db.Card> cards, db.AppDatabase dbase) async {
    final List<CardEditorItem> newItems = [];

    for (final c in cards) {
      final cmPrice = await (dbase.select(dbase.cardMarketPrices)
            ..where((t) => t.cardId.equals(c.id))
            ..orderBy([
              (t) => drift.OrderingTerm(
                  expression: t.fetchedAt, mode: drift.OrderingMode.desc)
            ])
            ..limit(1))
          .getSingleOrNull();

      newItems.add(CardEditorItem(card: c, cmUrl: cmPrice?.url));
    }

    if (mounted) {
      setState(() {
        _editorItems = newItems;
        _isLoadingEditor = false;
      });
    }
  }

  /// Saves updated image and artist metadata for a card.
  Future<void> _saveEditorItem(CardEditorItem item) async {
    final dbase = ref.read(databaseProvider);

    await (dbase.update(dbase.cards)..where((t) => t.id.equals(item.card.id)))
        .write(db.CardsCompanion(
      imageUrl: drift.Value(item.imgEnCtrl.text.trim()),
      artist: drift.Value(item.artistCtrl.text.trim()),
      hasManualImages: const drift.Value(true),
      hasManualStats: const drift.Value(true),
    ));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("✅ Karte gespeichert!"),
      backgroundColor: Colors.green,
      duration: Duration(seconds: 1),
    ));
  }

  /// Deep-links to the external Cardmarket product page.
  void _openCardmarket(CardEditorItem item) async {
    String url = item.cmUrl ?? "";
    if (url.isEmpty) {
      url =
          'https://www.cardmarket.com/de/Pokemon/Products/Search?searchString=${Uri.encodeComponent(item.card.name)}';
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ==========================================
  // EXTERNAL SQLITE DATABASE SYNCHRONIZATION
  // ==========================================

  /// Imports and synchronizes card catalog data from an external PC SQLite database file.
  Future<void> _syncApiDatabaseFromPC() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result == null || result.files.single.path == null) return;
      if (!mounted) return;

      final file = File(result.files.single.path!);

      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("API-Datenbank synchronisieren?"),
          content: const Text(
              "WICHTIG: Erstelle VORHER ein JSON-Backup deiner Nutzerdaten über das Seitenmenü!\n\n"
              "Diese Aktion kopiert alle Karten, Sets und Preise aus der gewählten PC-Datei in deine App.\n"
              "Deine Sammlung bleibt erhalten, aber manuelle Änderungen an Karten (Bilder, Namen) werden durch den PC-Stand überschrieben. Lade danach einfach dein JSON-Backup, um diese manuellen Änderungen wiederherzustellen!"),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("Abbrechen")),
            FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Sync starten")),
          ],
        ),
      );

      if (confirm != true) return;

      setState(() {
        _isLoadingEditor = true;
        _statusTranslator = "Synchronisiere Datenbank...";
      });

      final dbase = ref.read(databaseProvider);
      final syncService = DatabaseSyncService(dbase);
      await syncService.syncFromExternalDatabase(file.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("✅ Datenbank erfolgreich vom PC synchronisiert!"),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("❌ Fehler beim Sync: $e"),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingEditor = false);
      }
    }
  }

  // ==========================================
  // MANUAL CARD CREATION
  // ==========================================

  /// Validates and persists a manually created card entity.
  Future<void> _createNewCard() async {
    final setId = _newSelectedSetId;
    final number = _newNumberCtrl.text.trim();
    final nameEn = _newNameEnCtrl.text.trim();
    final nameDe = _newNameDeCtrl.text.trim();
    final imgUrl = _newImgCtrl.text.trim();
    final artist = _newArtistCtrl.text.trim();

    if (setId == null || number.isEmpty || nameEn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("❌ Set, Nummer und EN-Name sind Pflichtfelder!"),
        backgroundColor: Colors.red,
      ));
      return;
    }

    // Construct exact TCGdex card identifier (e.g. "sve-017")
    final String cardId = "$setId-$number".toLowerCase();

    // Extract numerical value for deterministic sorting order
    final int sortNum =
        int.tryParse(number.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    final dbase = ref.read(databaseProvider);

    try {
      await dbase.into(dbase.cards).insertOnConflictUpdate(
            db.CardsCompanion.insert(
              id: cardId,
              setId: setId,
              name: nameEn,
              number: number,
              sortNumber: drift.Value(sortNum),
              imageUrl: imgUrl,
              nameDe: nameDe.isNotEmpty
                  ? drift.Value(nameDe)
                  : const drift.Value.absent(),
              artist: artist.isNotEmpty
                  ? drift.Value(artist)
                  : const drift.Value.absent(),
              hasNormal: const drift.Value(true),
              hasHolo: const drift.Value(true),
              hasReverse: const drift.Value(true),
              hasWPromo: const drift.Value(true),
              hasManualImages: const drift.Value(true),
              hasManualTranslations: const drift.Value(true),
              hasManualStats: const drift.Value(true),
              hasManualVariants: const drift.Value(true),
            ),
          );

      setState(() {
        _newNumberCtrl.clear();
        _newNameEnCtrl.clear();
        _newNameDeCtrl.clear();
        _newImgCtrl.clear();
        _newArtistCtrl.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("✅ Karte $cardId erfolgreich gespeichert!"),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("❌ Fehler: $e"),
          backgroundColor: Colors.red,
        ));
      }
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
              Tab(icon: Icon(Icons.add_card), text: "Neue Karte"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTranslatorTab(),
            _buildImageManagerTab(),
            ManualCardCreateForm(
              availableSets: _availableSets,
              selectedSetId: _newSelectedSetId,
              onSetSelected: (val) => setState(() => _newSelectedSetId = val),
              numberController: _newNumberCtrl,
              nameEnController: _newNameEnCtrl,
              nameDeController: _newNameDeCtrl,
              imgController: _newImgCtrl,
              artistController: _newArtistCtrl,
              onSave: _createNewCard,
            ),
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
              Text("Status: $_statusTranslator",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed:
                          _isLoadingTranslator ? null : _buildDictionary,
                      icon: const Icon(Icons.book),
                      label: const Text("1. Pokedex"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed:
                          _isLoadingTranslator ? null : _generateProposals,
                      icon: const Icon(Icons.translate),
                      label: const Text("2. Übersetzen"),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed:
                    _isLoadingTranslator ? null : _confirmAndResetTranslations,
                icon: const Icon(Icons.warning_amber, color: Colors.red),
                label: const Text("Notfall: Alle Übersetzungen zurücksetzen",
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                ),
              ),
              if (_isLoadingTranslator) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
              ],
            ],
          ),
        ),
        if (_proposals.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.deepPurple.withValues(alpha: 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${_proposals.where((p) => p.isSelected).length} ausgewählt",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                FilledButton.icon(
                  onPressed: _isLoadingTranslator ? null : _saveProposals,
                  icon: const Icon(Icons.save),
                  label: const Text("Speichern"),
                  style: FilledButton.styleFrom(backgroundColor: Colors.green),
                ),
              ],
            ),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                if (safeProposals.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: ProposalSectionHeader(
                      title: "✅ Exakte Treffer (${safeProposals.length})",
                      color: Colors.green,
                      sectionProposals: safeProposals,
                      isExpanded: _isSafeExpanded,
                      onToggleExpand: () =>
                          setState(() => _isSafeExpanded = !_isSafeExpanded),
                      onSelectAllChanged: (state) {
                        setState(() {
                          for (final p in safeProposals) {
                            p.isSelected = state;
                          }
                        });
                      },
                    ),
                  ),
                  if (_isSafeExpanded)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => ProposalItemTile(
                          proposal: safeProposals[index],
                          onSelectionChanged: (val) => setState(
                              () => safeProposals[index].isSelected = val),
                        ),
                        childCount: safeProposals.length,
                      ),
                    ),
                ],
                if (reviewProposals.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: ProposalSectionHeader(
                      title: "⚠️ Zur Überprüfung (${reviewProposals.length})",
                      color: Colors.orange[800]!,
                      sectionProposals: reviewProposals,
                      isExpanded: _isReviewExpanded,
                      onToggleExpand: () => setState(
                          () => _isReviewExpanded = !_isReviewExpanded),
                      onSelectAllChanged: (state) {
                        setState(() {
                          for (final p in reviewProposals) {
                            p.isSelected = state;
                          }
                        });
                      },
                    ),
                  ),
                  if (_isReviewExpanded)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => ProposalItemTile(
                          proposal: reviewProposals[index],
                          onSelectionChanged: (val) => setState(
                              () => reviewProposals[index].isSelected = val),
                        ),
                        childCount: reviewProposals.length,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ] else if (!_isLoadingTranslator) ...[
          const Expanded(
            child: Center(
              child: Text(
                "Keine Vorschläge.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                onPressed: _isLoadingEditor ? null : _syncApiDatabaseFromPC,
                icon: const Icon(Icons.sync),
                label: const Text("API-Datenbank vom PC importieren (.sqlite)"),
                style: FilledButton.styleFrom(backgroundColor: Colors.blue),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _isLoadingEditor ? null : _loadMissingImages,
                icon: const Icon(Icons.broken_image),
                label: const Text("Fehlende EN-Bilder laden (Max 100)"),
                style:
                    FilledButton.styleFrom(backgroundColor: Colors.deepPurple),
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
                    icon: const Icon(Icons.search),
                  ),
                ],
              ),
              if (_isLoadingEditor)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: LinearProgressIndicator(),
                ),
            ],
          ),
        ),
        Expanded(
          child: _editorItems.isEmpty && !_isLoadingEditor
              ? const Center(
                  child: Text(
                    "Keine Karten gefunden.",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _editorItems.length,
                  itemBuilder: (context, index) {
                    final item = _editorItems[index];
                    return CardImageEditorTile(
                      item: item,
                      onOpenCardmarket: () => _openCardmarket(item),
                      onSave: () => _saveEditorItem(item),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
