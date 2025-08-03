import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  final String contactName;
  final String contactPhoto;

  const ChatScreen({
    super.key,
    required this.contactName,
    required this.contactPhoto,
  });

  @override
  Widget build(BuildContext context) {
    // Mensagens simuladas
    final messages = [
      {'fromMe': false, 'text': 'Oi! Tudo bem?', 'time': '10:30'},
      {'fromMe': true, 'text': 'Tudo sim! E você?', 'time': '10:31'},
      {'fromMe': false, 'text': 'Enviou uma figurinha', 'time': '10:32'},
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C63FF),
        title: Row(
          children: [
            CircleAvatar(backgroundImage: AssetImage(contactPhoto), radius: 18),
            const SizedBox(width: 12),
            Text(contactName),
          ],
        ),
      ),
      body: Container(
        color: const Color(0xFFF5F6FA),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  return Align(
                    alignment: (msg['fromMe'] as bool)
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 18,
                      ),
                      decoration: BoxDecoration(
                        color: (msg['fromMe'] as bool)
                            ? const Color(0xFF6C63FF)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        msg['text'] as String,
                        style: TextStyle(
                          color: (msg['fromMe'] as bool)
                              ? Colors.white
                              : Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.emoji_emotions,
                      color: Color(0xFF6C63FF),
                    ),
                    onPressed: () {
                      // TODO: Selecionar figurinha
                    },
                  ),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Digite uma mensagem...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF6C63FF)),
                    onPressed: () {
                      // TODO: Enviar mensagem
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
