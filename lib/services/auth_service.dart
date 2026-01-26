import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String baseUrl = 'https://edenhub.io';

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    if (token == null) return false;
    
    // Verify token is still valid
    return await _verifyToken(token);
  }

  // Get stored token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Save token after successful login
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // Save user data
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _storage.write(key: _userKey, value: json.encode(userData));
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    final data = await _storage.read(key: _userKey);
    if (data == null) return null;
    return json.decode(data);
  }

  // Verify token validity
  Future<bool> _verifyToken(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/auths'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  // Extract token from WebView localStorage
  String? extractTokenFromJs(String? jsResult) {
    if (jsResult == null || jsResult.isEmpty || jsResult == 'null') {
      return null;
    }
    // Remove quotes if present
    return jsResult.replaceAll('"', '').replaceAll("'", '');
  }
} 