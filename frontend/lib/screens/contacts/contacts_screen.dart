import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../chat/chat_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<dynamic> _all = [];
  List<dynamic> _filtered = [];
  bool _loading = true;
  String? _error;
  bool _openedChat = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = _all;
      } else {
        _filtered = _all.where((u) {
          final name = (u['name'] ?? '').toString().toLowerCase();
          final email = (u['email'] ?? '').toString().toLowerCase();
          return name.contains(q) || email.contains(q);
        }).toList();
      }
    });
  }

  Future<void> _fetchUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) {
        if (mounted) Navigator.pop(context, false);
        return;
      }
      final baseUrl = dotenv.env['API_BASE_URL'] as String;
      final resp = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;
        data.sort((a, b) {
          final na = (a['name'] ?? '').toString().toLowerCase();
          final nb = (b['name'] ?? '').toString().toLowerCase();
          return na.compareTo(nb);
        });
        setState(() {
          _all = data;
          _filtered = _all;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Erro ${resp.statusCode} ao carregar contatos';
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

  void _openChat(dynamic user) {
    final name = user['name'] ?? 'Sem nome';
    final photo = user['photoURL'] ?? 'assets/icons/icon.png';
    final id = user['id'] ?? user['_id'];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ChatScreen(contactName: name, contactPhoto: photo, contactId: id),
      ),
    ).then((_) {
      setState(() => _openedChat = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(
          context,
          _openedChat,
        ); // retorna sinal para atualizar conversas
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F3F8),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFF6C63FF),
          title: const Text('Todos os contatos'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context, _openedChat),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Color(0xFF6C63FF)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Buscar contatos...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    if (_searchCtrl.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                        },
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.black45,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(child: Text(_error!))
                  : _filtered.isEmpty
                  ? const Center(child: Text('Nenhum contato'))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final u = _filtered[index];
                        final name = u['name'] ?? 'Sem nome';
                        final photo = u['photoURL'] ?? 'assets/icons/icon.png';
                        return InkWell(
                          onTap: () => _openChat(u),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundImage:
                                      photo.toString().startsWith('http')
                                      ? NetworkImage(photo)
                                      : AssetImage(photo) as ImageProvider,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
