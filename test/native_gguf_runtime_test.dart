import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:border_safety_alert/services/native_gguf_runtime_io.dart';

void main() {
  group('Native GGUF Runtime - Verification & Header Inspection', () {
    late Directory tempDir;
    late NativeGgufRuntimeIo runtime;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('gguf_test_');
      runtime = NativeGgufRuntimeIo();
    });

    tearDown(() async {
      runtime.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Non-existent model file returns invalid with descriptive error', () async {
      final fakePath = '${tempDir.path}/non_existent.gguf';
      final metadata = await runtime.verifyModelFile(fakePath);

      expect(metadata.isValid, isFalse);
      expect(metadata.errorReason, contains('File does not exist'));
      expect(metadata.fileSizeBytes, equals(0));
    });

    test('Truncated file smaller than minimum header size is rejected', () async {
      final smallFile = File('${tempDir.path}/small.gguf');
      await smallFile.writeAsBytes([0x47, 0x47, 0x55, 0x46]); // 4 bytes only

      final metadata = await runtime.verifyModelFile(smallFile.path);

      expect(metadata.isValid, isFalse);
      expect(metadata.errorReason, contains('File smaller than minimum GGUF header size'));
      expect(metadata.fileSizeBytes, equals(4));
    });

    test('Invalid header magic is detected and rejected', () async {
      final corruptFile = File('${tempDir.path}/corrupt.gguf');
      final bytes = Uint8List(32);
      // Fill with non-GGUF bytes
      bytes.setRange(0, 4, [0x42, 0x41, 0x44, 0x21]); // "BAD!"
      await corruptFile.writeAsBytes(bytes);

      final metadata = await runtime.verifyModelFile(corruptFile.path);

      expect(metadata.isValid, isFalse);
      expect(metadata.errorReason, contains('Invalid header magic'));
      expect(metadata.magic, equals('BAD!'));
    });

    test('Valid GGUF binary header parses version, tensor count and calculates SHA-256', () async {
      final validFile = File('${tempDir.path}/valid_test.gguf');
      
      // Construct 32-byte binary:
      // [0..3]: 'GGUF' (0x47, 0x47, 0x55, 0x46)
      // [4..7]: uint32 version = 3
      // [8..15]: uint64 tensorCount = 28
      // [16..23]: uint64 metadataKvCount = 12
      // [24..31]: arbitrary payload
      final byteData = ByteData(32);
      // GGUF
      byteData.setUint8(0, 0x47);
      byteData.setUint8(1, 0x47);
      byteData.setUint8(2, 0x55);
      byteData.setUint8(3, 0x46);
      // Version 3
      byteData.setUint32(4, 3, Endian.little);
      // Tensors 28
      byteData.setUint64(8, 28, Endian.little);
      // Metadata KV 12
      byteData.setUint64(16, 12, Endian.little);

      await validFile.writeAsBytes(byteData.buffer.asUint8List());

      final metadata = await runtime.verifyModelFile(validFile.path);

      expect(metadata.isValid, isTrue);
      expect(metadata.magic, equals('GGUF'));
      expect(metadata.version, equals(3));
      expect(metadata.tensorCount, equals(28));
      expect(metadata.metadataKvCount, equals(12));
      expect(metadata.fileSizeBytes, equals(32));
      expect(metadata.sha256Hash, isNotEmpty);
      expect(metadata.errorReason, isNull);

      // Verify SHA-256 matching succeeds
      final verifiedWithHash = await runtime.verifyModelFile(
        validFile.path,
        expectedSha256: metadata.sha256Hash,
      );
      expect(verifiedWithHash.isValid, isTrue);

      // Verify SHA-256 mismatch is rejected
      final mismatch = await runtime.verifyModelFile(
        validFile.path,
        expectedSha256: '0000000000000000000000000000000000000000000000000000000000000000',
      );
      expect(mismatch.isValid, isFalse);
      expect(mismatch.errorReason, contains('SHA-256 hash mismatch'));
    });

    test('Disposing runtime resets active state safely', () {
      runtime.dispose();
      expect(runtime.isAvailable, isFalse);
    });
  });
}
