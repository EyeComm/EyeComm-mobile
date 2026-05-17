import 'package:flutter/material.dart';
import '../../core/language_service.dart';
import '../../core/eye_utils.dart';
import '../../core/nav_helper.dart';
import '../../shared/base_grid_page.dart';
import '../basic_needs/widgets/sub_items_screen.dart'; // مسار الكلاس المشترك

class PainCategoriesScreen extends StatelessWidget {
  const PainCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool ar = AppLanguage.current == 'ar';

    return BaseGridPage(
      title: ar ? 'أماكن الألم' : 'Pain Areas',
      color: const Color(0xFFD32F2F),
      items: [
        {'eye': 'closed', 'text': ar ? 'رجوع' : 'Back', 'iconAsset': 'assets/icons/back.png', 'color': const Color(0xFF455A64), 'is_nav': false, 'eye_name': eyeName('closed')},
        {'eye': 'left', 'text': ar ? 'الرأس والأسنان' : 'Head & Face', 'iconAsset': 'assets/icons/headache.png', 'color': const Color(0xFFE53935), 'is_nav': true, 'eye_name': eyeName('left')},
        {'eye': 'right', 'text': ar ? 'الصدر والبطن' : 'Chest & Stomach', 'iconAsset': 'assets/icons/stomach_pain.png', 'color': const Color(0xFFF57C00), 'is_nav': true, 'eye_name': eyeName('right')},
        {'eye': 'up', 'text': ar ? 'تشنجات وأعصاب' : 'Spasms & Nerves', 'iconAsset': 'assets/icons/nerve.png', 'color': const Color(0xFF8E24AA), 'is_nav': true, 'eye_name': eyeName('up')},
        {'eye': 'down', 'text': ar ? 'جلد وقرح فراش' : 'Skin & Bedsores', 'iconAsset': 'assets/icons/bedsore.png', 'color': const Color(0xFF0288D1), 'is_nav': true, 'eye_name': eyeName('down')},
      ],
      onAction: (eye, ctx) async {
        if (eye == 'closed') { Navigator.pop(ctx); return; }

        if (eye == 'left') {
          await push(ctx, SubItemsScreen(titleAr: 'الرأس والأسنان', titleEn: 'Head & Face', options: [
            {'eye': 'left', 'text': ar ? 'صداع' : 'Headache', 'iconAsset': 'assets/icons/headache.png', 'color': const Color(0xFFE53935), 'eye_name': eyeName('left')},
            {'eye': 'right', 'text': ar ? 'ألم أذن أو عين' : 'Ear/Eye Pain', 'iconAsset': 'assets/icons/ear_pain.png', 'color': const Color(0xFFF57C00), 'eye_name': eyeName('right')},
            {'eye': 'up', 'text': ar ? 'ألم أسنان' : 'Toothache', 'iconAsset': 'assets/icons/toothache.png', 'color': const Color(0xFF0288D1), 'eye_name': eyeName('up')},
          ]));
        } else if (eye == 'right') {
          await push(ctx, SubItemsScreen(titleAr: 'الصدر والبطن', titleEn: 'Chest & Stomach', options: [
            {'eye': 'left', 'text': ar ? 'ألم بالصدر' : 'Chest Pain', 'iconAsset': 'assets/icons/chest_pain.png', 'color': const Color(0xFFD32F2F), 'eye_name': eyeName('left')},
            {'eye': 'right', 'text': ar ? 'مغص بالبطن' : 'Stomachache', 'iconAsset': 'assets/icons/stomach_pain.png', 'color': const Color(0xFFFBC02D), 'eye_name': eyeName('right')},
            {'eye': 'up', 'text': ar ? 'ألم بالظهر' : 'Back Pain', 'iconAsset': 'assets/icons/back_pain.png', 'color': const Color(0xFF8D6E63), 'eye_name': eyeName('up')},
          ]));
        } else if (eye == 'up') {
          await push(ctx, SubItemsScreen(titleAr: 'تشنجات وأعصاب', titleEn: 'Spasms & Nerves', options: [
            {'eye': 'left', 'text': ar ? 'تشنج عضلي' : 'Muscle Spasm', 'iconAsset': 'assets/icons/muscle_spasm.png', 'color': const Color(0xFF8E24AA), 'eye_name': eyeName('left')},
            {'eye': 'right', 'text': ar ? 'ألم أعصاب' : 'Nerve Pain', 'iconAsset': 'assets/icons/nerve_pain.png', 'color': const Color(0xFF5E35B1), 'eye_name': eyeName('right')},
            {'eye': 'up', 'text': ar ? 'ألم بالمفاصل' : 'Joint Pain', 'iconAsset': 'assets/icons/joint_pain.png', 'color': const Color(0xFF3949AB), 'eye_name': eyeName('up')},
          ]));
        } else if (eye == 'down') {
          await push(ctx, SubItemsScreen(titleAr: 'جلد وقرح فراش', titleEn: 'Skin & Bedsores', options: [
            {'eye': 'left', 'text': ar ? 'ألم قرحة فراش' : 'Bedsore Pain', 'iconAsset': 'assets/icons/bedsore.png', 'color': const Color(0xFFC2185B), 'eye_name': eyeName('left')},
            {'eye': 'right', 'text': ar ? 'حكة شديدة' : 'Severe Itching', 'iconAsset': 'assets/icons/itching.png', 'color': const Color(0xFFF57C00), 'eye_name': eyeName('right')},
            {'eye': 'up', 'text': ar ? 'حرقان بالجلد' : 'Burning Sensation', 'iconAsset': 'assets/icons/burning.png', 'color': const Color(0xFFD32F2F), 'eye_name': eyeName('up')},
          ]));
        }
      },
    );
  }
}