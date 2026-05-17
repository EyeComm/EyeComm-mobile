import 'package:flutter/material.dart';
import '../../core/language_service.dart';
import '../../core/voice_service.dart';
import '../../core/eye_utils.dart';
import '../../core/nav_helper.dart';
import '../../shared/base_grid_page.dart';
import 'widgets/sub_items_screen.dart';

class DrinksScreen extends StatelessWidget {
  const DrinksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool ar = AppLanguage.current == 'ar';

    return BaseGridPage(
      title: ar ? 'المشروبات' : 'Drinks',
      color: const Color(0xFF0288D1),
      items: [
        {'eye': 'closed', 'text': ar ? 'رجوع' : 'Back', 'iconAsset': 'assets/icons/back.png', 'color': const Color(0xFF455A64), 'is_nav': false, 'eye_name': eyeName('closed')},
        {'eye': 'left', 'text': ar ? 'مياه' : 'Water', 'iconAsset': 'assets/icons/water.png', 'color': const Color(0xFF29B6F6), 'is_nav': false, 'eye_name': eyeName('left')},
        {'eye': 'right', 'text': ar ? 'مشروبات ساخنة' : 'Hot Drinks', 'iconAsset': 'assets/icons/hot_drink.png', 'color': const Color(0xFFD84315), 'is_nav': true, 'eye_name': eyeName('right')},
        {'eye': 'up', 'text': ar ? 'عصائر باردة' : 'Cold Juices', 'iconAsset': 'assets/icons/juice.png', 'color': const Color(0xFFFFA000), 'is_nav': true, 'eye_name': eyeName('up')},
        {'eye': 'down', 'text': ar ? 'ألبان وبروتين' : 'Dairy & Protein', 'iconAsset': 'assets/icons/protein_shake.png', 'color': const Color(0xFF6A1B9A), 'is_nav': true, 'eye_name': eyeName('down')},
      ],
      onAction: (eye, ctx) async {
        if (eye == 'closed') { Navigator.pop(ctx); return; }

        if (eye == 'left') {
          VoiceService.speak(ar ? 'أريد أن أشرب ماء' : 'I want to drink water');
          return;
        }

        // فصلنا اللوجيك هنا علشان الكود يكون Clean ومش معقد
        if (eye == 'right') {
          await push(ctx, _buildHotDrinks(ar));
        } else if (eye == 'up') {
          await push(ctx, _buildColdJuices(ar));
        } else if (eye == 'down') {
          await push(ctx, _buildDairyProtein(ar));
        }
      },
    );
  }

  // ─── دوال مساعدة لترتيب الكود (Clean Code) ─────────────────────────

  Widget _buildHotDrinks(bool ar) {
    return SubItemsScreen(
      titleAr: 'مشروبات ساخنة', titleEn: 'Hot Drinks',
      options: [
        {'eye': 'left', 'text': ar ? 'شاي' : 'Tea', 'iconAsset': 'assets/icons/tea.png', 'color': const Color(0xFFD84315), 'eye_name': eyeName('left')},
        {'eye': 'right', 'text': ar ? 'قهوة' : 'Coffee', 'iconAsset': 'assets/icons/coffee.png', 'color': const Color(0xFF5D4037), 'eye_name': eyeName('right')},
        {'eye': 'up', 'text': ar ? 'أعشاب دافئة' : 'Herbal Tea', 'iconAsset': 'assets/icons/herbs.png', 'color': const Color(0xFF2E7D32), 'eye_name': eyeName('up')},
      ],
    );
  }

  Widget _buildColdJuices(bool ar) {
    return SubItemsScreen(
      titleAr: 'عصائر باردة', titleEn: 'Cold Juices',
      options: [
        {'eye': 'left', 'text': ar ? 'عصير برتقال' : 'Orange Juice', 'iconAsset': 'assets/icons/orange_juice.png', 'color': const Color(0xFFFF8F00), 'eye_name': eyeName('left')},
        {'eye': 'right', 'text': ar ? 'ليمون نعناع' : 'Lemon Mint', 'iconAsset': 'assets/icons/lemon_mint.png', 'color': const Color(0xFF64DD17), 'eye_name': eyeName('right')},
        {'eye': 'up', 'text': ar ? 'عصير تفاح' : 'Apple Juice', 'iconAsset': 'assets/icons/apple_juice.png', 'color': const Color(0xFFE53935), 'eye_name': eyeName('up')},
      ],
    );
  }

  Widget _buildDairyProtein(bool ar) {
    return SubItemsScreen(
      titleAr: 'ألبان وبروتين', titleEn: 'Dairy & Protein',
      options: [
        {'eye': 'left', 'text': ar ? 'حليب' : 'Milk', 'iconAsset': 'assets/icons/milk.png', 'color': const Color(0xFF1976D2), 'eye_name': eyeName('left')},
        {'eye': 'right', 'text': ar ? 'مشروب بروتين' : 'Protein Shake', 'iconAsset': 'assets/icons/protein_shake.png', 'color': const Color(0xFF8E24AA), 'eye_name': eyeName('right')},
        {'eye': 'up', 'text': ar ? 'زبادي شرب' : 'Yogurt Drink', 'iconAsset': 'assets/icons/yogurt_drink.png', 'color': const Color(0xFF0288D1), 'eye_name': eyeName('up')},
      ],
    );
  }
}