import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'subject_details_screen.dart'; // Import the new file

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  // 1. DYNAMIC DATA
  List<Map<String, dynamic>> subjects = [
    {"name": "Mathematics", "count": "3", "desc": "Algebra, Calculus", "color": const Color(0xFF4A90E2), "icon": Icons.functions},
    {"name": "Physics", "count": "1", "desc": "Mechanics, Thermo", "color": const Color(0xFF9B51E0), "icon": Icons.science},
    {"name": "Literature", "count": "5", "desc": "Poetry, Prose", "color": const Color(0xFF27AE60), "icon": Icons.menu_book},
  ];

  // 2. LOGIC: Add Subject
  void _addSubject(String name, Color color) {
    setState(() {
      subjects.add({
        "name": name,
        "count": "0",
        "desc": "New Course",
        "color": color,
        "icon": Icons.book,
      });
    });
    Navigator.pop(context);
  }

  // 3. LOGIC: Delete Subject
  void _deleteSubject(int index) {
    final deletedSubject = subjects[index];
    setState(() {
      subjects.removeAt(index);
    });
    // Undo option
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("${deletedSubject['name']} deleted"),
      action: SnackBarAction(label: "UNDO", onPressed: () => setState(() => subjects.insert(index, deletedSubject))),
    ));
  }

  // 4. UI: Show Dialog
  void _showAddDialog() {
    String newName = "";
    Color selectedColor = const Color(0xFF3F6DFC);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("New Subject"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: "Subject Name", hintText: "e.g. History"),
                onChanged: (v) => newName = v,
              ),
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _colorDot(Colors.red, (c) => selectedColor = c),
                  _colorDot(Colors.blue, (c) => selectedColor = c),
                  _colorDot(Colors.green, (c) => selectedColor = c),
                  _colorDot(Colors.orange, (c) => selectedColor = c),
                ],
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () { if(newName.isNotEmpty) _addSubject(newName, selectedColor); },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3F6DFC)),
              child: const Text("Create", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _colorDot(Color color, Function(Color) onTap) {
    return GestureDetector(
      onTap: () => onTap(color),
      child: CircleAvatar(backgroundColor: color, radius: 15.r),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text("My Subjects", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF3F6DFC),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: subjects.isEmpty
          ? const Center(child: Text("No subjects yet. Add one!"))
          : ListView.builder(
        padding: EdgeInsets.all(20.w),
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          final s = subjects[index];
          return Dismissible(
            key: Key(s['name']),
            background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: EdgeInsets.only(right: 20.w), child: const Icon(Icons.delete, color: Colors.white)),
            onDismissed: (direction) => _deleteSubject(index),
            child: GestureDetector(
              onTap: () {
                // Navigate to details
                Navigator.push(context, MaterialPageRoute(builder: (c) => SubjectDetailsScreen(subject: s)));
              },
              child: Container(
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("${s['count']}", style: TextStyle(color: Colors.grey, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                      SizedBox(width: 10.w),
                      Icon(Icons.arrow_forward_ios, size: 14.sp, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}