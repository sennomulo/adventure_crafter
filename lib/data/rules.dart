import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';

class DieRange {
  final int min;
  final int max;

  const DieRange(this.min, this.max);

  bool contains(int value) => value >= min && value <= max;

  static DieRange? fromJsonList(List<dynamic>? list) =>
      list == null ? null : DieRange(list[0] as int, list[1] as int);
}

class PlotPoint {
  final String id;
  final String title;
  final String desc;
  final Map<String, DieRange?> ranges;

  const PlotPoint({
    required this.id,
    required this.title,
    required this.desc,
    required this.ranges,
  });

  String rangesLabel() {
    final parts = <String>[];
    ranges.forEach((theme, range) {
      final label = RulesService.themeNames[theme]!;
      parts.add(range == null ? '$label：—' : '$label：${range.min}-${range.max}');
    });
    return parts.join('　');
  }
}

class MetaPlotPoint {
  final String id;
  final String title;
  final String desc;
  final int min;
  final int max;

  const MetaPlotPoint({
    required this.id,
    required this.title,
    required this.desc,
    required this.min,
    required this.max,
  });
}

class NumberedEntry {
  final String id;
  final String text;
  final String? desc;
  final int min;
  final int max;
  final bool rollTwo;

  const NumberedEntry({
    required this.id,
    required this.text,
    required this.min,
    required this.max,
    this.desc,
    this.rollTwo = false,
  });
}

class ThemeOption {
  final String theme;
  final int min;
  final int max;

  const ThemeOption({required this.theme, required this.min, required this.max});
}

class ThemePriorityOption {
  final int priority;
  final int min;
  final int max;

  const ThemePriorityOption({required this.priority, required this.min, required this.max});
}

class RulesService extends GetxService {
  final plotPoints = <PlotPoint>[];
  final metaPlotPoints = <MetaPlotPoint>[];
  final traits = <NumberedEntry>[];
  final identities = <NumberedEntry>[];
  final descriptors = <NumberedEntry>[];
  final randomThemes = <ThemeOption>[];
  final themePriorities = <ThemePriorityOption>[];
  final plotlineRowDefaults = <String>[];
  final characterRowDefaults = <String>[];

  static const themeNames = {
    'action': '动作',
    'tension': '张力',
    'mystery': '悬疑',
    'social': '社交',
    'personal': '个人',
  };

  static const themeOrder = ['action', 'tension', 'mystery', 'social', 'personal'];

  Future<void> load() async {
    final plotJson = jsonDecode(await rootBundle.loadString('assets/rules/plot_points.json')) as List;
    for (final e in plotJson) {
      final ranges = <String, DieRange?>{};
      (e['ranges'] as Map<String, dynamic>).forEach((k, v) {
        ranges[k] = DieRange.fromJsonList(v as List<dynamic>?);
      });
      plotPoints.add(PlotPoint(
        id: e['id'] as String,
        title: e['title'] as String,
        desc: e['desc'] as String,
        ranges: ranges,
      ));
    }

    final metaJson = jsonDecode(await rootBundle.loadString('assets/rules/meta_plot_points.json')) as List;
    for (final e in metaJson) {
      metaPlotPoints.add(MetaPlotPoint(
        id: e['id'] as String,
        title: e['title'] as String,
        desc: e['desc'] as String,
        min: e['min'] as int,
        max: e['max'] as int,
      ));
    }

    traits.addAll(_loadNumbered(await rootBundle.loadString('assets/rules/character_traits.json'), traitText: true));
    identities.addAll(_loadNumbered(await rootBundle.loadString('assets/rules/character_identities.json')));
    descriptors.addAll(_loadNumbered(await rootBundle.loadString('assets/rules/character_descriptors.json')));

    final themesJson = jsonDecode(await rootBundle.loadString('assets/rules/random_themes.json')) as List;
    for (final e in themesJson) {
      randomThemes.add(ThemeOption(theme: e['theme'] as String, min: e['min'] as int, max: e['max'] as int));
    }

    final prioritiesJson = jsonDecode(await rootBundle.loadString('assets/rules/theme_priorities.json')) as List;
    for (final e in prioritiesJson) {
      themePriorities.add(ThemePriorityOption(priority: e['slot'] as int, min: e['min'] as int, max: e['max'] as int));
    }

    final defaults = jsonDecode(await rootBundle.loadString('assets/rules/list_defaults.json'));
    plotlineRowDefaults.addAll((defaults['plotlines'] as List).cast<String>());
    characterRowDefaults.addAll((defaults['characters'] as List).cast<String>());
  }

  List<NumberedEntry> _loadNumbered(String json, {bool traitText = false}) {
    final result = <NumberedEntry>[];
    final list = jsonDecode(json) as List;
    for (final e in list) {
      result.add(NumberedEntry(
        id: e['id'] as String,
        text: (e['title'] ?? e['text']) as String,
        desc: traitText ? e['desc'] as String? : null,
        min: e['min'] as int,
        max: e['max'] as int,
        rollTwo: (e['rollTwo'] ?? false) as bool,
      ));
    }
    return result;
  }

  PlotPoint plotPointAt(String theme, int roll) {
    return plotPoints.firstWhere(
      (p) => p.ranges[theme]?.contains(roll) ?? false,
      orElse: () => throw StateError('no plot point for $theme@$roll'),
    );
  }

  PlotPoint? plotPointById(String? id) {
    if (id == null) return null;
    for (final p in plotPoints) {
      if (p.id == id) return p;
    }
    return null;
  }

  MetaPlotPoint metaAt(int roll) {
    return metaPlotPoints.firstWhere((m) => roll >= m.min && roll <= m.max);
  }

  MetaPlotPoint? metaById(String? id) {
    if (id == null) return null;
    for (final m in metaPlotPoints) {
      if (m.id == id) return m;
    }
    return null;
  }

  NumberedEntry entryAt(List<NumberedEntry> list, int roll) {
    return list.firstWhere((e) => roll >= e.min && roll <= e.max);
  }

  String themeName(String themeId) => themeNames[themeId] ?? themeId;

  String rowDefault(bool isPlotline, int rowIndex) {
    final defaults = isPlotline ? plotlineRowDefaults : characterRowDefaults;
    return defaults[rowIndex];
  }
}
