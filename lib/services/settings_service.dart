import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GlobalSettingsService extends GetxService {
  static const _key = 'ac_allow_unlimited_count';

  final allowUnlimitedListCount = false.obs;

  int get maxWeight => allowUnlimitedListCount.value ? 1 << 30 : 3;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    allowUnlimitedListCount.value = prefs.getBool(_key) ?? false;
  }

  Future<void> setAllowUnlimitedListCount(bool value) async {
    allowUnlimitedListCount.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}
