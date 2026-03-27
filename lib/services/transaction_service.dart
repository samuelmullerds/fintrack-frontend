import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TransactionService {
  static const String baseUrl = "http://localhost:8081/transactions";

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Map<String, String> _headers(String token) => {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      };


  Future<List<Map<String, dynamic>>> getTransactions({int page = 0, int size = 100}) async {
    final token = await _token();
    if (token == null) return [];

    try {
      final res = await http.get(
        Uri.parse("$baseUrl?page=$page&size=$size&sort=date,desc"),
        headers: _headers(token),
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        // Resposta paginada: { content: [...], ... }
        final List<dynamic> content = body['content'] ?? [];
        return content.cast<Map<String, dynamic>>();
      }
      print("getTransactions error [${res.statusCode}]: ${res.body}");
    } catch (e) {
      print("getTransactions exception: $e");
    }
    return [];
  }

  Future<Map<String, dynamic>?> getDashboard() async {
    final token = await _token();
    if (token == null) return null;

    try {
      final res = await http.get(
        Uri.parse("$baseUrl/dashboard"),
        headers: _headers(token),
      );

      if (res.statusCode == 200) return jsonDecode(res.body);
      print("getDashboard error [${res.statusCode}]: ${res.body}");
    } catch (e) {
      print("getDashboard exception: $e");
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getCategorySummary() async {
    final token = await _token();
    if (token == null) return [];

    try {
      final res = await http.get(
        Uri.parse("$baseUrl/category-summary"),
        headers: _headers(token),
      );

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.cast<Map<String, dynamic>>();
      }
      print("getCategorySummary error [${res.statusCode}]: ${res.body}");
    } catch (e) {
      print("getCategorySummary exception: $e");
    }
    return [];
  }

  Future<bool> addTransaction({
    required double amount,
    required String description,
    required String category,
    required String type,          
    required String date,          
  }) async {
    final token = await _token();
    if (token == null) return false;

    final body = jsonEncode({
      "description": description,
      "amount": amount,
      "category": category,
      "type": type,
      "date": date,
    });

    try {
      final res = await http.post(
        Uri.parse(baseUrl),
        headers: _headers(token),
        body: body,
      );

      if (res.statusCode == 200 || res.statusCode == 201) return true;
      print("addTransaction error [${res.statusCode}]: ${res.body}");
      return false;
    } catch (e) {
      print("addTransaction exception: $e");
      return false;
    }
  }

  Future<bool> updateTransaction({
    required int id,
    required double amount,
    required String description,
    required String category,
    required String type,
    required String date,
  }) async {
    final token = await _token();
    if (token == null) return false;

    final body = jsonEncode({
      "description": description,
      "amount": amount,
      "category": category,
      "type": type,
      "date": date,
    });

    try {
      final res = await http.put(
        Uri.parse("$baseUrl/$id"),
        headers: _headers(token),
        body: body,
      );

      if (res.statusCode == 200) return true;
      print("updateTransaction error [${res.statusCode}]: ${res.body}");
      return false;
    } catch (e) {
      print("updateTransaction exception: $e");
      return false;
    }
  }

  Future<bool> deleteTransaction(int id) async {
    final token = await _token();
    if (token == null) return false;

    try {
      final res = await http.delete(
        Uri.parse("$baseUrl/$id"),
        headers: _headers(token),
      );
      if (res.statusCode == 200 || res.statusCode == 204) return true;
      print("deleteTransaction error [${res.statusCode}]: ${res.body}");
      return false;
    } catch (e) {
      print("deleteTransaction exception: $e");
      return false;
    }
  }
}