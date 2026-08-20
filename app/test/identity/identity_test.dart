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

/// SHA-256 of Flutter's stock `ic_launcher.png` at each density, recorded when
/// `docs/identity.md` was written. Replacing the icon changes these, which is
/// the point.
const _stockLauncherIcons = <String, String>{
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

  group('the launcher icon matches what identity.md declares', () {
    test('it is still Flutter stock artwork, and the doc says so', () {
      final replaced = <String>[];
      for (final entry in _stockLauncherIcons.entries) {
        final file = File('$_res/${entry.key}/ic_launcher.png');
        expect(file.existsSync(), isTrue, reason: '${entry.key} is missing');
        final digest = sha256.convert(file.readAsBytesSync()).toString();
        if (digest != entry.value) replaced.add(entry.key);
      }

      final docSaysMissing = File(
        _identityDoc,
      ).readAsStringSync().contains('is not in this repository');

      expect(
        replaced.isEmpty,
        docSaysMissing,
        reason: replaced.isEmpty
            ? 'docs/identity.md no longer says the artwork is missing, but the '
                  'launcher icon is still Flutter stock at every density'
            : 'the launcher icon changed at ${replaced.join(', ')} — the real '
                  'artwork has landed. Update docs/identity.md and these '
                  'hashes together.',
      );
    });
  });
}
