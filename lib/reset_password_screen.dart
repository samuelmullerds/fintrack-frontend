import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;

  const ResetPasswordScreen({super.key, required this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  static const Color primaryGreen = Color(0xFF1DB954);
  static const Color darkBg = Color(0xFF121212);
  static const String baseUrl = "http://localhost:8081/auth";

  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;
  bool _success = false;
  String? _error;
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    if (pass.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'Preencha todos os campos');
      return;
    }
    if (pass.length < 8) {
      setState(() => _error = 'A senha deve ter no mínimo 8 caracteres');
      return;
    }
    if (pass != confirm) {
      setState(() => _error = 'As senhas não coincidem');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      final res = await http.post(
        Uri.parse("$baseUrl/reset-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"token": widget.token, "newPassword": pass}),
      );

      if (res.statusCode == 200) {
        setState(() => _success = true);
      } else {
        final body = jsonDecode(res.body);
        final msg = body['message'] ?? '';
        if (msg.contains('expirado')) {
          setState(() => _error = 'Este link expirou. Solicite um novo.');
        } else if (msg.contains('utilizado')) {
          setState(() => _error = 'Este link já foi usado. Solicite um novo.');
        } else {
          setState(() => _error = 'Link inválido. Solicite um novo.');
        }
      }
    } catch (_) {
      setState(() => _error = 'Erro de conexão. Verifique sua internet.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  InputDecoration _deco(String hint, IconData icon,
      {bool obscure = false, VoidCallback? toggle}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: Colors.grey),
      suffixIcon: toggle != null
          ? IconButton(
              icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey),
              onPressed: toggle,
            )
          : null,
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: darkBg,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: _success ? _buildSuccess() : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Icon(Icons.lock_outline, color: primaryGreen, size: 52),
          const SizedBox(height: 20),
          const Text(
            'Nova senha',
            style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Crie uma nova senha para sua conta FinTrack.',
            style:
                TextStyle(color: Colors.white54, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 36),

          TextField(
            controller: _passCtrl,
            obscureText: _obscure1,
            style: const TextStyle(color: Colors.white),
            decoration: _deco(
              'Nova senha (mín. 8 caracteres)',
              Icons.lock_outline,
              obscure: _obscure1,
              toggle: () => setState(() => _obscure1 = !_obscure1),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _confirmCtrl,
            obscureText: _obscure2,
            style: const TextStyle(color: Colors.white),
            decoration: _deco(
              'Confirmar nova senha',
              Icons.lock_outline,
              obscure: _obscure2,
              toggle: () => setState(() => _obscure2 = !_obscure2),
            ),
          ),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_error!,
                  style: const TextStyle(color: Colors.red, fontSize: 13)),
            ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: _isLoading ? null : _reset,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Salvar nova senha',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline,
              color: primaryGreen, size: 80),
          const SizedBox(height: 24),
          const Text(
            'Senha alterada!',
            style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Sua senha foi redefinida com sucesso.\nFaça login com a nova senha.',
            textAlign: TextAlign.center,
            style:
                TextStyle(color: Colors.white54, fontSize: 14, height: 1.6),
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              ),
              child: const Text(
                'Ir para o login',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}