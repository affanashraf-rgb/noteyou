import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../../../main.dart';
import '../../data/services/ai_service.dart';
import 'smart_notes_screen.dart';

class Lecture {
  final File audioFile;
  final File noteFile;
  final Map<String, dynamic> data;

  Lecture({required this.audioFile, required this.noteFile, required this.data});

  String get displayName => data['displayName'] ?? 'Unnamed Lecture';
  String get summary => data['summary'] ?? 'No summary available.';
}

class SubjectDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> subject;
  const SubjectDetailsScreen({super.key, required this.subject});

  @override
  ConsumerState<SubjectDetailsScreen> createState() => _SubjectDetailsScreenState();
}

class _SubjectDetailsScreenState extends ConsumerState<SubjectDetailsScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<Lecture> _lectures = [];
  String? _playingPath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLectures();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingPath = null);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadLectures() async {
    setState(() => _isLoading = true);
    final List<Lecture> loadedLectures = [];
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String subjectName = widget.subject['name'];
    final Directory subjectNotesDir = Directory('${appDocDir.path}/notes/$subjectName');

    if (await subjectNotesDir.exists()) {
      final List<FileSystemEntity> noteFiles = subjectNotesDir.listSync();
      for (var file in noteFiles.where((f) => f.path.endsWith('.json'))) {
        try {
          final noteFile = file as File;
          final audioFileName = noteFile.path.split('/').last.replaceAll('.json', '.m4a');
          final audioFile = File('${appDocDir.path}/$audioFileName');

          if (await audioFile.exists()) {
            final data = jsonDecode(await noteFile.readAsString());
            loadedLectures.add(Lecture(audioFile: audioFile, noteFile: noteFile, data: data));
          }
        } catch (e) {
          debugPrint("Error loading lecture: $e");
        }
      }
    }
    
    loadedLectures.sort((a, b) => b.audioFile.statSync().modified.compareTo(a.audioFile.statSync().modified));

    if (mounted) {
      setState(() {
        _lectures = loadedLectures;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRename(Lecture lecture) async {
    final nameController = TextEditingController(text: lecture.displayName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Rename Lecture"),
        content: TextField(controller: nameController, decoration: const InputDecoration(hintText: "Enter new name")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, nameController.text), child: const Text("Save")),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      final updatedData = Map<String, dynamic>.from(lecture.data);
      updatedData['displayName'] = newName;
      await lecture.noteFile.writeAsString(jsonEncode(updatedData));
      await _loadLectures();
    }
  }

  Future<void> _handleDelete(Lecture lecture) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Lecture?"),
        content: const Text("Permanently remove this recording and all notes?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("Delete", style: TextStyle(color: Colors.white))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await lecture.audioFile.delete();
        await lecture.noteFile.delete();
        await _loadLectures();
      } catch (e) {
        debugPrint("Error deleting: $e");
      }
    }
  }

  Future<void> _generateNewQuiz(Lecture lecture) async {
    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
    try {
      final aiService = AIService();
      final newQuiz = await aiService.generateNewQuiz(lecture.summary);
      if (newQuiz.isNotEmpty) {
        final updatedData = Map<String, dynamic>.from(lecture.data);
        updatedData['quiz'] = newQuiz;
        await lecture.noteFile.writeAsString(jsonEncode(updatedData));
        await _loadLectures();
        if(mounted) Navigator.pop(context);
        if(mounted) Navigator.push(context, MaterialPageRoute(builder: (c) => SmartNotesScreen(aiData: updatedData)));
      } else {
        if(mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not generate a new quiz.")));
      }
    } catch(e) {
       if(mounted) Navigator.pop(context);
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _playFile(String filePath) async {
    if (_playingPath == filePath) {
      await _audioPlayer.stop();
      setState(() => _playingPath = null);
    } else {
      await _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(filePath));
      setState(() => _playingPath = filePath);
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month} • ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final Color subjectColor = widget.subject['color'] ?? const Color(0xFF3F6DFC);

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text(widget.subject['name'], style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.pop(context)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          children: [
            SizedBox(height: 10.h),
            Container(
              width: double.infinity, padding: EdgeInsets.all(25.w),
              decoration: BoxDecoration(color: subjectColor, borderRadius: BorderRadius.circular(25.r), boxShadow: [BoxShadow(color: subjectColor.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 8))]),
              child: Column(children: [Icon(widget.subject['icon'] ?? Icons.book, size: 50.sp, color: Colors.white), SizedBox(height: 15.h), Text("${_lectures.length} Lectures Found", style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14.sp)), SizedBox(height: 5.h), Text(widget.subject['desc'] ?? "Class Materials", style: TextStyle(color: Colors.white, fontSize: 12.sp, fontStyle: FontStyle.italic))]),
            ),
            SizedBox(height: 30.h),
            Align(alignment: Alignment.centerLeft, child: Text("Lecture History", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87))),
            SizedBox(height: 15.h),
            Expanded(
              child: _lectures.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.mic_none, size: 50.sp, color: isDarkMode ? Colors.white24 : Colors.grey[300]), SizedBox(height: 10.h), Text("No lectures recorded yet", style: TextStyle(color: isDarkMode ? Colors.white38 : Colors.grey[400]))]))
                  : ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: _lectures.length,
                itemBuilder: (context, index) {
                  final lecture = _lectures[index];
                  final isPlaying = _playingPath == lecture.audioFile.path;
                  return Container(
                    margin: EdgeInsets.only(bottom: 15.h),
                    decoration: BoxDecoration(color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(15.r), border: Border.all(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200)),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 5.h),
                      leading: GestureDetector(onTap: () => _playFile(lecture.audioFile.path), child: CircleAvatar(radius: 22.r, backgroundColor: isPlaying ? Colors.red.withValues(alpha: 0.1) : subjectColor.withValues(alpha: 0.1), child: Icon(isPlaying ? Icons.pause : Iconsax.play, color: isPlaying ? Colors.red : subjectColor, size: 20.sp))),
                      title: Text(lecture.displayName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp, color: isDarkMode ? Colors.white : Colors.black87)),
                      subtitle: Text("Recorded ${_formatDate(lecture.audioFile.statSync().modified)}", style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.grey, fontSize: 12.sp)),
                      trailing: PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: isDarkMode ? Colors.white54 : Colors.grey),
                        onSelected: (val) {
                          if (val == 'rename') _handleRename(lecture);
                          if (val == 'delete') _handleDelete(lecture);
                          if (val == 'quiz') _generateNewQuiz(lecture);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'quiz', child: Row(children: [Icon(Iconsax.magic_star, size: 18), SizedBox(width: 10), Text("New Quiz")])),
                          const PopupMenuItem(value: 'rename', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 10), Text("Rename")])),
                          const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: Colors.red, size: 18), SizedBox(width: 10), Text("Delete", style: TextStyle(color: Colors.red))])),
                        ],
                      ),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => SmartNotesScreen(aiData: lecture.data))),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
