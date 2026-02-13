import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Subject Model ---
class Subject {
  final String name;
  final String desc;
  final Color color;
  final IconData icon;

  const Subject({
    required this.name,
    required this.desc,
    required this.color,
    required this.icon,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'desc': desc,
    'color': color.value,
    'icon': icon.codePoint,
  };

  factory Subject.fromJson(Map<String, dynamic> json) {
    // To support tree shaking, we must use constant IconData.
    final int code = json['icon'];
    IconData selectedIcon;

    if (code == Icons.functions.codePoint) {
      selectedIcon = Icons.functions;
    } else if (code == Icons.science.codePoint) {
      selectedIcon = Icons.science;
    } else if (code == Icons.menu_book.codePoint) {
      selectedIcon = Icons.menu_book;
    } else if (code == Icons.book.codePoint) {
      selectedIcon = Icons.book;
    } else {
      selectedIcon = Icons.help_outline; // Constant fallback
    }

    return Subject(
      name: json['name'],
      desc: json['desc'],
      color: Color(json['color']),
      icon: selectedIcon,
    );
  }
}

// --- Provider ---
final subjectProvider = StateNotifierProvider<SubjectNotifier, List<Subject>>((ref) {
  return SubjectNotifier();
});

class SubjectNotifier extends StateNotifier<List<Subject>> {
  SubjectNotifier() : super([]) {
    _loadSubjects();
  }

  static const String _storageKey = 'user_subjects_list';

  Future<void> _loadSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final String? subjectsJson = prefs.getString(_storageKey);
    if (subjectsJson != null) {
      final List<dynamic> decoded = jsonDecode(subjectsJson);
      state = decoded.map((item) => Subject.fromJson(item)).toList();
    } else {
      // Default subjects
      state = const [
        Subject(name: "Mathematics", desc: "Algebra, Calculus", color: Color(0xFF4A90E2), icon: Icons.functions),
        Subject(name: "Physics", desc: "Mechanics, Thermo", color: Color(0xFF9B51E0), icon: Icons.science),
        Subject(name: "Literature", desc: "Poetry, Prose", color: Color(0xFF27AE60), icon: Icons.menu_book),
      ];
      _saveSubjects();
    }
  }

  Future<void> _saveSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(state.map((s) => s.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  void addSubject(Subject subject) {
    state = [...state, subject];
    _saveSubjects();
  }

  void deleteSubject(String name) {
    state = state.where((s) => s.name != name).toList();
    _saveSubjects();
  }
}
