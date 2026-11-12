import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/adventure.dart';
import '../../data/rules.dart';
import '../../helpers/utils.dart';
import '../../services/adventure_service.dart';
import '../tables/lookup_dialogs.dart';
import '../widgets/common.dart';

class TurningPointsController extends GetxController {
  RulesService get rules => Get.find<RulesService>();
  AdventureService get service => Get.find<AdventureService>();
  Adventure get adv => service.current.value!;

  void changed() {
    service.save();
    update();
  }

  TurningPoint addTurningPoint() {
    final tp = TurningPoint(
      index: adv.turningPoints.length + 1,
      slots: List.generate(5, (_) => Slot()),
    );
    adv.turningPoints.add(tp);
    changed();
    return tp;
  }

  void removeTurningPoint(int i) {
    adv.turningPoints.removeAt(i);
    for (var k = 0; k < adv.turningPoints.length; k++) {
      adv.turningPoints[k] = TurningPoint(
        index: k + 1,
        plotlineId: adv.turningPoints[k].plotlineId,
        status: adv.turningPoints[k].status,
        slots: adv.turningPoints[k].slots,
        notes: adv.turningPoints[k].notes,
      );
    }
    changed();
  }

  void rollSlot(TurningPoint tp, int slotIdx, BuildContext context) {
    final outcome = service.rollPlotPoint(adv);
    if (outcome == null) {
      showSnack(context, '请先在「主题」页设置冒险主题。');
      return;
    }
    final s = tp.slots[slotIdx];
    s.themeId = outcome.theme;
    s.plotPointId = outcome.plotPoint.id;
    s.metaId = outcome.meta?.id;
    changed();
    if (outcome.meta != null) {
      showMetaResult(context, outcome.meta!, roll: outcome.metaRoll);
    }
  }

  void setNone(TurningPoint tp, int slotIdx) {
    final s = tp.slots[slotIdx];
    s.plotPointId = 'none';
    s.metaId = null;
    changed();
  }

  void setMostLikely(TurningPoint tp, int slotIdx, BuildContext context) async {
    final pp = await showPlotPointLookup(context, rules);
    if (pp == null) return;
    final s = tp.slots[slotIdx];
    s.plotPointId = pp.id;
    s.metaId = null;
    changed();
  }

  void rollFocus(TurningPoint tp, BuildContext context) {
    final list = adv.plotlines;
    if (list.pages.isEmpty) {
      showSnack(context, '情节线列表为空。');
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
    service.logRoll('聚焦情节线掷骰',
        '$pageDesc 1d100=$roll → 第${rowIdx + 1}行（${rowIdx * 4 + 1}~${rowIdx * 4 + 4}）${entry == null ? '（空行）' : '：${entry.name}'}');
    if (entry != null) {
      tp.plotlineId = entry.id;
      changed();
      showSnack(context, '聚焦情节线：${entry.name}。如需提升权重，请到「情节线」页手动 +1。');
      return;
    }
    final hint = rules.rowDefault(true, rowIdx);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('掷中空行（第${rowIdx + 1}行）'),
        content: Text('默认提示：$hint'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('保持未聚焦'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _pickFocusManually(tp, context);
            },
            child: const Text('选择最合理的情节线'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFocusManually(TurningPoint tp, BuildContext context) async {
    final entries = adv.plotlines.entries;
    if (entries.isEmpty) {
      showSnack(context, '情节线列表为空，请先到「情节线」页新建。');
      return;
    }
    final picked = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('选择最合理的情节线'),
        children: entries
            .map((e) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, e.id),
                  child: Text(e.name),
                ))
            .toList(),
      ),
    );
    if (picked == null) return;
    tp.plotlineId = picked;
    changed();
  }

  void setFocusManually(TurningPoint tp, int? entryId) {
    tp.plotlineId = entryId;
    changed();
  }
}

class TurningPointsPage extends StatelessWidget {
  const TurningPointsPage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(TurningPointsController());
    return GetBuilder<TurningPointsController>(
      builder: (c) => Obx(() {
        final adv = c.adv;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text('转折点', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('新转折点'),
                    onPressed: () {
                      final tp = c.addTurningPoint();
                      _openEditor(context, c, tp);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: adv.turningPoints.isEmpty
                  ? const Center(child: Text('还没有转折点。点击「新转折点」开始。'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: adv.turningPoints.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final tp = adv.turningPoints[i];
                        final focus = adv.plotlines.entryById(tp.plotlineId);
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(child: Text('${tp.index}')),
                            title: Text('转折点 ${tp.index}　聚焦：${focus?.name ?? '未聚焦'}'),
                            subtitle: Text(
                                '状态：${_statusLabel(tp.status)}　'
                                '情节点：${tp.slots.where((s) => !s.isEmpty).length}/5'),
                            onTap: () => _openEditor(context, c, tp),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                final ok = await confirmDialog(
                                    context, '删除转折点', '删除转折点 ${tp.index}？');
                                if (ok) c.removeTurningPoint(i);
                              },
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

  static String _statusLabel(String status) {
    switch (status) {
      case 'development':
        return '发展';
      case 'conclusion':
        return '结束';
      default:
        return '未定';
    }
  }

  void _openEditor(BuildContext context, TurningPointsController c, TurningPoint tp) {
    showDialog(
      context: context,
      builder: (dialogContext) => _TurningPointEditor(c: c, tp: tp),
    );
  }
}

class _TurningPointEditor extends StatelessWidget {
  final TurningPointsController c;
  final TurningPoint tp;

  const _TurningPointEditor({required this.c, required this.tp});

  @override
  Widget build(BuildContext context) {
    final adv = c.adv;
    final focus = adv.plotlines.entryById(tp.plotlineId);
    return Dialog(
      child: SizedBox(
        width: 760,
        height: 680,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Text('转折点 ${tp.index}',
                      style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  FilledButton.tonal(
                    onPressed: () {
                      c.changed();
                      Navigator.pop(context);
                    },
                    child: const Text('保存并关闭'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.account_tree_outlined),
                      title: Text('聚焦情节线：${focus?.name ?? '未聚焦'}'),
                      subtitle: const Text('可掷骰确定，或手动指定（含「新情节线」）'),
                      trailing: PopupMenuButton<String>(
                        tooltip: '指定聚焦情节线',
                        icon: const Icon(Icons.more_vert),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                              value: 'roll', child: Text('掷情节线列表')),
                          const PopupMenuItem(
                              value: 'new', child: Text('新情节线并聚焦')),
                          const PopupMenuItem(
                              value: 'clear', child: Text('清除聚焦')),
                          ...adv.plotlines.entries.map((e) => PopupMenuItem(
                              value: 'e${e.id}', child: Text(e.name))),
                        ],
                        onSelected: (v) {
                          if (v == 'roll') {
                            c.rollFocus(tp, context);
                          } else if (v == 'clear') {
                            c.setFocusManually(tp, null);
                          } else if (v == 'new') {
                            asyncNewFocus(context);
                          } else if (v.startsWith('e')) {
                            c.setFocusManually(tp, int.parse(v.substring(1)));
                          }
                        },
                      ),
                    ),
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('转折点状态（由玩家手动设置）'),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'undecided', label: Text('未定')),
                              ButtonSegment(value: 'development', label: Text('发展')),
                              ButtonSegment(value: 'conclusion', label: Text('结束')),
                            ],
                            selected: {tp.status},
                            onSelectionChanged: (selection) {
                              tp.status = selection.first;
                              c.changed();
                              if (selection.first == 'conclusion') {
                                showSnack(context,
                                    '转折点为「结束」：请自行将该情节线移出情节线列表（编辑快捷操作不实现，交由玩家操作）。');
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (tp.status == 'conclusion')
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.all(10),
                      width: double.infinity,
                      color: Colors.deepOrange.shade50,
                      child: const Text(
                          '「结束」：将结束该情节线所需的一切纳入本转折点，并自行从情节线列表中移除该情节线。',
                          style: TextStyle(fontSize: 12)),
                    ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < 5; i++) _slotCard(context, i),
                  TextField(
                    controller: TextEditingController(text: tp.notes),
                    onChanged: (v) => tp.notes = v,
                    decoration: const InputDecoration(
                        labelText: '转折点笔记',
                        border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> asyncNewFocus(BuildContext context) async {
    final name = await textInputDialog(context, '新情节线', hint: '情节线名称');
    if (name == null || name.trim().isEmpty) return;
    final list = c.adv.plotlines;
    final id = list.nextEntryId();
    list.entries.add(ListEntry(id: id, name: name.trim()));
    list.assignNextEmpty(id);
    tp.plotlineId = id;
    c.changed();
  }

  Widget _slotCard(BuildContext context, int i) {
    final s = tp.slots[i];
    final pp = c.rules.plotPointById(s.plotPointId);
    final meta = c.rules.metaById(s.metaId);
    final themeLabel = s.themeId == null ? '' : c.rules.themeName(s.themeId!);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('情节点 ${i + 1}',
                    style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.casino, size: 18),
                  label: Text(pp == null ? '掷骰' : '重掷'),
                  onPressed: () => c.rollSlot(tp, i, context),
                ),
                TextButton(
                  onPressed: () => c.setNone(tp, i),
                  child: const Text('改为「无」'),
                ),
                TextButton(
                  onPressed: () => c.setMostLikely(tp, i, context),
                  child: const Text('改为最合理'),
                ),
              ],
            ),
            if (pp == null)
              const Text('（未掷）', style: TextStyle(color: Colors.grey))
            else ...[
              Text('$themeLabel → ${pp.title}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              if (s.plotPointId != 'meta' && pp.desc.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(pp.desc,
                      style: Theme.of(context).textTheme.bodySmall),
                ),
              if (s.plotPointId == 'meta')
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      Text('元情节点：${meta?.title ?? '未掷'}',
                          style: const TextStyle(
                              color: Colors.deepOrange,
                              fontWeight: FontWeight.bold)),
                      if (meta != null)
                        TextButton(
                          onPressed: () => showMetaResult(context, meta),
                          child: const Text('查看原文'),
                        ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _invokedChips(context, s),
                ),
              ],
            ),
            TextField(
              controller: TextEditingController(text: s.notes),
              onChanged: (v) => s.notes = v,
              decoration: const InputDecoration(
                  isDense: true,
                  labelText: '槽位笔记',
                  border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _invokedChips(BuildContext context, Slot s) {
    final adv = c.adv;
    final invoked = s.invoked
        .map((id) => adv.characters.entryById(id))
        .whereType<ListEntry>()
        .toList();
    return Wrap(
      spacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('征引角色：', style: Theme.of(context).textTheme.bodySmall),
        for (final ch in invoked)
          Chip(
            label: Text(ch.name, style: const TextStyle(fontSize: 12)),
            onDeleted: () {
              s.invoked.remove(ch.id);
              c.changed();
            },
          ),
        ActionChip(
          label: const Text('选择', style: TextStyle(fontSize: 12)),
          onPressed: () => _pickInvoked(context, s),
        ),
      ],
    );
  }

  Future<void> _pickInvoked(BuildContext context, Slot s) async {
    final entries = c.adv.characters.entries;
    if (entries.isEmpty) {
      showSnack(context, '角色列表为空。');
      return;
    }
    final selected = Set<int>.from(s.invoked);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('征引角色'),
          content: SizedBox(
            width: 360,
            height: 380,
            child: StatefulBuilder(
              builder: (context, setState) => ListView(
                children: entries
                    .map((e) => CheckboxListTile(
                          dense: true,
                          title: Text(e.name),
                          value: selected.contains(e.id),
                          onChanged: (v) => setState(() =>
                              v == true ? selected.add(e.id) : selected.remove(e.id)),
                        ))
                    .toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('确定')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    s.invoked
      ..clear()
      ..addAll(selected);
    c.changed();
  }
}
