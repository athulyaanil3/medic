import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Shows Firebase Console steps when Auth returns CONFIGURATION_NOT_FOUND.
void showFirebaseSetupDialog(BuildContext context, {String? extraMessage}) {
  const steps = '''
1. Firebase Console → medicvoice-a1047
2. Build → Authentication → Get started
3. Sign-in method → Email/Password → Enable → Save
4. Project settings → Android app → add SHA-1 & SHA-256
5. flutter clean && flutter run

SHA-1:
AE:50:56:D9:4D:40:48:B9:D7:95:33:65:07:F9:3F:6D:C7:FB:4B:80
''';

  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.cloud_off_rounded, color: AppTheme.deepTeal, size: 36),
      title: const Text('Firebase Auth not configured'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (extraMessage != null) ...[
              Text(extraMessage, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
            ],
            const Text(
              'Enable Authentication in Firebase Console, then rebuild:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            SelectableText(steps, style: const TextStyle(fontSize: 13, height: 1.45)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(const ClipboardData(text: steps));
            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Steps copied')));
          },
          child: const Text('Copy steps'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

bool isFirebaseConfigurationError(String? message) {
  if (message == null) return false;
  final m = message.toUpperCase();
  return m.contains('CONFIGURATION_NOT_FOUND') ||
      m.contains('FIREBASE AUTHENTICATION IS NOT SET UP');
}
