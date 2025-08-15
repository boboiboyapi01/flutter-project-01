import 'package:flutter/material.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(9, 52, 67, 1),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // const Icon(Icons.face_retouching_natural,
              //     size: 80, color: Colors.blue),
              // const SizedBox(height: 20),
              Text(
                "Welcome to EduPresence",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Bahnschrift',
                  color: Color.fromRGBO(21, 218, 218, 1),
                ),
              ),
              const SizedBox(height: 30),

              // Email field
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 15),

              // Password field
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 25),

              // Login button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Proses login
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    "Login",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Navigate to register page
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Belum punya akun?"),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const RegisterPage()),
                      );
                    },
                    child: const Text("Daftar"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
