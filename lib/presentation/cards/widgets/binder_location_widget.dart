import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/database_provider.dart';
import '../../../domain/models/api_card.dart';
import '../../binders/binder_detail_screen.dart';

/// Tag info containing binder metadata and slot positioning coordinates.
class BinderTagInfo {
  final Binder binder;
  final int page;
  final int row;
  final int col;

  const BinderTagInfo(this.binder, this.page, this.row, this.col);
}

/// Provider loading all binder placements and grid coordinates for a card.
final cardBinderDetailsProvider =
    FutureProvider.family<List<BinderTagInfo>, String>((ref, cardId) async {
  final db = ref.watch(databaseProvider);

  final query = db.select(db.binderCards).join([
    drift.innerJoin(
        db.binders, db.binders.id.equalsExp(db.binderCards.binderId))
  ]);

  query.where(db.binderCards.cardId.equals(cardId) &
      db.binderCards.isPlaceholder.equals(false));

  final rows = await query.get();

  final List<BinderTagInfo> results = [];
  for (final r in rows) {
    final binder = r.readTable(db.binders);
    final slot = r.readTable(db.binderCards);

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
    results.add(BinderTagInfo(binder, page, row, col));
  }

  return results;
});

/// Displays a clickable list of all physical binders containing [card].
class BinderLocationWidget extends ConsumerWidget {
  final ApiCard card;
  const BinderLocationWidget({required this.card, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bindersAsync = ref.watch(cardBinderDetailsProvider(card.id));

    return bindersAsync.when(
      data: (binders) {
        if (binders.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Einsortiert in:",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: binders.map((info) {
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BinderDetailScreen(
                            binder: info.binder,
                            initialSearchQuery: card.nameDe ?? card.name,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.book, size: 16, color: Colors.orange),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                info.binder.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[900],
                                ),
                              ),
                              Text(
                                "S. ${info.page} • Z. ${info.row} • Sp. ${info.col}",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: Colors.orange,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
