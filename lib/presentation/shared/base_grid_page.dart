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

class BaseGridPage extends StatefulWidget {
  final String title;
  final Color  color;
  final List<Map<String, dynamic>> items;
  final int    timerSeconds;
  final Future<void> Function(String eye, BuildContext ctx)? onAction;

  final Widget Function(BuildContext context, int index, Map<String, dynamic> item, String stable, int cd, int totalTimer)? itemBuilder;

  final bool        isMainScreen;
  final String      warningMsg;
  final Color       warningColor;
  final VoidCallback? onLangTap;

  final String serverBase;

  const BaseGridPage({
    super.key,
    required this.title,
    required this.color,
    required this.items,
    this.timerSeconds  = 5,
    this.onAction,
    this.itemBuilder,
    this.isMainScreen  = false,
    this.warningMsg    = '',
    this.warningColor  = Colors.transparent,
    this.onLangTap,
    this.serverBase    = 'http://127.0.0.1:5000',
  });

  @override
  State<BaseGridPage> createState() => _BaseGridPageState();
}

class _BaseGridPageState extends State<BaseGridPage> {
  String    _eye       = 'none';
  bool      _connected = false;
  int       _cd        = 0;
  String    _stable    = 'none';
  DateTime? _stableAt;
  Timer?    _pollTimer;
  Timer?    _dialogTimer;
  bool      _busy      = false;

  @override
  void initState() {
    super.initState();
    _startPoll();
  }

  void _startPoll() {
    _pollTimer?.cancel();
    _stable   = 'none';
    _stableAt = null;
    _cd       = 0;
    _pollTimer = Timer.periodic(
        const Duration(milliseconds: 800), (_) => _poll());
  }

  Future<void> _poll() async {
    if (!mounted || !ModalRoute.of(context)!.isCurrent) return;

    if (_busy) return;
    _busy = true;
    try {
      final r = await http
          .get(Uri.parse('${widget.serverBase}/predict'))
          .timeout(const Duration(seconds: 4));
      if (!mounted) return;

      if (r.statusCode == 200) {
        final String eye =
            jsonDecode(r.body)['prediction'] as String? ?? 'none';
        setState(() { _eye = eye; _connected = true; });
        EmergencyDetector.recordMovement();

        if (eye != 'none') {
          if (eye == _stable) {
            final int diff =
                DateTime.now().difference(_stableAt!).inSeconds;
            final int nc = widget.timerSeconds - diff;
            if (nc != _cd) setState(() => _cd = nc.clamp(0, widget.timerSeconds));
            if (diff >= widget.timerSeconds) {
              _pollTimer?.cancel();
              _execute(eye);
              _stable   = 'none';
              _stableAt = null;
              _cd       = 0;
            }
          } else {
            setState(() {
              _stable   = eye;
              _stableAt = DateTime.now();
              _cd       = widget.timerSeconds;
            });
          }
        } else {
          setState(() { _stable = 'none'; _stableAt = null; _cd = 0; });
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
    final item = widget.items.firstWhere(
            (e) => e['eye'] == eye, orElse: () => {});
    if (item.isNotEmpty) {
      VoiceService.speak(cleanForSpeech(item['text'].toString()));
    }

    if (widget.onAction != null) {
      await widget.onAction!(eye, context);
      if (mounted) _startPoll();
      return;
    }

    if (eye == 'down') {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      return;
    }
    if (item.isNotEmpty) {
      _showConfirmDialog(item['text'].toString());
      if (mounted) _startPoll();
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
                    color: Colors.green, fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(msg, textAlign: TextAlign.center,
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
    _pollTimer?.cancel();
    _dialogTimer?.cancel();
    super.dispose();
  }

  Widget _safeCard(int i) {
    if (i >= widget.items.length) return const SizedBox();

    if (widget.itemBuilder != null) {
      return widget.itemBuilder!(context, i, widget.items[i], _stable, _cd, widget.timerSeconds);
    }

    return DynamicEyeCard(
        item: widget.items[i], stable: _stable,
        cd: _cd, totalTimer: widget.timerSeconds);
  }

  Widget _portraitGrid(double gap) {
    final len = widget.items.length;
    return Column(children: [
      Expanded(child: Row(children: [
        Expanded(flex: 2, child: _safeCard(0)), SizedBox(width: gap),
        Expanded(flex: 2, child: _safeCard(1)),
      ])),
      if (len > 2) ...[
        SizedBox(height: gap),
        Expanded(child: Row(children: [
          if (len == 3) ...[
            const Expanded(flex: 1, child: SizedBox()),
            Expanded(flex: 2, child: _safeCard(2)),
            const Expanded(flex: 1, child: SizedBox()),
          ] else ...[
            Expanded(flex: 2, child: _safeCard(2)), SizedBox(width: gap),
            Expanded(flex: 2, child: _safeCard(3)),
          ]
        ])),
      ],
      if (len > 4) ...[
        SizedBox(height: gap),
        Expanded(child: Row(children: [
          const Expanded(flex: 1, child: SizedBox()),
          Expanded(flex: 2, child: _safeCard(4)),
          const Expanded(flex: 1, child: SizedBox()),
        ])),
      ]
    ]);
  }

  Widget _wideGrid(double gap) {
    final len = widget.items.length;
    return Column(children: [
      Expanded(child: Row(children: [
        Expanded(flex: 2, child: _safeCard(0)), SizedBox(width: gap),
        Expanded(flex: 2, child: _safeCard(1)), SizedBox(width: gap),
        Expanded(flex: 2, child: _safeCard(2)),
      ])),
      if (len > 3) ...[
        SizedBox(height: gap),
        Expanded(child: Row(children: [
          if (len == 4) ...[
            const Expanded(flex: 2, child: SizedBox()), SizedBox(width: gap),
            Expanded(flex: 2, child: _safeCard(3)), SizedBox(width: gap),
            const Expanded(flex: 2, child: SizedBox()),
          ] else ...[
            const Expanded(flex: 1, child: SizedBox()),
            Expanded(flex: 2, child: _safeCard(3)), SizedBox(width: gap),
            Expanded(flex: 2, child: _safeCard(4)),
            const Expanded(flex: 1, child: SizedBox()),
          ]
        ])),
      ]
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final bool ar = AppLanguage.current == 'ar';

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
                padding: const EdgeInsets.symmetric(
                    vertical: 6, horizontal: 16),
                child: Text(widget.warningMsg,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                        color: Colors.white, fontSize: 14,
                        fontWeight: FontWeight.bold)),
              ),

            // 🎯 تم إزالة الهيدر بالكامل من هنا لتوفر الطول للكاميرا والـ Grid
            const SizedBox(height: 4),

            // 🎯 نمرر تفاصيل الصفحة الحالية للبار ليصنع الـ Breadcrumbs والتاريخ داخلياً
            ModernTrackingQualityBar(
              currentEye: _eye,
              stableDirection: _stable,
              countdownSeconds: _cd,
              totalTimer: widget.timerSeconds,
              serverBase: widget.serverBase,
              activeColor: widget.color,
              pageTitle: widget.title,
              isMainScreen: widget.isMainScreen,
            ),

            const SizedBox(height: 4),

            Expanded(
              child: LayoutBuilder(builder: (ctx, screen) {
                final bool wide =
                    screen.maxWidth > 600 ||
                        screen.maxWidth > screen.maxHeight;
                final double gap =
                (screen.maxWidth * 0.025).clamp(8.0, 24.0);
                final double pad =
                (screen.maxWidth * 0.03).clamp(12.0, 32.0);

                return Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: pad, vertical: pad / 2),
                  child: wide
                      ? _wideGrid(gap)
                      : _portraitGrid(gap),
                );
              }),
            ),
          ]),
        ),
      ),
    );
  }
}