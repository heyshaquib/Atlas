import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:drift/drift.dart' show Value, InsertMode;
import 'package:atlas/app.dart';
import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/core/utils/utils.dart';

class BackupSettingsScreen extends ConsumerWidget {
  const BackupSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Export as HTML'),
            onTap: () => _exportHtml(context, db),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Export as JSON'),
            onTap: () => _exportJson(context, db),
          ),
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('Import from HTML'),
            onTap: () => _importHtml(context, db),
          ),
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('Import from JSON'),
            onTap: () => _importJson(context, db),
          ),
          ListTile(
            leading: Icon(Icons.delete_forever, color: cs.error),
            title: Text('Clear all data', style: TextStyle(color: cs.error)),
            onTap: () => _confirmClearAll(context, db),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _exportHtml(BuildContext context, AppDatabase db) async {
    final data = await db.exportAllData();
    final html = generateNetscapeHtml(
      bookmarks: List<Map<String, dynamic>>.from(data['bookmarks'] ?? []),
      folders: List<Map<String, dynamic>>.from(data['folders'] ?? []),
    );
    
    final outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Bookmarks Export',
      fileName: 'atlas_bookmarks.html',
      type: FileType.custom,
      allowedExtensions: ['html', 'htm'],
      bytes: Uint8List.fromList(utf8.encode(html)),
    );

    if (outputFile != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bookmarks exported successfully')),
        );
      }
    }
  }

  Future<void> _exportJson(BuildContext context, AppDatabase db) async {
    final data = await db.exportAllData();
    final json = jsonEncode(data);
    
    final outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Bookmarks Export',
      fileName: 'atlas_bookmarks.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: Uint8List.fromList(utf8.encode(json)),
    );

    if (outputFile != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bookmarks exported successfully')),
        );
      }
    }
  }

  Future<void> _importHtml(BuildContext context, AppDatabase db) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['html', 'htm'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = File(result.files.single.path!);
    final contents = await file.readAsString();
    final imported = parseNetscapeHtml(contents);

    int count = 0;
    for (final bookmark in imported) {
      int? folderId;
      if (bookmark.folderName != null) {
        final folders = await db.getAllFolders();
        final existing = folders.where((f) => f.name == bookmark.folderName).toList();
        if (existing.isNotEmpty) {
          folderId = existing.first.id;
        } else {
          folderId = await db.insertFolder(FoldersCompanion(
            name: Value(bookmark.folderName!),
            colorHex: const Value('#3D5A80'),
            icon: const Value('folder'),
          ));
        }
      }

      await db.insertBookmark(BookmarksCompanion(
        title: Value(bookmark.title),
        url: Value(bookmark.url),
        domain: Value(extractDomain(bookmark.url)),
        faviconUrl: Value(getFaviconUrl(extractDomain(bookmark.url))),
        folderId: Value(folderId),
        createdAt: Value(bookmark.addDate ?? DateTime.now()),
      ));
      count++;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported $count bookmarks')),
      );
    }
  }

  Future<void> _importJson(BuildContext context, AppDatabase db) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = File(result.files.single.path!);
    final contents = await file.readAsString();
    
    Map<String, dynamic> data;
    try {
      data = jsonDecode(contents);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid JSON file')),
        );
      }
      return;
    }

    int count = 0;
    
    await db.transaction(() async {
      // Import folders
      for (final folderData in List<Map<String, dynamic>>.from(data['folders'] ?? [])) {
        await db.into(db.folders).insert(
          FoldersCompanion(
            id: Value(folderData['id']),
            name: Value(folderData['name']),
            colorHex: Value(folderData['colorHex']),
            icon: Value(folderData['icon']),
            displayOrder: Value(folderData['displayOrder']),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }

      // Import tags
      for (final tagData in List<Map<String, dynamic>>.from(data['tags'] ?? [])) {
        await db.into(db.tags).insert(
          TagsCompanion(
            id: Value(tagData['id']),
            name: Value(tagData['name']),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }

      // Import bookmarks
      final bookmarksList = List<Map<String, dynamic>>.from(data['bookmarks'] ?? []);
      for (final bmData in bookmarksList) {
        await db.into(db.bookmarks).insert(
          BookmarksCompanion(
            id: Value(bmData['id']),
            title: Value(bmData['title']),
            url: Value(bmData['url']),
            domain: Value(bmData['domain']),
            pageDescription: Value(bmData['pageDescription']),
            notes: Value(bmData['notes']),
            notesPlainText: Value(bmData['notesPlainText']),
            faviconUrl: Value(bmData['faviconUrl']),
            previewImageUrl: Value(bmData['previewImageUrl']),
            folderId: Value(bmData['folderId']),
            isFavorite: Value(bmData['isFavorite']),
            isArchived: Value(bmData['isArchived']),
            isDeleted: Value(bmData['isDeleted']),
            isUnread: Value(bmData['isUnread']),
            isDead: Value(bmData['isDead']),
            deadCheckFailCount: Value(bmData['deadCheckFailCount']),
            estimatedReadingTimeMinutes: Value(bmData['estimatedReadingTimeMinutes']),
            estimatedWordCount: Value(bmData['estimatedWordCount']),
            createdAt: Value(DateTime.parse(bmData['createdAt'])),
            lastOpenedAt: bmData['lastOpenedAt'] != null ? Value(DateTime.parse(bmData['lastOpenedAt'])) : const Value.absent(),
            deletedAt: bmData['deletedAt'] != null ? Value(DateTime.parse(bmData['deletedAt'])) : const Value.absent(),
            visitCount: Value(bmData['visitCount']),
            customOrder: Value(bmData['customOrder']),
          ),
          mode: InsertMode.insertOrReplace,
        );
        count++;
      }

      // Import bookmark tag joins
      for (final joinData in List<Map<String, dynamic>>.from(data['bookmarkTagJoins'] ?? [])) {
        await db.into(db.bookmarkTagJoin).insert(
          BookmarkTagJoinCompanion(
            bookmarkId: Value(joinData['bookmarkId']),
            tagId: Value(joinData['tagId']),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
      
      // Import relations (if present)
      for (final rData in List<Map<String, dynamic>>.from(data['bookmarkRelations'] ?? [])) {
        await db.into(db.bookmarkRelations).insert(
          BookmarkRelationsCompanion(
            id: Value(rData['id']),
            sourceId: Value(rData['sourceId']),
            targetId: Value(rData['targetId']),
            relationType: Value(rData['relationType']),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imported $count bookmarks via JSON')),
      );
    }
  }

  void _confirmClearAll(BuildContext context, AppDatabase db) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
            'This will permanently delete all bookmarks, folders, and tags. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await db.clearAllData();
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All data cleared')));
              }
            },
            child: Text('Clear', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}
