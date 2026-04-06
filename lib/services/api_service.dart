import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/app_config.dart';

class ApiService {
  final AuthService _authService = AuthService();
  static const Duration _requestTimeout = Duration(seconds: 45);

  Future<http.Response> get(String path) async {
    try {
      final token = await _authService.getToken();
      final response = await http
          .get(
            AppConfig.uriForPath(path),
            headers: _buildHeaders(token),
          )
          .timeout(_requestTimeout);
      await _handleErrorResponse(response);
      return response;
    } catch (e) {
      throw _parseException(e);
    }
  }

  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    try {
      final token = await _authService.getToken();
      final response = await http
          .post(
            AppConfig.uriForPath(path),
            headers: _buildHeaders(token),
            body: jsonEncode(body),
          )
          .timeout(_requestTimeout);
      await _handleErrorResponse(response);
      return response;
    } catch (e) {
      throw _parseException(e);
    }
  }

  Future<http.Response> put(String path, Map<String, dynamic> body) async {
    try {
      final token = await _authService.getToken();
      final response = await http
          .put(
            AppConfig.uriForPath(path),
            headers: _buildHeaders(token),
            body: jsonEncode(body),
          )
          .timeout(_requestTimeout);
      await _handleErrorResponse(response);
      return response;
    } catch (e) {
      throw _parseException(e);
    }
  }

  Future<http.Response> delete(String path) async {
    try {
      final token = await _authService.getToken();
      final response = await http
          .delete(
            AppConfig.uriForPath(path),
            headers: _buildHeaders(token),
          )
          .timeout(_requestTimeout);
      await _handleErrorResponse(response);
      return response;
    } catch (e) {
      throw _parseException(e);
    }
  }

  Future<void> _handleErrorResponse(http.Response response) async {
    if (response.statusCode == 401 || response.statusCode == 403) {
      await _authService.logout();
      throw Exception("Session expired. Please login again.");
    } else if (response.statusCode >= 500) {
      throw Exception("Server error. Try again later.");
    } else if (response.statusCode >= 400) {
      // Try to parse error message from response body
      try {
        final errorData = jsonDecode(response.body);
        final message = errorData['detail'] ??
            errorData['message'] ??
            "Something went wrong. Try again.";
        throw Exception(message);
      } catch (_) {
        throw Exception("Something went wrong. Try again.");
      }
    }
  }

  Exception _parseException(dynamic error) {
    if (error is TimeoutException) {
      return Exception('Server took too long to respond. Please try again.');
    }

    if (error is SocketException ||
        error.toString().contains('connection') ||
        error.toString().contains('timeout') ||
        error.toString().contains('network')) {
      return Exception("Network error. Check your connection.");
    }

    if (error is Exception) {
      return error;
    }

    return Exception("Something went wrong. Try again.");
  }

  Map<String, String> _buildHeaders(String? token) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }
}
