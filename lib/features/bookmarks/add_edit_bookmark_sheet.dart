import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:atlas/app.dart';
import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/core/utils/utils.dart';
import 'package:atlas/core/theme/app_theme.dart';
import 'package:atlas/services/metadata_fetcher.dart';
import 'package:atlas/features/bookmarks/widgets/reading_time_badge.dart';
import 'package:atlas/core/widgets/custom_chip.dart';
class AddEditBookmarkSheet extends ConsumerStatefulWidget {
  final Bookmark? bookmark;
  const AddEditBookmarkSheet({super.key, this.bookmark});

  static Future<void> show(BuildContext context, {Bookmark? bookmark}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddEditBookmarkSheet(bookmark: bookmark),
    );
  }

  @override
  ConsumerState<AddEditBookmarkSheet> createState() => _AddEditBookmarkSheetState();
}

class _AddEditBookmarkSheetState extends ConsumerState<AddEditBookmarkSheet> {
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  Timer? _debounce;
  bool _isLoading = false;
  bool _isFavorite = false;

  int? _selectedFolderId;
  String? _previewImageUrl;
  String? _description;
  int? _readingTimeMinutes;
  int? _wordCount;
  Bookmark? _duplicate;
  final _fetcher = MetadataFetcher();

  bool get _isEditing => widget.bookmark != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final b = widget.bookmark!;
      _urlController.text = b.url;
      _titleController.text = b.title;
      _isFavorite = b.isFavorite;

      _selectedFolderId = b.folderId;
      _previewImageUrl = b.previewImageUrl;
      _description = b.pageDescription;
      _readingTimeMinutes = b.estimatedReadingTimeMinutes;
      _wordCount = b.estimatedWordCount;
      if (b.notesPlainText != null) {
        _notesController.text = b.notesPlainText!;
      }
    } else {
      _checkClipboard();
    }
  }

  Future<void> _checkClipboard() async {
    try {
      final data = await Clipboard.getData('text/plain');
      if (data?.text != null && isValidUrl(data!.text!)) {
        _urlController.text = data.text!;
        _fetchMetadata(data.text!);
      }
    } catch (_) {}
  }

  void _onUrlChanged(String url) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      if (url.isNotEmpty && isValidUrl(normalizeUrl(url))) {
        _fetchMetadata(normalizeUrl(url));
        _checkDuplicate(normalizeUrl(url));
      }
    });
  }

  Future<void> _fetchMetadata(String url) async {
    setState(() => _isLoading = true);
    final meta = await _fetcher.fetch(url);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (meta.title != null && _titleController.text.isEmpty) {
          _titleController.text = meta.title!;
        }
        _previewImageUrl = meta.previewImageUrl;
        _description = meta.description;
        _readingTimeMinutes = meta.estimatedReadingTimeMinutes;
        _wordCount = meta.estimatedWordCount;
      });
    }
  }

  Future<void> _checkDuplicate(String url) async {
    final db = ref.read(databaseProvider);
    final existing = await db.findByUrl(url);
    if (mounted && existing != null && existing.id != (widget.bookmark?.id ?? -1)) {
      setState(() => _duplicate = existing);
    } else {
      setState(() => _duplicate = null);
    }
  }

  Future<void> _save() async {
    final url = normalizeUrl(_urlController.text.trim());
    final title = _titleController.text.trim();
    if (!isValidUrl(url) || title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid URL and title')),
      );
      return;
    }

    final db = ref.read(databaseProvider);
    final domain = extractDomain(url);
    
    final noteText = _notesController.text.trim();
    String? deltaJson;
    if (noteText.isNotEmpty) {
      deltaJson = jsonEncode([{"insert": "$noteText\n"}]);
    }

    if (_isEditing) {
      await db.updateBookmark(BookmarksCompanion(
        id: Value(widget.bookmark!.id),
        title: Value(title),
        url: Value(url),
        domain: Value(domain),
        pageDescription: Value(_description),
        faviconUrl: Value(getFaviconUrl(domain)),
        previewImageUrl: Value(_previewImageUrl),
        folderId: Value(_selectedFolderId),
        isFavorite: Value(_isFavorite),
        notes: Value(deltaJson),
        notesPlainText: Value(noteText.isEmpty ? null : noteText),
        estimatedReadingTimeMinutes: Value(_readingTimeMinutes),
        estimatedWordCount: Value(_wordCount),
      ));
    } else {
      await db.insertBookmark(BookmarksCompanion(
        title: Value(title),
        url: Value(url),
        domain: Value(domain),
        pageDescription: Value(_description),
        faviconUrl: Value(getFaviconUrl(domain)),
        previewImageUrl: Value(_previewImageUrl),
        folderId: Value(_selectedFolderId),
        isFavorite: Value(_isFavorite),
        notes: Value(deltaJson),
        notesPlainText: Value(noteText.isEmpty ? null : noteText),
        estimatedReadingTimeMinutes: Value(_readingTimeMinutes),
        estimatedWordCount: Value(_wordCount),
        createdAt: Value(DateTime.now()),
      ));
    }

    HapticFeedback.mediumImpact();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _urlController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    _fetcher.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final db = ref.watch(databaseProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isEditing ? 'Edit Bookmark' : 'Add Bookmark',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),

            // URL field
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
              onChanged: _onUrlChanged,
            ),
            if (_isLoading) const LinearProgressIndicator(),
            const SizedBox(height: 12),

            // Title field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 12),

            // Preview image
            if (_previewImageUrl != null) ...[
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: kShapeTokens.small,
                    child: Image.network(
                      _previewImageUrl!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton.filledTonal(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () =>
                          setState(() => _previewImageUrl = null),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Description
            if (_description != null)
              Text(
                _description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),

            // Reading time
            if (_readingTimeMinutes != null) ...[
              const SizedBox(height: 8),
              ReadingTimeBadge(minutes: _readingTimeMinutes),
            ],

            // Duplicate warning
            if (_duplicate != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: kShapeTokens.small,
                ),
                child: Text(
                  'Already bookmarked${_duplicate!.folderId != null ? '' : ''}',
                  style: TextStyle(color: cs.onErrorContainer),
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Folder selector
            Text('Folder', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: StreamBuilder<List<Folder>>(
                stream: db.watchAllFolders(),
                builder: (ctx, snap) {
                  final folders = snap.data ?? [];
                  return ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      CustomChip(
                        label: 'Default',
                        isSelected: _selectedFolderId == null,
                        onTap: () => setState(() => _selectedFolderId = null),
                      ),
                      const SizedBox(width: 8),
                      ...folders.map((f) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CustomChip(
                              label: f.name,
                              isSelected: _selectedFolderId == f.id,
                              onTap: () => setState(() => _selectedFolderId = f.id),
                            ),
                          )),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            Text('Notes', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Add a note...',
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: kShapeTokens.small,
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Toggles + Save
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.star : Icons.star_border,
                    color: _isFavorite ? kFavoriteColor : null,
                  ),
                  onPressed: () =>
                      setState(() => _isFavorite = !_isFavorite),
                ),

                const Spacer(),
                FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: Text(_isEditing ? 'Update' : 'Save'),
                  onPressed: _save,
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

}
