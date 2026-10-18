import 'package:flutter/material.dart';
import '../models/admin_editor_models.dart';

/// List tile representing a single proposed card translation with selection toggle and editable text field.
class ProposalItemTile extends StatelessWidget {
  final TranslationProposal proposal;
  final ValueChanged<bool> onSelectionChanged;

  const ProposalItemTile({
    super.key,
    required this.proposal,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Checkbox(
              value: proposal.isSelected,
              activeColor: Colors.deepPurple,
              onChanged: (val) => onSelectionChanged(val ?? false),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Original: ${proposal.card.name} (${proposal.card.setId.toUpperCase()})",
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  TextField(
                    controller: proposal.controller,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
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
