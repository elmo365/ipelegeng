/// The session survives a restart — and never survives it signed in.
///
/// "OTP on every fresh login; the session then persists until explicit logout."
/// The first half was always true. The second was not: every restart was a
/// fresh install, which session.dart recorded as "the safe direction to be
/// wrong in" rather than as right.
///
/// The load-bearing assertion in this file is the negative one. A restored
/// session that comes back [SessionStage.active] makes a stolen handset a
/// signed-in handset, and it is the one way this could be wrong that matters.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ipelege/core/session.dart';
import 'package:ipelege/core/session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// One store, two containers — a restart, without a process to restart.
  ProviderContainer containerOn(SessionStore store) {
    final container = ProviderContainer(
      overrides: [sessionStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Sign in fully, on one "launch".
  void signIn(ProviderContainer c, {bool enrolBiometrics = false}) {
    c.read(sessionProvider.notifier)
      ..requestCode(name: 'Kabo Mothibi', phone: '71 234 567')
      ..confirmCode()
      ..agree()
      ..answerBiometricOffer(enrol: enrolBiometrics);
  }

  group('a signed-in session comes back', () {
    test('the account is remembered', () {
      final store = InMemorySessionStore();
      signIn(containerOn(store), enrolBiometrics: true);

      final restored = containerOn(store).read(sessionProvider);

      expect(restored.name, 'Kabo Mothibi');
      expect(restored.phone, '71 234 567');
      expect(restored.consentVersion, Consent.current);
      expect(restored.biometricOffered, isTrue);
    });

    test('but never as active — this is the one that matters', () {
      final store = InMemorySessionStore();
      signIn(containerOn(store), enrolBiometrics: true);

      expect(
        containerOn(store).read(sessionProvider).stage,
        isNot(SessionStage.active),
        reason:
            'a reopened app is signed in without anyone proving anything, so '
            'a stolen handset is a signed-in handset',
      );
    });

    test('with biometry on it comes back locked', () {
      final store = InMemorySessionStore();
      signIn(containerOn(store), enrolBiometrics: true);

      final restored = containerOn(store).read(sessionProvider);
      expect(restored.stage, SessionStage.locked);
      expect(restored.canBook, isFalse);
    });

    test('with biometry off it comes back locked too, not through an OTP', () {
      // **Changed 2026-08-21.** This used to assert the opposite, because the
      // Security screen promised "an OTP every time the app is opened".
      //
      // The rule was dropped because the check does not do what it looks like
      // it does: an SMS code proves possession of the SIM, and on a reopen the
      // SIM is inside the handset the person is holding. Against a stolen
      // phone — the only threat a reopen check exists for — the code arrives
      // in the thief's hand with everything else, while costing a message on
      // every single launch.
      //
      // The device credential is the proof a thief does not have, so both
      // preferences now land on `locked`. What `biometricUnlock` still decides
      // is what `/unlock` offers first. See docs/design-deltas.md §20.
      final store = InMemorySessionStore();
      signIn(containerOn(store), enrolBiometrics: false);

      final restored = containerOn(store).read(sessionProvider);
      expect(restored.stage, SessionStage.locked);
      expect(restored.canBook, isFalse);
      expect(
        restored.phone,
        '71 234 567',
        reason: 'the number is still known — nothing about it was forgotten',
      );
    });

    test('the OTP is kept for what it actually proves', () {
      // Not a reopen: a *fresh* start on this device. Signing out is the user
      // saying they are done, and what comes back has to prove the number
      // again because nothing on the device vouches for them any more.
      final store = InMemorySessionStore();
      final container = containerOn(store);
      signIn(container, enrolBiometrics: true);
      container.read(sessionProvider.notifier).signOut();

      expect(containerOn(store).read(sessionProvider).stage, SessionStage.none);
    });

    test('unlocking a restored session gets all the way in', () {
      final store = InMemorySessionStore();
      signIn(containerOn(store), enrolBiometrics: true);

      final next = containerOn(store);
      next.read(sessionProvider.notifier).unlock();

      expect(next.read(sessionProvider).canBook, isTrue);
    });
  });

  group('what is deliberately not kept', () {
    test('a visitor leaves nothing behind', () {
      final store = InMemorySessionStore();
      containerOn(store);

      expect(store.read(), isNull);
      expect(containerOn(store).read(sessionProvider).stage, SessionStage.none);
    });

    test('a session mid-verification is not resumed mid-verification', () {
      // "Not kept: any OTP already sent." Resuming into a form whose code has
      // expired is worse than starting the round again.
      final store = InMemorySessionStore();
      containerOn(
        store,
      ).read(sessionProvider.notifier).requestCode(phone: '71 234 567');

      expect(store.read(), isNull);
      expect(containerOn(store).read(sessionProvider).stage, SessionStage.none);
    });

    test('the attempt count is not carried across a launch', () {
      final store = InMemorySessionStore();
      final first = containerOn(store);
      signIn(first, enrolBiometrics: true);
      // Burn an attempt on this launch.
      first.read(sessionProvider.notifier).requestCode(phone: '71 234 567');
      first
          .read(sessionProvider.notifier)
          .submitCode('', const DemoOtpVerifier());

      expect(
        containerOn(store).read(sessionProvider).codeAttemptsLeft,
        Session.maxCodeAttempts,
      );
    });

    test('signing out clears the record, not just the state', () {
      final store = InMemorySessionStore();
      final c = containerOn(store);
      signIn(c, enrolBiometrics: true);
      expect(store.read(), isNotNull);

      c.read(sessionProvider.notifier).signOut();

      expect(store.read(), isNull);
      expect(containerOn(store).read(sessionProvider).stage, SessionStage.none);
    });
  });

  group('a session that needs re-consent still comes back', () {
    test('it is remembered so the redirect can catch it', () {
      // The whole reason SessionController.restore and the consent-supersede
      // redirect exist: a version is superseded by shipping a new build, so
      // the case appears when yesterday's session is restored against today's
      // constant.
      final store = InMemorySessionStore()
        ..write(
          const Session(
            stage: SessionStage.needsConsent,
            phone: '71 234 567',
            consentVersion: '2.0',
          ),
        );

      final restored = containerOn(store).read(sessionProvider);
      expect(restored.stage, SessionStage.needsConsent);
      expect(restored.consentVersion, '2.0');
    });
  });

  group('the prefs-backed store round-trips', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('everything kept survives encoding', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = PrefsSessionStore(prefs);

      const written = Session(
        stage: SessionStage.active,
        name: 'Kabo Mothibi',
        phone: '71 234 567',
        consentVersion: Consent.current,
        channels: {ConsentChannel.sms, ConsentChannel.whatsApp},
        locationGranted: true,
        biometricOffered: true,
        biometricUnlock: true,
      );
      store.write(written);

      final read = store.read()!;
      expect(read.stage, SessionStage.active);
      expect(read.name, 'Kabo Mothibi');
      expect(read.phone, '71 234 567');
      expect(read.consentVersion, Consent.current);
      expect(read.channels, {ConsentChannel.sms, ConsentChannel.whatsApp});
      expect(read.locationGranted, isTrue);
      expect(read.biometricUnlock, isTrue);
    });

    test('a visitor is cleared rather than written', () async {
      final prefs = await SharedPreferences.getInstance();
      final store = PrefsSessionStore(prefs)
        ..write(
          const Session(
            stage: SessionStage.active,
            consentVersion: Consent.current,
          ),
        );
      expect(store.read(), isNotNull);

      store.write(const Session());
      expect(store.read(), isNull);
    });

    test('a corrupt record costs one sign-in, not the app', () async {
      SharedPreferences.setMockInitialValues({'session.v1': '{not json'});
      final prefs = await SharedPreferences.getInstance();

      expect(PrefsSessionStore(prefs).read(), isNull);
    });

    test('a record from an unknown future stage does not crash', () async {
      SharedPreferences.setMockInitialValues({
        'session.v1': '{"stage":"teleported","phone":"71 234 567"}',
      });
      final prefs = await SharedPreferences.getInstance();

      // Falls back to `none` — the safe direction to be wrong in.
      expect(PrefsSessionStore(prefs).read()!.stage, SessionStage.none);
    });
  });
}
