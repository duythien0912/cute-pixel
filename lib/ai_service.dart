import 'package:flutter/material.dart';
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

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'groq/compound',
        'messages': [
          {'role': 'user', 'content': promptText},
        ],
      }),
    );

    if (response.statusCode != 200) {
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
      throw Exception(
        'Gemini API Error ${response.statusCode} ${response.reasonPhrase} ${response.body.substring(0, 100)}...',
      );
    }

    final responseData = jsonDecode(response.body);
    var text =
        responseData['candidates'][0]['content']['parts'][0]['text']?.trim() ??
        '';
    return _parsePixelData(text, gridSize);
  }

  static String _buildPrompt(String subject, int gridSize) {
    return '''
You are a pixel-art generator that paints on a square canvas.

Canvas:
- Size: ${gridSize}x$gridSize pixels.
- Represent the canvas as a 2D array: rows = Y from top to bottom, columns = X from left to right.

Goal:
- Draw a simple, recognizable pixel-art version of the subject: "$subject".
- The main subject must be clearly visible and roughly centered.
- The subject should occupy about 60–80% of the canvas height and width (not too small, not touching the edges).
- Use a consistent background color different from the subject (e.g. light or dark solid background).
- Use at least 3 different colors total (foreground + details + background).
- Prefer high-contrast colors so the subject stands out from the background.

Styling guidelines:
- Think in terms of a small icon or game sprite, not photorealism.
- Avoid random noise. Neighboring pixels of the same region (e.g. face, clothing, background) should use similar colors.
- Symmetric subjects (like faces, logos, characters) should look roughly symmetric around the vertical center of the canvas.

Output rules (STRICT):
- Return ONLY valid JSON.
- The JSON must be a 2D array with exactly $gridSize rows.
- Each row must contain exactly $gridSize strings.
- Each string must be a valid hex color in format "#RRGGBB".
- Do NOT include comments, markdown, explanations, or extra text.
- Do NOT wrap the output in code fences.

Output example structure (for a 2x2 image, example only):
[["#000000","#FFFFFF"],["#FF0000","#00FF00"]]
''';
  }

  static List<List<Color>> _parsePixelData(String text, int gridSize) {
    try {
      // Clean HTML entities and markdown
      text = text
          .replaceAll('\'', '"')
          .replaceAll('&quot;', '"')
          .replaceAll('&"', '"');

      // Find JSON boundaries
      final jsonStart = text.indexOf('[');
      final jsonEnd = text.lastIndexOf(']') + 1;

      if (jsonStart == -1 || jsonEnd <= jsonStart) {
        throw Exception(
          'No JSON array found in response: ${text.substring(0, 100)}...',
        );
      }

      final jsonStr = text.substring(jsonStart, jsonEnd);
      debugPrint('Parsing JSON: $jsonStr');

      final List<dynamic> data = jsonDecode(jsonStr);
      return _convertToColorGrid(data, gridSize);
    } catch (e) {
      debugPrint('Parse error: $e');
      debugPrint('Raw response: $text');
      throw Exception('Failed to parse AI response: $e');
    }
  }

  static List<List<Color>> _convertToColorGrid(
    List<dynamic> data,
    int gridSize,
  ) {
    if (data.isEmpty) {
      throw Exception('Empty data array received');
    }

    final pixels = List.generate(
      gridSize,
      (_) => List.generate(gridSize, (_) => Colors.white),
    );

    for (int i = 0; i < gridSize && i < data.length; i++) {
      if (data[i] is! List) {
        throw Exception('Invalid row format at index $i: ${data[i]}');
      }

      final row = data[i] as List;
      for (int j = 0; j < gridSize && j < row.length; j++) {
        if (row[j] is String) {
          pixels[i][j] = _hexToColor(row[j]);
        }
      }
    }
    return pixels;
  }

  static Color _hexToColor(String hex) {
    try {
      hex = hex.replaceAll('#', '').toUpperCase();
      if (hex.length == 6 && RegExp(r'^[0-9A-F]{6}$').hasMatch(hex)) {
        return Color(int.parse('FF$hex', radix: 16));
      }
    } catch (e) {
      print('Invalid hex color: $hex');
    }
    return Colors.white;
  }
}
