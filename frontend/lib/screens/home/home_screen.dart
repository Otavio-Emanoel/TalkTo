import 'package:flutter/material.dart';
import '../chat/chat_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _users = []; // agora representa conversas exibidas
  List<dynamic> _allUsers = []; // cache completo das conversas
  bool _loading = true;
  String? _error;
  final TextEditingController _searchCtrl = TextEditingController();
  bool _searching = false;
  String? _myId; // id do usuário logado para marcar mensagens

  @override
  void initState() {
    super.initState();
    _fetchConversations();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() {
        _users = _allUsers;
        _searching = false;
      });
    } else {
      setState(() {
        _searching = true;
        _users = _allUsers.where((u) {
          final name = (u['name'] ?? '').toString().toLowerCase();
          final lastMsg = (u['lastMessage'] ?? '').toString().toLowerCase();
          return name.contains(q) || lastMsg.contains(q);
        }).toList();
      });
    }
  }

  Future<void> _fetchConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userId = prefs.getString('user_id');
      _myId = userId;
      if (token == null) {
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      final baseUrl = dotenv.env['API_BASE_URL'] as String;
      final resp = await http.get(
        Uri.parse('$baseUrl/conversations'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as List;
        // Garantir ordenação por lastMessageAt desc (caso backend já faça, mantém)
        data.sort((a, b) {
          final da =
              DateTime.tryParse(a['lastMessageAt'] ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final db =
              DateTime.tryParse(b['lastMessageAt'] ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return db.compareTo(da);
        });
        setState(() {
          _allUsers = data;
          _users = _allUsers;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Erro ao carregar conversas';
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

  void _openChat(dynamic conv) {
    final name = conv['name'] ?? 'Sem nome';
    final photo = conv['photoURL'] ?? 'assets/icons/icon.png';
    final contactId = conv['contactId'] ?? conv['id'] ?? conv['_id'];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          contactName: name,
          contactPhoto: photo,
          contactId: contactId,
        ),
      ),
    ).then((_) => _fetchConversations()); // atualiza lista ao voltar
  }

  Widget _buildHeader() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 170,
      backgroundColor: const Color(0xFF6C63FF),
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF5146D9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'TalkTo',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.account_circle,
                          color: Colors.white,
                          size: 30,
                        ),
                        onPressed: () => Navigator.pushNamed(
                          context,
                          '/profile',
                        ).then((_) => _fetchConversations()),
                        tooltip: 'Perfil',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.white70),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            style: const TextStyle(color: Colors.white),
                            cursorColor: Colors.white70,
                            decoration: const InputDecoration(
                              hintText: 'Buscar contatos...',
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: Colors.white60),
                            ),
                          ),
                        ),
                        if (_searching)
                          GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                            },
                            child: const Icon(
                              Icons.close,
                              color: Colors.white70,
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _fetchConversations,
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_users.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_outline, size: 56, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'Sem contatos disponíveis',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final conv = _users[index];
          final name = conv['name'] ?? 'Sem nome';
          final photo = conv['photoURL'] ?? 'assets/icons/icon.png';
          final lastMsg = conv['lastMessage'] ?? '';
          final lastAtRaw = conv['lastMessageAt'];
          DateTime? lastAt = DateTime.tryParse(lastAtRaw ?? '');
          String timeLabel = '';
          if (lastAt != null) {
            final now = DateTime.now();
            final isToday =
                lastAt.year == now.year &&
                lastAt.month == now.month &&
                lastAt.day == now.day;
            timeLabel = isToday
                ? '${lastAt.hour.toString().padLeft(2, '0')}:${lastAt.minute.toString().padLeft(2, '0')}'
                : '${lastAt.day.toString().padLeft(2, '0')}/${lastAt.month.toString().padLeft(2, '0')}';
          }
          final fromMe = conv['lastMessageFrom'] == _myId;
          final preview = lastMsg.isEmpty
              ? 'Sem mensagens ainda'
              : (fromMe ? 'Você: ' : '') + lastMsg.toString();
          return InkWell(
            onTap: () => _openChat(conv),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    radius: 28,
                    backgroundImage: photo.toString().startsWith('http')
                        ? NetworkImage(photo)
                        : AssetImage(photo) as ImageProvider,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF202020),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: lastMsg.isEmpty
                                ? Colors.black38
                                : Colors.black54,
                            fontStyle: lastMsg.isEmpty
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        timeLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Placeholder para badge não lidas futuramente
                      Container(
                        height: 8,
                        width: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }, childCount: _users.length),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F8),
      body: RefreshIndicator(
        onRefresh: _fetchConversations,
        edgeOffset: 0,
        child: CustomScrollView(slivers: [_buildHeader(), _buildBody()]),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6C63FF),
        onPressed: () async {
          final opened = await Navigator.pushNamed(context, '/contacts');
          if (opened == true) {
            _fetchConversations();
          }
        },
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }
}
