import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:atlas/app.dart';
import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/core/widgets/custom_chip.dart';

class FolderChipRow extends ConsumerWidget {
  final void Function(int folderId, String folderName)? onFolderSelected;
  const FolderChipRow({super.key, this.onFolderSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    return StreamBuilder<List<Folder>>(
      stream: db.watchAllFolders(),
      builder: (context, snapshot) {
        final folders = snapshot.data ?? [];
        if (folders.isEmpty) return const SizedBox.shrink();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: folders.map((folder) {
            final color = _parseColor(folder.colorHex);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CustomChip(
                label: folder.name,
                isSelected: false,
                onTap: () => onFolderSelected?.call(folder.id, folder.name),
                avatar: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Color _parseColor(String hex) {
    try {
      final cleaned = hex.replaceFirst('#', '');
      return Color(int.parse(cleaned, radix: 16) + 0xFF000000);
    } catch (_) {
      return const Color(0xFF3D5A80);
    }
  }
}
