import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/notifications/foreground_reminder_host.dart';
import 'features/shell/home_shell.dart';
import 'providers/settings_provider.dart';

class ManageSubscriptionApp extends ConsumerWidget {
  const ManageSubscriptionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Theme color is free for everyone; apply the stored accent directly.
    final accent = ref.watch(settingsProvider.select((s) => s.accent));

    return MaterialApp(
      title: 'サブスク家計簿',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(accent: accent),
      // Japanese UI for the native date/time pickers and calendar.
      locale: const Locale('ja'),
      supportedLocales: const [Locale('ja'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Floats the in-app reminder banner above every screen so a due reminder
      // is always shown while the app is open, regardless of OS foreground rules.
      builder: (context, child) =>
          ForegroundReminderHost(child: child ?? const SizedBox.shrink()),
      home: const HomeShell(),
    );
  }
}
