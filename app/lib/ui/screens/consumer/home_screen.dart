/// Consumer home — the app's front door.
///
/// Nine category tiles are the first thing a customer sees, and each one states
/// its real supply. That is a decision, not a placeholder: comparable
/// marketplaces win on trust in the first session, and a home screen that hides
/// low supply looks broken the moment the customer taps in. A thin category
/// says it is thin.
///
/// A visitor can browse all of this without an account — UC-4 gives browse
/// rights, so the account wall belongs at the booking action, not at launch. A
/// stranger sees supply before being asked for a number.
///
/// See docs/design-system.md and docs/categories.md.
library;

import 'package:flutter/material.dart';

import '../../../routing/navigation.dart';
import '../../../routing/routes.dart';
import '../../../theme/dimens.dart';
import '../../../theme/tokens.dart';
import '../../components/category_tile.dart';
import '../../components/surface.dart';

/// One real listing on the home screen's "near you" rail.
@immutable
class NearbyItem {
  const NearbyItem({
    required this.category,
    required this.title,
    required this.price,
  });

  final CategoryToken category;

  /// `Room · Block 8`, `Braids · Mobile`.
  final String title;

  /// `P1 200/mo`, `From P150`. Pre-formatted, because a monthly rent and a
  /// from-price are different shapes and neither is a bare amount.
  final String price;
}

@immutable
class HomeData {
  const HomeData({
    required this.city,
    required this.supplyLabels,
    required this.standings,
    required this.driversNearby,
    this.nearYou = const [],
    this.customerName,
  });

  /// Actual listings near the customer. The home screen's job is to sell
  /// supply to a stranger, so it shows real things people have listed rather
  /// than only the category grid.
  final List<NearbyItem> nearYou;

  /// Standing per category key. Set per category **per city**, because that is
  /// the unit a customer experiences — a healthy national average is no
  /// comfort to someone in Francistown looking for hire.
  final Map<String, SupplyStanding> standings;

  /// Drivers available right now. Rides is dispatch, not browse, so the count
  /// is the whole promise of the hero — an honest zero belongs here too.
  final int driversNearby;

  /// Gaborone or Francistown at launch. Named on screen because supply is a
  /// per-city fact and a count with no city is a count you cannot trust.
  final String city;

  /// Category key → honest count. A key missing from this map renders without
  /// a count, which is the loading state — never a way to hide a zero.
  final Map<String, String> supplyLabels;

  /// Null for a visitor who has not signed in. The greeting adapts; the
  /// browse rights do not.
  final String? customerName;
}

class ConsumerHomeScreen extends StatelessWidget {
  const ConsumerHomeScreen({super.key, required this.data});

  final HomeData data;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: Space.x8),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.gutter,
                Space.x4,
                Space.gutter,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data.customerName == null
                              ? 'Book, ride, send.'
                              : 'Dumela, ${data.customerName}',
                          style: text.headlineSmall,
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.notifications_outlined),
                        tooltip: 'Notifications',
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 15,
                        color: palette.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        data.city,
                        style: text.bodySmall?.copyWith(
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.x4),
                  // Rides takes the hero because it is dispatch and daily: the
                  // request goes straight to nearby drivers with sufficient
                  // credit, skipping browse and listing detail entirely. It is
                  // a different journey shape, so it gets a different entry.
                  _RidesHero(
                    driversNearby: data.driversNearby,
                    onTap: () => context.pushScreen(Routes.categoryOf('rides')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.x5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
              child: Text(
                'SERVICES',
                style: text.labelSmall?.copyWith(
                  fontSize: 10.5,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  color: palette.textMuted,
                ),
              ),
            ),
            const SizedBox(height: Space.x2),
            CategoryGrid(
              // Rides is not in the grid: it has the hero above, because it is
              // the dispatch shape and never goes through browse.
              categories: Categories.all
                  .where((c) => c.key != Categories.rides.key)
                  .toList(growable: false),
              supplyLabels: data.supplyLabels,
              standings: data.standings,
              onSelect: (category) =>
                  context.pushScreen(Routes.categoryOf(category.key)),
            ),
            const SizedBox(height: Space.x2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
              child: Text(
                'Counts are what is actually available in ${data.city} right '
                'now. A quiet category says so rather than pretending.',
                style: text.bodySmall?.copyWith(color: palette.textMuted),
              ),
            ),
            if (data.nearYou.isNotEmpty) ...[
              const SizedBox(height: Space.x6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                child: Text(
                  'NEAR YOU IN ${data.city.toUpperCase()}',
                  style: text.labelSmall?.copyWith(
                    fontSize: 10.5,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                    color: palette.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: Space.x2),
              // Real listings, not another category grid. This is what proves
              // to a stranger that there is actual supply behind the tiles —
              // the home screen's job is to sell supply to someone who has
              // not signed in yet.
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
                  itemCount: data.nearYou.length,
                  separatorBuilder: (_, _) => const SizedBox(width: Space.x3),
                  itemBuilder: (context, i) =>
                      _NearbyCard(item: data.nearYou[i]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NearbyCard extends StatelessWidget {
  const _NearbyCard({required this.item});

  final NearbyItem item;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;

    return SizedBox(
      width: 168,
      child: AppRow(
        onTap: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconPlate.category(
              item.category,
              brightness,
              size: 30,
              iconSize: 17,
            ),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
            Text(
              item.price,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelSmall?.copyWith(
                fontSize: 11,
                color: palette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The rides entry point.
///
/// Rides is the dispatch shape: no browse, no listing detail, no choosing a
/// provider. The request goes to nearby drivers who hold enough credit to
/// accept it (FR-3.10), so the only thing this needs to collect is a
/// destination — and the only thing it needs to promise is how many drivers
/// are actually there.
class _RidesHero extends StatelessWidget {
  const _RidesHero({required this.driversNearby, required this.onTap});

  final int driversNearby;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return HeroSurface(
      padding: const EdgeInsets.all(Space.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_car, size: 22),
              const SizedBox(width: Space.x2),
              Expanded(
                child: Text(
                  'Need a ride?',
                  style: text.titleLarge?.copyWith(color: Brand.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.x1),
          Text(
            driversNearby == 0
                // An honest zero. Dispatch with nobody to dispatch to is a
                // promise the app cannot keep, and saying so beats a spinner.
                ? 'No drivers nearby right now'
                : '$driversNearby drivers nearby right now',
            style: text.bodySmall?.copyWith(
              color: Brand.white.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: Space.x4),
          Material(
            color: Brand.white,
            borderRadius: Radii.buttonAll,
            child: InkWell(
              onTap: onTap,
              borderRadius: Radii.buttonAll,
              child: Container(
                height: Touch.min,
                padding: const EdgeInsets.symmetric(horizontal: Space.x3),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 20, color: Brand.deep),
                    const SizedBox(width: Space.x2),
                    Expanded(
                      child: Text(
                        'Where to?',
                        style: text.bodyLarge?.copyWith(color: Brand.deep),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
