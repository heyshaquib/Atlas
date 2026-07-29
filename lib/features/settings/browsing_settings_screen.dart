import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:atlas/core/models/models.dart';
import 'package:atlas/app.dart';

class BrowsingSettingsScreen extends ConsumerWidget {
  const BrowsingSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final browserChoice = ref.watch(browserChoiceProvider);
    final markAsRead = ref.watch(markAsReadOnOpenProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Browsing')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.open_in_browser),
            title: const Text('Open links in'),
            subtitle: Text(browserChoice == BrowserChoice.inApp
                ? 'In-app browser'
                : 'External browser'),
            onTap: () => _showBrowserDialog(context, ref, browserChoice),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.done_all),
            title: const Text('Mark as read on open'),
            value: markAsRead,
            onChanged: (_) =>
                ref.read(markAsReadOnOpenProvider.notifier).toggle(),
          ),
        ],
      ),
    );
  }

  void _showBrowserDialog(
      BuildContext context, WidgetRef ref, BrowserChoice current) {
    showDialog(
      context: context,
      builder: (ctx) {
        BrowserChoice selected = current;
        return StatefulBuilder(
          builder: (ctx, setState) => SimpleDialog(
            title: const Text('Open links in'),
            children: [
              RadioGroup<BrowserChoice>(
                groupValue: selected,
                onChanged: (v) {
                  if (v == null) return;
                  ref.read(browserChoiceProvider.notifier).setChoice(v);
                  Navigator.pop(ctx);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: BrowserChoice.values.map((choice) {
                    return ListTile(
                      title: Text(choice == BrowserChoice.inApp
                          ? 'In-app browser'
                          : 'External browser'),
                      leading: Radio<BrowserChoice>(value: choice),
                      onTap: () {
                        ref.read(browserChoiceProvider.notifier).setChoice(choice);
                        Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
