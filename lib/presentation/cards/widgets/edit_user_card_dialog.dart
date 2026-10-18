import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/database_provider.dart';
import '../../../domain/logic/binder_service.dart';
import '../../../domain/models/api_card.dart';

/// Modal dialog allowing the user to edit a specific owned card copy in their inventory.
///
/// Supports editing card print variant, condition, language, purchase date,
/// custom purchase valuation, and professional grading details (PSA, BGS, CGC, etc.).
class EditUserCardDialog extends ConsumerStatefulWidget {
  /// The master card metadata.
  final ApiCard card;

  /// The user card inventory row to edit.
  final UserCard item;

  /// Callback executed after changes are successfully written to the database.
  final VoidCallback onSaved;

  const EditUserCardDialog({
    super.key,
    required this.card,
    required this.item,
    required this.onSaved,
  });

  /// Displays the dialog modally.
  static Future<void> show(
    BuildContext context, {
    required ApiCard card,
    required UserCard item,
    required VoidCallback onSaved,
  }) {
    return showDialog(
      context: context,
      builder: (_) => EditUserCardDialog(
        card: card,
        item: item,
        onSaved: onSaved,
      ),
    );
  }

  @override
  ConsumerState<EditUserCardDialog> createState() => _EditUserCardDialogState();
}

class _EditUserCardDialogState extends ConsumerState<EditUserCardDialog> {
  late String _selectedVariant;
  late String _selectedLang;
  late String _selectedCond;
  late DateTime _selectedDate;
  late String _selectedCompany;

  late TextEditingController _scoreController;
  late TextEditingController _priceController;
  late List<String> _validVariants;

  final List<String> _languages = [
    'Englisch',
    'Deutsch',
    'Japanisch',
    'Französisch',
    'Italienisch',
    'Spanisch',
    'Koreanisch',
  ];

  final List<String> _conditions = [
    'Mint',
    'Near Mint',
    'Excellent',
    'Good',
    'Light Played',
    'Played',
    'Poor',
  ];

  final List<String> _companies = [
    'Kein Grading',
    'PSA',
    'Beckett (BGS)',
    'CGC',
    'AP',
    'PCA',
    'GSG',
    'EGS',
  ];

  @override
  void initState() {
    super.initState();
    _selectedVariant = widget.item.variant;
    _selectedLang = widget.item.language;
    _selectedCond = widget.item.condition;
    _selectedDate = widget.item.createdAt;
    _selectedCompany = widget.item.gradingCompany ?? 'Kein Grading';

    _scoreController =
        TextEditingController(text: widget.item.gradingScore ?? '');
    _priceController = TextEditingController(
      text: widget.item.customPrice?.toString() ?? '',
    );

    if (!_companies.contains(_selectedCompany)) {
      _companies.add(_selectedCompany);
    }
    if (!_conditions.contains(_selectedCond)) {
      _conditions.add(_selectedCond);
    }
    if (!_languages.contains(_selectedLang)) {
      _languages.add(_selectedLang);
    }

    _validVariants = [];
    if (widget.card.hasNormal) _validVariants.add('Normal');
    if (widget.card.hasHolo) _validVariants.add('Holo');
    if (widget.card.hasReverse) _validVariants.add('Reverse Holo');
    if (widget.card.hasFirstEdition) _validVariants.add('1st Edition');
    if (_validVariants.isEmpty) _validVariants.add('Normal');
    if (!_validVariants.contains(_selectedVariant)) {
      _validVariants.add(_selectedVariant);
    }
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final db = ref.read(databaseProvider);
    final double? newPrice =
        double.tryParse(_priceController.text.replaceAll(',', '.'));

    final String? comp =
        _selectedCompany == 'Kein Grading' ? null : _selectedCompany;
    final String? score = comp != null ? _scoreController.text.trim() : null;

    await (db.update(db.userCards)..where((t) => t.id.equals(widget.item.id)))
        .write(
      UserCardsCompanion(
        variant: drift.Value(_selectedVariant),
        language: drift.Value(_selectedLang),
        condition: drift.Value(_selectedCond),
        customPrice: drift.Value(newPrice),
        gradingCompany: drift.Value(comp),
        gradingScore: drift.Value(score),
        createdAt: drift.Value(_selectedDate),
      ),
    );

    await BinderService(db).recalculateBindersForCard(widget.card.id);

    if (mounted) {
      widget.onSaved();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        "Inventar-Eintrag bearbeiten",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Kartendetails",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),

            // Variant Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedVariant,
              decoration: InputDecoration(
                labelText: "Variante",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
              items: _validVariants
                  .map(
                    (v) => DropdownMenuItem(
                      value: v,
                      child: Text(v, style: const TextStyle(fontSize: 13)),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedVariant = val);
                }
              },
            ),
            const SizedBox(height: 10),

            // Language & Condition Row
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedLang,
                    decoration: InputDecoration(
                      labelText: "Sprache",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                    ),
                    items: _languages
                        .map(
                          (l) => DropdownMenuItem(
                            value: l,
                            child: Text(l, style: const TextStyle(fontSize: 12)),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedLang = val);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCond,
                    decoration: InputDecoration(
                      labelText: "Zustand",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                    ),
                    items: _conditions
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(c, style: const TextStyle(fontSize: 12)),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedCond = val);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Date Picker Row
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(1996),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  final newDateTime = DateTime(
                    picked.year,
                    picked.month,
                    picked.day,
                    _selectedDate.hour,
                    _selectedDate.minute,
                    _selectedDate.second,
                  );
                  setState(() => _selectedDate = newDateTime);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Erworben am",
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('dd.MM.yyyy').format(_selectedDate),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.calendar_today, size: 20, color: Colors.blue),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // Grading Section
            const Text(
              "Grading (Optional)",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedCompany,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
              items: _companies
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(c, style: const TextStyle(fontSize: 13)),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedCompany = val);
                }
              },
            ),
            const SizedBox(height: 10),
            if (_selectedCompany != 'Kein Grading') ...[
              TextField(
                controller: _scoreController,
                decoration: InputDecoration(
                  labelText: "Bewertung (z.B. 10, 9.5, GEM MT)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_selectedCompany == 'Kein Grading') const SizedBox(height: 6),

            const Divider(),
            const SizedBox(height: 8),

            // Individual Value
            const Text(
              "Individueller Wert (Optional)",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Überschreibt alle globalen Berechnungen für diese spezifische Karte.",
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: "Spezifischer Wert (€)",
                hintText: "z.B. 15.50",
                prefixIcon: const Icon(Icons.euro, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Abbrechen"),
        ),
        FilledButton(
          onPressed: _saveChanges,
          child: const Text("Speichern"),
        ),
      ],
    );
  }
}
