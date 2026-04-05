import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthResult {
  final bool success;
  final String? errorMessage;

  AuthResult.success()
      : success = true,
        errorMessage = null;
  AuthResult.error(this.errorMessage) : success = false;
}

class AuthService {
  static const String baseUrl = 'https://opengym-api-9ztx.onrender.com';
  static const String tokenKey = 'auth_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  Future<AuthResult> register(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AuthResult.success();
      } else {
        // Parse error message from response
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage =
              errorData['detail'] as String? ?? 'Registration failed';
          return AuthResult.error(errorMessage);
        } catch (e) {
          // Fallback error messages based on status code
          switch (response.statusCode) {
            case 400:
              return AuthResult.error('Email already registered');
            case 422:
              return AuthResult.error('Invalid email format');
            case 500:
              return AuthResult.error('Server error. Please try again later.');
            default:
              return AuthResult.error('Registration failed. Please try again.');
          }
        }
      }
    } catch (e) {
      return AuthResult.error('Network error. Check your connection.');
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
