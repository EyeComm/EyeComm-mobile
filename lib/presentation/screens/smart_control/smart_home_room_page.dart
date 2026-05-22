import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// تأكد من مسار BaseGridPage الصحيح في مشروعك
import '../../shared/base_grid_page.dart';
import '../../shared/device_switch_card.dart';
import '../../core/language_service.dart';
import '../../core/eye_utils.dart';
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

    return BlocConsumer<SmartHomeRoomCubit, EyeTrackingState>(
      listenWhen: (prev, current) => current.confirmedGesture == 'closed',
      listener: (context, state) {
        if (state.confirmedGesture == 'closed' && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
      builder: (context, state) {
        // قراءة الـ State المخصصة للغرفة
        final cubit = context.read<SmartHomeRoomCubit>();
        final roomState = cubit.roomState;

        // مصفوفة بسيطة لتعريف العناصر المطلوبة لـ BaseGridPage
        final List<Map<String, dynamic>> gridItems = [
          {'eye': 'down'},   // النور
          {'eye': 'left'},   // المروحة
          {'eye': 'right'},  // السرير
          {'eye': 'up'},     // الشباك
          {'eye': 'closed'}, // رجوع
        ];

        return BaseGridPage(
          title: ar ? 'الأوضة' : 'Room',
          color: const Color(0xFF00C853), // اللون الأساسي للصفحة
          items: gridItems,
          isMainScreen: false,
          showCameraCard: true,
          cameraCardAspectRatio: 1.15,
          currentEye: roomState.currentEye,
          stableDirection: roomState.stableDirection,
          countdownSeconds: roomState.countdownSeconds,
          timerSeconds: roomState.totalTimer,

          // 🎯 بناء الكروت المخصصة للغرفة بناءً على الـ Index
          itemBuilder: (ctx, index, item, stable, cd, totalTimer) {
            switch (index) {
              case 0:
                return DeviceSwitchCard(
                  iconAsset: 'assets/icons/light.png',
                  label: ar ? 'النور' : 'Light',
                  gestureName: eyeName('down'),
                  eyeCmd: 'down',
                  isOn: roomState.lightOn,
                  activeColor: const Color(0xFFFFA000),
                  stable: stable,
                  cd: cd,
                  totalTimer: totalTimer,
                );
              case 1:
                return DeviceSwitchCard(
                  iconAsset: 'assets/icons/fan.png',
                  label: ar ? 'المروحة' : 'Fan',
                  gestureName: eyeName('left'),
                  eyeCmd: 'left',
                  isOn: roomState.fanOn,
                  activeColor: const Color(0xFF00897B),
                  stable: stable,
                  cd: cd,
                  totalTimer: totalTimer,
                );
              case 2:
                return DeviceSwitchCard(
                  iconAsset: 'assets/icons/bed.png',
                  label: ar ? 'السرير' : 'Bed',
                  gestureName: eyeName('right'),
                  eyeCmd: 'right',
                  isOn: roomState.bedUp,
                  activeColor: const Color(0xFF6A1B9A),
                  statusText: ar
                      ? (roomState.bedUp ? 'مرفوع ⬆️' : 'نازل ⬇️')
                      : (roomState.bedUp ? 'UP ⬆️' : 'DOWN ⬇️'),
                  stable: stable,
                  cd: cd,
                  totalTimer: totalTimer,
                );
              case 3:
                return DeviceSwitchCard(
                  iconAsset: 'assets/icons/window.png',
                  label: ar ? 'الشباك' : 'Window',
                  gestureName: eyeName('up'),
                  eyeCmd: 'up',
                  isOn: roomState.windowOpen,
                  activeColor: const Color(0xFF0288D1),
                  statusText: ar
                      ? (roomState.windowOpen ? 'مفتوح' : 'مغلق')
                      : (roomState.windowOpen ? 'Open' : 'Closed'),
                  stable: stable,
                  cd: cd,
                  totalTimer: totalTimer,
                );
              case 4:
              default:
                return DeviceSwitchCard(
                  iconAsset: 'assets/icons/back.png',
                  label: ar ? 'رجوع' : 'Back',
                  gestureName: eyeName('closed'),
                  eyeCmd: 'closed',
                  isOn: false,
                  activeColor: Colors.grey,
                  stable: stable,
                  cd: cd,
                  totalTimer: totalTimer,
                );
            }
          },
        );
      },
    );
  }
}