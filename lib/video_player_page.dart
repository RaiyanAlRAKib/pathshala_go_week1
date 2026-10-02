import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoUrl;
  final String title;

  const VideoPlayerPage({super.key, required this.videoUrl, required this.title});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _isReady = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() => _isReady = true);
      _controller.play();
    }).catchError((_) {
      if (!mounted) return;
      setState(() => _hasError = true);
    });
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _seekBy(int seconds) {
    final target = _controller.value.position + Duration(seconds: seconds);
    final duration = _controller.value.duration;
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > duration ? duration : target);
    _controller.seekTo(clamped);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: _hasError
            ? const Center(
                child: Text('Could not load this video.', style: TextStyle(color: Colors.white)),
              )
            : (!_isReady
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        ),
                        const SizedBox(height: 12),
                        VideoProgressIndicator(
                          _controller,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: Colors.teal,
                            bufferedColor: Colors.white24,
                            backgroundColor: Colors.white12,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatDuration(_controller.value.position)} / ${_formatDuration(_controller.value.duration)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              iconSize: 32,
                              color: Colors.white,
                              icon: const Icon(Icons.replay_10),
                              onPressed: () => _seekBy(-10),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              iconSize: 48,
                              color: Colors.white,
                              icon: Icon(_controller.value.isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled),
                              onPressed: () {
                                setState(() {
                                  _controller.value.isPlaying
                                      ? _controller.pause()
                                      : _controller.play();
                                });
                              },
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              iconSize: 32,
                              color: Colors.white,
                              icon: const Icon(Icons.forward_10),
                              onPressed: () => _seekBy(10),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  )),
      ),
    );
  }
}