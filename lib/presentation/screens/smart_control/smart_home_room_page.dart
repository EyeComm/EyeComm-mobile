import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    try {
      context.read<SmartHomeRoomCubit>();
      return const _RoomView();
    } catch (_) {
      return BlocProvider(
        create: (_) => SmartHomeRoomCubit(),
        child: const _RoomView(),
      );
    }
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
        final cubit = context.read<SmartHomeRoomCubit>();
        final roomState = cubit.roomState;

        final List<Map<String, dynamic>> gridItems = [
          {'eye': 'down', 'text': ar ? 'النور' : 'Light'},
          {'eye': 'left', 'text': ar ? 'المروحة' : 'Fan'},
          {'eye': 'right', 'text': ar ? 'السرير' : 'Bed'},
          {'eye': 'up', 'text': ar ? 'الشباك' : 'Window'},
          {'eye': 'closed', 'text': ar ? 'رجوع' : 'Back'},
        ];

        return BaseGridPage(
          title: ar ? 'الأوضة' : 'Room',
          color: const Color(0xFF00C853),
          items: gridItems,
          isMainScreen: false,
          showCameraCard: true,
          cameraCardAspectRatio: 1.15,
          currentEye: state.currentEye,
          stableDirection: state.stableDirection,
          countdownSeconds: state.countdownSeconds,
          timerSeconds: roomState.totalTimer,
          itemBuilder: (ctx, index, item, stable, cd, totalTimer) {
            return _buildDeviceCard(ctx, index, roomState, ar, stable, cd, totalTimer, cubit);
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

  Widget _buildDeviceCard(
      BuildContext context,
      int index,
      SmartHomeRoomState roomState,
      bool ar,
      String stable,
      int cd,
      int totalTimer,
      SmartHomeRoomCubit cubit,
      ) {
    switch (index) {
      case 0:
        return DeviceSwitchCard(
          iconAsset: 'assets/light.png',
          label: ar ? 'النور' : 'Light',
          gestureName: eyeName('down'),
          eyeCmd: 'down',
          isOn: roomState.lightOn,
          activeColor: const Color(0xFFFFA000),
          stable: stable,
          cd: cd,
          totalTimer: totalTimer,
          onTap: () => cubit.executeCommand('down'),
        );
      case 1:
        return DeviceSwitchCard(
          iconAsset: 'assets/fan.png',
          label: ar ? 'المروحة' : 'Fan',
          gestureName: eyeName('left'),
          eyeCmd: 'left',
          isOn: roomState.fanOn,
          activeColor: const Color(0xFF00897B),
          stable: stable,
          cd: cd,
          totalTimer: totalTimer,
          onTap: () => cubit.executeCommand('left'),
        );
      case 2:
        return DeviceSwitchCard(
          iconAsset: 'assets/bed.png',
          label: ar ? 'السرير' : 'Bed',
          gestureName: eyeName('right'),
          eyeCmd: 'right',
          isOn: roomState.bedUp,
          activeColor: const Color(0xFF6A1B9A),
          statusText: ar
              ? (roomState.bedUp ? 'مرفوع ⬆' : 'نازل ⬇')
              : (roomState.bedUp ? 'UP ⬆' : 'DOWN ⬇'),
          stable: stable,
          cd: cd,
          totalTimer: totalTimer,
          onTap: () => cubit.executeCommand('right'),
        );
      case 3:
        return DeviceSwitchCard(
          iconAsset: 'assets/window.png',
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
          onTap: () => cubit.executeCommand('up'),
        );
      case 4:
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