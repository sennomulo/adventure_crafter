import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';

import 'data/rules.dart';
import 'helpers/app_exit.dart';
import 'i18n/translations.dart';
import 'services/adventure_service.dart';
import 'services/backup_service.dart';
import 'services/roll_log_service.dart';
import 'services/settings_service.dart';
import 'ui/adventure_index/adventure_index_page.dart';

const kChineseFontFallback = ['Noto Sans SC'];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (GetPlatform.isDesktop) {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      title: 'Adventure Crafter',
      size: Size(1280, 800),
      minimumSize: Size(400, 600),
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.setPreventClose(true);
      windowManager.addListener(AppWindowListener());
      await windowManager.show();
      await windowManager.focus();
    });
  }
  final rules = RulesService();
  await rules.load();
  final settings = GlobalSettingsService();
  await settings.load();
  Get.put(rules);
  Get.put(settings);
  Get.updateLocale(
      settings.uiLanguage.value == 'en'
          ? const Locale('en', 'US')
          : const Locale('zh', 'CN'));
  Get.put(RollLogService());
  Get.put(BackupService());
  final adventureService = Get.put(AdventureService());
  await adventureService.refreshList();
  runApp(const AdventureCrafterApp());
}

/// 退出流程（无拦截弹窗）：数据随每次改动即时自动保存，
/// 关闭窗口时补一次静默保存兜底，保存完成后立即终止进程。
/// 不用 windowManager.destroy()：实测其通道调用拖慢退出（约 6s）；
/// 不用 SystemNavigator.pop()：Windows 桌面端无法退出进程。
class AppWindowListener with WindowListener {
  @override
  void onWindowClose() async {
    try {
      await Get.find<AdventureService>().save();
    } catch (_) {}
    forceExit();
  }
}

class AdventureCrafterApp extends StatelessWidget {
  const AdventureCrafterApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<GlobalSettingsService>();
    final base = ThemeData(
      colorSchemeSeed: Colors.brown,
      useMaterial3: true,
      visualDensity: VisualDensity.comfortable,
    );
    // 深色主题必须独立构造：copyWith(colorScheme:) 不会重算
    // scaffoldBackgroundColor/dialogBackgroundColor/textTheme 等派生字段，
    // 会残留亮色值导致深色模式错乱。
    final dark = ThemeData(
      colorSchemeSeed: Colors.brown,
      brightness: Brightness.dark,
      useMaterial3: true,
      visualDensity: VisualDensity.comfortable,
    );
    return Obx(() => GetMaterialApp(
          title: 'Adventure Crafter',
          debugShowCheckedModeBanner: false,
          translations: AppTranslations(),
          fallbackLocale: const Locale('en', 'US'),
          locale: settings.uiLanguage.value == 'en'
              ? const Locale('en', 'US')
              : const Locale('zh', 'CN'),
          theme: base.copyWith(
            textTheme:
                base.textTheme.apply(fontFamilyFallback: kChineseFontFallback),
          ),
          darkTheme: dark.copyWith(
            textTheme:
                dark.textTheme.apply(fontFamilyFallback: kChineseFontFallback),
          ),
          themeMode:
              settings.darkMode.value ? ThemeMode.dark : ThemeMode.light,
          home: const AdventureIndexPage(),
        ));
  }
}
