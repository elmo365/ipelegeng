/// Botswana phone numbers, as the entry flow needs them.
///
/// Not a validator against a carrier — that is the backend's job and the OTP's
/// real one. This is only enough to stop the obvious mistake of sending a code
/// to something that cannot receive one, and to display a number the same way
/// everywhere: `+267 71 234 567`.
///
/// Botswana mobile numbers are 8 digits under country code 267, beginning 7.
library;

abstract final class Phone {
  static const countryCode = '+267';

  /// The design's own example, used as the field placeholder throughout.
  static const placeholder = '+267 71 234 567';

  /// Digits only, country code included.
  static String digitsOf(String input) =>
      input.replaceAll(RegExp(r'[^0-9]'), '');

  /// Good enough to send a code to: eight national digits starting with 7,
  /// with or without the country code.
  ///
  /// Deliberately permissive about spacing and the leading `+` — rejecting a
  /// number because of a space is the kind of validation that loses a user at
  /// the first screen.
  static bool isPlausible(String input) {
    var d = digitsOf(input);
    if (d.startsWith('267')) d = d.substring(3);
    return d.length == 8 && d.startsWith('7');
  }

  /// `+267 71 234 567`. Returns the input untouched if it is not plausible, so
  /// nothing silently mangles a number it did not understand.
  static String normalise(String input) {
    if (!isPlausible(input)) return input.trim();
    var d = digitsOf(input);
    if (d.startsWith('267')) d = d.substring(3);
    return '$countryCode ${d.substring(0, 2)} ${d.substring(2, 5)} '
        '${d.substring(5)}';
  }
}
