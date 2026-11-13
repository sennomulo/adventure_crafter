import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/adventure.dart';
import '../storage/app_storage.dart';
import '../storage/file_transfer.dart';

class BackupService extends GetxService {
  AdventureStorage get storage => createStorage();

  Future<void> exportAdventure(Adventure adv, BuildContext context) async {
    final safe = adv.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    await saveTextFile(adv.toJsonString(),
        fileName: '$safe.json', dialogTitle: 'Export adventure'.tr);
  }

  Future<void> exportBackup(BuildContext context) async {
    final list = await storage.listAll();
    if (list.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Nothing to back up'.tr),
            duration: const Duration(seconds: 2)));
      }
      return;
    }
    final archive = Archive();
    for (final meta in list) {
      final content = await storage.read(meta.id);
      if (content == null) continue;
      final bytes = utf8.encode(content);
      archive.add(ArchiveFile.bytes('${meta.id}.json', bytes));
    }
    final now = DateTime.now();
    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final zip = ZipEncoder().encode(archive);
    await saveBytesFile(Uint8List.fromList(zip),
        fileName: 'adventure_crafter_backup_$stamp.zip',
        dialogTitle: 'Export full backup (zip)'.tr);
  }

  /// 返回导入的冒险数量；失败抛出异常由调用方提示。
  Future<int> importFromFile() async {
    final picked = await pickFileBytes(
        dialogTitle: 'Import from file (json/zip)'.tr,
        extensions: ['json', 'zip']);
    if (picked == null) return 0;
    final (name, bytes) = picked;
    if (name.toLowerCase().endsWith('.zip')) {
      return _importZip(bytes);
    }
    await _importOne(utf8.decode(bytes));
    return 1;
  }

  Future<int> _importZip(Uint8List bytes) async {
    final archive = ZipDecoder().decodeBytes(bytes);
    var count = 0;
    for (final file in archive) {
      if (!file.isFile || !file.name.toLowerCase().endsWith('.json')) continue;
      await _importOne(utf8.decode(file.content as List<int>));
      count++;
    }
    return count;
  }

  Future<void> _importOne(String text) async {
    final map = jsonDecode(text) as Map<String, dynamic>;
    if (map['id'] == null || map['title'] == null) {
      throw const FormatException('not an adventure file');
    }
    var id = map['id'] as String;
    if (await storage.read(id) != null) {
      id = 'a${DateTime.now().millisecondsSinceEpoch}_import';
    }
    map['id'] = id;
    final adv = Adventure.fromJson(map);
    await storage.write(id, adv.toJsonString());
  }
}
