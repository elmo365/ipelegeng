/// Phase 3.5 — the settings spine.
///
/// The screen is small; the rules behind it are not, and they are the ones a
/// later change is likely to break:
///
/// - **A preference that is set must be written.** The session store shipped a
///   bug where a rule lived in one implementation and not the other, so tests
///   passed against behaviour the app did not have. `SettingsController` writes
///   through a single `_set` for exactly that reason, and these tests are what
///   stop someone adding a mutator that bypasses it.
/// - **Dark mode has to actually be reachable.** That is the whole reason this
///   phase was pulled forward.
/// - **A corrupt or older preferences record must not cost the launch.**
///
/// See docs/build-order.md Phase 3.5 and docs/device-permissions.md §1.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ipelege/core/settings.dart';
import 'package:ipelege/theme/app_theme.dart';
import 'package:ipelege/ui/screens/settings/preferences_screen.dart';

Future<ProviderContainer> pumpPreferences(
  WidgetTester tester, {
  SettingsStore? store,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      if (store != null) settingsStoreProvider.overrideWithValue(store),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      // AppTheme, not a bare MaterialApp: the palette is a ThemeExtension and
      // every component reads it through `context.palette`.
      child: MaterialApp(
        theme: AppTheme.light,
        home: const PreferencesScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  group('appearance — the row that made this phase worth pulling forward', () {
    testWidgets('all three modes are offered', (tester) async {
      await pumpPreferences(tester);

      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
    });

    testWidgets('choosing dark actually reaches the app', (tester) async {
      final store = InMemorySettingsStore();
      final container = await pumpPreferences(tester, store: store);

      expect(container.read(settingsProvider).themeMode, ThemeMode.system);

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      // The provider `main.dart` watches. Before this phase the palette and
      // both themes existed and nothing on any screen could change this value.
      expect(container.read(settingsProvider).themeMode, ThemeMode.dark);
    });

    testWidgets('and survives the next launch', (tester) async {
      final store = InMemorySettingsStore();
      final first = await pumpPreferences(tester, store: store);
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      first.dispose();

      // A second container over the same store is what a relaunch looks like.
      final next = ProviderContainer(
        overrides: [settingsStoreProvider.overrideWithValue(store)],
      );
      addTearDown(next.dispose);
      expect(next.read(settingsProvider).themeMode, ThemeMode.dark);
    });
  });

  group('keep the screen on during a ride', () {
    testWidgets('defaults on, and says what it costs', (tester) async {
      await pumpPreferences(tester);

      expect(find.text('Keep the screen on'), findsOneWidget);
      // The battery cost is stated, not buried. A user on 8% deserves to see
      // it at the moment they are deciding.
      expect(find.textContaining('Uses more battery'), findsOneWidget);

      final toggle = tester.widget<Switch>(find.byType(Switch));
      expect(toggle.value, isTrue);
    });

    testWidgets('turning it off is honoured and written', (tester) async {
      final store = InMemorySettingsStore();
      final container = await pumpPreferences(tester, store: store);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(container.read(settingsProvider).keepScreenOnDuringRides, isFalse);
      // Written, not merely held: the mutator cannot skip the store.
      expect(store.read()?.keepScreenOnDuringRides, isFalse);
    });
  });

  group('the store cannot be mutated without being written', () {
    test('every mutator goes through the single write', () {
      final store = InMemorySettingsStore();
      final container = ProviderContainer(
        overrides: [settingsStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);

      final controller = container.read(settingsProvider.notifier);

      controller.selectTheme(ThemeMode.light);
      expect(store.read()?.themeMode, ThemeMode.light);

      controller.setKeepScreenOnDuringRides(on: false);
      // Both fields, after two separate mutations — a mutator that replaced
      // the state without writing would lose the first one here.
      expect(store.read()?.themeMode, ThemeMode.light);
      expect(store.read()?.keepScreenOnDuringRides, isFalse);
    });
  });

  group('a record this build cannot fully read costs a preference, not the app', () {
    test('an unknown theme name falls back to system', () {
      final s = SettingsCodec.fromJson({
        'themeMode': 'sepia',
        'keepScreenOnDuringRides': false,
      });

      expect(s.themeMode, ThemeMode.system);
      // The field it *could* read is still honoured.
      expect(s.keepScreenOnDuringRides, isFalse);
    });

    test('a missing field takes its default rather than throwing', () {
      final s = SettingsCodec.fromJson({'themeMode': 'dark'});

      expect(s.themeMode, ThemeMode.dark);
      expect(s.keepScreenOnDuringRides, isTrue);
    });

    test('a round trip is lossless', () {
      const original = Settings(
        themeMode: ThemeMode.dark,
        keepScreenOnDuringRides: false,
      );

      expect(SettingsCodec.fromJson(SettingsCodec.toJson(original)), original);
    });
  });

  group('what is deliberately absent', () {
    testWidgets('notifications are not here — they are consent records', (
      tester,
    ) async {
      await pumpPreferences(tester);

      // The canvas puts SMS / WhatsApp / Push on this artboard. They stay with
      // the consent screen under FR-1.10 until Phase 7 can move the whole DPA
      // trail together, rather than splitting one record across two stores.
      expect(find.textContaining('WhatsApp'), findsNothing);
      expect(find.textContaining('SMS'), findsNothing);
    });
  });

  test('both themes exist for the setting to choose between', () {
    expect(AppTheme.light.brightness, Brightness.light);
    expect(AppTheme.dark.brightness, Brightness.dark);
  });
}
