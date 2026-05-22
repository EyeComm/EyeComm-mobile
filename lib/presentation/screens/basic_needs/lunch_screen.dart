import 'package:eye_comm_project/presentation/screens/basic_needs/widgets/sub_items_screen.dart';
import 'package:flutter/material.dart';
import '../../core/language_service.dart';
import '../../core/eye_utils.dart';
import '../../core/nav_helper.dart';
import '../../shared/base_grid_page.dart';

class LunchScreen extends StatelessWidget {
  const LunchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool ar = AppLanguage.current == 'ar';

    return BaseGridPage(
      title: ar ? 'الغداء' : 'Lunch',
      color: const Color(0xFFE53935),
      showCameraCard: true,
      cameraCardAspectRatio: 1.15,
      items: [
        {'eye': 'left', 'text': ar ? 'دجاج وطواجن' : 'Chicken', 'iconAsset': 'assets/icons/chicken.png', 'color': const Color(0xFFFB8C00), 'is_nav': true, 'eye_name': eyeName('left')},
        {'eye': 'up', 'text': ar ? 'نشويات' : 'Carbs', 'iconAsset': 'assets/icons/rice.png', 'color': const Color(0xFF0288D1), 'is_nav': true, 'eye_name': eyeName('up')},
        {'eye': 'right', 'text': ar ? 'لحوم وأسماك' : 'Meat & Fish', 'iconAsset': 'assets/icons/meat.png', 'color': const Color(0xFFE53935), 'is_nav': true, 'eye_name': eyeName('right')},
        {'eye': 'down', 'text': ar ? 'سلطة وخضار' : 'Veggies & Salad', 'iconAsset': 'assets/icons/salad.png', 'color': const Color(0xFF43A047), 'is_nav': true, 'eye_name': eyeName('down')},
        {'eye': 'closed', 'text': ar ? 'رجوع' : 'Back', 'iconAsset': 'assets/icons/back.png', 'color': const Color(0xFF455A64), 'is_nav': false, 'eye_name': eyeName('closed')},
      ],
      onAction: (eye, ctx) async {
        if (eye == 'closed') { Navigator.pop(ctx); return; }

        if (eye == 'left') {
          await push(ctx, SubItemsScreen(titleAr: 'دجاج وطواجن', titleEn: 'Chicken & Tagines', options: [
            {'eye': 'left', 'text': ar ? 'صدر دجاج مشوي' : 'Grilled Chicken Breast', 'iconAsset': 'assets/icons/grilled_chicken.png', 'color': const Color(0xFFFB8C00), 'eye_name': eyeName('left')},
            {'eye': 'up', 'text': ar ? 'شيش طاووق' : 'Shish Tawook', 'iconAsset': 'assets/icons/shish.png', 'color': const Color(0xFFEF6C00), 'eye_name': eyeName('up')},
            {'eye': 'right', 'text': ar ? 'فراخ بانيه' : 'Chicken Pane', 'iconAsset': 'assets/icons/pane.png', 'color': const Color(0xFFF57C00), 'eye_name': eyeName('right')},
          ]));
        } else if (eye == 'up') {
          await push(ctx, SubItemsScreen(titleAr: 'نشويات', titleEn: 'Carbs', options: [
            {'eye': 'left', 'text': ar ? 'أرز مدور معمر' : 'Roz Modawar', 'iconAsset': 'assets/icons/roz.png', 'color': const Color(0xFF039BE5), 'eye_name': eyeName('left')},
            {'eye': 'up', 'text': ar ? 'مكرونة' : 'Pasta', 'iconAsset': 'assets/icons/pasta.png', 'color': const Color(0xFF0277BD), 'eye_name': eyeName('up')},
            {'eye': 'right', 'text': ar ? 'أرز أبيض' : 'White Rice', 'iconAsset': 'assets/icons/white_rice.png', 'color': const Color(0xFF0288D1), 'eye_name': eyeName('right')},
          ]));
        } else if (eye == 'right') {
          await push(ctx, SubItemsScreen(titleAr: 'لحوم وأسماك', titleEn: 'Meat & Fish', options: [
            {'eye': 'left', 'text': ar ? 'ستيك مشوي' : 'Grilled Steak', 'iconAsset': 'assets/icons/steak.png', 'color': const Color(0xFFE53935), 'eye_name': eyeName('left')},
            {'eye': 'up', 'text': ar ? 'كفتة مشوية' : 'Grilled Kofta', 'iconAsset': 'assets/icons/kofta.png', 'color': const Color(0xFFC62828), 'eye_name': eyeName('up')},
            {'eye': 'right', 'text': ar ? 'سمك مشوي' : 'Grilled Fish', 'iconAsset': 'assets/icons/fish.png', 'color': const Color(0xFFD32F2F), 'eye_name': eyeName('right')},
          ]));
        } else if (eye == 'down') {
          await push(ctx, SubItemsScreen(titleAr: 'سلطة وخضار', titleEn: 'Veggies & Salad', options: [
            {'eye': 'left', 'text': ar ? 'سلطة خضراء' : 'Green Salad', 'iconAsset': 'assets/icons/green_salad.png', 'color': const Color(0xFF4CAF50), 'eye_name': eyeName('left')},
            {'eye': 'up', 'text': ar ? 'شوربة خضار' : 'Veggie Soup', 'iconAsset': 'assets/icons/soup.png', 'color': const Color(0xFF2E7D32), 'eye_name': eyeName('up')},
            {'eye': 'right', 'text': ar ? 'خضار سوتيه' : 'Sautéed Veggies', 'iconAsset': 'assets/icons/veg.png', 'color': const Color(0xFF388E3C), 'eye_name': eyeName('right')},
          ]));
        }
      },
    );
  }
}