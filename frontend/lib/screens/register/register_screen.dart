import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro'),
        backgroundColor: const Color(0xFF6C63FF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Icon(
                Icons.account_circle,
                size: 80,
                color: Color(0xFF6C63FF),
              ),
              const SizedBox(height: 24),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Digite seu nome' : null,
                onSaved: (value) => _name = value,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Digite seu email' : null,
                onSaved: (value) => _email = value,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Senha'),
                obscureText: true,
                validator: (value) => value == null || value.length < 6
                    ? 'Senha mínima de 6 caracteres'
                    : null,
                onSaved: (value) => _password = value,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    // Apenas validação local, sem integração
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cadastro realizado (simulado)!'),
                      ),
                    );
                  }
                },
                child: const Text('Cadastrar', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text(
                  'Já tenho conta',
                  style: TextStyle(color: Color(0xFF6C63FF), fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/home');
                },
                child: const Text(
                  'Pular',
                  style: TextStyle(
                    color: Color.fromARGB(255, 6, 5, 32),
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
