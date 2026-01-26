import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';

class ApiClient {
  static const String baseUrl = 'https://edenhub.io/api/v1';
  final AuthService _authService = AuthService();

  // Generic GET request
  Future<dynamic> get(String endpoint) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Request failed: $e');
    }
  }

  // Generic POST request
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Request failed: $e');
    }
  }

  // Streaming POST for chat completions
  Stream<String> postStream(String endpoint, Map<String, dynamic> body) async* {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    final request = http.Request('POST', Uri.parse('$baseUrl$endpoint'));
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
    });
    request.body = json.encode(body);

    final client = http.Client();
    try {
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Stream request failed: ${response.statusCode}');
      }

      await for (var chunk in response.stream.transform(utf8.decoder)) {
        // Parse SSE (Server-Sent Events) format
        final lines = chunk.split('\n');
        for (var line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6);
            if (data.trim() == '[DONE]') continue;
            
            try {
              final parsed = json.decode(data);
              if (parsed['choices'] != null && parsed['choices'].isNotEmpty) {
                final delta = parsed['choices'][0]['delta'];
                if (delta['content'] != null) {
                  yield delta['content'];
                }
              }
            } catch (e) {
              // Skip malformed chunks
              continue;
            }
          }
        }
      }
    } finally {
      client.close();
    }
  }

  // Handle API responses
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      // Token expired or invalid
      _authService.logout();
      throw Exception('Authentication failed. Please login again.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    }

    throw Exception('API Error ${response.statusCode}: ${response.body}');
  }

  // Specific API methods
  Future<List<dynamic>> getChats() async {
    return await get('/chats');
  }

  Future<dynamic> createChat(Map<String, dynamic> chatData) async {
    return await post('/chats/new', chatData);
  }

  Future<List<dynamic>> getModels() async {
    return await get('/models');
  }

  Stream<String> sendMessage(String message, String model, {String? chatId}) {
    return postStream('/chat/completions', {
      'model': model,
      'messages': [
        {'role': 'user', 'content': message}
      ],
      'stream': true,
      if (chatId != null) 'chat_id': chatId,
    });
  }
}
