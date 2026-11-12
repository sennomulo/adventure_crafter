import '../data/rules.dart';

String? themeForDieRoll(
    RulesService rules, List<String> themes, int die, int alternator) {
  for (final p in rules.themePriorities) {
    if (die >= p.min && die <= p.max) {
      if (p.priority == 0) {
        if (themes.length >= alternator) return themes[alternator - 1];
        return null;
      }
      if (p.priority <= themes.length) return themes[p.priority - 1];
      return null;
    }
  }
  return null;
}

int prioritySlotForDie(RulesService rules, int die) {
  for (final p in rules.themePriorities) {
    if (die >= p.min && die <= p.max) return p.priority;
  }
  return -1;
}

String? randomThemeForRoll(RulesService rules, int die, Set<String> used) {
  for (final o in rules.randomThemes) {
    if (die >= o.min && die <= o.max) {
      if (!used.contains(o.theme)) return o.theme;
      final order = RulesService.themeOrder;
      var idx = order.indexOf(o.theme);
      for (var step = 0; step < order.length; step++) {
        idx = (idx + 1) % order.length;
        if (!used.contains(order[idx])) return order[idx];
      }
      return null;
    }
  }
  return null;
}
