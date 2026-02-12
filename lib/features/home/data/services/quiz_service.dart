import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class QuizService {
  Future<List<Map<String, dynamic>>> getRandomQuizQuestions(int count) async {
    final List<Map<String, dynamic>> allQuestions = [];
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final Directory notesDir = Directory('${appDocDir.path}/notes');

      if (await notesDir.exists()) {
        final subjects = notesDir.listSync();
        for (var subject in subjects) {
          if (subject is Directory) {
            final notes = subject.listSync();
            for (var note in notes.where((f) => f.path.endsWith('.json'))) {
              final file = note as File;
              final content = await file.readAsString();
              final data = jsonDecode(content);
              if (data['quiz'] != null && data['quiz'] is List) {
                allQuestions.addAll(List<Map<String, dynamic>>.from(data['quiz']));
              }
            }
          }
        }
      }

      allQuestions.shuffle();
      return allQuestions.take(count).toList();

    } catch (e) {
      print("Error loading quiz questions: $e");
      return [];
    }
  }
}
