import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../../main.dart';
import '../../data/models/task.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  List<Task> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksJson = prefs.getString('user_tasks');
    if (tasksJson != null) {
      final List<dynamic> decoded = jsonDecode(tasksJson);
      setState(() {
        _tasks = decoded.map((item) => Task.fromJson(item)).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_tasks.map((t) => t.toJson()).toList());
    await prefs.setString('user_tasks', encoded);
  }

  void _addTask(String title, String subject, DateTime dueDate) {
    final newTask = Task(
      id: const Uuid().v4(),
      title: title,
      description: "",
      dueDate: dueDate,
      subject: subject,
    );
    setState(() {
      _tasks.add(newTask);
      _tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    });
    _saveTasks();
  }

  void _toggleTask(String id) {
    setState(() {
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        _tasks[index].isCompleted = !_tasks[index].isCompleted;
      }
    });
    _saveTasks();
  }

  void _deleteTask(String id) {
    setState(() {
      _tasks.removeWhere((t) => t.id == id);
    });
    _saveTasks();
  }

  void _showAddTaskSheet() {
    String title = "";
    String subject = "General";
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30.r))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 25.w, right: 25.w, top: 25.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Add Homework Task", style: GoogleFonts.poppins(fontSize: 20.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 20.h),
              TextField(
                onChanged: (v) => title = v,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: "Task Title",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r), borderSide: BorderSide.none),
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Due Date:", style: TextStyle(fontWeight: FontWeight.w600)),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime.now(), lastDate: DateTime(2030));
                      if (picked != null) setSheetState(() => selectedDate = picked);
                    },
                    child: Text("${selectedDate.day}/${selectedDate.month}/${selectedDate.year}", style: TextStyle(fontWeight: FontWeight.bold, color: const Color(0xFF3F6DFC))),
                  )
                ],
              ),
              SizedBox(height: 30.h),
              SizedBox(
                width: double.infinity,
                height: 55.h,
                child: ElevatedButton(
                  onPressed: () {
                    if (title.isNotEmpty) {
                      _addTask(title, subject, selectedDate);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3F6DFC), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r))),
                  child: Text("Add Task", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              SizedBox(height: 30.h),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text("My Tasks", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskSheet,
        backgroundColor: const Color(0xFF3F6DFC),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Iconsax.task_square, size: 60.sp, color: Colors.grey[300]), SizedBox(height: 15.h), Text("No tasks yet. Add your homework!", style: TextStyle(color: Colors.grey))]))
              : ListView.builder(
                  padding: EdgeInsets.all(20.w),
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    return Dismissible(
                      key: Key(task.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 20.w),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20.r)),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => _deleteTask(task.id),
                      child: Container(
                        margin: EdgeInsets.only(bottom: 15.h),
                        decoration: BoxDecoration(
                          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
                        ),
                        child: ListTile(
                          leading: IconButton(
                            icon: Icon(task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked, color: task.isCompleted ? Colors.green : Colors.grey),
                            onPressed: () => _toggleTask(task.id),
                          ),
                          title: Text(task.title, style: TextStyle(fontWeight: FontWeight.bold, decoration: task.isCompleted ? TextDecoration.lineThrough : null, color: isDarkMode ? Colors.white : Colors.black87)),
                          subtitle: Text("Due: ${task.dueDate.day}/${task.dueDate.month}", style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
                          trailing: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(color: const Color(0xFF3F6DFC).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10.r)),
                            child: Text(task.subject, style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: const Color(0xFF3F6DFC))),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
