import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class InlineVideoPlayer extends StatefulWidget {
  final String videoPath;
  final VoidCallback? onOpenFullScreen;

  const InlineVideoPlayer({
    super.key,
    required this.videoPath,
    this.onOpenFullScreen,
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
    // If video player engine cannot play natively on host OS (e.g. missing desktop codecs), render a 1:1 Video Card fallback
    if (_hasError || _controller == null) {
      final fileName = widget.videoPath.split('/').last;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onOpenFullScreen,
        child: Container(
          width: 200,
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF24243A),
            borderRadius: BorderRadius.circular(16),
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
                fileName.length > 20 ? "${fileName.substring(0, 17)}..." : fileName,
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
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFF24243A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF6366F1),
          ),
        ),
      );
    }

    return SizedBox(
      width: 200,
      height: 200,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1:1 Aspect ratio cropped video
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onOpenFullScreen,
                child: FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: _controller!.value.size.width > 0 ? _controller!.value.size.width : 200,
                    height: _controller!.value.size.height > 0 ? _controller!.value.size.height : 200,
                    child: VideoPlayer(_controller!),
                  ),
                ),
              ),
            ),

            // Tap Overlay: Center Play Button toggles playback, tapping outside opens Fullscreen
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onOpenFullScreen,
                child: Container(
                  color: _isPlaying ? Colors.transparent : Colors.black.withOpacity(0.35),
                  child: Center(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _togglePlayPause,
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
