import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../main.dart';
import 'settings_screen.dart';
import 'home_screen.dart';
import 'subjects_screen.dart';
import 'record_screen.dart';
import 'tasks_screen.dart';

class NavigationMenu extends ConsumerStatefulWidget {
  const NavigationMenu({super.key});

  @override
  ConsumerState<NavigationMenu> createState() => _NavigationMenuState();
}

class _NavigationMenuState extends ConsumerState<NavigationMenu> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SubjectsScreen(),
    const RecordScreen(),
    const TasksScreen(), // Added Tasks Screen
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: MaterialStateProperty.all(
            TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
          ),
        ),
        child: NavigationBar(
          height: 70.h,
          elevation: 0,
          backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
          selectedIndex: _selectedIndex,
          indicatorColor: Colors.transparent,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          destinations: [
            NavigationDestination(
              icon: Icon(Iconsax.home_2, color: isDarkMode ? Colors.white70 : Colors.grey),
              selectedIcon: const Icon(Iconsax.home_2, color: Color(0xFF3F6DFC)),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Iconsax.book, color: isDarkMode ? Colors.white70 : Colors.grey),
              selectedIcon: const Icon(Iconsax.book, color: Color(0xFF3F6DFC)),
              label: 'Subjects',
            ),
            NavigationDestination(
              icon: Icon(Iconsax.microphone_2, color: isDarkMode ? Colors.white70 : Colors.grey),
              selectedIcon: const Icon(Iconsax.microphone_2, color: Color(0xFF3F6DFC)),
              label: 'Record',
            ),
            NavigationDestination(
              icon: Icon(Iconsax.task_square, color: isDarkMode ? Colors.white70 : Colors.grey),
              selectedIcon: const Icon(Iconsax.task_square, color: Color(0xFF3F6DFC)),
              label: 'Tasks',
            ),
            NavigationDestination(
              icon: Icon(Iconsax.setting_2, color: isDarkMode ? Colors.white70 : Colors.grey),
              selectedIcon: const Icon(Iconsax.setting_2, color: Color(0xFF3F6DFC)),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
