import 'package:flutter/material.dart';
import '../models/admin_editor_models.dart';

/// Section header widget for translation proposals with tristate bulk-selection checkbox.
class ProposalSectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  final List<TranslationProposal> sectionProposals;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final ValueChanged<bool> onSelectAllChanged;

  const ProposalSectionHeader({
    super.key,
    required this.title,
    required this.color,
    required this.sectionProposals,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onSelectAllChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool allSelected = sectionProposals.every((p) => p.isSelected);
    final bool noneSelected = sectionProposals.every((p) => !p.isSelected);
    final bool? checkboxState =
        allSelected ? true : (noneSelected ? false : null);

    return Material(
      color: color.withValues(alpha: 0.1),
      child: InkWell(
        onTap: onToggleExpand,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Checkbox(
                tristate: true,
                value: checkboxState,
                activeColor: color,
                onChanged: (val) {
                  final bool targetState =
                      (checkboxState == null) ? true : (val ?? false);
                  onSelectAllChanged(targetState);
                },
              ),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: color,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
