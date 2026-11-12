import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'data/rules.dart';
import 'services/adventure_service.dart';
import 'services/roll_log_service.dart';
import 'services/settings_service.dart';
import 'ui/adventure_index/adventure_index_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final rules = RulesService();
  await rules.load();
  final settings = GlobalSettingsService();
  await settings.load();
  Get.put(rules);
  Get.put(settings);
  Get.put(RollLogService());
  final adventureService = Get.put(AdventureService());
  await adventureService.refreshList();
  runApp(const AdventureCrafterApp());
}

class AdventureCrafterApp extends StatelessWidget {
  const AdventureCrafterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Adventure Crafter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.brown,
        useMaterial3: true,
        visualDensity: VisualDensity.comfortable,
      ),
      home: const AdventureIndexPage(),
    );
  }
}
