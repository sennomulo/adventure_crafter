import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/adventure.dart';
import '../../data/rules.dart';
import '../../helpers/utils.dart';
import '../../services/adventure_service.dart';
import '../adventure/adventure_page.dart';
import '../tables/lookup_dialogs.dart';
import '../widgets/common.dart';

class TurningPointsController extends GetxController {
  RulesService get rules => Get.find<RulesService>();
  AdventureService get service => Get.find<AdventureService>();
  Adventure get adv => service.current.value!;

  void changed() {
    service.save();
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
      adv.turningPoints[k].index = k + 1;
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
    s.themeDie = outcome.themeDie;
    s.roll = outcome.roll;
    s.metaRoll = outcome.metaRoll;
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
      builder: (dialogContext) => AlertDialog(
        title: Text('掷中空行（第${rowIdx + 1}行）'),
        content: Text('默认提示：$hint'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('保持未聚焦'),
          ),
          if (hint == '新情节线')
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                goToAdventureTab(1);
              },
              child: const Text('前往情节线列表'),
            ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
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
      builder: (dialogContext) => SimpleDialog(
        title: const Text('选择最合理的情节线'),
        children: entries
            .map((e) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(dialogContext, e.id),
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
    return Obx(() {
      final c = Get.find<TurningPointsController>();
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
                    showDialog(
                      context: context,
                      builder: (_) => TurningPointEditor(c: c, tp: tp),
                    );
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
                          title:
                              Text('转折点 ${tp.index}　聚焦：${focus?.name ?? '未聚焦'}'),
                          subtitle: Text(
                              '状态：${statusLabel(tp.status)}　'
                              '情节点：${tp.slots.where((s) => !s.isEmpty).length}/5'),
                          onTap: () => showDialog(
                            context: context,
                            builder: (_) => TurningPointEditor(c: c, tp: tp),
                          ),
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
    });
  }

  static String statusLabel(String status) {
    switch (status) {
      case 'development':
        return '发展';
      case 'conclusion':
        return '结束';
      default:
        return '未定';
    }
  }
}

class TurningPointEditor extends StatefulWidget {
  final TurningPointsController c;
  final TurningPoint tp;

  const TurningPointEditor({super.key, required this.c, required this.tp});

  @override
  State<TurningPointEditor> createState() => _TurningPointEditorState();
}

class _TurningPointEditorState extends State<TurningPointEditor> {
  late final TextEditingController tpNotesCtrl;
  late final List<TextEditingController> slotNotesCtrls;

  @override
  void initState() {
    super.initState();
    tpNotesCtrl = TextEditingController(text: widget.tp.notes);
    slotNotesCtrls = List.generate(
        5, (i) => TextEditingController(text: widget.tp.slots[i].notes));
  }

  @override
  void dispose() {
    tpNotesCtrl.dispose();
    for (final ctrl in slotNotesCtrls) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    return Obx(() {
      final adv = c.service.current.value!;
      final focus = adv.plotlines.entryById(widget.tp.plotlineId);
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
                    Text('转折点 ${widget.tp.index}',
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
                              c.rollFocus(widget.tp, context);
                            } else if (v == 'clear') {
                              c.setFocusManually(widget.tp, null);
                            } else if (v == 'new') {
                              _newFocus(context);
                            } else if (v.startsWith('e')) {
                              c.setFocusManually(
                                  widget.tp, int.parse(v.substring(1)));
                            }
                          },
                        ),
                      ),
                    ),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('转折点状态（由玩家手动设置）'),
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                    value: 'undecided', label: Text('未定')),
                                ButtonSegment(
                                    value: 'development', label: Text('发展')),
                                ButtonSegment(
                                    value: 'conclusion', label: Text('结束')),
                              ],
                              selected: {widget.tp.status},
                              onSelectionChanged: (selection) {
                                widget.tp.status = selection.first;
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
                    if (widget.tp.status == 'conclusion')
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
                      controller: tpNotesCtrl,
                      onChanged: (v) => widget.tp.notes = v,
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
    });
  }

  Future<void> _newFocus(BuildContext context) async {
    final name = await textInputDialog(context, '新情节线', hint: '情节线名称');
    if (name == null || name.trim().isEmpty) return;
    final list = widget.c.adv.plotlines;
    final id = list.nextEntryId();
    list.entries.add(ListEntry(id: id, name: name.trim()));
    list.assignNextEmpty(id);
    widget.tp.plotlineId = id;
    widget.c.changed();
  }

  Widget _slotCard(BuildContext context, int i) {
    final s = widget.tp.slots[i];
    final pp = widget.c.rules.plotPointById(s.plotPointId);
    final meta = widget.c.rules.metaById(s.metaId);
    final themeLabel =
        s.themeId == null ? '' : widget.c.rules.themeName(s.themeId!);
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
                  onPressed: () =>
                      widget.c.rollSlot(widget.tp, i, context),
                ),
                TextButton(
                  onPressed: () => widget.c.setNone(widget.tp, i),
                  child: const Text('改为「无」'),
                ),
                TextButton(
                  onPressed: () =>
                      widget.c.setMostLikely(widget.tp, i, context),
                  child: const Text('改为最合理'),
                ),
              ],
            ),
            if (pp == null)
              const Text('（未掷）', style: TextStyle(color: Colors.grey))
            else ...[
              Text(
                  '${s.themeDie == null ? '' : '主题骰 ${s.themeDie}（$themeLabel）　情节点骰 ${s.roll}　→　'}${pp.title}',
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
                      Text(
                          '元情节点${s.metaRoll == null ? '' : '（1d100=${s.metaRoll}）'}：${meta?.title ?? '未掷'}',
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
            _invokedChips(context, s),
            TextField(
              controller: slotNotesCtrls[i],
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
    final adv = widget.c.adv;
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
              widget.c.changed();
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
    final entries = widget.c.adv.characters.entries;
    if (entries.isEmpty) {
      showSnack(context, '角色列表为空。');
      return;
    }
    final selected = Set<int>.from(s.invoked);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
                        onChanged: (v) => setState(() => v == true
                            ? selected.add(e.id)
                            : selected.remove(e.id)),
                      ))
                  .toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('确定')),
        ],
      ),
    );
    if (ok != true) return;
    s.invoked
      ..clear()
      ..addAll(selected);
    widget.c.changed();
  }
}
