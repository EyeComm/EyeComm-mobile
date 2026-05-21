import 'package:eye_comm_project/presentation/screens/basic_needs/snacks_screen.dart';
import 'package:flutter/material.dart';
import '../../core/language_service.dart';
import '../../core/eye_utils.dart';
import '../../core/nav_helper.dart';
import '../../shared/base_grid_page.dart';
import 'breakfast_screen.dart';
import 'dinner_screen.dart';
import 'lunch_screen.dart';

class FoodScreen extends StatelessWidget {
  const FoodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool ar = AppLanguage.current == 'ar';

    return BaseGridPage(
      title: ar ? 'وجبات الطعام' : 'Meals',
      color: const Color(0xFFE53935),
      items: [
        {'eye': 'left', 'text': ar ? 'إفطار' : 'Breakfast', 'iconAsset': 'assets/icons/breakfast.png', 'color': const Color(0xFFFBC02D), 'is_nav': true, 'eye_name': eyeName('left')},
        {'eye': 'up', 'text': ar ? 'غداء' : 'Lunch', 'iconAsset': 'assets/icons/lunch.png', 'color': const Color(0xFFE53935), 'is_nav': true, 'eye_name': eyeName('up')},
        {'eye': 'right', 'text': ar ? 'عشاء' : 'Dinner', 'iconAsset': 'assets/icons/dinner.png', 'color': const Color(0xFFF4511E), 'is_nav': true, 'eye_name': eyeName('right')},
        {'eye': 'down', 'text': ar ? 'سناكس' : 'Snacks', 'iconAsset': 'assets/icons/snacks.png', 'color': const Color(0xFF43A047), 'is_nav': true, 'eye_name': eyeName('down')},
        {'eye': 'closed', 'text': ar ? 'رجوع' : 'Back', 'iconAsset': 'assets/icons/back.png', 'color': const Color(0xFF455A64), 'is_nav': false, 'eye_name': eyeName('closed')},
      ],
      onAction: (eye, ctx) async {
        switch (eye) {
          case 'left':   await push(ctx, const BreakfastScreen()); break;
          case 'up':     await push(ctx, const LunchScreen()); break;
          case 'right':  await push(ctx, const DinnerScreen()); break;
          case 'down':   await push(ctx, const SnacksScreen()); break;
          case 'closed': Navigator.pop(ctx); break;
        }
      },
    );
  }
}