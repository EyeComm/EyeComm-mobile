// ════════════════════════════════════════════════════════════════════════════
// smart_control_main.dart
//
// Top-level Smart Control menu — pure routing, zero logic.
// All cubits are created inside the destination pages.
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:eye_comm_project/presentation/core/language_service.dart';
import 'package:eye_comm_project/presentation/core/eye_utils.dart';
import 'package:eye_comm_project/presentation/core/nav_helper.dart';
import 'package:eye_comm_project/presentation/shared/base_grid_page.dart';
import 'package:eye_comm_project/presentation/screens/emergency/emergency_page.dart';

import 'smart_home_hub.dart';
import 'wheelchair_page.dart';

class SmartControlMain extends StatelessWidget {
  const SmartControlMain({super.key});

  @override
  Widget build(BuildContext context) {
    final bool ar = AppLanguage.current == 'ar';

    return BaseGridPage(
      title: ar ? 'التحكم الذكي' : 'Smart Control',
      color: const Color(0xFF7C2BE8),
      showCameraCard: true,
      cameraCardAspectRatio: 1.15,
      items: [
        {
          'eye': 'left',
          'text': ar ? 'المنزل\nالذكي' : 'Smart\nHome',
          'iconAsset': 'assets/icons/home_control.png',
          'color': const Color(0xFF1565C0),
          'is_nav': true,
          'eye_name': eyeName('left'),
        },
        {
          'eye': 'up',
          'text': ar ? 'طوارئ' : 'Emergency',
          'iconAsset': 'assets/icons/siren.png',
          'color': const Color(0xFFC62828),
          'is_nav': true,
          'eye_name': eyeName('up'),
        },
        {
          'eye': 'right',
          'text': ar ? 'الكرسي\nالمتحرك' : 'Wheel\nChair',
          'iconAsset': 'assets/icons/wheelchair.png',
          'color': const Color(0xFF2E7D32),
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
          case 'closed':
            Navigator.pop(ctx);
            break;
          case 'left':
            await push(ctx, const SmartHomeHub());
            break;
          case 'right':
            await push(ctx, const WheelchairPage());
            break;
          case 'up':
            await push(ctx, const EmergencyPage());
            break;
        }
      },
    );
  }
}
