import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart' as yt_iframe;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class MediaContent extends StatelessWidget {
  final String url; // can be a full URL or a Firebase Storage path
  const MediaContent({required this.url});

  bool _isImagePath(String s) {
    final u = s.toLowerCase();
    return u.endsWith('.jpg') || u.endsWith('.jpeg') || u.endsWith('.png') || u.endsWith('.gif') || u.endsWith('.webp');
  }

  @override
  Widget build(BuildContext context) {
    final isHttp = url.startsWith('http://') || url.startsWith('https://');

    Widget buildFromResolved(String resolved) {
      // Detectar YouTube y tipos por la URL final
      final ytId = yt_iframe.YoutubePlayerController.convertUrlToId(resolved);
      if (ytId != null) {
        if (kIsWeb) {
          return _YouTubePlayerWeb(videoId: ytId, originalUrl: resolved);
        } else if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
          return _YouTubePlayerMobile(videoId: ytId, originalUrl: resolved);
        } else {
          return _YouTubeExternalFallback(videoId: ytId, originalUrl: resolved);
        }
      }
      final lower = resolved.toLowerCase();
      final isVideo = lower.endsWith('.mp4');
      final isLottie = lower.endsWith('.json');
      final isImage = _isImagePath(resolved);

      if (isVideo) {
        return _VideoPlayerWidget(url: resolved);
      }
      if (isLottie) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            color: Colors.black12.withOpacity(.04),
            padding: const EdgeInsets.all(8),
            child: Lottie.network(resolved, height: 220, repeat: true, fit: BoxFit.contain),
          ),
        );
      }
      if (isImage) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: Image.network(
              resolved,
              fit: BoxFit.cover,
              width: double.infinity,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 200,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.black12.withOpacity(.06), borderRadius: BorderRadius.circular(12)),
                  child: const CircularProgressIndicator(strokeWidth: 2),
                );
              },
              errorBuilder: (context, error, stack) => Container(
                height: 160,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.black12.withOpacity(.06), borderRadius: BorderRadius.circular(12)),
                child: const Text('No se pudo cargar la imagen'),
              ),
            ),
          ),
        );
      }
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black12.withOpacity(.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: const [
            Icon(Icons.insert_drive_file, color: Colors.black54),
            SizedBox(width: 8),
            Expanded(child: Text('Contenido multimedia no soportado')),
          ],
        ),
      );
    }

    if (isHttp) {
      return buildFromResolved(url);
    }

    // Resolve Firebase Storage path to a download URL
    final ref = FirebaseStorage.instance.ref(url);
    return FutureBuilder<String>(
      future: ref.getDownloadURL(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Container(
            height: 200,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.black12.withOpacity(.06), borderRadius: BorderRadius.circular(12)),
            child: const CircularProgressIndicator(strokeWidth: 2),
          );
        }
        if (snap.hasError || !snap.hasData) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black12.withOpacity(.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              children: const [
                Icon(Icons.error_outline, color: Colors.redAccent),
                SizedBox(width: 8),
                Expanded(child: Text('No se pudo obtener el contenido')),
              ],
            ),
          );
        }
        return buildFromResolved(snap.data!);
      },
    );
  }
}

class _YouTubeExternalFallback extends StatelessWidget {
  final String videoId;
  final String originalUrl;
  const _YouTubeExternalFallback({required this.videoId, required this.originalUrl});

  Future<void> _open() async {
    final uri = Uri.parse(originalUrl.isNotEmpty ? originalUrl : 'https://www.youtube.com/watch?v=$videoId');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black12.withOpacity(.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [Icon(Icons.error_outline, color: Colors.redAccent), SizedBox(width: 8), Expanded(child: Text('Reproducción embebida no soportada.'))]),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: _open, icon: const Icon(Icons.open_in_new), label: const Text('Abrir en YouTube')))
        ],
      ),
    );
  }
}

class _YouTubePlayerWeb extends StatefulWidget {
  final String videoId;
  final String originalUrl;
  const _YouTubePlayerWeb({required this.videoId, required this.originalUrl});

  @override
  State<_YouTubePlayerWeb> createState() => _YouTubePlayerWebState();
}

class _YouTubePlayerWebState extends State<_YouTubePlayerWeb> {
  yt_iframe.YoutubePlayerController? _controller;
  bool _failed = false;
  Timer? _timer;

  bool _isValidId(String id) => RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(id);

  @override
  void initState() {
    super.initState();
    if (!_isValidId(widget.videoId)) { _failed = true; return; }
    try {
      _controller = yt_iframe.YoutubePlayerController.fromVideoId(
        videoId: widget.videoId,
        params: const yt_iframe.YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          enableCaption: true,
          strictRelatedVideos: true,
          playsInline: true,
        ),
      );
      _timer = Timer(const Duration(seconds: 4), () {
        if (!mounted || _failed) return;
        final v = _controller?.value;
        if (v == null || v.metaData.duration == Duration.zero) {
          setState(() { _failed = true; });
        }
      });
    } catch (_) { _failed = true; }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.close();
    super.dispose();
  }

  Widget _error() => _YouTubeExternalFallback(videoId: widget.videoId, originalUrl: widget.originalUrl);

  @override
  Widget build(BuildContext context) {
    if (_failed || _controller == null) return _error();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(aspectRatio: 16/9, child: yt_iframe.YoutubePlayer(controller: _controller!)),
    );
  }
}

class _YouTubePlayerMobile extends StatefulWidget {
  final String videoId;
  final String originalUrl;
  const _YouTubePlayerMobile({required this.videoId, required this.originalUrl});

  @override
  State<_YouTubePlayerMobile> createState() => _YouTubePlayerMobileState();
}

class _YouTubePlayerMobileState extends State<_YouTubePlayerMobile> {
  YoutubePlayerController? _controller;
  bool _failed = false;
  bool _ready = false;
  Timer? _timer;

  bool _isValidId(String id) => RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(id);

  @override
  void initState() {
    super.initState();
    if (!_isValidId(widget.videoId)) { _failed = true; return; }
    try {
      _controller = YoutubePlayerController(
        initialVideoId: widget.videoId,
        flags: const YoutubePlayerFlags(autoPlay: false, mute: false, forceHD: false, enableCaption: true, disableDragSeek: false),
      );
      _timer = Timer(const Duration(seconds: 4), () {
        if (!mounted || _failed) return;
        if (!_ready && (_controller?.metadata.duration == Duration.zero)) {
          setState(() { _failed = true; });
        }
      });
    } catch (_) { _failed = true; }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Widget _error() => _YouTubeExternalFallback(videoId: widget.videoId, originalUrl: widget.originalUrl);

  @override
  Widget build(BuildContext context) {
    if (_failed || _controller == null) return _error();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16/9,
        child: YoutubePlayer(
          controller: _controller!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: Colors.redAccent,
          onReady: () { setState(() { _ready = true; }); },
          bottomActions: [
            const CurrentPosition(),
            const SizedBox(width: 8),
            ProgressBar(isExpanded: true),
            const RemainingDuration(),
            FullScreenButton(), // quitar const para evitar queja de const inconsistente
          ],
        ),
      ),
    );
  }
}

class _VideoPlayerWidget extends StatefulWidget {
  final String url;
  const _VideoPlayerWidget({required this.url});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _error = false;
  bool _muted = false;
  double _progress = 0.0; // 0..1

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) setState(() { _initialized = true; });
      }).catchError((_) {
        if (mounted) setState(() { _error = true; });
      });
    _controller.addListener(_onVideoTick);
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoTick);
    _controller.dispose();
    super.dispose();
  }

  void _onVideoTick() {
    if (!_controller.value.isInitialized) return;
    final dur = _controller.value.duration.inMilliseconds;
    final pos = _controller.value.position.inMilliseconds;
    if (dur > 0) {
      final newProg = pos / dur;
      // Evitar demasiados rebuilds si cambio mínimo
      if ((newProg - _progress).abs() > 0.002 && mounted) {
        setState(() { _progress = newProg.clamp(0.0, 1.0); });
      }
    }
  }

  void _togglePlay() {
    if (!_initialized) return;
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  void _toggleMute() {
    if (!_initialized) return;
    setState(() {
      _muted = !_muted;
      _controller.setVolume(_muted ? 0.0 : 1.0);
    });
  }

  void _seekRelative(double percent) {
    if (!_initialized) return;
    final dur = _controller.value.duration;
    if (dur.inMilliseconds == 0) return;
    final target = Duration(milliseconds: (dur.inMilliseconds * percent).round());
    _controller.seekTo(target);
  }

  void _openFullscreen() {
    if (!_initialized) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => _FullscreenVideo(controller: _controller, muted: _muted, onToggleMute: _toggleMute)));
  }

  Widget _buildControls() {
    if (!_initialized) return const SizedBox();
    final playing = _controller.value.isPlaying;
    final duration = _controller.value.duration;
    final position = _controller.value.position;
    String fmt(Duration d) {
      final m = d.inMinutes.remainder(60).toString().padLeft(2,'0');
      final s = d.inSeconds.remainder(60).toString().padLeft(2,'0');
      return '$m:$s';
    }
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black54.withOpacity(.65),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(playing ? Icons.pause : Icons.play_arrow, color: Colors.white),
                  onPressed: _togglePlay,
                  tooltip: playing ? 'Pausar' : 'Reproducir',
                ),
                IconButton(
                  icon: Icon(_muted ? Icons.volume_off : Icons.volume_up, color: Colors.white),
                  onPressed: _toggleMute,
                  tooltip: _muted ? 'Activar sonido' : 'Silenciar',
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.fullscreen, color: Colors.white),
                  onPressed: _openFullscreen,
                  tooltip: 'Pantalla completa',
                ),
              ],
            ),
            Row(
              children: [
                Text(fmt(position), style: const TextStyle(color: Colors.white, fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: _progress,
                    onChanged: (v) => _seekRelative(v),
                    activeColor: Colors.white,
                    inactiveColor: Colors.white30,
                  ),
                ),
                Text(fmt(duration), style: const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.black12.withOpacity(.06), borderRadius: BorderRadius.circular(12)),
        child: const Text('No se pudo reproducir el video'),
      );
    }
    if (!_initialized) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.black12.withOpacity(.06), borderRadius: BorderRadius.circular(12)),
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio == 0 ? 16/9 : _controller.value.aspectRatio,
            child: GestureDetector(
              onTap: _togglePlay,
              child: VideoPlayer(_controller),
            ),
          ),
          _buildControls(),
        ],
      ),
    );
  }
}

class _FullscreenVideo extends StatelessWidget {
  final VideoPlayerController controller;
  final bool muted;
  final VoidCallback onToggleMute;
  const _FullscreenVideo({required this.controller, required this.muted, required this.onToggleMute});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio == 0 ? 16/9 : controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(controller.value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                          onPressed: () {
                            if (controller.value.isPlaying) {
                              controller.pause();
                            } else {
                              controller.play();
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(muted ? Icons.volume_off : Icons.volume_up, color: Colors.white),
                          onPressed: onToggleMute,
                        ),
                        const Spacer(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

