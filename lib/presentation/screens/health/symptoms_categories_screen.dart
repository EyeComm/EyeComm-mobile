import 'package:flutter/material.dart';
import '../../core/language_service.dart';
import '../../core/eye_utils.dart';
import '../../core/nav_helper.dart';
import '../../shared/base_grid_page.dart';
import '../basic_needs/widgets/sub_items_screen.dart';

class SymptomsCategoriesScreen extends StatelessWidget {
  const SymptomsCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool ar = AppLanguage.current == 'ar';

    return BaseGridPage(
      title: ar ? 'الأعراض' : 'Symptoms',
      color: const Color(0xFFF57C00),
      showCameraCard: true,
      cameraCardAspectRatio: 1.15,
      items: [
        {'eye': 'closed', 'text': ar ? 'رجوع' : 'Back', 'iconAsset': 'assets/icons/back.png', 'color': const Color(0xFF455A64), 'is_nav': false, 'eye_name': eyeName('closed')},
        {'eye': 'left', 'text': ar ? 'تنفس' : 'Breathing', 'iconAsset': 'assets/icons/breathing.png', 'color': const Color(0xFF0288D1), 'is_nav': true, 'eye_name': eyeName('left')},
        {'eye': 'right', 'text': ar ? 'معدة وهضم' : 'Digestion', 'iconAsset': 'assets/icons/nausea.png', 'color': const Color(0xFF43A047), 'is_nav': true, 'eye_name': eyeName('right')},
        {'eye': 'up', 'text': ar ? 'حرارة ودوخة' : 'Fever & Dizziness', 'iconAsset': 'assets/icons/fever.png', 'color': const Color(0xFFE53935), 'is_nav': true, 'eye_name': eyeName('up')},
        {'eye': 'down', 'text': ar ? 'تعرق وضغط' : 'Sweating & Pressure', 'iconAsset': 'assets/icons/sweat.png', 'color': const Color(0xFF8E24AA), 'is_nav': true, 'eye_name': eyeName('down')},
      ],
      onAction: (eye, ctx) async {
        if (eye == 'closed') { Navigator.pop(ctx); return; }

        if (eye == 'left') {
          await push(ctx, SubItemsScreen(titleAr: 'التنفس', titleEn: 'Breathing', options: [
            {'eye': 'left', 'text': ar ? 'ضيق تنفس' : 'Shortness of Breath', 'iconAsset': 'assets/icons/short_breath.png', 'color': const Color(0xFF0288D1), 'eye_name': eyeName('left')},
            {'eye': 'right', 'text': ar ? 'سعال / كحة' : 'Coughing', 'iconAsset': 'assets/icons/cough.png', 'color': const Color(0xFFF57C00), 'eye_name': eyeName('right')},
            {'eye': 'up', 'text': ar ? 'شرقة / غصة' : 'Choking', 'iconAsset': 'assets/icons/choking.png', 'color': const Color(0xFFD32F2F), 'eye_name': eyeName('up')},
          ]));
        } else if (eye == 'right') {
          await push(ctx, SubItemsScreen(titleAr: 'معدة وهضم', titleEn: 'Digestion', options: [
            {'eye': 'left', 'text': ar ? 'غثيان' : 'Nausea', 'iconAsset': 'assets/icons/nausea.png', 'color': const Color(0xFF43A047), 'eye_name': eyeName('left')},
            {'eye': 'right', 'text': ar ? 'قيء' : 'Vomiting', 'iconAsset': 'assets/icons/vomiting.png', 'color': const Color(0xFFE53935), 'eye_name': eyeName('right')},
            {'eye': 'up', 'text': ar ? 'إمساك أو انتفاخ' : 'Constipation/Bloating', 'iconAsset': 'assets/icons/stomach_pain.png', 'color': const Color(0xFF8D6E63), 'eye_name': eyeName('up')},
          ]));
        } else if (eye == 'up') {
          await push(ctx, SubItemsScreen(titleAr: 'حرارة ودوخة', titleEn: 'Fever & Dizziness', options: [
            {'eye': 'left', 'text': ar ? 'سخونة وحرارة' : 'Fever', 'iconAsset': 'assets/icons/fever.png', 'color': const Color(0xFFD32F2F), 'eye_name': eyeName('left')},
            {'eye': 'right', 'text': ar ? 'دوخة' : 'Dizziness', 'iconAsset': 'assets/icons/dizziness.png', 'color': const Color(0xFFFBC02D), 'eye_name': eyeName('right')},
            {'eye': 'up', 'text': ar ? 'برد ورعشة' : 'Shivering', 'iconAsset': 'assets/icons/cold.png', 'color': const Color(0xFF0288D1), 'eye_name': eyeName('up')},
          ]));
        } else if (eye == 'down') {
          await push(ctx, SubItemsScreen(titleAr: 'تعرق وضغط', titleEn: 'Sweating & Pressure', options: [
            {'eye': 'left', 'text': ar ? 'تعرق شديد' : 'Heavy Sweating', 'iconAsset': 'assets/icons/sweat.png', 'color': const Color(0xFF00ACC1), 'eye_name': eyeName('left')},
            {'eye': 'right', 'text': ar ? 'إحساس بضغط عالي' : 'High Pressure Feeling', 'iconAsset': 'assets/icons/blood_pressure.png', 'color': const Color(0xFFD32F2F), 'eye_name': eyeName('right')},
            {'eye': 'up', 'text': ar ? 'ضربات قلب سريعة' : 'Palpitations', 'iconAsset': 'assets/icons/heartbeat.png', 'color': const Color(0xFFE53935), 'eye_name': eyeName('up')},
          ]));
        }
      },
    );
  }
}