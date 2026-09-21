import 'package:flutter_test/flutter_test.dart';
import 'package:border_safety_alert/services/model_manager.dart';

void main() {
  group('ModelManager Lifecycle & Diagnostics', () {
    late ModelManager manager;

    setUp(() {
      manager = ModelManager();
    });

    test('initial state is not installed or uninitialized', () {
      expect(manager.state, ModelState.notInstalled);
      expect(manager.isModelLoaded, isFalse);
    });

    test('installation workflow sets model ready', () async {
      await manager.installLocalModel(simulateFromLocalPack: true);
      expect(manager.state, ModelState.ready);
      expect(manager.isModelReady, isTrue);

      final verified = await manager.verifyChecksum();
      expect(verified, isTrue);
      expect(manager.state, ModelState.ready);
    });

    test('load and unload lifecycle', () async {
      await manager.installLocalModel(simulateFromLocalPack: true);
      await manager.loadModel();
      expect(manager.state, ModelState.loaded);
      expect(manager.isModelLoaded, isTrue);
      expect(manager.diagnostics.allocatedRamMb, greaterThan(0));

      await manager.unloadModel();
      expect(manager.state, ModelState.ready);
      expect(manager.isModelLoaded, isFalse);
    });

    test('deletion resets model to notInstalled', () async {
      await manager.installLocalModel(simulateFromLocalPack: true);
      expect(manager.isModelReady, isTrue);

      await manager.deleteModel();
      expect(manager.state, ModelState.notInstalled);
      expect(manager.isModelReady, isFalse);
    });
  });
}
