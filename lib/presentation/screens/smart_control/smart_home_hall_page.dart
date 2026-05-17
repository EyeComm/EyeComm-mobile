import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_theme.dart';
import '../../core/language_service.dart';
import '../../core/eye_utils.dart';
import '../../shared/modern_tracking_quality_bar.dart';
import '../../shared/device_switch_card.dart';
import 'smart_home_hall_cubit.dart';
import '../eye_tracking/eye_tracking_state.dart';

class SmartHomeHallPage extends StatelessWidget {
  const SmartHomeHallPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SmartHomeHallCubit(),
      child: const _HallView(),
    );
  }
}

class _HallView extends StatelessWidget {
  const _HallView();

  @override
  Widget build(BuildContext context) {
    final bool ar = AppLanguage.current == 'ar';

    // 🎯 تم ضبط النوع هنا ليستقبل الـ EyeTrackingState الأساسية المتوافقة مع الكيوبيت الموروث
    return BlocConsumer<SmartHomeHallCubit, EyeTrackingState>(
      listenWhen: (prev, current) => current.confirmedGesture == 'closed',
      listener: (context, state) {
        if (state.confirmedGesture == 'closed' && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
      builder: (context, state) {
        // 🎯 قراءة الـ State المخصصة للصالة التي تحتوي على قيم الأجهزة الفرعية من الـ getter
        final cubit = context.read<SmartHomeHallCubit>();
        final hallState = cubit.hallState;

        return Directionality(
          textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: kBg1,
            body: SafeArea(
              child: Column(
                children: [
                  // ── Header ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: kSurface1,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kBorder1),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: kTextMain1),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(ar ? 'الصالة' : 'Hall', style: GoogleFonts.cairo(color: kTextMain1, fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),

                  // ── البار المودرن الشامل ──
                  ModernTrackingQualityBar(
                    currentEye: hallState.currentEye,
                    stableDirection: hallState.stableDirection,
                    countdownSeconds: hallState.countdownSeconds,
                    totalTimer: hallState.totalTimer,
                    serverBase: 'http://127.0.0.1:5000',
                    activeColor: const Color(0xFF00C853),
                  ),
                  const SizedBox(height: 8),

                  // ── Grid Layout ──
                  Expanded(
                    child: LayoutBuilder(
                      builder: (ctx, screen) {
                        final bool wide = screen.maxWidth > 600 || screen.maxWidth > screen.maxHeight;
                        final double gap = (screen.maxWidth * 0.025).clamp(8.0, 24.0);
                        final double pad = (screen.maxWidth * 0.03).clamp(12.0, 32.0);

                        final devices = _buildCards(hallState, ar);

                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: pad, vertical: pad / 2),
                          child: wide
                              ? Column(
                            children: [
                              Expanded(child: Row(children: [Expanded(flex: 2, child: devices[0]), SizedBox(width: gap), Expanded(flex: 2, child: devices[1]), SizedBox(width: gap), Expanded(flex: 2, child: devices[2])])),
                              SizedBox(height: gap),
                              Expanded(child: Row(children: [const Expanded(flex: 1, child: SizedBox()), Expanded(flex: 2, child: devices[3]), SizedBox(width: gap), Expanded(flex: 2, child: devices[4]), const Expanded(flex: 1, child: SizedBox())])),
                            ],
                          )
                              : Column(
                            children: [
                              Expanded(child: Row(children: [Expanded(flex: 2, child: devices[0]), SizedBox(width: gap), Expanded(flex: 2, child: devices[1])])),
                              SizedBox(height: gap),
                              Expanded(child: Row(children: [Expanded(flex: 2, child: devices[2]), SizedBox(width: gap), Expanded(flex: 2, child: devices[3])])),
                              SizedBox(height: gap),
                              Expanded(child: Row(children: [const Expanded(flex: 1, child: SizedBox()), Expanded(flex: 2, child: devices[4]), const Expanded(flex: 1, child: SizedBox())])),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildCards(SmartHomeHallState state, bool ar) => [
    DeviceSwitchCard(
      iconAsset: 'assets/icons/ac.png',
      label: ar ? 'التكييف' : 'AC',
      gestureName: eyeName('left'),
      eyeCmd: 'left',
      isOn: state.acMode != AcMode.off,
      activeColor: state.acMode == AcMode.hot ? const Color(0xFFEF5350) : (state.acMode == AcMode.cold ? const Color(0xFF4FC3F7) : Colors.grey),
      statusText: state.acMode == AcMode.hot ? (ar ? '🔥 سخن' : '🔥 Hot') : (state.acMode == AcMode.cold ? (ar ? '❄️ بارد' : '❄️ Cold') : null),
      stable: state.stableDirection,
      cd: state.countdownSeconds,
      totalTimer: state.totalTimer,
    ),
    DeviceSwitchCard(
      iconAsset: 'assets/icons/door.png',
      label: ar ? 'الباب' : 'Door',
      gestureName: eyeName('right'),
      eyeCmd: 'right',
      isOn: state.doorOpen,
      activeColor: const Color(0xFF8D6E63),
      stable: state.stableDirection,
      cd: state.countdownSeconds,
      totalTimer: state.totalTimer,
    ),
    DeviceSwitchCard(
      iconAsset: 'assets/icons/tv.png',
      label: ar ? 'الشاشة' : 'TV',
      gestureName: eyeName('up'),
      eyeCmd: 'up',
      isOn: state.tvOn,
      activeColor: const Color(0xFF42A5F5),
      stable: state.stableDirection,
      cd: state.countdownSeconds,
      totalTimer: state.totalTimer,
    ),
    DeviceSwitchCard(
      iconAsset: 'assets/icons/heater.png',
      label: ar ? 'الدفاية' : 'Heater',
      gestureName: eyeName('down'),
      eyeCmd: 'down',
      isOn: state.heaterOn,
      activeColor: const Color(0xFFFF7043),
      stable: state.stableDirection,
      cd: state.countdownSeconds,
      totalTimer: state.totalTimer,
    ),
    DeviceSwitchCard(
      iconAsset: 'assets/icons/back.png',
      label: ar ? 'رجوع' : 'Back',
      gestureName: eyeName('closed'),
      eyeCmd: 'closed',
      isOn: false,
      activeColor: Colors.grey,
      stable: state.stableDirection,
      cd: state.countdownSeconds,
      totalTimer: state.totalTimer,
    ),
  ];
}