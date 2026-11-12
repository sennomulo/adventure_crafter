import 'dart:ui' show AppExitResponse;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'data/rules.dart';
import 'i18n/translations.dart';
import 'services/adventure_service.dart';
import 'services/roll_log_service.dart';
import 'services/settings_service.dart';
import 'ui/adventure_index/adventure_index_page.dart';

const kChineseFontFallback = ['Noto Sans SC'];

String _elapsedFromNow(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'just now'.tr;
  if (d.inMinutes < 60) return '${d.inMinutes}${'minutes ago'.tr}';
  if (d.inHours < 24) return '${d.inHours}${'hours ago'.tr}';
  return '${d.inDays}${'days ago'.tr}';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        ? 'No save record yet.'.tr
        : '${'Data was last saved at'.tr} '
            '${last.hour.toString().padLeft(2, '0')}:${last.minute.toString().padLeft(2, '0')}:${last.second.toString().padLeft(2, '0')}（${_elapsedFromNow(last)}）。';
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Quit Adventure Crafter?'.tr),
        content: Text('$savedText\n\n${'All unsaved progress will be lost.'.tr}'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancel'.tr),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: Text('Quit'.tr),
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
    final settings = Get.find<GlobalSettingsService>();
    final base = ThemeData(
      colorSchemeSeed: Colors.brown,
      useMaterial3: true,
      visualDensity: VisualDensity.comfortable,
    );
    final dark = base.copyWith(
      colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.brown, brightness: Brightness.dark),
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
