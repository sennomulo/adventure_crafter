import 'dart:ui' show AppExitResponse;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'data/rules.dart';
import 'services/adventure_service.dart';
import 'services/roll_log_service.dart';
import 'services/settings_service.dart';
import 'ui/adventure_index/adventure_index_page.dart';

const kChineseFontFallback = ['Noto Sans SC'];

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
  runApp(const ExitGuard(child: AdventureCrafterApp()));
}

class ExitGuard extends StatefulWidget {
  final Widget child;

  const ExitGuard({super.key, required this.child});

  @override
  State<ExitGuard> createState() => _ExitGuardState();
}

class _ExitGuardState extends State<ExitGuard> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(onExitRequested: _onExitRequested);
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  Future<AppExitResponse> _onExitRequested() async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('退出 Adventure Crafter？'),
        content: const Text('冒险进度已自动保存。确定退出吗？'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('退出'),
          ),
        ],
      ),
    );
    return (result ?? false) ? AppExitResponse.exit : AppExitResponse.cancel;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class AdventureCrafterApp extends StatelessWidget {
  const AdventureCrafterApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      colorSchemeSeed: Colors.brown,
      useMaterial3: true,
      visualDensity: VisualDensity.comfortable,
    );
    return GetMaterialApp(
      title: 'Adventure Crafter',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: base.textTheme.apply(fontFamilyFallback: kChineseFontFallback),
      ),
      home: const AdventureIndexPage(),
    );
  }
}
