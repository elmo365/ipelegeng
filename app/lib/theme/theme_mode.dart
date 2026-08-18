/// Light, dark or follow the system.
///
/// The design is two full themes, not one with a filter, so the choice is a
/// first-class setting (Settings → Appearance in the screen inventory) rather
/// than something inferred. It defaults to the system so a user who has
/// already chosen dark everywhere else is not asked again.
///
/// Persistence lands with the settings store; until then the choice lives for
/// the session.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void select(ThemeMode mode) => state = mode;
}
