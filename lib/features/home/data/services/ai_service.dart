import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  static const String _apiKey = "AIzaSyA0_eF8ql2e5y-wqUz8Rhmc6z3wfUxqcxU";

  late final GenerativeModel _model;
  ChatSession? _chatSession;

  AIService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
  }

  // Initial analysis of the audio
  Future<Map<String, dynamic>> processLectureAudio(File audioFile) async {
    try {
      final audioBytes = await audioFile.readAsBytes();

      final prompt = """
        You are an expert tutor. Analyze this lecture recording and:
        1. Create a concise summary (max 100 words).
        2. Create 3 quiz questions based on the lecture.
        
        Return the result STRICTLY as a JSON object with this format:
        {
          "summary": "The summary text...",
          "quiz": [
            {
              "question": "Question 1?",
              "options": ["Option A", "Option B", "Option C", "Option D"],
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

      // Clean the response
      responseText = responseText.replaceAll("```json", "").replaceAll("```", "").trim();
      final result = jsonDecode(responseText);

      // Start a chat session using the summary as context instead of the raw audio
      // This saves bandwidth and prevents "history too large" errors
      _chatSession = _model.startChat(history: [
        Content.text("Here is the summary of the lecture we are discussing: ${result['summary']}"),
        Content.model([TextPart("Understood. I have the lecture summary. I'm ready to answer any questions about this topic.")]),
      ]);

      return result;
    } catch (e) {
      print("AI Analysis Error: $e");
      return {
        "summary": "Could not analyze audio. Error: $e",
        "quiz": []
      };
    }
  }

  // Chatbot functionality
  Future<String> chatWithAgent(String message) async {
    try {
      if (_chatSession == null) {
        // If no audio was processed, just start a normal chat
        _chatSession = _model.startChat();
      }

      final response = await _chatSession!.sendMessage(Content.text(message));
      return response.text ?? "I'm sorry, I couldn't process that.";
    } catch (e) {
      print("Chat Error Details: $e");
      // Return the actual error message to help debugging
      return "Chat Error: ${e.toString().split('\n').first}";
    }
  }
}
