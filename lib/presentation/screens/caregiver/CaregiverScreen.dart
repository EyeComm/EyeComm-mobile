import 'package:flutter/material.dart';
import '../../core/language_service.dart';
import '../../core/voice_service.dart';
import '../../core/eye_utils.dart';
import '../../shared/base_grid_page.dart';
import '../../../data/notification_service.dart'; // خدمة الإشعارات اللي هنعملها

class CaregiverScreen extends StatelessWidget {
  const CaregiverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool ar = AppLanguage.current == 'ar';

    return BaseGridPage(
      title: ar ? 'نداء المرافق' : 'Call Caregiver',
      color: const Color(0xFFE64A19), // لون برتقالي داكن يعطي إحساس بالأهمية
      items: [
        {'eye': 'closed', 'text': ar ? 'رجوع' : 'Back', 'iconAsset': 'assets/icons/back.png', 'color': const Color(0xFF455A64), 'is_nav': false, 'eye_name': eyeName('closed')},

        {'eye': 'left', 'text': ar ? 'تعال فوراً!' : 'Come Now!', 'iconAsset': 'assets/icons/urgent.png', 'color': const Color(0xFFD32F2F), 'is_nav': false, 'eye_name': eyeName('left')},
        {'eye': 'right', 'text': ar ? 'أحتاج مساعدة' : 'Need Help', 'iconAsset': 'assets/icons/help.png', 'color': const Color(0xFFF57C00), 'is_nav': false, 'eye_name': eyeName('right')},
        {'eye': 'up', 'text': ar ? 'طوارئ طبية' : 'Emergency', 'iconAsset': 'assets/icons/siren.png', 'color': const Color(0xFFB71C1C), 'is_nav': false, 'eye_name': eyeName('up')},
        {'eye': 'down', 'text': ar ? 'أنا بخير' : 'I am Fine', 'iconAsset': 'assets/icons/happy.png', 'color': const Color(0xFF388E3C), 'is_nav': false, 'eye_name': eyeName('down')},
      ],
      onAction: (eye, ctx) async {
        if (eye == 'closed') { Navigator.pop(ctx); return; }

        String title = '';
        String body = '';
        String voiceMsg = '';

        // تحديد محتوى الإشعار بناءً على نظرة المريض
        if (eye == 'left') {
          title = ar ? 'نداء عاجل' : 'Urgent Call';
          body = ar ? 'المريض يحتاجك في الغرفة فوراً!' : 'Patient needs you immediately!';
          voiceMsg = ar ? 'تم إرسال نداء عاجل للمرافق' : 'Urgent call sent';
        } else if (eye == 'right') {
          title = ar ? 'طلب مساعدة' : 'Need Help';
          body = ar ? 'المريض يطلب مساعدتك' : 'Patient requested your help';
          voiceMsg = ar ? 'تم إرسال طلب المساعدة' : 'Help request sent';
        } else if (eye == 'up') {
          title = ar ? '🚨 طوارئ طبية 🚨' : '🚨 MEDICAL EMERGENCY 🚨';
          body = ar ? 'توجه للمريض فوراً، حالة طوارئ!' : 'Go to patient immediately!';
          voiceMsg = ar ? 'تم إرسال إنذار الطوارئ' : 'Emergency alert sent';
        } else if (eye == 'down') {
          title = ar ? 'رسالة طمأنينة' : 'Reassurance';
          body = ar ? 'المريض يخبرك أنه بخير ولا يحتاج شيئاً' : 'Patient is fine and needs nothing';
          voiceMsg = ar ? 'تم إرسال رسالة الطمأنة' : 'Reassurance message sent';
        }

        if (title.isNotEmpty) {
          // 1. التطبيق ينطق فوراً ليطمئن المريض (بدون Await)
          VoiceService.speak(voiceMsg);

          // 2. إرسال الإشعار لـ Firebase في الخلفية (Fire and forget)
          NotificationService.sendToCaregiver(title: title, body: body);
        }
      },
    );
  }
}