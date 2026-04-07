import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class AuthResult {
  final bool success;
  final String? errorMessage;

  AuthResult.success()
      : success = true,
        errorMessage = null;
  AuthResult.error(this.errorMessage) : success = false;
}

class AuthService {
  static String get baseUrl => AppConfig.normalizedApiBaseUrl;
  static const String tokenKey = 'auth_token';
  static const String internetRequiredMessage =
      'Internet connection is required (Wi-Fi or mobile data).';
  static bool _isApiWarmedUp = false;

  static const Duration _requestTimeout = Duration(seconds: 45);
  static const Duration _warmupTimeout = Duration(seconds: 10);
  static const Duration _internetCheckTimeout = Duration(seconds: 8);

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  Future<void> warmupApi() async {
    if (_isApiWarmedUp) {
      return;
    }

    try {
      final response = await http
          .get(AppConfig.uriForPath('/health'))
          .timeout(_warmupTimeout);
      if (response.statusCode < 500) {
        _isApiWarmedUp = true;
      }
    } catch (_) {
      // Ignore warmup failures to preserve offline-first behavior.
    }
  }

  Future<AuthResult> register(String email, String password) async {
    final hasInternet = await _hasInternetAccess();
    if (!hasInternet) {
      return AuthResult.error(internetRequiredMessage);
    }

    try {
      final response = await http
          .post(
            AppConfig.uriForPath('/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(_requestTimeout);

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
    } on TimeoutException {
      return AuthResult.error(internetRequiredMessage);
    } on SocketException {
      return AuthResult.error(internetRequiredMessage);
    } catch (e) {
      return AuthResult.error('Network error. Check your connection.');
    }
  }

  Future<AuthResult> login(String email, String password) async {
    final hasInternet = await _hasInternetAccess();
    if (!hasInternet) {
      return AuthResult.error(internetRequiredMessage);
    }

    try {
      final response = await http
          .post(
            AppConfig.uriForPath('/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'] ?? data['token'];
        if (token != null) {
          await _storage.write(key: tokenKey, value: token);
          return AuthResult.success();
        }
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        return AuthResult.error('Invalid credentials');
      }

      try {
        final errorData = jsonDecode(response.body);
        final message =
            errorData['detail'] as String? ?? 'Login failed. Please try again.';
        return AuthResult.error(message);
      } catch (_) {
        return AuthResult.error('Login failed. Please try again.');
      }
    } on TimeoutException {
      return AuthResult.error(internetRequiredMessage);
    } on SocketException {
      return AuthResult.error(internetRequiredMessage);
    } catch (e) {
      return AuthResult.error('Network error. Check your connection.');
    }
  }

  Future<bool> _hasInternetAccess() async {
    try {
      final response = await http
          .get(AppConfig.uriForPath('/health'))
          .timeout(_internetCheckTimeout);
      return response.statusCode < 500;
    } on TimeoutException {
      return false;
    } on SocketException {
      return false;
    } catch (_) {
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
