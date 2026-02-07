import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'settings_screen.dart';

// Import your screens
import 'home_screen.dart';
import 'subjects_screen.dart';
import 'record_screen.dart'; // <--- Make sure this import is here!

class NavigationMenu extends StatefulWidget {
  const NavigationMenu({super.key});

  @override
  State<NavigationMenu> createState() => _NavigationMenuState();
}

class _NavigationMenuState extends State<NavigationMenu> {
  int _selectedIndex = 0;

  // This list holds the screens for each tab
  final List<Widget> _screens = [
    const HomeScreen(),     // Index 0: Home
    const SubjectsScreen(), // Index 1: Subjects
    const RecordScreen(),   // Index 2: Record (Microphone)
    const SettingsScreen(),
    Container(),            // Index 3: Settings (Still empty for now)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // This shows the current screen based on the index
      body: _screens[_selectedIndex],

      // The Real Navigation Bar
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: MaterialStateProperty.all(
            TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
          ),
        ),
        child: NavigationBar(
          height: 70.h,
          elevation: 0,
          backgroundColor: Colors.white,
          selectedIndex: _selectedIndex,
          indicatorColor: Colors.transparent,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          destinations: [
            NavigationDestination(
              icon: Icon(Iconsax.home_2, color: Colors.grey),
              selectedIcon: Icon(Iconsax.home_2, color: Color(0xFF3F6DFC)),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Iconsax.book, color: Colors.grey),
              selectedIcon: Icon(Iconsax.book, color: Color(0xFF3F6DFC)),
              label: 'Subjects',
            ),
            NavigationDestination(
              icon: Icon(Iconsax.microphone_2, color: Colors.grey),
              selectedIcon: Icon(Iconsax.microphone_2, color: Color(0xFF3F6DFC)),
              label: 'Record',
            ),
            NavigationDestination(
              icon: Icon(Iconsax.setting_2, color: Colors.grey),
              selectedIcon: Icon(Iconsax.setting_2, color: Color(0xFF3F6DFC)),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}