/// The driver half of Phase 0's gate.
///
/// `flutter test integration_test/...` runs the test on the device but throws
/// the screenshots away — the bytes only reach the host through a driver. So
/// the gate is run with `flutter drive`, and this writes each frame to
/// `build/gate/`.
///
/// See docs/build-order.md Phase 0 for the command and what the gate is for.
library;

import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? _]) async {
      final file = File('build/gate/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
      return true;
    },
  );
}
