import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
 
import 'presentation/core/app_theme.dart';
import 'presentation/core/language_service.dart';
import 'presentation/shared/eye_tracker_dots.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/smart_control/smart_home_hall_cubit.dart';
import 'presentation/screens/smart_control/smart_home_room_cubit.dart';
import 'presentation/screens/smart_control/wheelchair_cubit.dart';
import 'presentation/screens/smart_control/smart_home_hub_cubit.dart';
import 'presentation/screens/emergency/emergency_cubit.dart';
 
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
 
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
 
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
 
  await AppLanguage.init();
 
  runApp(const EyeCommApp());
}
 
class EyeCommApp extends StatelessWidget {
  const EyeCommApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<EmergencyCubit>(
          create: (context) => EmergencyCubit(),
        ),
        BlocProvider<SmartHomeHubCubit>(
          create: (context) => SmartHomeHubCubit(),
        ),
        BlocProvider<SmartHomeHallCubit>(
          create: (context) => SmartHomeHallCubit(),
        ),
        BlocProvider<SmartHomeRoomCubit>(
          create: (context) => SmartHomeRoomCubit(),
        ),
        BlocProvider<WheelchairCubit>(
          create: (context) => WheelchairCubit(),
        ),
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
        builder: (ctx, child) => EyeTrackerDots(child: child!),
        home: const SplashScreen(),
      ),
    );
  }
}