import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'auth_service.dart';
import '../data/models/chat_model.dart';

class ApiClient {
  static const String baseUrl = 'https://edenhub.io/api';
  final AuthService _authService = AuthService();

  // Get authorization headers
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    if (token == null) throw Exception('Not authenticated');

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // Generic GET request
  Future<dynamic> _get(String endpoint) async {
    try {
      final headers = await _getHeaders();
      print('GET Request: $baseUrl$endpoint');
      
      final response = await http
          .get(Uri.parse('$baseUrl$endpoint'), headers: headers)
          .timeout(const Duration(seconds: 10));

      print('GET Response [${response.statusCode}]');
      return _handleResponse(response);
    } on TimeoutException {
      throw Exception('Request timeout');
    } catch (e) {
      print('GET Error: $e');
      rethrow;
    }
  }

  // Generic POST request
  Future<dynamic> _post(String endpoint, Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();
      print('POST Request: $baseUrl$endpoint');

      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 30));

      print('POST Response [${response.statusCode}]');
      return _handleResponse(response);
    } on TimeoutException {
      throw Exception('Request timeout');
    } catch (e) {
      print('POST Error: $e');
      rethrow;
    }
  }

  // Handle responses
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      _authService.logout();
      throw Exception('Authentication failed. Please login again.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    }

    try {
      final error = json.decode(response.body);
      throw Exception('API Error: ${error['detail'] ?? error['message'] ?? response.body}');
    } catch (e) {
      throw Exception('API Error ${response.statusCode}');
    }
  }

  // 1. Fetch chat list
  Future<List<ChatSession>> getChatList() async {
    try {
      final response = await _get('/chats');
      
      if (response is List) {
        print('SUCCESS! Found ${response.length} chat sessions');
        return response.map((json) => ChatSession.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('getChatList Error: $e');
      return [];
    }
  }

  // 2. Fetch models
  Future<List<dynamic>> getModels() async {
    try {
      final response = await _get('/models');
      
      if (response is Map && response['data'] != null) {
        final models = response['data'] as List;
        print('Models loaded: ${models.length} models');
        for (var model in models) {
          print('  - ${model['name'] ?? model['id']}');
        }
        return models;
      } else if (response is List) {
        print('Models loaded: ${response.length} models');
        return response;
      }
      
      return [];
    } catch (e) {
      print('getModels Error: $e');
      return [];
    }
  }

  // 3. Fetch specific chat details
  Future<ChatSession?> getChatDetail(String chatId) async {
    try {
      final response = await _get('/chats/$chatId');
      if (response != null) {
        return ChatSession.fromJson(response);
      }
      return null;
    } catch (e) {
      print('getChatDetail Error: $e');
      return null;
    }
  }

  // 4. Create new chat
  Future<ChatSession?> createChat({String? title}) async {
    try {
      final response = await _post('/chats/new', {
        if (title != null) 'title': title,
      });
      
      if (response != null) {
        return ChatSession.fromJson(response);
      }
      return null;
    } catch (e) {
      print('createChat Error: $e');
      return null;
    }
  }

  // 5. Send message with streaming
  Stream<String> sendMessageStream(
    String message,
    String model, {
    String? chatId,
    List<Message>? history,
  }) async* {
    final headers = await _getHeaders();
    headers['Accept'] = 'text/event-stream';

    final messages = <Map<String, dynamic>>[];
    
    // Add history if provided
    if (history != null) {
      messages.addAll(history.map((m) => m.toJson()));
    }
    
    // Add current message
    messages.add({'role': 'user', 'content': message});

    final body = {
      'model': model,
      'messages': messages,
      'stream': true,
    };

    if (chatId != null) {
      body['chat_id'] = chatId;
    }

    print('STREAM Request: $baseUrl/chat/completions');

    final request = http.Request('POST', Uri.parse('$baseUrl/chat/completions'));
    request.headers.addAll(headers);
    request.body = json.encode(body);

    final client = http.Client();

    try {
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Stream failed: ${response.statusCode}');
      }

      String buffer = '';
      await for (var chunk in response.stream.transform(utf8.decoder)) {
        buffer += chunk;

        while (buffer.contains('\n')) {
          final lineEnd = buffer.indexOf('\n');
          final line = buffer.substring(0, lineEnd).trim();
          buffer = buffer.substring(lineEnd + 1);

          if (line.isEmpty) continue;

          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            if (data == '[DONE]') break;

            try {
              final parsed = json.decode(data);
              String? content;

              // Extract content
              if (parsed['choices'] != null && parsed['choices'].isNotEmpty) {
                final delta = parsed['choices'][0]['delta'];
                content = delta?['content'];
              }

              if (content != null && content.isNotEmpty) {
                yield content;
              }
            } catch (e) {
              continue;
            }
          }
        }
      }
    } finally {
      client.close();
    }
  }

  // 6. Send message without streaming (for testing)
  Future<String> sendMessage(
    String message,
    String model, {
    String? chatId,
  }) async {
    final body = {
      'model': model,
      'messages': [
        {'role': 'user', 'content': message}
      ],
      'stream': false,
    };

    if (chatId != null) {
      body['chat_id'] = chatId;
    }

    final response = await _post('/chat/completions', body);

    if (response['choices'] != null && response['choices'].isNotEmpty) {
      return response['choices'][0]['message']['content'] ?? '';
    }

    return response['content'] ?? '';
  }
}
