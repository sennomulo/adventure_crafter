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
        Text('Settings'.tr, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Obx(() => SwitchListTile(
              title: Text('Allow entry weight above 3'.tr),
              subtitle:
                  Text('Default off: each entry occupies at most 3 rows (optional rule from the book). Turn on to remove the cap.'.tr),
              value: settings.allowUnlimitedListCount.value,
              onChanged: (v) => settings.setAllowUnlimitedListCount(v),
            )),
        Obx(() => SwitchListTile(
              title: Text('Dark mode'.tr),
              value: settings.darkMode.value,
              onChanged: (v) => settings.setDarkMode(v),
            )),
        Obx(() => SwitchListTile(
              title: Text('Physical dice mode'.tr),
              subtitle: Text(
                  'Roll buttons open lookup tables instead: roll your physical dice and read the result from the table. The software rolls nothing and logs nothing.'
                      .tr),
              value: settings.physicalDiceMode.value,
              onChanged: (v) async {
                await settings.setPhysicalDiceMode(v);
                if (v && !settings.physicalDiceModeExplained.value) {
                  await settings.setPhysicalDiceModeExplained(true);
                  if (!context.mounted) return;
                  await showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: Text('Physical dice mode'.tr),
                      content: Text(
                          'With physical dice mode on, roll buttons open lookup tables: roll your physical dice, then find the result in the table.'
                              .tr),
                      actions: [
                        FilledButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text('Got it'.tr),
                        ),
                      ],
                    ),
                  );
                }
              },
            )),
        Obx(() => ListTile(
              title: Text('Language'.tr),
              subtitle: Text(settings.uiLanguage.value == 'en'
                  ? 'English'.tr
                  : 'Chinese'.tr),
              trailing: DropdownButton<String>(
                value: settings.uiLanguage.value,
                items: [
                  DropdownMenuItem(value: 'zh', child: Text('Chinese'.tr)),
                  DropdownMenuItem(value: 'en', child: Text('English'.tr)),
                ],
                onChanged: (v) async {
                  if (v == null) return;
                  await settings.setLanguage(v);
                  Get.updateLocale(v == 'en'
                      ? const Locale('en', 'US')
                      : const Locale('zh', 'CN'));
                },
              ),
            )),
        const Divider(height: 32),
        Text('Browse data tables'.tr,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.table_chart_outlined),
          title: Text('Plot point table'.tr),
          subtitle: Text('All plot points with per-theme roll ranges'.tr),
          onTap: () => showPlotPointLookup(context, rules),
        ),
        ListTile(
          leading: const Icon(Icons.table_chart_outlined),
          title: Text('Meta plot point table'.tr),
          subtitle: Text('Triggered when a plot point roll is 96-100'.tr),
          onTap: () => showMetaTable(context, rules),
        ),
        ListTile(
          leading: const Icon(Icons.table_chart_outlined),
          title: Text('Special trait table'.tr),
          onTap: () => showNumberedLookup(context, rules.traits, 'Special trait table'.tr),
        ),
        ListTile(
          leading: const Icon(Icons.table_chart_outlined),
          title: Text('Identity table'.tr),
          onTap: () => showNumberedLookup(context, rules.identities, 'Identity table'.tr),
        ),
        ListTile(
          leading: const Icon(Icons.table_chart_outlined),
          title: Text('Descriptor table'.tr),
          onTap: () => showNumberedLookup(context, rules.descriptors, 'Descriptor table'.tr),
        ),
        const Divider(height: 32),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text('Adventure Crafter (assistant)'.tr),
          subtitle: Text(
              'Unofficial fan tool. Rule data comes from the Chinese translation of "The Adventure Crafter" (by Tana Pigeon, Word Mill Games); all rights belong to the original authors.'
                  .tr),
        ),
      ],
    );
  }
}
