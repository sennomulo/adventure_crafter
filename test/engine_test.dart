import 'package:flutter_test/flutter_test.dart';

import 'package:adventure_crafter/data/rules.dart';
import 'package:adventure_crafter/helpers/engine.dart';
import 'package:adventure_crafter/helpers/utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RulesService rules;
  setUpAll(() async {
    rules = RulesService();
    await rules.load();
  });

  test('情节点表：每个主题的 1-100 均恰好命中唯一条目', () {
    for (final theme in RulesService.themeOrder) {
      for (var roll = 1; roll <= 100; roll++) {
        final hits = rules.plotPoints
            .where((p) => p.ranges[theme]?.contains(roll) ?? false)
            .toList();
        expect(hits.length, 1, reason: '$theme@$roll 命中 ${hits.length} 条');
      }
    }
  });

  test('元情节点表覆盖 1-100', () {
    for (var roll = 1; roll <= 100; roll++) {
      expect(rules.metaAt(roll).title, isNotEmpty);
    }
  });

  test('角色三表覆盖 1-100', () {
    for (final table in [rules.traits, rules.identities, rules.descriptors]) {
      for (var roll = 1; roll <= 100; roll++) {
        expect(rules.entryAt(table, roll), isNotNull);
      }
    }
  });

  test('主题骰映射：1-4→第1优先 / 5-7→第2 / 8-9→第3 / 10→交替指针', () {
    final themes = ['a', 'b', 'c', 'd', 'e'];
    expect(themeForDieRoll(rules, themes, 1, 4), 'a');
    expect(themeForDieRoll(rules, themes, 4, 4), 'a');
    expect(themeForDieRoll(rules, themes, 5, 4), 'b');
    expect(themeForDieRoll(rules, themes, 7, 4), 'b');
    expect(themeForDieRoll(rules, themes, 8, 4), 'c');
    expect(themeForDieRoll(rules, themes, 9, 4), 'c');
    expect(themeForDieRoll(rules, themes, 10, 4), 'd');
    expect(themeForDieRoll(rules, themes, 10, 5), 'e');
    expect(themeForDieRoll(rules, themes, 10, 4), isNot('e'));
  });

  test('掷骰行映射：行 n 覆盖 4n-3~4n', () {
    expect(rowForRoll(1), 0);
    expect(rowForRoll(4), 0);
    expect(rowForRoll(5), 1);
    expect(rowForRoll(8), 1);
    expect(rowForRoll(97), 24);
    expect(rowForRoll(100), 24);
  });

  test('随机主题装配：重复主题环形顺延', () {
    expect(randomThemeForRoll(rules, 1, {}), 'action');
    expect(randomThemeForRoll(rules, 1, {'action'}), 'tension');
    expect(
      randomThemeForRoll(rules, 1, {'action', 'tension', 'mystery', 'social'}),
      'personal',
    );
    expect(randomThemeForRoll(rules, 10, {}), 'personal');
    expect(randomThemeForRoll(rules, 10, {'personal'}), 'action');
  });

  test('随机主题表覆盖 1-10', () {
    for (var die = 1; die <= 10; die++) {
      expect(randomThemeForRoll(rules, die, {}), isNotNull);
    }
  });

  test('掷骰函数范围正确', () {
    for (var i = 0; i < 200; i++) {
      final d = roll100();
      expect(d, inInclusiveRange(1, 100));
      final t = roll10();
      expect(t, inInclusiveRange(1, 10));
      expect(rollDie(6), inInclusiveRange(1, 6));
    }
  });
}
