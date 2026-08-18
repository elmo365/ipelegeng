/// Ipelege.
///
/// Everything visual comes from [AppTheme]; everything navigational from
/// [createRouter]. This file wires the two together and does nothing else.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'routing/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_mode.dart';

void main() {
  runApp(const ProviderScope(child: IpelegeApp()));
}

/// Built once and kept, so a rebuild never drops the navigation stacks.
final routerProvider = Provider<GoRouter>((ref) => createRouter());

class IpelegeApp extends ConsumerWidget {
  const IpelegeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Ipelege',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
