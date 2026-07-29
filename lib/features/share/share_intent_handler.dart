import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:atlas/core/utils/utils.dart';
import 'package:atlas/features/share/quick_save_sheet.dart';

class ShareIntentHandler {
  static const MethodChannel _channel = MethodChannel('com.atlas.web/share');

  /// Check for any intent text that launched the app initially.
  static Future<void> checkInitialIntent(BuildContext context) async {
    try {
      final String? sharedText = await _channel.invokeMethod('getSharedText');
      if (sharedText != null && sharedText.isNotEmpty) {
        if (context.mounted) {
          _handleSharedText(sharedText, context);
        }
      }
    } on PlatformException catch (e) {
      debugPrint("Failed to get shared text: '${e.message}'.");
    }
  }

  /// Listen for new intents while the app is already running in the background.
  static void setupIntentListener(BuildContext context) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onSharedText') {
        final String? sharedText = call.arguments as String?;
        if (sharedText != null && sharedText.isNotEmpty) {
          if (context.mounted) {
            _handleSharedText(sharedText, context);
          }
        }
      }
    });
  }

  static void _handleSharedText(String text, BuildContext context) {
    final url = extractUrlFromText(text);
    if (url != null && isValidUrl(url)) {
      QuickSaveSheet.show(context, prefilledUrl: url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No valid URL found in shared text')),
      );
    }
  }
}
