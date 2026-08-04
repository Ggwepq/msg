import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../services/media_cache_service.dart';

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
  bool _isPlaying = false;
  bool _hasError = false;
  File? _cachedFile;

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    if (widget.mediaPath.startsWith('http')) {
      final file = await MediaCacheService().getCachedFile(widget.mediaPath);
      if (mounted) {
        setState(() {
          _cachedFile = file;
        });
      }
    } else {
      _cachedFile = File(widget.mediaPath);
    }

    if (widget.messageType == 'video') {
      await _initVideo();
    }
  }

  Future<void> _initVideo() async {
    try {
      if (_cachedFile != null && await _cachedFile!.exists()) {
        _videoController = VideoPlayerController.file(_cachedFile!);
      } else if (kIsWeb || widget.mediaPath.startsWith('http')) {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.mediaPath));
      } else {
        _videoController = VideoPlayerController.file(File(widget.mediaPath));
      }

      await _videoController!.initialize();
      _videoController!.setLooping(true);
      await _videoController!.play();

      _videoController!.addListener(() {
        if (mounted && _videoController != null) {
          final isPlayingNow = _videoController!.value.isPlaying;
          if (_isPlaying != isPlayingNow) {
            setState(() {
              _isPlaying = isPlayingNow;
            });
          }
        }
      });

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
          _isPlaying = true;
        });
      }
    } catch (e) {
      debugPrint("FullScreenMediaViewer video error: $e");
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  void _togglePlayPause() {
    if (_videoController == null || !_isVideoInitialized) return;
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
    });
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
        backgroundColor: Colors.black.withOpacity(0.6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.messageType == 'video' ? "Video Viewer" : "Photo Viewer",
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: widget.messageType == 'image'
            ? InteractiveViewer(
                child: _cachedFile != null && _cachedFile!.existsSync()
                    ? Image.file(_cachedFile!, fit: BoxFit.contain)
                    : (kIsWeb || widget.mediaPath.startsWith('http')
                        ? Image.network(
                            widget.mediaPath,
                            fit: BoxFit.contain,
                            loadingBuilder: (_, child, progress) {
                              if (progress == null) return child;
                              return const CircularProgressIndicator(color: Color(0xFF6366F1));
                            },
                          )
                        : Image.file(File(widget.mediaPath), fit: BoxFit.contain)),
              )
            : (_hasError
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.white54, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        "Unable to play video on this device",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  )
                : (_isVideoInitialized && _videoController != null
                    ? GestureDetector(
                        onTap: _togglePlayPause,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AspectRatio(
                              aspectRatio: _videoController!.value.aspectRatio,
                              child: VideoPlayer(_videoController!),
                            ),
                            // Play/Pause Overlay Icon
                            AnimatedOpacity(
                              opacity: _isPlaying ? 0.0 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: CircleAvatar(
                                radius: 36,
                                backgroundColor: const Color(0xFF6366F1).withOpacity(0.9),
                                child: Icon(
                                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 44,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: VideoProgressIndicator(
                                _videoController!,
                                allowScrubbing: true,
                                colors: const VideoProgressColors(
                                  playedColor: Color(0xFF6366F1),
                                  bufferedColor: Colors.white38,
                                  backgroundColor: Colors.white12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const CircularProgressIndicator(color: Color(0xFF6366F1)))),
      ),
    );
  }
}
