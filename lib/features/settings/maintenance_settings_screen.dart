import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atlas/app.dart';
import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/services/dead_link_checker.dart';

class MaintenanceSettingsScreen extends ConsumerWidget {
  const MaintenanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Maintenance')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Check all links now'),
            subtitle: const Text('Scan for dead links'),
            onTap: () => _runDeadLinkCheck(context, db),
          ),
          ListTile(
            leading: const Icon(Icons.auto_delete_outlined),
            title: const Text('Trash auto-clear'),
            subtitle: const Text('Set retention period'),
            onTap: () => _showTrashRetentionDialog(context),
          ),
        ],
      ),
    );
  }

  void _runDeadLinkCheck(BuildContext context, AppDatabase db) {
    int checked = 0;
    int total = 0;
    int deadFound = 0;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          if (checked == 0 && total == 0) {
            // Start the check
            Future(() async {
              final checker = DeadLinkChecker(db);
              deadFound = await checker.checkAll(onProgress: (c, t) {
                setState(() {
                  checked = c;
                  total = t;
                });
              });
              checker.dispose();
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Found $deadFound dead links')),
                );
              }
            });
          }
          return AlertDialog(
            title: const Text('Checking links...'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(total > 0 ? '$checked / $total' : 'Starting...'),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showTrashRetentionDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt('trash_auto_clear_days') ?? -1;
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) {
        int selected = current;
        return StatefulBuilder(
          builder: (ctx, setState) => SimpleDialog(
            title: const Text('Trash auto-clear'),
            children: [
              RadioGroup<int>(
                groupValue: selected,
                onChanged: (v) async {
                  if (v == null) return;
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setInt('trash_auto_clear_days', v);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [7, 14, 30, -1].map((days) {
                    return ListTile(
                      title: Text(days > 0 ? '$days days' : 'Never'),
                      leading: Radio<int>(value: days),
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setInt('trash_auto_clear_days', days);
                        if (ctx.mounted) Navigator.pop(ctx);
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
