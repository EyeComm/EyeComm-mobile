import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../core/app_theme.dart';
import '../../core/voice_service.dart';
import '../../core/nav_helper.dart';
import '../language/language_selection_page.dart';

class FaceRegistrationScreen extends StatefulWidget {
  const FaceRegistrationScreen({super.key});
  @override
  State<FaceRegistrationScreen> createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen>
    with TickerProviderStateMixin {
  static const String _serverBase = 'http://127.0.0.1:5000';

  bool _isRegistering    = false;
  bool _registrationDone = false;
  bool _serverConnected  = false;
  String _statusMsg      = 'جاري الاتصال بالسيرفر...';
  int _countdown         = 7;  // ✅ 7 ثواني
  Timer? _countdownTimer;
  Timer? _checkTimer;
  bool _faceDetected = false;

  // ✅ متغيرات تتبع العين
  String _eye = 'none';
  String _stable = 'none';
  DateTime? _stableAt;
  int _cd = 0;
  bool _gestureConfirmed = false;

  Uint8List? _frameBytes;
  bool _streamError = false;
  late http.Client _streamClient;
  StreamSubscription<List<int>>? _streamSub;

  late final AnimationController _pulseCtrl;
  late final Animation<double>   _pulseAnim;
  late final AnimationController _countdownCtrl;
  late final Animation<double>   _countdownAnim;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _countdownCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),  // ✅ 7 ثواني
    );
    _countdownAnim =
        Tween<double>(begin: 1.0, end: 0.0).animate(_countdownCtrl);

    _streamClient = http.Client();
    _initServer();
  }

  Future<void> _initServer() async {
    try {
      await http.post(Uri.parse('$_serverBase/clear_face'))
          .timeout(const Duration(seconds: 3));
    } catch (_) {}
    _connectStream();
    _startChecking();
    _startEyeTracking();  // ✅ بدء تتبع العين
  }

  // ✅ تتبع العين للإيماءات
  void _startEyeTracking() {
    Timer.periodic(const Duration(milliseconds: 800), (timer) async {
      if (_isRegistering || _registrationDone || _gestureConfirmed) return;
      try {
        final r = await http
            .get(Uri.parse('$_serverBase/predict'))
            .timeout(const Duration(seconds: 3));
        if (r.statusCode == 200 && mounted) {
          final data = jsonDecode(r.body);
          final String eye = data['prediction'] as String? ?? 'none';
          setState(() {
            _eye = eye;
          });

          // ✅ لو النظر يمين لمدة 7 ثواني → يبدأ التسجيل
          if (eye == 'right' || eye == 'left') {
            if (eye == _stable) {
              final int elapsed = DateTime.now().difference(_stableAt!).inSeconds;
              final int remaining = 7 - elapsed;
              setState(() => _cd = remaining.clamp(0, 7));
              if (elapsed >= 7) {
                _stable = 'none';
                _stableAt = null;
                _cd = 0;
                _gestureConfirmed = true;
                timer.cancel();
                // ✅ بدأ التسجيل بالإيماءة
                _startRegistration();
              }
            } else {
              setState(() {
                _stable = eye;
                _stableAt = DateTime.now();
                _cd = 7;
              });
            }
          } else {
            setState(() {
              _stable = 'none';
              _stableAt = null;
              _cd = 0;
            });
          }
        }
      } catch (_) {}
    });
  }

  void _connectStream() async {
    try {
      final uri     = Uri.parse('$_serverBase/video_feed');
      final request = http.Request('GET', uri);
      final response =
          await _streamClient.send(request).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        if (mounted) setState(() => _streamError = true);
        return;
      }
      if (mounted) setState(() { _serverConnected = true; _streamError = false; });
      final List<int> buffer = [];
      _streamSub = response.stream.listen(
        (chunk) { buffer.addAll(chunk); _extractFrames(buffer); },
        onError: (_) { if (mounted) setState(() => _streamError = true); },
        onDone:  () { if (mounted) setState(() => _streamError = true); },
        cancelOnError: true,
      );
    } catch (_) {
      if (mounted) setState(() { _streamError = true; _serverConnected = false; });
    }
  }

  static final _jpegStart = [0xFF, 0xD8];
  static final _jpegEnd   = [0xFF, 0xD9];

  void _extractFrames(List<int> buf) {
    int start = _indexOf(buf, _jpegStart, 0);
    while (start != -1) {
      int end = _indexOf(buf, _jpegEnd, start + 2);
      if (end == -1) break;
      final fb = Uint8List.fromList(buf.sublist(start, end + 2));
      buf.removeRange(0, end + 2);
      if (mounted) setState(() => _frameBytes = fb);
      start = _indexOf(buf, _jpegStart, 0);
    }
    if (buf.isNotEmpty) {
      final next = _indexOf(buf, _jpegStart, 0);
      if (next > 0) buf.removeRange(0, next);
    }
  }

  int _indexOf(List<int> src, List<int> pat, int from) {
    for (int i = from; i <= src.length - pat.length; i++) {
      bool ok = true;
      for (int j = 0; j < pat.length; j++) {
        if (src[i + j] != pat[j]) { ok = false; break; }
      }
      if (ok) return i;
    }
    return -1;
  }

  void _startChecking() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_isRegistering || _registrationDone) return;
      try {
        final r = await http
            .get(Uri.parse('$_serverBase/face_status'))
            .timeout(const Duration(seconds: 2));
        if (r.statusCode == 200 && mounted) {
          final data = jsonDecode(r.body);
          setState(() {
            _serverConnected = true;
            _faceDetected    = data['face_detected'] ?? false;
            _statusMsg = _faceDetected
                ? '👁️ انظر يمين لمدة 7 ثواني للتسجيل'
                : 'ضع وجهك أمام الكاميرا...';
          });
        }
      } catch (_) {
        if (mounted) setState(() { _serverConnected = false; _faceDetected = false; });
      }
    });
  }

  Future<void> _startRegistration() async {
    if (_isRegistering) return;
    setState(() { _isRegistering = true; _countdown = 7; _statusMsg = '⏳ اضبط وجهك... 7'; });
    await VoiceService.speak('استعد');
    _countdownCtrl.reset();
    _countdownCtrl.forward();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (_countdown > 1) {
        _countdown--;
        if (mounted) {
          setState(() => _statusMsg = '⏳ اضبط وجهك... $_countdown');
          await VoiceService.speak(_countdown.toString());
        }
      } else {
        t.cancel();
        if (mounted) setState(() => _statusMsg = '📸 جاري التقاط الصورة...');
        await VoiceService.speak('التقاط');
        await _doRegister();
      }
    });
  }

  Future<void> _doRegister() async {
    if (!mounted) return;
    try {
      final r = await http
          .post(Uri.parse('$_serverBase/register_face'))
          .timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        if (data['success'] == true) {
          _checkTimer?.cancel();
          if (mounted) setState(() { _registrationDone = true; _isRegistering = false; _statusMsg = '✅ تم التسجيل بنجاح!'; });
          await VoiceService.speak('تم');
          await Future.delayed(const Duration(milliseconds: 800));
          await VoiceService.speak('أهلاً بك');
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) pushReplacement(context, const LanguageSelectionPage());
        } else {
          _onError(data['message'] ?? 'فشل، حاول مرة أخرى');
        }
      } else {
        _onError('خطأ في السيرفر');
      }
    } catch (_) {
      _onError('تعذر الاتصال بالسيرفر');
    }
  }

  void _onError(String msg) {
    if (!mounted) return;
    setState(() { _isRegistering = false; _statusMsg = msg; });
    VoiceService.speak(msg);
    _countdownCtrl.reset();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _countdownCtrl.dispose();
    _countdownTimer?.cancel();
    _checkTimer?.cancel();
    _streamSub?.cancel();
    _streamClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isWide = size.width > 700;

    return Scaffold(
      backgroundColor: kBg1,
      body: SafeArea(
        child: isWide ? _buildWideLayout() : _buildNarrowLayout(),
      ),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: _buildRegistrationPanel(),
        ),
        Container(
          width: 1,
          margin: const EdgeInsets.symmetric(vertical: 32),
          color: kBorder1,
        ),
        Expanded(
          flex: 5,
          child: _buildLogoPanel(),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildLogoPanel(compact: true),
          const Divider(height: 1),
          _buildRegistrationPanel(),
        ],
      ),
    );
  }

  Widget _buildLogoPanel({bool compact = false}) {
    return Container(
      padding: EdgeInsets.all(compact ? 24 : 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width:  compact ? 100 : 160,
            height: compact ? 100 : 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: const Color(0xFF2B8EE8), width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2B8EE8).withOpacity(0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/logo.jpeg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFE8F4FF),
                  child: const Icon(Icons.remove_red_eye_rounded,
                      color: Color(0xFF2B8EE8), size: 70),
                ),
              ),
            ),
          ),
          SizedBox(height: compact ? 16 : 28),
          Text(
            'EyeComm',
            style: GoogleFonts.orbitron(
              color: const Color(0xFF2B8EE8),
              fontSize: compact ? 26 : 36,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          SizedBox(height: compact ? 8 : 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF2B8EE8).withOpacity(0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFF2B8EE8).withOpacity(0.2)),
            ),
            child: Text(
              'An Intelligent Eye-Tracking\nCommunication System\nfor ALS and Quadriplegic Patients',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                color: const Color(0xFF1E3A5F),
                fontSize: compact ? 13 : 15,
                fontWeight: FontWeight.w700,
                height: 1.6,
              ),
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 28),
            _featureRow(Icons.visibility_rounded, 'تتبع العين بـ 5 اتجاهات'),
            const SizedBox(height: 10),
            _featureRow(Icons.home_rounded, 'التحكم في المنزل الذكي'),
            const SizedBox(height: 10),
            _featureRow(Icons.accessible_rounded, 'الكرسي المتحرك بالعين'),
            const SizedBox(height: 10),
            _featureRow(Icons.face_retouching_natural, 'تعرف ذكي على الوجه'),
          ],
        ],
      ),
    );
  }

  Widget _featureRow(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: const Color(0xFF2B8EE8), size: 18),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.cairo(
            color: const Color(0xFF64748B),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationPanel() {
    final bool isEyeActive = _stable == 'right' && _cd > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'تسجيل الوجه',
            style: GoogleFonts.cairo(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: kTextMain,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '👁️ انظر يمين لمدة 7 ثواني للتسجيل',
            style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          ScaleTransition(
            scale: _pulseAnim,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 230,
                  height: 230,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                    border: Border.all(
                      color: isEyeActive
                          ? const Color(0xFF00C853)
                          : _faceDetected
                              ? const Color(0xFF2B8EE8)
                              : Colors.red,
                      width: isEyeActive ? 5 : 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isEyeActive
                                ? const Color(0xFF00C853)
                                : _faceDetected
                                    ? const Color(0xFF2B8EE8)
                                    : Colors.red)
                            .withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: ClipOval(child: _buildCameraView()),
                ),
                // ✅ عداد 7 ثواني
                if (_isRegistering && !_registrationDone)
                  SizedBox(
                    width: 238,
                    height: 238,
                    child: AnimatedBuilder(
                      animation: _countdownAnim,
                      builder: (_, __) => CircularProgressIndicator(
                        value: _countdownAnim.value,
                        strokeWidth: 5,
                        backgroundColor: Colors.transparent,
                        color: const Color(0xFF00C853),
                      ),
                    ),
                  ),
                // ✅ مؤشر الإيماءة
                if (isEyeActive && !_isRegistering)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '👁️ $_cd',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isEyeActive
                  ? const Color(0xFF00C853).withOpacity(0.2)
                  : _faceDetected
                      ? const Color(0xFF2B8EE8).withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isEyeActive
                    ? const Color(0xFF00C853)
                    : _faceDetected
                        ? const Color(0xFF2B8EE8)
                        : Colors.orange,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isEyeActive
                      ? Icons.visibility
                      : _faceDetected
                          ? Icons.face_retouching_natural
                          : Icons.face_retouching_off,
                  color: isEyeActive
                      ? const Color(0xFF00C853)
                      : _faceDetected
                          ? const Color(0xFF2B8EE8)
                          : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isEyeActive
                      ? '👁️ $_cd ثانية'
                      : _faceDetected
                          ? '✅ وجهك ظاهر - انظر يمين'
                          : '⏳ ضع وجهك أمام الكاميرا...',
                  style: GoogleFonts.cairo(
                    color: isEyeActive
                        ? const Color(0xFF00C853)
                        : _faceDetected
                            ? const Color(0xFF2B8EE8)
                            : Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Text(
            _statusMsg,
            style: GoogleFonts.cairo(
                fontSize: 15, color: kTextMain, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          if (_registrationDone) ...[
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFF00C853), size: 60),
            const SizedBox(height: 10),
            Text(
              'تم! جاري الدخول...',
              style: GoogleFonts.cairo(
                  color: const Color(0xFF00C853),
                  fontSize: 17,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    if (!_serverConnected || _streamError || _frameBytes == null) {
      return Container(
        color: const Color(0xFF1E1E24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined,
                color: Colors.white38, size: 42),
            const SizedBox(height: 8),
            Text(
              _serverConnected ? 'جاري تحميل البث...' : 'انتظار السيرفر...',
              style: GoogleFonts.cairo(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      );
    }
    return Image.memory(
      _frameBytes!,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
    );
  }
}