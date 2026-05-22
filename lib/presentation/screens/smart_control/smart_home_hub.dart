// ════════════════════════════════════════════════════════════════════════════
// smart_home_hub.dart
//
// Thin routing widget for the Smart Home sub-menu.
// Manages local state for the door and renders custom DeviceSwitchCards.
// ════════════════════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:eye_comm_project/presentation/core/eye_utils.dart';
import 'package:eye_comm_project/presentation/core/language_service.dart';
import 'package:eye_comm_project/presentation/core/nav_helper.dart';
import 'package:eye_comm_project/presentation/shared/base_grid_page.dart';
import 'package:eye_comm_project/presentation/shared/device_switch_card.dart';

import 'smart_home_hall_page.dart';
import 'smart_home_room_page.dart';

class SmartHomeHub extends StatefulWidget {
  const SmartHomeHub({super.key});

  @override
  State<SmartHomeHub> createState() => _SmartHomeHubState();
}

class _SmartHomeHubState extends State<SmartHomeHub> {
  // 💡 حالة الباب الرئيسية في الـ Hub (True مفتوح / False مغلق)
  bool _isDoorOpen = false;

  // 🎯 دالة إرسال أمر فتح/إغلاق الباب مباشرة إلى سيرفر الـ ESP32
  Future<void> _sendDoorCommand(bool open) async {
    final String command = open ? "door open" : "door close";
    print("Sending to ESP32: $command");

    try {
      // يمكنكِ تعديل الـ IP والـ Port حسب إعدادات السيرفر الفعلي لديكِ
      final url = Uri.parse('http://127.0.0.1:5000/command?cmd=$command');
      await http.get(url).timeout(const Duration(seconds: 2));
    } catch (e) {
      print("Error sending command to ESP32: $e");
    }
  }

  // 🎯 دالة موحدة لتنفيذ الأكشن سواء بالعين أو بالضغط باليد
  Future<void> _executeAction(String eye, BuildContext ctx) async {
    switch (eye) {
      case 'closed':
        Navigator.pop(ctx);
        break;
      case 'left':
        await push(ctx, const SmartHomeHallPage());
        break;
      case 'right':
        await push(ctx, const SmartHomeRoomPage());
        break;
      case 'up': // 🎯 أكشن فتح/إغلاق الباب الرئيسي للمنزل
        setState(() {
          _isDoorOpen = !_isDoorOpen;
        });
        await _sendDoorCommand(_isDoorOpen);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool ar = AppLanguage.current == 'ar';

    // 🎯 تحديث قائمة العناصر بوضع "الباب" في الاتجاه الأعلى (up) بدلاً من الإضاءة
    final List<Map<String, dynamic>> menuItems = [
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
        'text': ar ? 'الباب' : 'Door',
        'iconAsset': 'assets/icons/door.png',
        'color': const Color(0xFF8D6E63),
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
    ];

    return BaseGridPage(
      title: ar ? 'المنزل الذكي' : 'Smart Home',
      color: const Color(0xFF1565C0),
      showCameraCard: true,
      cameraCardAspectRatio: 1.15,
      items: menuItems,
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
          // نمرر القيمة البرمجية الحالية فقط لكارت الباب ليتحول إلى Switch
          isOn: isDoorCard ? _isDoorOpen : null,
          onTap: () async {
            await _executeAction(currentEye, context);
          },
        );
      },
      onAction: (eye, ctx) async {
        await _executeAction(eye, ctx);
      },
    );
  }
}