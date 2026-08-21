/// Scaffolding data, so the screens can be built and looked at before the API
/// exists.
///
/// **This file is temporary.** Every screen takes its data as a constructor
/// argument, so when the Django backend lands the change is at the router, not
/// in the screens. Delete this file then; nothing but the router and the
/// widget tests should ever import it.
///
/// The figures are the design's own worked example, kept exactly rather than
/// invented, so a screenshot of the build can be compared against the canvas:
/// a P120 ride → 8% commission P9.60 → 14% VAT P1.34 → P10.94 deducted, and
/// the driver keeps the full P120 in hand.
library;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../ui/components/category_tile.dart';
import '../ui/components/ledger_entry.dart';
import '../ui/components/status_chip.dart';
import '../ui/screens/consumer/category_browse_screen.dart';
import '../ui/screens/consumer/home_screen.dart';
import '../ui/screens/consumer/listing_detail_screen.dart';
import '../ui/screens/provider/dashboard_screen.dart';
import '../ui/screens/provider/wallet_screen.dart';

abstract final class Demo {
  static Decimal _d(String v) => Decimal.parse(v);

  static final home = HomeData(
    city: 'Gaborone',
    customerName: null,
    driversNearby: 62,
    // Verbatim from the design's `CATS` array. Note the shape of the thin
    // ones: "New in Gaborone · 2 providers", not "2 nearby". The count is
    // never hidden, but it is framed as a young category rather than a
    // failing one — that is the difference between honest and discouraging.
    supplyLabels: const {
      'rides': '62 drivers nearby',
      'movers': '21 trucks in Gaborone',
      'rentals': '140 rooms listed',
      'beauty': 'New in Gaborone · 4 providers',
      'plumbing': 'New in Gaborone · 6 plumbers',
      'electrical': 'New in Gaborone · 4 electricians',
      'tiling': 'New in Gaborone · 3 tilers',
      'catering': 'New in Gaborone · 3 home cooks',
      'hire': 'New in Gaborone · 2 providers',
    },
    nearYou: const [
      NearbyItem(
        category: Categories.rentals,
        title: 'Room · Block 8',
        price: 'P1 200/mo',
      ),
      NearbyItem(
        category: Categories.beauty,
        title: 'Braids · Mobile',
        price: 'From P150',
      ),
      NearbyItem(
        category: Categories.movers,
        title: 'Bakkie · 1 tonne',
        price: 'From P350',
      ),
    ],
    // `supply` from the design's `CATS` array, verbatim. Six of nine are thin
    // at launch — that is the design condition, not an edge case: the seeding
    // plan goes deep rather than wide, so two or three categories look healthy
    // and the rest look new, for months.
    standings: const {
      'rides': SupplyStanding.ok,
      'movers': SupplyStanding.ok,
      'rentals': SupplyStanding.ok,
      'beauty': SupplyStanding.thin,
      'plumbing': SupplyStanding.thin,
      'electrical': SupplyStanding.thin,
      'tiling': SupplyStanding.thin,
      'catering': SupplyStanding.thin,
      'hire': SupplyStanding.thin,
    },
  );

  /// Browse for one category. Keyed by category so the route parameter can
  /// resolve it; unknown keys fall back to plumbing's shape with an empty list,
  /// which is what a category with no providers actually looks like.
  static CategoryBrowseData browse(String key) {
    final category = Categories.byKey(key) ?? Categories.plumbing;
    return CategoryBrowseData(
      category: category,
      city: 'Gaborone',
      standing: home.standings[category.key] ?? SupplyStanding.thin,
      listings: category.key == Categories.plumbing.key
          ? [
              Listing(
                id: 'L-4417',
                name: 'Kabelo’s Plumbing & Repairs',
                tag: 'Block 8, Gaborone',
                fromPrice: _d('150.00'),
                direction: ServiceDirection.comesToYou,
                verified: true,
                // Zero jobs and still listed. That is the whole point: a new
                // provider has to be bookable or the ratings problem kills
                // supply before it starts.
                isNew: true,
              ),
              Listing(
                id: 'L-4402',
                name: 'Tumelo Pipeworks',
                tag: 'Mobile · same day',
                fromPrice: _d('220.00'),
                direction: ServiceDirection.comesToYou,
                verified: true,
                isNew: false,
              ),
              Listing(
                id: 'L-4390',
                name: 'Gaborone Drain Care',
                tag: 'Workshop · Gaborone West',
                fromPrice: _d('180.00'),
                direction: ServiceDirection.youGoToThem,
                verified: true,
                isNew: false,
              ),
            ]
          : const [],
    );
  }

  /// The booking the status screen renders. One provider, one category; the
  /// *state* is what varies, and it is picked by the route so all eleven are
  /// reachable without a backend — the design's own artboard works the same
  /// way, with a row of state tabs above the phone.
  static const bookingProviderName = "Kabelo’s Plumbing & Repairs";
  static const bookingProviderFirstName = 'Kabelo';
  static const bookingCategory = Categories.plumbing;

  static final listing = ListingDetailData(
    name: 'Kabelo’s Plumbing & Repairs',
    category: Categories.plumbing,
    location: 'Block 8, Gaborone',
    direction: ServiceDirection.comesToYou,
    startingFrom: _d('150.00'),
    priceNote: 'Call-out fee. The quote comes back on your request.',
    verified: true,
    completedJobs: 0,
    // Null, not 0.0 and not 5.0. A provider with no jobs has no rating, and
    // inventing one is exactly the failure this product is built against.
    rating: null,
  );

  static final dashboard = DashboardData(
    providerName: 'Kagiso',
    balance: _d('340.00'),
    canAcceptWork: true,
    newRequests: 2,
    oldestRequestExpiry: '3h 20m',
    jobsThisMonth: 4,
    jobsDelta: 2,
    week: const [1, 0, 2, 1, 0, 0, 0],
    todayIndex: 2,
    feesThisMonth: _d('48.94'),
    categories: const [
      CategoryStanding(
        category: Categories.movers,
        detail: '3 listings live',
        label: 'Approved',
        tone: ChipTone.verified,
      ),
      CategoryStanding(
        category: Categories.rentals,
        detail: 'Submitted 2 days ago',
        label: 'Pending',
        tone: ChipTone.pending,
      ),
    ],
  );

  static final wallet = WalletData(
    balance: _d('340.00'),
    activity: [
      // No amount. A reversal under review has not moved the balance, and an
      // amount here would imply it had.
      const LedgerRow(
        icon: Icons.hourglass_top,
        title: 'Reversal under review',
        subtitle: 'Ride #4462',
        pending: true,
      ),
      LedgerRow(
        icon: Icons.directions_car,
        title: 'Commission · ride #4471',
        subtitle: 'Today 09:12 · 8% of P120',
        amount: _d('-9.60'),
        vat: VatLine.charged(_d('-1.34'), ofFee: 'P9.60'),
      ),
      // A top-up is not a fee, so it carries no VAT line.
      LedgerRow(
        icon: Icons.arrow_downward,
        title: 'Top-up · Orange Money',
        subtitle: 'Yesterday 18:40 · settled',
        amount: _d('200.00'),
      ),
      // A reversal mirrors the deduction line for line — fee back and VAT
      // back, same figures, opposite sign. Never one merged credit.
      LedgerRow(
        icon: Icons.undo,
        title: 'Commission reversed',
        subtitle: 'Job #1264 · cancellation confirmed',
        amount: _d('24.00'),
        vat: VatLine.reversed(_d('3.36')),
      ),
    ],
  );
}
