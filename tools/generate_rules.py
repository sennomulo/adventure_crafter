import json
import re
import os

SRC = r'C:\Users\Administrator\.local\share\opencode\tool-output\tool_1cf458df10018omsPCV5nroh4f'
OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'assets', 'rules')
THEMES = ['action', 'tension', 'mystery', 'social', 'personal']

with open(SRC, encoding='utf-8') as f:
    LINES = f.read().splitlines()

def find_exact(s, start=0):
    for i in range(start, len(LINES)):
        if LINES[i].strip() == s:
            return i
    raise SystemExit(f'marker not found: {s}')

def find_prefix(s, start=0):
    for i in range(start, len(LINES)):
        if LINES[i].strip().startswith(s):
            return i
    raise SystemExit(f'marker not found: {s}')

RANGE_RE = re.compile(r'^(\d+)(?:-(\d+))?$')

def parse_range(s):
    s = s.strip()
    if s in ('—', '-', '－', ''):
        return None
    m = RANGE_RE.match(s)
    if not m:
        raise ValueError(f'bad range: {s!r}')
    a = int(m.group(1))
    b = int(m.group(2)) if m.group(2) else a
    return [a, b]

def table_rows(start, end, ncols, skip_header_cells):
    rows = []
    warnings = []
    for i in range(start, end):
        t = LINES[i].strip()
        if not t or t.startswith('==='):
            continue
        parts = [p.strip() for p in t.split(' | ')]
        if len(parts) != ncols:
            continue
        if any(p in skip_header_cells for p in parts):
            continue
        rows.append((i + 1, parts))
    return rows, warnings

def validate_coverage(spans, label, upper = 100):
    spans = sorted(spans)
    expect = 1
    for lo, hi in spans:
        if lo != expect:
            raise SystemExit(f'{label}: coverage gap/overlap at {expect} (got {lo})')
        expect = hi + 1
    if expect != upper + 1:
        raise SystemExit(f'{label}: coverage ends at {expect - 1}, expected {upper}')

# ---------- plot points (full table with descriptions) ----------
start = find_exact('情节点表')
end = find_exact('元情节点表', start + 1)
rows, _ = table_rows(start, end, 6, {'情节点'})
plot_points = []
for lineno, parts in rows:
    head = parts[0]
    if '：' not in head:
        raise SystemExit(f'line {lineno}: plot point row without title separator: {head[:50]}')
    title, desc = head.split('：', 1)
    ranges = {}
    for k, cell in zip(THEMES, parts[1:6]):
        ranges[k] = parse_range(cell)
    idx = len(plot_points) + 1
    pid = {'结束': 'conclusion', '无': 'none', '元情节点': 'meta'}.get(title, f'pp{idx:03d}')
    plot_points.append({'id': pid, 'title': title, 'desc': desc, 'ranges': ranges})

for theme in THEMES:
    spans = [(e['ranges'][theme][0], e['ranges'][theme][1])
             for e in plot_points if e['ranges'][theme]]
    validate_coverage(spans, f'plot_points[{theme}]')
print(f'plot_points: {len(plot_points)} entries')

# ---------- meta plot points ----------
start = find_prefix('（Meta Plot Points Table')
end = find_exact('精简版情节点表')
rows, _ = table_rows(start, end, 2, {'情节点'})
meta = []
for lineno, parts in rows:
    title, desc = parts[0].split('：', 1)
    lo, hi = parse_range(parts[1])
    meta.append({'id': f'meta{len(meta) + 1:02d}', 'title': title, 'desc': desc, 'min': lo, 'max': hi})
validate_coverage([(e['min'], e['max']) for e in meta], 'meta_plot_points')
print(f'meta_plot_points: {len(meta)} entries')

# ---------- character special traits ----------
start = find_prefix('（Character Special Trait')
end = find_prefix('（Character Identity')
rows, _ = table_rows(start, end, 2, {'特殊特质'})
traits = []
for lineno, parts in rows:
    title, desc = parts[0].split('：', 1)
    lo, hi = parse_range(parts[1])
    traits.append({'id': f'trait{len(traits) + 1:02d}', 'title': title, 'desc': desc, 'min': lo, 'max': hi})
validate_coverage([(e['min'], e['max']) for e in traits], 'character_traits')
print(f'character_traits: {len(traits)} entries')

# ---------- character identities ----------
start = find_prefix('（Character Identity')
end = find_prefix('（Character Descriptors')
rows, _ = table_rows(start, end, 2, {'掷骰'})
identities = []
for lineno, parts in rows:
    lo, hi = parse_range(parts[0])
    roll_two = parts[1].startswith('为两个')
    identities.append({'id': f'ident{len(identities) + 1:02d}', 'text': parts[1], 'min': lo, 'max': hi, 'rollTwo': roll_two})
validate_coverage([(e['min'], e['max']) for e in identities], 'character_identities')
print(f'character_identities: {len(identities)} entries')

# ---------- character descriptors ----------
start = find_prefix('（Character Descriptors')
end = find_exact('冒险工匠之路')
rows, _ = table_rows(start, end, 2, {'掷骰'})
descriptors = []
for lineno, parts in rows:
    lo, hi = parse_range(parts[0])
    roll_two = parts[1].startswith('为两个')
    descriptors.append({'id': f'desc{len(descriptors) + 1:02d}', 'text': parts[1], 'min': lo, 'max': hi, 'rollTwo': roll_two})
validate_coverage([(e['min'], e['max']) for e in descriptors], 'character_descriptors')
print(f'character_descriptors: {len(descriptors)} entries')

# ---------- random themes ----------
start = find_prefix('随机主题表（Random Themes Table')
end = find_exact('五大主题（The Themes）')
rows, _ = table_rows(start, end, 2, {'掷骰'})
theme_map = {'动作': 'action', '张力': 'tension', '悬疑': 'mystery', '社交': 'social', '个人': 'personal'}
random_themes = []
for lineno, parts in rows:
    lo, hi = parse_range(parts[0])
    random_themes.append({'min': lo, 'max': hi, 'theme': theme_map[parts[1]]})
validate_coverage([(e['min'], e['max']) for e in random_themes], 'random_themes', 10)
print(f'random_themes: {len(random_themes)} entries')

# ---------- theme priority (plot point theme table) ----------
start = find_exact('情节点主题表')
end = start + 12
rows, _ = table_rows(start, end, 2, {'掷骰'})
theme_priorities = []
for lineno, parts in rows:
    lo, hi = parse_range(parts[0])
    label = parts[1]
    if '第四' in label:
        slot = 0
    else:
        slot = {'一': 1, '二': 2, '三': 3}[label[1]]
    theme_priorities.append({'min': lo, 'max': hi, 'slot': slot})
validate_coverage([(e['min'], e['max']) for e in theme_priorities], 'theme_priorities', 10)
print(f'theme_priorities: {len(theme_priorities)} entries')

# ---------- list row defaults (full-size tables, p.16) ----------
start = find_prefix('角色列表（Characters List，原书 p.16')
end = find_prefix('情节线列表（Plotlines List，原书 p.16')
rows, _ = table_rows(start, end, 2, {'掷骰'})
char_defaults = [p[1] for _, p in rows]

start = find_prefix('情节线列表（Plotlines List，原书 p.16')
end = find_exact('转折点与情节点')
rows, _ = table_rows(start, end, 2, {'掷骰'})
plot_defaults = [p[1] for _, p in rows]

assert len(char_defaults) == 25, f'characters defaults: {len(char_defaults)}'
assert len(plot_defaults) == 25, f'plotlines defaults: {len(plot_defaults)}'
print(f'list_defaults: 25 + 25 rows')

# ---------- write ----------
os.makedirs(OUT, exist_ok=True)

def write(name, data):
    path = os.path.join(OUT, name)
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=1)
    print(f'wrote {name}')

write('plot_points.json', plot_points)
write('meta_plot_points.json', meta)
write('character_traits.json', traits)
write('character_identities.json', identities)
write('character_descriptors.json', descriptors)
write('random_themes.json', random_themes)
write('theme_priorities.json', theme_priorities)
write('list_defaults.json', {'plotlines': plot_defaults, 'characters': char_defaults})
print('ALL OK')
