import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:atlas/app.dart';
import 'package:atlas/services/backlink_detector.dart';
import 'package:atlas/features/note_editor/formatting_toolbar.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final int bookmarkId;
  final String bookmarkTitle;
  final String? initialNotesJson;

  const NoteEditorScreen({
    super.key,
    required this.bookmarkId,
    required this.bookmarkTitle,
    this.initialNotesJson,
  });

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late QuillController _controller;
  Timer? _debounce;
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initController();
    _controller.addListener(_onTextChanged);
  }

  void _initController() {
    if (widget.initialNotesJson != null &&
        widget.initialNotesJson!.isNotEmpty) {
      try {
        final json = jsonDecode(widget.initialNotesJson!);
        final doc = Document.fromJson(json);
        _controller = QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
        return;
      } catch (_) {}
    }
    _controller = QuillController.basic();
  }

  void _onTextChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), _saveNotes);
  }

  Future<void> _saveNotes() async {
    final db = ref.read(databaseProvider);
    final deltaJson =
        jsonEncode(_controller.document.toDelta().toJson());
    final plainText = _controller.document.toPlainText().trim();

    await db.updateNotes(
      widget.bookmarkId,
      deltaJson,
      plainText.isEmpty ? null : plainText,
    );

    // Detect backlinks
    final detector = BacklinkDetector(db);
    await detector.detectAndUpdateBacklinks(
      widget.bookmarkId,
      plainText.isEmpty ? null : plainText,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _debounce?.cancel();
          _saveNotes();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Notes for ${widget.bookmarkTitle}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: QuillEditor(
                controller: _controller,
                focusNode: _focusNode,
                scrollController: _scrollController,
                config: const QuillEditorConfig(
                  placeholder:
                      'Why did you save this? Add research findings, action items, or personal thoughts...',
                  padding: EdgeInsets.all(16),
                  expands: true,
                ),
              ),
            ),
            FormattingToolbar(controller: _controller),
          ],
        ),
      ),
    );
  }
}
