import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/rules.dart';
import '../../helpers/engine.dart';
import '../../helpers/utils.dart';
import '../../services/adventure_service.dart';
import '../../services/settings_service.dart';
import '../tables/lookup_dialogs.dart';
import '../widgets/common.dart';

class ThemesPage extends StatelessWidget {
  const ThemesPage({super.key});

  static const _slotDieLabels = ['1-4', '5-7', '8-9', '10 (alt)', '10 (alt)'];

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
              Text('Adventure themes (priority 1-5)'.tr,
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Tooltip(
                message:
                    'Each click rolls 1d10 and fills one priority slot; click again for the next theme'
                        .tr,
                child: FilledButton.tonalIcon(
                  icon: const Icon(Icons.casino),
                  label: Text('Roll assembly'.tr),
                  onPressed: () {
                    final settings = Get.find<GlobalSettingsService>();
                    if (settings.getPhysicalDiceModeEnabled) {
                      showRandomThemeTableLookup(context, rules);
                    } else {
                      _assemble(context, service);
                    }
                  },
                ),
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
                  'Theme alternation counter: when the theme die rolls 10, the theme currently at priority @n is used, then it alternates with priority @m.'
                      .trParams({
                    'n': '$alternator',
                    'm': alternator == 4 ? '5' : '4',
                  }),
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
                    title: Text(set ? rules.themeName(themeId!) : 'Unset'.tr),
                    subtitle: Text(_slotDieLabels[i].tr),
                    trailing: set
                        ? IconButton(
                            tooltip:
                                'Remove (later priorities removed too)'.tr,
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              themes.removeRange(i, themes.length);
                              service.save();
                            },
                          )
                        : (next
                            ? DropdownButton<String>(
                                hint: Text('Pick theme'.tr),
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
                            : Text('Set a higher priority first'.tr,
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant))),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  void _assemble(BuildContext context, AdventureService service) {
    final rules = Get.find<RulesService>();
    final adv = service.current.value!;
    if (adv.themes.length >= 5) {
      showSnack(context, 'All 5 priority slots are set.'.tr);
      return;
    }
    final slotIndex = adv.themes.length;
    final die = rollDie(10);
    final direct = rules.randomThemes
        .firstWhere((o) => die >= o.min && die <= o.max)
        .theme;
    final theme = randomThemeForRoll(rules, die, adv.themes.toSet());
    if (theme == null) {
      showSnack(context, 'Cannot generate an unused theme.'.tr);
      return;
    }
    final shifted = theme != direct;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Priority @slot roll'.trParams({'slot': '${slotIndex + 1}'})),
        content: Text(
            '${shifted ? '1d10=@die → rolled "@direct" which is taken, ring-shifted to "@theme"'.trParams({'die': '$die', 'direct': rules.themeName(direct), 'theme': rules.themeName(theme)}) : '1d10=@die → "@theme"'.trParams({'die': '$die', 'theme': rules.themeName(theme)})}\n\n${'Fill this as priority @slot? Click "Roll assembly" again for the next theme.'.trParams({'slot': '${slotIndex + 1}'})}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel'.tr),
          ),
          FilledButton(
            onPressed: () {
              adv.themes.add(theme);
              service.logRoll(
                  'Random theme assembly'.tr,
                  '${'Priority @slot roll'.trParams({'slot': '${slotIndex + 1}'})}: 1d10=$die → ${rules.themeName(theme)}${shifted ? '(shifted)'.tr : ''}');
              service.save();
              Navigator.pop(dialogContext);
            },
            child: Text('Fill in'.tr),
          ),
        ],
      ),
    );
  }
}
