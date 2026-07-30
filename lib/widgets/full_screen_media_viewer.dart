import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class FullScreenMediaViewer extends StatefulWidget {
  final String? imageUrl;
  final String? videoUrl;

  const FullScreenMediaViewer({
    super.key,
    this.imageUrl,
    this.videoUrl,
  });

  @override
  State<FullScreenMediaViewer> createState() => _FullScreenMediaViewerState();
}

class _FullScreenMediaViewerState extends State<FullScreenMediaViewer> {
  VideoPlayerController? _videoController;
  bool _videoError = false;
  bool _imageError = false;

  @override
  void initState() {
    super.initState();
    if (widget.videoUrl != null) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    try {
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl!));
      await _videoController!.initialize();
      if (mounted) {
        setState(() {});
        _videoController!.play();
        _videoController!.setLooping(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _videoError = true);
      }
    }
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
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: widget.videoUrl != null ? _buildVideoPlayer() : _buildImageViewer(),
      ),
    );
  }

  Widget _buildImageViewer() {
    if (widget.imageUrl == null || _imageError) {
      return _buildErrorState('Image could not be loaded');
    }
    return InteractiveViewer(
      panEnabled: true,
      boundaryMargin: const EdgeInsets.all(20),
      minScale: 0.5,
      maxScale: 4,
      child: Image.network(
        widget.imageUrl!,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              color: const Color(0xFF7C3AED),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          // Instead of crashing, show a graceful error
          return _buildErrorState('Image could not be loaded');
        },
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_videoError) {
      return _buildErrorState('Video could not be loaded');
    }
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return const CircularProgressIndicator(color: Color(0xFF7C3AED));
    }
    return AspectRatio(
      aspectRatio: _videoController!.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_videoController!),
          GestureDetector(
            onTap: () {
              setState(() {
                if (_videoController!.value.isPlaying) {
                  _videoController!.pause();
                } else {
                  _videoController!.play();
                }
              });
            },
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _videoController!.value.isPlaying ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.broken_image_outlined, color: Colors.white.withOpacity(0.3), size: 64),
        const SizedBox(height: 16),
        Text(
          message,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
        ),
        const SizedBox(height: 24),
        TextButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF7C3AED)),
          label: const Text('Go back', style: TextStyle(color: Color(0xFF7C3AED))),
        ),
      ],
    );
  }
}
