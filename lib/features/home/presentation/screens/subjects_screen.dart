import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  // Mock Data
  List<Map<String, dynamic>> subjects = [
    {"name": "Mathematics", "count": "2", "desc": "Algebra, Calculus", "color": const Color(0xFF4A90E2), "icon": Icons.functions},
    {"name": "Physics", "count": "1", "desc": "Mechanics, Thermo", "color": const Color(0xFF9B51E0), "icon": Icons.science},
    {"name": "Literature", "count": "5", "desc": "Poetry, Prose", "color": const Color(0xFF27AE60), "icon": Icons.menu_book},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text("My Subjects", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(20.w),
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          final s = subjects[index];
          return Container(
            margin: EdgeInsets.only(bottom: 15.h),
            padding: EdgeInsets.all(15.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15.r),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: s['color'].withOpacity(0.1), child: Icon(s['icon'], color: s['color'])),
              title: Text(s['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
              subtitle: Text(s['desc']),
              trailing: Text("${s['count']} lectures", style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
            ),
          );
        },
      ),
    );
  }
}