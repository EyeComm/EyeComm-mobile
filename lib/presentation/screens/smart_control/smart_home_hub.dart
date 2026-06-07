import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eye_comm_project/presentation/core/eye_utils.dart';
import 'package:eye_comm_project/presentation/core/language_service.dart';
import 'package:eye_comm_project/presentation/core/nav_helper.dart';
import 'package:eye_comm_project/presentation/shared/base_grid_page.dart';
import 'package:eye_comm_project/presentation/shared/device_switch_card.dart';

import 'smart_home_hall_page.dart';
import 'smart_home_room_page.dart';
import 'smart_home_hub_cubit.dart';
import '../eye_tracking/eye_tracking_state.dart';

class SmartHomeHub extends StatelessWidget {
  const SmartHomeHub({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      context.read<SmartHomeHubCubit>();
      return const _HubView();
    } catch (_) {
      return BlocProvider(
        create: (_) => SmartHomeHubCubit(),
        child: const _HubView(),
      );
    }
  }
}

class _HubView extends StatelessWidget {
  const _HubView();

  Future<void> _handleNavigation(String eye, BuildContext ctx, SmartHomeHubCubit cubit) async {
    switch (eye) {
      case 'closed':
        await cubit.executeHubCommand('closed');
        if (Navigator.canPop(ctx)) Navigator.pop(ctx);
        break;
      case 'left':
        await push(ctx, const SmartHomeHallPage());
        break;
      case 'right':
        await push(ctx, const SmartHomeRoomPage());
        break;
      case 'up':
        await cubit.executeHubCommand('up');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool ar = AppLanguage.current == 'ar';

    return BlocConsumer<SmartHomeHubCubit, EyeTrackingState>(
      listenWhen: (prev, current) => current.confirmedGesture != null,
      listener: (context, state) {
        if (state.confirmedGesture == 'left' ||
            state.confirmedGesture == 'right' ||
            state.confirmedGesture == 'closed') {
          _handleNavigation(state.confirmedGesture!, context, context.read<SmartHomeHubCubit>());
        }
      },
      builder: (context, state) {
        final cubit = context.read<SmartHomeHubCubit>();
        final hubState = cubit.hubState;

        final List<Map<String, dynamic>> menuItems = [
          {'eye': 'left', 'text': ar ? 'الصالة' : 'Hall', 'iconAsset': 'assets/hall.png', 'color': const Color(0xFF00695C), 'eye_name': eyeName('left')},
          {'eye': 'up', 'text': ar ? 'الباب' : 'Door', 'iconAsset': 'assets/door.png', 'color': const Color(0xFF8D6E63), 'eye_name': eyeName('up')},
          {'eye': 'right', 'text': ar ? 'الأوضة' : 'Room', 'iconAsset': 'assets/room.png', 'color': Colors.indigo, 'eye_name': eyeName('right')},
          {'eye': 'closed', 'text': ar ? 'رجوع' : 'Back', 'iconAsset': 'assets/back.png', 'color': const Color(0xFF455A64), 'eye_name': eyeName('closed')},
        ];

        return BaseGridPage(
          title: ar ? 'المنزل الذكي' : 'Smart Home',
          color: const Color(0xFF1565C0),
          showCameraCard: true,
          cameraCardAspectRatio: 1.15,
          items: menuItems,
          currentEye: state.currentEye,
          stableDirection: state.stableDirection,
          countdownSeconds: state.countdownSeconds,
          timerSeconds: hubState.totalTimer,
          itemBuilder: (context, index, item, stable, cd, totalTimer) {
            final String currentEye = item['eye'].toString();
            final bool isDoorCard = currentEye == 'up';

            return DeviceSwitchCard(
              iconAsset: item['iconAsset'].toString(),
              label: item['text'].toString(),
              gestureName: item['eye_name'].toString(),
              eyeCmd: currentEye,
              activeColor: item['color'] as Color,
              stable: stable,
              cd: cd,
              totalTimer: totalTimer,
              isOn: isDoorCard ? hubState.isDoorOpen : null,
              onTap: () => _handleNavigation(currentEye, context, cubit),
            );
          },
          onAction: (eye, ctx) async {
            if (eye == 'up') {
              await cubit.executeHubCommand('up');
            }
          },
        );
      },
    );
  }
}