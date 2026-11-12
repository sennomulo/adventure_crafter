import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/rules.dart';
import '../../helpers/engine.dart';
import '../../helpers/utils.dart';
import '../../services/adventure_service.dart';
import '../widgets/common.dart';

class ThemesPage extends StatelessWidget {
  const ThemesPage({super.key});

  static const _slotDieLabels = ['主题骰 1-4', '主题骰 5-7', '主题骰 8-9', '主题骰 10（交替）', '主题骰 10（交替）'];

  @override
  Widget build(BuildContext context) {
    final rules = Get.find<RulesService>();
    final service = Get.find<AdventureService>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text('冒险主题（按优先级 1-5）',
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.casino),
                label: const Text('掷骰装配'),
                onPressed: () {
                  final themes = service.current.value!.themes;
                  if (themes.isNotEmpty) {
                    _confirmAssemble(context, service);
                  } else {
                    _assemble(context, service);
                  }
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Obx(() {
                final alternator = service.current.value!.alternator;
                return Text(
                  '主题交替计数器：主题骰掷出 10 时，使用当前第 $alternator 优先的主题，随后与第 ${alternator == 4 ? 5 : 4} 优先位自动交替。',
                  style: Theme.of(context).textTheme.bodySmall,
                );
              }),
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            final adv = service.current.value!;
            final themes = adv.themes;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (context, i) {
                final set = i < themes.length;
                final next = i == themes.length;
                final themeId = set ? themes[i] : null;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${i + 1}')),
                    title: Text(set ? rules.themeName(themeId!) : '未设置'),
                    subtitle: Text(_slotDieLabels[i]),
                    trailing: set
                        ? IconButton(
                            tooltip: '移除（其后优先位一并移除）',
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              themes.removeRange(i, themes.length);
                              service.save();
                            },
                          )
                        : (next
                            ? DropdownButton<String>(
                                hint: const Text('选择主题'),
                                items: RulesService.themeOrder
                                    .where((t) => !themes.contains(t))
                                    .map((t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(rules.themeName(t))))
                                    .toList(),
                                onChanged: (t) {
                                  if (t == null) return;
                                  themes.add(t);
                                  service.save();
                                },
                              )
                            : const Text('先设置更高优先位',
                                style: TextStyle(color: Colors.grey))),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  void _confirmAssemble(BuildContext context, AdventureService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重新装配主题'),
        content: const Text('将掷骰重新填充全部 5 个优先位，覆盖现有主题。确定？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _assemble(context, service);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _assemble(BuildContext context, AdventureService service) {
    final rules = Get.find<RulesService>();
    final adv = service.current.value!;
    final used = <String>{};
    final result = <String>[];
    for (var i = 0; i < 5; i++) {
      final die = rollDie(10);
      final theme = randomThemeForRoll(rules, die, used);
      if (theme == null) break;
      used.add(theme);
      result.add(theme);
      service.logRoll('随机主题装配', '第${i + 1}优先：1d10=$die → ${rules.themeName(theme)}');
    }
    adv.themes
      ..clear()
      ..addAll(result);
    service.save();
    showSnack(context, '已装配 ${result.length} 个主题');
  }
}
