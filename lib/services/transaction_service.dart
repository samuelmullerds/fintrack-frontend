import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TransactionService {
  // ⚠️ Emulador Android → use http://10.0.2.2:8081
  // ⚠️ Dispositivo físico → use o IP da sua máquina
  // ⚠️ Web/Chrome → localhost funciona normalmente
  final String baseUrl = "http://localhost:8081/transactions";

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Map<String, String> _headers(String token) => {
    "Content-Type": "application/json",
    "Authorization": "Bearer $token",
  };

  /// Busca todas as transações do usuário logado
  Future<List<Map<String, dynamic>>> getTransactions() async {
    final token = await _getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: _headers(token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print("Erro ao buscar transações: $e");
    }
    return [];
  }

  /// Adiciona uma nova transação — envia date no formato yyyy-MM-dd
  Future<bool> addTransaction({
    required double value,
    required String category,
    required String paymentMethod,
    required String type,
    String? date,         // yyyy-MM-dd  (ex: "2026-03-26")
    String? description,
  }) async {
    final token = await _getToken();
    if (token == null) return false;

    // Usa a data informada ou hoje como fallback
    final today = DateTime.now();
    final fallback =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final body = <String, dynamic>{
      "value": value,
      "category": category,
      "paymentMethod": paymentMethod,
      "type": type,
      "date": date ?? fallback,
    };

    if (description != null && description.isNotEmpty) {
      body["description"] = description;
    }

    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: _headers(token),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        // Imprime o body do erro para facilitar depuração
        print("Erro ao adicionar transação [${response.statusCode}]: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Exceção ao adicionar transação: $e");
      return false;
    }
  }

  /// Deleta uma transação por ID
  Future<bool> deleteTransaction(String id) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/$id"),
        headers: _headers(token),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print("Erro ao deletar transação: $e");
      return false;
    }
  }
}