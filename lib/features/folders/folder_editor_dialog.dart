import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:drift/drift.dart' show Value;
import 'package:atlas/app.dart';
import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/core/theme/app_theme.dart';

class FolderEditorDialog extends ConsumerStatefulWidget {
  final Folder? folder;
  const FolderEditorDialog({super.key, this.folder});

  static Future<void> show(BuildContext context, {Folder? folder}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => FolderEditorDialog(folder: folder),
    );
  }

  @override
  ConsumerState<FolderEditorDialog> createState() => _FolderEditorDialogState();
}

class _FolderEditorDialogState extends ConsumerState<FolderEditorDialog> {
  late final TextEditingController _nameController;
  late String _selectedColorHex;
  late String _selectedIconName;

  static const _presetColors = [
    '#3D5A80', '#EE6C4D', '#98C1D9', '#E0FBFC', '#293241',
    '#F4A261', '#2A9D8F', '#E76F51', '#264653', '#E9C46A',
  ];

  static const _iconMap = {
    'folder': Icons.folder,
    'work': Icons.work,
    'school': Icons.school,
    'favorite': Icons.favorite,
    'star': Icons.star,
    'code': Icons.code,
    'science': Icons.science,
    'music_note': Icons.music_note,
    'sports': Icons.sports_soccer,
    'flight': Icons.flight,
    'restaurant': Icons.restaurant,
    'fitness': Icons.fitness_center,
    'book': Icons.book,
    'shopping': Icons.shopping_bag,
    'health': Icons.local_hospital,
    'camera': Icons.photo_camera,
  };

  bool get _isEditing => widget.folder != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.folder?.name ?? '');
    _selectedColorHex = widget.folder?.colorHex ?? _presetColors[0];
    _selectedIconName = widget.folder?.icon ?? 'folder';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Color _parseColor(String hex) {
    try {
      final cleaned = hex.replaceFirst('#', '');
      return Color(int.parse(cleaned, radix: 16) + 0xFF000000);
    } catch (_) {
      return const Color(0xFF3D5A80);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isEditing ? 'Edit Folder' : 'New Folder', 
                 style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Folder name',
                prefixIcon: Icon(Icons.edit),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),

            // Color picker
            Text('Color', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._presetColors.map((hex) {
                  final isSelected = _selectedColorHex == hex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColorHex = hex),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _parseColor(hex),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: cs.primary, width: 2)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                  );
                }),
                GestureDetector(
                  onTap: _showColorPicker,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.outline),
                    ),
                    child: Icon(Icons.palette, size: 16, color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Icon picker
            Text('Icon', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _iconMap.entries.map((e) {
                final isSelected = _selectedIconName == e.key;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIconName = e.key),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected ? cs.secondaryContainer : null,
                      borderRadius: kShapeTokens.small,
                    ),
                    child: Icon(e.value,
                        color: isSelected
                            ? cs.onSecondaryContainer
                            : cs.onSurfaceVariant),
                  ),
                );
              }).toList(),
            ),

            // Delete option
            if (_isEditing) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                icon: Icon(Icons.delete, color: cs.error),
                label: Text('Delete Folder',
                    style: TextStyle(color: cs.error)),
                onPressed: _confirmDelete,
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _save,
                  child: Text(_isEditing ? 'Save' : 'Create'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker() {
    Color pickerColor = _parseColor(_selectedColorHex);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (c) => pickerColor = c,
          ),
        ),
        actions: [
          FilledButton(
            child: const Text('Done'),
            onPressed: () {
              setState(() {
                _selectedColorHex =
                    '#${pickerColor.toARGB32().toRadixString(16).substring(2)}';
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final db = ref.read(databaseProvider);
    if (_isEditing) {
      await db.updateFolder(FoldersCompanion(
        id: Value(widget.folder!.id),
        name: Value(name),
        colorHex: Value(_selectedColorHex),
        icon: Value(_selectedIconName),
      ));
    } else {
      await db.insertFolder(FoldersCompanion(
        name: Value(name),
        colorHex: Value(_selectedColorHex),
        icon: Value(_selectedIconName),
      ));
    }
    if (mounted) Navigator.pop(context);
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Folder?'),
        content: const Text(
            'Bookmarks in this folder will be moved to unfiled.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: Text('Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
            onPressed: () async {
              final db = ref.read(databaseProvider);
              await db.deleteFolder(widget.folder!.id);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
