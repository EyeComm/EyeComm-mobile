import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_theme.dart';
import '../../core/language_service.dart';
import '../../core/eye_utils.dart';
import '../../shared/modern_tracking_quality_bar.dart';
import '../../shared/device_switch_card.dart';
import 'smart_home_room_cubit.dart';
import '../eye_tracking/eye_tracking_state.dart';

class SmartHomeRoomPage extends StatelessWidget {
  const SmartHomeRoomPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SmartHomeRoomCubit(),
      child: const _RoomView(),
    );
  }
}

class _RoomView extends StatelessWidget {
  const _RoomView();

  @override
  Widget build(BuildContext context) {
    final bool ar = AppLanguage.current == 'ar';

    // 🎯 تم ضبط النوع هنا ليستقبل الـ EyeTrackingState الأساسية المتوافقة مع الكيوبيت الموروث
    return BlocConsumer<SmartHomeRoomCubit, EyeTrackingState>(
      listenWhen: (prev, current) => current.confirmedGesture == 'closed',
      listener: (context, state) {
        if (state.confirmedGesture == 'closed' && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
      builder: (context, state) {
        // 🎯 قراءة الـ State المخصصة لغرفة النوم التي تحتوي على قيم الأجهزة الفرعية من الـ getter
        final cubit = context.read<SmartHomeRoomCubit>();
        final roomState = cubit.roomState;

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
                        Text(ar ? 'الأوضة' : 'Room', style: GoogleFonts.cairo(color: kTextMain1, fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),

                  // ── البار المودرن الشامل ──
                  ModernTrackingQualityBar(
                    currentEye: roomState.currentEye,
                    stableDirection: roomState.stableDirection,
                    countdownSeconds: roomState.countdownSeconds,
                    totalTimer: roomState.totalTimer,
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

                        final devices = _buildCards(roomState, ar);

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

  List<Widget> _buildCards(SmartHomeRoomState state, bool ar) => [
    DeviceSwitchCard(
      iconAsset: 'assets/icons/light.png',
      label: ar ? 'النور' : 'Light',
      gestureName: eyeName('down'),
      eyeCmd: 'down',
      isOn: state.lightOn,
      activeColor: const Color(0xFFFFA000),
      stable: state.stableDirection,
      cd: state.countdownSeconds,
      totalTimer: state.totalTimer,
    ),
    DeviceSwitchCard(
      iconAsset: 'assets/icons/fan.png',
      label: ar ? 'المروحة' : 'Fan',
      gestureName: eyeName('left'),
      eyeCmd: 'left',
      isOn: state.fanOn,
      activeColor: const Color(0xFF00897B),
      stable: state.stableDirection,
      cd: state.countdownSeconds,
      totalTimer: state.totalTimer,
    ),
    DeviceSwitchCard(
      iconAsset: 'assets/icons/bed.png',
      label: ar ? 'السرير' : 'Bed',
      gestureName: eyeName('right'),
      eyeCmd: 'right',
      isOn: state.bedUp,
      activeColor: const Color(0xFF6A1B9A),
      statusText: ar ? (state.bedUp ? 'مرفوع ⬆️' : 'نازل ⬇️') : (state.bedUp ? 'UP ⬆️' : 'DOWN ⬇️'),
      stable: state.stableDirection,
      cd: state.countdownSeconds,
      totalTimer: state.totalTimer,
    ),
    DeviceSwitchCard(
      iconAsset: 'assets/icons/window.png',
      label: ar ? 'الشباك' : 'Window',
      gestureName: eyeName('up'),
      eyeCmd: 'up',
      isOn: state.windowOpen,
      activeColor: const Color(0xFF0288D1),
      statusText: ar ? (state.windowOpen ? 'مفتوح' : 'مغلق') : (state.windowOpen ? 'Open' : 'Closed'),
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