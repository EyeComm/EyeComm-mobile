import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/eye_utils.dart';
import '../../core/language_service.dart';
import '../../shared/base_grid_page.dart';
import '../../shared/device_switch_card.dart';
import '../eye_tracking/eye_tracking_state.dart';
import 'emergency_cubit.dart';

class EmergencyPage extends StatelessWidget {
  const EmergencyPage({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      context.read<EmergencyCubit>();
      return const _EmergencyView();
    } catch (_) {
      return BlocProvider(
        create: (_) => EmergencyCubit(),
        child: const _EmergencyView(),
      );
    }
  }
}

class _EmergencyView extends StatelessWidget {
  const _EmergencyView();

  @override
  Widget build(BuildContext context) {
    final bool ar = AppLanguage.current == 'ar';

    return BlocConsumer<EmergencyCubit, EyeTrackingState>(
      listenWhen: (prev, current) => current.confirmedGesture == 'closed',
      listener: (context, state) {
        if (state.confirmedGesture == 'closed' && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
      builder: (context, state) {
        final cubit = context.read<EmergencyCubit>();
        final emState = cubit.emergencyState;

        final List<Map<String, dynamic>> gridItems = [
          {'eye': 'left'},
          {'eye': 'up'},
          {'eye': 'right'},
          {'eye': 'closed'},
        ];

        return BaseGridPage(
          title: ar ? ' طوارئ' : ' EMERGENCY',
          color: const Color(0xFFC62828),
          items: gridItems,
          isMainScreen: false,
          showCameraCard: true,
          cameraCardAspectRatio: 1.15,
          currentEye: state.currentEye,
          stableDirection: state.stableDirection,
          countdownSeconds: state.countdownSeconds,
          timerSeconds: emState.totalTimer,
          itemBuilder: (ctx, index, item, stable, cd, totalTimer) {
            return _buildEmergencyCard(
                ctx,
                index,
                emState,
                ar,
                stable,
                cd,
                totalTimer,
                cubit);
          },
          onAction: (eye, ctx) async {
            if (eye != 'closed') {
              cubit.executeCommand(eye);
            }
          },
        );
      },
    );
  }

  Widget _buildEmergencyCard(BuildContext context,
      int index,
      EmergencyState emState,
      bool ar,
      String stable,
      int cd,
      int totalTimer,
      EmergencyCubit cubit,) {
    switch (index) {
      case 0:
        final bool isHelp = emState.activeAlert == 'help';
        return DeviceSwitchCard(
          iconAsset: 'assets/help.png',
          label: ar ? ' مساعدة' : ' HELP',
          gestureName: eyeName('left'),
          eyeCmd: 'left',
          isOn: isHelp,
          activeColor: const Color(0xFFE65100),
          statusText: ar
              ? (isHelp ? 'يعمل' : 'مغلق')
              : (isHelp ? 'Working' : 'Closed'),
          stable: stable,
          cd: cd,
          totalTimer: totalTimer,
          onTap: () => cubit.executeCommand('left'),
        );
      case 1:
        final bool isEmergency = emState.activeAlert == 'emergency';
        return DeviceSwitchCard(
          iconAsset: 'assets/siren.png',
          label: ar ? ' طوارئ' : ' EMERGENCY',
          gestureName: eyeName('up'),
          eyeCmd: 'up',
          isOn: isEmergency,
          activeColor: const Color(0xFFD32F2F),
          statusText: ar
              ? (isEmergency ? 'يعمل' : 'مغلق')
              : (isEmergency ? 'Working' : 'Closed'),
          stable: stable,
          cd: cd,
          totalTimer: totalTimer,
          onTap: () => cubit.executeCommand('up'),
        );
      case 2:
        return DeviceSwitchCard(
          iconAsset: 'assets/stop.png',
          label: ar ? ' إيقاف التنبيه' : ' STOP ALERT',
          gestureName: eyeName('right'),
          eyeCmd: 'right',
          isOn: null,
          activeColor: const Color(0xFF546E7A),
          stable: stable,
          cd: cd,
          totalTimer: totalTimer,
          onTap: () => cubit.executeCommand('right'),
        );
      case 3:
      default:
        return DeviceSwitchCard(
          iconAsset: 'assets/back.png',
          label: ar ? 'رجوع' : 'Back',
          gestureName: eyeName('closed'),
          eyeCmd: 'closed',
          isOn: null,
          activeColor: const Color(0xFF455A64),
          stable: stable,
          cd: cd,
          totalTimer: totalTimer,
          onTap: () {
            cubit.executeCommand('closed');
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
        );
    }
  }
}