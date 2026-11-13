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
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20),
                    const SizedBox(width: 8),
                    Text('Adventure Crafter (assistant)'.tr,
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                    'Unofficial fan tool based on "The Adventure Crafter" by Tana Pigeon, published by Word Mill Games. Rule text and tables from the book are used under the Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0) license, pursuant to the Word Mill Games CC-BY-NC policy (www.wordmillgames.com/license.html); the license covers text only. Find out more at www.wordmillgames.com.'
                        .tr,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                Text(
                    'Modifications: selected rule tables and texts were translated into Chinese and integrated into this software (including the data files under assets/rules/, also provided under CC BY-NC 4.0). The full Chinese translation of the book was produced by the maintainer with AI assistance for personal use only and is not distributed with this software.'
                        .tr,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                Text(
                    'Disclaimer: unofficial fan project, not affiliated with or endorsed by Word Mill Games or Tana Pigeon. All third-party trademarks belong to their respective owners.'
                        .tr,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                Text(
                    'Software code: PolyForm Noncommercial License 1.0.0. Rule content from The Adventure Crafter (including the assets/rules/ data files): CC BY-NC 4.0.'
                        .tr,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
