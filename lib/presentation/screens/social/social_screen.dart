import 'package:eye_comm_project/presentation/screens/caregiver/CaregiverScreen.dart';
import 'package:flutter/material.dart';
import '../../core/language_service.dart';
import '../../core/eye_utils.dart';
import '../../core/nav_helper.dart';
import '../../shared/base_grid_page.dart';
import '../basic_needs/widgets/sub_items_screen.dart';

class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool ar = AppLanguage.current == 'ar';

    return BaseGridPage(
      title: ar ? 'تواصل اجتماعي' : 'Social',
      color: const Color(0xFF0DB868),
      showCameraCard: true,
      cameraCardAspectRatio: 1.15,
      items: [
        // 1. اليسار
        {
          'eye': 'left',
          'text': ar ? 'ردود سريعة' : 'Quick Phrases',
          'iconAsset': 'assets/icons/chat.png',
          'color': const Color(0xFF00897B),
          'is_nav': true,
          'eye_name': eyeName('left')
        },
        // 2. الأعلى
        {
          'eye': 'up',
          'text': ar ? 'تحيات ومجاملات' : 'Greetings',
          'iconAsset': 'assets/icons/handshake.png',
          'color': const Color(0xFF3949AB),
          'is_nav': true,
          'eye_name': eyeName('up')
        },
        // 3. اليمين
        {
          'eye': 'right',
          'text': ar ? 'مشاعري' : 'My Feelings',
          'iconAsset': 'assets/icons/feelings.png',
          'color': const Color(0xFFD81B60),
          'is_nav': true,
          'eye_name': eyeName('right')
        },
        // 4. الأسفل
        {
          'eye': 'down',
          'text': ar ? 'نداء المرافق' : 'Caregiver',
          'iconAsset': 'assets/icons/caregiver.png',
          'color': const Color(0xFFE64A19),
          'is_nav': true,
          'eye_name': eyeName('down')
        },
        // 5. الإغلاق (رجوع)
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
          case 'left':   await push(ctx, _buildQuickPhrases(ar)); break;
          case 'up':     await push(ctx, _buildGreetings(ar)); break;
          case 'right':  await push(ctx, _buildFeelings(ar)); break;
          case 'down':   await push(ctx, const CaregiverScreen()); break;
          case 'closed': Navigator.pop(ctx); break;
        }
      },
    );
  }

  Widget _buildQuickPhrases(bool ar) {
    return SubItemsScreen(
      titleAr: 'ردود سريعة',
      titleEn: 'Quick Phrases',
      options: [
        {
          'eye': 'left',
          'text': ar ? 'نعم / بالتأكيد' : 'Yes / Sure',
          'iconAsset': 'assets/icons/yes.png',
          'color': const Color(0xFF43A047),
          'eye_name': eyeName('left')
        },
        {
          'eye': 'up',
          'text': ar ? 'شكراً لك' : 'Thank You',
          'iconAsset': 'assets/icons/thanks.png',
          'color': const Color(0xFF00ACC1),
          'eye_name': eyeName('up')
        },
        {
          'eye': 'right',
          'text': ar ? 'لا / أرفض' : 'No / Never',
          'iconAsset': 'assets/icons/no.png',
          'color': const Color(0xFFE53935),
          'eye_name': eyeName('right')
        },
        {
          'eye': 'down',
          'text': ar ? 'لا أعرف / لست متأكداً' : 'I don\'t know',
          'iconAsset': 'assets/icons/dont_know.png',
          'color': const Color(0xFF757575),
          'eye_name': eyeName('down')
        },
      ],
    );
  }

  Widget _buildFeelings(bool ar) {
    return SubItemsScreen(
      titleAr: 'مشاعري',
      titleEn: 'My Feelings',
      options: [
        {
          'eye': 'left',
          'text': ar ? 'أشعر بالسعادة والراحة' : 'I feel happy and relaxed',
          'iconAsset': 'assets/icons/happy.png',
          'color': const Color(0xFFFBC02D),
          'eye_name': eyeName('left')
        },
        {
          'eye': 'up',
          'text': ar ? 'أنا غاضب ومحبط الآن' : 'I am angry and frustrated',
          'iconAsset': 'assets/icons/angry.png',
          'color': const Color(0xFFD32F2F),
          'eye_name': eyeName('up')
        },
        {
          'eye': 'right',
          'text': ar ? 'أشعر بالحزن أو الضيق' : 'I feel sad or upset',
          'iconAsset': 'assets/icons/sad.png',
          'color': const Color(0xFF1E88E5),
          'eye_name': eyeName('right')
        },
        {
          'eye': 'down',
          'text': ar ? 'أشعر بالقلق والخوف' : 'I feel anxious and scared',
          'iconAsset': 'assets/icons/anxious.png',
          'color': const Color(0xFF8E24AA),
          'eye_name': eyeName('down')
        },
      ],
    );
  }

  Widget _buildGreetings(bool ar) {
    return SubItemsScreen(
      titleAr: 'تحيات ومجاملات',
      titleEn: 'Greetings',
      options: [
        {
          'eye': 'left',
          'text': ar ? 'مرحباً، أهلاً بك' : 'Hello, Welcome',
          'iconAsset': 'assets/icons/hello.png',
          'color': const Color(0xFF3949AB),
          'eye_name': eyeName('left')
        },
        {
          'eye': 'up',
          'text': ar ? 'مع السلامة، أراك لاحقاً' : 'Goodbye, see you later',
          'iconAsset': 'assets/icons/goodbye.png',
          'color': const Color(0xFF8E24AA),
          'eye_name': eyeName('up')
        },
        {
          'eye': 'right',
          'text': ar ? 'كيف حالك؟' : 'How are you?',
          'iconAsset': 'assets/icons/how_are_you.png',
          'color': const Color(0xFF00897B),
          'eye_name': eyeName('right')
        },
        {
          'eye': 'down',
          'text': ar ? 'تصبح على خير' : 'Good night',
          'iconAsset': 'assets/icons/good_night.png',
          'color': const Color(0xFF283593),
          'eye_name': eyeName('down')
        },
      ],
    );
  }
}