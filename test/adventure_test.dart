import 'package:flutter_test/flutter_test.dart';

import 'package:adventure_crafter/data/adventure.dart';

void main() {
  test('PagedList：权重即占用行数，± 权重操作正确', () {
    final list = PagedList();
    list.entries.add(ListEntry(id: 1, name: 'A'));
    list.entries.add(ListEntry(id: 2, name: 'B'));

    expect(list.assignNextEmpty(1), isTrue);
    expect(list.assignNextEmpty(1), isTrue);
    expect(list.assignNextEmpty(2), isTrue);
    expect(list.weightOf(1), 2);
    expect(list.weightOf(2), 1);

    list.unassignLast(1);
    expect(list.weightOf(1), 1);
  });

  test('PagedList：占满一页后自动扩展新页', () {
    final list = PagedList();
    for (var i = 1; i <= 25; i++) {
      expect(list.assignNextEmpty(i), isTrue);
    }
    expect(list.pages.length, 1);
    list.assignNextEmpty(26);
    expect(list.pages.length, 2);
    expect(list.pages[1][0], 26);
  });

  test('PagedList：删除条目同时清空占用行', () {
    final list = PagedList();
    list.entries.add(ListEntry(id: 1, name: 'A'));
    list.assignNextEmpty(1);
    list.assignNextEmpty(1);
    expect(list.weightOf(1), 2);
    list.removeEntryRefs(1);
    expect(list.weightOf(1), 0);
    expect(list.entries.where((e) => e.id == 1), isEmpty);
  });

  test('Adventure：JSON 往返一致', () {
    final adv = Adventure(id: 'a1', title: '测试冒险', date: '2026-11-12');
    adv.themes.addAll(['tension', 'action', 'mystery', 'social', 'personal']);
    adv.alternator = 5;
    adv.plotlines.entries.add(ListEntry(id: 1, name: '运送圣物'));
    adv.plotlines.assignNextEmpty(1);
    adv.characters.entries.add(ListEntry(id: 2, name: '艾里克',
        trait: '角色是个人', identities: ['船长'], descriptors: ['果断']));
    adv.characters.assignNextEmpty(2);
    final tp = TurningPoint(
      index: 1,
      plotlineId: 1,
      status: 'development',
      slots: List.generate(5, (_) => Slot()),
    );
    tp.slots[0]
      ..themeId = 'tension'
      ..plotPointId = 'none'
      ..invoked.add(2);
    adv.turningPoints.add(tp);

    final restored = Adventure.fromJsonString(adv.toJsonString());
    expect(restored.title, '测试冒险');
    expect(restored.themes, adv.themes);
    expect(restored.alternator, 5);
    expect(restored.plotlines.entries.first.name, '运送圣物');
    expect(restored.plotlines.weightOf(1), 1);
    expect(restored.characters.entries.first.identities, ['船长']);
    expect(restored.turningPoints.first.slots[0].plotPointId, 'none');
    expect(restored.turningPoints.first.slots[0].invoked, [2]);
    expect(Adventure.schemaVersion, 1);  });
}
