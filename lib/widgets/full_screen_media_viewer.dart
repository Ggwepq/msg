import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class FullScreenMediaViewer extends StatefulWidget {
  final String mediaPath;
  final String messageType; // 'image' or 'video'

  const FullScreenMediaViewer({
    super.key,
    required this.mediaPath,
    required this.messageType,
  });

  @override
  State<FullScreenMediaViewer> createState() => _FullScreenMediaViewerState();
}

class _FullScreenMediaViewerState extends State<FullScreenMediaViewer> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.messageType == 'video') {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    try {
      if (kIsWeb || widget.mediaPath.startsWith('http')) {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.mediaPath));
      } else {
        _videoController = VideoPlayerController.file(File(widget.mediaPath));
      }
      await _videoController!.initialize();
      _videoController!.play();
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: widget.messageType == 'image'
            ? InteractiveViewer(
                child: kIsWeb || widget.mediaPath.startsWith('http')
                    ? Image.network(widget.mediaPath, fit: BoxFit.contain)
                    : Image.file(File(widget.mediaPath), fit: BoxFit.contain),
              )
            : (_isVideoInitialized && _videoController != null
                ? AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        VideoPlayer(_videoController!),
                        VideoProgressIndicator(
                          _videoController!,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: Color(0xFF6366F1),
                            bufferedColor: Colors.white24,
                            backgroundColor: Colors.white10,
                          ),
                        ),
                      ],
                    ),
                  )
                : const CircularProgressIndicator(color: Color(0xFF6366F1))),
      ),
    );
  }
}
