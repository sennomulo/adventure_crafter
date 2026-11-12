import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/adventure.dart';
import '../../data/rules.dart';
import '../../helpers/utils.dart';
import '../../services/adventure_service.dart';
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
  final identityNotesCtrl = TextEditingController();
  final descriptorNotesCtrl = TextEditingController();

  RulesService get rules => Get.find<RulesService>();
  AdventureService get service => Get.find<AdventureService>();

  void roll(int which) {
    final roll = roll100();
    if (which == 0) {
      traitDie.value = roll;
      trait.value = rules.entryAt(rules.traits, roll);
      relatedRollResult.value = '';
      service.logRoll('角色铸造·特殊特质', '1d100=$roll → ${trait.value!.text}');
    } else if (which == 1) {
      identityDie.value = roll;
      identity.value = rules.entryAt(rules.identities, roll);
      identityNotesCtrl.clear();
      service.logRoll('角色铸造·身份', '1d100=$roll → ${identity.value!.text}');
    } else {
      descriptorDie.value = roll;
      descriptor.value = rules.entryAt(rules.descriptors, roll);
      descriptorNotesCtrl.clear();
      service.logRoll('角色铸造·描述词', '1d100=$roll → ${descriptor.value!.text}');
    }
  }

  void rollRelatedCharacter() {
    final adv = service.current.value!;
    final list = adv.characters;
    if (list.pages.isEmpty) {
      relatedRollResult.value = '（角色列表为空）';
      return;
    }
    int pageIdx = 0;
    var pageDesc = '';
    if (list.pages.length > 1) {
      final die = rollDie(list.pages.length);
      pageIdx = die - 1;
      pageDesc = '1d${list.pages.length}=$die（第${pageIdx + 1}页），';
    }
    final roll = roll100();
    final rowIdx = rowForRoll(roll);
    final entry = list.entryById(list.pages[pageIdx][rowIdx]);
    final hint = rules.characterRowDefaults[rowIdx];
    service.logRoll('角色铸造·关联角色掷骰',
        '$pageDesc 1d100=$roll → 第${rowIdx + 1}行${entry == null ? '（空行）' : '：${entry.name}'}');
    relatedRollResult.value =
        '第${pageIdx + 1}页 第${rowIdx + 1}行：${entry != null ? entry.name : '空行 → $hint'}';
  }

  void addToCharacters(String name) {
    final adv = service.current.value!;
    final chars = adv.characters;
    final id = chars.nextEntryId();
    chars.entries.add(ListEntry(
      id: id,
      name: name,
      trait: trait.value?.text,
      identities: identity.value == null ? [] : [identity.value!.text],
      descriptors: descriptor.value == null ? [] : [descriptor.value!.text],
    ));
    chars.assignNextEmpty(id);
    service.save();
    service.logRoll('角色铸造', '新角色「$name」已加入角色列表');
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
    identityNotesCtrl.clear();
    descriptorNotesCtrl.clear();
  }
}

class CastCharacterPage extends StatelessWidget {
  const CastCharacterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(CastController());
    final nameCtrl = TextEditingController();
    return Obx(() {
      final adv = c.service.current.value!;
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('角色铸造向导', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('依次掷特殊特质 → 身份 → 描述词，综合解读后命名并加入角色列表。特殊特质 93-100、身份 1-33、描述词 1-21 的原文说明仅作展示，由玩家自行处置。',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          _rollCard(context, c, 0, '第一步：特殊特质', c.trait.value, c.traitDie.value),
          _rollCard(context, c, 1, '第二步：身份', c.identity.value, c.identityDie.value),
          _rollCard(
              context, c, 2, '第三步：描述词', c.descriptor.value, c.descriptorDie.value),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                          labelText: '角色名称（综合三表结果解读后命名）',
                          border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) return;
                      c.addToCharacters(name);
                      nameCtrl.clear();
                      showSnack(context, '「$name」已加入角色列表');
                    },
                    child: const Text('加入角色列表'),
                  ),
                ],
              ),
            ),
          ),
          if (adv.characters.entries.isNotEmpty) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => showNumberedLookup(
                    context, c.rules.identities, '身份表'),
                child: const Text('浏览身份表'),
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _rollCard(BuildContext context, CastController c, int which,
      String title, NumberedEntry? result, int die) {
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
                  label: Text(die == 0 ? '掷 1d100' : '重掷'),
                  onPressed: () => c.roll(which),
                ),
              ],
            ),
            if (result != null) ...[
              const SizedBox(height: 6),
              Text('1d100=$die → ${result.text}',
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
                        label: const Text('掷角色列表查询关联角色'),
                        onPressed: () => c.rollRelatedCharacter(),
                      ),
                      if (c.relatedRollResult.value.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(c.relatedRollResult.value,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ),
              if (result.rollTwo)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.all(8),
                  width: double.infinity,
                  color: Colors.amber.shade100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('此结果要求掷两个：请自行再掷（软件不自动重骰），并在下方记录两次结果。',
                          style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: which == 1
                            ? c.identityNotesCtrl
                            : c.descriptorNotesCtrl,
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: which == 1
                              ? '记录两次身份掷骰结果…'
                              : '记录两次描述词掷骰结果…',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
