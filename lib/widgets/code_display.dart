import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Displays a TOTP code with formatting and copy-on-tap
class CodeDisplay extends StatelessWidget {
  final String code;
  final VoidCallback? onCopied;

  const CodeDisplay({
    super.key,
    required this.code,
    this.onCopied,
  });

  String get formattedCode {
    // Format as "XXX XXX" for 6 digits, "XXXX XXXX" for 8 digits
    if (code.length == 6) {
      return '${code.substring(0, 3)} ${code.substring(3)}';
    } else if (code.length == 8) {
      return '${code.substring(0, 4)} ${code.substring(4)}';
    }
    return code;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: code));
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Code copied!'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
        onCopied?.call();
      },
      child: Text(
        formattedCode,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: 2,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
