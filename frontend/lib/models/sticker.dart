import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class Sticker {
  final String id; // identificador único
  final String asset; // caminho do asset
  const Sticker({required this.id, required this.asset});

  Map<String, dynamic> toJson() => {'id': id, 'asset': asset};
  factory Sticker.fromJson(Map<String, dynamic> json) =>
      Sticker(id: json['id'] as String, asset: json['asset'] as String);
}

class StickerRepository {
  static List<Sticker>? _cache;

  // Lista fixa opcional (caso queira controlar ordem manual)
  static const List<String> predefinedOrder = [
    // adicione nomes de arquivos (sem extensão) aqui se quiser priorizar
    // 'smile','heart','wow'
  ];

  /// Carrega dinamicamente todos os assets dentro de assets/stickers/
  /// usando o AssetManifest (não precisa manter lista manual).
  static Future<List<Sticker>> loadAll() async {
    if (_cache != null) return _cache!;
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = jsonDecode(manifestContent);
    final stickerPaths =
        manifestMap.keys
            .where(
              (k) =>
                  k.startsWith('assets/stickers/') &&
                  (k.endsWith('.png') ||
                      k.endsWith('.webp') ||
                      k.endsWith('.gif')),
            )
            .toList()
          ..sort();

    final stickers = stickerPaths.map((path) {
      // gera id a partir do nome do arquivo sem extensão
      final fileName = path.split('/').last;
      final id = fileName.split('.').first; // antes do .png/.webp
      return Sticker(id: id, asset: path);
    }).toList();

    // Reordenar se houver predefinedOrder
    if (predefinedOrder.isNotEmpty) {
      stickers.sort((a, b) {
        final ia = predefinedOrder.indexOf(a.id);
        final ib = predefinedOrder.indexOf(b.id);
        if (ia == -1 && ib == -1) return a.id.compareTo(b.id);
        if (ia == -1) return 1;
        if (ib == -1) return -1;
        return ia.compareTo(ib);
      });
    }

    _cache = stickers;
    return stickers;
  }

  static Sticker? findById(String id) {
    final list = _cache;
    if (list == null) return null;
    try {
      return list.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<Sticker?> loadAndFind(String id) async {
    final list = await loadAll();
    try {
      return list.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  static void clearCache() {
    _cache = null;
  }
}
