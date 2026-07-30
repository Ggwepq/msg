import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/access_key.dart';
import '../services/theme_service.dart';

class KeyBadge extends StatelessWidget {
  final AccessKey accessKey;
  final VoidCallback? onDelete;

  const KeyBadge({
    super.key,
    required this.accessKey,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeService();
    final accent = theme.primary;
    final createdStr = DateFormat('MMM d').format(accessKey.createdAt);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  accessKey.key,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  accessKey.isClaimed
                      ? "→ ${accessKey.claimedByNickname ?? 'someone'}"
                      : "created $createdStr · unclaimed",
                  style: TextStyle(
                    color: accessKey.isClaimed
                        ? accent.withOpacity(0.7)
                        : theme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.copy_rounded, size: 18, color: theme.textSecondary),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: accessKey.key));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("copied ${accessKey.key}")),
              );
            },
          ),
          if (onDelete != null)
            IconButton(
              icon: Icon(Icons.close_rounded, size: 18, color: theme.textMuted),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
