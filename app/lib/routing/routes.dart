/// Every path in the app, in one place.
///
/// Screens never write a path literal. A route that is not named here does
/// not exist.
///
/// See docs/design-system.md#navigation.
library;

abstract final class Routes {
  // Consumer tabs.
  static const home = '/home';
  static const bookings = '/bookings';
  static const messages = '/messages';
  static const account = '/account';

  // Consumer stacks. Each pushes onto the tab it belongs to.
  static const category = '/home/category/:key';
  static const listing = '/home/listing/:id';
  static const booking = '/bookings/:id';

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
  static String bookingOf(String id) => '/bookings/$id';
}
