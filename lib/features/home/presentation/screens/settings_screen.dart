import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';

// Enum to manage which view is currently active
enum SettingsView { main, profile, notifications, language, security, storage, offline, help }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // State Management
  SettingsView _currentView = SettingsView.main;

  // Notification States
  bool _pushEnabled = true;
  bool _emailEnabled = false;
  bool _lectureReminders = true;

  // App Settings States
  bool _isDarkMode = false;
  String _selectedLanguage = "English";

  // --- MAIN BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    // We use AnimatedSwitcher for smooth transitions between "pages"
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.1, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ));
          },
          child: _buildCurrentView(),
        ),
      ),
    );
  }

  // --- VIEW ROUTER ---
  Widget _buildCurrentView() {
    switch (_currentView) {
      case SettingsView.main:
        return _buildMainView();
      case SettingsView.profile:
        return _buildProfileView();
      case SettingsView.notifications:
        return _buildNotificationsView();
      case SettingsView.language:
        return _buildLanguageView();
      case SettingsView.security:
        return _buildSecurityView();
      case SettingsView.storage:
        return _buildStorageView();
      case SettingsView.offline:
        return _buildOfflineView();
      case SettingsView.help:
        return _buildHelpView();
    }
  }

  // ===========================================================================
  // 1. MAIN SETTINGS DASHBOARD
  // ===========================================================================
  Widget _buildMainView() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      physics: const BouncingScrollPhysics(),
      key: const ValueKey('MainView'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Settings",
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              // Hidden spacer or extra icon if needed
            ],
          ),
          SizedBox(height: 25.h),

          // Profile Card
          Container(
            padding: EdgeInsets.all(15.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 60.w,
                  height: 60.w,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                    image: const DecorationImage(
                      image: NetworkImage("https://api.dicebear.com/7.x/avataaars/png?seed=Affan"), // Used png for Flutter
                    ),
                  ),
                ),
                SizedBox(width: 15.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Affan Ashraf",
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      Text(
                        "affan@example.com",
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
                      ),
                      SizedBox(height: 5.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3F6DFC).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          "PRO PLAN",
                          style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: const Color(0xFF3F6DFC)),
                        ),
                      )
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _currentView = SettingsView.profile),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r), side: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Text("Edit", style: TextStyle(fontSize: 12.sp, color: Colors.black87)),
                )
              ],
            ),
          ),

          SizedBox(height: 25.h),

          // Account Section
          _buildSectionHeader("ACCOUNT"),
          _buildSettingsGroup([
            _buildTile(Iconsax.user, Colors.blue, "Profile Information", onTap: () => setState(() => _currentView = SettingsView.profile)),
            _buildTile(Iconsax.notification, Colors.amber, "Notifications", onTap: () => setState(() => _currentView = SettingsView.notifications)),
            _buildTile(Iconsax.shield_tick, Colors.green, "Security & Privacy", onTap: () => setState(() => _currentView = SettingsView.security)),
          ]),

          SizedBox(height: 25.h),

          // App Settings Section
          _buildSectionHeader("APP SETTINGS"),
          _buildSettingsGroup([
            _buildTile(Iconsax.global, const Color(0xFF3F6DFC), "Language", trailingText: _selectedLanguage, onTap: () => setState(() => _currentView = SettingsView.language)),
            _buildTile(Iconsax.moon, Colors.indigo, "Dark Mode", isSwitch: true, switchValue: _isDarkMode, onSwitchChanged: (v) => setState(() => _isDarkMode = v)),
            _buildTile(Iconsax.data, Colors.purple, "Storage & Data", onTap: () => setState(() => _currentView = SettingsView.storage)),
            _buildTile(Iconsax.mobile, Colors.cyan, "Offline Models", onTap: () => setState(() => _currentView = SettingsView.offline)),
          ]),

          SizedBox(height: 25.h),

          // Support Section
          _buildSectionHeader("SUPPORT"),
          _buildSettingsGroup([
            _buildTile(Iconsax.message_question, Colors.redAccent, "Help Center", onTap: () => setState(() => _currentView = SettingsView.help)),
          ]),

          SizedBox(height: 25.h),

          // Log Out Button
          Container(
            width: double.infinity,
            height: 55.h,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red.shade100),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: TextButton.icon(
              onPressed: () {},
              icon: Icon(Iconsax.logout, color: Colors.red, size: 20.sp),
              label: Text("Log Out", style: TextStyle(color: Colors.red, fontSize: 16.sp, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
              ),
            ),
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. PROFILE VIEW
  // ===========================================================================
  Widget _buildProfileView() {
    return _buildSubPageLayout(
      title: "Profile Information",
      content: Column(
        children: [
          SizedBox(height: 20.h),
          Center(
            child: Stack(
              children: [
                Container(
                  width: 100.w,
                  height: 100.w,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF3F6DFC).withOpacity(0.2), width: 4),
                    image: const DecorationImage(
                      image: NetworkImage("https://api.dicebear.com/7.x/avataaars/png?seed=Affan"),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: const BoxDecoration(color: Color(0xFF3F6DFC), shape: BoxShape.circle),
                    child: Icon(Iconsax.camera, color: Colors.white, size: 16.sp),
                  ),
                )
              ],
            ),
          ),
          SizedBox(height: 30.h),
          _buildTextField("Full Name", "Affan Ahmed"),
          SizedBox(height: 20.h),
          _buildTextField("Email Address", "affan@example.com"),
          SizedBox(height: 40.h),
          SizedBox(
            width: double.infinity,
            height: 55.h,
            child: ElevatedButton(
              onPressed: () => setState(() => _currentView = SettingsView.main),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3F6DFC),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
              ),
              child: Text("Save Changes", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. NOTIFICATIONS VIEW
  // ===========================================================================
  Widget _buildNotificationsView() {
    return _buildSubPageLayout(
      title: "Notifications",
      content: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            _buildSwitchRow("Push Notifications", "Receive alerts on your device", _pushEnabled, (v) => setState(() => _pushEnabled = v)),
            Divider(height: 1, color: Colors.grey.shade100),
            _buildSwitchRow("Email Updates", "Receive weekly summaries via email", _emailEnabled, (v) => setState(() => _emailEnabled = v)),
            Divider(height: 1, color: Colors.grey.shade100),
            _buildSwitchRow("Lecture Reminders", "Alerts for upcoming subjects", _lectureReminders, (v) => setState(() => _lectureReminders = v)),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 4. LANGUAGE VIEW
  // ===========================================================================
  Widget _buildLanguageView() {
    final languages = ["English", "Urdu", "Arabic", "Hindi"];
    return _buildSubPageLayout(
      title: "Language",
      content: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: List.generate(languages.length, (index) {
            final lang = languages[index];
            final isSelected = _selectedLanguage == lang;
            return Column(
              children: [
                ListTile(
                  onTap: () => setState(() => _selectedLanguage = lang),
                  title: Text(lang, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? const Color(0xFF3F6DFC) : Colors.black87)),
                  trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF3F6DFC)) : null,
                ),
                if (index != languages.length - 1) Divider(height: 1, color: Colors.grey.shade100),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ===========================================================================
  // 5. STORAGE VIEW (Visual Only)
  // ===========================================================================
  Widget _buildStorageView() {
    return _buildSubPageLayout(
      title: "Storage & Data",
      content: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("2.4 GB", style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold)),
                    Text("Used of 5 GB", style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ],
                ),
                Text("Upgrade Storage", style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: const Color(0xFF3F6DFC))),
              ],
            ),
            SizedBox(height: 15.h),
            LinearProgressIndicator(
              value: 0.48,
              backgroundColor: Colors.grey.shade100,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF3F6DFC)),
              minHeight: 8.h,
              borderRadius: BorderRadius.circular(4.r),
            ),
            SizedBox(height: 20.h),
            _buildSimpleRow(Iconsax.trash, Colors.blue, "Clear Cache", "124 MB"),
            SizedBox(height: 15.h),
            _buildSwitchRow("Auto-Download", "", true, (v) {}),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 6. HELPER WIDGETS
  // ===========================================================================

  Widget _buildSubPageLayout({required String title, required Widget content}) {
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _currentView = SettingsView.main),
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
                style: IconButton.styleFrom(backgroundColor: Colors.white, padding: EdgeInsets.all(10.w)),
              ),
              SizedBox(width: 15.w),
              Text(title, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 30.h),
          content,
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          int idx = entry.key;
          Widget child = entry.value;
          return Column(
            children: [
              child,
              if (idx != children.length - 1)
                Divider(height: 1, indent: 60.w, color: Colors.grey.shade100),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTile(IconData icon, Color color, String title, {String? trailingText, bool isSwitch = false, bool switchValue = false, Function(bool)? onSwitchChanged, VoidCallback? onTap}) {
    return ListTile(
      onTap: isSwitch ? null : onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 5.h),
      leading: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(icon, color: color, size: 20.sp),
      ),
      title: Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.black87)),
      trailing: isSwitch
          ? Switch(value: switchValue, onChanged: onSwitchChanged, activeColor: const Color(0xFF3F6DFC))
          : Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(trailingText, style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
          if (trailingText != null) SizedBox(width: 5.w),
          Icon(Icons.arrow_forward_ios_rounded, size: 16.sp, color: Colors.grey[300]),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 10.w, bottom: 10.h),
      child: Text(
        title,
        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildTextField(String label, String initialValue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 1)),
        SizedBox(height: 8.h),
        TextFormField(
          initialValue: initialValue,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r), borderSide: BorderSide(color: Colors.grey.shade200)),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchRow(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                if (subtitle.isNotEmpty) Text(subtitle, style: TextStyle(fontSize: 10.sp, color: Colors.grey)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: const Color(0xFF3F6DFC)),
        ],
      ),
    );
  }

  // Placeholders for Security, Offline, Help to prevent errors
  Widget _buildSecurityView() => _buildSubPageLayout(title: "Security & Privacy", content: const Center(child: Text("Security Placeholder")));
  Widget _buildOfflineView() => _buildSubPageLayout(title: "Offline Models", content: const Center(child: Text("Offline Models Placeholder")));
  Widget _buildHelpView() => _buildSubPageLayout(title: "Help Center", content: const Center(child: Text("Help Placeholder")));

  Widget _buildSimpleRow(IconData icon, Color color, String title, String trailing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8.r)),
              child: Icon(icon, size: 16.sp, color: color),
            ),
            SizedBox(width: 12.w),
            Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
          ],
        ),
        Text(trailing, style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
      ],
    );
  }
}