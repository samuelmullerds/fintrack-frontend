import 'package:flutter/material.dart';

import 'login_screen.dart';
void main() {
  runApp(const FinTrackApp());
}


class FinTrackApp extends StatelessWidget {
  const FinTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF1DB954);
    const Color darkBackground = Color(0xFF121212);

    return Scaffold(
      backgroundColor: darkBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            children: [
              
              const SizedBox(height: 40),
              Image.asset(
                "assets/images/logo.png",
                width: 500, 
                fit: BoxFit.contain,
              ),


              const Spacer(flex: 2), 

              const Text(
                'Seja Bem Vindo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primaryGreen,
                  fontSize: 40, 
                  fontWeight: FontWeight.bold,
                ),
              ),


              const Spacer(flex: 3), 

              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    elevation: 12,
                    shadowColor: primaryGreen.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Entrar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

   
              Column(
                children: [
                  const Text(
                    'Não possui conta?',
                    style: TextStyle(
                      color: primaryGreen,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 5),
                  GestureDetector(
                    onTap: () {},
                    child: const Text(
                      'Cadastre-se',
                      style: TextStyle(
                        color: primaryGreen,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        decorationThickness: 2,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40), // Respiro final
            ],
          ),
        ),
      ),
    );
  }
} 