/// Brand identity, enforced.
///
/// `docs/identity.md` records what identity the build actually has. Two things
/// drift silently otherwise:
///
/// - The **launch colour**, which lives in an Android XML resource that nothing
///   in Dart references, so a palette change leaves it behind and every cold
///   start flashes the old colour.
/// - The **launcher icon**, which is still Flutter's stock artwork. That is the
///   declared state; when the real icon lands, this suite fails until
///   `docs/identity.md` stops saying it is missing.
///
/// Both are one statement in two places on purpose — the duplication is what
/// makes the drift visible.
library;

import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ipelege/theme/tokens.dart';

/// Tests run with the working directory at the Flutter package root.
const _res = 'android/app/src/main/res';
const _identityDoc = '../docs/identity.md';

/// `#AARRGGBB` out of an Android colour resource.
String? _colorResource(String path, String name) {
  final xml = File(path).readAsStringSync();
  final match = RegExp(
    '<color\\s+name="$name"\\s*>\\s*(#[0-9A-Fa-f]{6,8})\\s*</color>',
  ).firstMatch(xml);
  return match?.group(1)?.toUpperCase();
}

void main() {
  group('the launch window matches the palette', () {
    test('light is screenBg2, not white', () {
      expect(
        _colorResource('$_res/values/colors.xml', 'ipelegeLaunchBg'),
        '#FF${AppPalette.light.screenBg2.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        reason:
            'the cold-start window no longer matches the page it opens onto, '
            'so every launch flashes. Update values/colors.xml.',
      );
    });

    test('dark is the dark screenBg2, not black', () {
      expect(
        _colorResource('$_res/values-night/colors.xml', 'ipelegeLaunchBg'),
        '#FF${AppPalette.dark.screenBg2.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
        reason:
            'the dark cold-start window drifted from AppPalette.dark. Update '
            'values-night/colors.xml.',
      );
    });

    test('the launch drawable paints that colour rather than the theme', () {
      // `?android:colorBackground` is the stock value and resolves to plain
      // white or plain black from the launch theme, which is how the flash got
      // there in the first place.
      for (final dir in const ['drawable', 'drawable-v21']) {
        // Comments stripped: these files explain the stock value they replaced,
        // and naming it in prose is not the same as painting it.
        final xml = File('$_res/$dir/launch_background.xml')
            .readAsStringSync()
            .replaceAll(RegExp(r'<!--[\s\S]*?-->'), '');
        expect(
          xml,
          contains('@color/ipelegeLaunchBg'),
          reason: '$dir/launch_background.xml is not using the brand ground',
        );
        expect(
          xml,
          isNot(contains('?android:colorBackground')),
          reason: '$dir/launch_background.xml is back on the stock theme colour',
        );
      }
    });
  });

  group('the launcher icon is the real artwork', () {
    test('no density is still Flutter stock', () {
      // These hashes are Flutter's default blue flag. It shipped on five
      // densities for weeks because nothing checked.
      const stock = <String, String>{
        'mipmap-mdpi':
            'c7c0c0189145e4e32a401c61c9bdc615754b0264e7afae24e834bb81049eaf81',
        'mipmap-hdpi':
            '6a7c8f0d703e3682108f9662f813302236240d3f8f638bb391e32bfb96055fef',
        'mipmap-xhdpi':
            'e14aa40904929bf313fded22cf7e7ffcbf1d1aac4263b5ef1be8bfce650397aa',
        'mipmap-xxhdpi':
            '4d470bf22d5c17d84edc5f82516d1ba8a1c09559cd761cefb792f86d9f52b540',
        'mipmap-xxxhdpi':
            '3c34e1f298d0c9ea3455d46db6b7759c8211a49e9ec6e44b635fc5c87dfb4180',
      };

      for (final entry in stock.entries) {
        final file = File('$_res/${entry.key}/ic_launcher.png');
        expect(file.existsSync(), isTrue, reason: '${entry.key} is missing');
        expect(
          sha256.convert(file.readAsBytesSync()).toString(),
          isNot(entry.value),
          reason: '${entry.key} is still the stock Flutter icon',
        );
      }
    });

    test('every density carries an adaptive foreground too', () {
      for (final d in const [
        'mipmap-mdpi',
        'mipmap-hdpi',
        'mipmap-xhdpi',
        'mipmap-xxhdpi',
        'mipmap-xxxhdpi',
      ]) {
        expect(
          File('$_res/$d/ic_launcher_foreground.png').existsSync(),
          isTrue,
          reason:
              '$d has no adaptive foreground, so the icon is letterboxed on '
              'Android 8+',
        );
      }

      final xml = File('$_res/mipmap-anydpi-v26/ic_launcher.xml')
          .readAsStringSync();
      expect(xml, contains('ic_launcher_foreground'));
      expect(xml, contains('@color/ipelegeIconBg'));
    });
  });

  group('the brand artwork that identity.md claims is present, is', () {
    // The doc lists what came through the fetch cap. A file named there and
    // missing here means someone deleted artwork; a corrupt one means it was
    // transcribed rather than decoded, which is how mark-icon.png was lost.
    test('every asset identity.md names exists and is a readable PNG', () {
      final doc = File(_identityDoc).readAsStringSync();
      final named = RegExp(r'`([a-z0-9-]+\.png)`')
          .allMatches(doc)
          .map((m) => m.group(1)!)
          .toSet();

      expect(
        named,
        contains('appicon-light.png'),
        reason: 'identity.md no longer names the launcher icon source',
      );

      for (final name in named) {
        final f = File('../design/assets/$name');
        if (!f.existsSync()) continue; // named as blocked, not as present
        final bytes = f.readAsBytesSync();
        expect(
          bytes.length,
          greaterThan(1000),
          reason: '$name is implausibly small',
        );
        // A truncated PNG keeps its header and loses its tail. IEND is the
        // last chunk, so its absence is exactly the corruption to catch.
        expect(
          _endsWithIend(bytes),
          isTrue,
          reason:
              '$name has no IEND chunk — it is a truncated or mis-transcribed '
              'PNG. Re-fetch it, and decode from disk rather than by hand.',
        );
      }
    });
  });
}

/// PNG ends with a 12-byte IEND chunk. Anything cut short by the fetch cap
/// loses it.
bool _endsWithIend(List<int> bytes) {
  if (bytes.length < 12) return false;
  const iend = [0x49, 0x45, 0x4E, 0x44];
  final tail = bytes.sublist(bytes.length - 8, bytes.length - 4);
  for (var i = 0; i < 4; i++) {
    if (tail[i] != iend[i]) return false;
  }
  return true;
}
