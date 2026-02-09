import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../main.dart'; 
import 'profile_info_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // --- STATE VARIABLES ---
  String _userName = "Affan Ashraf";
  String _userEmail = "affan@example.com";
  bool _notificationsEnabled = true;
  String _language = "English";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? "Affan Ashraf";
      _userEmail = prefs.getString('userEmail') ?? "affan@example.com";
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _language = prefs.getString('language') ?? "English";
      _isLoading = false;
    });
  }

  void _navigateToProfileInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileInfoScreen(
          currentName: _userName,
          currentEmail: _userEmail,
          onUpdate: (name, email) {
            setState(() {
              _userName = name;
              _userEmail = email;
            });
          },
        ),
      ),
    );
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);
    setState(() => _notificationsEnabled = value);
  }

  void _showLanguageDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Select Language", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 20.h),
            _languageOption("English"),
            _languageOption("Urdu"),
            _languageOption("Spanish"),
            _languageOption("French"),
          ],
        ),
      ),
    );
  }

  Widget _languageOption(String lang) {
    return ListTile(
      title: Text(lang),
      trailing: _language == lang ? const Icon(Icons.check, color: Color(0xFF3F6DFC)) : null,
      onTap: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('language', lang);
        setState(() => _language = lang);
        if (mounted) Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20.h),

            // --- PROFILE CARD ---
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(25.r),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30.r,
                    backgroundColor: const Color(0xFF3F6DFC).withOpacity(0.1),
                    child: Icon(Iconsax.user, size: 30.sp, color: const Color(0xFF3F6DFC)),
                  ),
                  SizedBox(width: 15.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_userName, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                        Text(_userEmail, style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
                        SizedBox(height: 5.h),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                          decoration: BoxDecoration(color: const Color(0xFF3F6DFC).withOpacity(0.1), borderRadius: BorderRadius.circular(5.r)),
                          child: Text("PRO PLAN", style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: const Color(0xFF3F6DFC))),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _navigateToProfileInfo,
                    icon: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(15.r)),
                      child: Text("Edit", style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),

            SizedBox(height: 30.h),

            // --- SECTIONS ---
            _sectionHeader("ACCOUNT"),
            _buildSettingTile(icon: Iconsax.user, title: "Profile Information", isDarkMode: isDarkMode, onTap: _navigateToProfileInfo),
            _buildSettingTile(icon: Iconsax.notification, title: "Notifications", isDarkMode: isDarkMode, trailing: Switch(
              value: _notificationsEnabled,
              onChanged: _toggleNotifications,
              activeColor: const Color(0xFF3F6DFC),
            )),
            _buildSettingTile(icon: Iconsax.shield_security, title: "Security & Privacy", isDarkMode: isDarkMode, onTap: () {}),

            SizedBox(height: 20.h),
            _sectionHeader("APP SETTINGS"),
            _buildSettingTile(icon: Iconsax.global, title: "Language", isDarkMode: isDarkMode, subtitle: _language, onTap: _showLanguageDialog),
            _buildSettingTile(icon: Iconsax.moon, title: "Dark Mode", isDarkMode: isDarkMode, trailing: Switch(
              value: isDarkMode,
              onChanged: (val) => ref.read(themeProvider.notifier).toggleTheme(val),
              activeColor: const Color(0xFF3F6DFC),
            )),

            SizedBox(height: 30.h),
            Center(child: Text("Version 1.0.0", style: TextStyle(color: Colors.grey, fontSize: 12.sp))),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Text(title, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
    );
  }

  Widget _buildSettingTile({required IconData icon, required String title, required bool isDarkMode, String? subtitle, Widget? trailing, VoidCallback? onTap}) {
    return Container(
      margin: EdgeInsets.only(bottom: 15.h),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(color: isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFF2F4F7), borderRadius: BorderRadius.circular(12.r)),
          child: Icon(icon, color: isDarkMode ? Colors.white70 : Colors.black87, size: 20.sp),
        ),
        title: Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12.sp, color: Colors.grey)) : null,
        trailing: trailing ?? Icon(Icons.arrow_forward_ios, size: 14.sp, color: Colors.grey),
      ),
    );
  }
}
