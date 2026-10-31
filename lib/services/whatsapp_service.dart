import 'package:url_launcher/url_launcher.dart';

enum WhatsAppHandoffState {
  openedHandoff,
  appNotInstalled,
  failed,
}

class WhatsAppService {
  /// Opens a WhatsApp conversation with recipient and prefilled emergency text.
  /// Requires user to tap send inside WhatsApp (respects platform & WhatsApp policy).
  Future<WhatsAppHandoffState> openEmergencyChat({
    required String phoneNumber,
    required String message,
  }) async {
    // Clean phone number for WhatsApp wa.me link (digits only, no '+' prefix in path)
    final cleanDigits = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse(
      'https://wa.me/$cleanDigits?text=${Uri.encodeComponent(message)}',
    );

    try {
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        return launched
            ? WhatsAppHandoffState.openedHandoff
            : WhatsAppHandoffState.failed;
      } else {
        return WhatsAppHandoffState.appNotInstalled;
      }
    } catch (_) {
      return WhatsAppHandoffState.failed;
    }
  }
}
