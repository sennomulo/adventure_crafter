import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/rules.dart';
import '../../helpers/engine.dart';

Future<PlotPoint?> showPlotPointLookup(
    BuildContext context, RulesService rules,
    {String? initialTheme}) async {
  return showDialog<PlotPoint>(
    context: context,
    builder: (context) =>
        _PlotPointLookupDialog(rules: rules, initialTheme: initialTheme),
  );
}

/// 情节点表查询：先选主题，再显示该主题下的情节点；支持输入 1-100 索引定位。
class _PlotPointLookupDialog extends StatefulWidget {
  final RulesService rules;
  final String? initialTheme;
  const _PlotPointLookupDialog({required this.rules, this.initialTheme});

  @override
  State<_PlotPointLookupDialog> createState() => _PlotPointLookupDialogState();
}

class _PlotPointLookupDialogState extends State<_PlotPointLookupDialog> {
  String? selectedTheme;
  String? highlightId;
  Timer? _highlightTimer;
  final _scroll = ScrollController();
  final _indexCtrl = TextEditingController();
  static const _itemExtent = 64.0;

  @override
  void initState() {
    super.initState();
    selectedTheme = widget.initialTheme;
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _scroll.dispose();
    _indexCtrl.dispose();
    super.dispose();
  }

  List<PlotPoint> get themed {
    final t = selectedTheme;
    if (t == null) return const [];
    final list = widget.rules.plotPoints
        .where((p) => p.ranges[t] != null)
        .toList()
      ..sort((a, b) =>
          a.ranges[t]!.min.compareTo(b.ranges[t]!.min));
    return list;
  }

  void _selectTheme(String t) {
    _highlightTimer?.cancel();
    setState(() {
      selectedTheme = t;
      highlightId = null;
    });
  }

  void _jumpToIndex() {
    final t = selectedTheme;
    if (t == null) return;
    final v = int.tryParse(_indexCtrl.text.trim());
    if (v == null || v < 1 || v > 100) return;
    final list = themed;
    final idx = list.indexWhere((p) => p.ranges[t]!.contains(v));
    if (idx < 0) return;
    final target =
        (idx * _itemExtent).clamp(0.0, _scroll.position.maxScrollExtent);
    _scroll.animateTo(target,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    _highlightTimer?.cancel();
    setState(() => highlightId = list[idx].id);
    _highlightTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => highlightId = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = selectedTheme;
    final list = themed;
    return AlertDialog(
      title: Text('Plot point table'.tr),
      content: SizedBox(
        width: 560,
        height: 560,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final theme in RulesService.themeOrder)
                  ChoiceChip(
                    label: Text(widget.rules.themeName(theme)),
                    selected: t == theme,
                    onSelected: (_) => _selectTheme(theme),
                  ),
              ],
            ),
            if (t != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    width: 150,
                    child: TextField(
                      controller: _indexCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Index 1-100'.tr,
                          border: const OutlineInputBorder()),
                      onSubmitted: (_) => _jumpToIndex(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _jumpToIndex,
                    child: Text('Locate'.tr),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Expanded(
              child: t == null
                  ? Center(child: Text('Select a theme to view its plot points.'.tr))
                  : ListView.builder(
                      controller: _scroll,
                      itemExtent: _itemExtent,
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final pp = list[i];
                        final range = pp.ranges[t]!;
                        final highlighted = highlightId == pp.id;
                        return Container(
                          color: highlighted
                              ? Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer
                              : Colors.transparent,
                          child: ListTile(
                            dense: true,
                            title: Text('${range.min}-${range.max}　${pp.title}'),
                            onTap: () async {
                              final detail = await showDialog<PlotPoint>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(pp.title),
                                  content: SizedBox(
                                    width: 420,
                                    child: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(pp.rangesLabel(),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall),
                                          const SizedBox(height: 8),
                                          Text(pp.desc),
                                        ],
                                      ),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('Back'.tr),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(context, pp),
                                      child: Text('Select'.tr),
                                    ),
                                  ],
                                ),
                              );
                              if (detail != null && context.mounted) {
                                Navigator.pop(context, detail);
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text('Close'.tr)),
      ],
    );
  }
}

/// [onSelect] 非空时进入"实体骰确认"模式：条目后出现确认按钮，点击即确认出目。
Future<NumberedEntry?> showNumberedLookup(BuildContext context,
    List<NumberedEntry> list, String title,
    {void Function(NumberedEntry e)? onSelect}) async {
  return showDialog<NumberedEntry>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 480,
        height: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (onSelect != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                    'Physical dice: pick the row matching your roll to confirm.'
                        .tr,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final e = list[i];
                  return ExpansionTile(
                    dense: true,
                    title: Text('${e.min}-${e.max}　${e.text}'),
                    subtitle: e.desc == null
                        ? null
                        : Text('Tap to view original text'.tr,
                            style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant)),
                    trailing: onSelect == null
                        ? null
                        : IconButton(
                            tooltip: 'Select'.tr,
                            icon: const Icon(Icons.check_circle_outline),
                            onPressed: () {
                              Navigator.pop(context);
                              onSelect(e);
                            },
                          ),
                    children: [
                      if (e.desc != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(e.desc!),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Close'.tr)),
      ],
    ),
  );
}

void showMetaTable(BuildContext context, RulesService rules,
    {void Function(MetaPlotPoint meta)? onPick}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Meta plot point table'.tr),
      content: SizedBox(
        width: 480,
        height: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (onPick != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                    'Physical dice: pick the row matching your roll to confirm.'
                        .tr,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            Expanded(
              child: ListView(
                children: rules.metaPlotPoints
                    .map((m) => ExpansionTile(
                          dense: true,
                          title: Text('${m.min}-${m.max}　${m.title}'),
                          trailing: onPick == null
                              ? null
                              : IconButton(
                                  tooltip: 'Select'.tr,
                                  icon: const Icon(Icons.check_circle_outline),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    onPick(m);
                                  },
                                ),
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(m.desc),
                              ),
                            ),
                          ],
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Close'.tr)),
      ],
    ),
  );
}

void showMetaResult(BuildContext context, MetaPlotPoint meta, {int? roll}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Meta plot point (1d100=@roll): @title'.trParams({
        'roll': roll == null ? '' : '$roll',
        'title': meta.title,
      })),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(meta.desc),
              const SizedBox(height: 8),
              Text(
                  'The above is the original rule text; side effects are not executed automatically and are handled by the player.'
                      .tr,
                  style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(onPressed: () => Navigator.pop(context), child: Text('OK'.tr)),
      ],
    ),
  );
}

void showRandomThemeTableLookup(BuildContext context, RulesService rules) {
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Random theme table (1d10)'.tr),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Physical dice: roll yourself and read the result from the table.'
                .tr),
            const SizedBox(height: 8),
            for (final o in rules.randomThemes)
              ListTile(
                dense: true,
                leading: SizedBox(
                    width: 56,
                    child: Text(
                        o.min == o.max ? '${o.min}' : '${o.min}-${o.max}')),
                title: Text(rules.themeName(o.theme)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Close'.tr)),
      ],
    ),
  );
}

/// 实体骰模式的主题骰映射表：玩家掷 1d10 后点选对应行即确认，
/// 确认后由调用方打开情节点表选择情节点。
/// [alternator] 为冒险当前的交替指针（1~4），用于"10 → 交替位"行。
Future<void> showPhysicalSlotLookup(
  BuildContext context,
  RulesService rules,
  List<String> themes,
  int alternator, {
  required void Function(int die, String themeId) onSelected,
}) async {
  final rows = [
    ('1-4', 1, '1-4 → priority 1 (@theme)'),
    ('5-7', 5, '5-7 → priority 2 (@theme)'),
    ('8-9', 8, '8-9 → priority 3 (@theme)'),
    ('10', 10, '10 → alternator (@theme)'),
  ];
  await showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Theme die (1d10)'.tr),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Physical dice: pick the row matching your roll to confirm.'
                .tr),
            const SizedBox(height: 8),
            for (final (label, die, key) in rows)
              Builder(builder: (context) {
                final theme = themeForDieRoll(rules, themes, die, alternator);
                final themeLabel =
                    theme == null ? 'Unset'.tr : rules.themeName(theme);
                return ListTile(
                  dense: true,
                  enabled: theme != null,
                  leading: SizedBox(width: 56, child: Text(label)),
                  title: Text(key.trParams({'theme': themeLabel})),
                  onTap: theme == null
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                          onSelected(die, theme);
                        },
                );
              }),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Close'.tr)),
      ],
    ),
  );
}
