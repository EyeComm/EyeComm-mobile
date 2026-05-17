import 'package:flutter/material.dart';
import '../../core/language_service.dart';
import '../../core/voice_service.dart';
import '../../core/eye_utils.dart';
import '../../shared/base_grid_page.dart';
import '../../../data/iot_service.dart';

class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key});

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  /// 'none' | 'emergency' | 'help'
  String _active = 'none';

  bool get _ar => AppLanguage.current == 'ar';

  @override
  Widget build(BuildContext context) => BaseGridPage(
        title: _ar ? '🚨 طوارئ' : '🚨 EMERGENCY',
        color: const Color(0xFFC62828),
        items: [
          {
            'eye':      'closed',
            'text':     _ar
                ? (_active == 'emergency' ? '🚨 طوارئ\nجاري الإرسال' : '🚨 طوارئ\nاضغط للإرسال')
                : (_active == 'emergency' ? '🚨 EMERGENCY\nSENT'       : '🚨 EMERGENCY\nTAP TO SEND'),
            'eye_name': eyeName('closed'),
            'color':    const Color(0xFFD32F2F),
            'is_nav':   false,
            'status':   _active == 'emergency',
          },
          {
            'eye':      'left',
            'text':     _ar
                ? (_active == 'help' ? '🆘 مساعدة\nجاري الإرسال' : '🆘 مساعدة\nاضغط للإرسال')
                : (_active == 'help' ? '🆘 HELP\nSENT'             : '🆘 HELP\nTAP TO SEND'),
            'eye_name': eyeName('left'),
            'color':    const Color(0xFFE65100),
            'is_nav':   false,
            'status':   _active == 'help',
          },
          {
            'eye':      'right',
            'text':     _ar ? '⏹️ إيقاف\nالتنبيه' : '⏹️ STOP\nALERT',
            'eye_name': eyeName('right'),
            'color':    const Color(0xFF546E7A),
            'is_nav':   false,
            'status':   _active == 'none',
          },
          {
            'eye':      'up',
            'text':     _ar ? '📞 اتصل\nبالمرافق' : '📞 CALL\nCAREGIVER',
            'eye_name': eyeName('up'),
            'color':    const Color(0xFF1565C0),
            'is_nav':   false,
            'status':   false,
          },
          {
            'eye':      'down',
            'text':     _ar ? '⬅️ رجوع' : '⬅️ BACK',
            'eye_name': eyeName('down'),
            'color':    const Color(0xFF455A64),
            'is_nav':   false,
            'status':   false,
          },
        ],
        onAction: (eye, ctx) async {
          switch (eye) {
            case 'closed':
              setState(() => _active = 'emergency');
              await IoTService.emergency();
              VoiceService.speak(_ar ? 'طوارئ' : 'Emergency');
              break;
            case 'left':
              setState(() => _active = 'help');
              await IoTService.help();
              VoiceService.speak(_ar ? 'مساعدة' : 'Help');
              break;
            case 'right':
              setState(() => _active = 'none');
              await IoTService.stopAll();
              VoiceService.speak(_ar ? 'توقف' : 'Stop');
              break;
            case 'up':
              VoiceService.speak(
                  _ar ? 'جاري الاتصال بالمرافق' : 'Calling caregiver');
              break;
            case 'down':
              Navigator.pop(ctx);
              break;
          }
        },
      );
}
