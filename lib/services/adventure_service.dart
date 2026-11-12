import 'package:get/get.dart';

import '../data/adventure.dart';
import '../data/rules.dart';
import '../helpers/engine.dart';
import '../helpers/utils.dart';
import '../storage/app_storage.dart';
import 'roll_log_service.dart';

class AdventureService extends GetxService {
  final storage = createStorage();
  final adventures = <AdventureMeta>[].obs;
  final current = Rx<Adventure?>(null);

  Future<void> refreshList() async {
    adventures.assignAll(await storage.listAll());
  }

  Future<Adventure?> open(String id) async {
    final content = await storage.read(id);
    if (content == null) return null;
    final adv = Adventure.fromJsonString(content);
    current.value = adv;
    return adv;
  }

  Future<Adventure> create(String title) async {
    final now = DateTime.now();
    final adv = Adventure(
      id: 'a${now.millisecondsSinceEpoch}',
      title: title.isEmpty ? '未命名冒险' : title,
      date: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
    );
    current.value = adv;
    await save();
    await refreshList();
    return adv;
  }

  Future<void> save() async {
    final adv = current.value;
    if (adv == null) return;
    await storage.write(adv.id, adv.toJsonString());
  }

  Future<void> remove(String id) async {
    await storage.delete(id);
    if (current.value?.id == id) current.value = null;
    await refreshList();
  }

  void logRoll(String label, String detail) => Get.find<RollLogService>().log(label, detail);

  RollOutcome? rollPlotPoint(Adventure adv) {
    final rules = Get.find<RulesService>();
    final themes = adv.themes;
    if (themes.isEmpty) return null;
    final die = rollDie(10);
    final theme = themeForDieRoll(rules, themes, die, adv.alternator);
    final slot = prioritySlotForDie(rules, die);
    logRoll('主题骰', '1d10=$die → ${theme == null ? '主题未设置' : '${rules.themeName(theme)}（第${slot == 0 ? adv.alternator : slot}优先）'}');
    if (theme == null) return null;
    if (die == 10) {
      adv.alternator = adv.alternator == 4 ? 5 : 4;
    }
    final roll = roll100();
    final pp = rules.plotPointAt(theme, roll);
    logRoll('情节点掷骰', '1d100=$roll（${rules.themeName(theme)}）→ ${pp.id == 'meta' ? '元情节点！' : pp.title}');
    if (pp.id == 'meta') {
      final metaRoll = roll100();
      final meta = rules.metaAt(metaRoll);
      logRoll('元情节点', '1d100=$metaRoll → ${meta.title}');
      return RollOutcome(
          theme: theme,
          themeDie: die,
          roll: roll,
          plotPoint: pp,
          meta: meta,
          metaRoll: metaRoll);
    }
    return RollOutcome(theme: theme, themeDie: die, roll: roll, plotPoint: pp);
  }
}

class RollOutcome {
  final String theme;
  final int themeDie;
  final int roll;
  final PlotPoint plotPoint;
  final MetaPlotPoint? meta;
  final int? metaRoll;

  RollOutcome({
    required this.theme,
    required this.themeDie,
    required this.roll,
    required this.plotPoint,
    this.meta,
    this.metaRoll,
  });
}
