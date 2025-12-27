import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account.dart';
import '../providers/totp_provider.dart';
import 'code_display.dart';
import 'countdown_indicator.dart';

/// Displays a single account with its live TOTP code
class AccountTile extends ConsumerWidget {
  final Account account;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const AccountTile({
    super.key,
    required this.account,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch ticker to rebuild every second
    ref.watch(tickerProvider);

    final totpService = ref.read(totpServiceProvider);
    final code = totpService.generateCode(account);
    final remainingSeconds = totpService.getRemainingSeconds(account);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Account icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getColorForAccount(account),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _getInitials(account),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Account name and code
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.issuer ?? account.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    if (account.issuer != null)
                      Text(
                        account.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    const SizedBox(height: 4),
                    CodeDisplay(code: code),
                  ],
                ),
              ),

              // Countdown
              CountdownIndicator(
                remainingSeconds: remainingSeconds,
                totalSeconds: account.period,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(Account account) {
    final name = account.issuer ?? account.name;
    final words = name.split(RegExp(r'[\s\-_]'));
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  Color _getColorForAccount(Account account) {
    // Generate consistent color from account name
    final name = account.issuer ?? account.name;
    final hash = name.hashCode;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
    ];
    return colors[hash.abs() % colors.length];
  }
}
