/// Source files are UTF-8, and stay UTF-8.
///
/// This exists because of a real defect: a PowerShell rename read a Dart file
/// with the ANSI default and rewrote it as UTF-8, turning the middot in
/// "Verified . Plumbing" into a two-character mess. It compiled, every test passed, and it was
/// only caught by looking at a screenshot — which is a bad way to find an
/// encoding bug, because most damaged strings never appear in one.
///
/// The copy on these screens is quoted verbatim from the design and carries
/// money rules, so a silently mangled character is a changed promise. Cheap
/// check, whole class of bug.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// What UTF-8 looks like after a round trip through a single-byte codepage.
///
/// `U+00C2` precedes every Latin-1 supplement character - the middot, the
/// degree sign, a non-breaking space. `U+00E2 U+20AC` precedes the punctuation
/// this design actually uses: the em dash and both curly quotes.
///
/// Built from escapes rather than written out, because a file that contains
/// the mangled sequences would match its own pattern and fail on itself.
final _mojibake = RegExp('\u00C2[\u0080-\u00BF]|\u00E2\u20AC');

void main() {
  test('no source file has been mangled by a non-UTF-8 rewrite', () {
    final offenders = <String>[];

    for (final dir in const ['lib', 'test']) {
      for (final entity in Directory(dir).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;

        final bytes = entity.readAsBytesSync();

        // A BOM is the other symptom of the same rewrite. Dart does not need
        // one and some tools choke on it.
        expect(
          bytes.length >= 3 &&
              bytes[0] == 0xEF &&
              bytes[1] == 0xBB &&
              bytes[2] == 0xBF,
          isFalse,
          reason: '${entity.path} starts with a UTF-8 BOM',
        );

        // Must decode as strict UTF-8 in the first place.
        late String text;
        try {
          text = const Utf8Decoder(allowMalformed: false).convert(bytes);
        } on FormatException {
          offenders.add('${entity.path} (not valid UTF-8)');
          continue;
        }

        if (_mojibake.hasMatch(text)) {
          final hit = _mojibake.firstMatch(text)!;
          final from = (hit.start - 40).clamp(0, text.length);
          final to = (hit.end + 40).clamp(0, text.length);
          offenders.add(
            '${entity.path}: ...${text.substring(from, to).trim()}...',
          );
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'these files look double-encoded. On Windows, read and write source '
          'with an explicit UTF-8 encoding — PowerShell\'s Get-Content /'
          'Set-Content default to the system codepage and will do this again.',
    );
  });
}
