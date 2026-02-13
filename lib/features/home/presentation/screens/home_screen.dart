import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// IMPORTS
import '../../../../main.dart';
import '../../data/models/study_reminder.dart';
import '../../data/models/task.dart';
import '../../data/logic/home_logic.dart';
import '../../data/logic/subject_provider.dart';
import 'subjects_screen.dart';
import 'study_session_screen.dart';
import 'subject_details_screen.dart';
import 'smart_notes_screen.dart';

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
  Map<String, String> _displayNames = {}; // Store AI suggested names
  List<StudyReminder> _reminders = [];
  List<Task> _tasks = [];
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
    final names = await _loadDisplayNames(recs);
    final tasks = await _loadTasks();
    setState(() {
      _greeting = _logic.getGreeting();
      _recordings = recs;
      _displayNames = names;
      _tasks = tasks;
      _reminders = _logic.getInitialReminders();
    });
  }

  Future<List<Task>> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksJson = prefs.getString('user_tasks');
    if (tasksJson != null) {
      final List<dynamic> decoded = jsonDecode(tasksJson);
      return decoded.map((item) => Task.fromJson(item)).toList();
    }
    return [];
  }

  Future<Map<String, String>> _loadDisplayNames(List<FileSystemEntity> recs) async {
    final Map<String, String> names = {};
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final Directory notesDir = Directory('${appDocDir.path}/notes');

    if (await notesDir.exists()) {
      for (var file in recs) {
        final audioName = file.path.split('/').last.replaceAll('.m4a', '');
        bool found = false;
        
        for (var subjectDir in notesDir.listSync()) {
          if (subjectDir is Directory) {
            final File noteFile = File('${subjectDir.path}/$audioName.json');
            if (await noteFile.exists()) {
              final String content = await noteFile.readAsString();
              final Map<String, dynamic> data = jsonDecode(content);
              names[file.path] = data['displayName'] ?? audioName;
              found = true;
              break;
            }
          }
        }
        if (!found) names[file.path] = audioName;
      }
    }
    return names;
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

  Future<void> _viewSummary(FileSystemEntity file) async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String audioName = file.path.split('/').last.replaceAll('.m4a', '');
      
      final Directory notesDir = Directory('${appDocDir.path}/notes');
      if (await notesDir.exists()) {
        for (var subjectDir in notesDir.listSync()) {
          if (subjectDir is Directory) {
            final File noteFile = File('${subjectDir.path}/$audioName.json');
            if (await noteFile.exists()) {
              final String content = await noteFile.readAsString();
              final Map<String, dynamic> data = jsonDecode(content);
              if (mounted) {
                Navigator.push(context, MaterialPageRoute(builder: (c) => SmartNotesScreen(aiData: data)));
              }
              return;
            }
          }
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No smart notes found for this lecture.")));
      }
    } catch (e) {
      debugPrint("Error loading notes: $e");
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
    
    final List<Subject> userSubjects = ref.watch(subjectProvider);

    // --- SYNCED UPCOMING TASK LOGIC ---
    Task? nextQuiz = _tasks.where((t) => t.type == "Quiz" && !t.isCompleted).toList().fold<Task?>(null, (prev, curr) {
      if (prev == null) return curr;
      return curr.dueDate.isBefore(prev.dueDate) ? curr : prev;
    });

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
                _buildHeader(isDarkMode),
                SizedBox(height: 25.h),
                Text(_greeting, style: GoogleFonts.poppins(fontSize: 26.sp, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
                Text("Lecture notes", style: GoogleFonts.poppins(fontSize: 14.sp, color: Colors.grey[500])),
                SizedBox(height: 25.h),
                _buildReminderCard(nextQuiz, isDarkMode),
                SizedBox(height: 30.h),

                _buildSectionHeader("My Subjects", "See All", isDarkMode, () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SubjectsScreen()))),
                SizedBox(height: 15.h),
                userSubjects.isEmpty 
                  ? Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100, borderRadius: BorderRadius.circular(15.r)),
                      child: Text("No subjects yet. Tap 'See All' to add one!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13.sp)),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: userSubjects.map((s) => _buildSubjectCard(s.name, s.desc, s.color, s.icon, isDarkMode)).toList()),
                    ),
                SizedBox(height: 30.h),
                Text("Recent Lectures", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87)),
                SizedBox(height: 15.h),
                _buildRecordingsList(isDarkMode),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          CircleAvatar(radius: 18.r, backgroundColor: const Color(0xFF3F6DFC), child: Icon(Iconsax.microphone_2, color: Colors.white, size: 18.sp)),
          SizedBox(width: 8.w),
          Text("NoteYou", style: GoogleFonts.poppins(fontSize: 20.sp, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : const Color(0xFF0F172A))),
        ]),
        Row(children: [Icon(Iconsax.search_normal, size: 24.sp, color: isDarkMode ? Colors.white : Colors.black87), SizedBox(width: 15.w), Icon(Iconsax.notification, size: 24.sp, color: isDarkMode ? Colors.white : Colors.black87)]),
      ],
    );
  }

  Widget _buildReminderCard(Task? nextQuiz, bool isDarkMode) {
    String daysLeft = nextQuiz != null ? nextQuiz.dueDate.difference(DateTime.now()).inDays.toString() : "0";

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(color: const Color(0xFF3F6DFC), borderRadius: BorderRadius.circular(20.r), boxShadow: [BoxShadow(color: const Color(0xFF3F6DFC).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))]),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(padding: EdgeInsets.all(10.w), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12.r)), child: Icon(Iconsax.lamp_on, color: Colors.white, size: 24.sp)),
            SizedBox(width: 15.w),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(nextQuiz != null ? "Upcoming ${nextQuiz.type}" : "No Upcoming Quizzes", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(nextQuiz != null ? "${nextQuiz.title} in $daysLeft days" : "You're all caught up!", style: TextStyle(fontSize: 12.sp, color: Colors.white.withValues(alpha: 0.8))),
            ]),
          ]),
          GestureDetector(onTap: () {}, child: Container(padding: EdgeInsets.all(8.w), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle), child: Icon(Icons.add, color: Colors.white, size: 20.sp)))
        ]),
        SizedBox(height: 20.h),
        SizedBox(width: double.infinity, height: 45.h, child: ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const StudySessionScreen())), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF3F6DFC), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))), child: Text(nextQuiz != null ? "Prepare for ${nextQuiz.subject}" : "Start Session", style: const TextStyle(fontWeight: FontWeight.bold)))),
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
        final displayName = _displayNames[file.path] ?? "Recording ${index + 1}";

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
              onTap: () => _viewSummary(file),
              leading: CircleAvatar(backgroundColor: isPlaying ? Colors.red.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1), child: Icon(isPlaying ? Icons.pause : Iconsax.book_1, color: isPlaying ? Colors.red : const Color(0xFF3F6DFC), size: 20.sp)),
              title: Text(displayName, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text("Lecture Note", style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
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
        height: 160.h,
        margin: EdgeInsets.only(right: 15.w),
        padding: EdgeInsets.all(15.w),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12.r)),
              child: Icon(icon, color: Colors.white, size: 24.sp),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 4.h),
                Text(sub, style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String action, bool isDarkMode, VoidCallback onTap) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87)), GestureDetector(onTap: onTap, child: Text(action, style: TextStyle(fontSize: 14.sp, color: const Color(0xFF3F6DFC), fontWeight: FontWeight.bold)))]);
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
