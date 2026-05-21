import 'package:eye_comm_project/presentation/screens/basic_needs/widgets/sub_items_screen.dart';
import 'package:flutter/material.dart';
import '../../core/language_service.dart';
import '../../core/eye_utils.dart';
import '../../core/nav_helper.dart';
import '../../shared/base_grid_page.dart';

class DinnerScreen extends StatelessWidget {
  const DinnerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool ar = AppLanguage.current == 'ar';

    return BaseGridPage(
      title: ar ? 'العشاء' : 'Dinner',
      color: const Color(0xFFF4511E),
      items: [
        {'eye': 'left', 'text': ar ? 'بروتين خفيف' : 'Light Protein', 'iconAsset': 'assets/icons/yogurt.png', 'color': const Color(0xFF039BE5), 'is_nav': true, 'eye_name': eyeName('left')},
        {'eye': 'up', 'text': ar ? 'شوربات دافئة' : 'Warm Soups', 'iconAsset': 'assets/icons/soup_bowl.png', 'color': const Color(0xFFFB8C00), 'is_nav': true, 'eye_name': eyeName('up')},
        {'eye': 'right', 'text': ar ? 'سلطات وعشاء خفيف' : 'Salads', 'iconAsset': 'assets/icons/salad_bowl.png', 'color': const Color(0xFF43A047), 'is_nav': true, 'eye_name': eyeName('right')},
        {'eye': 'down', 'text': ar ? 'باقي الغداء' : 'Leftovers', 'iconAsset': 'assets/icons/leftover.png', 'color': const Color(0xFF8D6E63), 'is_nav': true, 'eye_name': eyeName('down')},
        {'eye': 'closed', 'text': ar ? 'رجوع' : 'Back', 'iconAsset': 'assets/icons/back.png', 'color': const Color(0xFF455A64), 'is_nav': false, 'eye_name': eyeName('closed')},
      ],
      onAction: (eye, ctx) async {
        if (eye == 'closed') { Navigator.pop(ctx); return; }

        if (eye == 'left') {
          await push(ctx, SubItemsScreen(titleAr: 'بروتين خفيف', titleEn: 'Light Protein', options: [
            {'eye': 'left', 'text': ar ? 'علبة تونة' : 'Canned Tuna', 'iconAsset': 'assets/icons/tuna.png', 'color': const Color(0xFF29B6F6), 'eye_name': eyeName('left')},
            {'eye': 'up', 'text': ar ? 'بيض مسلوق' : 'Boiled Eggs', 'iconAsset': 'assets/icons/boiled_egg.png', 'color': const Color(0xFF0288D1), 'eye_name': eyeName('up')},
            {'eye': 'right', 'text': ar ? 'زبادي يوناني' : 'Greek Yogurt', 'iconAsset': 'assets/icons/greek_yogurt.png', 'color': const Color(0xFF039BE5), 'eye_name': eyeName('right')},
          ]));
        } else if (eye == 'up') {
          await push(ctx, SubItemsScreen(titleAr: 'شوربات دافئة', titleEn: 'Warm Soups', options: [
            {'eye': 'left', 'text': ar ? 'شوربة عدس' : 'Lentil Soup', 'iconAsset': 'assets/icons/lentil.png', 'color': const Color(0xFFFFA726), 'eye_name': eyeName('left')},
            {'eye': 'up', 'text': ar ? 'شوربة خضار صافية' : 'Clear Veggie Soup', 'iconAsset': 'assets/icons/veg_soup.png', 'color': const Color(0xFFF57C00), 'eye_name': eyeName('up')},
            {'eye': 'right', 'text': ar ? 'شوربة لسان عصفور' : 'Orzo Soup', 'iconAsset': 'assets/icons/chicken_soup.png', 'color': const Color(0xFFFB8C00), 'eye_name': eyeName('right')},
          ]));
        } else if (eye == 'right') {
          await push(ctx, SubItemsScreen(titleAr: 'سلطات وعشاء خفيف', titleEn: 'Salads & Light Dinner', options: [
            {'eye': 'left', 'text': ar ? 'سلطة خضراء' : 'Green Salad', 'iconAsset': 'assets/icons/green_salad.png', 'color': const Color(0xFF4CAF50), 'eye_name': eyeName('left')},
            {'eye': 'up', 'text': ar ? 'سلطة جبنة فيتا' : 'Feta Salad', 'iconAsset': 'assets/icons/feta_salad.png', 'color': const Color(0xFF2E7D32), 'eye_name': eyeName('up')},
            {'eye': 'right', 'text': ar ? 'سلطة دجاج مشوي' : 'Grilled Chicken Salad', 'iconAsset': 'assets/icons/chicken_salad.png', 'color': const Color(0xFF388E3C), 'eye_name': eyeName('right')},
          ]));
        } else if (eye == 'down') {
          await push(ctx, SubItemsScreen(titleAr: 'باقي الغداء', titleEn: 'Leftovers', options: [
            {'eye': 'left', 'text': ar ? 'باقي غداء اليوم' : 'Today\'s Lunch Leftovers', 'iconAsset': 'assets/icons/plate.png', 'color': const Color(0xFF8D6E63), 'eye_name': eyeName('left')},
            {'eye': 'up', 'text': ar ? 'توست خفيف' : 'Light Toast', 'iconAsset': 'assets/icons/toast.png', 'color': const Color(0xFF5D4037), 'eye_name': eyeName('up')},
            {'eye': 'right', 'text': ar ? 'أرز مدور معمر' : 'Roz Modawar', 'iconAsset': 'assets/icons/roz.png', 'color': const Color(0xFF795548), 'eye_name': eyeName('right')},
          ]));
        }
      },
    );
  }
}