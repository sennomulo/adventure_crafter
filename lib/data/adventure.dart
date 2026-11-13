import 'dart:convert';

class RollLogEntry {
  final String time;
  final String label;
  final String detail;

  RollLogEntry({required this.time, required this.label, required this.detail});

  Map<String, dynamic> toJson() => {'time': time, 'label': label, 'detail': detail};

  factory RollLogEntry.fromJson(Map<String, dynamic> json) => RollLogEntry(
        time: (json['time'] ?? '') as String,
        label: (json['label'] ?? '') as String,
        detail: (json['detail'] ?? '') as String,
      );
}

class ListEntry {
  final int id;
  String name;
  String notes;
  String? trait;
  List<String> identities;
  List<String> descriptors;

  ListEntry({
    required this.id,
    required this.name,
    this.notes = '',
    this.trait,
    List<String>? identities,
    List<String>? descriptors,
  })  : identities = identities ?? [],
        descriptors = descriptors ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'notes': notes,
        if (trait != null) 'trait': trait,
        if (identities.isNotEmpty) 'identities': identities,
        if (descriptors.isNotEmpty) 'descriptors': descriptors,
      };

  factory ListEntry.fromJson(Map<String, dynamic> json) => ListEntry(
        id: json['id'] as int,
        name: json['name'] as String,
        notes: (json['notes'] ?? '') as String,
        trait: json['trait'] as String?,
        identities:
            ((json['identities'] ?? []) as List).cast<String>().toList(),
        descriptors:
            ((json['descriptors'] ?? []) as List).cast<String>().toList(),
      );
}

class PagedList {
  static const rowsPerPage = 25;

  final List<ListEntry> entries;
  final List<List<int?>> pages;

  PagedList({List<ListEntry>? entries, List<List<int?>>? pages})
      : entries = entries ?? [],
        pages = pages ?? [List.filled(rowsPerPage, null)];

  int weightOf(int entryId) {
    var count = 0;
    for (final page in pages) {
      for (final row in page) {
        if (row == entryId) count++;
      }
    }
    return count;
  }

  int? firstEmptyPage() {
    for (var p = 0; p < pages.length; p++) {
      for (var r = 0; r < pages[p].length; r++) {
        if (pages[p][r] == null) return p;
      }
    }
    return null;
  }

  (int, int)? firstEmptyRow() {
    for (var p = 0; p < pages.length; p++) {
      for (var r = 0; r < pages[p].length; r++) {
        if (pages[p][r] == null) return (p, r);
      }
    }
    return null;
  }

  bool assignNextEmpty(int entryId, {bool grow = true}) {
    final spot = firstEmptyRow();
    if (spot == null) {
      if (!grow) return false;
      pages.add(List.filled(rowsPerPage, null));
      pages.last[0] = entryId;
      return true;
    }
    pages[spot.$1][spot.$2] = entryId;
    return true;
  }

  void unassignLast(int entryId) {
    for (var p = pages.length - 1; p >= 0; p--) {
      for (var r = pages[p].length - 1; r >= 0; r--) {
        if (pages[p][r] == entryId) {
          pages[p][r] = null;
          return;
        }
      }
    }
  }

  void removeEntryRefs(int entryId) {
    for (final page in pages) {
      for (var r = 0; r < page.length; r++) {
        if (page[r] == entryId) page[r] = null;
      }
    }
    entries.removeWhere((e) => e.id == entryId);
  }

  ListEntry? entryById(int? id) {
    if (id == null) return null;
    for (final e in entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  int nextEntryId() {
    var maxId = 0;
    for (final e in entries) {
      if (e.id > maxId) maxId = e.id;
    }
    return maxId + 1;
  }

  Map<String, dynamic> toJson() => {
        'entries': entries.map((e) => e.toJson()).toList(),
        'pages': pages,
      };

  factory PagedList.fromJson(Map<String, dynamic> json) {
    final pages = <List<int?>>[];
    for (final page in (json['pages'] ?? []) as List) {
      pages.add((page as List)
          .map((v) => v == null ? null : v as int)
          .toList());
    }
    if (pages.isEmpty) {
      pages.add(List.filled(rowsPerPage, null));
    }
    return PagedList(
      entries: ((json['entries'] ?? []) as List)
          .map((e) => ListEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      pages: pages,
    );
  }
}

class Slot {
  String? themeId;
  String? plotPointId;
  String? metaId;
  List<int> invoked;
  String notes;
  int? themeDie;
  int? roll;
  int? metaRoll;

  Slot({
    this.themeId,
    this.plotPointId,
    this.metaId,
    List<int>? invoked,
    this.notes = '',
    this.themeDie,
    this.roll,
    this.metaRoll,
  }) : invoked = invoked ?? [];

  bool get isEmpty => plotPointId == null && metaId == null;

  Map<String, dynamic> toJson() => {
        'themeId': themeId,
        'plotPointId': plotPointId,
        'metaId': metaId,
        'invoked': invoked,
        'notes': notes,
        if (themeDie != null) 'themeDie': themeDie,
        if (roll != null) 'roll': roll,
        if (metaRoll != null) 'metaRoll': metaRoll,
      };

  factory Slot.fromJson(Map<String, dynamic> json) => Slot(
        themeId: json['themeId'] as String?,
        plotPointId: json['plotPointId'] as String?,
        metaId: json['metaId'] as String?,
        invoked: ((json['invoked'] ?? []) as List).cast<int>().toList(),
        notes: (json['notes'] ?? '') as String,
        themeDie: json['themeDie'] as int?,
        roll: json['roll'] as int?,
        metaRoll: json['metaRoll'] as int?,
      );
}

class TurningPoint {
  int index;
  int? plotlineId;
  String status;
  final List<Slot> slots;
  String notes;

  TurningPoint({
    required this.index,
    this.plotlineId,
    this.status = 'new',
    required this.slots,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'index': index,
        'plotlineId': plotlineId,
        'status': status,
        'slots': slots.map((s) => s.toJson()).toList(),
        'notes': notes,
      };

  factory TurningPoint.fromJson(Map<String, dynamic> json) {
    final stored = (json['status'] ?? 'new') as String;
    return TurningPoint(
        index: json['index'] as int,
        plotlineId: json['plotlineId'] as int?,
        status: stored == 'undecided' ? 'new' : stored,
        slots: ((json['slots'] ?? []) as List)
            .map((s) => Slot.fromJson(s as Map<String, dynamic>))
            .toList(),
        notes: (json['notes'] ?? '') as String,
      );
  }
}

class Adventure {
  static const schemaVersion = 1;

  final String id;
  String title;
  String date;
  String notes;
  List<String> themes;
  int alternator;
  final PagedList plotlines;
  final PagedList characters;
  final List<TurningPoint> turningPoints;
  final List<RollLogEntry> rollLog;

  Adventure({
    required this.id,
    required this.title,
    required this.date,
    this.notes = '',
    List<String>? themes,
    this.alternator = 4,
    PagedList? plotlines,
    PagedList? characters,
    List<TurningPoint>? turningPoints,
    List<RollLogEntry>? rollLog,
  })  : themes = themes ?? [],
        plotlines = plotlines ?? PagedList(),
        characters = characters ?? PagedList(),
        turningPoints = turningPoints ?? [],
        rollLog = rollLog ?? [];

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'id': id,
        'title': title,
        'date': date,
        'notes': notes,
        'themes': themes,
        'alternator': alternator,
        'plotlines': plotlines.toJson(),
        'characters': characters.toJson(),
        'turningPoints': turningPoints.map((t) => t.toJson()).toList(),
        'rollLog': rollLog.map((r) => r.toJson()).toList(),
      };

  factory Adventure.fromJson(Map<String, dynamic> json) => Adventure(
        id: json['id'] as String,
        title: (json['title'] ?? '') as String,
        date: (json['date'] ?? '') as String,
        notes: (json['notes'] ?? '') as String,
        themes: ((json['themes'] ?? []) as List).cast<String>().toList(),
        alternator: (json['alternator'] ?? 4) as int,
        plotlines: PagedList.fromJson(json['plotlines'] as Map<String, dynamic>),
        characters:
            PagedList.fromJson(json['characters'] as Map<String, dynamic>),
        turningPoints: ((json['turningPoints'] ?? []) as List)
            .map((t) => TurningPoint.fromJson(t as Map<String, dynamic>))
            .toList(),
        rollLog: ((json['rollLog'] ?? []) as List)
            .map((r) => RollLogEntry.fromJson(r as Map<String, dynamic>))
            .toList(),
      );

  String toJsonString() => jsonEncode(toJson());

  static Adventure fromJsonString(String s) =>
      Adventure.fromJson(jsonDecode(s) as Map<String, dynamic>);

  /// F14 延续冒险预填（冒险工匠之路·你的起点）：
  /// 把上一冒险的情节线与角色列表（含权重，即网格占行）深拷贝到本冒险。
  void seedListsFrom(Adventure src) {
    final pl = PagedList.fromJson(
        jsonDecode(jsonEncode(src.plotlines.toJson())) as Map<String, dynamic>);
    plotlines.entries
      ..clear()
      ..addAll(pl.entries);
    plotlines.pages
      ..clear()
      ..addAll(pl.pages);
    final ch = PagedList.fromJson(
        jsonDecode(jsonEncode(src.characters.toJson())) as Map<String, dynamic>);
    characters.entries
      ..clear()
      ..addAll(ch.entries);
    characters.pages
      ..clear()
      ..addAll(ch.pages);
  }
}
