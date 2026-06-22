import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/eye_utils.dart';
import '../../core/language_service.dart';
import '../../shared/base_grid_page.dart';
import '../../shared/device_switch_card.dart';
import '../eye_tracking/eye_tracking_state.dart';
import 'wheelchair_cubit.dart';

class WheelchairPage extends StatelessWidget {
  const WheelchairPage({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      context.read<WheelchairCubit>();
      return const _WheelchairView();
    } catch (_) {
      return BlocProvider(
        create: (_) => WheelchairCubit(),
        child: const _WheelchairView(),
      );
    }
  }
}

class _WheelchairView extends StatelessWidget {
  const _WheelchairView();

  @override
  Widget build(BuildContext context) {
    final bool ar = AppLanguage.current == 'ar';

    return BlocConsumer<WheelchairCubit, EyeTrackingState>(
      listenWhen: (prev, current) => current.confirmedGesture == 'closed',
      listener: (context, state) {
        if (state.confirmedGesture == 'closed' && Navigator.canPop(context)) {
          // ✅ إيقاف الـ polling عند الخروج
          try {
            final cubit = context.read<WheelchairCubit>();
            cubit.stopPolling();
          } catch (_) {}
          Navigator.pop(context);
        }
      },
      builder: (context, state) {
        final cubit = context.read<WheelchairCubit>();
        final wheelchairState = cubit.wheelchairState;

        final List<Map<String, dynamic>> items = [
          {'eye': 'up',     'text': ar ? 'للأمام'  : 'Forward'},
          {'eye': 'down',   'text': ar ? 'للخلف'   : 'Backward'},
          {'eye': 'left',   'text': ar ? 'يسار'    : 'Left'},
          {'eye': 'right',  'text': ar ? 'يمين'    : 'Right'},
          {'eye': 'closed', 'text': ar ? 'رجوع'    : 'Back'},
        ];

        return BaseGridPage(
          title: ar ? 'الكرسي المتحرك' : 'Wheelchair',
          color: const Color(0xFF2E7D32),
          showCameraCard: true,
          cameraCardAspectRatio: 1.15,
          items: items,
          timerSeconds: wheelchairState.totalTimer,
          currentEye: state.currentEye,
          stableDirection: state.stableDirection,
          countdownSeconds: state.countdownSeconds,
          itemBuilder: (context, index, item, stable, cd, totalTimer) {
            return _buildCard(context, index, wheelchairState, ar,
                stable, cd, totalTimer, cubit);
          },
          onAction: (eye, ctx) async {
            if (eye == 'closed') {
              // ✅ إيقاف الـ polling عند الخروج
              try {
                final cubit = context.read<WheelchairCubit>();
                cubit.stopPolling();
              } catch (_) {}
              if (Navigator.canPop(ctx)) Navigator.pop(ctx);
            } else {
              cubit.executeCommand(eye);
            }
          },
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    int index,
    WheelchairState state,
    bool ar,
    String stable,
    int cd,
    int totalTimer,
    WheelchairCubit cubit,
  ) {
    switch (index) {
      case 0:
        return DeviceSwitchCard(
          iconAsset: 'assets/forward.png',
          isIcon: false,
          label: ar ? 'للأمام' : 'Forward',
          gestureName: eyeName('up'),
          eyeCmd: 'up',
          isOn: state.currentDirection == 'F' ? true : null,
          activeColor: const Color(0xFF388E3C),
          stable: stable,
          cd: cd,
          totalTimer: totalTimer,
        );

      case 1:
        return DeviceSwitchCard(
          iconAsset: 'assets/backward.png',
          isIcon: false,
          label: ar ? 'للخلف' : 'Backward',
          gestureName: eyeName('down'),
          eyeCmd: 'down',
          isOn: state.currentDirection == 'B' ? true : null,
          activeColor: const Color(0xFFD32F2F),
          stable: stable,
          cd: cd,
          totalTimer: totalTimer,
        );

      case 2:
        return DeviceSwitchCard(
          iconAsset: 'assets/left_arrow.png',
          isIcon: false,
          label: ar ? 'يسار' : 'Left',
          gestureName: eyeName('left'),
          eyeCmd: 'left',
          isOn: state.currentDirection == 'L' ? true : null,
          activeColor: const Color(0xFF1976D2),
          stable: stable,
          cd: cd,
          totalTimer: totalTimer,
        );

      case 3:
        return DeviceSwitchCard(
          iconAsset: 'assets/right_arrow.png',
          isIcon: false,
          label: ar ? 'يمين' : 'Right',
          gestureName: eyeName('right'),
          eyeCmd: 'right',
          isOn: state.currentDirection == 'R' ? true : null,
          activeColor: const Color(0xFF7B1FA2),
          stable: stable,
          cd: cd,
          totalTimer: totalTimer,
        );

      case 4:
      default:
        return DeviceSwitchCard(
          iconAsset: 'assets/back.png',
          isIcon: false,
          label: ar ? 'رجوع' : 'Back',
          gestureName: eyeName('closed'),
          eyeCmd: 'closed',
          isOn: null,
          activeColor: const Color(0xFF455A64),
          stable: stable,
          cd: cd,
          totalTimer: totalTimer,
        );
    }
  }
}