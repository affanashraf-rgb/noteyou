import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../main.dart';

class DailyQuizSettingsScreen extends ConsumerStatefulWidget {
  const DailyQuizSettingsScreen({super.key});

  @override
  ConsumerState<DailyQuizSettingsScreen> createState() => _DailyQuizSettingsScreenState();
}

class _DailyQuizSettingsScreenState extends ConsumerState<DailyQuizSettingsScreen> {
  bool _dailyQuizEnabled = false;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 19, minute: 0); // Default 7 PM

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dailyQuizEnabled = prefs.getBool('dailyQuizEnabled') ?? false;
      final hour = prefs.getInt('dailyQuizHour') ?? 19;
      final minute = prefs.getInt('dailyQuizMinute') ?? 0;
      _selectedTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dailyQuizEnabled', _dailyQuizEnabled);
    await prefs.setInt('dailyQuizHour', _selectedTime.hour);
    await prefs.setInt('dailyQuizMinute', _selectedTime.minute);
    
    // Here you would typically schedule or cancel the notification
    // e.g., NotificationService().scheduleDailyQuiz(_dailyQuizEnabled, _selectedTime);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Daily quiz settings saved!")),
      );
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text("Daily Quiz Settings", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(15.r),
                border: Border.all(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200)
              ),
              child: SwitchListTile(
                title: Text("Enable Daily Quiz", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp, color: isDarkMode ? Colors.white : Colors.black87)),
                subtitle: Text("Get a short quiz every day to review your lectures.", style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
                value: _dailyQuizEnabled,
                onChanged: (bool value) {
                  setState(() {
                    _dailyQuizEnabled = value;
                  });
                },
                activeColor: const Color(0xFF3F6DFC),
              ),
            ),
            SizedBox(height: 20.h),
            if (_dailyQuizEnabled)
              GestureDetector(
                onTap: () => _selectTime(context),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 20.h),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(15.r),
                    border: Border.all(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200)
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Quiz Time", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp, color: isDarkMode ? Colors.white : Colors.black87)),
                      Text(
                        _selectedTime.format(context),
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF3F6DFC)),
                      ),
                    ],
                  ),
                ),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 55.h,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3F6DFC),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                  elevation: 0,
                ),
                child: Text("Save Settings", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
