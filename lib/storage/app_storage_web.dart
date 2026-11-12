import 'package:shared_preferences/shared_preferences.dart';

import '../data/adventure.dart';
import 'storage_types.dart';

class WebAdventureStorage implements AdventureStorage {
  static const _indexKey = 'ac_adv_index';
  static String _contentKey(String id) => 'ac_adv_$id';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<List<AdventureMeta>> listAll() async {
    final p = await _prefs;
    final result = <AdventureMeta>[];
    for (final id in p.getStringList(_indexKey) ?? <String>[]) {
      final s = p.getString(_contentKey(id));
      if (s == null) continue;
      final adv = Adventure.fromJsonString(s);
      result.add(AdventureMeta(id: id, title: adv.title, date: adv.date));
    }
    result.sort((a, b) => b.id.compareTo(a.id));
    return result;
  }

  @override
  Future<String?> read(String id) async {
    final p = await _prefs;
    return p.getString(_contentKey(id));
  }

  @override
  Future<void> write(String id, String content) async {
    final p = await _prefs;
    await p.setString(_contentKey(id), content);
    final index = p.getStringList(_indexKey) ?? <String>[];
    if (!index.contains(id)) {
      index.add(id);
      await p.setStringList(_indexKey, index);
    }
  }

  @override
  Future<void> delete(String id) async {
    final p = await _prefs;
    await p.remove(_contentKey(id));
    final index = p.getStringList(_indexKey) ?? <String>[];
    index.remove(id);
    await p.setStringList(_indexKey, index);
  }
}

AdventureStorage createStorage() => WebAdventureStorage();
