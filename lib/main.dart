import 'package:eye_comm_project/presentation/screens/smart_control/smart_home_hall_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // 🎯 ضفنا الاستيراد ده عشان البلوك

import 'presentation/core/app_theme.dart';
import 'presentation/core/language_service.dart';
import 'presentation/shared/eye_tracker_dots.dart';
import 'presentation/screens/splash/splash_screen.dart';

// 🎯 ضيفي استيراد ملف الـ Cubit بتاع الصالة هنا (راجعي المسار لو مختلف عندك)

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Full immersive mode — no system bars.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Lock to portrait by default.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Init language + TTS.
  await AppLanguage.init();

  runApp(const EyeCommApp());
}

class EyeCommApp extends StatelessWidget {
  const EyeCommApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 🎯 هنا لفينا التطبيق بـ MultiBlocProvider عشان الـ Cubit يعيش برا الشاشات
    return MultiBlocProvider(
      providers: [
        BlocProvider<SmartHomeHallCubit>(
          create: (context) => SmartHomeHallCubit(),
        ),
        // لو عندك أي كيوبيت تاني (زي أوضة النوم مثلاً) وعاوزاه يحتفظ بحالته، ضيفيه هنا تحت ده
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'EyeComm',
        theme: ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: kBg,
          colorScheme: ColorScheme.fromSeed(
            seedColor: kAppBar,
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.cairoTextTheme(),
          useMaterial3: true,
        ),
        // Overlay calibration dots on every screen.
        builder: (ctx, child) => EyeTrackerDots(child: child!),
        home: const SplashScreen(),
      ),
    );
  }
}