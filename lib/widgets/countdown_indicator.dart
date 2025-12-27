import 'package:flutter/material.dart';

/// Circular countdown indicator showing time remaining for TOTP code
class CountdownIndicator extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;

  const CountdownIndicator({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final progress = remainingSeconds / totalSeconds;
    final isLow = remainingSeconds <= 5;

    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(
              isLow ? Colors.red : Theme.of(context).primaryColor,
            ),
          ),
          Text(
            '$remainingSeconds',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isLow ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }
}
