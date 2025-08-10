import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:ui';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _name;
  String? _email;
  String? _password;
  String? _phone;
  bool _loading = false;
  bool _obscurePass = true;

  void _togglePass() => setState(() => _obscurePass = !_obscurePass);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _loading = true);
    try {
      final baseUrl = dotenv.env['API_BASE_URL'] as String;
      final resp = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _name,
          'email': _email,
          'password': _password,
          'phone': _phone,
          'photoURL': '',
        }),
      );
      if (!mounted) return;
      if (resp.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Cadastro realizado!')));
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        String msg = 'Erro ao cadastrar';
        try {
          msg = jsonDecode(resp.body)['message'] ?? msg;
        } catch (_) {}
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Falha de rede: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _dec(String label, {IconData? icon, Widget? suffix}) =>
      InputDecoration(
        labelText: label,
        prefixIcon: icon != null
            ? Icon(icon, color: const Color(0xFF6C63FF))
            : null,
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withOpacity(0.94),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF6C63FF),
                  Color(0xFF5146D9),
                  Color(0xFF4036B5),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/login'),
                tooltip: 'Voltar',
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 40,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.person_add_alt_1,
                          size: 44,
                          color: Colors.white,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Criar conta',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.fromLTRB(24, 30, 24, 34),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(34),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.18),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 22,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Preencha seus dados',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 26),
                                TextFormField(
                                  decoration: _dec(
                                    'Nome',
                                    icon: Icons.person_outline,
                                  ),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                      ? 'Informe o nome'
                                      : null,
                                  onSaved: (v) => _name = v?.trim(),
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 18),
                                TextFormField(
                                  decoration: _dec(
                                    'Email',
                                    icon: Icons.email_outlined,
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                      ? 'Informe o email'
                                      : null,
                                  onSaved: (v) => _email = v?.trim(),
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 18),
                                TextFormField(
                                  decoration: _dec(
                                    'Senha',
                                    icon: Icons.lock_outline,
                                    suffix: IconButton(
                                      icon: Icon(
                                        _obscurePass
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: const Color(0xFF6C63FF),
                                      ),
                                      onPressed: _togglePass,
                                    ),
                                  ),
                                  obscureText: _obscurePass,
                                  validator: (v) => v == null || v.length < 6
                                      ? 'Mínimo 6 caracteres'
                                      : null,
                                  onSaved: (v) => _password = v,
                                  textInputAction: TextInputAction.next,
                                ),
                                const SizedBox(height: 18),
                                TextFormField(
                                  decoration: _dec(
                                    'Telefone',
                                    icon: Icons.phone_outlined,
                                  ),
                                  keyboardType: TextInputType.phone,
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                      ? 'Informe o telefone'
                                      : null,
                                  onSaved: (v) => _phone = v?.trim(),
                                  textInputAction: TextInputAction.done,
                                ),
                                const SizedBox(height: 26),
                                SizedBox(
                                  height: 54,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFF6C63FF),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                    onPressed: _loading ? null : _submit,
                                    child: AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      child: _loading
                                          ? const SizedBox(
                                              key: ValueKey('ld'),
                                              width: 26,
                                              height: 26,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 3,
                                                valueColor:
                                                    AlwaysStoppedAnimation(
                                                      Color(0xFF6C63FF),
                                                    ),
                                              ),
                                            )
                                          : const Text(
                                              'Cadastrar',
                                              key: ValueKey('tx'),
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Já tem conta?',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    TextButton(
                                      onPressed: _loading
                                          ? null
                                          : () =>
                                                Navigator.pushReplacementNamed(
                                                  context,
                                                  '/login',
                                                ),
                                      child: const Text(
                                        'Entrar',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.05),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
