import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatScreen extends StatefulWidget {
  final String contactName;
  final String contactPhoto;
  final String? contactId;

  const ChatScreen({
    super.key,
    required this.contactName,
    required this.contactPhoto,
    this.contactId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  String? _error;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  IO.Socket? _socket;
  // Guarda conteúdos (com hash) de mensagens enviadas localmente para evitar duplicar quando o socket ecoar
  final Set<String> _pendingSent = {};

  void _initSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;
    final baseUrl = dotenv.env['API_BASE_URL']
        ?.replaceFirst('http://', '')
        .replaceFirst('https://', '');
    final url = dotenv.env['API_BASE_URL']!.startsWith('https')
        ? 'https://${baseUrl}'
        : 'http://${baseUrl}';
    _socket = IO.io(
      url,
      IO.OptionBuilder()
          .setQuery({'token': token})
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );
    _socket!.onConnect((_) {
      // conectado
    });
    _socket!.on('message:new', (data) async {
      final prefs = await SharedPreferences.getInstance();
      final myId = prefs.getString('user_id');
      final to = data['to'];
      final from = data['from'];
      if (widget.contactId == null) return;
      // Apenas mensagens entre mim e o contato atual
      if ((from == myId && to == widget.contactId) ||
          (from == widget.contactId && to == myId)) {
        final content = data['content'];
        final pendingKey = _buildPendingKey(content, from == myId);
        if (from == myId && _pendingSent.contains(pendingKey)) {
          // Atualiza horário da mensagem optimista em vez de duplicar
          final idx = _messages.lastIndexWhere(
            (m) => m['fromMe'] == true && m['text'] == content,
          );
          if (idx != -1) {
            _messages[idx]['time'] = data['timestamp'];
          } else {
            _messages.add({
              'fromMe': true,
              'text': content,
              'time': data['timestamp'],
            });
          }
          _pendingSent.remove(pendingKey);
        } else {
          _messages.add({
            'fromMe': from == myId,
            'text': content,
            'time': data['timestamp'],
          });
        }
        setState(() {});
        _jumpToEnd();
      }
    });
    _socket!.connect();
  }

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _initSocket();
  }

  Future<void> _loadHistory() async {
    if (widget.contactId == null) {
      setState(() {
        _loading = false;
      });
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        setState(() {
          _error = 'Não autenticado';
          _loading = false;
        });
        return;
      }
      final baseUrl = dotenv.env['API_BASE_URL'] as String;
      final resp = await http.get(
        Uri.parse('$baseUrl/chats/${widget.contactId}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;
        final prefsId = prefs.getString('user_id');
        setState(() {
          _messages.clear();
          _messages.addAll(
            data.map(
              (m) => {
                'fromMe': m['from'] == prefsId,
                'text': m['content'],
                'time': m['timestamp'],
              },
            ),
          );
          _loading = false;
        });
        _jumpToEnd();
      } else {
        setState(() {
          _error = 'Erro ao carregar histórico';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Falha: $e';
        _loading = false;
      });
    }
  }

  String _buildPendingKey(String content, bool fromMe) =>
      '${fromMe ? 'me' : 'other'}-${content.hashCode}-${content.length}';

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.contactId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final myId = prefs.getString('user_id');
      if (token == null || myId == null) return;
      final baseUrl = dotenv.env['API_BASE_URL'] as String;
      final pendingKey = _buildPendingKey(text, true);
      final resp = await http.post(
        Uri.parse('$baseUrl/messages'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from': myId,
          'to': widget.contactId,
          'content': text,
          'type': 'text',
        }),
      );
      if (resp.statusCode == 201) {
        _controller.clear();
        setState(() {
          _messages.add({
            'fromMe': true,
            'text': text,
            'time': DateTime.now().toUtc().toIso8601String(),
          });
          _pendingSent.add(pendingKey);
        });
        _jumpToEnd();
        // Emissão opcional se backend exigir socket separado; comentar se duplicar
        //_socket?.emit('message:send', {
        //  'to': widget.contactId,
        //  'content': text,
        //  'type': 'text',
        //});
      } else {
        debugPrint('Erro enviar mensagem: ${resp.statusCode} ${resp.body}');
      }
    } catch (e) {
      debugPrint('Exceção enviar mensagem: $e');
    }
  }

  void _jumpToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _socket?.dispose();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C63FF),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.contactPhoto.startsWith('http')
                  ? NetworkImage(widget.contactPhoto)
                  : AssetImage(widget.contactPhoto) as ImageProvider,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.contactName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Container(
        color: const Color(0xFFF5F6FA),
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(child: Text(_error!))
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final m = _messages[index];
                        final fromMe = m['fromMe'] as bool;
                        final text = m['text'] as String;
                        final dateStr = m['time'] as String?;
                        DateTime date;
                        try {
                          date = DateTime.parse(
                            dateStr ?? DateTime.now().toIso8601String(),
                          );
                          if (!date.isUtc)
                            date = date.toLocal();
                          else
                            date = date.toLocal();
                        } catch (_) {
                          date = DateTime.now();
                        }
                        final timeStr = DateFormat.Hm().format(date);
                        return Align(
                          alignment: fromMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            constraints: const BoxConstraints(maxWidth: 280),
                            decoration: BoxDecoration(
                              color: fromMe
                                  ? const Color(0xFF6C63FF)
                                  : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(fromMe ? 16 : 4),
                                bottomRight: Radius.circular(fromMe ? 4 : 16),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: fromMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  text,
                                  style: TextStyle(
                                    color: fromMe
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  timeStr,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: fromMe
                                        ? Colors.white70
                                        : Colors.black45,
                                  ),
                                ),
                              ],
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
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        hintText: 'Digite uma mensagem...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF6C63FF)),
                    onPressed: _sendMessage,
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
