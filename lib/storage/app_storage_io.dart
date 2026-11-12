import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../data/adventure.dart';
import 'storage_types.dart';

class IoAdventureStorage implements AdventureStorage {
  Future<Directory> _dir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}${Platform.pathSeparator}adventures');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  File _file(Directory dir, String id) =>
      File('${dir.path}${Platform.pathSeparator}$id.json');

  @override
  Future<List<AdventureMeta>> listAll() async {
    final dir = await _dir();
    final result = <AdventureMeta>[];
    for (final entity in dir.listSync()) {
      if (entity is File && entity.path.endsWith('.json')) {
        try {
          final adv = Adventure.fromJsonString(await entity.readAsString());
          result.add(AdventureMeta(id: adv.id, title: adv.title, date: adv.date));
        } catch (_) {}
      }
    }
    result.sort((a, b) => b.id.compareTo(a.id));
    return result;
  }

  @override
  Future<String?> read(String id) async {
    final dir = await _dir();
    final f = _file(dir, id);
    if (!f.existsSync()) return null;
    return f.readAsString();
  }

  @override
  Future<void> write(String id, String content) async {
    final dir = await _dir();
    await _file(dir, id).writeAsString(content, flush: true);
  }

  @override
  Future<void> delete(String id) async {
    final dir = await _dir();
    final f = _file(dir, id);
    if (f.existsSync()) f.deleteSync();
  }
}

AdventureStorage createStorage() => IoAdventureStorage();
