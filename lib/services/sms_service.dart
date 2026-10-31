import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

enum SmsSendState {
  sentDirect,
  openedComposerFallback,
  failed,
  permissionDenied,
  telephonyUnavailable,
}

class SmsSendResult {
  const SmsSendResult({
    required this.state,
    this.errorMessage,
    this.partsCount = 1,
  });

  final SmsSendState state;
  final String? errorMessage;
  final int partsCount;

  bool get isSuccessful =>
      state == SmsSendState.sentDirect || state == SmsSendState.openedComposerFallback;
}

class SmsService {
  SmsService({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('org.bsas.sos/sms');

  final MethodChannel _channel;

  /// Checks if telephony hardware is available and whether SEND_SMS permission is granted.
  Future<Map<String, bool>> checkCapability() async {
    try {
      final res = await _channel.invokeMapMethod<String, dynamic>('checkSmsCapability');
      return {
        'hasTelephony': res?['hasTelephony'] as bool? ?? true,
        'hasPermission': res?['hasPermission'] as bool? ?? false,
      };
    } catch (_) {
      return {'hasTelephony': true, 'hasPermission': false};
    }
  }

  /// Sends direct SMS via Android native SmsManager or opens native composer fallback.
  Future<SmsSendResult> sendEmergencySms({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      // 1. Attempt direct SMS via native Android MethodChannel
      final res = await _channel.invokeMapMethod<String, dynamic>('sendDirectSms', {
        'phoneNumber': phoneNumber,
        'message': message,
      });

      final status = res?['status'] as String?;
      final parts = res?['parts'] as int? ?? 1;

      if (status == 'SENT') {
        return SmsSendResult(state: SmsSendState.sentDirect, partsCount: parts);
      }
    } on PlatformException catch (e) {
      // If permission is denied or native direct send failed, use compliant composer fallback
      if (e.code == 'PERMISSION_DENIED') {
        final fallback = await _launchSmsComposer(phoneNumber, message);
        return fallback
            ? const SmsSendResult(state: SmsSendState.openedComposerFallback)
            : SmsSendResult(
                state: SmsSendState.permissionDenied,
                errorMessage: 'SEND_SMS permission denied and composer failed to open: ${e.message}',
              );
      }
    } catch (e) {
      // Fallback
    }

    // 2. Fallback: Launch native SMS app with recipient & text prefilled
    final fallbackOk = await _launchSmsComposer(phoneNumber, message);
    if (fallbackOk) {
      return const SmsSendResult(state: SmsSendState.openedComposerFallback);
    }

    return const SmsSendResult(
      state: SmsSendState.failed,
      errorMessage: 'Could not send SMS automatically or launch default messaging app.',
    );
  }

  Future<bool> _launchSmsComposer(String phoneNumber, String message) async {
    try {
      final encodedBody = Uri.encodeComponent(message);
      final uri = Uri.parse('sms:$phoneNumber?body=$encodedBody');
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
    } catch (_) {}
    return false;
  }
}
