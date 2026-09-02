import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool ocultarSenha = true;
  bool lembrarSenha = false;
  final emailController = TextEditingController();
  final senhaController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:const Color(0xFFF8F9FC),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Color(0xFFEEEAFE),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.timer_outlined,
                  size: 50,
                  color: Color(0xFF5B3DF5),
                ),
              ),
            ),
            Center(
              child: Text(
                'StudyFlow',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5B3DF5),
                ),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: Text(
                'Seu tempo de estudo, sua evolução.',
                style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
              ),
            ),
            const SizedBox(height: 40),

            const Text(
              'Bem-vindo de volta!',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Faça login para continuar',
              style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 28),
            const Text(
              'Email',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                hintText: 'seu@email.com',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Senha',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: senhaController,
              decoration: InputDecoration(
                hintText: 'Digite sua senha',
                prefixIcon: Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    ocultarSenha ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      ocultarSenha = !ocultarSenha;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              obscureText: ocultarSenha,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Checkbox(
                  value: lembrarSenha,
                  onChanged: (value) {
                    setState(() {
                      lembrarSenha = value ?? false;
                    });
                  },
                ),
                const Text('Lembrar-me'),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: const Text('Esqueci minha senha'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF5B3DF5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  String email = emailController.text;
                  String senha = senhaController.text;
                  if (email.isEmpty || senha.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Preencha todos os campos')),
                    );
                  } else {
                    print('Login permitido');
                  }
                },
                // Ação ao pressionar o botão de login
                child: const Text(
                  'Entrar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
