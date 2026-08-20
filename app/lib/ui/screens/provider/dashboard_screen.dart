/// B1 · Provider dashboard.
///
/// The screen the design rebuilt first when it moved to the new surface, and
/// the one that carries the most rules:
///
/// - the **balance is a meter, not an account** — it sits on the hero with its
///   non-redeemable status stated beside it, and there is no withdraw control
///   anywhere on this screen because there is nothing to withdraw;
/// - **the month is a chart**, not the string "4 jobs";
/// - **"provider" is never a single status** — My categories shows the matrix,
///   because one account can hold approved, pending, more-info, rejected and
///   not-applied simultaneously and that is the normal case after a few
///   months, not an edge case.
///
/// See docs/design-system.md#surface-treatment and docs/wallet.md.
library;

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../../routing/nav_tabs.dart';
import '../../../routing/navigation.dart';
import '../../../routing/routes.dart';
import '../../../theme/dimens.dart';
import '../../../theme/tokens.dart';
import '../../components/money_text.dart';
import '../../components/status_chip.dart';
import '../../components/surface.dart';
import '../../components/week_chart.dart';

/// What one category application looks like on this screen.
@immutable
class CategoryStanding {
  const CategoryStanding({
    required this.category,
    required this.detail,
    required this.label,
    required this.tone,
  });

  final CategoryToken category;

  /// `3 listings live`, `Submitted 2 days ago`.
  final String detail;

  /// `Approved`, `Pending`, `Needs attention`.
  final String label;
  final ChipTone tone;
}

@immutable
class DashboardData {
  const DashboardData({
    required this.providerName,
    required this.balance,
    required this.canAcceptWork,
    required this.newRequests,
    required this.oldestRequestExpiry,
    required this.jobsThisMonth,
    required this.jobsDelta,
    required this.week,
    required this.todayIndex,
    required this.feesThisMonth,
    required this.categories,
  });

  final String providerName;
  final Decimal balance;

  /// Derived from the balance against the commission on a typical job — the
  /// provider needs to know they can accept, not do the arithmetic.
  final bool canAcceptWork;

  final int newRequests;

  /// `3h 20m`. A request that expires unanswered is supply lost silently, so
  /// the countdown is on the dashboard rather than only in the inbox.
  final String oldestRequestExpiry;

  final int jobsThisMonth;
  final int jobsDelta;
  final List<int> week;
  final int todayIndex;
  final Decimal feesThisMonth;
  final List<CategoryStanding> categories;
}

class ProviderDashboardScreen extends StatelessWidget {
  const ProviderDashboardScreen({super.key, required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Space.gutter,
            Space.x4,
            Space.gutter,
            Space.x8,
          ),
          children: [
            _Greeting(name: data.providerName),
            const SizedBox(height: Space.x4),
            _BalanceHero(data: data),
            const SizedBox(height: Space.x3),
            if (data.newRequests > 0) ...[
              _RequestsCard(data: data),
              const SizedBox(height: Space.x5),
            ],
            _SectionLabel('This month'),
            const SizedBox(height: Space.x2),
            _MonthCard(data: data),
            const SizedBox(height: Space.x5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _SectionLabel('My categories'),
                TextButton(
                  onPressed: () => context.pushScreen(Routes.listings),
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: Space.x1),
            // Never one status: each category carries its own, because they
            // are separate decisions on separate requirement sets.
            for (final standing in data.categories) ...[
              _CategoryRow(standing: standing),
              const SizedBox(height: Space.x2),
            ],
            const SizedBox(height: Space.x4),
            Text(
              'Ipelege never handles your customer’s payment. They pay you '
              'directly, in cash or by mobile money.',
              style: text.bodySmall?.copyWith(color: palette.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
        .join();

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.navPillBg,
            borderRadius: Radii.iconTileAll,
          ),
          child: Text(
            initials,
            style: text.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: palette.accentText,
            ),
          ),
        ),
        const SizedBox(width: Space.x3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Singular and personal: the product speaks to one person.
              Text('Dumela, $name', style: text.titleLarge),
              Text(
                'Service provider',
                style: text.bodySmall?.copyWith(color: palette.textMuted),
              ),
            ],
          ),
        ),
        // The mode switch lives in the provider header. It has to be reachable
        // from here, not buried in Account: switching is navigation, not
        // authentication, and a provider who came in to check a booking they
        // made as a customer should not have to hunt for the way back.
        IconButton(
          onPressed: () => context.switchMode(AppMode.consumer),
          icon: const Icon(Icons.swap_horiz),
          tooltip: 'Switch to customer',
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Notifications',
        ),
      ],
    );
  }
}

/// The balance, on the hero, with its two actions.
///
/// There is no withdraw button and no "available balance" framing. The
/// disclaimer lives on the card itself rather than in a footnote — that is the
/// whole basis on which the design defends calling it a wallet balance.
class _BalanceHero extends StatelessWidget {
  const _BalanceHero({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return HeroSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  'WALLET BALANCE',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelSmall?.copyWith(
                    fontSize: 10,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                    color: Brand.white.withValues(alpha: 0.72),
                  ),
                ),
              ),
              const SizedBox(width: Space.x2),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.x2,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Brand.white.withValues(alpha: 0.18),
                    borderRadius: Radii.pillAll,
                  ),
                  child: Text(
                    data.canAcceptWork ? 'Can accept work' : 'Top up to accept',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelSmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Brand.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.x2),
          MoneyText(data.balance, size: MoneySize.large, onDarkSurface: true),
          const SizedBox(height: Space.x4),
          Row(
            children: [
              Expanded(
                child: _HeroAction(
                  icon: Icons.add,
                  label: 'Top up',
                  filled: true,
                  onTap: () => context.pushScreen(Routes.wallet),
                ),
              ),
              const SizedBox(width: Space.x2),
              Expanded(
                child: _HeroAction(
                  icon: Icons.receipt_long,
                  label: 'Ledger',
                  filled: false,
                  onTap: () => context.pushScreen(Routes.wallet),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroAction extends StatelessWidget {
  const _HeroAction({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Material(
      color: filled ? Brand.white : Brand.white.withValues(alpha: 0.16),
      borderRadius: Radii.buttonAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.buttonAll,
        child: Container(
          height: Touch.min,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: filled ? Brand.deep : Brand.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: text.labelLarge?.copyWith(
                  fontSize: 14,
                  color: filled ? Brand.deep : Brand.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestsCard extends StatelessWidget {
  const _RequestsCard({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;

    return AppCard(
      onTap: () => context.goReplacing(Routes.requests),
      child: Row(
        children: [
          IconPlate(
            icon: Icons.local_shipping,
            plate: palette.navPillBg,
            ink: palette.accentText,
          ),
          const SizedBox(width: Space.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data.newRequests} new '
                  '${data.newRequests == 1 ? 'request' : 'requests'}',
                  style: text.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  'Oldest expires in ${data.oldestRequestExpiry}',
                  style: text.bodySmall?.copyWith(color: palette.textMuted),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: palette.textFaint),
        ],
      ),
    );
  }
}

class _MonthCard extends StatelessWidget {
  const _MonthCard({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return HeroSurface(
      padding: const EdgeInsets.all(Space.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${data.jobsThisMonth}',
                style: text.displaySmall?.copyWith(color: Brand.white),
              ),
              const SizedBox(width: Space.x2),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'jobs done',
                  style: text.bodySmall?.copyWith(
                    color: Brand.white.withValues(alpha: 0.78),
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: DeltaPill(delta: data.jobsDelta),
              ),
            ],
          ),
          const SizedBox(height: Space.x3),
          WeekChart(values: data.week, todayIndex: data.todayIndex),
          const SizedBox(height: Space.x4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Fees paid this month',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                    color: Brand.white.withValues(alpha: 0.78),
                  ),
                ),
              ),
              const SizedBox(width: Space.x2),
              MoneyText(data.feesThisMonth, onDarkSurface: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.standing});

  final CategoryStanding standing;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final brightness = Theme.of(context).brightness;

    return AppRow(
      onTap: () {},
      child: Row(
        children: [
          IconPlate.category(standing.category, brightness),
          const SizedBox(width: Space.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  standing.category.label,
                  style: text.titleMedium?.copyWith(fontSize: 14.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  standing.detail,
                  style: text.labelSmall?.copyWith(
                    fontSize: 11.5,
                    color: palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Space.x2),
          StatusChip(label: standing.label, tone: standing.tone),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontSize: 10.5,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w700,
        color: context.palette.textMuted,
      ),
    );
  }
}
