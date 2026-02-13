import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../main.dart';
import '../../data/logic/subject_provider.dart';
import 'subject_details_screen.dart';

class SubjectsScreen extends ConsumerStatefulWidget {
  const SubjectsScreen({super.key});

  @override
  ConsumerState<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends ConsumerState<SubjectsScreen> {
  void _addSubject(String name, Color color) {
    ref.read(subjectProvider.notifier).addSubject(Subject(
      name: name,
      desc: "New Course",
      color: color,
      icon: Icons.book,
    ));
    Navigator.pop(context);
  }

  void _deleteSubject(String name) {
    ref.read(subjectProvider.notifier).deleteSubject(name);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("$name deleted"),
    ));
  }

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
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    
    // --- WATCH THE GLOBAL SUBJECTS ---
    final List<Subject> subjects = ref.watch(subjectProvider);

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text("My Subjects", style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
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
            key: Key(s.name),
            background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: EdgeInsets.only(right: 20.w), child: const Icon(Icons.delete, color: Colors.white)),
            onDismissed: (direction) => _deleteSubject(s.name),
            child: GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (c) => SubjectDetailsScreen(subject: {
                  'name': s.name,
                  'desc': s.desc,
                  'color': s.color,
                  'icon': s.icon,
                })));
              },
              child: Container(
                margin: EdgeInsets.only(bottom: 15.h),
                padding: EdgeInsets.all(15.w),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(15.r),
                  border: Border.all(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
                ),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: s.color.withValues(alpha: 0.1), child: Icon(s.icon, color: s.color)),
                  title: Text(s.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp, color: isDarkMode ? Colors.white : Colors.black87)),
                  subtitle: Text(s.desc, style: TextStyle(color: Colors.grey)),
                  trailing: Icon(Icons.arrow_forward_ios, size: 14.sp, color: Colors.grey),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
