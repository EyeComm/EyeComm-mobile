import 'package:eye_comm_project/presentation/screens/basic_needs/widgets/sub_items_screen.dart';
import 'package:flutter/material.dart';
import '../../core/language_service.dart';
import '../../core/eye_utils.dart';
import '../../core/nav_helper.dart';
import '../../shared/base_grid_page.dart';

class SnacksScreen extends StatelessWidget {
  const SnacksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool ar = AppLanguage.current == 'ar';

    return BaseGridPage(
      title: ar ? 'سناكس' : 'Snacks',
      color: const Color(0xFF43A047),
      items: [
        {'eye': 'closed', 'text': ar ? 'رجوع' : 'Back', 'iconAsset': 'assets/icons/back.png', 'color': const Color(0xFF455A64), 'is_nav': false, 'eye_name': eyeName('closed')},
        {'eye': 'left', 'text': ar ? 'فواكه طازجة' : 'Fresh Fruits', 'iconAsset': 'assets/icons/fruits.png', 'color': const Color(0xFFE53935), 'is_nav': true, 'eye_name': eyeName('left')},
        {'eye': 'right', 'text': ar ? 'مكسرات صحية' : 'Healthy Nuts', 'iconAsset': 'assets/icons/nuts.png', 'color': const Color(0xFF795548), 'is_nav': true, 'eye_name': eyeName('right')},
        {'eye': 'up', 'text': ar ? 'مقرمشات خفيفة' : 'Light Snacks', 'iconAsset': 'assets/icons/popcorn.png', 'color': const Color(0xFFFBC02D), 'is_nav': true, 'eye_name': eyeName('up')},
        {'eye': 'down', 'text': ar ? 'مكملات وبروتين' : 'Protein & Sweets', 'iconAsset': 'assets/icons/protein_shake.png', 'color': const Color(0xFF8E24AA), 'is_nav': true, 'eye_name': eyeName('down')},
      ],
      onAction: (eye, ctx) async {
        if (eye == 'closed') { Navigator.pop(ctx); return; }

        if (eye == 'left') {
          await push(ctx, SubItemsScreen(titleAr: 'فواكه طازجة', titleEn: 'Fresh Fruits', options: [
            {'eye': 'left', 'text': ar ? 'تفاح' : 'Apple', 'iconAsset': 'assets/icons/apple.png', 'color': const Color(0xFFE53935), 'eye_name': eyeName('left')},
            {'eye': 'right', 'text': ar ? 'موز' : 'Banana', 'iconAsset': 'assets/icons/banana.png', 'color': const Color(0xFFFBC02D), 'eye_name': eyeName('right')},
            {'eye': 'up', 'text': ar ? 'برتقال' : 'Orange', 'iconAsset': 'assets/icons/orange.png', 'color': const Color(0xFFF57C00), 'eye_name': eyeName('up')},
          ]));
        } else if (eye == 'right') {
          await push(ctx, SubItemsScreen(titleAr: 'مكسرات صحية', titleEn: 'Healthy Nuts', options: [
            {'eye': 'left', 'text': ar ? 'حفنة لوز' : 'Almonds', 'iconAsset': 'assets/icons/almond.png', 'color': const Color(0xFF8D6E63), 'eye_name': eyeName('left')},
            {'eye': 'right', 'text': ar ? 'فول سوداني' : 'Peanuts', 'iconAsset': 'assets/icons/peanut.png', 'color': const Color(0xFF795548), 'eye_name': eyeName('right')},
            {'eye': 'up', 'text': ar ? 'مكسرات مشكلة' : 'Mixed Nuts', 'iconAsset': 'assets/icons/mixed_nuts.png', 'color': const Color(0xFF5D4037), 'eye_name': eyeName('up')},
          ]));
        } else if (eye == 'up') {
          await push(ctx, SubItemsScreen(titleAr: 'مقرمشات خفيفة', titleEn: 'Light Snacks', options: [
            {'eye': 'left', 'text': ar ? 'فشار كمية صغيرة' : 'Small Popcorn', 'iconAsset': 'assets/icons/popcorn.png', 'color': const Color(0xFFFBC02D), 'eye_name': eyeName('left')},
            {'eye': 'right', 'text': ar ? 'رايس كيك صحي' : 'Rice Cakes', 'iconAsset': 'assets/icons/rice_cake.png', 'color': const Color(0xFFF57F17), 'eye_name': eyeName('right')},
            {'eye': 'up', 'text': ar ? 'بسكويت مالح خفيف' : 'Crackers', 'iconAsset': 'assets/icons/crackers.png', 'color': const Color(0xFFF9A825), 'eye_name': eyeName('up')},
          ]));
        } else if (eye == 'down') {
          await push(ctx, SubItemsScreen(titleAr: 'مكملات وبروتين', titleEn: 'Protein Supplements', options: [
            {'eye': 'left', 'text': ar ? 'سكوب مشروب بروتين' : 'Protein Shake', 'iconAsset': 'assets/icons/protein_shake.png', 'color': const Color(0xFFAB47BC), 'eye_name': eyeName('left')},
            {'eye': 'right', 'text': ar ? 'بروتين بار صحي' : 'Protein Bar', 'iconAsset': 'assets/icons/protein_bar.png', 'color': const Color(0xFF8E24AA), 'eye_name': eyeName('right')},
            {'eye': 'up', 'text': ar ? 'مكعب شوكولاتة داكنة' : 'Dark Chocolate', 'iconAsset': 'assets/icons/chocolate.png', 'color': const Color(0xFF6A1B9A), 'eye_name': eyeName('up')},
          ]));
        }
      },
    );
  }
}