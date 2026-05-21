import 'package:eye_comm_project/presentation/screens/basic_needs/comfort_screen.dart';
import 'package:eye_comm_project/presentation/screens/basic_needs/personal_care_screen.dart';
import 'package:flutter/material.dart';
import '../../core/language_service.dart';
import '../../core/voice_service.dart';
import '../../core/eye_utils.dart';
import '../../core/nav_helper.dart';
import '../../shared/base_grid_page.dart';
import 'drinks_screen.dart';
import 'food_screen.dart';

class BasicNeedsScreen extends StatelessWidget {
  const BasicNeedsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool ar = AppLanguage.current == 'ar';

    return BaseGridPage(
      title: ar ? 'الاحتياجات الأساسية' : 'Basic Needs',
      color: Colors.blue,
      items: [
        {'eye': 'left', 'text': ar ? 'طعام' : 'Food', 'iconAsset': 'assets/icons/food.png', 'color': Colors.red, 'is_nav': true, 'eye_name': eyeName('left')},
        {'eye': 'up', 'text': ar ? 'عناية ونظافة' : 'Personal Care', 'iconAsset': 'assets/icons/care.png', 'color': Colors.teal, 'is_nav': true, 'eye_name': eyeName('up')},
        {'eye': 'right', 'text': ar ? 'مشروبات' : 'Drinks', 'iconAsset': 'assets/icons/water.png', 'color': Colors.blue, 'is_nav': true, 'eye_name': eyeName('right')},
        {'eye': 'down', 'text': ar ? 'راحتي' : 'Comfort', 'iconAsset': 'assets/icons/comfort.png', 'color': Colors.purple, 'is_nav': true, 'eye_name': eyeName('down')},
        {'eye': 'closed', 'text': ar ? 'رجوع' : 'Back', 'iconAsset': 'assets/icons/back.png', 'color': Colors.grey, 'is_nav': false, 'eye_name': eyeName('closed')},
      ],
      onAction: (eye, ctx) async {
        switch (eye) {
          case 'left':   await push(ctx, const FoodScreen()); VoiceService.speak(ar ? 'طعام' : 'Food'); break;
          case 'up':     await push(ctx, const PersonalCareScreen()); VoiceService.speak(ar ? 'عناية' : 'Care'); break;
          case 'right':  await push(ctx, const DrinksScreen()); VoiceService.speak(ar ? 'مشروب' : 'Drink'); break;
          case 'down':   await push(ctx, const ComfortScreen()); VoiceService.speak(ar ? 'راحة' : 'Comfort'); break;
          case 'closed': VoiceService.speak(ar ? 'رجوع' : 'Going back'); Navigator.pop(ctx); break;
        }
      },
    );
  }
}