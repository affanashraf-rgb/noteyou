import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class StudySessionScreen extends StatelessWidget {
  const StudySessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text("Study Session", style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 80.sp, color: const Color(0xFF3F6DFC)),
            SizedBox(height: 20.h),
            Text("Quiz Mode Active", style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
            Text("Prepare for your upcoming quiz!", style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}