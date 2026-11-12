import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/adventure_service.dart';
import '../adventure/adventure_page.dart';
import '../global_settings/settings_page.dart';
import '../roll_log/roll_log_page.dart';
import '../widgets/common.dart';

class AdventureIndexPage extends StatelessWidget {
  const AdventureIndexPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = Get.find<AdventureService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adventure Crafter'),
        actions: [
          IconButton(
            tooltip: '掷骰日志',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => Scaffold(
                          appBar: AppBar(title: const Text('掷骰日志')),
                          body: const RollLogPage(),
                        ))),
          ),
          IconButton(
            tooltip: '设置',
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => Scaffold(
                          appBar: AppBar(title: const Text('设置')),
                          body: const SettingsPage(),
                        ))),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        final list = service.adventures;
        if (list.isEmpty) {
          return const Center(child: Text('还没有冒险。点击右下角「新建冒险」开始。'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final meta = list[i];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.auto_stories),
                title: Text(meta.title),
                subtitle: Text(meta.date.isEmpty ? '—' : meta.date),
                onTap: () async {
                  await service.open(meta.id);
                  if (!context.mounted) return;
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AdventurePage()));
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: '重命名',
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        final name = await textInputDialog(context, '重命名冒险',
                            initial: meta.title);
                        if (name == null || name.trim().isEmpty) return;
                        final adv = await service.open(meta.id);
                        if (adv == null) return;
                        adv.title = name.trim();
                        await service.save();
                        await service.refreshList();
                      },
                    ),
                    IconButton(
                      tooltip: '删除',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final ok = await confirmDialog(
                            context, '删除冒险', '确定删除「${meta.title}」？此操作不可恢复。');
                        if (!ok) return;
                        await service.remove(meta.id);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('新建冒险'),
        onPressed: () async {
          final name = await textInputDialog(context, '新建冒险', hint: '冒险标题');
          if (name == null) return;
          final adv = await service.create(name.trim());
          await service.open(adv.id);
          if (!context.mounted) return;
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AdventurePage()));
        },
      ),
    );
  }
}
