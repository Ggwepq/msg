import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/access_key.dart';

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
    final createdStr = DateFormat('MMM d, h:mm a').format(accessKey.createdAt);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accessKey.isClaimed
              ? const Color(0xFF10B981).withOpacity(0.4)
              : Colors.indigo.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accessKey.isClaimed
                  ? const Color(0xFF10B981).withOpacity(0.15)
                  : Colors.indigo.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              accessKey.isClaimed ? Icons.check_circle_outline : Icons.vpn_key,
              color: accessKey.isClaimed ? const Color(0xFF34D399) : Colors.indigoAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  accessKey.key,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    fontSize: 15,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                if (accessKey.isClaimed)
                  Text(
                    "Claimed by: ${accessKey.claimedByNickname ?? 'Friend'}",
                    style: const TextStyle(
                      color: Color(0xFF34D399),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  Text(
                    "Created: $createdStr",
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18, color: Colors.white70),
            tooltip: "Copy Key",
            onPressed: () {
              Clipboard.setData(ClipboardData(text: accessKey.key));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Copied ${accessKey.key} to clipboard"),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
              tooltip: "Delete Key",
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
