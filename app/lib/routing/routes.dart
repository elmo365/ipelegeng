/// Every path in the app, in one place.
///
/// Screens never write a path literal. A route that is not named here does
/// not exist.
///
/// See docs/design-system.md#navigation.
library;

abstract final class Routes {
  // Entry. These sit outside both shells: there is no tab bar until there is
  // an account, and the flow must not be escapable by tapping a tab.
  static const splash = '/welcome';
  static const register = '/register';
  static const signIn = '/sign-in';

  /// OTP. Reached from register and from sign in alike — both send a code,
  /// because there is no password to skip it with.
  static const verify = '/verify';

  /// Consent capture. A route rather than a step inside OTP, because a
  /// superseded version has to be able to send an already-signed-in user here
  /// on its own.
  static const consent = '/consent';

  /// Biometric unlock with the passcode fallback. Only reachable from a
  /// session that was already active on this device.
  static const unlock = '/unlock';

  /// The enrolment offer, made once after the first OTP. Distinct from
  /// [unlock]: this asks, that one uses.
  static const biometricEnrolment = '/biometric';

  static const location = '/location';

  /// Every entry route, for the guard in the router and the build-order test.
  static const entry = <String>[
    splash,
    register,
    signIn,
    verify,
    consent,
    unlock,
    biometricEnrolment,
    location,
  ];

  // Consumer tabs.
  static const home = '/home';
  static const bookings = '/bookings';
  static const messages = '/messages';
  static const account = '/account';

  // Consumer stacks. Each pushes onto the tab it belongs to.
  static const category = '/home/category/:key';
  static const listing = '/home/listing/:id';

  /// The request form, on the **Home** tab rather than Bookings, because until
  /// it is sent there is no booking — only a listing being looked at. Backing
  /// out returns to the listing, which is where the customer was.
  static const bookingRequest = '/home/listing/:id/request';

  static const booking = '/bookings/:id';

  /// Rate & review. A push onto the booking rather than a replace: the booking
  /// is already closed, and skipping has to leave the customer where they
  /// were.
  static const bookingRate = '/bookings/:id/rate';

  // Provider tabs.
  static const dashboard = '/provider';
  static const requests = '/provider/requests';
  static const listings = '/provider/listings';
  static const providerAccount = '/provider/account';

  /// The wallet is deliberately not a tab. A provider goes there to fix a
  /// problem, not to browse, so it hangs off the dashboard.
  static const wallet = '/provider/wallet';

  static String categoryOf(String key) => '/home/category/$key';
  static String listingOf(String id) => '/home/listing/$id';
  static String bookingRequestOf(String id) => '/home/listing/$id/request';
  static String bookingOf(String id) => '/bookings/$id';
  static String bookingRateOf(String id) => '/bookings/$id/rate';
}
