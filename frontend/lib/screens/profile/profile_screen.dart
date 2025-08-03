import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final String name;
  final String email;
  final String photo;

  const ProfileScreen({
    super.key,
    required this.name,
    required this.email,
    required this.photo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        backgroundColor: const Color(0xFF6C63FF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: CircleAvatar(
                backgroundImage: AssetImage(photo),
                radius: 60,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              name,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6C63FF),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              email,
              style: const TextStyle(fontSize: 18, color: Colors.black54),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 32,
                ),
              ),
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text(
                'Editar Perfil',
                style: TextStyle(fontSize: 18),
              ),
              onPressed: () {
                // TODO: Implementar edição de perfil
              },
            ),
          ],
        ),
      ),
    );
  }
}
