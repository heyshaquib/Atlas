/// Atlas App Shell — MaterialApp with dynamic color, theme switching,
/// and bottom navigation with 3 tabs.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'package:atlas/core/theme/app_theme.dart';
import 'package:atlas/core/models/models.dart';
import 'package:atlas/core/database/app_database.dart';

import 'package:atlas/features/bookmarks/bookmarks_screen.dart';
import 'package:atlas/features/search/search_screen.dart';
import 'package:atlas/features/folders/folders_screen.dart';
import 'package:atlas/features/share/share_intent_handler.dart';
import 'package:atlas/features/onboarding/onboarding_screen.dart';

// ─── Global Providers ─────────────────────────────────────

/// Database singleton
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// SharedPreferences
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

/// Theme mode provider
final themeModeProvider = NotifierProvider<ThemeModeNotifier, AtlasThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<AtlasThemeMode> {
  @override
  AtlasThemeMode build() {
    _load();
    return AtlasThemeMode.system;
  }

  Future<void> _load() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final mode = prefs.getString('theme_mode') ?? 'system';
    state = AtlasThemeMode.values.firstWhere(
      (m) => m.name == mode,
      orElse: () => AtlasThemeMode.system,
    );
  }

  Future<void> setMode(AtlasThemeMode mode) async {
    state = mode;
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString('theme_mode', mode.name);
  }
}

/// Dynamic color toggle
final dynamicColorEnabledProvider =
    NotifierProvider<DynamicColorNotifier, bool>(DynamicColorNotifier.new);

class DynamicColorNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return true;
  }

  Future<void> _load() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    state = prefs.getBool('dynamic_color') ?? true;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool('dynamic_color', state);
  }
}

/// View mode provider
final viewModeProvider = NotifierProvider<ViewModeNotifier, ViewMode>(
  ViewModeNotifier.new,
);

class ViewModeNotifier extends Notifier<ViewMode> {
  @override
  ViewMode build() {
    _load();
    return ViewMode.list;
  }

  Future<void> _load() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final mode = prefs.getString('view_mode') ?? 'list';
    state = ViewMode.values.firstWhere(
      (m) => m.name == mode,
      orElse: () => ViewMode.list,
    );
  }

  void cycle() {
    final modes = ViewMode.values;
    final nextIndex = (modes.indexOf(state) + 1) % modes.length;
    state = modes[nextIndex];
    _save();
  }

  void setMode(ViewMode mode) {
    state = mode;
    _save();
  }

  Future<void> _save() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString('view_mode', state.name);
  }
}

/// Show reading time badge
final showReadingTimeProvider = NotifierProvider<ShowReadingTimeNotifier, bool>(
  ShowReadingTimeNotifier.new,
);

class ShowReadingTimeNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return true;
  }

  Future<void> _load() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    state = prefs.getBool('show_reading_time') ?? true;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool('show_reading_time', state);
  }
}

/// Browser choice
final browserChoiceProvider =
    NotifierProvider<BrowserChoiceNotifier, BrowserChoice>(
      BrowserChoiceNotifier.new,
    );

class BrowserChoiceNotifier extends Notifier<BrowserChoice> {
  @override
  BrowserChoice build() {
    _load();
    return BrowserChoice.inApp;
  }

  Future<void> _load() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final choice = prefs.getString('browser_choice') ?? 'inApp';
    state = BrowserChoice.values.firstWhere(
      (c) => c.name == choice,
      orElse: () => BrowserChoice.inApp,
    );
  }

  Future<void> setChoice(BrowserChoice choice) async {
    state = choice;
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString('browser_choice', choice.name);
  }
}

/// Mark as read on open
final markAsReadOnOpenProvider =
    NotifierProvider<MarkAsReadOnOpenNotifier, bool>(
      MarkAsReadOnOpenNotifier.new,
    );

class MarkAsReadOnOpenNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return true;
  }

  Future<void> _load() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    state = prefs.getBool('mark_read_on_open') ?? true;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool('mark_read_on_open', state);
  }
}

// ─── Atlas App ────────────────────────────────────────────

class AtlasApp extends ConsumerStatefulWidget {
  final bool initialOnboardingDone;

  const AtlasApp({super.key, required this.initialOnboardingDone});

  @override
  ConsumerState<AtlasApp> createState() => _AtlasAppState();
}

class _AtlasAppState extends ConsumerState<AtlasApp> {
  ColorScheme? _lightDynamic;
  ColorScheme? _darkDynamic;
  bool _monetLoaded = false;

  @override
  void initState() {
    super.initState();
    _syncSplashAndMonet();
  }

  Future<void> _syncSplashAndMonet() async {
    try {
      final corePalette = await DynamicColorPlugin.getCorePalette();
      if (corePalette != null) {
        _lightDynamic = corePalette.toColorScheme();
        _darkDynamic = corePalette.toColorScheme(brightness: Brightness.dark);
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _monetLoaded = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FlutterNativeSplash.remove();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_monetLoaded) {
      return const SizedBox.shrink();
    }

    final themeMode = ref.watch(themeModeProvider);
    final dynamicColorEnabled = ref.watch(dynamicColorEnabledProvider);

    final lightScheme = dynamicColorEnabled ? _lightDynamic : null;
    final darkScheme = dynamicColorEnabled ? _darkDynamic : null;

    final lightTheme = buildAtlasTheme(
      brightness: Brightness.light,
      dynamicScheme: lightScheme,
    );
    final darkTheme = buildAtlasTheme(
      brightness: Brightness.dark,
      dynamicScheme: darkScheme,
    );
    final amoledTheme = buildAtlasTheme(
      brightness: Brightness.dark,
      dynamicScheme: darkScheme,
      isAmoled: true,
    );

    ThemeData effectiveTheme;
    ThemeData effectiveDarkTheme;
    ThemeMode flutterThemeMode;

    switch (themeMode) {
      case AtlasThemeMode.light:
        effectiveTheme = lightTheme;
        effectiveDarkTheme = darkTheme;
        flutterThemeMode = ThemeMode.light;
        break;
      case AtlasThemeMode.dark:
        effectiveTheme = lightTheme;
        effectiveDarkTheme = darkTheme;
        flutterThemeMode = ThemeMode.dark;
        break;
      case AtlasThemeMode.amoled:
        effectiveTheme = lightTheme;
        effectiveDarkTheme = amoledTheme;
        flutterThemeMode = ThemeMode.dark;
        break;
      case AtlasThemeMode.system:
        effectiveTheme = lightTheme;
        effectiveDarkTheme = darkTheme;
        flutterThemeMode = ThemeMode.system;
        break;
    }

    return MaterialApp(
      title: 'Atlas',
      debugShowCheckedModeBanner: false,
      theme: effectiveTheme,
      darkTheme: effectiveDarkTheme,
      themeMode: flutterThemeMode,
      home: widget.initialOnboardingDone
          ? const AtlasShell()
          : const OnboardingScreen(),
    );
  }
}

// ─── Shell with Bottom Navigation ─────────────────────────

class AtlasShell extends ConsumerStatefulWidget {
  const AtlasShell({super.key});

  @override
  ConsumerState<AtlasShell> createState() => _AtlasShellState();
}

class _AtlasShellState extends ConsumerState<AtlasShell> {
  int _currentIndex = 0;

  final _screens = const [BookmarksScreen(), SearchScreen(), FoldersScreen()];

  @override
  void initState() {
    super.initState();
    ShareIntentHandler.checkInitialIntent(context);
    ShareIntentHandler.setupIntentListener(context);
  }

  @override
  Widget build(BuildContext context) {
    // Update system UI based on theme
    final brightness = Theme.of(context).brightness;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
    );

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: IndexedStack(
            key: ValueKey(_currentIndex),
            index: _currentIndex,
            children: _screens,
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            HapticFeedback.selectionClick();
            setState(() => _currentIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.bookmarks_outlined),
              selectedIcon: Icon(Icons.bookmarks),
              label: 'Bookmarks',
            ),
            NavigationDestination(
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search),
              label: 'Search',
            ),
            NavigationDestination(
              icon: Icon(Icons.folder_outlined),
              selectedIcon: Icon(Icons.folder),
              label: 'Folders',
            ),
          ],
        ),
      ),
    );
  }
}
