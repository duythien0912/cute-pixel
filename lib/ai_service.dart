import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum AIModel { groq, gemini }

class AIService {

  static Future<List<List<Color>>> generate(
    AIModel model,
    String prompt,
    int gridSize,
  ) async {
    switch (model) {
      case AIModel.groq:
        return _generateGroq(prompt, gridSize);
      case AIModel.gemini:
        return _generateGemini(prompt, gridSize);
    }
  }

  static Future<List<List<Color>>> _generateGroq(
    String prompt,
    int gridSize,
  ) async {
    final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    final promptText = _buildPrompt(prompt, gridSize);

    http.Response? response;
    for (int attempt = 0; attempt < 3; attempt++) {
      response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'user', 'content': promptText},
          ],
        }),
      );

      if (response.statusCode == 200) break;
      if (response.statusCode == 429 && attempt < 2) {
        await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
      }
    }

    if (response!.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(
        errorData['error']['message'] ?? 'API Error ${response.statusCode}',
      );
    }

    final responseData = jsonDecode(response.body);
    var text = responseData['choices'][0]['message']['content']?.trim() ?? '';
    return _parsePixelData(text, gridSize);
  }

  static Future<List<List<Color>>> _generateGemini(
    String prompt,
    int gridSize,
  ) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent',
    );
    final promptText = _buildPrompt(prompt, gridSize);

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', 'x-goog-api-key': apiKey},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': promptText},
            ],
          },
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini API Error ${response.statusCode}');
    }

    final responseData = jsonDecode(response.body);
    var text =
        responseData['candidates'][0]['content']['parts'][0]['text']?.trim() ??
        '';
    return _parsePixelData(text, gridSize);
  }



  static String _buildPrompt(String prompt, int gridSize) {
    return '''You are a pixel-art generator.

Generate a ${gridSize}x${gridSize} pixel art for the subject: "${prompt}".

Output rules (STRICT):
- Return ONLY valid JSON.
- The JSON must be a 2D array with exactly ${gridSize} rows.
- Each row must contain exactly ${gridSize} strings.
- Each string must be a valid hex color in format "#RRGGBB".
- Do NOT include comments, markdown, explanations, or extra text.
- Do NOT wrap the output in code fences.

Output example structure:
[["#000000","#FFFFFF"],["#FF0000","#00FF00"]]''';
  }

  static List<List<Color>> _parsePixelData(String text, int gridSize) {
    text = text.replaceAll('&quot;', '"').replaceAll('&amp;', '&');
    final jsonStart = text.indexOf('[');
    final jsonEnd = text.lastIndexOf(']') + 1;

    if (jsonStart == -1 || jsonEnd <= jsonStart) {
      throw Exception('Invalid response format');
    }

    final jsonStr = text.substring(jsonStart, jsonEnd);
    final List<dynamic> data = jsonDecode(jsonStr);
    return _convertToColorGrid(data, gridSize);
  }

  static List<List<Color>> _convertToColorGrid(
    List<dynamic> data,
    int gridSize,
  ) {
    final pixels = List.generate(
      gridSize,
      (_) => List.generate(gridSize, (_) => Colors.white),
    );

    for (int i = 0; i < gridSize && i < data.length; i++) {
      for (int j = 0; j < gridSize && j < data[i].length; j++) {
        pixels[i][j] = _hexToColor(data[i][j]);
      }
    }
    return pixels;
  }

  static Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return Colors.white;
  }
}
