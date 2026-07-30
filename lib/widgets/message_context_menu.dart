import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/chat_message.dart';
import '../services/theme_service.dart';

class MessageContextMenu extends StatefulWidget {
  final ChatMessage message;
  final bool isMe;
  final Offset tapPosition;
  final Size bubbleSize;
  final VoidCallback onDismiss;
  final VoidCallback onCopy;
  final VoidCallback onReply;
  final VoidCallback? onDelete;

  const MessageContextMenu({
    super.key,
    required this.message,
    required this.isMe,
    required this.tapPosition,
    required this.bubbleSize,
    required this.onDismiss,
    required this.onCopy,
    required this.onReply,
    this.onDelete,
  });

  @override
  State<MessageContextMenu> createState() => _MessageContextMenuState();
}

class _MessageContextMenuState extends State<MessageContextMenu>
    with SingleTickerProviderStateMixin {
  final _theme = ThemeService();
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _blurAnim;
  late Animation<double> _menuSlideAnim;

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _blurAnim = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _menuSlideAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final accent = _theme.primary;
    final screenSize = MediaQuery.of(context).size;

    // Calculate positions
    final bubbleTop = widget.tapPosition.dy - (widget.bubbleSize.height / 2);
    final clampedTop = bubbleTop.clamp(80.0, screenSize.height - 300);

    // Menu appears above or below the bubble depending on space
    final spaceBelow = screenSize.height - (clampedTop + widget.bubbleSize.height);
    final menuAbove = spaceBelow < 180;
    final menuTop = menuAbove
        ? clampedTop - 8 // will use Positioned bottom instead
        : clampedTop + widget.bubbleSize.height + 8;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            // Blurred + dimmed background — tap to dismiss
            GestureDetector(
              onTap: _dismiss,
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: _blurAnim.value,
                  sigmaY: _blurAnim.value,
                ),
                child: Container(
                  color: Colors.black.withOpacity(0.35 * _fadeAnim.value),
                ),
              ),
            ),

            // Message preview (scaled + lifted)
            Positioned(
              top: clampedTop,
              left: widget.isMe ? null : 14,
              right: widget.isMe ? 14 : null,
              child: Transform.scale(
                scale: _scaleAnim.value,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: screenSize.width * 0.75,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 11),
                    decoration: BoxDecoration(
                      color: widget.isMe
                          ? accent.withOpacity(0.22)
                          : _theme.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft:
                            Radius.circular(widget.isMe ? 20 : 6),
                        bottomRight:
                            Radius.circular(widget.isMe ? 6 : 20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Text(
                      widget.message.text,
                      style: TextStyle(
                        color: _theme.textPrimary,
                        fontSize: 14.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Context menu options
            Positioned(
              top: menuAbove ? null : menuTop,
              bottom: menuAbove
                  ? screenSize.height - clampedTop + 8
                  : null,
              left: widget.isMe ? null : 14,
              right: widget.isMe ? 14 : null,
              child: FadeTransition(
                opacity: _menuSlideAnim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.2),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _controller,
                    curve: const Interval(0.15, 1.0,
                        curve: Curves.easeOutCubic),
                  )),
                  child: _buildMenu(accent),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenu(Color accent) {
    return Container(
      width: 180,
      decoration: BoxDecoration(
        color: _theme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _menuItem(
            icon: Icons.copy_rounded,
            label: "Copy",
            onTap: () {
              widget.onCopy();
              _dismiss();
            },
          ),
          _divider(),
          _menuItem(
            icon: Icons.reply_rounded,
            label: "Reply",
            onTap: () {
              widget.onReply();
              _dismiss();
            },
          ),
          if (widget.onDelete != null) ...[
            _divider(),
            _menuItem(
              icon: Icons.delete_outline_rounded,
              label: "Delete",
              isDestructive: true,
              onTap: () {
                widget.onDelete!();
                _dismiss();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive
        ? const Color(0xFFFF6F6F)
        : _theme.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: _theme.divider,
    );
  }
}
