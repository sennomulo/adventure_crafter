import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/adventure.dart';
import '../../services/adventure_service.dart';
import '../adventure/adventure_page.dart';
import '../global_settings/settings_page.dart';
import '../help/help_dialog.dart';
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
            tooltip: 'How to use the Adventure Crafter'.tr,
            icon: const Icon(Icons.help_outline),
            onPressed: () => showHelpDialog(context),
          ),
          IconButton(
            tooltip: 'Settings'.tr,
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => Scaffold(
                          appBar: AppBar(title: Text('Settings'.tr)),
                          body: const SettingsPage(),
                        ))),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        final list = service.adventures;
        if (list.isEmpty) {
          return Center(
              child: Text('No adventures yet. Tap "New adventure" at the bottom right to start.'
                  .tr));
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
                      tooltip: 'Rename'.tr,
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        final name = await textInputDialog(
                            context, 'Rename adventure'.tr,
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
                      tooltip: 'Delete'.tr,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        final ok = await confirmDialog(
                            context,
                            'Delete adventure'.tr,
                            'Delete adventure "@title"? This cannot be undone.'
                                .trParams({'title': meta.title}));
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
        label: Text('New adventure'.tr),
        onPressed: () => _newAdventureDialog(context, service),
      ),
    );
  }

  Future<void> _newAdventureDialog(
      BuildContext context, AdventureService service) async {
    final titleCtrl = TextEditingController();
    String? sourceId;
    final metas = service.adventures.toList();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text('New adventure'.tr),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                autofocus: true,
                decoration: InputDecoration(
                    hintText: 'Adventure title'.tr,
                    border: const OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: sourceId,
                decoration: InputDecoration(
                    labelText: 'Carry over lists from a previous adventure'.tr,
                    helperText:
                        'Copies the plotline and character lists, including weights.'
                            .tr,
                    border: const OutlineInputBorder()),
                items: [
                  DropdownMenuItem<String?>(
                      value: null, child: Text('Start fresh'.tr)),
                  for (final m in metas)
                    DropdownMenuItem<String?>(value: m.id, child: Text(m.title)),
                ],
                onChanged: (v) => setState(() => sourceId = v),
              ),
            ],
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
      ),
    );
    if (ok != true) return;
    final name = titleCtrl.text.trim();
    if (name.isEmpty) return;
    final adv = await service.create(name);
    if (sourceId != null) {
      final srcContent = await service.storage.read(sourceId!);
      if (srcContent != null) {
        adv.seedListsFrom(Adventure.fromJsonString(srcContent));
        await service.save();
      }
    }
    await service.open(adv.id);
    if (!context.mounted) return;
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const AdventurePage()));
  }
}
