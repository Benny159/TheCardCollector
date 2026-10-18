import 'package:flutter/material.dart';
import '../../../data/database/app_database.dart' as db;

/// Form widget for creating or updating a custom card record manually.
class ManualCardCreateForm extends StatelessWidget {
  final List<db.CardSet> availableSets;
  final String? selectedSetId;
  final ValueChanged<String?> onSetSelected;
  final TextEditingController numberController;
  final TextEditingController nameEnController;
  final TextEditingController nameDeController;
  final TextEditingController imgController;
  final TextEditingController artistController;
  final VoidCallback onSave;

  const ManualCardCreateForm({
    super.key,
    required this.availableSets,
    required this.selectedSetId,
    required this.onSetSelected,
    required this.numberController,
    required this.nameEnController,
    required this.nameDeController,
    required this.imgController,
    required this.artistController,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Neue Karte manuell anlegen",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Ideal für Promo-Karten. Verwende die exakte Karten-Nummer (z.B. '030' oder '151'), damit sie später nahtlos mit API-Updates verschmilzt!",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),

          // Set dropdown
          DropdownButtonFormField<String>(
            initialValue: selectedSetId,
            decoration: const InputDecoration(
              labelText: 'Set auswählen (Pflicht)',
              border: OutlineInputBorder(),
            ),
            isExpanded: true,
            items: availableSets.map((set) {
              return DropdownMenuItem<String>(
                value: set.id,
                child: Text(
                  "${set.name} (${set.id})",
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: onSetSelected,
          ),
          const SizedBox(height: 16),

          // Card number
          TextField(
            controller: numberController,
            decoration: const InputDecoration(
              labelText: 'Karten-Nummer (z.B. 030 oder 151)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.tag),
            ),
          ),
          const SizedBox(height: 16),

          // English name
          TextField(
            controller: nameEnController,
            decoration: const InputDecoration(
              labelText: 'Name (Englisch) (Pflicht)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // German name
          TextField(
            controller: nameDeController,
            decoration: const InputDecoration(
              labelText: 'Name (Deutsch) (Optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Image URL
          TextField(
            controller: imgController,
            decoration: const InputDecoration(
              labelText: 'Bild URL (.png/.jpg) (Optional aber empfohlen)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.image),
            ),
          ),
          const SizedBox(height: 16),

          // Artist
          TextField(
            controller: artistController,
            decoration: const InputDecoration(
              labelText: 'Künstler (Optional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.brush),
            ),
          ),
          const SizedBox(height: 24),

          // Submit action
          FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.green,
            ),
            onPressed: onSave,
            icon: const Icon(Icons.save),
            label: const Text(
              "Karte in Datenbank speichern",
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
