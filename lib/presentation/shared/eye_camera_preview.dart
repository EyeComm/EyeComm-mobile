import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EyeCameraPreview extends StatefulWidget {
  final String serverBase;
  final String stableDirection;

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

  // ✅ منع محاولات إعادة الاتصال المتزامنة/المتداخلة
  bool _disposed = false;
  Timer? _retryTimer;
  int _retryAttempt = 0;

  late String _currentDirection;

  @override
  void initState() {
    super.initState();
    _currentDirection = widget.stableDirection;
    _client = http.Client();
    _connectStream();
  }

  @override
  void didUpdateWidget(covariant EyeCameraPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stableDirection != widget.stableDirection) {
      setState(() => _currentDirection = widget.stableDirection);
    }
    if (oldWidget.serverBase != widget.serverBase) {
      _restartConnection();
    }
  }

  void _restartConnection() {
    _retryTimer?.cancel();
    _sub?.cancel();
    _sub = null;
    try {
      _client.close();
    } catch (_) {}
    _client = http.Client();
    _retryAttempt = 0;
    _connectStream();
  }

  // ✅ إعادة الاتصال تلقائياً بعد أي خطأ أو انقطاع، بدل ما تفضل الصورة
  // سوداء للأبد لحد ما المستخدم يخرج ويدخل الصفحة تاني.
  void _scheduleRetry() {
    if (_disposed) return;
    _retryTimer?.cancel();

    // ✅ backoff بسيط: 1s, 2s, 3s... لحد أقصى 5s، عشان منضغطش على
    // السيرفر بمحاولات متلاحقة لو فيه مشكلة مستمرة.
    _retryAttempt++;
    final int delaySeconds = _retryAttempt.clamp(1, 5);

    _retryTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_disposed && mounted) {
        _connectStream();
      }
    });
  }

  Future<void> _connectStream() async {
    if (!mounted || _disposed) return;

    // ✅ تنظيف أي اشتراك قديم قبل ما نفتح اتصال جديد، عشان مانخليش
    // اتصالات قديمة مفتوحة على السيرفر (وده كان بيستهلك من الحد
    // الأقصى لعدد عملاء الفيديو على السيرفر بدون داعي).
    await _sub?.cancel();
    _sub = null;

    setState(() {
      _connecting = true;
      _streamError = false;
    });

    try {
      final uri = Uri.parse('${widget.serverBase}/video_feed');
      final request = http.Request('GET', uri);
      final response = await _client.send(request).timeout(const Duration(seconds: 8));

      if (!mounted || _disposed) return;

      if (response.statusCode != 200) {
        setState(() { _streamError = true; _connecting = false; });
        _scheduleRetry();
        return;
      }

      setState(() => _connecting = false);
      _retryAttempt = 0; // ✅ نجح الاتصال، نصفّر عداد المحاولات
      final List<int> buffer = [];

      _sub = response.stream.listen(
        (chunk) {
          buffer.addAll(chunk);
          _extractFrames(buffer);
        },
        onError: (_) {
          if (!mounted || _disposed) return;
          setState(() => _streamError = true);
          _scheduleRetry();
        },
        onDone: () {
          if (!mounted || _disposed) return;
          setState(() => _streamError = true);
          _scheduleRetry();
        },
        cancelOnError: true,
      );
    } catch (_) {
      if (!mounted || _disposed) return;
      setState(() { _streamError = true; _connecting = false; });
      _scheduleRetry();
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
      if (mounted && !_disposed) {
        setState(() => _frameBytes = frameBytes);
      }
      start = _indexOf(buf, _jpegStart, 0);
    }
    if (buf.isNotEmpty) {
      final next = _indexOf(buf, _jpegStart, 0);
      if (next > 0) buf.removeRange(0, next);
    }
    // ✅ حماية إضافية: لو الـ buffer كبر جداً من غير ما نلاقي فريم كامل
    // (مثلاً بيانات تالفة)، نفضّيه بدل ما يفضل يكبر ويبطّئ التطبيق.
    if (buf.length > 2 * 1024 * 1024) {
      buf.clear();
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
    _disposed = true;
    _retryTimer?.cancel();
    _sub?.cancel();
    _client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ حالة الاتصال الأولى فقط (مفيش فريم اتعرض قبل كده)
    if (_connecting && _frameBytes == null) {
      return Container(
        color: const Color(0xFF1E1E24),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
          ),
        ),
      );
    }

    // ✅ في حالة الخطأ: لو عندنا آخر فريم اتعرض قبل كده، نفضل نوريه
    // (بدل شاشة سودا فجأة) لحد ما إعادة الاتصال التلقائي تنجح.
    if (_streamError && _frameBytes == null) {
      return Container(
        color: const Color(0xFF1E1E24),
        child: const Center(
          child: Icon(Icons.videocam_off_rounded, color: Colors.white24, size: 34),
        ),
      );
    }

    if (_frameBytes == null) {
      return Container(
        color: const Color(0xFF1E1E24),
        child: const Center(
          child: Icon(Icons.videocam_off_rounded, color: Colors.white24, size: 34),
        ),
      );
    }

    final String? eyeAsset = _assetForEye(_currentDirection);
    final Color eyeColor = _colorForEye(_currentDirection);

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(
            _frameBytes!,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.black,
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.white24, size: 40),
                ),
              );
            },
          ),

          if (_currentDirection != 'none' && eyeAsset != null)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
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
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: eyeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}