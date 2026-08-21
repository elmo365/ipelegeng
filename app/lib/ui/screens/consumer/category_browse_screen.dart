/// Category browse — the browse-and-book shape.
///
/// Seven of the nine categories arrive here. Rides does not: it is dispatch,
/// and skips browse and listing detail entirely. Property rentals arrives but
/// leads to an enquiry rather than a booking, because it is pay-per-listing
/// with no commission and no completion.
///
/// Each provider is a card with the price pulled right, and the direction
/// filter narrows by **how the service is delivered** — which is the axis that
/// matters when nobody has fixed premises.
///
/// See docs/categories.md and docs/design-deltas.md#6-the-journey-has-three-shapes-not-one.
library;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../routing/navigation.dart';
import '../../../routing/routes.dart';
import '../../../theme/dimens.dart';
import '../../../theme/tokens.dart';
import '../../components/category_tile.dart';
import '../../components/money_text.dart';
import '../../components/status_chip.dart';
import '../../components/surface.dart';

/// How the service reaches the customer.
///
/// **Confirmed against the canvas 2026-08-21**, which the previous note here
/// asked for: the customer-facing set is two options, not three, and the
/// canvas writes both the label and the line under it —
///
/// > `{ key: 'provider_comes', label: 'Comes to you', sub: 'Provider travels to your location' }`
/// > `{ key: 'customer_goes',  label: 'You go to them', sub: 'Service is at their premises' }`
///
/// [either] is **not** one of those, and it is not an invention either. It is a
/// property of a *listing*, from docs/booking.md: "**Both** — provider offers
/// either", with the customer picking the applicable one at the point of
/// booking. So a listing may be `either`; a booking request never is, which is
/// what [choices] exists to say.
enum ServiceDirection {
  comesToYou(
    'Comes to you',
    'Provider travels to your location',
    Icons.directions_walk,
  ),
  youGoToThem(
    'You go to them',
    'Service is at their premises',
    Icons.storefront,
  ),

  /// A listing that offers both. The sub-line is docs/booking.md's own wording
  /// rather than the canvas's, because the canvas never offers this one.
  either('Either', 'Provider offers either', Icons.swap_horiz);

  const ServiceDirection(this.label, this.sub, this.icon);

  final String label;

  /// The line under the label in the booking request's radio set.
  final String sub;

  final IconData icon;

  /// The two a customer may choose between: the browse filter's chips and the
  /// booking request's radio set are the same pair, and both read it from
  /// here rather than filtering [values] by hand.
  static const choices = <ServiceDirection>[comesToYou, youGoToThem];
}

@immutable
class Listing {
  const Listing({
    required this.id,
    required this.name,
    required this.tag,
    required this.fromPrice,
    required this.direction,
    required this.verified,
    required this.isNew,
  });

  final String id;
  final String name;

  /// `Block 8, Gaborone`, `Mobile · same day`.
  final String tag;

  final Decimal fromPrice;
  final ServiceDirection direction;

  /// A compliance fact, present from day one.
  final bool verified;

  /// Zero completed jobs. Shown *beside* verification, never instead of it —
  /// the two are independent signals and conflating them is what strands new
  /// providers.
  final bool isNew;
}

@immutable
class CategoryBrowseData {
  const CategoryBrowseData({
    required this.category,
    required this.city,
    required this.listings,
    required this.standing,
    this.direction,
  });

  final CategoryToken category;
  final String city;
  final List<Listing> listings;
  final SupplyStanding standing;

  /// Null means no filter applied.
  final ServiceDirection? direction;

  List<Listing> get visible => rank(filter(listings, direction));

  /// Narrow by how the service is delivered.
  static List<Listing> filter(List<Listing> all, ServiceDirection? direction) =>
      direction == null
      ? all
      : all
            .where(
              (l) =>
                  l.direction == direction ||
                  l.direction == ServiceDirection.either,
            )
            .toList(growable: false);

  /// Placement, with the new-provider boost.
  ///
  /// The repo's own recommendation on ratings is to build them **with** an
  /// explicit new-provider boost, otherwise you manufacture provider churn.
  /// Labelling a provider "New on Ipelege" is only half the fix — a provider
  /// nobody scrolls to never gets a first job, which is the failure that
  /// contributed to Lynk's shutdown.
  ///
  /// So one new provider is guaranteed a slot above the fold. It is a single
  /// slot, not a re-sort: established providers are not buried to make the
  /// point, and the boost does not compound as more new providers join.
  static List<Listing> rank(List<Listing> filtered) {
    const aboveTheFold = 3;
    if (filtered.length <= aboveTheFold) return filtered;

    final firstNew = filtered.indexWhere((l) => l.isNew);
    if (firstNew < 0 || firstNew < aboveTheFold) return filtered;

    final ranked = [...filtered];
    // Second position, not first: the boost earns a look, it does not claim
    // to be the best match.
    ranked.insert(1, ranked.removeAt(firstNew));
    return List.unmodifiable(ranked);
  }
}

class CategoryBrowseScreen extends StatefulWidget {
  const CategoryBrowseScreen({super.key, required this.data});

  final CategoryBrowseData data;

  @override
  State<CategoryBrowseScreen> createState() => _CategoryBrowseScreenState();
}

class _CategoryBrowseScreenState extends State<CategoryBrowseScreen> {
  ServiceDirection? _direction;

  @override
  void initState() {
    super.initState();
    _direction = widget.data.direction;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;
    final data = widget.data;

    final visible = CategoryBrowseData.rank(
      CategoryBrowseData.filter(data.listings, _direction),
    );

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            IconPlate.category(
              data.category,
              brightness,
              size: 32,
              iconSize: 18,
            ),
            const SizedBox(width: Space.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    data.category.label,
                    style: text.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${data.city} · ${data.listings.length} '
                    '${data.listings.length == 1 ? 'provider' : 'providers'}',
                    style: text.labelSmall?.copyWith(
                      fontSize: 11.5,
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.tune),
            tooltip: 'Filters',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.gutter,
                  vertical: Space.x2,
                ),
                children: [
                  _DirectionChip(
                    label: 'Any direction',
                    selected: _direction == null,
                    onTap: () => setState(() => _direction = null),
                  ),
                  for (final d in ServiceDirection.choices)
                    _DirectionChip(
                      label: d.label,
                      icon: d.icon,
                      selected: _direction == d,
                      onTap: () => setState(() => _direction = d),
                    ),
                ],
              ),
            ),
            Expanded(
              child: visible.isEmpty
                  ? _EmptyBrowse(category: data.category, city: data.city)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        Space.gutter,
                        Space.x2,
                        Space.gutter,
                        Space.x8,
                      ),
                      itemCount: visible.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: Space.x3),
                      itemBuilder: (context, i) => _ListingCard(
                        listing: visible[i],
                        category: data.category,
                        onTap: () =>
                            context.pushScreen(Routes.listingOf(visible[i].id)),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectionChip extends StatelessWidget {
  const _DirectionChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(right: Space.x2),
      child: Material(
        color: selected ? Brand.deep : palette.cardBg,
        borderRadius: Radii.pillAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: Radii.pillAll,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 17,
                    color: selected ? Brand.white : palette.textMuted,
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: text.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: selected ? Brand.white : palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({
    required this.listing,
    required this.category,
    required this.onTap,
  });

  final Listing listing;
  final CategoryToken category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;

    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconPlate.category(category, brightness),
          const SizedBox(width: Space.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.name,
                  style: text.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  listing.tag,
                  style: text.labelSmall?.copyWith(
                    fontSize: 11.5,
                    color: palette.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Space.x2),
                // Two independent signals, side by side. Verification is a
                // compliance fact from day one; "new" is the absence of a
                // review history. Neither substitutes for the other.
                Wrap(
                  spacing: Space.x2,
                  runSpacing: Space.x1,
                  children: [
                    if (listing.verified) StatusChip.verified(category.label),
                    if (listing.isNew) const StatusChip.newProvider(),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: Space.x2),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'FROM',
                style: text.labelSmall?.copyWith(
                  fontSize: 9.5,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w700,
                  color: palette.textFaint,
                ),
              ),
              const SizedBox(height: 2),
              MoneyText(listing.fromPrice),
            ],
          ),
        ],
      ),
    );
  }
}

/// What a filtered-to-nothing category says.
///
/// It states the fact and offers the way back, rather than showing a spinner
/// or an illustration that implies something is loading.
class _EmptyBrowse extends StatelessWidget {
  const _EmptyBrowse({required this.category, required this.city});

  final CategoryToken category;
  final String city;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.x6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nobody here yet',
              style: text.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Space.x2),
            Text(
              'No ${category.label.toLowerCase()} provider in $city matches '
              'that filter right now. Try removing it.',
              style: text.bodySmall?.copyWith(color: palette.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
