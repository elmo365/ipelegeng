/// The user's preferences, and where they live between launches.
///
/// The Preferences screen is Phase 7 in the design's own ordering. This spine
/// was pulled forward to Phase 3.5 for a reason that only became visible when
/// someone asked where a new preference would go:
///
/// > **Dark mode was finished and unreachable.** Both themes, the whole
/// > palette and `themeModeProvider` were built and verified on two devices,
/// > and the only control that drives them was a row on a screen that rendered
/// > `PlaceholderScreen`. The app shipped a completed feature nobody could
/// > turn on.
///
/// So this file is deliberately narrow. It holds the preferences that have
/// somewhere to be *set* today, and it is the seam Phase 5 reads rather than a
/// reason to build Phase 7 early. Account, Security, Data & storage and
/// deletion stay where they are — they are the compliance surface and they
/// need their own care.
///
/// ## Why the store is shaped like `session_store.dart`
///
/// Same seam, same reason: [PrefsSettingsStore] ships, the in-memory one is
/// the default so a widget test never needs a platform channel, and every
/// mutation goes through a single write so a preference added later cannot be
/// silently not persisted. That last point is not hypothetical — the session
/// store had exactly that bug, where a policy written into the shipping store
/// only meant the tests were passing against behaviour the app did not have.
///
/// ## What is *not* here
///
/// Notifications (SMS / WhatsApp / Push) are on the canvas's Preferences
/// artboard, and they are consent records rather than preferences: the consent
/// screen already collects them under FR-1.10, and moving them here without
/// moving the consent trail with them would split one DPA record across two
/// stores. They land with Phase 7.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class Settings {
  const Settings({
    this.themeMode = ThemeMode.system,
    this.keepScreenOnDuringRides = true,
  });

  /// Light / Dark / System. The canvas: *"System follows your phone. This
  /// control drives every screen in this document too."*
  final ThemeMode themeMode;

  /// Holds the display awake **during a ride, and nowhere else**.
  ///
  /// Default **on**, because a passenger watching a driver approach and a
  /// driver following a route are both looking at a screen they are not
  /// touching — the exact condition a 30-second display timeout ends. Off is
  /// honoured absolutely: a user on 8% battery who turns this off has made a
  /// real decision about their evening.
  ///
  /// **Nothing reads this yet.** The ride screens are Phase 5. It is stored
  /// now so that Phase 5 finds a preference already here instead of needing a
  /// detour through Phase 7 to add one row — see docs/device-permissions.md §1
  /// for the scoping rules it will be read under, and §2b for why the *overlay*
  /// permission could not be front-loaded the same way.
  final bool keepScreenOnDuringRides;

  Settings copyWith({ThemeMode? themeMode, bool? keepScreenOnDuringRides}) =>
      Settings(
        themeMode: themeMode ?? this.themeMode,
        keepScreenOnDuringRides:
            keepScreenOnDuringRides ?? this.keepScreenOnDuringRides,
      );

  @override
  bool operator ==(Object other) =>
      other is Settings &&
      other.themeMode == themeMode &&
      other.keepScreenOnDuringRides == keepScreenOnDuringRides;

  @override
  int get hashCode => Object.hash(themeMode, keepScreenOnDuringRides);
}

/// The seam. See the library doc for why it mirrors `SessionStore`.
abstract base class SettingsStore {
  /// Null when nothing is stored, or when what is stored cannot be read.
  Settings? read();

  void write(Settings settings);
}

/// The default: remembers nothing across a process, which is what a test wants.
final class InMemorySettingsStore extends SettingsStore {
  Settings? _settings;

  @override
  Settings? read() => _settings;

  @override
  void write(Settings settings) => _settings = settings;
}

final class PrefsSettingsStore extends SettingsStore {
  PrefsSettingsStore(this._prefs);

  static const _key = 'settings.v1';

  final SharedPreferences _prefs;

  @override
  Settings? read() {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      return SettingsCodec.fromJson(json);
    } on FormatException {
      // A half-written or downgraded record is not worth a crash on launch.
      // Dropping it costs the user their theme choice; throwing costs the app.
      return null;
    }
  }

  @override
  void write(Settings settings) =>
      _prefs.setString(_key, jsonEncode(SettingsCodec.toJson(settings)));
}

/// Serialisation, kept out of [Settings] so the model has no opinion about
/// storage — the same split `SessionCodec` makes.
abstract final class SettingsCodec {
  static Map<String, dynamic> toJson(Settings s) => {
    'themeMode': s.themeMode.name,
    'keepScreenOnDuringRides': s.keepScreenOnDuringRides,
  };

  static Settings fromJson(Map<String, dynamic> json) {
    // Every field falls back to its default rather than throwing. A preference
    // file written by a newer build, or by one that did not have this field
    // yet, should cost the user that one preference — not the launch.
    final mode = switch (json['themeMode']) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    return Settings(
      themeMode: mode,
      keepScreenOnDuringRides: switch (json['keepScreenOnDuringRides']) {
        final bool b => b,
        _ => true,
      },
    );
  }
}

final settingsStoreProvider = Provider<SettingsStore>(
  (ref) => InMemorySettingsStore(),
);

final settingsProvider = NotifierProvider<SettingsController, Settings>(
  SettingsController.new,
);

class SettingsController extends Notifier<Settings> {
  @override
  Settings build() =>
      ref.read(settingsStoreProvider).read() ?? const Settings();

  /// **Every mutation goes through here.** Not a style preference: the session
  /// store shipped a bug where a rule lived in one implementation and not the
  /// other, and the fix was to make it impossible to mutate without writing.
  void _set(Settings next) {
    state = next;
    ref.read(settingsStoreProvider).write(next);
  }

  void selectTheme(ThemeMode mode) => _set(state.copyWith(themeMode: mode));

  void setKeepScreenOnDuringRides({required bool on}) =>
      _set(state.copyWith(keepScreenOnDuringRides: on));
}
