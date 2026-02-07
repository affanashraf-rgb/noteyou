import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

// Import the new Navigation Menu we just created
import 'features/home/presentation/screens/navigation_menu.dart';

void main() {
  runApp(const ProviderScope(child: NoteYouApp()));
}

class NoteYouApp extends StatelessWidget {
  const NoteYouApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'NoteYou',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6C63FF),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF9F9F9),
            textTheme: GoogleFonts.poppinsTextTheme(),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
            ),
          ),

          // CHANGE: Set the home to NavigationMenu so the bottom bar works!
          home: const NavigationMenu(),
        );
      },
    );
  }
}