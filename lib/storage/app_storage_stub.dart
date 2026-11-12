import 'storage_types.dart';

class UnsupportedAdventureStorage implements AdventureStorage {
  @override
  Future<List<AdventureMeta>> listAll() async => [];

  @override
  Future<String?> read(String id) async => null;

  @override
  Future<void> write(String id, String content) async {}

  @override
  Future<void> delete(String id) async {}
}

AdventureStorage createStorage() => UnsupportedAdventureStorage();
