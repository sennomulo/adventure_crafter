import 'package:get/get.dart';

import '../data/adventure.dart';
import 'adventure_service.dart';

class RollLogService extends GetxService {
  static const maxEntries = 200;

  Adventure? get _adv => Get.find<AdventureService>().current.value;

  void log(String label, String detail) {
    final adv = _adv;
    if (adv == null) return;
    adv.rollLog.insert(
        0,
        RollLogEntry(
            time: DateTime.now().toIso8601String(),
            label: label,
            detail: detail));
    if (adv.rollLog.length > maxEntries) {
      adv.rollLog.removeRange(maxEntries, adv.rollLog.length);
    }
    Get.find<AdventureService>().save();
  }

  void clear() {
    final adv = _adv;
    if (adv == null) return;
    adv.rollLog.clear();
    Get.find<AdventureService>().save();
  }
}
