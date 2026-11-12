import 'dart:ui' show AppExitResponse;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'data/rules.dart';
import 'services/adventure_service.dart';
import 'services/roll_log_service.dart';
import 'services/settings_service.dart';
import 'ui/adventure_index/adventure_index_page.dart';

const kChineseFontFallback = ['Noto Sans SC'];

String _elapsedFromNow(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return '刚刚';
  if (d.inMinutes < 60) return '${d.inMinutes}分钟前';
  if (d.inHours < 24) return '${d.inHours}小时前';
  return '${d.inDays}天前';
}

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
    final last = Get.find<AdventureService>().lastSavedAt.value;
    final savedText = last == null
        ? '尚无保存记录。'
        : '数据上次保存于 '
            '${last.hour.toString().padLeft(2, '0')}:${last.minute.toString().padLeft(2, '0')}:${last.second.toString().padLeft(2, '0')}（${_elapsedFromNow(last)}）。';
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('退出 Adventure Crafter？'),
        content: Text('$savedText\n\n所有未保存的进度将会丢失。'),
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
