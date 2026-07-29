import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:atlas/core/models/models.dart';
import 'package:atlas/app.dart';

class AppearanceSettingsScreen extends ConsumerWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final dynamicColor = ref.watch(dynamicColorEnabledProvider);
    final showReadingTime = ref.watch(showReadingTimeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Theme'),
            subtitle: Text(_themeLabel(themeMode)),
            onTap: () => _showThemeDialog(context, ref, themeMode),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.color_lens),
            title: const Text('Dynamic color'),
            subtitle: const Text('Use wallpaper colors'),
            value: dynamicColor,
            onChanged: (_) =>
                ref.read(dynamicColorEnabledProvider.notifier).toggle(),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.timer_outlined),
            title: const Text('Show reading time'),
            value: showReadingTime,
            onChanged: (_) =>
                ref.read(showReadingTimeProvider.notifier).toggle(),
          ),
        ],
      ),
    );
  }

  String _themeLabel(AtlasThemeMode mode) {
    switch (mode) {
      case AtlasThemeMode.system: return 'System';
      case AtlasThemeMode.light: return 'Light';
      case AtlasThemeMode.dark: return 'Dark';
      case AtlasThemeMode.amoled: return 'Amoled';
    }
  }

  void _showThemeDialog(
      BuildContext context, WidgetRef ref, AtlasThemeMode current) {
    showDialog(
      context: context,
      builder: (ctx) {
        AtlasThemeMode selected = current;
        return StatefulBuilder(
          builder: (ctx, setState) => SimpleDialog(
            title: const Text('Theme'),
            children: [
              RadioGroup<AtlasThemeMode>(
                groupValue: selected,
                onChanged: (v) {
                  if (v == null) return;
                  ref.read(themeModeProvider.notifier).setMode(v);
                  Navigator.pop(ctx);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: AtlasThemeMode.values.map((mode) {
                    return ListTile(
                      title: Text(_themeLabel(mode)),
                      leading: Radio<AtlasThemeMode>(value: mode),
                      onTap: () {
                        ref.read(themeModeProvider.notifier).setMode(mode);
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
