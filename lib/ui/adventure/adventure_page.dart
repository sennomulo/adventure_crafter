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

class AdventurePage extends StatelessWidget {
  const AdventurePage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = Get.find<AdventureService>();
    final controller = Get.put(AdventurePageController());
    final destinations = const [
      NavigationRailDestination(icon: Icon(Icons.palette_outlined), selectedIcon: Icon(Icons.palette), label: Text('主题')),
      NavigationRailDestination(icon: Icon(Icons.account_tree_outlined), selectedIcon: Icon(Icons.account_tree), label: Text('情节线')),
      NavigationRailDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: Text('角色')),
      NavigationRailDestination(icon: Icon(Icons.bolt_outlined), selectedIcon: Icon(Icons.bolt), label: Text('转折点')),
      NavigationRailDestination(icon: Icon(Icons.casino_outlined), selectedIcon: Icon(Icons.casino), label: Text('角色铸造')),
      NavigationRailDestination(icon: Icon(Icons.history), selectedIcon: Icon(Icons.history), label: Text('日志')),
      NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('设置')),
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
          body: const Center(child: Text('未打开任何冒险')),
        );
      }
      return Scaffold(
        appBar: AppBar(
          title: Obx(() {
            final a = service.current.value;
            return Text(a == null ? 'Adventure Crafter' : a.title);
          }),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(child: Text('自动保存', style: TextStyle(fontSize: 12))),
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
