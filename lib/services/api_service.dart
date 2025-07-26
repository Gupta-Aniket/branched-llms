import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

class ApiService {
  
  Future<String> sendMessage(
    List<Map<String, String>> context, 
    String provider,
    String apiKey,
  ) async {
    print("🔗 Context Sent: ${jsonEncode(context)}");
    try {
      switch (provider.toLowerCase()) {
        case 'openai':
          return await _sendToOpenAI(context, apiKey);
        case 'gemini':
          return await _sendToGemini(context, apiKey);
        case 'claude':
          return await _sendToClaude(context, apiKey);
        default:
          throw Exception('Unsupported provider: $provider');
      }
    } catch (e) {
      throw Exception('API call failed: $e');
    }
  }

  /// ✅ OpenAI: gpt-3.5 / gpt-4 compatible
  Future<String> _sendToOpenAI(
      List<Map<String, String>> context, String apiKey) async {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': context,
        'max_tokens': 200,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'].toString().trim();
    } else {
      log("OpenAI Error: ${response.body}");
      throw Exception('OpenAI API error: ${response.statusCode}');
    }
  }

  /// ✅ Gemini: gemini-2.0-flash compatible
  Future<String> _sendToGemini(
      List<Map<String, String>> context, String apiKey) async {
    final contents = context.map((m) {
      return {
        'role': m['role'] == 'user' ? 'user' : 'model',
        'parts': [
          {'text': m['content']}
        ],
      };
    }).toList();

    final response = await http.post(
      Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'contents': contents}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text']
          .toString()
          .trim();
    } else {
      log("Gemini Error: ${response.body}");
      throw Exception('Gemini API error: ${response.statusCode}');
    }
  }

  /// ✅ Claude: Claude 3.x compatible
  Future<String> _sendToClaude(
      List<Map<String, String>> context, String apiKey) async {
    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': 'claude-3-sonnet-20240229',
        'max_tokens': 200,
        'messages': context,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['content'][0]['text'].toString().trim();
    } else {
      log("Claude Error: ${response.body}");
      throw Exception('Claude API error: ${response.statusCode}');
    }
  }
}
