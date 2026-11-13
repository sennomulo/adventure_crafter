import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/adventure.dart';
import '../../data/rules.dart';
import '../../helpers/utils.dart';
import '../../services/adventure_service.dart';
import '../../services/settings_service.dart';
import '../adventure/adventure_page.dart';
import '../tables/list_roll_lookup.dart';
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
      showSnack(context, 'Set adventure themes on the Themes page first.'.tr);
      return;
    }
    final s = tp.slots[slotIdx];
    s.themeId = outcome.theme;
    s.plotPointId = outcome.plotPoint.id;
    s.metaId = null;
    s.metaRoll = null;
    s.themeDie = outcome.themeDie;
    s.roll = outcome.roll;
    changed();
    if (outcome.plotPoint.id == 'meta') {
      showSnack(context,
          'Meta plot point triggered: click "Roll for meta plot point" in this slot.'
              .tr);
    }
  }

  void rollMeta(TurningPoint tp, int slotIdx, BuildContext context) {
    final roll = roll100();
    final meta = rules.metaAt(roll);
    final s = tp.slots[slotIdx];
    s.metaId = meta.id;
    s.metaRoll = roll;
    service.logRoll(
        'Meta plot point'.tr, '1d100=$roll → ${meta.title}');
    changed();
    showMetaResult(context, meta, roll: roll);
  }

  /// 实体骰模式：玩家在主题骰映射表中点选行确认主题，
  /// 再在情节点表中选定情节点后写入槽位。
  /// 联动：出目为交替位（10）时，交替指针翻转，记录本次使用的交替位主题。
  void pickSlotPhysical(TurningPoint tp, int slotIdx, int die, String themeId,
      PlotPoint pp, BuildContext context) {
    final s = tp.slots[slotIdx];
    s.themeId = themeId;
    s.plotPointId = pp.id;
    s.metaId = null;
    s.metaRoll = null;
    if (die == 10) {
      adv.alternator = adv.alternator == 4 ? 5 : 4;
      service.logRoll('Theme die (1d10)'.tr,
          '${'Physical pick'.tr} → ${rules.themeName(themeId)}（${'Alternator'.tr}）');
    } else {
      service.logRoll('Theme die (1d10)'.tr,
          '${'Physical pick'.tr} → ${rules.themeName(themeId)}');
    }
    service.logRoll(
        'Plot point roll'.tr,
        '${rules.themeName(themeId)} → ${pp.id == 'meta' ? 'Meta plot point triggered (not rolled)'.tr : pp.title}');
    changed();
    if (pp.id == 'meta' && context.mounted) {
      showSnack(context,
          'Meta plot point triggered: click "Roll for meta plot point" in this slot.'
              .tr);
    }
  }

  /// 实体骰模式：玩家在元情节点表中点选条目，确认该出目。
  void pickMeta(
      TurningPoint tp, int slotIdx, MetaPlotPoint meta, BuildContext context) {
    final s = tp.slots[slotIdx];
    s.metaId = meta.id;
    s.metaRoll = null;
    service.logRoll(
        'Meta plot point'.tr, '${'Physical pick'.tr} → ${meta.title}');
    changed();
    showMetaResult(context, meta);
  }

  /// 实体骰模式：玩家在情节线列表查询表中点选行，确认聚焦情节线。
  void pickFocusFromLookup(
      TurningPoint tp, BuildContext context, ListEntry? entry, int rowIdx) {
    if (entry != null) {
      service.logRoll('Rolling focus plotline'.tr,
          '${'Physical pick'.tr} → ${entry.name}');
      tp.plotlineId = entry.id;
      changed();
      showSnack(
          context,
          'Focused plotline: @name. To raise its weight, manually +1 on the Plotlines page.'
              .trParams({'name': entry.name}));
      return;
    }
    // 空行：按默认提示处理（与随机掷骰的空行分支一致）
    handleFocusEmptyRow(tp, context, rowIdx);
  }

  void handleFocusEmptyRow(TurningPoint tp, BuildContext context, int rowIdx) {
    final hint = rowIdx < 0 ? '' : rules.rowDefault(true, rowIdx);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title:
            Text('Empty row rolled (row @row)'.trParams({'row': '${rowIdx + 1}'})),
        content: Text('Default hint: @hint'.trParams({'hint': hint})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Keep unfocused'.tr),
          ),
          if (hint == '新情节线')
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                goToAdventureTab(1);
              },
              child: Text('Go to plotline list'.tr),
            ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _pickFocusManually(tp, context);
            },
            child: Text('Pick the most likely plotline'.tr),
          ),
        ],
      ),
    );
  }

  void setNone(TurningPoint tp, int slotIdx) {
    final s = tp.slots[slotIdx];
    s.plotPointId = 'none';
    s.metaId = null;
    changed();
  }

  void setMostLikely(TurningPoint tp, int slotIdx, BuildContext context) async {
    final pp = await showPlotPointLookup(context, rules,
        initialTheme: tp.slots[slotIdx].themeId);
    if (pp == null) return;
    final s = tp.slots[slotIdx];
    s.plotPointId = pp.id;
    s.metaId = null;
    changed();
  }

  void rollFocus(TurningPoint tp, BuildContext context) {
    final list = adv.plotlines;
    if (list.pages.isEmpty) {
      showSnack(context, 'The plotline list is empty.'.tr);
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
    service.logRoll('Rolling focus plotline'.tr,
        '$pageDesc 1d100=$roll → ${rowIdx * 4 + 1}~${rowIdx * 4 + 4}${entry == null ? '（${'empty'.tr}）' : '：${entry.name}'}');
    if (entry != null) {
      tp.plotlineId = entry.id;
      changed();
      showSnack(
          context,
          'Focused plotline: @name. To raise its weight, manually +1 on the Plotlines page.'
              .trParams({'name': entry.name}));
      return;
    }
    handleFocusEmptyRow(tp, context, rowIdx);
  }

  Future<void> _pickFocusManually(TurningPoint tp, BuildContext context) async {
    final entries = adv.plotlines.entries;
    if (entries.isEmpty) {
      showSnack(context,
          'The plotline list is empty. Create one on the Plotlines page first.'.tr);
      return;
    }
    final picked = await showDialog<int>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text('Pick the most likely plotline'.tr),
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

  /// F1：为情节点"征引角色"掷角色列表，确定征引哪个既有角色。
  Future<void> rollInvokedCharacter(
      TurningPoint tp, int slotIdx, BuildContext context) async {
    final list = adv.characters;
    if (list.pages.isEmpty) {
      showSnack(context, 'The character list is empty.'.tr);
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
    service.logRoll('Invoked character roll'.tr,
        '$pageDesc 1d100=$roll → ${rowIdx * 4 + 1}~${rowIdx * 4 + 4}${entry == null ? '（${'empty'.tr}）' : '：${entry.name}'}');
    await _applyInvokedRoll(tp, slotIdx, entry, rowIdx, context);
  }

  /// 实体骰模式：玩家在角色列表查询表中点选行确认征引结果。
  Future<void> pickInvokedFromLookup(TurningPoint tp, int slotIdx,
      ListEntry? entry, int pageIdx, int rowIdx, BuildContext context) async {
    if (entry != null) {
      service.logRoll(
          'Invoked character roll'.tr,
          'Physical pick p@p, r@r → @result'.trParams({
            'p': '${pageIdx + 1}',
            'r': '${rowIdx + 1}',
            'result': entry.name,
          }));
    }
    await _applyInvokedRoll(tp, slotIdx, entry, rowIdx, context);
  }

  Future<void> _applyInvokedRoll(TurningPoint tp, int slotIdx,
      ListEntry? entry, int rowIdx, BuildContext context) async {
    if (entry != null) {
      final s = tp.slots[slotIdx];
      if (!s.invoked.contains(entry.id)) s.invoked.add(entry.id);
      changed();
      if (context.mounted) {
        showSnack(context,
            'Invoked character: @name'.trParams({'name': entry.name}));
      }
      return;
    }
    final hint = rules.characterRowDefaults[rowIdx];
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title:
            Text('Empty row rolled (row @row)'.trParams({'row': '${rowIdx + 1}'})),
        content: Text('Default hint: @hint'.trParams({'hint': hint})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Keep uninvoked'.tr),
          ),
          if (hint == '新角色')
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                goToAdventureTab(4);
              },
              child: Text('Go to character casting'.tr),
            ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _pickInvokedManually(tp, slotIdx, context);
            },
            child: Text('Choose the most fitting character'.tr),
          ),
        ],
      ),
    );
  }

  Future<void> _pickInvokedManually(
      TurningPoint tp, int slotIdx, BuildContext context) async {
    final entries = adv.characters.entries;
    if (entries.isEmpty) {
      showSnack(context, 'The character list is empty.'.tr);
      return;
    }
    final picked = await showDialog<int>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text('Choose the most fitting character'.tr),
        children: entries
            .map((e) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(dialogContext, e.id),
                  child: Text(e.name),
                ))
            .toList(),
      ),
    );
    if (picked == null) return;
    final s = tp.slots[slotIdx];
    if (!s.invoked.contains(picked)) s.invoked.add(picked);
    changed();
  }

  void setFocusManually(TurningPoint tp, int? entryId) {
    tp.plotlineId = entryId;
    changed();
  }
}

String turningPointStatusLabel(String status) {
  switch (status) {
    case 'development':
      return 'Development'.tr;
    case 'conclusion':
      return 'Conclusion'.tr;
    default:
      return 'New plotline'.tr;
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
                Text('Turning points'.tr,
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text('New turning point'.tr),
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
                ? Center(
                    child: Text(
                        'No turning points yet. Click "New turning point" to start.'
                            .tr))
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
                          title: Text('Turning point @index　Focus: @focus'
                              .trParams({
                            'index': '${tp.index}',
                            'focus': focus?.name ?? '—',
                          })),
                          subtitle: Text('Plotline status: @status　Plot points: @filled/5'
                              .trParams({
                            'status': turningPointStatusLabel(tp.status),
                            'filled': '${tp.slots.where((s) => !s.isEmpty).length}',
                          })),
                          onTap: () => showDialog(
                            context: context,
                            builder: (_) => TurningPointEditor(c: c, tp: tp),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              final ok = await confirmDialog(
                                  context,
                                  'Delete turning point'.tr,
                                  'Delete turning point @index?'
                                      .trParams({'index': '${tp.index}'}));
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
    final settings = Get.find<GlobalSettingsService>();
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
                    Text('Turning point @index'.trParams({'index': '${widget.tp.index}'}),
                        style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    FilledButton.tonal(
                      onPressed: () {
                        c.changed();
                        Navigator.pop(context);
                      },
                      child: Text('Save & close'.tr),
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
                        title: Text('Focus plotline: @focus'
                            .trParams({'focus': focus?.name ?? '—'})),
                        subtitle: Text(
                            'Roll to decide, or pick manually (including "new plotline")'
                                .tr),
                        trailing: PopupMenuButton<String>(
                          tooltip: 'Focus plotline: @focus'
                              .trParams({'focus': focus?.name ?? '—'}),
                          icon: const Icon(Icons.more_vert),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                                value: 'roll',
                                child: Text('Roll plotline list'.tr)),
                            PopupMenuItem(
                                value: 'new',
                                child: Text('New plotline and focus'.tr)),
                            PopupMenuItem(
                                value: 'clear', child: Text('Clear focus'.tr)),
                            ...adv.plotlines.entries.map((e) => PopupMenuItem(
                                value: 'e${e.id}', child: Text(e.name))),
                          ],
                          onSelected: (v) {
                            if (v == 'roll') {
                              if (settings.getPhysicalDiceModeEnabled) {
                                showListRollLookup(
                                  context,
                                  title: 'Plotline list'.tr,
                                  list: c.adv.plotlines,
                                  defaults: c.rules.plotlineRowDefaults,
                                  onSelect: (entry, pageIdx, rowIdx) => c
                                      .pickFocusFromLookup(
                                          widget.tp, context, entry, rowIdx),
                                );
                              } else {
                                c.rollFocus(widget.tp, context);
                              }
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
                            Text('Plotline status (set by the player)'.tr),
                            SegmentedButton<String>(
                              segments: [
                                ButtonSegment(
                                    value: 'new',
                                    label: Text('New plotline'.tr)),
                                ButtonSegment(
                                    value: 'development',
                                    label: Text('Development'.tr)),
                                ButtonSegment(
                                    value: 'conclusion',
                                    label: Text('Conclusion'.tr)),
                              ],
                              selected: {widget.tp.status},
                              onSelectionChanged: (selection) {
                                widget.tp.status = selection.first;
                                c.changed();
                                if (selection.first == 'conclusion') {
                                  showSnack(
                                      context,
                                      '"Conclusion": remove this plotline from the plotline list yourself (edit shortcuts are not implemented; the player operates).'
                                          .tr);
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
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        child: Text(
                            '"Conclusion": include whatever is needed to end this plotline, and remove the plotline from the plotline list yourself.'
                                .tr,
                            style: const TextStyle(fontSize: 12)),
                      ),
                    const SizedBox(height: 8),
                    for (var i = 0; i < 5; i++) _slotCard(context, i),
                    TextField(
                      controller: tpNotesCtrl,
                      onChanged: (v) => widget.tp.notes = v,
                      decoration: InputDecoration(
                          labelText: 'Turning point notes'.tr,
                          border: const OutlineInputBorder()),
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
    final name = await textInputDialog(context, 'New plotline'.tr,
        hint: 'Plotline name'.tr);
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
    final diceDesc = [
      if (s.themeDie != null)
        'Theme die @die (@theme)'
            .trParams({'die': '${s.themeDie}', 'theme': themeLabel}),
      if (s.roll != null)
        'plot point die @roll'.trParams({'roll': '${s.roll}'}),
    ].join('　');
    final settings = Get.find<GlobalSettingsService>();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Plot point @index'.trParams({'index': '${i + 1}'}),
                    style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.casino, size: 18),
                  label: Text(pp == null ? 'Roll'.tr : 'Reroll'.tr),
                  onPressed: () {
                    if (settings.getPhysicalDiceModeEnabled) {
                      showPhysicalSlotLookup(
                        context,
                        widget.c.rules,
                        widget.c.adv.themes,
                        widget.c.adv.alternator,
                        onSelected: (die, themeId) async {
                          final pp = await showPlotPointLookup(
                              context, widget.c.rules,
                              initialTheme: themeId);
                          if (pp == null) return;
                          if (!context.mounted) return;
                          widget.c.pickSlotPhysical(
                              widget.tp, i, die, themeId, pp, context);
                        },
                      );
                      return;
                    }
                    widget.c.rollSlot(widget.tp, i, context);
                  },
                ),
                TextButton(
                  onPressed: () => widget.c.setNone(widget.tp, i),
                  child: Text('Change to "None"'.tr),
                ),
                TextButton(
                  onPressed: () =>
                      widget.c.setMostLikely(widget.tp, i, context),
                  child: Text('Change to most likely'.tr),
                ),
              ],
            ),
            if (pp == null)
              Text('Not rolled yet'.tr,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant))
            else ...[
              Text(
                  diceDesc.isEmpty ? pp.title : '$diceDesc　→　${pp.title}',
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
                  child: meta == null
                      ? FilledButton.tonalIcon(
                          icon: const Icon(Icons.casino, size: 18),
                          label: Text('Roll for meta plot point'.tr),
                          onPressed: () {
                            if (settings.getPhysicalDiceModeEnabled) {
                              showMetaTable(context, widget.c.rules,
                                  onPick: (meta) => widget.c
                                      .pickMeta(widget.tp, i, meta, context));
                              return;
                            }
                            widget.c.rollMeta(widget.tp, i, context);
                          },
                        )
                      : Row(
                          children: [
                            Flexible(
                              child: Text(
                                  'Meta plot point (1d100=@roll): @title'.trParams({
                                    'roll': '${s.metaRoll}',
                                    'title': meta.title,
                                  }),
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .tertiary,
                                      fontWeight: FontWeight.bold)),
                            ),
                            TextButton(
                              onPressed: () => showMetaResult(context, meta),
                              child: Text('View original text'.tr),
                            ),
                          ],
                        ),
                ),
            ],
            const SizedBox(height: 6),
            _invokedChips(context, s, i),
            TextField(
              controller: slotNotesCtrls[i],
              onChanged: (v) => s.notes = v,
              decoration: InputDecoration(
                  isDense: true,
                  labelText: 'Slot notes'.tr,
                  border: const OutlineInputBorder()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _invokedChips(BuildContext context, Slot s, int slotIdx) {
    final adv = widget.c.adv;
    final invoked = s.invoked
        .map((id) => adv.characters.entryById(id))
        .whereType<ListEntry>()
        .toList();
    return Wrap(
      spacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Invoked characters:'.tr,
            style: Theme.of(context).textTheme.bodySmall),
        for (final ch in invoked)
          Chip(
            label: Text(ch.name, style: const TextStyle(fontSize: 12)),
            onDeleted: () {
              s.invoked.remove(ch.id);
              widget.c.changed();
            },
          ),
        ActionChip(
          label: Text('Select'.tr, style: const TextStyle(fontSize: 12)),
          onPressed: () => _pickInvoked(context, s),
        ),
        Tooltip(
          message: 'Roll character list to invoke'.tr,
          child: ActionChip(
            avatar: const Icon(Icons.casino, size: 16),
            label: Text('Roll'.tr, style: const TextStyle(fontSize: 12)),
            onPressed: () {
              final settings = Get.find<GlobalSettingsService>();
              if (settings.getPhysicalDiceModeEnabled) {
                showListRollLookup(
                  context,
                  title: 'Character list'.tr,
                  list: adv.characters,
                  defaults: widget.c.rules.characterRowDefaults,
                  onSelect: (entry, pageIdx, rowIdx) => widget.c
                      .pickInvokedFromLookup(
                          widget.tp, slotIdx, entry, pageIdx, rowIdx, context),
                );
                return;
              }
              widget.c.rollInvokedCharacter(widget.tp, slotIdx, context);
            },
          ),
        ),
      ],
    );
  }

  Future<void> _pickInvoked(BuildContext context, Slot s) async {
    final entries = widget.c.adv.characters.entries;
    if (entries.isEmpty) {
      showSnack(context, 'The plotline list is empty.'.tr);
      return;
    }
    final selected = Set<int>.from(s.invoked);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Invoked characters:'.tr),
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
              child: Text('Cancel'.tr)),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text('OK'.tr)),
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
