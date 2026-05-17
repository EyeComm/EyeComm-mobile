import 'package:flutter/material.dart';
import '../../core/language_service.dart';
import '../../core/voice_service.dart';
import '../../core/eye_utils.dart';
import '../../shared/base_grid_page.dart';

class MedicationScreen extends StatelessWidget {
  const MedicationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool ar = AppLanguage.current == 'ar';

    return BaseGridPage(
      title: ar ? 'الأدوية' : 'Medication',
      color: const Color(0xFF1976D2),
      items: [
        {'eye': 'closed', 'text': ar ? 'رجوع' : 'Back', 'iconAsset': 'assets/icons/back.png', 'color': const Color(0xFF455A64), 'is_nav': false, 'eye_name': eyeName('closed')},

        {'eye': 'left', 'text': ar ? 'مسكن ألم' : 'Painkiller', 'iconAsset': 'assets/icons/painkiller.png', 'color': const Color(0xFFE53935), 'is_nav': false, 'eye_name': eyeName('left')},
        {'eye': 'right', 'text': ar ? 'دواء التشنجات' : 'Spasm Meds', 'iconAsset': 'assets/icons/muscle_spasm.png', 'color': const Color(0xFF8E24AA), 'is_nav': false, 'eye_name': eyeName('right')},
        {'eye': 'up', 'text': ar ? 'دواء الموعد الأساسي' : 'Scheduled Meds', 'iconAsset': 'assets/icons/pills.png', 'color': const Color(0xFF43A047), 'is_nav': false, 'eye_name': eyeName('up')},
        {'eye': 'down', 'text': ar ? 'مراجعة الطبيب' : 'Call Doctor', 'iconAsset': 'assets/icons/doctor.png', 'color': const Color(0xFF0288D1), 'is_nav': false, 'eye_name': eyeName('down')},
      ],
      onAction: (eye, ctx) async {
        if (eye == 'closed') { Navigator.pop(ctx); return; }

        final msg = {
          'left': ar ? 'أحتاج إلى مسكن للألم من فضلك' : 'I need a painkiller please',
          'right': ar ? 'أحتاج إلى دواء التشنجات العضلية' : 'I need my muscle spasm medication',
          'up': ar ? 'لقد حان موعد دوائي الأساسي' : 'It is time for my scheduled medication',
          'down': ar ? 'أريد مراجعة الطبيب أو الممرض بخصوص أدويتي' : 'I need to see the doctor or nurse regarding my meds',
        }[eye];

        if (msg != null) VoiceService.speak(msg);
      },
    );
  }
}