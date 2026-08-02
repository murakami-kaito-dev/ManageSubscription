import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/shell/home_shell.dart';
import 'providers/settings_provider.dart';

class ManageSubscriptionApp extends ConsumerWidget {
  const ManageSubscriptionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Theme color is free for everyone; apply the stored accent directly.
    final accent = ref.watch(settingsProvider.select((s) => s.accent));

    return MaterialApp(
      title: 'サブスク管理',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(accent: accent),
      home: const HomeShell(),
    );
  }
}
