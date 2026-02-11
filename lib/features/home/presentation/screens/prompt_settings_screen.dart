import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../main.dart';

class PromptSettingsScreen extends ConsumerStatefulWidget {
  const PromptSettingsScreen({super.key});

  @override
  ConsumerState<PromptSettingsScreen> createState() => _PromptSettingsScreenState();
}

class _PromptSettingsScreenState extends ConsumerState<PromptSettingsScreen> {
  final TextEditingController _promptController = TextEditingController();
  bool _isLoading = true;

  static const String _defaultPrompt = """
Analyze this lecture recording and:
1. Create a detailed summary (use bulletpoints, headings, and list of topics covered, with enough words to give a thorough understanding of the complete lecture).
2. Create 3 quiz questions based on the lecture.
3. Create a full, detailed, and explanatory document of the lecture.(make sure no to add data from your side keep the document strictly according to lecture)
""";

  @override
  void initState() {
    super.initState();
    _loadPrompt();
  }

  Future<void> _loadPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _promptController.text = prefs.getString('custom_summary_prompt') ?? _defaultPrompt;
      _isLoading = false;
    });
  }

  Future<void> _savePrompt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_summary_prompt', _promptController.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Summary prompt saved successfully!")),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text("Prompt Settings", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Customize Summary Prompt",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    "This prompt tells the AI how to summarize your lectures. You can change it to focus on specific details or formats.",
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  ),
                  SizedBox(height: 20.h),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(15.w),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(15.r),
                        border: Border.all(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: _promptController,
                        maxLines: null,
                        expands: true,
                        style: TextStyle(fontSize: 14.sp, color: isDarkMode ? Colors.white70 : Colors.black87),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Enter your custom prompt here...",
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 25.h),
                  SizedBox(
                    width: double.infinity,
                    height: 55.h,
                    child: ElevatedButton(
                      onPressed: _savePrompt,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3F6DFC),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                        elevation: 0,
                      ),
                      child: Text(
                        "Save Prompt",
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() => _promptController.text = _defaultPrompt),
                      child: Text("Reset to Default", style: TextStyle(color: const Color(0xFF3F6DFC), fontSize: 14.sp)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
