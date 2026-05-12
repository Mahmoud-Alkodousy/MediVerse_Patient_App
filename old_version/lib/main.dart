import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/constants/app_colors.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor:       Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MediVerseApp());
}

class MediVerseApp extends StatelessWidget {
  const MediVerseApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize:     const Size(390, 844),
      minTextAdapt:   true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title:                    'MediVerse',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            scaffoldBackgroundColor: AppColors.bgDeep,
            primaryColor:            AppColors.primary,
            colorScheme: ColorScheme.dark(
              primary:   AppColors.primary,
              secondary: AppColors.accent,
              surface:   AppColors.bgCard,
              background: AppColors.bgDeep,
            ),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: AppColors.textPrimary),
            ),
            useMaterial3: true,
          ),
          home: const LoginScreen(),
        );
      },
    );
  }
}
