import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../main.dart';

class SubjectDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> subject;

  const SubjectDetailsScreen({super.key, required this.subject});

  @override
  ConsumerState<SubjectDetailsScreen> createState() => _SubjectDetailsScreenState();
}

class _SubjectDetailsScreenState extends ConsumerState<SubjectDetailsScreen> {
  // --- STATE VARIABLES ---
  List<FileSystemEntity> _recordings = [];
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingPath; // Which file is currently playing?
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecordings();

    // Listen for when audio finishes
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _playingPath = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // --- 1. LOGIC: Load Real Files ---
  Future<void> _loadRecordings() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    List<FileSystemEntity> files = appDocDir.listSync();

    // Filter for .m4a audio files
    var audioFiles = files.where((file) => file.path.endsWith('.m4a')).toList();

    // Sort: Newest first
    audioFiles.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

    if (mounted) {
      setState(() {
        _recordings = audioFiles;
        _isLoading = false;
      });
    }
  }

  // --- 2. LOGIC: Play/Stop ---
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

  // --- 3. LOGIC: Delete File ---
  Future<void> _deleteFile(FileSystemEntity file) async {
    try {
      await file.delete();
      await _loadRecordings(); // Refresh the list
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Recording deleted")),
      );
    } catch (e) {
      debugPrint("Error deleting: $e");
    }
  }

  // --- HELPER: Date Format ---
  String _formatDate(DateTime date) {
    return "${date.day}/${date.month} • ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    
    // Determine the subject color
    final Color subjectColor = widget.subject['color'] ?? const Color(0xFF3F6DFC);

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text(widget.subject['name'], style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          children: [
            SizedBox(height: 10.h),

            // --- HEADER CARD ---
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(25.w),
              decoration: BoxDecoration(
                color: subjectColor,
                borderRadius: BorderRadius.circular(25.r),
                boxShadow: [
                  BoxShadow(
                    color: subjectColor.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(widget.subject['icon'] ?? Icons.book, size: 50.sp, color: Colors.white),
                  SizedBox(height: 15.h),
                  Text(
                    "${_recordings.length} Lectures Found",
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14.sp),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    widget.subject['desc'] ?? "Class Materials",
                    style: TextStyle(color: Colors.white, fontSize: 12.sp, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),

            SizedBox(height: 30.h),

            // --- LIST TITLE ---
            Align(alignment: Alignment.centerLeft, child: Text("Lecture History", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87))),
            SizedBox(height: 15.h),

            // --- DYNAMIC LIST ---
            Expanded(
              child: _recordings.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mic_none, size: 50.sp, color: isDarkMode ? Colors.white24 : Colors.grey[300]),
                    SizedBox(height: 10.h),
                    Text("No lectures recorded yet", style: TextStyle(color: isDarkMode ? Colors.white38 : Colors.grey[400])),
                  ],
                ),
              )
                  : ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: _recordings.length,
                itemBuilder: (context, index) {
                  final file = _recordings[index];
                  final isPlaying = _playingPath == file.path;
                  final fileName = "Lecture ${_recordings.length - index}"; // Reverse numbering

                  return Dismissible(
                    key: Key(file.path),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: 20.w),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) => _deleteFile(file),
                    child: Container(
                      margin: EdgeInsets.only(bottom: 15.h),
                      padding: EdgeInsets.all(15.w),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(15.r),
                        border: Border.all(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: GestureDetector(
                          onTap: () => _playFile(file.path),
                          child: CircleAvatar(
                            radius: 22.r,
                            backgroundColor: isPlaying ? Colors.red.withOpacity(0.1) : subjectColor.withOpacity(0.1),
                            child: Icon(
                                isPlaying ? Icons.pause : Iconsax.play,
                                color: isPlaying ? Colors.red : subjectColor,
                                size: 20.sp
                            ),
                          ),
                        ),
                        title: Text(fileName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp, color: isDarkMode ? Colors.white : Colors.black87)),
                        subtitle: Text("Recorded ${_formatDate(file.statSync().modified)}", style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.grey, fontSize: 12.sp)),
                        trailing: IconButton(
                          icon: Icon(Icons.share, size: 20, color: isDarkMode ? Colors.white54 : Colors.grey),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Share feature coming soon!")));
                          },
                        ),
                      ),
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
