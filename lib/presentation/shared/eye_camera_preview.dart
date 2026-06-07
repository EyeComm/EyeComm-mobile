import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EyeCameraPreview extends StatefulWidget {
  final String serverBase;
  final String stableDirection; // ⬅️ مررنا الاتجاه الحالي لمطابقة الأيقونة واللون

  const EyeCameraPreview({
    super.key,
    this.serverBase = 'http://127.0.0.1:5000',
    this.stableDirection = 'none',
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
      final uri = Uri.parse('${widget.serverBase}/video_feed');
      final request = http.Request('GET', uri);
      final response = await _client.send(request).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        if (mounted) setState(() { _streamError = true; _connecting = false; });
        return;
      }

      if (mounted) setState(() => _connecting = false);
      final List<int> buffer = [];

      _sub = response.stream.listen(
            (chunk) {
          buffer.addAll(chunk);
          _extractFrames(buffer);
        },
        onError: (_) { if (mounted) setState(() => _streamError = true); },
        onDone: () { if (mounted) setState(() => _streamError = true); },
        cancelOnError: true,
      );
    } catch (_) {
      if (mounted) setState(() { _streamError = true; _connecting = false; });
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
        if (src[i + j] != pattern[j]) { match = false; break; }
      }
      if (match) return i;
    }
    return -1;
  }

  // 🎯 جلب مسار الأيقونة النظيفة الموحدة للتطبيق
  String? _assetForEye(String cmd) {
    switch (cmd) {
      case 'left':   return 'assets/look-left.png';
      case 'right':  return 'assets/look-right.png';
      case 'up':     return 'assets/look-up.png';
      case 'down':   return 'assets/look-down.png';
      case 'closed': return 'assets/close.png';
      default:       return null;
    }
  }

  // 🎨 نفس باليتة الألوان المريحة للعين المتطابقة مع الكروت
  Color _colorForEye(String cmd) {
    switch (cmd) {
      case 'left':   return const Color(0xFF2B8EE8);
      case 'right':  return const Color(0xFFF9A825);
      case 'up':     return const Color(0xFFE53935);
      case 'down':   return const Color(0xFF7E57C2);
      case 'closed': return const Color(0xFF78909C);
      default:       return const Color(0xFF4CAF50);
    }
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
        color: const Color(0xFF1E1E24),
        child: const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue))),
      );
    }

    if (_streamError || _frameBytes == null) {
      return Container(
        color: const Color(0xFF1E1E24),
        child: const Center(child: Icon(Icons.videocam_off_rounded, color: Colors.white24, size: 34)),
      );
    }

    final String? eyeAsset = _assetForEye(widget.stableDirection);
    final Color eyeColor = _colorForEye(widget.stableDirection);

    return Stack(
      children: [
        // بث الكاميرا الأساسي
        Positioned.fill(
          child: Image.memory(
            _frameBytes!,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            filterQuality: FilterQuality.high,
          ),
        ),

        // 🎯 غطاء علوي ناعم (شريط ذكي ومطفي يخفي الكتابة القديمة ويظهر اتجاهك بنظافة)
        if (widget.stableDirection != 'none' && eyeAsset != null)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65), // خلفية داكنة معتمة لمسح أي تشتيت خلفها
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: eyeColor.withOpacity(0.4), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    eyeAsset,
                    width: 16,
                    height: 16,
                    color: eyeColor,
                    colorBlendMode: BlendMode.srcIn,
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: eyeColor),
                  )
                ],
              ),
            ),
          ),
      ],
    );
  }
}