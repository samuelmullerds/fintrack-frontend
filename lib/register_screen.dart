import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  static const Color primaryGreen = Color(0xFF1DB954);
  static const Color darkBg = Color(0xFF121212);
  static const Color fieldBg = Color(0xFF1E1E1E);

  InputDecoration _fieldDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: Colors.grey, size: 20),
      filled: true,
      fillColor: fieldBg,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
    );
  }

  Future<void> _register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirm = confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      setState(() => errorMessage = "Preencha todos os campos");
      return;
    }

    if (password != confirm) {
      setState(() => errorMessage = "As senhas não coincidem");
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final authService = AuthService();
      final result = await authService.register(name, email, password);

      if (result != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', result['token']);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        setState(() => errorMessage = "Erro ao criar conta. Tente novamente.");
      }
    } catch (e) {
      setState(() => errorMessage = "Erro no servidor. Tente novamente.");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Logo
              Image.asset(
                "assets/images/logo.png",
                width: 200,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 32),

              // Título
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Crie sua conta FinTrack",
                  style: TextStyle(
                    color: primaryGreen,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Nome
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _fieldDecoration("Digite seu nome completo", Icons.person_outline),
              ),

              const SizedBox(height: 16),

              // Email
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: _fieldDecoration("Digite seu email", Icons.email_outlined),
              ),

              const SizedBox(height: 16),

              // Senha
              TextField(
                controller: passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: _fieldDecoration("Digite sua senha", Icons.lock_outline),
              ),

              const SizedBox(height: 16),

              // Confirmar senha
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: _fieldDecoration("Confirme sua senha", Icons.lock_outline),
              ),

              const SizedBox(height: 32),

              // Botão
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: isLoading ? null : _register,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Entrar",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              // Erro
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),

              const SizedBox(height: 24),

              // Link voltar ao login
              const Text(
                "Já possui conta?",
                style: TextStyle(color: primaryGreen, fontSize: 16),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: const Text(
                  "Entrar",
                  style: TextStyle(
                    color: primaryGreen,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}