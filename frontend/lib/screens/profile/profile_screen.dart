import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? name;
  String? email;
  String? photo;
  String? phone;
  String? bio; // nova bio
  bool _loading = true;
  String? _error;
  late final String _apiBaseUrl = dotenv.env['API_BASE_URL'] as String;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userId = prefs.getString('user_id');
      // Carrega cache inicial
      setState(() {
        name = prefs.getString('user_name');
        email = prefs.getString('user_email');
        photo = prefs.getString('user_photo') ?? 'assets/icons/icon.png';
        phone = prefs.getString('user_phone');
      });
      if (token != null && userId != null) {
        final resp = await http.get(
          Uri.parse('$_apiBaseUrl/users/$userId'),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          setState(() {
            name = data['name'] ?? name;
            email = data['email'] ?? email;
            photo = data['photoURL'] ?? photo;
            phone = data['phone'] ?? phone;
            bio = data['bio'] ?? bio; // carregar bio
            _loading = false;
          });
        } else {
          setState(() {
            _loading = false;
            _error = 'Falha ao carregar perfil';
          });
        }
      } else {
        setState(() {
          _loading = false;
          _error = 'Usuário não autenticado';
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Erro: $e';
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_photo');
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  Future<void> _openEditModal() async {
    final nameController = TextEditingController(text: name ?? '');
    final emailController = TextEditingController(text: email ?? '');
    final phoneController = TextEditingController(text: phone ?? '');
    final photoUrlController = TextEditingController(
      text: (photo != null && photo!.startsWith('http')) ? photo : '',
    );
    String tempPreview = photoUrlController.text.trim();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            void updatePreview(String value) {
              String v = value.trim();
              if (v.isNotEmpty && !v.startsWith('http')) {
                // heurística simples: prefixar https
                v = 'https://$v';
              }
              setModalState(() => tempPreview = v);
            }

            bool isValidUrl(String u) {
              if (u.isEmpty) return false;
              final uri = Uri.tryParse(u);
              return uri != null &&
                  (uri.isScheme('http') || uri.isScheme('https'));
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const Text(
                      'Editar Perfil',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF6C63FF),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.grey.shade200,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: isValidUrl(tempPreview)
                              ? FadeInImage.assetNetwork(
                                  placeholder: 'assets/icons/icon.png',
                                  image: tempPreview,
                                  fit: BoxFit.cover,
                                  imageErrorBuilder: (_, __, ___) =>
                                      const Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.image_outlined,
                                    size: 40,
                                    color: Colors.black38,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              TextField(
                                controller: nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Nome',
                                ),
                                textInputAction: TextInputAction.next,
                              ),
                              TextField(
                                controller: emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                ),
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                              ),
                              TextField(
                                controller: phoneController,
                                decoration: const InputDecoration(
                                  labelText: 'Telefone',
                                ),
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: photoUrlController,
                      decoration: InputDecoration(
                        labelText: 'URL da Foto (https://...)',
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.refresh,
                            color: Color(0xFF6C63FF),
                          ),
                          onPressed: () =>
                              updatePreview(photoUrlController.text),
                          tooltip: 'Atualizar preview',
                        ),
                      ),
                      keyboardType: TextInputType.url,
                      onChanged: updatePreview,
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C63FF),
                            ),
                            onPressed: () async {
                              await _saveProfile(
                                newName: nameController.text.trim(),
                                newEmail: emailController.text.trim(),
                                newPhone: phoneController.text.trim(),
                                newPhotoUrl:
                                    isValidUrl(photoUrlController.text.trim())
                                    ? photoUrlController.text.trim()
                                    : null,
                              );
                              if (!mounted) return;
                              Navigator.of(ctx).pop();
                            },
                            child: const Text('Salvar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveProfile({
    String? newName,
    String? newEmail,
    String? newPhone,
    String? newPhotoUrl,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userId = prefs.getString('user_id');
      if (token == null || userId == null) return;

      final updateResp = await http.put(
        Uri.parse('$_apiBaseUrl/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          if (newName != null && newName.isNotEmpty) 'name': newName,
          if (newEmail != null && newEmail.isNotEmpty) 'email': newEmail,
          if (newPhone != null && newPhone.isNotEmpty) 'phone': newPhone,
          if (newPhotoUrl != null && newPhotoUrl.isNotEmpty)
            'photoURL': newPhotoUrl,
        }),
      );
      if (updateResp.statusCode == 200) {
        final updated = jsonDecode(updateResp.body);
        setState(() {
          name = updated['name'] ?? name;
          email = updated['email'] ?? email;
          phone = updated['phone'] ?? phone;
          if (newPhotoUrl != null && newPhotoUrl.isNotEmpty)
            photo = newPhotoUrl;
        });
        await prefs.setString('user_name', name ?? '');
        await prefs.setString('user_email', email ?? '');
        await prefs.setString('user_phone', phone ?? '');
        if (photo != null) await prefs.setString('user_photo', photo!);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Perfil atualizado')));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha ao atualizar (${updateResp.statusCode})'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Future<void> _openBioModal() async {
    final bioController = TextEditingController(text: bio ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 18,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const Text(
                  'Editar Bio',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: bioController,
                  maxLines: 5,
                  minLines: 3,
                  maxLength: 280,
                  decoration: InputDecoration(
                    labelText: 'Sua bio',
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C63FF),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          await _saveBio(bioController.text.trim());
                          if (!mounted) return;
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('Salvar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveBio(String newBio) async {
    if (newBio.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bio não pode ser vazia.')));
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userId = prefs.getString('user_id');
      if (token == null || userId == null) return;
      final resp = await http.put(
        Uri.parse('$_apiBaseUrl/users/$userId/bio'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'bio': newBio}),
      );
      if (resp.statusCode == 200) {
        setState(() => bio = newBio);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Bio atualizada.')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha ao atualizar bio (${resp.statusCode}).'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  Widget _buildHeader(double width) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: width,
          height: 200,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF5146D9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                    ),
                    tooltip: 'Voltar',
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context).pushReplacementNamed('/home');
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: _logout,
                    tooltip: 'Sair',
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -60,
          left: 0,
          right: 0,
          child: Center(
            child: Hero(
              tag: 'profile_photo',
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 56,
                  backgroundImage: (photo != null && photo!.startsWith('http'))
                      ? NetworkImage(photo!)
                      : AssetImage(photo ?? 'assets/icons/icon.png')
                            as ImageProvider,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardContent() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadProfile,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        const SizedBox(height: 70),
        Text(
          name ?? 'Usuário',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF222222),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          email ?? '',
          style: const TextStyle(fontSize: 15, color: Colors.black54),
        ),
        if (phone != null && phone!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            phone!,
            style: const TextStyle(fontSize: 14, color: Colors.black45),
          ),
        ],
        const SizedBox(height: 24),
        // Métricas fictícias (placeholder)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatItem(label: 'Contatos', value: '—'),
            _StatItem(label: 'Msgs', value: '—'),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Sobre',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6C63FF),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.edit,
                      size: 20,
                      color: Color(0xFF6C63FF),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Editar bio',
                    onPressed: _openBioModal,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                (bio != null && bio!.isNotEmpty)
                    ? bio!
                    : 'Adicione uma bio para personalizar seu perfil.',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  _openEditModal();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Editar',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton(
                onPressed: _logout,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFF6C63FF), width: 1.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Sair',
                  style: TextStyle(fontSize: 16, color: Color(0xFF6C63FF)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F8),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(width),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.only(top: 70),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: _buildCardContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF222222),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black45),
        ),
      ],
    );
  }
}
