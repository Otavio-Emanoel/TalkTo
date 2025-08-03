import 'package:flutter/material.dart';
import '../chat/chat_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lista simulada de contatos
    final contacts = [
      {
        'name': 'Matuê',
        'photo': 'assets/icons/icon.png',
        'lastMessage': 'Oi! Tudo bem?',
        'time': '10:30',
      },
      {
        'name': 'Ryu the Runner',
        'photo': 'assets/icons/icon.png',
        'lastMessage': 'Vamos conversar depois?',
        'time': '09:15',
      },
      {
        'name': 'Jotapê',
        'photo': 'assets/icons/icon.png',
        'lastMessage': 'Enviou uma figurinha',
        'time': 'Ontem',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('TalkTo'),
        backgroundColor: const Color(0xFF6C63FF),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFF5F6FA),
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: contacts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final contact = contacts[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: AssetImage(contact['photo']!),
                  radius: 28,
                ),
                title: Text(
                  contact['name']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                subtitle: Text(
                  contact['lastMessage']!,
                  style: const TextStyle(fontSize: 15),
                ),
                trailing: Text(
                  contact['time']!,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        contactName: contact['name']!,
                        contactPhoto: contact['photo']!,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6C63FF),
        child: const Icon(Icons.chat, color: Colors.white),
        onPressed: () {
          // TODO: Nova conversa
        },
      ),
    );
  }
}
