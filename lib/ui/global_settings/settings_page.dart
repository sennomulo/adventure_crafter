import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/rules.dart';
import '../../services/settings_service.dart';
import '../tables/lookup_dialogs.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<GlobalSettingsService>();
    final rules = Get.find<RulesService>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('设置', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Obx(() => SwitchListTile(
              title: const Text('允许条目权重超过 3'),
              subtitle: const Text('默认关闭：每个条目最多占用 3 行（仿原书可选规则）。开启后不限制。'),
              value: settings.allowUnlimitedListCount.value,
              onChanged: (v) => settings.setAllowUnlimitedListCount(v),
            )),
        const Divider(height: 32),
        Text('数据表浏览', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.table_chart_outlined),
          title: const Text('情节点表'),
          subtitle: const Text('全部情节点与各主题掷骰区间'),
          onTap: () => showPlotPointLookup(context, rules),
        ),
        ListTile(
          leading: const Icon(Icons.table_chart_outlined),
          title: const Text('元情节点表'),
          subtitle: const Text('情节点掷出 96-100 时触发'),
          onTap: () => showMetaTable(context, rules),
        ),
        ListTile(
          leading: const Icon(Icons.table_chart_outlined),
          title: const Text('特殊特质表'),
          onTap: () => showNumberedLookup(context, rules.traits, '特殊特质表'),
        ),
        ListTile(
          leading: const Icon(Icons.table_chart_outlined),
          title: const Text('身份表'),
          onTap: () => showNumberedLookup(context, rules.identities, '身份表'),
        ),
        ListTile(
          leading: const Icon(Icons.table_chart_outlined),
          title: const Text('描述词表'),
          onTap: () => showNumberedLookup(context, rules.descriptors, '描述词表'),
        ),
        const Divider(height: 32),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Adventure Crafter（冒险工匠助手）'),
          subtitle: const Text(
              '非官方粉丝工具。规则表数据来自《The Adventure Crafter》（Tana Pigeon 著，Word Mill Games）中文译本，版权归原作者所有。'),
        ),
      ],
    );
  }
}
