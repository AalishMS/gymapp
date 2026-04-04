import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiService {
  final AuthService _authService = AuthService();

  Future<http.Response> get(String path) async {
    final token = await _authService.getToken();
    return http.get(
      Uri.parse('${AuthService.baseUrl}$path'),
      headers: _buildHeaders(token),
    );
  }

  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    final token = await _authService.getToken();
    return http.post(
      Uri.parse('${AuthService.baseUrl}$path'),
      headers: _buildHeaders(token),
      body: jsonEncode(body),
    );
  }

  Future<http.Response> put(String path, Map<String, dynamic> body) async {
    final token = await _authService.getToken();
    return http.put(
      Uri.parse('${AuthService.baseUrl}$path'),
      headers: _buildHeaders(token),
      body: jsonEncode(body),
    );
  }

  Future<http.Response> delete(String path) async {
    final token = await _authService.getToken();
    return http.delete(
      Uri.parse('${AuthService.baseUrl}$path'),
      headers: _buildHeaders(token),
    );
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
