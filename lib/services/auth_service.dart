import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'https://opengym-api-9ztx.onrender.com';
  static const String tokenKey = 'auth_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  Future<bool> register(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'] ?? data['token'];
        if (token != null) {
          await _storage.write(key: tokenKey, value: token);
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: tokenKey);
  }

  Future<String?> getToken() async {
    final token = await _storage.read(key: tokenKey);
    return token;
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    final loggedIn = token != null && token.isNotEmpty;
    return loggedIn;
  }
}
