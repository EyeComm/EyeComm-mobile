import 'package:flutter/material.dart';
import '../../core/language_service.dart';
import '../../core/eye_utils.dart';
import '../../core/nav_helper.dart';
import '../../shared/base_grid_page.dart';

import 'pain_categories_screen.dart';
import 'symptoms_categories_screen.dart';
import 'medication_screen.dart';

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool ar = AppLanguage.current == 'ar';

    return BaseGridPage(
      title: ar ? 'الصحة' : 'Health',
      color: const Color(0xFFE53935), // لون أحمر طبي
      items: [
        // 1. اليسار (أشعر بألم)
        {
          'eye': 'left',
          'text': ar ? 'أشعر بألم' : 'Pain',
          'iconAsset': 'assets/icons/pain.png',
          'color': const Color(0xFFD32F2F),
          'is_nav': true,
          'eye_name': eyeName('left')
        },
        // 2. الأعلى (الأدوية)
        {
          'eye': 'up',
          'text': ar ? 'الأدوية' : 'Medication',
          'iconAsset': 'assets/icons/pills.png',
          'color': const Color(0xFF1976D2),
          'is_nav': true,
          'eye_name': eyeName('up')
        },
        // 3. اليمين (أعراض أخرى)
        {
          'eye': 'right',
          'text': ar ? 'أعراض أخرى' : 'Symptoms',
          'iconAsset': 'assets/icons/symptoms.png',
          'color': const Color(0xFFF57C00),
          'is_nav': true,
          'eye_name': eyeName('right')
        },
        // 4. الإغلاق (رجوع)
        {
          'eye': 'closed',
          'text': ar ? 'رجوع' : 'Back',
          'iconAsset': 'assets/icons/back.png',
          'color': const Color(0xFF455A64),
          'is_nav': false,
          'eye_name': eyeName('closed')
        },
      ],
      onAction: (eye, ctx) async {
        switch (eye) {
          case 'left':   await push(ctx, const PainCategoriesScreen()); break;
          case 'up':     await push(ctx, const MedicationScreen()); break;
          case 'right':  await push(ctx, const SymptomsCategoriesScreen()); break;
          case 'closed': Navigator.pop(ctx); break;
        }
      },
    );
  }
}