/// 18 · Preferences.
///
/// The canvas artboard is labelled `Settings` and titled *Preferences*; this
/// follows the title, because that is the word the user sees.
///
/// **Why this screen exists before the rest of Phase 7.** Dark mode was
/// finished and unreachable: both themes, the whole palette and the theme
/// provider were built and verified on two devices, and the only control that
/// drove them was a row on a screen that rendered `PlaceholderScreen`. See
/// docs/build-order.md Phase 3.5.
///
/// Two of the canvas's three groups are here. The third — **Notifications**
/// (SMS / WhatsApp / Push) — is deliberately absent: those are consent records
/// rather than preferences, the consent screen already collects them under
/// FR-1.10, and splitting one DPA trail across two stores to save a phase
/// would be the wrong kind of shortcut. They land with Phase 7.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings.dart';
import '../../../theme/dimens.dart';
import '../../../theme/tokens.dart';
import '../../../theme/typography.dart';
import '../../components/screen_header.dart';
import '../../components/stepper_bar.dart';

class PreferencesScreen extends ConsumerWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Preferences'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                children: [
                  const _GroupLabel('APPEARANCE'),
                  const SizedBox(height: Space.x2),
                  _AppearanceCard(
                    selected: settings.themeMode,
                    onSelect: controller.selectTheme,
                  ),
                  const SizedBox(height: Space.x5),

                  const _GroupLabel('DURING A RIDE'),
                  const SizedBox(height: Space.x2),
                  _Card(
                    child: ToggleRow(
                      label: 'Keep the screen on',
                      // The cost, in the words a user on a failing battery
                      // would want. Not hidden, and not apologised for.
                      note:
                          'The display stays awake while a ride is on its way '
                          'or under way. Uses more battery.',
                      value: settings.keepScreenOnDuringRides,
                      onChanged: (on) =>
                          controller.setKeepScreenOnDuringRides(on: on),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTypography.sectionLabel.copyWith(
      fontSize: 10.5,
      color: context.palette.textMuted,
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: Radii.cardAll,
        boxShadow: palette.shadowRow,
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

/// Light / Dark / System, as three rows rather than a segmented control.
///
/// The canvas's own sub-line is kept verbatim: *"System follows your phone.
/// This control drives every screen in this document too."* — trimmed only of
/// the clause about the design document, which is not a thing the user is
/// holding.
class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard({required this.selected, required this.onSelect});

  final ThemeMode selected;
  final ValueChanged<ThemeMode> onSelect;

  static const _modes = <(ThemeMode, String, IconData)>[
    (ThemeMode.light, 'Light', Icons.light_mode),
    (ThemeMode.dark, 'Dark', Icons.dark_mode),
    (ThemeMode.system, 'System', Icons.brightness_auto),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (mode, label, icon) in _modes) ...[
            Semantics(
              inMutuallyExclusiveGroup: true,
              selected: mode == selected,
              button: true,
              label: label,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: () => onSelect(mode),
                  borderRadius: Radii.rowAll,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 11,
                      horizontal: 4,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          size: 20,
                          color: mode == selected
                              ? palette.accentText
                              : palette.textMuted,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ExcludeSemantics(
                            child: Text(
                              label,
                              style: text.bodyMedium?.copyWith(
                                fontSize: 13.5,
                                fontWeight: mode == selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        // A tick rather than a radio: the choice is already
                        // legible from the row's own weight, and status never
                        // depends on colour alone.
                        if (mode == selected)
                          Icon(
                            Icons.check,
                            size: 19,
                            color: palette.accentText,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'System follows your phone.',
            style: text.labelSmall?.copyWith(
              fontSize: 11.5,
              height: 1.5,
              color: palette.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
