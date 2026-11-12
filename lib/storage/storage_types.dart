class AdventureMeta {
  final String id;
  final String title;
  final String date;

  AdventureMeta({required this.id, required this.title, required this.date});
}

abstract class AdventureStorage {
  Future<List<AdventureMeta>> listAll();
  Future<String?> read(String id);
  Future<void> write(String id, String content);
  Future<void> delete(String id);
}
