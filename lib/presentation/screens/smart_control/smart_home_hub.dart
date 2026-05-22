// ════════════════════════════════════════════════════════════════════════════
// smart_home_hub.dart
//
// Thin routing widget for the Smart Home sub-menu.
// No BlocProvider wrapping is done here — each room page manages its own
// cubit lifecycle internally via BlocProvider.create.
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:eye_comm_project/presentation/core/eye_utils.dart';
import 'package:eye_comm_project/presentation/core/language_service.dart';
import 'package:eye_comm_project/presentation/core/nav_helper.dart';
import 'package:eye_comm_project/presentation/shared/base_grid_page.dart';

import 'smart_home_hall_page.dart';
import 'smart_home_room_page.dart';

class SmartHomeHub extends StatelessWidget {
  const SmartHomeHub({super.key});

  @override
  Widget build(BuildContext context) {
    final bool ar = AppLanguage.current == 'ar';

    return BaseGridPage(
      title: ar ? 'المنزل الذكي' : 'Smart Home',
      color: const Color(0xFF1565C0),
      showCameraCard: true,
      cameraCardAspectRatio: 1.15,
      items: [
        {
          'eye': 'left',
          'text': ar ? 'الصالة' : 'Hall',
          'iconAsset': 'assets/icons/hall.png',
          'color': const Color(0xFF00695C),
          'is_nav': true,
          'eye_name': eyeName('left'),
        },
        {
          'eye': 'up',
          'text': ar ? 'النور الرئيسي' : 'Main Light',
          'iconAsset': 'assets/icons/light.png',
          'color': const Color(0xFF388E3C),
          'is_nav': false,
          'eye_name': eyeName('up'),
        },
        {
          'eye': 'right',
          'text': ar ? 'الأوضة' : 'Room',
          'iconAsset': 'assets/icons/room.png',
          'color': Colors.indigo,
          'is_nav': true,
          'eye_name': eyeName('right'),
        },
        {
          'eye': 'closed',
          'text': ar ? 'رجوع' : 'Back',
          'iconAsset': 'assets/icons/back.png',
          'color': const Color(0xFF455A64),
          'is_nav': false,
          'eye_name': eyeName('closed'),
        },
      ],
      onAction: (eye, ctx) async {
        switch (eye) {
          // Each push creates a new BlocProvider inside the destination page.
          // No manual BlocProvider wrapping needed here.
          case 'closed':
            Navigator.pop(ctx);
            break;
          case 'left':
            await push(ctx, const SmartHomeHallPage());
            break;
          case 'right':
            await push(ctx, const SmartHomeRoomPage());
            break;
        }
      },
    );
  }
}
