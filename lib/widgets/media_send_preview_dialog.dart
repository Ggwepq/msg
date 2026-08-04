import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';
import '../services/theme_service.dart';
import 'inline_video_player.dart';

class MediaSendPreviewDialog extends StatefulWidget {
  final XFile pickedFile;
  final bool isVideo;
  final Function(String finalPath, String caption) onConfirmSend;

  const MediaSendPreviewDialog({
    super.key,
    required this.pickedFile,
    required this.isVideo,
    required this.onConfirmSend,
  });

  @override
  State<MediaSendPreviewDialog> createState() => _MediaSendPreviewDialogState();
}

class _MediaSendPreviewDialogState extends State<MediaSendPreviewDialog> {
  final _captionController = TextEditingController();
  final _theme = ThemeService();
  bool _isProcessing = false;
  double _compressionPercent = 0.0;
  String? _errorMessage;
  double _fileSizeMB = 0.0;
  Subscription? _compressSubscription;

  @override
  void initState() {
    super.initState();
    _calculateInitialFileSize();
    if (widget.isVideo) {
      try {
        _compressSubscription = VideoCompress.compressProgress$.subscribe((progress) {
          if (mounted) {
            setState(() {
              _compressionPercent = progress;
            });
          }
        });
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _compressSubscription?.unsubscribe();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _calculateInitialFileSize() async {
    try {
      final bytes = await File(widget.pickedFile.path).length();
      if (mounted) {
        setState(() {
          _fileSizeMB = bytes / (1024 * 1024);
        });
      }
    } catch (_) {}
  }

  Future<void> _processAndSend() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _compressionPercent = 0.0;
    });

    String finalPath = widget.pickedFile.path;

    if (widget.isVideo) {
      try {
        // Attempt Video Compression if supported
        final MediaInfo? compressedInfo = await VideoCompress.compressVideo(
          widget.pickedFile.path,
          quality: VideoQuality.MediumQuality,
          deleteOrigin: false,
        ).timeout(const Duration(seconds: 15), onTimeout: () {
          debugPrint("Video compression timed out. Using original file.");
          return null;
        });

        if (compressedInfo?.file != null && await compressedInfo!.file!.exists()) {
          finalPath = compressedInfo.file!.path;
        } else if (compressedInfo?.path != null) {
          finalPath = compressedInfo!.path!;
        }
      } on MissingPluginException {
        finalPath = widget.pickedFile.path;
      } catch (e) {
        debugPrint("Video compression fallback: $e");
        finalPath = widget.pickedFile.path;
      }

      // Check final file size (< 100 MB)
      try {
        final finalBytes = await File(finalPath).length();
        final finalMB = finalBytes / (1024 * 1024);
        if (finalMB > 100) {
          setState(() {
            _isProcessing = false;
            _errorMessage = "File size is ${finalMB.toStringAsFixed(1)} MB (Exceeds 100 MB limit).";
          });
          return;
        }
      } catch (_) {}
    }

    if (mounted) {
      widget.onConfirmSend(finalPath, _captionController.text.trim());
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _theme.primary;

    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      widget.isVideo ? Icons.videocam_rounded : Icons.image_rounded,
                      color: accent,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.isVideo ? "Preview Video" : "Preview Photo",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (!_isProcessing)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Media Preview Container
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              clipBehavior: Clip.antiAlias,
              child: widget.isVideo
                  ? InlineVideoPlayer(videoPath: widget.pickedFile.path)
                  : (kIsWeb || widget.pickedFile.path.startsWith('http')
                      ? Image.network(
                          widget.pickedFile.path,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        )
                      : Image.file(
                          File(widget.pickedFile.path),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        )),
            ),

            const SizedBox(height: 10),
            if (_fileSizeMB > 0)
              Text(
                "Original File Size: ${_fileSizeMB.toStringAsFixed(1)} MB",
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                textAlign: TextAlign.center,
              ),

            const SizedBox(height: 14),

            // Caption Text Field
            TextField(
              controller: _captionController,
              enabled: !_isProcessing,
              style: const TextStyle(color: Colors.white, fontSize: 14.5),
              decoration: InputDecoration(
                hintText: "Add a caption...",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
                prefixIcon: const Icon(Icons.short_text_rounded, color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 20),

            // Action Button with Live Progress Bar
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _isProcessing ? null : _processAndSend,
              child: _isProcessing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _compressionPercent > 0
                              ? "Compressing Video: ${_compressionPercent.toInt()}%"
                              : (widget.isVideo ? "Compressing Video..." : "Preparing Photo..."),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          widget.isVideo ? "Compress & Send" : "Send Photo",
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF0F172A),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_outlined, size: 40, color: Colors.white24),
            SizedBox(height: 8),
            Text("Preview unavailable", style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
