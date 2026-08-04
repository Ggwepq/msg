import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/theme_service.dart';

class NotificationPermissionDialog extends StatefulWidget {
  final VoidCallback onDone;

  const NotificationPermissionDialog({super.key, required this.onDone});

  static Future<void> checkAndShow(BuildContext context, {required VoidCallback onDone}) async {
    final notificationService = NotificationService();
    await notificationService.init();
    final hasPermission = await notificationService.checkPermission();

    if (!hasPermission && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => NotificationPermissionDialog(onDone: onDone),
      );
    } else {
      onDone();
    }
  }

  @override
  State<NotificationPermissionDialog> createState() => _NotificationPermissionDialogState();
}

class _NotificationPermissionDialogState extends State<NotificationPermissionDialog> {
  final _theme = ThemeService();
  bool _isRequesting = false;

  Future<void> _handleEnable() async {
    setState(() => _isRequesting = true);
    await NotificationService().requestPermission();
    if (mounted) {
      Navigator.pop(context);
      widget.onDone();
    }
  }

  void _handleSkip() {
    Navigator.pop(context);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final accent = _theme.primary;

    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bell Header Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: accent.withOpacity(0.3), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.notifications_active_rounded,
                  color: accent,
                  size: 34,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              "Don't Miss A Chat! 🔔",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // Description
            Text(
              "Turn on notifications to get instant alerts whenever your friends send you new messages, photos, or videos.",
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 26),

            // Primary Action: Enable Notifications
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                onPressed: _isRequesting ? null : _handleEnable,
                child: _isRequesting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 18, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            "Enable Notifications",
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // Secondary Action: Skip
            TextButton(
              onPressed: _handleSkip,
              child: Text(
                "Maybe Later",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
