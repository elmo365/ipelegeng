/// Listing detail.
///
/// The screen carries the product's sharpest trust decision: **verification
/// and rating are separate signals.** Lynk's shutdown traced partly to ratings
/// working too well — new providers with zero reviews never got a first
/// booking. So a provider with no completed jobs shows the verified badge (a
/// compliance fact, present from day one) and says plainly that there is no
/// review history yet. It never fabricates a rating, and it never hides the
/// zero.
///
/// The other rule: **the app never implies it took the customer's money.** The
/// price is a starting figure, the quote comes back on the request, and
/// payment happens directly between the two people.
///
/// See docs/user-model.md, docs/booking.md and docs/design-deltas.md.
library;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/loop_prompt.dart';
import '../../../routing/navigation.dart';
import '../../../routing/routes.dart';
import '../../../theme/dimens.dart';
import '../../../theme/tokens.dart';
import '../../components/info_note.dart';
import '../../components/money_text.dart';
import '../../components/status_chip.dart';
import '../../components/surface.dart';
import '../entry/auth_gate.dart';
import 'category_browse_screen.dart';
import 'loop_handoff.dart';

@immutable
class ListingDetailData {
  const ListingDetailData({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    required this.direction,
    required this.startingFrom,
    required this.priceNote,
    required this.verified,
    required this.completedJobs,
    this.rating,
  });

  /// `L-4417`. The booking request hangs off this listing's path, so the
  /// screen has to know which listing it is rather than only what it says.
  final String id;

  final String name;
  final CategoryToken category;

  /// `Block 8, Gaborone`.
  final String location;

  final ServiceDirection direction;
  final Decimal startingFrom;

  /// `Call-out fee. The quote comes back on your request.` The basis of the
  /// figure, because a bare "from" price is what generates disputes later.
  final String priceNote;

  final bool verified;
  final int completedJobs;

  /// Null until there are completed jobs to rate. Never synthesised.
  final double? rating;
}

class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({super.key, required this.data, this.loopPrompt});

  final ListingDetailData data;

  /// Stage 7's handoff, already through [LoopPrompts.decide] — a pair here
  /// means the four suppression rules ran and none fired.
  ///
  /// It is offered **after** the enquiry, never beside it: a truck suggested
  /// next to the enquiry button competes with the thing the customer came for.
  /// Null on a category that books, because a booking has its own next step.
  final LoopPair? loopPrompt;

  /// "Kabelo's Plumbing & Repairs" → "Kabelo". The gate says *who* needs the
  /// number, and a trading name is not a person.
  static String firstNameOf(String tradingName) {
    final first = tradingName.trim().split(RegExp(r'\s+')).first;
    return first.replaceAll(RegExp(r"['’]s$"), '');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: Space.x8),
          children: [
            _PhotoBand(category: data.category),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
              child: Transform.translate(
                // The identity card overlaps the photo band, so the person
                // reads before the picture does.
                offset: const Offset(0, -28),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconPlate.category(
                            data.category,
                            brightness,
                            size: 42,
                            iconSize: 22,
                          ),
                          const SizedBox(width: Space.x3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data.name, style: text.titleLarge),
                                const SizedBox(height: 2),
                                Text(
                                  '${data.category.label} · ${data.location}',
                                  style: text.bodySmall?.copyWith(
                                    color: palette.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Space.x3),
                      Wrap(
                        spacing: Space.x2,
                        runSpacing: Space.x2,
                        children: [
                          if (data.verified)
                            StatusChip.verified(data.category.label),
                          if (data.completedJobs == 0)
                            const StatusChip.newProvider(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The zero is stated, and what verification does and does
                  // not cover is stated with it. No fabricated rating.
                  if (!data.category.shape.books)
                    // A rental has no completions to count — the design is
                    // explicit that pay-per-listing means "no booking, no
                    // commission, no completion". A job count here would be a
                    // zero that can never become anything else.
                    const InfoNote(
                      body:
                          'Verification confirms the landlord owns this '
                          'property and that it has been inspected. Rooms are '
                          'not booked through Ipelege — you arrange the '
                          'viewing directly.',
                    )
                  else if (data.completedJobs == 0)
                    const InfoNote(
                      // "trade certification" was wrong for at least two of the
                      // nine: rentals is verified on proof of ownership and
                      // tiling on proof of past work, neither of which is a
                      // certificate. The requirement is per category — see
                      // docs/categories.md.
                      body:
                          '0 completed jobs yet. Verification confirms '
                          'identity and the documents this category requires, '
                          'independent of a review history.',
                    )
                  else
                    _Completed(jobs: data.completedJobs, rating: data.rating),
                  const SizedBox(height: Space.x5),
                  _Label('Service direction'),
                  const SizedBox(height: Space.x2),
                  AppRow(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Space.x4,
                      vertical: Space.x3,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          data.direction.icon,
                          size: 20,
                          color: palette.accentText,
                        ),
                        const SizedBox(width: Space.x3),
                        Text(
                          data.direction.label,
                          style: text.titleMedium?.copyWith(fontSize: 14.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Space.x5),
                  _Label('Starting from'),
                  const SizedBox(height: Space.x2),
                  MoneyText(data.startingFrom, size: MoneySize.large),
                  const SizedBox(height: Space.x1),
                  Text(
                    data.priceNote,
                    style: text.bodySmall?.copyWith(color: palette.textMuted),
                  ),
                  const SizedBox(height: Space.x6),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      // UC-4: browsing is free, and the wall is exactly here.
                      // A visitor who taps this is shown the gate naming the
                      // provider, then returned to this screen if they decline
                      // — they never lose their place for refusing.
                      onPressed: () async {
                        final allowed = await requireAccount(
                          context,
                          ref,
                          providerName: data.name,
                          providerFirstName: firstNameOf(data.name),
                        );
                        if (!allowed || !context.mounted) return;
                        // Rentals stop at the enquiry: there is no booking to
                        // request. What follows instead is stage 7's handoff —
                        // "a tenant who takes a room is a mover customer that
                        // same week" — offered after the enquiry, not beside
                        // it.
                        if (!data.category.shape.books) {
                          final pair = loopPrompt;
                          if (pair == null) return;
                          final taken = await offerLoopHandoff(
                            context,
                            pair: pair,
                          );
                          if (!taken || !context.mounted) return;
                          // A push, not a replace: they can still go back to
                          // the room they just enquired about.
                          context.pushScreen(Routes.categoryOf(pair.then.key));
                          return;
                        }
                        context.pushScreen(Routes.bookingRequestOf(data.id));
                      },
                      // Property rentals is pay-per-listing: there is no
                      // booking, no commission and no completion. The tenant
                      // enquires and leaves the app, so offering "Request
                      // booking" here would promise a flow that does not
                      // exist.
                      child: Text(
                        data.category.shape.books
                            ? 'Request booking'
                            : 'Enquire about this room',
                      ),
                    ),
                  ),
                  const SizedBox(height: Space.x3),
                  Text(
                    data.category.shape.books
                        ? 'You pay ${data.name} directly, in cash or by '
                              'mobile money. Ipelege never handles your '
                              'payment.'
                        : 'You arrange the viewing and the rent directly '
                              'with ${data.name}. Ipelege never handles your '
                              'payment.',
                    style: text.bodySmall?.copyWith(color: palette.textMuted),
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

/// The photo band.
///
/// Deliberately renders a labelled placeholder rather than waiting on an
/// image: no layout depends on an image loading before it is usable, because
/// this ships on 3G.
class _PhotoBand extends StatelessWidget {
  const _PhotoBand({required this.category});

  final CategoryToken category;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final text = Theme.of(context).textTheme;

    return Container(
      height: 160,
      color: category.plateOf(brightness),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.photo_camera_outlined,
            size: 26,
            color: category.inkOf(brightness),
          ),
          const SizedBox(height: 6),
          Text(
            'PROVIDER PHOTO',
            style: text.labelSmall?.copyWith(
              fontSize: 10,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
              color: category.inkOf(brightness),
            ),
          ),
        ],
      ),
    );
  }
}

class _Completed extends StatelessWidget {
  const _Completed({required this.jobs, this.rating});

  final int jobs;
  final double? rating;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return AppRow(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.x4,
        vertical: Space.x3,
      ),
      child: Row(
        children: [
          Icon(Icons.task_alt, size: 20, color: palette.creditColor),
          const SizedBox(width: Space.x3),
          Expanded(
            child: Text(
              '$jobs completed ${jobs == 1 ? 'job' : 'jobs'}',
              style: text.titleMedium?.copyWith(fontSize: 14.5),
            ),
          ),
          // A rating exists only once there are jobs behind it.
          if (rating != null) ...[
            Icon(Icons.star, size: 17, color: Status.warning),
            const SizedBox(width: 4),
            Text(
              rating!.toStringAsFixed(1),
              style: text.titleMedium?.copyWith(fontSize: 14.5),
            ),
          ],
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontSize: 10.5,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w700,
        color: context.palette.textMuted,
      ),
    );
  }
}
