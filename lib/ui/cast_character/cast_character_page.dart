import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/adventure.dart';
import '../../data/rules.dart';
import '../../helpers/utils.dart';
import '../../services/adventure_service.dart';
import '../../services/settings_service.dart';
import '../tables/list_roll_lookup.dart';
import '../tables/lookup_dialogs.dart';
import '../widgets/common.dart';

class CastController extends GetxController {
  final traitDie = 0.obs;
  final identityDie = 0.obs;
  final descriptorDie = 0.obs;
  final trait = Rxn<NumberedEntry>();
  final identity = Rxn<NumberedEntry>();
  final descriptor = Rxn<NumberedEntry>();
  final relatedRollResult = ''.obs;
  final identityHistory = <String>[].obs;
  final descriptorHistory = <String>[].obs;

  RulesService get rules => Get.find<RulesService>();
  AdventureService get service => Get.find<AdventureService>();

  void roll(int which) {
    final roll = roll100();
    if (which == 0) {
      traitDie.value = roll;
      trait.value = rules.entryAt(rules.traits, roll);
      relatedRollResult.value = '';
      service.logRoll(
          'Casting · special trait'.tr, '1d100=$roll → ${trait.value!.text}');
    } else if (which == 1) {
      identityDie.value = roll;
      identity.value = rules.entryAt(rules.identities, roll);
      identityHistory.add(identity.value!.text);
      service.logRoll(
          'Casting · identity'.tr, '1d100=$roll → ${identity.value!.text}');
    } else {
      descriptorDie.value = roll;
      descriptor.value = rules.entryAt(rules.descriptors, roll);
      descriptorHistory.add(descriptor.value!.text);
      service.logRoll(
          'Casting · descriptor'.tr, '1d100=$roll → ${descriptor.value!.text}');
    }
  }

  /// 书中规则：关联角色查询得到"新角色"时，结果转换为"选择最合理的角色"。
  String _relatedResultText(ListEntry? entry, String hint) {
    if (entry != null) return entry.name;
    if (hint == '新角色') return 'Choose the most fitting character'.tr;
    return '${'empty'.tr} → $hint';
  }

  void rollRelatedCharacter() {
    final adv = service.current.value!;
    final list = adv.characters;
    if (list.pages.isEmpty) {
      relatedRollResult.value = '(character list is empty)'.tr;
      return;
    }
    int pageIdx = 0;
    var pageDesc = '';
    if (list.pages.length > 1) {
      final die = rollDie(list.pages.length);
      pageIdx = die - 1;
      pageDesc = '1d${list.pages.length}=$die，';
    }
    final roll = roll100();
    final rowIdx = rowForRoll(roll);
    final entry = list.entryById(list.pages[pageIdx][rowIdx]);
    final hint = rules.characterRowDefaults[rowIdx];
    service.logRoll('Casting · related character roll'.tr,
        '$pageDesc 1d100=$roll → ${rowIdx + 1}${entry == null ? '（${'empty'.tr}）' : '：${entry.name}'}');
    relatedRollResult.value = 'page @page, row @row: @result'.trParams({
      'page': '${pageIdx + 1}',
      'row': '${rowIdx + 1}',
      'result': _relatedResultText(entry, hint),
    });
  }

  /// 实体骰模式：玩家在角色列表查询表中点选行，确认关联角色结果。
  void pickRelatedCharacter(ListEntry? entry, int pageIdx, int rowIdx) {
    final hint = rules.characterRowDefaults[rowIdx];
    final result = _relatedResultText(entry, hint);
    service.logRoll('Casting · related character roll'.tr,
        'Physical pick p@p, r@r → @result'.trParams({
          'p': '${pageIdx + 1}',
          'r': '${rowIdx + 1}',
          'result': result,
        }));
    relatedRollResult.value = 'page @page, row @row: @result'.trParams({
      'page': '${pageIdx + 1}',
      'row': '${rowIdx + 1}',
      'result': result,
    });
  }

  /// 实体骰模式：玩家在特质/身份/描述词表中点选条目，确认该出目。
  void pickManual(int which, NumberedEntry e) {
    final label = which == 0
        ? 'Casting · special trait'.tr
        : which == 1
            ? 'Casting · identity'.tr
            : 'Casting · descriptor'.tr;
    if (which == 0) {
      trait.value = e;
      relatedRollResult.value = '';
    } else if (which == 1) {
      identity.value = e;
      identityHistory.add(e.text);
    } else {
      descriptor.value = e;
      descriptorHistory.add(e.text);
    }
    service.logRoll(label, '${'Physical pick'.tr} → ${e.text}');
  }

  void addToCharacters(String name) {
    final adv = service.current.value!;
    final chars = adv.characters;
    final id = chars.nextEntryId();
    chars.entries.add(ListEntry(
      id: id,
      name: name,
      trait: trait.value?.text,
      identities: identityHistory.toList(),
      descriptors: descriptorHistory.toList(),
    ));
    chars.assignNextEmpty(id);
    service.save();
    service.logRoll('Casting'.tr,
        '"@name" added to the character list.'.trParams({'name': name}));
    reset();
  }

  void reset() {
    traitDie.value = 0;
    identityDie.value = 0;
    descriptorDie.value = 0;
    trait.value = null;
    identity.value = null;
    descriptor.value = null;
    relatedRollResult.value = '';
    identityHistory.clear();
    descriptorHistory.clear();
  }
}

class CastCharacterPage extends StatelessWidget {
  const CastCharacterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(CastController());
    final nameCtrl = TextEditingController();
    return Obx(() {
      Get.find<AdventureService>().current.value;
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Character casting wizard'.tr,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Roll trait → identity → descriptor in order, interpret, name, then add to the character list. Original text for trait 93-100, identity 1-33, descriptor 1-21 is display-only; the player handles it.'
              .tr),
          const SizedBox(height: 12),
          _rollCard(context, c, 0, 'Step 1: special trait'.tr, c.trait.value,
              c.traitDie.value),
          _rollCard(context, c, 1, 'Step 2: identity'.tr, c.identity.value,
              c.identityDie.value),
          _rollCard(context, c, 2, 'Step 3: descriptor'.tr, c.descriptor.value,
              c.descriptorDie.value),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                          labelText:
                              'Character name (interpret the three tables, then name)'
                                  .tr,
                          border: const OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      c.addToCharacters(name);
                      nameCtrl.clear();
                      showSnack(
                          context,
                          '"@name" added to the character list.'
                              .trParams({'name': name}));
                    },
                    child: Text('Add to character list'.tr),
                  ),
                ],
              ),
            ),
          ),
          if (c.relatedRollResult.value.isNotEmpty) ...[
            const SizedBox(height: 8),
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.relatedRollResult.value,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => showNumberedLookup(
                        context, c.rules.traits, 'Special trait table'.tr),
                    child: Text('Browse special trait table'.tr),
                  ),
                  OutlinedButton(
                    onPressed: () => showNumberedLookup(
                        context, c.rules.identities, 'Identity table'.tr),
                    child: Text('Browse identity table'.tr),
                  ),
                  OutlinedButton(
                    onPressed: () => showNumberedLookup(
                        context, c.rules.descriptors, 'Descriptor table'.tr),
                    child: Text('Browse descriptor table'.tr),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _rollCard(BuildContext context, CastController c, int which,
      String title, NumberedEntry? result, int die) {
    final settings = Get.find<GlobalSettingsService>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                OutlinedButton.icon(
                  icon: const Icon(Icons.casino, size: 18),
                  label: Text(die == 0 ? 'Roll 1d100'.tr : 'Reroll'.tr),
                  onPressed: () {
                    if (settings.getPhysicalDiceModeEnabled) {
                      showNumberedLookup(
                          context,
                          which == 0
                              ? c.rules.traits
                              : which == 1
                                  ? c.rules.identities
                                  : c.rules.descriptors,
                          title,
                          onSelect: (e) => c.pickManual(which, e));
                      return;
                    }
                    c.roll(which);
                  },
                ),
              ],
            ),
            if (result != null) ...[
              const SizedBox(height: 6),
              Text(die == 0
                      ? result.text
                      : '1d100=$die → ${result.text}',
                  style: Theme.of(context).textTheme.titleSmall),
              if (result.desc != null && result.desc!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(result.desc!,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
              if (result.id == 'trait08')
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.casino, size: 18),
                        label:
                            Text('Roll character list for the related character'.tr),
                        onPressed: () {
                          if (settings.getPhysicalDiceModeEnabled) {
                            showListRollLookup(
                              context,
                              title: 'Character list'.tr,
                              list: c.service.current.value!.characters,
                              defaults: c.rules.characterRowDefaults,
                              onSelect: (entry, pageIdx, rowIdx) =>
                                  c.pickRelatedCharacter(
                                      entry, pageIdx, rowIdx),
                            );
                            return;
                          }
                          c.rollRelatedCharacter();
                        },
                      ),
                      if (c.relatedRollResult.value.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(c.relatedRollResult.value,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ),
              if (result.rollTwo)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.all(8),
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  child: Text(
                      'This result requires rolling two: roll again yourself (the software does not handle it); every roll result is recorded in the list below.'
                          .tr),
                ),
              if (which >= 1) ...[
                const SizedBox(height: 8),
                Obx(() {
                  final history =
                      which == 1 ? c.identityHistory : c.descriptorHistory;
                  if (history.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (var i = 0; i < history.length; i++)
                        Chip(
                          label: Text(history[i],
                              style: const TextStyle(fontSize: 12)),
                          onDeleted: () => history.removeAt(i),
                        ),
                    ],
                  );
                }),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
