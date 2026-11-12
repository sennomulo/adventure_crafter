import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/adventure.dart';
import '../../data/rules.dart';
import '../../helpers/utils.dart';
import '../../services/adventure_service.dart';
import '../../services/settings_service.dart';
import '../widgets/common.dart';

class PagedListController extends GetxController {
  final bool isPlotline;
  PagedListController({required this.isPlotline});

  RulesService get rules => Get.find<RulesService>();
  AdventureService get service => Get.find<AdventureService>();
  GlobalSettingsService get settings => Get.find<GlobalSettingsService>();
  Adventure get adv => service.current.value!;
  PagedList get list => isPlotline ? adv.plotlines : adv.characters;

  final page = 0.obs;

  void changed() {
    service.save();
    update();
  }

  void addEntry(String name, String notes,
      {String? trait, List<String>? identities, List<String>? descriptors}) {
    final id = list.nextEntryId();
    list.entries.add(ListEntry(
      id: id,
      name: name,
      notes: notes,
      trait: trait,
      identities: identities,
      descriptors: descriptors,
    ));
    list.assignNextEmpty(id);
    changed();
  }

  void editEntry(int entryId, String name, String notes,
      {String? trait, List<String>? identities, List<String>? descriptors}) {
    for (final e in list.entries) {
      if (e.id == entryId) {
        e.name = name;
        e.notes = notes;
        if (!isPlotline) {
          e.trait = trait;
          e.identities = identities ?? [];
          e.descriptors = descriptors ?? [];
        }
        break;
      }
    }
    changed();
  }

  bool incWeight(int entryId) {
    if (list.weightOf(entryId) >= settings.maxWeight) return false;
    list.assignNextEmpty(entryId);
    changed();
    return true;
  }

  bool decWeight(int entryId) {
    if (list.weightOf(entryId) <= 0) return false;
    list.unassignLast(entryId);
    changed();
    return true;
  }

  void deleteEntry(int entryId) {
    list.removeEntryRefs(entryId);
    if (page.value >= list.pages.length) page.value = list.pages.length - 1;
    changed();
  }

  ({int pageIdx, int rowIdx})? rollRow() {
    if (list.pages.isEmpty) return null;
    int pageIdx = 0;
    int? pageDie;
    if (list.pages.length > 1) {
      pageDie = rollDie(list.pages.length);
      pageIdx = pageDie - 1;
    }
    final roll = roll100();
    final rowIdx = rowForRoll(roll);
    final entry = list.entryById(list.pages[pageIdx][rowIdx]);
    final label = isPlotline ? '情节线列表掷骰' : '角色列表掷骰';
    final detail = [
      if (pageDie != null) '1d${list.pages.length}=$pageDie（第${pageIdx + 1}页）',
      '1d100=$roll → 第${rowIdx + 1}行（${rowIdx * 4 + 1}~${rowIdx * 4 + 4}）',
      entry != null ? '→ ${entry.name}' : '→ 空行',
    ].join('，');
    service.logRoll(label, detail);
    return (pageIdx: pageIdx, rowIdx: rowIdx);
  }
}

class PagedListPage extends StatelessWidget {
  final bool isPlotline;
  const PagedListPage({super.key, required this.isPlotline});

  @override
  Widget build(BuildContext context) {
    final tag = isPlotline ? 'plotlines' : 'characters';
    final rules = Get.find<RulesService>();
    return GetBuilder<PagedListController>(
      tag: tag,
      builder: (c) => Obx(() {
        final list = c.list;
        final pageIndex = c.page.value.clamp(0, list.pages.length - 1);
        final defaults =
            isPlotline ? rules.plotlineRowDefaults : rules.characterRowDefaults;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Text(isPlotline ? '情节线列表' : '角色列表',
                      style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(isPlotline ? '新情节线' : '新角色'),
                    onPressed: () async {
                      final result = await _entryDialog(context, c, null);
                      if (result == null) return;
                      c.addEntry(result.$1, result.$2,
                          trait: result.$3,
                          identities: result.$4,
                          descriptors: result.$5);
                    },
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    icon: const Icon(Icons.casino),
                    label: const Text('掷骰'),
                    onPressed: () {
                      final r = c.rollRow();
                      if (r == null) return;
                      final entry = c.list.entryById(
                          c.list.pages[r.pageIdx][r.rowIdx]);
                      final hint = defaults[r.rowIdx];
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('掷骰结果：第${r.pageIdx + 1}页 第${r.rowIdx + 1}行'),
                          content: Text(entry != null
                              ? '${entry.name}${c.list.weightOf(entry.id) > 1 ? '（当前权重 x${c.list.weightOf(entry.id)}）' : ''}\n\n如需提升权重，请手动对该条目 +1。'
                              : '空行 → 默认提示：$hint'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('关闭'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 6,
                children: [
                  for (var p = 0; p < list.pages.length; p++)
                    ChoiceChip(
                      label: Text('第${p + 1}页 (${p * 25 + 1}-${p * 25 + 25})'),
                      selected: p == pageIndex,
                      onSelected: (_) => c.page.value = p,
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 25,
                itemBuilder: (context, r) {
                  final entryId = list.pages[pageIndex][r];
                  final entry = list.entryById(entryId);
                  final hint = defaults[r];
                  return Card(
                    child: ListTile(
                      dense: true,
                      leading: SizedBox(
                        width: 52,
                        child: Text('${r * 4 + 1}~${r * 4 + 4}',
                            style: Theme.of(context).textTheme.bodySmall),
                      ),
                      title: entry == null
                          ? Text(hint, style: const TextStyle(color: Colors.grey))
                          : Text(entry.name),
                      subtitle: entry != null && !isPlotline && entry.trait != null
                          ? Text('特质：${entry.trait}',
                              maxLines: 1, overflow: TextOverflow.ellipsis)
                          : (entry != null && entry.notes.isNotEmpty
                              ? Text(entry.notes,
                                  maxLines: 1, overflow: TextOverflow.ellipsis)
                              : null),
                      onTap: entry == null
                          ? null
                          : () async {
                              final result = await _entryDialog(context, c, entry);
                              if (result == null) return;
                              c.editEntry(entry.id, result.$1, result.$2,
                                  trait: result.$3,
                                  identities: result.$4,
                                  descriptors: result.$5);
                            },
                      trailing: entry == null
                          ? null
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                weightBadge(c.list.weightOf(entry.id)),
                                IconButton(
                                  tooltip: '权重 +1（占下一个空行）',
                                  icon: const Icon(Icons.add_circle_outline, size: 20),
                                  onPressed: () {
                                    if (!c.incWeight(entry.id)) {
                                      showSnack(context,
                                          '已达权重上限（${c.settings.allowUnlimitedListCount.value ? '不限制' : '3'}）。可在设置中解除上限。');
                                    }
                                  },
                                ),
                                IconButton(
                                  tooltip: '权重 -1',
                                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                                  onPressed: () {
                                    if (!c.decWeight(entry.id)) {
                                      showSnack(context, '该条目没有占用行。');
                                    }
                                  },
                                ),
                              ],
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  Future<(String, String, String?, List<String>?, List<String>?)?> _entryDialog(
      BuildContext context, PagedListController c, ListEntry? entry) async {
    final nameCtrl = TextEditingController(text: entry?.name ?? '');
    final notesCtrl = TextEditingController(text: entry?.notes ?? '');
    final traitCtrl = TextEditingController(text: entry?.trait ?? '');
    final idCtrl =
        TextEditingController(text: entry?.identities.join('，') ?? '');
    final descCtrl =
        TextEditingController(text: entry?.descriptors.join('，') ?? '');
    List<String> split(String s) => s
        .split(RegExp('[，,]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final result = await showDialog<List<dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(entry == null
            ? (c.isPlotline ? '新情节线' : '新角色')
            : '编辑条目'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                        labelText: '名称', border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                        labelText: '笔记', border: OutlineInputBorder())),
                if (!c.isPlotline) ...[
                  const SizedBox(height: 8),
                  TextField(
                      controller: traitCtrl,
                      decoration: const InputDecoration(
                          labelText: '特殊特质', border: OutlineInputBorder())),
                  const SizedBox(height: 8),
                  TextField(
                      controller: idCtrl,
                      decoration: const InputDecoration(
                          labelText: '身份（多个用「，」分隔）',
                          border: OutlineInputBorder())),
                  const SizedBox(height: 8),
                  TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                          labelText: '描述词（多个用「，」分隔）',
                          border: OutlineInputBorder())),
                ],
              ],
            ),
          ),
        ),
        actions: [
          if (entry != null)
            TextButton(
              onPressed: () async {
                final ok = await confirmDialog(
                    context, '删除条目', '删除「${entry.name}」及其全部占用行（权重随之消失）。确定？');
                if (!ok) return;
                c.deleteEntry(entry.id);
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: const Text('删除',
                  style: TextStyle(color: Colors.red)),
            ),
          const Spacer(),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(context, [
                nameCtrl.text.trim(),
                notesCtrl.text.trim(),
                c.isPlotline ? null : (traitCtrl.text.trim().isEmpty ? null : traitCtrl.text.trim()),
                c.isPlotline ? null : split(idCtrl.text),
                c.isPlotline ? null : split(descCtrl.text),
              ]);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (result == null) return null;
    return (
      result[0] as String,
      result[1] as String,
      result[2] as String?,
      (result[3] as List<String>?),
      (result[4] as List<String>?),
    );
  }
}
