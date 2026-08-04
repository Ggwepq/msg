import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../services/theme_service.dart';
import 'full_screen_media_viewer.dart';
import 'inline_video_player.dart';


class ChatBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isMe;
  final bool isAdmin;
  final Function(Offset position, Size size)? onLongPress;
  final VoidCallback? onReactionBadgeTap;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.isAdmin = false,
    this.onLongPress,
    this.onReactionBadgeTap,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  bool _isRevealedByAdmin = false;

  void _openFullScreenViewer() {
    if (widget.message.mediaPath != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullScreenMediaViewer(
            mediaPath: widget.message.mediaPath!,
            messageType: widget.message.messageType,
          ),
        ),
      );
    }
  }

  Widget _buildMediaContent(ThemeService theme, Color accent) {
    final mediaPath = widget.message.mediaPath;
    if (mediaPath == null || mediaPath.isEmpty) return const SizedBox.shrink();

    final uploadProgress = ChatService().getUploadProgress(widget.message.id);
    final isUploading = uploadProgress != null;

    Widget mediaWidget;
    if (widget.message.messageType == 'image') {
      if (kIsWeb || mediaPath.startsWith('http')) {
        mediaWidget = Image.network(
          mediaPath,
          width: 200,
          height: 200,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            final percent = loadingProgress.expectedTotalBytes != null && loadingProgress.expectedTotalBytes! > 0
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null;
            return _buildMediaLoadingPlaceholder(percent: percent, status: "Loading photo...");
          },
          errorBuilder: (_, __, ___) => _buildMediaError("Photo unavailable"),
        );
      } else {
        mediaWidget = Image.file(
          File(mediaPath),
          width: 200,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildMediaError("Photo file unavailable"),
        );
      }
    } else {
      mediaWidget = InlineVideoPlayer(
        videoPath: mediaPath,
        onOpenFullScreen: _openFullScreenViewer,
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      width: 200,
      height: 200,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.surfaceLight,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          mediaWidget,
          if (isUploading)
            _buildUploadProgressOverlay(accent, uploadProgress),
        ],
      ),
    );
  }

  Widget _buildMediaLoadingPlaceholder({double? percent, String status = "Loading..."}) {
    return Container(
      width: 200,
      height: 200,
      color: const Color(0xFF1E293B),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_outlined, color: Colors.white38, size: 36),
          const SizedBox(height: 10),
          if (percent != null) ...[
            SizedBox(
              width: 110,
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: Colors.white12,
                color: Colors.white70,
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "${(percent * 100).toInt()}%",
              style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ] else ...[
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
            ),
            const SizedBox(height: 8),
            Text(
              status,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadProgressOverlay(Color accent, double progress) {
    final percentInt = (progress * 100).clamp(0, 100).toInt();
    return Container(
      color: Colors.black.withOpacity(0.65),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            "Uploading... $percentInt%",
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),
          SizedBox(
            width: 120,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white24,
              color: accent,
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaError(String msg) {
    return Container(
      width: 200,
      height: 200,
      padding: const EdgeInsets.all(12),
      color: const Color(0xFF1E293B),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image_outlined, color: Colors.white38, size: 28),
            const SizedBox(height: 6),
            Text(msg, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = ThemeService();
    final accent = theme.primary;
    final timeStr = DateFormat('h:mm a').format(widget.message.timestamp);

    final Map<String, int> reactionCounts = {};
    widget.message.reactions.forEach((_, emoji) {
      reactionCounts[emoji] = (reactionCounts[emoji] ?? 0) + 1;
    });

    final isDeleted = widget.message.isDeleted;
    final isShowingNormalStyle = !isDeleted || (isDeleted && _isRevealedByAdmin);

    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: () {
          if (isDeleted && widget.isAdmin) {
            setState(() {
              _isRevealedByAdmin = !_isRevealedByAdmin;
            });
          } else if (isShowingNormalStyle && widget.message.mediaPath != null) {
            _openFullScreenViewer();
          }
        },
        onLongPressStart: (details) {
          if (widget.onLongPress != null && !isDeleted) {
            final box = context.findRenderObject() as RenderBox?;
            final size = box?.size ?? const Size(200, 200);
            widget.onLongPress!(details.globalPosition, size);
          }
        },
        child: Container(
          margin: EdgeInsets.only(
            left: widget.isMe ? 60 : 14,
            right: widget.isMe ? 14 : 60,
            top: 3,
            bottom: 3,
          ),
          child: Column(
            crossAxisAlignment:
                widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isShowingNormalStyle
                      ? (widget.isMe ? accent.withOpacity(0.18) : theme.surface)
                      : theme.surface.withOpacity(0.5),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(widget.isMe ? 20 : 6),
                    bottomRight: Radius.circular(widget.isMe ? 6 : 20),
                  ),
                  border: !isShowingNormalStyle
                      ? Border.all(color: Colors.white.withOpacity(0.08))
                      : null,
                ),
                child: Column(
                  crossAxisAlignment:
                      widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Reply Quote if any
                    if (isShowingNormalStyle && widget.message.replyToText != null) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border(
                            left: BorderSide(color: accent, width: 3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.message.replyToSender ?? "Reply",
                              style: TextStyle(
                                color: accent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.message.replyToText!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: theme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Media Content (1:1 Ratio Photo / Playable Video)
                    if (isShowingNormalStyle && widget.message.mediaPath != null)
                      _buildMediaContent(theme, accent),

                    // Message text
                    if (isShowingNormalStyle) ...[
                      if (widget.message.text.isNotEmpty)
                        Text(
                          widget.message.text,
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 14.5,
                            height: 1.35,
                          ),
                        ),
                    ] else ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.block_rounded,
                            size: 14,
                            color: theme.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "this message was deleted",
                            style: TextStyle(
                              color: theme.textMuted,
                              fontSize: 13.5,
                              fontStyle: FontStyle.italic,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 4),
                    Text(
                      isDeleted && _isRevealedByAdmin
                          ? "$timeStr · deleted"
                          : timeStr,
                      style: TextStyle(
                        color: theme.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              // Interactive Reaction Badges Pill Row
              if (!isDeleted && reactionCounts.isNotEmpty) ...[
                GestureDetector(
                  onTap: widget.onReactionBadgeTap,
                  child: Transform.translate(
                    offset: const Offset(0, -6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: reactionCounts.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 3),
                            child: Text(
                              entry.value > 1 ? "${entry.key} ${entry.value}" : entry.key,
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
