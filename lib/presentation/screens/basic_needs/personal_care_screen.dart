import 'package:flutter/material.dart';
import '../../core/language_service.dart';
import '../../core/voice_service.dart';
import '../../core/eye_utils.dart';
import '../../shared/base_grid_page.dart';

class PersonalCareScreen extends StatelessWidget {
  const PersonalCareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool ar = AppLanguage.current == 'ar';

    return BaseGridPage(
      title: ar ? 'عناية ونظافة' : 'Personal Care',
      color: const Color(0xFF00897B), // لون Teal مريح
      items: [
        {'eye': 'closed', 'text': ar ? 'رجوع' : 'Back', 'iconAsset': 'assets/icons/back.png', 'color': const Color(0xFF455A64), 'is_nav': false, 'eye_name': eyeName('closed')},
        {'eye': 'left', 'text': ar ? 'دخول الحمام' : 'Bathroom', 'iconAsset': 'assets/icons/toilet.png', 'color': const Color(0xFF5D4037), 'is_nav': false, 'eye_name': eyeName('left')},
        {'eye': 'right', 'text': ar ? 'استحمام' : 'Shower', 'iconAsset': 'assets/icons/shower.png', 'color': const Color(0xFF0288D1), 'is_nav': false, 'eye_name': eyeName('right')},
        {'eye': 'up', 'text': ar ? 'عناية وأدوية' : 'Grooming & Meds', 'iconAsset': 'assets/icons/toothbrush.png', 'color': const Color(0xFF00ACC1), 'is_nav': false, 'eye_name': eyeName('up')},
        {'eye': 'down', 'text': ar ? 'تغيير ملابس' : 'Change Clothes', 'iconAsset': 'assets/icons/clothes.png', 'color': const Color(0xFF43A047), 'is_nav': false, 'eye_name': eyeName('down')},
      ],
      onAction: (eye, ctx) async {
        if (eye == 'closed') { Navigator.pop(ctx); return; }

        final msg = {
          'left': ar ? 'أحتاج إلى دخول الحمام فوراً' : 'I need to use the bathroom immediately',
          'right': ar ? 'أريد غسل وجهي أو الاستحمام' : 'I would like to wash my face or take a shower',
          'up': ar ? 'أريد غسل أسناني أو تسريح شعري' : 'I want to brush my teeth or comb my hair',
          'down': ar ? 'أريد تغيير ملابسي' : 'I want to change my clothes',
        }[eye];

        if (msg != null) VoiceService.speak(msg);
      },
    );
  }
}