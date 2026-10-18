import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/admin_editor_models.dart';

/// Card item editor tile enabling live preview, image URL entry, artist input, and Cardmarket deep-linking.
class CardImageEditorTile extends StatelessWidget {
  final CardEditorItem item;
  final VoidCallback onOpenCardmarket;
  final VoidCallback onSave;

  const CardImageEditorTile({
    super.key,
    required this.item,
    required this.onOpenCardmarket,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Card name, set info, and external Cardmarket action
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.card.nameDe ?? item.card.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          "EN: ${item.card.name}  |  Set: ${item.card.setId.toUpperCase()}  |  Nr: ${item.card.number}",
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onOpenCardmarket,
                    icon: const Icon(Icons.open_in_browser, size: 16),
                    label: const Text("Cardmarket", style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      side: BorderSide(color: Colors.blue[700]!),
                      foregroundColor: Colors.blue[700],
                    ),
                  ),
                ],
              ),
              const Divider(),

              // Image preview and input controls
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live image preview
                  Container(
                    width: 70,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ValueListenableBuilder(
                      valueListenable: item.imgEnCtrl,
                      builder: (context, value, _) {
                        if (value.text.isEmpty) {
                          return const Icon(Icons.add_a_photo, color: Colors.grey);
                        }
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: CachedNetworkImage(
                            imageUrl: value.text,
                            memCacheHeight: 200,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                const Icon(Icons.broken_image, color: Colors.red),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Metadata input fields
                  Expanded(
                    child: Column(
                      children: [
                        TextField(
                          controller: item.imgEnCtrl,
                          decoration: const InputDecoration(
                            labelText: "Bild URL (Englisch / Fallback)",
                            isDense: true,
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: item.artistCtrl,
                                decoration: const InputDecoration(
                                  labelText: "Künstler (Artist)",
                                  isDense: true,
                                ),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: onSave,
                              icon: const Icon(Icons.save, size: 16),
                              label: const Text("Speichern"),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            ),
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
      ),
    );
  }
}
