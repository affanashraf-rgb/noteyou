import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  // ⚠️ YOUR API KEY
  static const String _apiKey = "AIzaSyA0_eF8ql2e5y-wqUz8Rhmc6z3wfUxqcxU";

  late final GenerativeModel _model;

  AIService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash', // Flash is faster and cheaper
      apiKey: _apiKey,
    );
  }

  // This function sends audio to Gemini and asks for a Summary + Quiz
  Future<Map<String, dynamic>> processLectureAudio(File audioFile) async {
    try {
      final audioBytes = await audioFile.readAsBytes();

      // 1. THE PROMPT
      final prompt = TextPart("""
        You are an expert tutor. Listen to this lecture recording and do two things:
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
        (Note: 'answer' should be the index of the correct option: 0, 1, 2, or 3)
        Do not use Markdown formatting (like ```json). Just return the raw JSON string.
      """);

      // 2. PREPARE AUDIO DATA
      final audioPart = DataPart('audio/mp4', audioBytes);

      // 3. SEND TO GEMINI
      final content = [Content.multi([prompt, audioPart])];
      final response = await _model.generateContent(content);

      // 4. CLEAN UP RESPONSE
      String? responseText = response.text;
      if (responseText == null) throw "No response from AI";

      responseText = responseText.replaceAll("```json", "").replaceAll("```", "").trim();

      // 5. PARSE TO MAP
      return jsonDecode(responseText);

    } catch (e) {
      print("AI Error: $e");
      return {
        "summary": "Could not analyze audio. Please check your internet connection or API key.",
        "quiz": []
      };
    }
  }
}
