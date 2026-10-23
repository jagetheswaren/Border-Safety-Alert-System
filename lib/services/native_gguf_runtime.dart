import 'dart:async';
import 'native_gguf_runtime_stub.dart'
    if (dart.library.io) 'native_gguf_runtime_io.dart'
    if (dart.library.html) 'native_gguf_runtime_web.dart'
    if (dart.library.js_interop) 'native_gguf_runtime_web.dart';

/// Metadata describing a validated GGUF model file on disk.
class GgufMetadata {
  final String magic;
  final int version;
  final int tensorCount;
  final int metadataKvCount;
  final int fileSizeBytes;
  final String sha256Hash;
  final bool isValid;
  final String? errorReason;

  const GgufMetadata({
    required this.magic,
    required this.version,
    required this.tensorCount,
    required this.metadataKvCount,
    required this.fileSizeBytes,
    required this.sha256Hash,
    required this.isValid,
    this.errorReason,
  });
}

/// Architecture interface for the real on-device GGUF inference runtime (llama.cpp)
/// compiled via Android NDK / JNI / FFI on native targets.
abstract class NativeGgufRuntime {
  factory NativeGgufRuntime() => getNativeGgufRuntime();

  bool get isAvailable;
  String? get unavailableReason;

  /// Attempts to bind to the native llama.cpp shared library on the current platform.
  Future<bool> loadNativeLibrary();

  /// Verifies the binary structure of a GGUF model file on disk.
  Future<GgufMetadata> verifyModelFile(String path, {String? expectedSha256});

  /// Streams genuine tokens from the native GGUF model.
  Stream<String> generateTokens({
    required String modelPath,
    required String prompt,
    int maxTokens = 180,
    double temperature = 0.3,
  });

  void dispose();
}
