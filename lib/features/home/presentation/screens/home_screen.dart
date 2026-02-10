import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

// IMPORTS
import '../../../../main.dart';
import '../../data/models/study_reminder.dart';
import '../../data/logic/home_logic.dart';
import 'subjects_screen.dart';
import 'study_session_screen.dart';
import 'subject_details_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Logic Controller
  final HomeLogic _logic = HomeLogic();

  // UI State
  String _greeting = "Hello";
  List<FileSystemEntity> _recordings = [];
  List<StudyReminder> _reminders = [];
  String? _playingPath;

  @override
  void initState() {
    super.initState();
    _loadData();

    // Listen to Logic for audio finish
    _logic.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingPath = null);
    });
  }

  void _loadData() async {
    final recs = await _logic.loadRecordings();
    setState(() {
      _greeting = _logic.getGreeting();
      _recordings = recs;
      _reminders = _logic.getInitialReminders();
    });
  }

  void _handlePlay(String path) {
    if (_playingPath == path) {
      _logic.stopAudio();
      setState(() => _playingPath = null);
    } else {
      _logic.playAudio(path);
      setState(() => _playingPath = path);
    }
  }

  Future<void> _deleteRecording(FileSystemEntity file) async {
    try {
      await file.delete();
      _loadData(); // Refresh list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Recording deleted")),
        );
      }
    } catch (e) {
      debugPrint("Error deleting: $e");
    }
  }

  void _addReminder(String title, String subject, DateTime date) {
    setState(() {
      _reminders.add(StudyReminder(title: title, subject: subject, date: date, type: "Quiz"));
      _reminders.sort((a, b) => a.date.compareTo(b.date));
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    StudyReminder? upcoming = _reminders.isNotEmpty ? _reminders.first : null;
    String daysLeft = upcoming != null ? upcoming.date.difference(DateTime.now()).inDays.toString() : "0";

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header
                _buildHeader(isDarkMode),
                SizedBox(height: 25.h),

                // 2. Greeting
                Text(_greeting, style: GoogleFonts.poppins(fontSize: 26.sp, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
                Text("Lecture notes", style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.grey[500])),
                SizedBox(height: 25.h),

                // 3. Reminder Card
                _buildReminderCard(upcoming, daysLeft),
                SizedBox(height: 30.h),

                // 4. Subjects
                _buildSectionHeader("My Subjects", "See All", () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SubjectsScreen()))),
                SizedBox(height: 15.h),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    _buildSubjectCard("Mathematics", "12 lectures", const Color(0xFF4A90E2), Icons.functions, isDarkMode),
                    _buildSubjectCard("Physics", "8 lectures", const Color(0xFF9B51E0), Icons.science, isDarkMode),
                    _buildSubjectCard("Literature", "15 lectures", const Color(0xFF27AE60), Icons.menu_book, isDarkMode),
                  ]),
                ),
                SizedBox(height: 30.h),

                // 5. Recent Recordings
                Text("Recent Lectures", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                SizedBox(height: 15.h),
                _buildRecordingsList(isDarkMode),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI WIDGETS ---

  Widget _buildHeader(bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          CircleAvatar(radius: 18.r, backgroundColor: const Color(0xFF3F6DFC), child: Icon(Iconsax.microphone_2, color: Colors.white, size: 18.sp)),
          SizedBox(width: 8.w),
          Text("NoteYou", style: GoogleFonts.poppins(fontSize: 20.sp, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : const Color(0xFF0F172A))),
        ]),
        Row(children: [Icon(Iconsax.search_normal, size: 24.sp), SizedBox(width: 15.w), Icon(Iconsax.notification, size: 24.sp)]),
      ],
    );
  }

  Widget _buildReminderCard(StudyReminder? upcoming, String daysLeft) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(color: const Color(0xFF3F6DFC), borderRadius: BorderRadius.circular(20.r), boxShadow: [BoxShadow(color: const Color(0xFF3F6DFC).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(padding: EdgeInsets.all(10.w), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12.r)), child: Icon(Iconsax.lamp_on, color: Colors.white, size: 24.sp)),
            SizedBox(width: 15.w),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(upcoming != null ? "Upcoming ${upcoming.type}" : "No Quiz", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(upcoming != null ? "${upcoming.title} in $daysLeft days" : "Add a reminder", style: TextStyle(fontSize: 12.sp, color: Colors.white.withOpacity(0.8))),
            ]),
          ]),
          GestureDetector(onTap: _showAddDialog, child: Container(padding: EdgeInsets.all(8.w), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle), child: Icon(Icons.add, color: Colors.white, size: 20.sp)))
        ]),
        SizedBox(height: 20.h),
        SizedBox(width: double.infinity, height: 45.h, child: ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const StudySessionScreen())), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF3F6DFC), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))), child: Text(upcoming != null ? "Prepare Now" : "Start Session", style: const TextStyle(fontWeight: FontWeight.bold)))),
      ]),
    );
  }

  Widget _buildRecordingsList(bool isDarkMode) {
    if (_recordings.isEmpty) return const Center(child: Text("No recordings found.", style: TextStyle(color: Colors.grey)));
    return ListView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _recordings.length,
      itemBuilder: (context, index) {
        final file = _recordings[index];
        final isPlaying = _playingPath == file.path;
        return Dismissible(
          key: Key(file.path),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(15.r)),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (direction) => _deleteRecording(file),
          child: Container(
            margin: EdgeInsets.only(bottom: 10.h),
            decoration: BoxDecoration(color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(15.r), border: Border.all(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100)),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: isPlaying ? Colors.red.withOpacity(0.1) : Colors.blue.withOpacity(0.1), child: Icon(isPlaying ? Icons.pause : Iconsax.microphone, color: isPlaying ? Colors.red : const Color(0xFF3F6DFC), size: 20.sp)),
              title: Text("Recording ${index + 1}", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
              subtitle: Text("Audio Note", style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
              trailing: IconButton(icon: Icon(isPlaying ? Icons.stop_circle_outlined : Icons.play_circle_outline, color: isPlaying ? Colors.red : Colors.grey, size: 28.sp), onPressed: () => _handlePlay(file.path)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubjectCard(String title, String sub, Color color, IconData icon, bool isDarkMode) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubjectDetailsScreen(
              subject: {
                'name': title,
                'desc': sub,
                'color': color,
                'icon': icon,
              },
            ),
          ),
        );
      },
      child: Container(
        width: 140.w,
        margin: EdgeInsets.only(right: 15.w),
        padding: EdgeInsets.all(15.w),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12.r)),
              child: Icon(icon, color: Colors.white, size: 24.sp),
            ),
            SizedBox(height: 15.h),
            Text(title, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
            Text(sub, style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action, VoidCallback onTap) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)), GestureDetector(onTap: onTap, child: Text(action, style: TextStyle(fontSize: 14.sp, color: const Color(0xFF3F6DFC), fontWeight: FontWeight.bold)))]);
  }

  void _showAddDialog() {
    String title = "";
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
          title: Text("Add Reminder", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20.sp)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  onChanged: (v) => title = v,
                  decoration: InputDecoration(
                    labelText: "Title",
                    labelStyle: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14.sp),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF3F6DFC))),
                  ),
                ),
                SizedBox(height: 20.h),
                Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF3F6DFC),
                      onPrimary: Colors.white,
                      onSurface: Colors.black,
                    ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFF3F6DFC)),
                    ),
                  ),
                  child: SizedBox(
                    width: 300.w,
                    height: 280.h,
                    child: CalendarDatePicker(
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                      onDateChanged: (date) {
                        setDialogState(() => selectedDate = date);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: GoogleFonts.poppins(color: const Color(0xFF3F6DFC), fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () {
                if (title.isNotEmpty) _addReminder(title, "General", selectedDate);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF1F4FF),
                foregroundColor: const Color(0xFF3F6DFC),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 10.h),
              ),
              child: Text("Add", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
