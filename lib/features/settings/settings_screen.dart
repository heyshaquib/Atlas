import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:atlas/features/settings/about_screen.dart';
import 'package:atlas/features/settings/backup_settings_screen.dart';
import 'package:atlas/features/settings/appearance_settings_screen.dart';
import 'package:atlas/features/settings/browsing_settings_screen.dart';
import 'package:atlas/features/settings/maintenance_settings_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Appearance'),
            subtitle: const Text('Theme, Colors, And Styling'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppearanceSettingsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.open_in_browser),
            title: const Text('Browsing'),
            subtitle: const Text('Browser Defaults And Behavior'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BrowsingSettingsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.build),
            title: const Text('Maintenance'),
            subtitle: const Text('Check Links And Clean Trash'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MaintenanceSettingsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings_applications),
            title: const Text('Backup & Restore'),
            subtitle: const Text('Data Backup And Restore'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BackupSettingsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            subtitle: const Text('About And Licenses'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}


class SectionHeader extends StatelessWidget {
  final String text;
  const SectionHeader(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
