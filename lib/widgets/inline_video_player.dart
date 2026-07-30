import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class InlineVideoPlayer extends StatefulWidget {
  final String videoPath;

  const InlineVideoPlayer({
    super.key,
    required this.videoPath,
  });

  @override
  State<InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<InlineVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initVideoPlayer();
  }

  Future<void> _initVideoPlayer() async {
    try {
      final file = File(widget.videoPath);
      if (!kIsWeb && !widget.videoPath.startsWith('http') && !file.existsSync()) {
        if (mounted) setState(() => _hasError = true);
        return;
      }

      if (kIsWeb || widget.videoPath.startsWith('http')) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoPath));
      } else {
        _controller = VideoPlayerController.file(file);
      }

      await _controller!.initialize();
      _controller!.setLooping(false);
      _controller!.addListener(() {
        if (mounted && _controller != null) {
          final isPlayingNow = _controller!.value.isPlaying;
          if (_isPlaying != isPlayingNow) {
            setState(() {
              _isPlaying = isPlayingNow;
            });
          }
        }
      });

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        if (_controller!.value.position >= _controller!.value.duration) {
          _controller!.seekTo(Duration.zero);
        }
        _controller!.play();
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    // If video player engine cannot play natively on host OS (e.g. missing desktop codecs), render a sleek Video Card fallback!
    if (_hasError || _controller == null) {
      final fileName = widget.videoPath.split('/').last;
      return Container(
        height: 160,
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF24243A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.movie_creation_outlined, color: Color(0xFF6366F1), size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              fileName.length > 25 ? "${fileName.substring(0, 22)}..." : fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              "Video File Attached",
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: const Color(0xFF24243A),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF6366F1),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      constraints: const BoxConstraints(maxHeight: 250),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: _controller!.value.aspectRatio > 0
                  ? _controller!.value.aspectRatio
                  : 16 / 9,
              child: VideoPlayer(_controller!),
            ),

            // Play / Pause Gesture Overlay
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _togglePlayPause,
                child: Container(
                  color: _isPlaying ? Colors.transparent : Colors.black.withOpacity(0.35),
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: _isPlaying ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: const Color(0xFF6366F1).withOpacity(0.9),
                        child: Icon(
                          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Video Duration Badge
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "${_formatDuration(_controller!.value.position)} / ${_formatDuration(_controller!.value.duration)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Video Progress Bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                _controller!,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Color(0xFF6366F1),
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
