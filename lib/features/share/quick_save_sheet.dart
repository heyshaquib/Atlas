import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import 'package:atlas/app.dart';
import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/core/utils/utils.dart';
import 'package:atlas/core/theme/app_theme.dart';
import 'package:atlas/services/metadata_fetcher.dart';
import 'package:atlas/core/widgets/custom_chip.dart';

class QuickSaveSheet extends ConsumerStatefulWidget {
  final String? prefilledUrl;
  const QuickSaveSheet({super.key, this.prefilledUrl});

  static Future<void> show(BuildContext context, {String? prefilledUrl}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: QuickSaveSheet(prefilledUrl: prefilledUrl),
      ),
    );
  }

  @override
  ConsumerState<QuickSaveSheet> createState() => _QuickSaveSheetState();
}

class _QuickSaveSheetState extends ConsumerState<QuickSaveSheet> {
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  Timer? _debounce;
  int? _selectedFolderId;
  bool _isFavorite = false;
  bool _isLoading = false;
  final _fetcher = MetadataFetcher();

  @override
  void initState() {
    super.initState();
    if (widget.prefilledUrl != null) {
      _urlController.text = widget.prefilledUrl!;
      _fetchMetadata(widget.prefilledUrl!);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _urlController.dispose();
    _titleController.dispose();
    _fetcher.dispose();
    super.dispose();
  }

  void _onUrlChanged(String url) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      final normalized = normalizeUrl(url);
      if (isValidUrl(normalized)) _fetchMetadata(normalized);
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
      });
    }
  }

  Future<void> _save() async {
    final url = normalizeUrl(_urlController.text.trim());
    if (!isValidUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid URL')),
      );
      return;
    }
    final title = _titleController.text.trim().isEmpty
        ? url
        : _titleController.text.trim();
    final domain = extractDomain(url);
    final db = ref.read(databaseProvider);

    await db.insertBookmark(BookmarksCompanion(
      title: Value(title),
      url: Value(url),
      domain: Value(domain),
      faviconUrl: Value(getFaviconUrl(domain)),
      folderId: Value(_selectedFolderId),
      isFavorite: Value(_isFavorite),
      createdAt: Value(DateTime.now()),
    ));

    HapticFeedback.mediumImpact();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Save',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'URL',
              prefixIcon: Icon(Icons.link),
            ),
            keyboardType: TextInputType.url,
            onChanged: _onUrlChanged,
          ),
          if (_isLoading) const LinearProgressIndicator(),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              prefixIcon: Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 12),
          Text('Folder', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
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
                      label: 'None',
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
          const SizedBox(height: 12),
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
              FilledButton(
                onPressed: _save,
                child: const Text('Save'),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
