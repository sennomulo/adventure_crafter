import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GlobalSettingsService extends GetxService {
  static const _keyUnlimited = 'ac_allow_unlimited_count';
  static const _keyDarkMode = 'ac_dark_mode';
  static const _keyLanguage = 'ac_language';
  static const _keyPhysicalDice = 'ac_physical_dice_mode';
  static const _keyPhysicalDiceExplained = 'ac_physical_dice_explained';

  final allowUnlimitedListCount = false.obs;
  final darkMode = false.obs;
  final uiLanguage = 'zh'.obs;
  final physicalDiceMode = false.obs;
  final physicalDiceModeExplained = false.obs;

  int get maxWeight => allowUnlimitedListCount.value ? 1 << 30 : 3;

  bool get getPhysicalDiceModeEnabled => physicalDiceMode.value;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    allowUnlimitedListCount.value = prefs.getBool(_keyUnlimited) ?? false;
    darkMode.value = prefs.getBool(_keyDarkMode) ?? false;
    uiLanguage.value = prefs.getString(_keyLanguage) ?? 'zh';
    physicalDiceMode.value = prefs.getBool(_keyPhysicalDice) ?? false;
    physicalDiceModeExplained.value =
        prefs.getBool(_keyPhysicalDiceExplained) ?? false;
  }

  Future<void> setAllowUnlimitedListCount(bool value) async {
    allowUnlimitedListCount.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUnlimited, value);
  }

  Future<void> setDarkMode(bool value) async {
    darkMode.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
  }

  Future<void> setLanguage(String code) async {
    uiLanguage.value = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, code);
  }

  Future<void> setPhysicalDiceMode(bool value) async {
    physicalDiceMode.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPhysicalDice, value);
  }

  Future<void> setPhysicalDiceModeExplained(bool value) async {
    physicalDiceModeExplained.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPhysicalDiceExplained, value);
  }
}
