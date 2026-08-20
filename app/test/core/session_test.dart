import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ipelege/core/phone.dart';
import 'package:ipelege/core/session.dart';

/// The entry rules, tested where they live rather than through the screens.
/// Each one is a rule the design states in prose and the type is supposed to
/// make impossible to get wrong.
void main() {
  Session read(ProviderContainer c) => c.read(sessionProvider);
  SessionController act(ProviderContainer c) =>
      c.read(sessionProvider.notifier);

  ProviderContainer container() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  group('a visitor', () {
    test('starts with no account and cannot book', () {
      final c = container();
      expect(read(c).stage, SessionStage.none);
      expect(read(c).canBook, isFalse);
    });
  });

  group('every fresh login goes through OTP', () {
    test('requesting a code does not sign anyone in', () {
      final c = container();
      act(c).requestCode(name: 'Kabo Mothibi', phone: '+267 71 234 567');

      expect(read(c).stage, SessionStage.confirmingNumber);
      expect(
        read(c).canBook,
        isFalse,
        reason: 'a number typed in is not an authenticated session',
      );
    });

    test('a first account still has to consent after the code', () {
      final c = container();
      act(c)
        ..requestCode(name: 'Kabo Mothibi', phone: '+267 71 234 567')
        ..confirmCode();

      expect(read(c).stage, SessionStage.needsConsent);
      expect(read(c).canBook, isFalse);

      act(c).agree();
      expect(read(c).stage, SessionStage.active);
      expect(read(c).canBook, isTrue);
    });

    test('a returning user on the current version goes straight in', () {
      final c = container();
      act(c)
        ..requestCode(name: 'Kabo Mothibi', phone: '+267 71 234 567')
        ..confirmCode()
        ..agree();

      // Second visit: the code is asked for again, because there is no
      // password to skip it with.
      act(c).requestCode(phone: '+267 71 234 567');
      expect(read(c).canBook, isFalse);

      act(c).confirmCode();
      expect(
        read(c).stage,
        SessionStage.active,
        reason: 'consent already current — do not ask twice',
      );
    });
  });

  group('consent is versioned, not a boolean', () {
    test('a superseded version cannot act', () {
      final c = container();
      act(c)
        ..requestCode(name: 'Kabo Mothibi', phone: '+267 71 234 567')
        ..confirmCode()
        ..agree();
      expect(read(c).canBook, isTrue);

      // What a version bump looks like from the session's side.
      const stale = Session(
        stage: SessionStage.active,
        name: 'Kabo Mothibi',
        consentVersion: '2.0',
      );
      expect(
        stale.canBook,
        isFalse,
        reason:
            'signed in on a superseded version is not a usable session — '
            're-consent has to be forced before anything else proceeds',
      );
    });

    test('each optional channel is recorded separately', () {
      final c = container();
      act(c)
        ..requestCode(name: 'Kabo Mothibi', phone: '+267 71 234 567')
        ..confirmCode()
        ..agree(channels: {ConsentChannel.sms});

      expect(read(c).channels, {ConsentChannel.sms});
      expect(read(c).channels.contains(ConsentChannel.whatsApp), isFalse);
    });
  });

  group('biometry unlocks, it never authenticates', () {
    test('only an active session can lock', () {
      final c = container();
      act(c).lock();
      expect(
        read(c).stage,
        SessionStage.none,
        reason: 'a visitor has nothing to unlock',
      );
    });

    test('unlocking reopens the same session, it does not create one', () {
      final c = container();
      act(c)
        ..requestCode(name: 'Kabo Mothibi', phone: '+267 71 234 567')
        ..confirmCode()
        ..agree()
        ..lock();

      expect(read(c).stage, SessionStage.locked);
      expect(read(c).canBook, isFalse);

      act(c).unlock();
      expect(read(c).stage, SessionStage.active);
      expect(read(c).name, 'Kabo Mothibi');
    });

    test('signing out leaves nothing behind — the next entry is a full OTP',
        () {
      final c = container();
      act(c)
        ..requestCode(name: 'Kabo Mothibi', phone: '+267 71 234 567')
        ..confirmCode()
        ..agree()
        ..signOut();

      expect(read(c).stage, SessionStage.none);
      expect(read(c).name, isNull);
      expect(read(c).consentVersion, isNull);
    });
  });

  group('initials', () {
    test('two names give two letters', () {
      expect(const Session(name: 'Kabo Mothibi').initials, 'KM');
    });

    test('one name gives one', () {
      expect(const Session(name: 'Kabo').initials, 'K');
    });

    test('no name gives nothing rather than a stray letter', () {
      expect(const Session().initials, '');
    });
  });

  group('phone numbers', () {
    test('accepts the shapes a person actually types', () {
      for (final input in const [
        '+267 71 234 567',
        '26771234567',
        '71234567',
        '71 234 567',
      ]) {
        expect(Phone.isPlausible(input), isTrue, reason: input);
      }
    });

    test('rejects what cannot receive a code', () {
      for (final input in const ['', '7123', '61234567', 'not a number']) {
        expect(Phone.isPlausible(input), isFalse, reason: input);
      }
    });

    test('normalises to one display form', () {
      expect(Phone.normalise('71234567'), '+267 71 234 567');
      expect(Phone.normalise('26771234567'), '+267 71 234 567');
    });

    test('leaves an unparseable number alone rather than mangling it', () {
      expect(Phone.normalise('61234567'), '61234567');
    });
  });
}
