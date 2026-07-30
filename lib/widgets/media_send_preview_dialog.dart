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
  bool _isCompressing = false;
  String? _errorMessage;
  double _fileSizeMB = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateInitialFileSize();
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _calculateInitialFileSize() async {
    try {
      final bytes = await File(widget.pickedFile.path).length();
      setState(() {
        _fileSizeMB = bytes / (1024 * 1024);
      });
    } catch (_) {}
  }

  Future<void> _processAndSend() async {
    setState(() {
      _isCompressing = true;
      _errorMessage = null;
    });

    String finalPath = widget.pickedFile.path;

    if (widget.isVideo) {
      try {
        // 1. Duration check (< 10 minutes)
        final info = await VideoCompress.getMediaInfo(widget.pickedFile.path);
        final durationMs = info.duration ?? 0;
        if (durationMs > 600000) {
          setState(() {
            _isCompressing = false;
            _errorMessage = "Video exceeds 10-minute duration limit.";
          });
          return;
        }

        // 2. Compress Video
        final MediaInfo? compressedInfo = await VideoCompress.compressVideo(
          widget.pickedFile.path,
          quality: VideoQuality.MediumQuality,
          deleteOrigin: false,
        );

        finalPath = compressedInfo?.file?.path ?? compressedInfo?.path ?? widget.pickedFile.path;
      } on MissingPluginException {
        // Native fallback if video_compress plugin binary is unavailable on host
        finalPath = widget.pickedFile.path;
      } catch (_) {
        finalPath = widget.pickedFile.path;
      }

      // 3. File Size Check (< 50 MB)
      try {
        final finalBytes = await File(finalPath).length();
        final finalMB = finalBytes / (1024 * 1024);
        if (finalMB > 50) {
          setState(() {
            _isCompressing = false;
            _errorMessage = "Video size is ${finalMB.toStringAsFixed(1)} MB (Exceeds 50 MB limit).";
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
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.isVideo ? "Preview Video" : "Preview Photo",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!_isCompressing)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Preview Area
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: widget.isVideo
                  ? InlineVideoPlayer(videoPath: widget.pickedFile.path)
                  : (kIsWeb || widget.pickedFile.path.startsWith('http')
                      ? Image.network(widget.pickedFile.path, fit: BoxFit.cover)
                      : Image.file(File(widget.pickedFile.path), fit: BoxFit.cover)),
            ),

            const SizedBox(height: 12),
            if (_fileSizeMB > 0)
              Text(
                "Original Size: ${_fileSizeMB.toStringAsFixed(1)} MB",
                style: const TextStyle(color: Colors.white54, fontSize: 12),
                textAlign: TextAlign.center,
              ),

            const SizedBox(height: 14),

            // Optional Caption Field
            TextField(
              controller: _captionController,
              enabled: !_isCompressing,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Add a caption (optional)...",
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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

            // Send / Compress Action Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isCompressing ? null : _processAndSend,
              child: _isCompressing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                        SizedBox(width: 12),
                        Text("Compressing & Processing...", style: TextStyle(color: Colors.white)),
                      ],
                    )
                  : Text(
                      widget.isVideo ? "Compress & Send" : "Send Photo",
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
