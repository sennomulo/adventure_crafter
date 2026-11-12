import 'package:flutter/material.dart';

import '../../data/rules.dart';

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
      title: const Text('情节点表'),
      content: SizedBox(
        width: 560,
        height: 560,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: '搜索标题或描述',
                  border: OutlineInputBorder()),
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
                              child: const Text('返回'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, pp),
                              child: const Text('选用'),
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
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭')),
      ],
    );
  }
}

Future<NumberedEntry?> showNumberedLookup(BuildContext context,
    List<NumberedEntry> list, String title) async {
  return showDialog<NumberedEntry>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 480,
        height: 520,
        child: ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, i) {
            final e = list[i];
            return ExpansionTile(
              dense: true,
              title: Text('${e.min}-${e.max}　${e.text}'),
              subtitle: e.desc == null ? null : const Text('点开查看原文说明',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
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
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭')),
      ],
    ),
  );
}

void showMetaTable(BuildContext context, RulesService rules) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('元情节点表'),
      content: SizedBox(
        width: 480,
        height: 420,
        child: ListView(
          children: rules.metaPlotPoints
              .map((m) => ExpansionTile(
                    dense: true,
                    title: Text('${m.min}-${m.max}　${m.title}'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭')),
      ],
    ),
  );
}

void showMetaResult(BuildContext context, MetaPlotPoint meta, {int? roll}) {  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('元情节点${roll == null ? '' : '（1d100=$roll）'}：${meta.title}'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(meta.desc),
              const SizedBox(height: 8),
              Text('以上为原文规则说明，副作用不自动执行，由玩家自行处置。',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('确定')),
      ],
    ),
  );
}
