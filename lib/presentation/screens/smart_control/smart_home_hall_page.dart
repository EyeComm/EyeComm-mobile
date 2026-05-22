import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/eye_utils.dart';
import '../../core/language_service.dart';
import '../../shared/base_grid_page.dart';
import '../../shared/device_switch_card.dart';
import 'smart_home_hall_cubit.dart';
import '../eye_tracking/eye_tracking_state.dart';

class SmartHomeHallPage extends StatelessWidget {
  const SmartHomeHallPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 💡 الحفاظ على الـ State: نبحث أولاً إذا كان الـ Cubit تم إنشاؤه مسبقاً في مستوى أعلى
    // إذا لم يكن موجوداً، نقوم بإنشائه هنا لحماية التطبيق من الـ Crash.
    try {
      context.read<SmartHomeHallCubit>();
      return const _HallView();
    } catch (_) {
      return BlocProvider(
        create: (_) => SmartHomeHallCubit(),
        child: const _HallView(),
      );
    }
  }
}

class _HallView extends StatelessWidget {
  const _HallView();

  @override
  Widget build(BuildContext context) {
    final bool ar = AppLanguage.current == 'ar';

    return BlocConsumer<SmartHomeHallCubit, EyeTrackingState>(
      listenWhen: (prev, current) => current.confirmedGesture == 'closed',
      listener: (context, state) {
        if (state.confirmedGesture == 'closed' && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
      builder: (context, state) {
        final cubit = context.read<SmartHomeHallCubit>();
        final hallState = cubit.hallState;

        // خريطة العناصر لتمريرها للـ BaseGrid لضبط الترتيب والهندسة الرياضية للأبعاد
        final List<Map<String, dynamic>> items = [
          {'eye': 'left', 'text': ar ? 'التكييف' : 'AC'},
          {'eye': 'right', 'text': ar ? 'الباب' : 'Door'},
          {'eye': 'up', 'text': ar ? 'الشاشة' : 'TV'},
          {'eye': 'down', 'text': ar ? 'الدفاية' : 'Heater'},
          {'eye': 'closed', 'text': ar ? 'رجوع' : 'Back'},
        ];

        return BaseGridPage(
          title: ar ? 'الصالة' : 'Hall',
          color: const Color(0xFF00C853),
          items: items,
          timerSeconds: hallState.totalTimer,
          // 🎯 نمرر الـ State الخارجي للـ BaseGridPage لإلغاء الـ Polling الداخلي التكراري
          currentEye: state.currentEye,
          stableDirection: state.stableDirection,
          countdownSeconds: state.countdownSeconds,
          itemBuilder: (context, index, item, stable, cd, totalTimer) {
            return _buildDeviceCard(index, hallState, ar);
          },
        );
      },
    );
  }

  // 🎯 بناء كروت التحكم بناءً على الحالات الحالية والمستمرة داخل الـ SmartHomeHallState
  Widget _buildDeviceCard(int index, SmartHomeHallState state, bool ar) {
    switch (index) {
      case 0:
        return DeviceSwitchCard(
          iconAsset: 'assets/icons/ac.png',
          label: ar ? 'التكييف' : 'AC',
          gestureName: eyeName('left'),
          eyeCmd: 'left',
          isOn: state.acMode != AcMode.off,
          activeColor: state.acMode == AcMode.hot
              ? const Color(0xFFEF5350)
              : (state.acMode == AcMode.cold ? const Color(0xFF4FC3F7) : Colors.grey),
          statusText: state.acMode == AcMode.hot
              ? (ar ? '🔥 سخن' : '🔥 Hot')
              : (state.acMode == AcMode.cold ? (ar ? '❄️ بارد' : '❄️ Cold') : null),
          stable: state.stableDirection,
          cd: state.countdownSeconds,
          totalTimer: state.totalTimer,
        );
      case 1:
        return DeviceSwitchCard(
          iconAsset: 'assets/icons/door.png',
          label: ar ? 'الباب' : 'Door',
          gestureName: eyeName('right'),
          eyeCmd: 'right',
          isOn: state.doorOpen,
          activeColor: const Color(0xFF8D6E63),
          stable: state.stableDirection,
          cd: state.countdownSeconds,
          totalTimer: state.totalTimer,
        );
      case 2:
        return DeviceSwitchCard(
          iconAsset: 'assets/icons/tv.png',
          label: ar ? 'الشاشة' : 'TV',
          gestureName: eyeName('up'),
          eyeCmd: 'up',
          isOn: state.tvOn,
          activeColor: const Color(0xFF42A5F5),
          stable: state.stableDirection,
          cd: state.countdownSeconds,
          totalTimer: state.totalTimer,
        );
      case 3:
        return DeviceSwitchCard(
          iconAsset: 'assets/icons/heater.png',
          label: ar ? 'الدفاية' : 'Heater',
          gestureName: eyeName('down'),
          eyeCmd: 'down',
          isOn: state.heaterOn,
          activeColor: const Color(0xFFFF7043),
          stable: state.stableDirection,
          cd: state.countdownSeconds,
          totalTimer: state.totalTimer,
        );
      case 4:
        return DeviceSwitchCard(
          iconAsset: 'assets/icons/back.png',
          label: ar ? 'رجوع' : 'Back',
          gestureName: eyeName('closed'),
          eyeCmd: 'closed',
          isOn: false,
          activeColor: Colors.grey,
          stable: state.stableDirection,
          cd: state.countdownSeconds,
          totalTimer: state.totalTimer,
        );
      default:
        return const SizedBox();
    }
  }
}