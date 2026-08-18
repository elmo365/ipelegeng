/// A screen that exists so navigation can be built and tested before the real
/// screens land. Replaced one at a time; nothing else should depend on it.
///
/// It carries no colours or sizes of its own — every value comes from the
/// theme, which is the point: when a real screen replaces it, the look does
/// not change.
library;

import 'package:flutter/material.dart';

import '../../theme/dimens.dart';
import '../../theme/tokens.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    this.note,
    this.showAppBar = true,
  });

  final String title;
  final String? note;
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: showAppBar ? AppBar(title: Text(title)) : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: Breakpoints.formMaxWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.all(Space.x6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: text.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Space.x2),
                  Text(
                    note ?? 'Not built yet.',
                    style: text.bodySmall?.copyWith(color: palette.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
