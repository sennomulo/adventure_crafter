import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/adventure_service.dart';
import '../cast_character/cast_character_page.dart';
import '../characters/paged_list_page.dart';
import '../global_settings/settings_page.dart';
import '../roll_log/roll_log_page.dart';
import '../themes/themes_page.dart';
import '../turning_points/turning_points_page.dart';

class AdventurePageController extends GetxController {
  final index = 0.obs;
}

void goToAdventureTab(int index) {
  if (Get.isRegistered<AdventurePageController>()) {
    Get.find<AdventurePageController>().index.value = index;
  }
}

class AdventurePage extends StatelessWidget {
  const AdventurePage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = Get.find<AdventureService>();
    final controller = Get.put(AdventurePageController());
    final tabs = <(IconData, IconData, String)>[
      (Icons.palette_outlined, Icons.palette, 'Themes'),
      (Icons.account_tree_outlined, Icons.account_tree, 'Plotlines'),
      (Icons.groups_outlined, Icons.groups, 'Characters'),
      (Icons.bolt_outlined, Icons.bolt, 'Turning points'),
      (Icons.casino_outlined, Icons.casino, 'Cast character'),
      (Icons.history, Icons.history, 'Roll log'),
      (Icons.settings_outlined, Icons.settings, 'Settings'),
    ];
    final destinations = [
      for (final (icon, selected, label) in tabs)
        NavigationRailDestination(
            icon: Icon(icon),
            selectedIcon: Icon(selected),
            label: Text(label.tr)),
    ];
    final pagesList = const [
      ThemesPage(),
      PagedListPage(isPlotline: true),
      PagedListPage(isPlotline: false),
      TurningPointsPage(),
      CastCharacterPage(),
      RollLogPage(),
      SettingsPage(),
    ];
    return Obx(() {
      final adv = service.current.value;
      if (adv == null) {
        return Scaffold(
          appBar: AppBar(),
          body: Center(child: Text('No adventure opened'.tr)),
        );
      }
      return Scaffold(
        appBar: AppBar(
          title: Obx(() {
            final a = service.current.value;
            return Text(a == null ? 'Adventure Crafter' : a.title);
          }),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                  child:
                      Text('Auto-save'.tr, style: const TextStyle(fontSize: 12))),
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final pagesView = IndexedStack(
                index: controller.index.value, children: pagesList);
            if (width < 600) {
              return Column(
                children: [
                  Expanded(child: pagesView),
                  Obx(() => NavigationBar(
                        selectedIndex: controller.index.value,
                        onDestinationSelected: (i) =>
                            controller.index.value = i,
                        destinations: [
                          for (final (icon, selected, label) in tabs)
                            NavigationDestination(
                                icon: Icon(icon),
                                selectedIcon: Icon(selected),
                                label: label.tr),
                        ],
                      )),
                ],
              );
            }
            return Row(
              children: [
                Obx(() => NavigationRail(
                      selectedIndex: controller.index.value,
                      onDestinationSelected: (i) => controller.index.value = i,
                      extended: width > 1100,
                      labelType: width > 1100
                          ? NavigationRailLabelType.none
                          : NavigationRailLabelType.all,
                      destinations: destinations,
                    )),
                const VerticalDivider(width: 1),
                Expanded(child: pagesView),
              ],
            );
          },
        ),
      );
    });
  }
}
