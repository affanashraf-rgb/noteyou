import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:path_provider/path_provider.dart';

class AIService {
  static const String _apiKey = "AIzaSyA0_eF8ql2e5y-wqUz8Rhmc6z3wfUxqcxU";

  late final GenerativeModel _model;
  ChatSession? _chatSession;

  AIService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: _apiKey,
    );
  }

  Future<Map<String, dynamic>> processLectureAudio(File audioFile, {String? subject}) async {
    try {
      final audioBytes = await audioFile.readAsBytes();

      final prompt = """
        You are an expert tutor. Analyze this lecture recording and:
        1. Create a concise summary (max 100 words).
        2. Create 3 quiz questions based on the lecture.
        3. Create a full, detailed, and explanatory document of the lecture.
        
        Return the result STRICTLY as a JSON object with this format:
        {
          "summary": "The short summary...",
          "explanatoryDoc": "The full detailed explanation...",
          "quiz": [
            {
              "question": "Question?",
              "options": ["A", "B", "C", "D"],
              "answer": 0 
            }
          ]
        }
        Do not use Markdown formatting. Just return the raw JSON string.
      """;

      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('audio/mp4', audioBytes),
        ])
      ];

      final response = await _model.generateContent(content);
      String? responseText = response.text;
      if (responseText == null) throw "No response from AI";

      responseText = responseText.replaceAll("```json", "").replaceAll("```", "").trim();
      final result = jsonDecode(responseText);

      // --- SAVE TO DISK ---
      if (subject != null) {
        await _saveSmartNotes(subject, audioFile.path, result);
      }

      _chatSession = _model.startChat(history: [
        Content.text("Lecture Context: ${result['summary']}"),
        Content.model([TextPart("Understood. I have the lecture context. Ask me anything.")]),
      ]);

      return result;
    } catch (e) {
      print("AI Error: $e");
      return {"summary": "Error: $e", "quiz": [], "explanatoryDoc": ""};
    }
  }

  Future<void> _saveSmartNotes(String subject, String audioPath, Map<String, dynamic> data) async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String folderPath = '${appDocDir.path}/notes/$subject';
      final Directory folder = Directory(folderPath);
      
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }

      final String fileName = audioPath.split('/').last.replaceAll('.m4a', '.json');
      final File file = File('$folderPath/$fileName');
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      print("Error saving notes: $e");
    }
  }

  Future<String> chatWithAgent(String message) async {
    try {
      _chatSession ??= _model.startChat();
      final response = await _chatSession!.sendMessage(Content.text(message));
      return response.text ?? "I couldn't process that.";
    } catch (e) {
      return "Chat Error: ${e.toString().split('\n').first}";
    }
  }
}
