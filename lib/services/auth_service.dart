import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = "http://localhost:8081/auth";

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      if (response.statusCode == 200) return jsonDecode(response.body);
      if (response.statusCode == 401 || response.statusCode == 404) return null;
      throw Exception("Erro no servidor [${response.statusCode}]");
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> register(
      String name, String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"name": name, "email": email, "password": password}),
      );

      if (res.statusCode == 201 || res.statusCode == 200) {
        return await login(email, password);
      }
      if (res.statusCode == 409) return null; // e-mail já cadastrado
      throw Exception("Erro ao registrar [${res.statusCode}]: ${res.body}");
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUser() async {
    final token = await _token();
    if (token == null) return null;
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/me"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
      print("getUser error [${res.statusCode}]");
      return null;
    } catch (e) {
      print("getUser exception: $e");
      return null;
    }
  }

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
}