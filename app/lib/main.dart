/// Ipelege.
///
/// Everything visual comes from [AppTheme]; everything navigational from
/// [createRouter]. This file wires the two together and does nothing else.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/biometrics.dart';
import 'core/session.dart';
import 'core/session_store.dart';
import 'routing/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_mode.dart';

Future<void> main() async {
  // Resolved before the first frame so every read and write afterwards is
  // synchronous, which is what lets SessionController.build() stay sync and
  // the app open straight onto the right screen instead of flashing the splash
  // and then correcting itself.
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sessionStoreProvider.overrideWithValue(PrefsSessionStore(prefs)),
        // The real sensor. The default is AlwaysAllowBiometrics so a widget
        // test never needs a platform channel — the same shape the session
        // store and the OTP verifier use.
        biometricsProvider.overrideWithValue(PlatformBiometrics()),
      ],
      child: const IpelegeApp(),
    ),
  );
}

/// Built once and kept, so a rebuild never drops the navigation stacks.
///
/// The session is handed in as a read rather than a watch: watching would
/// rebuild the router and drop every stack on the first sign-in. The router
/// only needs the session at the moment it evaluates a redirect, which is what
/// enforces consent supersede — see `createRouter`.
final routerProvider = Provider<GoRouter>(
  (ref) => createRouter(readSession: () => ref.read(sessionProvider)),
);

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
