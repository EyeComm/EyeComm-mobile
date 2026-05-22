import 'package:eye_comm_project/presentation/screens/basic_needs/basic_needs_screen.dart';
import 'package:eye_comm_project/presentation/screens/health/HealthScreen.dart';
import 'package:eye_comm_project/presentation/screens/social/social_screen.dart';
import 'package:flutter/material.dart';
import '../../core/language_service.dart';
import '../../core/voice_service.dart';
import '../../core/emergency_service.dart';
import '../../core/eye_utils.dart';
import '../../core/nav_helper.dart';
import '../../shared/base_grid_page.dart';
import '../language/language_selection_page.dart';
import '../smart_control/smart_control_main.dart';
import '../keyboard/keyboard_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String _warningMsg = '';
  Color _warningColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    EmergencyDetector.onWarning = (int s) {
      if (!mounted) return;
      setState(() {
        if (s >= 270) {
          _warningMsg = AppLanguage.t('emergency_alert');
          _warningColor = Colors.red;
        } else if (s >= 210) {
          _warningMsg = AppLanguage.t('no_movement_warn');
          _warningColor = Colors.orange;
        } else if (s >= 150) {
          _warningMsg = AppLanguage.t('are_you_ok');
          _warningColor = Colors.amber.shade700;
        } else {
          _warningMsg = '';
          _warningColor = Colors.transparent;
        }
      });
    };

    Future.delayed(const Duration(milliseconds: 600), () {
      VoiceService.speak(AppLanguage.current == 'ar'
          ? 'أهلاً، استخدم عينيك للتنقل'
          : 'Welcome to EyeComm. Use your eyes to navigate.');
    });
  }

  @override
  void dispose() {
    EmergencyDetector.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 الترتيب هنا اتعدل عشان يترص صح في الـ BaseGridPage
    // الصف الأول (هياخد 3 كروت على الشاشات العريضة): شمال، أعلى (في النص)، يمين
    // الصف التاني (هياخد كارتين): إغلاق، أسفل
    final List<Map<String, dynamic>> menuItems = [
      {
        'eye': 'left',
        'text': AppLanguage.t("health"),
        'iconAsset': 'assets/health.png', // تأكدي إن عندك الأيقونات أو استخدمي الإيموجي لو لسه مغيرتيهاش
        'color': const Color(0xFFE8762B),
        'eye_name': eyeName('left'),
        'page': () => const HealthScreen(),
      },
      {
        'eye': 'up',
        'text': AppLanguage.t("social"),
        'iconAsset': 'assets/social.png',
        'color': const Color(0xFF0DB868),
        'eye_name': eyeName('up'),
        'page': () => const SocialScreen(),
      },
      {
        'eye': 'right',
        'text': AppLanguage.t("smart"),
        'iconAsset': 'assets/smart_home.png',
        'color': const Color(0xFF7C2BE8),
        'eye_name': eyeName('right'),
        'page': () => const SmartControlMain(),
      },
      {
        'eye': 'closed',
        'text': AppLanguage.t("basic"),
        'iconAsset': 'assets/basic-needs.png',
        'color': const Color(0xFF2B8EE8),
        'eye_name': eyeName('closed'),
        'page': () => const BasicNeedsScreen(),
      },
      {
        'eye': 'down',
        'text': AppLanguage.t("keyboard"),
        'iconAsset': 'assets/keyboard.png',
        'color': const Color(0xFFE82B6A),
        'eye_name': eyeName('down'),
        'page': () => const KeyboardPage(),
      },
    ];

    return BaseGridPage(
      title: AppLanguage.current == 'ar' ? 'الرئيسية' : 'EyeComm',
      color: const Color(0xFF2B8EE8),
      items: menuItems,
      isMainScreen: true,
      showCameraCard: true,
      cameraCardAspectRatio: 1.15,
      warningMsg: _warningMsg,
      warningColor: _warningColor,
      onLangTap: () => pushReplacement(context, const LanguageSelectionPage()),
      onAction: (String eye, BuildContext ctx) async {
        final item =
        menuItems.firstWhere((m) => m['eye'] == eye, orElse: () => {});
        if (item.isEmpty) return;
        VoiceService.speak(item['text'].toString().trim());
        await push(ctx, item['page']() as Widget);
      },
    );
  }
}