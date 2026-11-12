import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/rules.dart';
import '../../helpers/engine.dart';

Future<PlotPoint?> showPlotPointLookup(
    BuildContext context, RulesService rules) async {
  return showDialog<PlotPoint>(
    context: context,
    builder: (context) => _PlotPointLookupDialog(rules: rules),
  );
}

class _PlotPointLookupDialog extends StatefulWidget {
  final RulesService rules;
  const _PlotPointLookupDialog({required this.rules});

  @override
  State<_PlotPointLookupDialog> createState() => _PlotPointLookupDialogState();
}

class _PlotPointLookupDialogState extends State<_PlotPointLookupDialog> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final matches = widget.rules.plotPoints.where((p) {
      if (query.isEmpty) return true;
      return p.title.contains(query) || p.desc.contains(query);
    }).toList();
    return AlertDialog(
      title: Text('Plot point table'.tr),
      content: SizedBox(
        width: 560,
        height: 560,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search title or description'.tr,
                  border: const OutlineInputBorder()),
              onChanged: (v) => setState(() => query = v.trim()),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: matches.length,
                itemBuilder: (context, i) {
                  final pp = matches[i];
                  return ListTile(
                    dense: true,
                    title: Text(pp.title),
                    subtitle: Text(pp.rangesLabel(),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () async {
                      final detail = await showDialog<PlotPoint>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(pp.title),
                          content: SizedBox(
                            width: 420,
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(pp.rangesLabel(),
                                      style:
                                          Theme.of(context).textTheme.bodySmall),
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
                              onPressed: () => Navigator.pop(context, pp),
                              child: Text('Select'.tr),
                            ),
                          ],
                        ),
                      );
                      if (detail != null && context.mounted) {
                        Navigator.pop(context, detail);
                      }
                    },
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
