import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/adventure.dart';
import '../../data/rules.dart';
import '../../helpers/utils.dart';
import '../../services/adventure_service.dart';
import '../../services/settings_service.dart';
import '../adventure/adventure_page.dart';
import '../tables/list_roll_lookup.dart';
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
    final label = isPlotline ? 'Plotline list'.tr : 'Character list'.tr;
    final detail = [
      if (pageDie != null) '1d${list.pages.length}=$pageDie',
      '1d100=$roll → ${rowIdx * 4 + 1}~${rowIdx * 4 + 4}',
      entry != null ? '→ ${entry.name}' : '→ ${'empty'.tr}',
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
    final c = Get.isRegistered<PagedListController>(tag: tag)
        ? Get.find<PagedListController>(tag: tag)
        : Get.put(PagedListController(isPlotline: isPlotline), tag: tag);
    final rules = Get.find<RulesService>();
    return Obx(() {
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
                  Text(isPlotline ? 'Plotline list'.tr : 'Character list'.tr,
                      style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(isPlotline ? 'New plotline'.tr : 'New character'.tr),
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
                    label: Text('Roll'.tr),
                    onPressed: () {
                      final settings = Get.find<GlobalSettingsService>();
                      if (settings.getPhysicalDiceModeEnabled) {
                        showListRollLookup(
                          context,
                          title: isPlotline ? 'Plotline list'.tr : 'Character list'.tr,
                          list: c.list,
                          defaults: defaults,
                        );
                        return;
                      }
                      final r = c.rollRow();
                      if (r == null) return;
                      final entry = c.list.entryById(
                          c.list.pages[r.pageIdx][r.rowIdx]);
                      final hint = defaults[r.rowIdx];
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: Text('Roll result: page @page, row @row'
                              .trParams({'page': '${r.pageIdx + 1}', 'row': '${r.rowIdx + 1}'})),
                          content: Text(entry != null
                              ? '${entry.name}${c.list.weightOf(entry.id) > 1 ? '(current weight x@weight)'.trParams({'weight': '${c.list.weightOf(entry.id)}'}) : ''}${'To raise the weight, manually +1 the entry.'.tr}'
                              : 'Empty row → default hint: @hint'.trParams({'hint': hint})),
                          actions: [
                            if (entry == null && hint == '新情节线')
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(dialogContext);
                                  final result =
                                      await _entryDialog(context, c, null);
                                  if (result == null) return;
                                  c.addEntry(result.$1, result.$2);
                                },
                                child: Text('New plotline'.tr),
                              ),
                            if (entry == null && hint == '新角色')
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(dialogContext);
                                  goToAdventureTab(4);
                                },
                                child: Text('Go to character casting'.tr),
                              ),
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: Text('Close'.tr),
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
                      label: Text('Page @page (@from-@to)'.trParams({
                        'page': '${p + 1}',
                        'from': '${p * 25 + 1}',
                        'to': '${p * 25 + 25}',
                      })),
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
                          ? Text(hint,
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant))
                          : Text(entry.name),
                      subtitle: entry != null && !isPlotline && entry.trait != null
                          ? Text('${'Special trait'.tr}：${entry.trait}',
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
                                weightBadge(context, c.list.weightOf(entry.id)),
                                IconButton(
                                  tooltip: 'Weight +1 (takes next empty row)'.tr,
                                  icon: const Icon(Icons.add_circle_outline, size: 20),
                                  onPressed: () {
                                    if (!c.incWeight(entry.id)) {
                                      showSnack(
                                          context,
                                          'Weight cap reached (@max). You can lift the cap in Settings.'
                                              .trParams({
                                            'max': c.settings
                                                    .allowUnlimitedListCount.value
                                                ? '∞'
                                                : '3',
                                          }));
                                    }
                                  },
                                ),
                                IconButton(
                                  tooltip: 'Weight -1'.tr,
                                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                                  onPressed: () {
                                    if (!c.decWeight(entry.id)) {
                                      showSnack(context,
                                          'This entry occupies no row.'.tr);
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
    });
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
            ? (c.isPlotline ? 'New plotline'.tr : 'New character'.tr)
            : 'Edit entry'.tr),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                        labelText: 'Name'.tr,
                        border: const OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(
                    controller: notesCtrl,
                    decoration: InputDecoration(
                        labelText: 'Notes'.tr,
                        border: const OutlineInputBorder())),
                if (!c.isPlotline) ...[
                  const SizedBox(height: 8),
                  TextField(
                      controller: traitCtrl,
                      decoration: InputDecoration(
                          labelText: 'Special trait'.tr,
                          border: const OutlineInputBorder())),
                  const SizedBox(height: 8),
                  TextField(
                      controller: idCtrl,
                      decoration: InputDecoration(
                          labelText: 'Identities (separate with ，)'.tr,
                          border: const OutlineInputBorder())),
                  const SizedBox(height: 8),
                  TextField(
                      controller: descCtrl,
                      decoration: InputDecoration(
                          labelText: 'Descriptors (separate with ，)'.tr,
                          border: const OutlineInputBorder())),
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
                    context,
                    'Delete entry'.tr,
                    'Delete "@name" and all its occupied rows (weight is lost). Are you sure?'
                        .trParams({'name': entry.name}));
                if (!ok) return;
                c.deleteEntry(entry.id);
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: Text('Delete'.tr,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel'.tr)),
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
            child: Text('Save'.tr),
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
