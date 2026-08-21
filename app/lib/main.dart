/// Ipelege.
///
/// Everything visual comes from [AppTheme]; everything navigational from
/// [createRouter]. This file wires the two together and does nothing else.
library;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';

import 'core/biometrics.dart';
import 'core/session.dart';
import 'core/session_store.dart';
import 'core/settings.dart';
import 'routing/app_router.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  // Resolved before the first frame so every read and write afterwards is
  // synchronous, which is what lets SessionController.build() stay sync and
  // the app open straight onto the right screen instead of flashing the splash
  // and then correcting itself.
  WidgetsFlutterBinding.ensureInitialized();

  // **Firebase is initialised for messaging, not for auth.** The two are
  // independent products in one project, and only one of them costs money:
  // FCM is free and unlimited, phone auth is billed past a quota. Push is the
  // only way to reach a closed app on Android — a socket dies to Doze unless a
  // foreground service holds it up, which a waiting customer will never have —
  // and the manifest has expected FCM since the notification icon landed.
  //
  // A failure here must not take the app down. Firebase is how a booking
  // update *arrives*; it is not how the app *runs*, and browse, search and the
  // whole entry flow work without it.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    debugPrint('Firebase unavailable, continuing without push: ${e.code}');
  }

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sessionStoreProvider.overrideWithValue(PrefsSessionStore(prefs)),
        settingsStoreProvider.overrideWithValue(PrefsSettingsStore(prefs)),
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
      // Narrowed with `select`, so changing an unrelated preference does not
      // rebuild the whole app.
      themeMode: ref.watch(settingsProvider.select((s) => s.themeMode)),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
