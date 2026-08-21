import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ipelege/core/booking.dart';
import 'package:ipelege/core/demo_data.dart';
import 'package:ipelege/core/loop_prompt.dart';
import 'package:ipelege/core/session.dart';
import 'package:ipelege/main.dart';
import 'package:ipelege/routing/app_router.dart';
import 'package:ipelege/routing/routes.dart';
import 'package:ipelege/theme/app_theme.dart';
import 'package:ipelege/theme/tokens.dart';
import 'package:ipelege/ui/components/loop_prompt_card.dart';
import 'package:ipelege/ui/screens/consumer/booking_status_screen.dart';
import 'package:ipelege/ui/screens/consumer/category_browse_screen.dart';

/// Stage 7 on screen — the two placements the journey map names.
///
/// The model's four suppression rules are tested in test/core/loop_prompt_test
/// .dart. What is tested here is that the prompt appears **where** the design
/// puts it and nowhere else: "the prompt belongs at the rental enquiry, and
/// again at a completed movers job".
void main() {
  Future<ProviderContainer> pumpAt(WidgetTester tester, String location) async {
    final container = ProviderContainer(
      overrides: [
        routerProvider.overrideWithValue(
          createRouter(initialLocation: location),
        ),
      ],
    );
    addTearDown(container.dispose);

    tester.view.physicalSize = const Size(1080, 3600);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const IpelegeApp(),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  /// A rentals listing, with an account, ready to enquire.
  Future<void> pumpRentalWithAccount(WidgetTester tester) async {
    final container = await pumpAt(tester, Routes.listingOf('R-2210'));
    container.read(sessionProvider.notifier)
      ..requestCode(phone: '71 234 567')
      ..agree();
    await tester.pumpAndSettle();
  }

  Future<void> pumpStatus(
    WidgetTester tester,
    BookingState state, {
    LoopPair? pair,
  }) async {
    tester.view.physicalSize = const Size(1080, 3600);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BookingStatusScreen(
          state: state,
          category: Categories.movers,
          providerName: 'Boiki Transport',
          providerFirstName: 'Boiki',
          loopPrompt: pair,
          onLoopPrompt: pair == null ? null : () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('the rental enquiry hands off to movers', () {
    testWidgets('enquiring offers the truck, in the design\'s own words', (
      tester,
    ) async {
      await pumpRentalWithAccount(tester);

      expect(find.text('Enquire about this room'), findsOneWidget);
      await tester.tap(find.text('Enquire about this room'));
      await tester.pumpAndSettle();

      expect(
        find.text('Moving in? Find a truck'),
        findsOneWidget,
        reason: 'the one finished line the design wrote for stage 7',
      );
    });

    testWidgets('it is offered after the enquiry, never beside it', (
      tester,
    ) async {
      await pumpRentalWithAccount(tester);

      // A truck alongside the enquiry button competes with the thing the
      // customer actually came for.
      expect(find.text('Moving in? Find a truck'), findsNothing);
    });

    testWidgets('Not now costs them nothing', (tester) async {
      await pumpRentalWithAccount(tester);
      await tester.tap(find.text('Enquire about this room'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      expect(find.text('Moving in? Find a truck'), findsNothing);
      expect(
        find.text('Enquire about this room'),
        findsOneWidget,
        reason:
            'declining took the room away, which is what a gate must not do',
      );
    });

    testWidgets('taking it lands on movers, with the room still behind', (
      tester,
    ) async {
      await pumpRentalWithAccount(tester);
      await tester.tap(find.text('Enquire about this room'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('See movers in Gaborone'));
      await tester.pumpAndSettle();

      final browse = tester.widget<CategoryBrowseScreen>(
        find.byType(CategoryBrowseScreen),
      );
      expect(browse.data.category, Categories.movers);
    });
  });

  group('a plumbing listing is not handed off anywhere', () {
    testWidgets('a category that books has its own next step', (tester) async {
      final container = await pumpAt(tester, Routes.listingOf('L-4417'));
      container.read(sessionProvider.notifier)
        ..requestCode(phone: '71 234 567')
        ..agree();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Request booking'));
      await tester.pumpAndSettle();

      expect(find.text('Moving in? Find a truck'), findsNothing);
    });
  });

  group('the completed booking carries the card, and only it', () {
    final pair = LoopPrompts.pairFor(
      Categories.movers,
      LoopMoment.bookingCompleted,
    )!;

    testWidgets('COMPLETED shows it', (tester) async {
      await pumpStatus(tester, BookingState.byKey('COMPLETED'), pair: pair);

      expect(find.byType(LoopPromptCard), findsOneWidget);
      expect(find.text(pair.headline), findsOneWidget);
    });

    testWidgets('a live job does not, even when handed a pair', (tester) async {
      // The screen gates on COMPLETED itself. A prompt surfacing while the
      // plumber is still under the sink is exactly the cross-sell banner
      // stage 7 exists not to be, and a caller bug must not be able to cause
      // it.
      for (final key in const [
        'REQUESTED',
        'IN_PROGRESS',
        'AWAITING_PAYMENT',
        'PENDING_CONFIRMATION',
      ]) {
        await pumpStatus(tester, BookingState.byKey(key), pair: pair);
        expect(
          find.byType(LoopPromptCard),
          findsNothing,
          reason: '$key is showing a cross-category prompt',
        );
      }
    });

    testWidgets('an ending does not either', (tester) async {
      for (final key in const ['DECLINED', 'CANCELLED', 'NO_SHOW']) {
        await pumpStatus(tester, BookingState.byKey(key), pair: pair);
        expect(
          find.byType(LoopPromptCard),
          findsNothing,
          reason: '$key is selling something after a job went wrong',
        );
      }
    });

    testWidgets('COMPLETED with nothing to offer shows nothing', (
      tester,
    ) async {
      await pumpStatus(tester, BookingState.byKey('COMPLETED'));
      expect(find.byType(LoopPromptCard), findsNothing);
    });
  });

  group('the demo data exercises the suppression rule for real', () {
    test('the rental handoff fires; the thin ones do not', () {
      // Six of nine categories are thin at launch by plan, so a loop prompt
      // that mostly declines to fire is the feature working. If this ever
      // flips to all four showing, the supply figures have been edited to
      // make a demo look good.
      expect(
        Demo.loopAfter(Categories.rentals, LoopMoment.rentalEnquiry).shows,
        isTrue,
      );

      for (final source in const [
        Categories.movers,
        Categories.catering,
        Categories.hire,
      ]) {
        final decision = Demo.loopAfter(source, LoopMoment.bookingCompleted);
        expect(
          decision.shows,
          isFalse,
          reason: '${source.key} prompts into a category the design calls thin',
        );
        expect(decision.reason, LoopSuppression.thinSupply);
      }
    });
  });
}
