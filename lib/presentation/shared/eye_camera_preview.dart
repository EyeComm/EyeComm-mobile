import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EyeCameraPreview extends StatefulWidget {
  final String currentEye;
  final String serverBase;

  const EyeCameraPreview({
    super.key,
    required this.currentEye,
    this.serverBase = 'http://127.0.0.1:5000', // شغال لوكال على الويندوز تمام
  });

  @override
  State<EyeCameraPreview> createState() => _EyeCameraPreviewState();
}

class _EyeCameraPreviewState extends State<EyeCameraPreview> {
  Uint8List? _frameBytes;
  bool _streamError = false;
  bool _connecting = true;

  late http.Client _client;
  StreamSubscription<List<int>>? _sub;

  @override
  void initState() {
    super.initState();
    _client = http.Client();
    _connectStream();
  }

  Future<void> _connectStream() async {
    if (!mounted) return;
    setState(() {
      _connecting = true;
      _streamError = false;
    });
    try {
      // ── التعديل الأساسي هنا: تم تغيير /stream إلى /video_feed ليطابق السيرفر ──
      final uri = Uri.parse('${widget.serverBase}/video_feed');
      final request = http.Request('GET', uri);
      final response =
          await _client.send(request).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        if (mounted)
          setState(() {
            _streamError = true;
            _connecting = false;
          });
        return;
      }

      if (mounted) setState(() => _connecting = false);

      final List<int> buffer = [];

      _sub = response.stream.listen(
        (chunk) {
          buffer.addAll(chunk);
          _extractFrames(buffer);
        },
        onError: (_) {
          if (mounted) setState(() => _streamError = true);
        },
        onDone: () {
          if (mounted) setState(() => _streamError = true);
        },
        cancelOnError: true,
      );
    } catch (_) {
      if (mounted)
        setState(() {
          _streamError = true;
          _connecting = false;
        });
    }
  }

  static final _jpegStart = [0xFF, 0xD8];
  static final _jpegEnd = [0xFF, 0xD9];

  void _extractFrames(List<int> buf) {
    int start = _indexOf(buf, _jpegStart, 0);
    while (start != -1) {
      int end = _indexOf(buf, _jpegEnd, start + 2);
      if (end == -1) break;

      final frameBytes = Uint8List.fromList(buf.sublist(start, end + 2));
      buf.removeRange(0, end + 2);

      if (mounted) setState(() => _frameBytes = frameBytes);
      start = _indexOf(buf, _jpegStart, 0);
    }
    if (buf.isNotEmpty) {
      final next = _indexOf(buf, _jpegStart, 0);
      if (next > 0) buf.removeRange(0, next);
    }
  }

  int _indexOf(List<int> src, List<int> pattern, int from) {
    for (int i = from; i <= src.length - pattern.length; i++) {
      bool match = true;
      for (int j = 0; j < pattern.length; j++) {
        if (src[i + j] != pattern[j]) {
          match = false;
          break;
        }
      }
      if (match) return i;
    }
    return -1;
  }

  @override
  void dispose() {
    _sub?.cancel();
    _client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_connecting) {
      return Container(
        color: const Color(0xFF0D1B2A),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                color: Colors.cyanAccent, strokeWidth: 2),
          ),
        ),
      );
    }

    if (_streamError || _frameBytes == null) {
      return Container(
        color: const Color(0xFF0D1B2A),
        child: const Center(
          child:
              Icon(Icons.videocam_off_rounded, color: Colors.white24, size: 28),
        ),
      );
    }

    return Transform.scale(
      scaleX: -1,
      child: Image.memory(
        _frameBytes!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => Container(
          color: const Color(0xFF0D1B2A),
          child: const Icon(Icons.broken_image_rounded,
              color: Colors.white24, size: 28),
        ),
      ),
    );
  }
}
