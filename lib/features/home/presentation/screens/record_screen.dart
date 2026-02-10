import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import '../../../../main.dart';
import '../../data/services/ai_service.dart';

class RecordScreen extends ConsumerStatefulWidget {
  const RecordScreen({super.key});

  @override
  ConsumerState<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends ConsumerState<RecordScreen> {
  // --- SERVICES ---
  final AIService _aiService = AIService();

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

  // --- AI AGENT VARIABLES ---
  bool _showAiAgent = false;
  bool _isAiAnalyzing = false;
  String _aiSummary = "Standby. Tap to analyze your current recording session.";
  List<dynamic> _aiQuiz = [];
  
  // --- CHAT VARIABLES ---
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _chatMessages = [];
  bool _isTyping = false;

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
    _chatController.dispose();
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
          _isPlaying = false;
          _isPaused = false;
          _aiSummary = "Recording in progress... AI Agent is listening.";
          _aiQuiz = [];
          _chatMessages.clear();
        });

        _startTimer();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Microphone permission required!")));
      }
    } catch (e) {
      debugPrint("Error starting record: $e");
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _timer?.cancel();

      setState(() {
        _isRecording = false;
        _audioPath = path;
        _aiSummary = "Recording saved. Ready for AI analysis.";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Recording Saved! (${_formatTime(_recordDuration)})"),
          backgroundColor: const Color(0xFF3F6DFC),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint("Error stopping record: $e");
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
      debugPrint("Error playing audio: $e");
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
      debugPrint("Error pausing audio: $e");
    }
  }

  // --- AI ANALYSIS LOGIC ---
  Future<void> _analyzeWithAi() async {
    if (_isRecording || _audioPath == null) return;
    
    setState(() {
      _isAiAnalyzing = true;
      _aiSummary = "Analyzing recording with Gemini AI... Please wait.";
      _showAiAgent = true; 
    });

    try {
      final result = await _aiService.processLectureAudio(File(_audioPath!));
      
      setState(() {
        _isAiAnalyzing = false;
        _aiSummary = result['summary'] ?? "Could not generate summary.";
        _aiQuiz = result['quiz'] ?? [];
        _chatMessages.add({"role": "assistant", "content": "I've analyzed your lecture! You can now ask me anything about it."});
      });
    } catch (e) {
      setState(() {
        _isAiAnalyzing = false;
        _aiSummary = "Error: AI analysis failed. Please check your connection.";
      });
    }
  }

  // --- CHAT LOGIC ---
  Future<void> _sendMessage() async {
    final message = _chatController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _chatMessages.add({"role": "user", "content": message});
      _chatController.clear();
      _isTyping = true;
    });

    try {
      final response = await _aiService.chatWithAgent(message);
      setState(() {
        _chatMessages.add({"role": "assistant", "content": response});
        _isTyping = false;
      });
    } catch (e) {
      setState(() {
        _chatMessages.add({"role": "assistant", "content": "Sorry, I encountered an error."});
        _isTyping = false;
      });
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
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
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
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const Spacer(),
                    Icon(Iconsax.search_normal, size: 24.sp, color: isDarkMode ? Colors.white70 : Colors.grey[600]),
                    SizedBox(width: 15.w),
                    Icon(Iconsax.notification, size: 24.sp, color: isDarkMode ? Colors.white70 : Colors.grey[600]),
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
                        Text(
                          "Algebra Basics",
                          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
                        ),
                        Row(
                          children: [
                            Text(
                              "Mathematics",
                              style: TextStyle(fontSize: 12.sp, color: isDarkMode ? Colors.white70 : Colors.grey[600]),
                            ),
                            Icon(Icons.keyboard_arrow_down, size: 16.sp, color: isDarkMode ? Colors.white70 : Colors.grey[600]),
                          ],
                        ),
                      ],
                    ),
                    Icon(Icons.more_horiz, size: 24.sp, color: isDarkMode ? Colors.white : Colors.black87),
                  ],
                ),
                SizedBox(height: 20.h),

                // 3. MAIN RECORDING & PLAYBACK CARD
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 30.h, horizontal: 20.w),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
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
                          color: _isRecording ? Colors.red.withOpacity(0.1) : (isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFF2F4F7)),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                            _isRecording ? Icons.stop_rounded : Iconsax.microphone,
                            size: 32.sp,
                            color: _isRecording ? Colors.red : (isDarkMode ? Colors.white70 : Colors.grey[600])
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // Live Timer
                      Text(
                        _formatTime(_recordDuration),
                        style: TextStyle(
                          fontSize: 32.sp,
                          fontWeight: FontWeight.bold,
                          color: _isRecording ? Colors.red : (isDarkMode ? Colors.white : Colors.black87),
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: 5.h),

                      // Status Text or Playback Controls
                      if (!_isRecording && _audioPath != null)
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 10.h),
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(30.r),
                            border: Border.all(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
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
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
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

                // AI AGENT & NOTES TOGGLE
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(child: _buildStatusCard(isDarkMode: isDarkMode, icon: Iconsax.global, label: "MODE", value: "Offline", iconColor: Colors.green)),
                    SizedBox(width: 15.w),
                    Expanded(child: _buildStatusCard(isDarkMode: isDarkMode, icon: Iconsax.magic_star, label: "AI STATUS", value: _isAiAnalyzing ? "Analyzing..." : "Standby", iconColor: const Color(0xFF3F6DFC))),
                  ],
                ),
                SizedBox(height: 25.h),
                
                // TAB TOGGLE
                _buildTabToggle(isDarkMode),
                SizedBox(height: 20.h),
                
                // DYNAMIC CONTENT (NOTES OR AI AGENT)
                _showAiAgent ? _buildAiAgentSection(isDarkMode) : _buildStaticNoteSection(isDarkMode),

                SizedBox(height: 25.h),
                Row(
                  children: [
                    Expanded(child: _buildActionButton(isDarkMode, Iconsax.share, "Share")),
                    SizedBox(width: 15.w),
                    Expanded(child: _buildActionButton(isDarkMode, Iconsax.export_1, "Export")),
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

  Widget _buildTabToggle(bool isDarkMode) {
    return Container(
      height: 50.h,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey.shade200, borderRadius: BorderRadius.circular(25.r)),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showAiAgent = false),
              child: Container(
                decoration: BoxDecoration(
                  color: !_showAiAgent ? (isDarkMode ? const Color(0xFF2C2C2C) : Colors.white) : Colors.transparent,
                  borderRadius: BorderRadius.circular(25.r),
                  boxShadow: !_showAiAgent ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
                ),
                alignment: Alignment.center,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Iconsax.document_text, size: 16.sp, color: !_showAiAgent ? (isDarkMode ? Colors.white : Colors.black87) : Colors.grey.shade600), SizedBox(width: 8.w), Text("Notes", style: TextStyle(fontSize: 14.sp, fontWeight: !_showAiAgent ? FontWeight.bold : FontWeight.w500, color: !_showAiAgent ? (isDarkMode ? Colors.white : Colors.black87) : Colors.grey.shade600))]),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showAiAgent = true),
              child: Container(
                decoration: BoxDecoration(
                  color: _showAiAgent ? (isDarkMode ? const Color(0xFF2C2C2C) : Colors.white) : Colors.transparent,
                  borderRadius: BorderRadius.circular(25.r),
                  boxShadow: _showAiAgent ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
                ),
                alignment: Alignment.center,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Iconsax.cpu, size: 16.sp, color: _showAiAgent ? (isDarkMode ? Colors.white : Colors.black87) : Colors.grey.shade600), SizedBox(width: 8.w), Text("AI Agent", style: TextStyle(fontSize: 14.sp, fontWeight: _showAiAgent ? FontWeight.bold : FontWeight.w500, color: _showAiAgent ? (isDarkMode ? Colors.white : Colors.black87) : Colors.grey.shade600))]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiAgentSection(bool isDarkMode) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("AI Analysis & Chat", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87)),
                    if (_isAiAnalyzing) SizedBox(width: 15.w, height: 15.w, child: const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3F6DFC))),
                  ],
                ),
                SizedBox(height: 10.h),
                Text(_aiSummary, style: TextStyle(fontSize: 14.sp, height: 1.5, color: isDarkMode ? Colors.white70 : Colors.grey.shade700)),
                
                if (_aiQuiz.isNotEmpty) ...[
                  SizedBox(height: 15.h),
                  Text("Generated Quiz", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF3F6DFC))),
                  SizedBox(height: 8.h),
                  ..._aiQuiz.take(2).map((q) => Padding(
                    padding: EdgeInsets.only(bottom: 5.h),
                    child: Text("• ${q['question']}", style: TextStyle(fontSize: 13.sp, color: isDarkMode ? Colors.white60 : Colors.black54)),
                  )).toList(),
                ],
              ],
            ),
          ),

          // CHAT INTERFACE
          if (!_isAiAnalyzing && _audioPath != null) ...[
            const Divider(height: 1),
            Container(
              height: 200.h,
              padding: EdgeInsets.symmetric(horizontal: 15.w),
              child: ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                itemCount: _chatMessages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _chatMessages.length) {
                    return _buildTypingIndicator(isDarkMode);
                  }
                  final msg = _chatMessages[index];
                  final isUser = msg['role'] == 'user';
                  return _buildChatMessage(msg['content']!, isUser, isDarkMode);
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      style: TextStyle(fontSize: 14.sp, color: isDarkMode ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        hintText: "Ask anything about the lecture...",
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 13.sp),
                        filled: true,
                        fillColor: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25.r), borderSide: BorderSide.none),
                        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: CircleAvatar(
                      backgroundColor: const Color(0xFF3F6DFC),
                      radius: 20.r,
                      child: const Icon(Iconsax.send_1, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (!_isAiAnalyzing && _audioPath == null)
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Text("Start recording to enable AI analysis and chat.", style: TextStyle(color: Colors.grey, fontSize: 13.sp)),
            ),

          if (!_isAiAnalyzing && _audioPath != null && _aiQuiz.isEmpty)
             Padding(
               padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
               child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _analyzeWithAi,
                  style: TextButton.styleFrom(backgroundColor: const Color(0xFF3F6DFC).withOpacity(0.1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))),
                  child: Text("Analyze with AI", style: TextStyle(color: const Color(0xFF3F6DFC), fontWeight: FontWeight.bold, fontSize: 14.sp)),
                ),
              ),
             ),
        ],
      ),
    );
  }

  Widget _buildChatMessage(String text, bool isUser, bool isDarkMode) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
        constraints: BoxConstraints(maxWidth: 220.w),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF3F6DFC) : (isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey.shade100),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15.r),
            topRight: Radius.circular(15.r),
            bottomLeft: Radius.circular(isUser ? 15.r : 0),
            bottomRight: Radius.circular(isUser ? 0 : 15.r),
          ),
        ),
        child: Text(text, style: TextStyle(fontSize: 13.sp, color: isUser ? Colors.white : (isDarkMode ? Colors.white : Colors.black87))),
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDarkMode) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
        decoration: BoxDecoration(color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey.shade100, borderRadius: BorderRadius.circular(15.r)),
        child: SizedBox(width: 30.w, child: const LinearProgressIndicator(backgroundColor: Colors.transparent, color: Color(0xFF3F6DFC))),
      ),
    );
  }

  Widget _buildStaticNoteSection(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(20.r), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Algebra Variables (س، ش)", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87)),
          SizedBox(height: 15.h),
          Text("The lecturer explained that Urdu uses specific symbols for variables. Transitioning to English notation involves mapping 'Seen' to 'x'.", style: TextStyle(fontSize: 14.sp, height: 1.5, color: isDarkMode ? Colors.white70 : Colors.grey.shade700)),
          SizedBox(height: 20.h),
          Row(children: [Icon(Icons.check_circle_outline, color: const Color(0xFF3F6DFC), size: 18.sp), SizedBox(width: 8.w), Text("Key concept saved", style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xFF3F6DFC)))]),
        ],
      ),
    );
  }

  Widget _buildStatusCard({required bool isDarkMode, required IconData icon, required String label, required String value, required Color iconColor}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 15.w),
      decoration: BoxDecoration(color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(15.r), border: Border.all(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, size: 18.sp, color: iconColor), SizedBox(width: 8.w), Text(label, style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: Colors.grey[400]))]), SizedBox(height: 5.h), Padding(padding: EdgeInsets.only(left: 26.w), child: Text(value, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87)))]),
    );
  }

  Widget _buildActionButton(bool isDarkMode, IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 15.h),
      decoration: BoxDecoration(color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(15.r), border: Border.all(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))]),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 20.sp, color: isDarkMode ? Colors.white : Colors.black87), SizedBox(width: 10.w), Text(label, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white : Colors.black87))]),
    );
  }
}
