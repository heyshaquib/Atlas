import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class FormattingToolbar extends StatefulWidget {
  final QuillController controller;
  const FormattingToolbar({super.key, required this.controller});

  @override
  State<FormattingToolbar> createState() => _FormattingToolbarState();
}

class _FormattingToolbarState extends State<FormattingToolbar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onSelectionChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onSelectionChanged);
    super.dispose();
  }

  void _onSelectionChanged() {
    if (mounted) setState(() {});
  }

  bool _isActive(Attribute attr) {
    return widget.controller
        .getSelectionStyle()
        .attributes
        .containsKey(attr.key);
  }

  void _toggle(Attribute attr) {
    if (_isActive(attr)) {
      widget.controller
          .formatSelection(Attribute.clone(attr, null));
    } else {
      widget.controller.formatSelection(attr);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _btn(Icons.format_bold, Attribute.bold),
                _btn(Icons.format_italic, Attribute.italic),
                _btn(Icons.format_underline, Attribute.underline),
                _btn(Icons.strikethrough_s, Attribute.strikeThrough),
                _divider(),
                _btn(Icons.format_list_bulleted, Attribute.ul),
                _btn(Icons.format_list_numbered, Attribute.ol),
                _btn(Icons.checklist, Attribute.unchecked),
                _divider(),
                _btn(Icons.format_quote, Attribute.blockQuote),
                _btn(Icons.code, Attribute.codeBlock),
                _divider(),
                IconButton(
                  icon: const Icon(Icons.format_clear),
                  iconSize: 20,
                  tooltip: 'Clear formatting',
                  onPressed: () {
                    final attrs = widget.controller
                        .getSelectionStyle()
                        .attributes;
                    for (final attr in attrs.values) {
                      widget.controller.formatSelection(
                          Attribute.clone(attr, null));
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _btn(IconData icon, Attribute attr) {
    final active = _isActive(attr);
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: IconButton(
        icon: Icon(icon),
        iconSize: 20,
        style: active
            ? IconButton.styleFrom(
                backgroundColor: cs.secondaryContainer,
                foregroundColor: cs.onSecondaryContainer,
              )
            : null,
        onPressed: () => _toggle(attr),
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        height: 24,
        child: VerticalDivider(
          width: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
    );
  }
}
