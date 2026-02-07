import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart'; // IMPORTED THIS
import 'dart:io';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  // --- RECORDING VARIABLES ---
  late final AudioRecorder _audioRecorder;
  bool _isRecording = false;
  Timer? _timer;
  int _recordDuration = 0;
  String? _audioPath;

  // --- PLAYBACK VARIABLES ---
  late final AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _audioPlayer = AudioPlayer();

    // Listen: When audio finishes playing, reset the UI
    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
        _isPaused = false;
      });
    });
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // --- RECORDING LOGIC ---
  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String filePath = '${appDocDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(const RecordConfig(), path: filePath);

        setState(() {
          _isRecording = true;
          _recordDuration = 0;
          _audioPath = filePath;
          // Reset playback state
          _isPlaying = false;
          _isPaused = false;
        });

        _startTimer();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Microphone permission required!")));
      }
    } catch (e) {
      print("Error starting record: $e");
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _timer?.cancel();

      setState(() {
        _isRecording = false;
        _audioPath = path;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Recording Saved! (${_formatTime(_recordDuration)})"),
          backgroundColor: const Color(0xFF3F6DFC),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print("Error stopping record: $e");
    }
  }

  // --- PLAYBACK LOGIC ---
  Future<void> _playRecording() async {
    try {
      if (_audioPath != null) {
        Source urlSource = DeviceFileSource(_audioPath!);
        await _audioPlayer.play(urlSource);
        setState(() {
          _isPlaying = true;
          _isPaused = false;
        });
      }
    } catch (e) {
      print("Error playing audio: $e");
    }
  }

  Future<void> _pauseRecording() async {
    try {
      await _audioPlayer.pause();
      setState(() {
        _isPlaying = false;
        _isPaused = true;
      });
    } catch (e) {
      print("Error pausing audio: $e");
    }
  }

  // --- TIMER HELPERS ---
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() {
        _recordDuration++;
      });
    });
  }

  String _formatTime(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')} : ${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // --- UI BUILD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            child: Column(
              children: [

                // 1. MAIN HEADER
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20.r,
                      backgroundColor: const Color(0xFF3F6DFC),
                      child: Icon(Iconsax.microphone_2, color: Colors.white, size: 20.sp),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      "NoteYou",
                      style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                    ),
                    const Spacer(),
                    Icon(Iconsax.search_normal, size: 24.sp, color: Colors.grey[600]),
                    SizedBox(width: 15.w),
                    Icon(Iconsax.notification, size: 24.sp, color: Colors.grey[600]),
                  ],
                ),
                SizedBox(height: 25.h),

                // 2. SUB-HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Algebra Basics", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
                        Row(
                          children: [
                            Text("Mathematics", style: TextStyle(fontSize: 12.sp, color: Colors.grey[600])),
                            Icon(Icons.keyboard_arrow_down, size: 16.sp, color: Colors.grey[600]),
                          ],
                        ),
                      ],
                    ),
                    Icon(Icons.more_horiz, size: 24.sp, color: Colors.black87),
                  ],
                ),
                SizedBox(height: 20.h),

                // 3. MAIN RECORDING & PLAYBACK CARD
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 30.h, horizontal: 20.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25.r),
                    boxShadow: [
                      BoxShadow(
                        color: _isRecording ? Colors.red.withOpacity(0.1) : Colors.black.withOpacity(0.04),
                        blurRadius: _isRecording ? 20 : 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Animated Mic Circle
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 80.w,
                        width: 80.w,
                        decoration: BoxDecoration(
                          color: _isRecording ? Colors.red.withOpacity(0.1) : const Color(0xFFF2F4F7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                            _isRecording ? Icons.stop_rounded : Iconsax.microphone,
                            size: 32.sp,
                            color: _isRecording ? Colors.red : Colors.grey[600]
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // Live Timer
                      Text(
                        _formatTime(_recordDuration),
                        style: TextStyle(
                          fontSize: 32.sp,
                          fontWeight: FontWeight.bold,
                          color: _isRecording ? Colors.red : Colors.black87,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: 5.h),

                      // Status Text or Playback Controls
                      if (!_isRecording && _audioPath != null)
                      // Show Playback Controls if recorded
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 10.h),
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(30.r),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: _isPlaying ? _pauseRecording : _playRecording,
                                child: Icon(
                                  _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                                  color: const Color(0xFF3F6DFC),
                                  size: 32.sp,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Text(
                                _isPlaying ? "Playing..." : "Preview Recording",
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                      // Show normal text
                        Text(
                          _isRecording ? "RECORDING..." : "READY TO START",
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: _isRecording ? Colors.red.withOpacity(0.7) : Colors.grey[400],
                            letterSpacing: 1,
                          ),
                        ),

                      SizedBox(height: 25.h),

                      // Start/Stop Button
                      SizedBox(
                        width: double.infinity,
                        height: 55.h,
                        child: ElevatedButton(
                          onPressed: _isRecording ? _stopRecording : _startRecording,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isRecording ? Colors.red : const Color(0xFF3F6DFC),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.r),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            _isRecording ? "Stop Recording" : (_audioPath != null ? "Record Again" : "Start New Record"),
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // REST OF THE UI (Status, Notes, Share)
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(child: _buildStatusCard(icon: Iconsax.global, label: "MODE", value: "Offline", iconColor: Colors.green)),
                    SizedBox(width: 15.w),
                    Expanded(child: _buildStatusCard(icon: Iconsax.magic_star, label: "AI STATUS", value: "Standby", iconColor: const Color(0xFF3F6DFC))),
                  ],
                ),
                SizedBox(height: 25.h),
                _buildStaticNoteSection(),
                SizedBox(height: 25.h),
                Row(
                  children: [
                    Expanded(child: _buildActionButton(Iconsax.share, "Share")),
                    SizedBox(width: 15.w),
                    Expanded(child: _buildActionButton(Iconsax.export_1, "Export")),
                  ],
                ),
                SizedBox(height: 30.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---
  Widget _buildStaticNoteSection() {
    return Column(
      children: [
        Container(
          height: 50.h,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(25.r)),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25.r), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]),
                  alignment: Alignment.center,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Iconsax.document_text, size: 16.sp, color: Colors.black87), SizedBox(width: 8.w), Text("Notes", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black87))]),
                ),
              ),
              Expanded(child: Container(alignment: Alignment.center, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Iconsax.cpu, size: 16.sp, color: Colors.grey.shade600), SizedBox(width: 8.w), Text("AI Agent", style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: Colors.grey.shade600))]))),
            ],
          ),
        ),
        SizedBox(height: 20.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20.r), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Algebra Variables (س، ش)", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
              SizedBox(height: 15.h),
              Text("The lecturer explained that Urdu uses specific symbols for variables. Transitioning to English notation involves mapping 'Seen' to 'x'.", style: TextStyle(fontSize: 14.sp, height: 1.5, color: Colors.grey.shade700)),
              SizedBox(height: 20.h),
              Row(children: [Icon(Icons.check_circle_outline, color: const Color(0xFF3F6DFC), size: 18.sp), SizedBox(width: 8.w), Text("Key concept saved", style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF3F6DFC)))]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard({required IconData icon, required String label, required String value, required Color iconColor}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 15.w),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15.r), border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, size: 18.sp, color: iconColor), SizedBox(width: 8.w), Text(label, style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: Colors.grey[400]))]), SizedBox(height: 5.h), Padding(padding: EdgeInsets.only(left: 26.w), child: Text(value, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black87)))]),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 15.h),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15.r), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))]),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 20.sp, color: Colors.black87), SizedBox(width: 10.w), Text(label, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: Colors.black87))]),
    );
  }
}