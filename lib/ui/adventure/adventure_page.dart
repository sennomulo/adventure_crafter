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
    final destinations = [
      NavigationRailDestination(icon: const Icon(Icons.palette_outlined), selectedIcon: const Icon(Icons.palette), label: Text('Themes'.tr)),
      NavigationRailDestination(icon: const Icon(Icons.account_tree_outlined), selectedIcon: const Icon(Icons.account_tree), label: Text('Plotlines'.tr)),
      NavigationRailDestination(icon: const Icon(Icons.groups_outlined), selectedIcon: const Icon(Icons.groups), label: Text('Characters'.tr)),
      NavigationRailDestination(icon: const Icon(Icons.bolt_outlined), selectedIcon: const Icon(Icons.bolt), label: Text('Turning points'.tr)),
      NavigationRailDestination(icon: const Icon(Icons.casino_outlined), selectedIcon: const Icon(Icons.casino), label: Text('Cast character'.tr)),
      NavigationRailDestination(icon: const Icon(Icons.history), selectedIcon: const Icon(Icons.history), label: Text('Roll log'.tr)),
      NavigationRailDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings), label: Text('Settings'.tr)),
    ];
    final pages = const [
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
        body: Row(
          children: [
            Obx(() => NavigationRail(
                  selectedIndex: controller.index.value,
                  onDestinationSelected: (i) => controller.index.value = i,
                  labelType: NavigationRailLabelType.all,
                  destinations: destinations,
                )),
            const VerticalDivider(width: 1),
            Expanded(
              child: IndexedStack(index: controller.index.value, children: pages),
            ),
          ],
        ),
      );
    });
  }
}
