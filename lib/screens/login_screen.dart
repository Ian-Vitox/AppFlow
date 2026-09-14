import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../widgets/app_logo.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _rememberEmailKey = 'remember_login_email';
  final _preferences = SharedPreferencesAsync();
  bool ocultarSenha = true;
  bool lembrarSenha = false;
  bool _loading = false;
  final emailController = TextEditingController();
  final senhaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _restoreRememberedEmail();
  }

  Future<void> _restoreRememberedEmail() async {
    final email = await _preferences.getString(_rememberEmailKey);
    if (!mounted || email == null || email.isEmpty) return;
    emailController.text = email;
    setState(() => lembrarSenha = true);
  }

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = emailController.text.trim();
    final senha = senhaController.text;
    String? error;
    if (email.isEmpty) {
      error = 'Informe seu e-mail';
    } else if (!email.contains('@') || !email.contains('.')) {
      error = 'E-mail inválido';
    } else if (senha.isEmpty) {
      error = 'Informe sua senha';
    } else if (senha.length < 8) {
      error = 'A senha deve conter no mínimo 8 caracteres';
    }
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthService.instance.signIn(email: email, password: senha);
      if (lembrarSenha) {
        await _preferences.setString(_rememberEmailKey, email);
      } else {
        await _preferences.remove(_rememberEmailKey);
      }
    } on AuthException catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(exception.message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(child: AppLogo(size: 150)),
                    SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Seu tempo de estudo, sua evolução.',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF6B7280),
                        ),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: senhaController,
                      decoration: InputDecoration(
                        hintText: 'Digite sua senha',
                        prefixIcon: Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            ocultarSenha
                                ? Icons.visibility_off
                                : Icons.visibility,
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
                          backgroundColor: Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _loading ? null : _signIn,
                        child: _loading
                            ? const SizedBox.square(
                                dimension: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Entrar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Ainda não tem uma conta?'),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignupScreen(),
                            ),
                          ),
                          child: const Text('Cadastre-se'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
