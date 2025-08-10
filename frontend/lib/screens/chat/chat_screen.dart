import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../models/sticker.dart';

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
  final Set<String> _pendingSent = {};
  List<Sticker> _stickers = [];
  bool _stickersLoading = false;

  void _initSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;
    final baseUrl = dotenv.env['API_BASE_URL']
        ?.replaceFirst('http://', '')
        .replaceFirst('https://', '');
    final url = dotenv.env['API_BASE_URL']!.startsWith('https')
        ? 'https://$baseUrl'
        : 'http://$baseUrl';
    _socket = IO.io(
      url,
      IO.OptionBuilder()
          .setQuery({'token': token})
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );
    _socket!.onConnect((_) {});
    _socket!.on('message:new', (data) async {
      final prefs = await SharedPreferences.getInstance();
      final myId = prefs.getString('user_id');
      final to = data['to'];
      final from = data['from'];
      if (widget.contactId == null) return;
      if ((from == myId && to == widget.contactId) ||
          (from == widget.contactId && to == myId)) {
        final content = data['content'];
        final type = data['type'] ?? 'text';
        final pendingKey = _buildPendingKey(content, from == myId, type);
        if (from == myId && _pendingSent.contains(pendingKey)) {
          final idx = _messages.lastIndexWhere(
            (m) =>
                m['fromMe'] == true &&
                m['text'] == content &&
                m['type'] == type,
          );
          if (idx != -1) {
            _messages[idx]['time'] = data['timestamp'];
          } else {
            _messages.add({
              'fromMe': true,
              'text': content,
              'time': data['timestamp'],
              'type': type,
            });
          }
          _pendingSent.remove(pendingKey);
        } else {
          _messages.add({
            'fromMe': from == myId,
            'text': content,
            'time': data['timestamp'],
            'type': type,
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
    _loadStickers();
  }

  Future<void> _loadStickers() async {
    setState(() => _stickersLoading = true);
    try {
      _stickers = await StickerRepository.loadAll();
    } catch (e) {
      debugPrint('Erro carregando stickers: $e');
    } finally {
      if (mounted) setState(() => _stickersLoading = false);
    }
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
                'type': m['type'] ?? 'text',
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

  String _buildPendingKey(String content, bool fromMe, String type) =>
      '${fromMe ? 'me' : 'other'}-${type}-${content.hashCode}-${content.length}';

  Future<void> _sendTextMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.contactId == null) return;
    await _sendMessage(content: text, type: 'text');
  }

  Future<void> _sendStickerMessage(Sticker sticker) async {
    if (widget.contactId == null) return;
    await _sendMessage(content: sticker.id, type: 'sticker');
  }

  Future<void> _sendMessage({
    required String content,
    required String type,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final myId = prefs.getString('user_id');
      if (token == null || myId == null) return;
      final baseUrl = dotenv.env['API_BASE_URL'] as String;
      final pendingKey = _buildPendingKey(content, true, type);
      final resp = await http.post(
        Uri.parse('$baseUrl/messages'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from': myId,
          'to': widget.contactId,
          'content': content,
          'type': type,
        }),
      );
      if (resp.statusCode == 201) {
        if (type == 'text') _controller.clear();
        setState(() {
          _messages.add({
            'fromMe': true,
            'text': content,
            'time': DateTime.now().toUtc().toIso8601String(),
            'type': type,
          });
          _pendingSent.add(pendingKey);
        });
        _jumpToEnd();
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
          _scroll.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openStickerPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        if (_stickersLoading) {
          return const SizedBox(
            height: 260,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (_stickers.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'Nenhum sticker encontrado',
                style: TextStyle(fontSize: 16),
              ),
            ),
          );
        }
        return SizedBox(
          height: 340,
          child: Column(
            children: [
              const SizedBox(height: 14),
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 16, bottom: 4),
                child: Text(
                  'Stickers',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _stickers.length,
                  itemBuilder: (c, i) {
                    final s = _stickers[i];
                    return Material(
                      color: const Color(0xFFF3F4F8),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.pop(context);
                          _sendStickerMessage(s);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Image.asset(
                            s.asset,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.error_outline,
                              size: 32,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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
                        final type = m['type'] as String? ?? 'text';
                        final dateStr = m['time'] as String?;
                        DateTime date;
                        try {
                          date = DateTime.parse(
                            dateStr ?? DateTime.now().toIso8601String(),
                          );
                          date = date.toLocal();
                        } catch (_) {
                          date = DateTime.now();
                        }
                        final timeStr = DateFormat.Hm().format(date);
                        Widget contentWidget;
                        if (type == 'sticker') {
                          // tenta localizar o asset pelo id
                          final st = _stickers.firstWhere(
                            (s) => s.id == text,
                            orElse: () => Sticker(id: text, asset: ''),
                          );
                          contentWidget = st.asset.isNotEmpty
                              ? Image.asset(
                                  st.asset,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.contain,
                                )
                              : Text(
                                  '[sticker:$text]',
                                  style: TextStyle(
                                    color: fromMe
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                );
                        } else {
                          contentWidget = Text(
                            text,
                            style: TextStyle(
                              color: fromMe ? Colors.white : Colors.black87,
                              fontSize: 16,
                            ),
                          );
                        }
                        return Align(
                          alignment: fromMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: EdgeInsets.symmetric(
                              horizontal: type == 'sticker' ? 8 : 14,
                              vertical: type == 'sticker' ? 8 : 10,
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
                                contentWidget,
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
                    onPressed: _openStickerPicker,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendTextMessage(),
                      decoration: const InputDecoration(
                        hintText: 'Digite uma mensagem...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF6C63FF)),
                    onPressed: _sendTextMessage,
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
