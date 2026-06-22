import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../core/app_theme.dart';
import '../core/eye_utils.dart';
import '../core/language_service.dart';
import '../core/voice_service.dart';
import '../core/emergency_service.dart';
import 'dynamic_eye_card.dart';
import 'modern_tracking_quality_bar.dart';
import 'tracking_camera_card.dart';

class BaseGridPage extends StatefulWidget {
  final String title;
  final Color color;
  final List<Map<String, dynamic>> items;
  final int timerSeconds;
  final Future<void> Function(String eye, BuildContext ctx)? onAction;

  final Widget Function(
      BuildContext context,
      int index,
      Map<String, dynamic> item,
      String stable,
      int cd,
      int totalTimer)? itemBuilder;

  final bool isMainScreen;
  final String warningMsg;
  final Color warningColor;
  final VoidCallback? onLangTap;

  final String serverBase;

  final String? currentEye;
  final String? stableDirection;
  final int? countdownSeconds;

  final bool showCameraCard;
  final double cameraCardAspectRatio;

  const BaseGridPage({
    super.key,
    required this.title,
    required this.color,
    required this.items,
    this.timerSeconds = 7,
    this.onAction,
    this.itemBuilder,
    this.isMainScreen = false,
    this.warningMsg = '',
    this.warningColor = Colors.transparent,
    this.onLangTap,
    this.serverBase = 'http://127.0.0.1:5000',
    this.currentEye,
    this.stableDirection,
    this.countdownSeconds,
    this.showCameraCard = false,
    this.cameraCardAspectRatio = 1.0,
  });

  @override
  State<BaseGridPage> createState() => _BaseGridPageState();
}

class _BaseGridPageState extends State<BaseGridPage> {
  String _eye = 'none';
  bool _connected = false;
  int _cd = 0;
  String _stable = 'none';
  DateTime? _stableAt;
  Timer? _pollTimer;
  Timer? _dialogTimer;
  bool _busy = false;

  late DateTime _cooldownUntil;
  bool _isActive = true;

  // مهم: لمنع تنفيذ أوامر بعد الخروج
  bool _isDisposed = false;

  // ✅ هل البيج دي بتستخدم Cubit خارجي (currentEye جاي من برّه)؟
  bool get _isExternallyDriven => widget.currentEye != null;

  // ✅ لمنع تكرار النطق
  String _lastSpokenStable = 'none';

  @override
  void initState() {
    super.initState();
    _cooldownUntil = DateTime.now().add(const Duration(milliseconds: 1500));
    if (!_isExternallyDriven) {
      _startPoll();
    }
  }

  @override
  void didUpdateWidget(covariant BaseGridPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ✅ الصفحات الخارجية مش محتاجة نطق هنا لأن النطق بيحصل في الـ Cubit
  }

  void _startPoll() {
    _pollTimer?.cancel();
    _isActive = true;
    _isDisposed = false;
    _stable = 'none';
    _stableAt = null;
    _cd = 0;
    _lastSpokenStable = 'none';
    _pollTimer =
        Timer.periodic(const Duration(milliseconds: 800), (_) => _poll());
  }

  void stopPolling() {
    _isActive = false;
    _isDisposed = true;
    _pollTimer?.cancel();
    _pollTimer = null;
    _stable = 'none';
    _stableAt = null;
    _cd = 0;
    if (mounted) {
      setState(() {
        _eye = 'none';
        _stable = 'none';
        _cd = 0;
      });
    }
  }

  Future<void> _poll() async {
    // التأكد أن الصفحة لسه مفتوحة ونشطة
    if (!mounted || !_isActive || _isDisposed) return;

    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) {
      // الصفحة مش الحالية، نوقف القراءة
      stopPolling();
      return;
    }

    if (DateTime.now().isBefore(_cooldownUntil)) {
      if (_stable != 'none') {
        setState(() { _stable = 'none'; _stableAt = null; _cd = 0; });
      }
      return;
    }

    if (_busy) return;
    _busy = true;
    try {
      final r = await http
          .get(Uri.parse('${widget.serverBase}/predict'))
          .timeout(const Duration(seconds: 4));

      if (!mounted || !_isActive || _isDisposed) return;

      if (r.statusCode == 200) {
        final body = jsonDecode(r.body);
        final String eye = body['prediction'] as String? ?? 'none';
        setState(() {
          _eye = eye;
          _connected = true;
        });
        EmergencyDetector.recordMovement();

        if (eye != 'none') {
          if (eye == _stable) {
            final int diff = DateTime.now().difference(_stableAt!).inSeconds;
            final int nc = widget.timerSeconds - diff;
            if (nc != _cd) setState(() => _cd = nc.clamp(0, widget.timerSeconds));
            if (diff >= widget.timerSeconds) {
              _pollTimer?.cancel();
              _cooldownUntil = DateTime.now().add(const Duration(milliseconds: 1500));
              // التأكد أن الصفحة لسه مفتوحة قبل التنفيذ
              if (mounted && _isActive && !_isDisposed) {
                _execute(eye);
              }
              _stable = 'none';
              _stableAt = null;
              _cd = 0;
            }
          } else {
            setState(() {
              _stable = eye;
              _stableAt = DateTime.now();
              _cd = widget.timerSeconds;
            });
            
            // ✅ نطق اسم الزرار عند الاستقرار (مرة واحدة بس)
            // للصفحات اللي مش بتستخدم Cubit خارجي
            if (!_isExternallyDriven && eye != _lastSpokenStable) {
              final item = widget.items.firstWhere(
                (e) => e['eye'] == eye,
                orElse: () => {},
              );
              if (item.isNotEmpty && item['text'] != null) {
                VoiceService.speak(cleanForSpeech(item['text'].toString()));
                _lastSpokenStable = eye;
              }
            }
          }
        } else {
          setState(() { _stable = 'none'; _stableAt = null; _cd = 0; });
          _lastSpokenStable = 'none';
        }
      } else {
        setState(() => _connected = false);
      }
    } catch (_) {
      if (mounted) setState(() => _connected = false);
    } finally {
      _busy = false;
    }
  }

  void _execute(String eye) async {
    // التأكد أن الصفحة لسه مفتوحة
    if (!mounted || !_isActive || _isDisposed) return;

    final item =
        widget.items.firstWhere((e) => e['eye'] == eye, orElse: () => {});

    if (widget.onAction != null) {
      await widget.onAction!(eye, context);
      // التأكد أن الصفحة لسه مفتوحة قبل إعادة تشغيل القراءة
      if (mounted && _isActive && !_isDisposed) {
        _startPoll();
      }
      return;
    }

    if (eye == 'down' || eye == 'closed') {
      if (mounted && Navigator.canPop(context)) {
        stopPolling();
        Navigator.pop(context);
      }
      return;
    }
    if (item.isNotEmpty) {
      _showConfirmDialog(item['text'].toString());
      if (mounted && _isActive && !_isDisposed) {
        _startPoll();
      }
    }
  }

  void _showConfirmDialog(String msg) {
    _dialogTimer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: widget.color, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 52),
            const SizedBox(height: 10),
            Text(AppLanguage.t('confirmed'),
                style: GoogleFonts.cairo(
                    color: Colors.green, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(msg,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(color: kTextMain1, fontSize: 17)),
          ]),
        ),
      ),
    );
    _dialogTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _isActive = false;
    _isDisposed = true;
    _pollTimer?.cancel();
    _dialogTimer?.cancel();
    super.dispose();
  }

  Widget _safeCard(int i, String stable, int cd) {
    if (widget.showCameraCard && i == 0) {
      return AspectRatio(
        aspectRatio: widget.cameraCardAspectRatio,
        child: TrackingCameraCard(
          currentEye: stable,
          serverBase: widget.serverBase,
          accentColor: widget.color,
          showGestureLabel: true,
        ),
      );
    }

    final int actualItemIndex = widget.showCameraCard ? i - 1 : i;
    if (actualItemIndex >= widget.items.length) return const SizedBox();

    final currentItem = widget.items[actualItemIndex];

    return widget.itemBuilder != null
        ? widget.itemBuilder!(context, actualItemIndex, currentItem, stable, cd, widget.timerSeconds)
        : DynamicEyeCard(item: currentItem, stable: stable, cd: cd, totalTimer: widget.timerSeconds);
  }

  int _getTotalCards() => widget.items.length + (widget.showCameraCard ? 1 : 0);

  Widget _portraitGrid(double gap, String stable, int cd) {
    final len = _getTotalCards();
    return Column(children: [
      Expanded(child: Row(children: [
        Expanded(flex: 2, child: _safeCard(0, stable, cd)),
        SizedBox(width: gap),
        Expanded(flex: 2, child: _safeCard(1, stable, cd)),
      ])),
      if (len > 2) ...[
        SizedBox(height: gap),
        Expanded(child: Row(children: [
          if (len == 3) ...[
            const Expanded(flex: 1, child: SizedBox()),
            Expanded(flex: 2, child: _safeCard(2, stable, cd)),
            const Expanded(flex: 1, child: SizedBox()),
          ] else ...[
            Expanded(flex: 2, child: _safeCard(2, stable, cd)),
            SizedBox(width: gap),
            Expanded(flex: 2, child: _safeCard(3, stable, cd)),
          ]
        ])),
      ],
      if (len > 4) ...[
        SizedBox(height: gap),
        Expanded(child: Row(children: [
          const Expanded(flex: 1, child: SizedBox()),
          Expanded(flex: 2, child: _safeCard(4, stable, cd)),
          const Expanded(flex: 1, child: SizedBox()),
        ])),
      ]
    ]);
  }

  Widget _wideGrid(double gap, String stable, int cd) {
    final len = _getTotalCards();
    return Column(children: [
      Expanded(child: Row(children: [
        Expanded(flex: 2, child: _safeCard(0, stable, cd)),
        SizedBox(width: gap),
        Expanded(flex: 2, child: _safeCard(1, stable, cd)),
        SizedBox(width: gap),
        Expanded(flex: 2, child: _safeCard(2, stable, cd)),
      ])),
      if (len > 3) ...[
        SizedBox(height: gap),
        Expanded(child: Row(children: [
          Expanded(flex: 2, child: _safeCard(3, stable, cd)),
          SizedBox(width: gap),
          Expanded(flex: 2, child: _safeCard(4, stable, cd)),
          SizedBox(width: gap),
          Expanded(flex: 2, child: _safeCard(5, stable, cd)),
        ])),
      ],
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final bool ar = AppLanguage.current == 'ar';
    final String effectiveEye = widget.currentEye ?? _eye;
    final String effectiveStable = widget.stableDirection ?? _stable;
    final int effectiveCd = widget.countdownSeconds ?? _cd;

    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: kBg1,
        body: SafeArea(
          child: Column(children: [
            if (widget.warningMsg.isNotEmpty)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                color: widget.warningColor,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                child: Text(widget.warningMsg,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                        color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            const SizedBox(height: 4),
            ModernTrackingQualityBar(
              currentEye: effectiveEye,
              stableDirection: effectiveStable,
              countdownSeconds: effectiveCd,
              totalTimer: widget.timerSeconds,
              serverBase: widget.serverBase,
              activeColor: widget.color,
              pageTitle: widget.title,
              isMainScreen: widget.isMainScreen,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: LayoutBuilder(builder: (ctx, screen) {
                final bool wide = screen.maxWidth > 600 || screen.maxWidth > screen.maxHeight;
                final double gap = (screen.maxWidth * 0.025).clamp(8.0, 24.0);
                final double pad = (screen.maxWidth * 0.03).clamp(12.0, 32.0);
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: pad, vertical: pad / 2),
                  child: wide
                      ? _wideGrid(gap, effectiveStable, effectiveCd)
                      : _portraitGrid(gap, effectiveStable, effectiveCd),
                );
              }),
            ),
          ]),
        ),
      ),
    );
  }
}