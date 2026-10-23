import 'dart:async';
import 'native_gguf_runtime.dart';

NativeGgufRuntime getNativeGgufRuntime() => NativeGgufRuntimeWeb();

class NativeGgufRuntimeWeb implements NativeGgufRuntime {
  @override
  bool get isAvailable => false;

  @override
  String? get unavailableReason =>
      'Native GGUF FFI runtime is not supported on the web platform.';

  @override
  Future<bool> loadNativeLibrary() async => false;

  @override
  Future<GgufMetadata> verifyModelFile(String path, {String? expectedSha256}) async {
    return const GgufMetadata(
      magic: '',
      version: 0,
      tensorCount: 0,
      metadataKvCount: 0,
      fileSizeBytes: 0,
      sha256Hash: '',
      isValid: false,
      errorReason: 'Web platform does not support local disk filesystem verification.',
    );
  }

  @override
  Stream<String> generateTokens({
    required String modelPath,
    required String prompt,
    int maxTokens = 180,
    double temperature = 0.3,
  }) async* {
    throw StateError(
      'Native GGUF runtime unavailable: $unavailableReason',
    );
  }

  @override
  void dispose() {}
}
