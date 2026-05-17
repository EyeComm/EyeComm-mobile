import 'package:flutter/material.dart';
import '../../core/language_service.dart';
import '../../core/voice_service.dart';
import '../../core/eye_utils.dart';
import '../../shared/base_grid_page.dart';

class ComfortScreen extends StatelessWidget {
  const ComfortScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool ar = AppLanguage.current == 'ar';

    return BaseGridPage(
      title: ar ? 'راحتي' : 'Comfort',
      color: const Color(0xFF8E24AA), // لون Purple
      items: [
        {'eye': 'closed', 'text': ar ? 'رجوع' : 'Back', 'iconAsset': 'assets/icons/back.png', 'color': const Color(0xFF455A64), 'is_nav': false, 'eye_name': eyeName('closed')},

        {'eye': 'left', 'text': ar ? 'تعديل وضعيتي' : 'Change Position', 'iconAsset': 'assets/icons/pillow.png', 'color': const Color(0xFF8E24AA), 'is_nav': false, 'eye_name': eyeName('left')},
        {'eye': 'right', 'text': ar ? 'أشعر بالبرد' : 'I Feel Cold', 'iconAsset': 'assets/icons/cold.png', 'color': const Color(0xFF1E88E5), 'is_nav': false, 'eye_name': eyeName('right')},
        {'eye': 'up', 'text': ar ? 'أشعر بالحر' : 'I Feel Hot', 'iconAsset': 'assets/icons/hot.png', 'color': const Color(0xFFE53935), 'is_nav': false, 'eye_name': eyeName('up')},
        {'eye': 'down', 'text': ar ? 'أشعر بحكة' : 'I Feel Itchy', 'iconAsset': 'assets/icons/itchy.png', 'color': const Color(0xFFF4511E), 'is_nav': false, 'eye_name': eyeName('down')},
      ],
      onAction: (eye, ctx) async {
        if (eye == 'closed') { Navigator.pop(ctx); return; }

        final msg = {
          'left': ar ? 'أريد تغيير وضعيتي في السرير أو تعديل الوسادة' : 'I need to change my position or adjust the pillow',
          'right': ar ? 'أنا بردان جداً، أحتاج إلى غطاء' : 'I feel cold, I need a blanket',
          'up': ar ? 'أنا حران، شغل المروحة أو التكييف' : 'I feel hot, please turn on the fan or AC',
          'down': ar ? 'أشعر بحكة مزعجة، هل يمكنك مساعدتي؟' : 'I feel itchy, can you please help me scratch?',
        }[eye];

        if (msg != null) VoiceService.speak(msg);
      },
    );
  }
}