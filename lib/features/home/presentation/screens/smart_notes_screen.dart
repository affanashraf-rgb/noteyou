import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../main.dart';

class SmartNotesScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> aiData;

  const SmartNotesScreen({super.key, required this.aiData});

  @override
  ConsumerState<SmartNotesScreen> createState() => _SmartNotesScreenState();
}

class _SmartNotesScreenState extends ConsumerState<SmartNotesScreen> {
  // Keep track of which options the user selects for the quiz
  final Map<int, int> _selectedAnswers = {};
  bool _showResults = false;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final String summary = widget.aiData['summary'] ?? "No summary generated.";
    final List<dynamic> quiz = widget.aiData['quiz'] ?? [];

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text("Smart Notes", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. SUMMARY SECTION ---
            Row(
              children: [
                Icon(Iconsax.document_text_1, color: const Color(0xFF3F6DFC), size: 24.sp),
                SizedBox(width: 10.w),
                Text("Lecture Summary", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87)),
              ],
            ),
            SizedBox(height: 15.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
              ),
              child: Text(
                summary,
                style: TextStyle(fontSize: 14.sp, height: 1.6, color: isDarkMode ? Colors.white70 : Colors.black87),
              ),
            ),

            SizedBox(height: 30.h),

            // --- 2. QUIZ SECTION ---
            if (quiz.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Iconsax.task_square, color: const Color(0xFF3F6DFC), size: 24.sp),
                  SizedBox(width: 10.w),
                  Text("Practice Quiz", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87)),
                ],
              ),
              SizedBox(height: 15.h),

              ...List.generate(quiz.length, (index) {
                final q = quiz[index];
                return _buildQuizQuestion(index, q, isDarkMode);
              }),

              SizedBox(height: 20.h),

              // --- SUBMIT BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showResults = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3F6DFC),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                  ),
                  child: Text("Check Answers", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              SizedBox(height: 40.h),
            ]
          ],
        ),
      ),
    );
  }

  // --- HELPER TO BUILD EACH QUESTION ---
  Widget _buildQuizQuestion(int qIndex, Map<String, dynamic> questionData, bool isDarkMode) {
    final question = questionData['question'] ?? "Question?";
    final options = List<String>.from(questionData['options'] ?? []);
    final correctAnswer = questionData['answer'];

    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Q${qIndex + 1}. $question", style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87)),
          SizedBox(height: 15.h),
          ...List.generate(options.length, (optIndex) {

            // Logic for coloring the options after clicking "Check Answers"
            Color tileColor = Colors.transparent;
            Color borderColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300;

            if (_showResults) {
              if (optIndex == correctAnswer) {
                tileColor = Colors.green.withValues(alpha: 0.1);
                borderColor = Colors.green;
              } else if (_selectedAnswers[qIndex] == optIndex && optIndex != correctAnswer) {
                tileColor = Colors.red.withValues(alpha: 0.1);
                borderColor = Colors.red;
              }
            } else if (_selectedAnswers[qIndex] == optIndex) {
              tileColor = const Color(0xFF3F6DFC).withValues(alpha: 0.1);
              borderColor = const Color(0xFF3F6DFC);
            }

            return GestureDetector(
              onTap: () {
                if (!_showResults) {
                  setState(() {
                    _selectedAnswers[qIndex] = optIndex;
                  });
                }
              },
              child: Container(
                margin: EdgeInsets.only(bottom: 10.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: tileColor,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedAnswers[qIndex] == optIndex ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: _selectedAnswers[qIndex] == optIndex ? const Color(0xFF3F6DFC) : Colors.grey,
                      size: 20.sp,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(child: Text(options[optIndex], style: TextStyle(fontSize: 14.sp, color: isDarkMode ? Colors.white70 : Colors.black87))),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
