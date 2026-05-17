import 'package:eye_comm_project/presentation/screens/basic_needs/widgets/sub_items_screen.dart';
import 'package:flutter/material.dart';
import '../../core/language_service.dart';
import '../../core/eye_utils.dart';
import '../../core/nav_helper.dart';
import '../../shared/base_grid_page.dart';

class BreakfastScreen extends StatelessWidget {
  const BreakfastScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool ar = AppLanguage.current == 'ar';

    return BaseGridPage(
      title: ar ? 'الإفطار' : 'Breakfast',
      color: const Color(0xFFFBC02D),
      items: [
        {'eye': 'closed', 'text': ar ? 'رجوع' : 'Back', 'iconAsset': 'assets/icons/back.png', 'color': const Color(0xFF455A64), 'is_nav': false, 'eye_name': eyeName('closed')},
        {'eye': 'left', 'text': ar ? 'بيض' : 'Eggs', 'iconAsset': 'assets/icons/eggs.png', 'color': const Color(0xFFFBC02D), 'is_nav': true, 'eye_name': eyeName('left')},
        {'eye': 'right', 'text': ar ? 'أجبان وألبان' : 'Cheese & Dairy', 'iconAsset': 'assets/icons/cheese.png', 'color': const Color(0xFF1E88E5), 'is_nav': true, 'eye_name': eyeName('right')},
        {'eye': 'up', 'text': ar ? 'أكل شعبي' : 'Traditional', 'iconAsset': 'assets/icons/foul.png', 'color': const Color(0xFF6D4C41), 'is_nav': true, 'eye_name': eyeName('up')},
        {'eye': 'down', 'text': ar ? 'شوفان ومخبوزات' : 'Oats & Bread', 'iconAsset': 'assets/icons/oats.png', 'color': const Color(0xFF43A047), 'is_nav': true, 'eye_name': eyeName('down')},
      ],
      onAction: (eye, ctx) async {
        if (eye == 'closed') { Navigator.pop(ctx); return; }

        if (eye == 'left') {
          await push(ctx, SubItemsScreen(titleAr: 'البيض', titleEn: 'Eggs', options: [
            {'eye': 'left', 'text': ar ? 'بيض مسلوق' : 'Boiled Eggs', 'iconAsset': 'assets/icons/boiled_egg.png', 'color': const Color(0xFFFBC02D), 'eye_name': eyeName('left')},
            {'eye': 'right', 'text': ar ? 'بيض مقلي' : 'Fried Eggs', 'iconAsset': 'assets/icons/fried_egg.png', 'color': const Color(0xFFF57F17), 'eye_name': eyeName('right')},
            {'eye': 'up', 'text': ar ? 'أومليت' : 'Omelette', 'iconAsset': 'assets/icons/omelette.png', 'color': const Color(0xFFF9A825), 'eye_name': eyeName('up')},
          ]));
        } else if (eye == 'right') {
          await push(ctx, SubItemsScreen(titleAr: 'أجبان وألبان', titleEn: 'Cheese & Dairy', options: [
            {'eye': 'left', 'text': ar ? 'جبنة قريش' : 'Cottage Cheese', 'iconAsset': 'assets/icons/cottage.png', 'color': const Color(0xFF64B5F6), 'eye_name': eyeName('left')},
            {'eye': 'right', 'text': ar ? 'جبنة بيضاء' : 'White Cheese', 'iconAsset': 'assets/icons/feta.png', 'color': const Color(0xFF1E88E5), 'eye_name': eyeName('right')},
            {'eye': 'up', 'text': ar ? 'حليب' : 'Milk', 'iconAsset': 'assets/icons/milk.png', 'color': const Color(0xFF1565C0), 'eye_name': eyeName('up')},
          ]));
        } else if (eye == 'up') {
          await push(ctx, SubItemsScreen(titleAr: 'أكل شعبي', titleEn: 'Traditional', options: [
            {'eye': 'left', 'text': ar ? 'فول' : 'Foul', 'iconAsset': 'assets/icons/beans.png', 'color': const Color(0xFF8D6E63), 'eye_name': eyeName('left')},
            {'eye': 'right', 'text': ar ? 'طعمية' : 'Falafel', 'iconAsset': 'assets/icons/falafel.png', 'color': const Color(0xFF795548), 'eye_name': eyeName('right')},
            {'eye': 'up', 'text': ar ? 'بطاطس' : 'Potatoes', 'iconAsset': 'assets/icons/fries.png', 'color': const Color(0xFF5D4037), 'eye_name': eyeName('up')},
          ]));
        } else if (eye == 'down') {
          await push(ctx, SubItemsScreen(titleAr: 'شوفان ومخبوزات', titleEn: 'Oats & Bread', options: [
            {'eye': 'left', 'text': ar ? 'شوفان' : 'Oats', 'iconAsset': 'assets/icons/oatmeal.png', 'color': const Color(0xFF4CAF50), 'eye_name': eyeName('left')},
            {'eye': 'right', 'text': ar ? 'توست' : 'Toast', 'iconAsset': 'assets/icons/toast.png', 'color': const Color(0xFF388E3C), 'eye_name': eyeName('right')},
            {'eye': 'up', 'text': ar ? 'خبز' : 'Bread', 'iconAsset': 'assets/icons/bread.png', 'color': const Color(0xFF2E7D32), 'eye_name': eyeName('up')},
          ]));
        }
      },
    );
  }
}