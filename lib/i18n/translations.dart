import 'package:get/get.dart';

class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': _zh,
      };

  static const _zh = <String, String>{
    // common
    'OK': '确定',
    'Cancel': '取消',
    'Save': '保存',
    'Delete': '删除',
    'Close': '关闭',
    'Back': '返回',
    'Settings': '设置',
    'Language': '语言',
    'Chinese': '中文',
    'English': 'English',

    // main / exit guard
    'Quit Adventure Crafter?': '退出 Adventure Crafter？',
    'Data was last saved at': '数据上次保存于',
    'No save record yet.': '尚无保存记录。',
    'All unsaved progress will be lost.':
        '所有未保存的进度将会丢失。',
    'Quit': '退出',
    'just now': '刚刚',
    'minutes ago': '分钟前',
    'hours ago': '小时前',
    'days ago': '天前',

    // adventure index
    'No adventures yet. Tap "New adventure" at the bottom right to start.':
        '还没有冒险。点击右下角「新建冒险」开始。',
    'New adventure': '新建冒险',
    'Adventure title': '冒险标题',
    'Rename': '重命名',
    'Rename adventure': '重命名冒险',
    'Delete adventure': '删除冒险',
    'Delete adventure "@title"? This cannot be undone.':
        '确定删除「@title」？此操作不可恢复。',
    'Open': '打开',

    // adventure page rail
    'Themes': '主题',
    'Plotlines': '情节线',
    'Characters': '角色',
    'Turning points': '转折点',
    'Cast character': '角色铸造',
    'Roll log': '日志',
    'Auto-save': '自动保存',
    'No adventure opened': '未打开任何冒险',

    // themes page
    'Adventure themes (priority 1-5)': '冒险主题（按优先级 1-5）',
    'Roll assembly': '掷骰装配',
    'Each click rolls 1d10 and fills one priority slot; click again for the next theme':
        '每次点击掷 1d10 并装填一个优先位，未装填完可反复点击',
    'Theme alternation counter: when the theme die rolls 10, the theme currently at priority @n is used, then it alternates with priority @m.':
        '主题交替计数器：主题骰掷出 10 时，使用当前第 @n 优先的主题，随后与第 @m 优先位自动交替。',
    'Unset': '未设置',
    'Pick theme': '选择主题',
    'Remove (later priorities removed too)': '移除（其后优先位一并移除）',
    'Set a higher priority first': '先设置更高优先位',
    '10 (alt)': '10（交替）',
    'All 5 priority slots are set.': '5 个优先位已全部设置。',
    'Cannot generate an unused theme.': '无法生成未占用的主题。',
    'Priority @slot roll': '第@slot优先掷骰',
    '1d10=@die → rolled "@direct" which is taken, ring-shifted to "@theme"':
        '1d10=@die → 掷出「@direct」已被占用，环形顺延至「@theme」',
    '1d10=@die → "@theme"': '1d10=@die → 「@theme」',
    'Fill this as priority @slot? Click "Roll assembly" again for the next theme.':
        '确定装填为第@slot优先？后续主题需再次点击「掷骰装配」。',
    'Fill in': '确定装填',
    '(shifted)': '（顺延）',

    // paged lists
    'Plotline list': '情节线列表',
    'Character list': '角色列表',
    'New plotline': '新情节线',
    'New character': '新角色',
    'Roll': '掷骰',
    'Page @page (@from-@to)': '第@page页 (@from-@to)',
    'Weight +1 (takes next empty row)': '权重 +1（占下一个空行）',
    'Weight -1': '权重 -1',
    'Weight cap reached (@max). You can lift the cap in Settings.':
        '已达权重上限（@max）。可在设置中解除上限。',
    'This entry occupies no row.': '该条目没有占用行。',
    'Roll result: page @page, row @row': '掷骰结果：第@page页 第@row行',
    '(current weight x@weight)': '（当前权重 x@weight）',
    'To raise the weight, manually +1 the entry.':
        '如需提升权重，请手动对该条目 +1。',
    'Empty row → default hint: @hint': '空行 → 默认提示：@hint',
    'Go to character casting': '前往角色铸造',
    'Edit entry': '编辑条目',
    'Name': '名称',
    'Notes': '笔记',
    'Special trait': '特殊特质',
    'Identities (separate with ，)': '身份（多个用「，」分隔）',
    'Descriptors (separate with ，)': '描述词（多个用「，」分隔）',
    'Delete entry': '删除条目',
    'Delete "@name" and all its occupied rows (weight is lost). Are you sure?':
        '删除「@name」及其全部占用行（权重随之消失）。确定？',

    // cast character
    'Character casting wizard': '角色铸造向导',
    'Roll trait → identity → descriptor in order, interpret, name, then add to the character list. Original text for trait 93-100, identity 1-33, descriptor 1-21 is display-only; the player handles it.':
        '依次掷特殊特质 → 身份 → 描述词，综合解读后命名并加入角色列表。特殊特质 93-100、身份 1-33、描述词 1-21 的原文说明仅作展示，由玩家自行处置。',
    'Step 1: special trait': '第一步：特殊特质',
    'Step 2: identity': '第二步：身份',
    'Step 3: descriptor': '第三步：描述词',
    'Roll 1d100': '掷 1d100',
    'Reroll': '重掷',
    'This result requires rolling two: roll again yourself (the software does not handle it); every roll result is recorded in the list below.':
        '此结果要求掷两个：请自行再掷（软件不自动处理），历次掷骰出目已自动记录到下方列表。',
    'Roll character list for the related character': '掷角色列表查询关联角色',
    '(character list is empty)': '（角色列表为空）',
    'page @page, row @row: @result': '第@page页 第@row行：@result',
    'Character name (interpret the three tables, then name)':
        '角色名称（综合三表结果解读后命名）',
    'Add to character list': '加入角色列表',
    '"@name" added to the character list.': '「@name」已加入角色列表。',
    'Browse special trait table': '浏览特殊特质表',
    'Browse identity table': '浏览身份表',
    'Browse descriptor table': '浏览描述词表',
    'Special trait table': '特殊特质表',
    'Identity table': '身份表',
    'Descriptor table': '描述词表',

    // turning points
    'New turning point': '新转折点',
    'No turning points yet. Click "New turning point" to start.':
        '还没有转折点。点击「新转折点」开始。',
    'Turning point @index　Focus: @focus': '转折点 @index　聚焦：@focus',
    'Plotline status: @status　Plot points: @filled/5': '情节线状态：@status　情节点：@filled/5',
    'Delete turning point': '删除转折点',
    'Delete turning point @index?': '删除转折点 @index？',
    'Save & close': '保存并关闭',
    'Focus plotline: @focus': '聚焦情节线：@focus',
    'Roll to decide, or pick manually (including "new plotline")':
        '可掷骰确定，或手动指定（含「新情节线」）',
    'Roll plotline list': '掷情节线列表',
    'New plotline and focus': '新情节线并聚焦',
    'Clear focus': '清除聚焦',
    'Plotline status (set by the player)': '情节线状态（由玩家手动设置）',
    'Undecided': '未定',
    'Development': '发展',
    'Conclusion': '结束',
    '"Conclusion": include whatever is needed to end this plotline, and remove the plotline from the plotline list yourself.':
        '「结束」：将结束该情节线所需的一切纳入本转折点，并自行从情节线列表中移除该情节线。',
    '"Conclusion": remove this plotline from the plotline list yourself (edit shortcuts are not implemented; the player operates).':
        '转折点为「结束」：请自行将该情节线移出情节线列表（编辑快捷操作不实现，交由玩家操作）。',
    'Plot point @index': '情节点 @index',
    'Not rolled yet': '（未掷）',
    'Change to "None"': '改为「无」',
    'Change to most likely': '改为最合理',
    'Theme die @die (@theme)': '主题骰 @die（@theme）',
    'plot point die @roll': '情节点骰 @roll',
    'Roll for meta plot point': '为元情节点掷骰',
    'Meta plot point (1d100=@roll): @title': '元情节点（1d100=@roll）：@title',
    'View original text': '查看原文',
    'Invoked characters:': '征引角色：',
    'Select': '选择',
    'Turning point notes': '转折点笔记',
    'Slot notes': '槽位笔记',
    'The plotline list is empty.': '情节线列表为空。',
    'Set adventure themes on the Themes page first.': '请先在「主题」页设置冒险主题。',
    'Meta plot point triggered: click "Roll for meta plot point" in this slot.':
        '触发元情节点：请点击该槽位的「为元情节点掷骰」。',
    'Focused plotline: @name. To raise its weight, manually +1 on the Plotlines page.':
        '聚焦情节线：@name。如需提升权重，请到「情节线」页手动 +1。',
    'Empty row rolled (row @row)': '掷中空行（第@row行）',
    'Default hint: @hint': '默认提示：@hint',
    'Keep unfocused': '保持未聚焦',
    'Go to plotline list': '前往情节线列表',
    'Pick the most likely plotline': '选择最合理的情节线',
    'The plotline list is empty. Create one on the Plotlines page first.':
        '情节线列表为空，请先到「情节线」页新建。',
    'Plotline name': '情节线名称',
    'Rolling focus plotline': '聚焦情节线掷骰',
    'Meta plot point': '元情节点',
    'Meta plot point triggered (not rolled)': '元情节点触发（未掷）',

    // lookup dialogs
    'Plot point table': '情节点表',
    'Tap to view original text': '点开查看原文说明',
    'Meta plot point table': '元情节点表',
    'The above is the original rule text; side effects are not executed automatically and are handled by the player.':
        '以上为原文规则说明，副作用不自动执行，由玩家自行处置。',

    // roll log
    'Roll log (this adventure)': '掷骰日志（本冒险）',
    'Clear': '清空',
    'No roll records': '暂无掷骰记录',

    // settings
    'Allow entry weight above 3': '允许条目权重超过 3',
    'Default off: each entry occupies at most 3 rows (optional rule from the book). Turn on to remove the cap.':
        '默认关闭：每个条目最多占用 3 行（仿原书可选规则）。开启后不限制。',
    'Browse data tables': '数据表浏览',
    'All plot points with per-theme roll ranges': '全部情节点与各主题掷骰区间',
    'Triggered when a plot point roll is 96-100': '情节点掷出 96-100 时触发',
    'Dark mode': '深色模式',
    'Physical dice mode': '实体骰模式',
    'Roll buttons open lookup tables instead: roll your physical dice and read the result from the table. The software rolls nothing and logs nothing.':
        '掷骰按钮改为打开查询表：由玩家自行掷实体骰并查表；软件不做随机、不写日志。',
    'With physical dice mode on, roll buttons open lookup tables: roll your physical dice, then find the result in the table.':
        '启用实体骰模式后，掷骰按钮将打开查询表：你可以自己掷实体骰，然后在查询表中查找结果。',
    'Got it': '知道了',
    'Adventure Crafter (assistant)':
        'Adventure Crafter（冒险工匠助手）',
    'Unofficial fan tool based on "The Adventure Crafter" by Tana Pigeon, published by Word Mill Games. Rule text and tables from the book are used under the Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0) license, pursuant to the Word Mill Games CC-BY-NC policy (www.wordmillgames.com/license.html); the license covers text only. Find out more at www.wordmillgames.com.':
        '非官方粉丝工具，基于 Tana Pigeon 著、Word Mill Games 出版的《The Adventure Crafter》。书中规则文本与表格依据 Word Mill Games 官方 CC-BY-NC 政策（www.wordmillgames.com/license.html），按 Creative Commons 署名-非商业性使用 4.0 国际许可协议（CC BY-NC 4.0）使用；该许可仅覆盖文本。详情见 www.wordmillgames.com。',
    'Modifications: selected rule tables and texts were translated into Chinese and integrated into this software (including the data files under assets/rules/, also provided under CC BY-NC 4.0). The full Chinese translation of the book was produced by the maintainer with AI assistance for personal use only and is not distributed with this software.':
        '修改说明：本软件将书中部分规则表格与文本翻译为中文并整合进软件（含 assets/rules/ 数据文件，同样按 CC BY-NC 4.0 提供）。全书中文译文由维护者个人借助 AI 完成，仅供自用，不随本软件发布。',
    'Disclaimer: unofficial fan project, not affiliated with or endorsed by Word Mill Games or Tana Pigeon. All third-party trademarks belong to their respective owners.':
        '非官方声明：本软件为爱好者制作的非官方项目，与 Word Mill Games 或 Tana Pigeon 无隶属关系，亦未获得其官方认可。各第三方商标归其各自所有者所有。',
    'Software code: PolyForm Noncommercial License 1.0.0. Rule content from The Adventure Crafter (including the assets/rules/ data files): CC BY-NC 4.0.':
        '软件代码：PolyForm Noncommercial License 1.0.0；《The Adventure Crafter》规则内容（含 assets/rules/ 数据文件）：CC BY-NC 4.0。',

    // M2: carry-over, help, data management
    'Carry over lists from a previous adventure': '从上一冒险誊入列表',
    'Copies the plotline and character lists, including weights.':
        '将复制情节线与角色列表（含权重）。',
    'Start fresh': '不誊入（全新开始）',
    'How to use the Adventure Crafter': '冒险工匠的用法',
    'Adventure outline': '冒险大纲',
    'Assemble themes, then generate turning points one by one ahead of play to build the outline of a full adventure; expand the results into scene outlines yourself.':
        '先装配主题，再在开跑前逐个生成转折点，构建完整冒险的大纲；由玩家自行把结果扩写为场景大纲。',
    'Adventure seed': '冒险种子',
    'Generate a single turning point when starting a new adventure and use it as the seed you grow into an adventure.':
        '新冒险开局时生成一个转折点，把它作为种子自行发展成完整冒险。',
    'Opening scene': '开场场景',
    'Use a generated turning point as an alternative way to create the first scene of a Mythic adventure.':
        '把生成的转折点作为 Mythic 冒险第一场景的另一种生成方式。',
    'Inspiration': '灵感',
    'When stuck, roll a single plot point or a list entry to get ideas; interpret the results yourself.':
        '卡壳时单掷一个情节点或列表条目寻找灵感；结果由玩家自行解读。',
    'The software only rolls dice and looks up tables; all creative decisions are made by the player.':
        '软件只负责掷骰与查表；所有创造性决定由玩家做出。',
    'Data management': '数据管理',
    'Export current adventure': '导出当前冒险',
    'Save the adventure as a .json file.': '把当前冒险保存为 .json 文件。',
    'Export full backup (zip)': '导出全量备份（zip）',
    'Packs all adventures into a zip archive.': '把所有冒险打包为一个 zip 压缩包。',
    'Import from file (json/zip)': '从文件导入（json/zip）',
    'Import a single adventure (.json) or a backup archive (.zip).':
        '导入单个冒险（.json）或备份压缩包（.zip）。',
    'Imported @count adventure(s).': '已导入 @count 个冒险。',
    'Import failed: invalid file': '导入失败：文件无效',
    'Nothing to back up': '没有可备份的冒险',
    'Export adventure': '导出冒险',

    // F1: invoked character roll
    'Roll character list to invoke': '掷角色列表征引角色',
    'Invoked character roll': '征引角色掷骰',
    'Invoked character: @name': '征引角色：@name',
    'Keep uninvoked': '不征引',
    'The character list is empty.': '角色列表为空。',

    // physical dice lookups
    'Physical dice: roll yourself and read the result from the table.':
        '实体骰：请自行掷骰并在下表查找结果。',
    'Physical dice: pick the row matching your roll to confirm.':
        '实体骰：点击与你的出目相符的行即可确认。',
    'Physical pick': '实体骰选定',
    'Physical pick p@p, r@r → @result': '实体骰选定 第@p页 第@r行 → @result',
    'Alternator': '交替位',
    'Select a theme to view its plot points.': '请先选择要查询的主题。',
    'Index 1-100': '索引 1-100',
    'Locate': '定位',
    'Paged list: roll 1d@pages to pick a page, then 1d100 for the row (row n covers 4n-3 ~ 4n).':
        '多页列表：先掷 1d@pages 选页，再掷 1d100 定行（行n覆盖4n−3~4n）。',
    'Page @page': '第@page页',
    'empty': '空行',
    'Theme die (1d10)': '主题骰（1d10）',
    '1-4 → priority 1 (@theme)': '1-4 → 第1优先（@theme）',
    '5-7 → priority 2 (@theme)': '5-7 → 第2优先（@theme）',
    '8-9 → priority 3 (@theme)': '8-9 → 第3优先（@theme）',
    '10 → alternator (@theme)': '10 → 交替位（@theme）',
    'Random theme table (1d10)': '随机主题表（1d10）',
    'Rolling plotline list (physical)': '情节线列表掷骰',
    'Rolling character list (physical)': '角色列表掷骰',
    'Theme die': '主题骰',
    'Plot point roll': '情节点掷骰',
    'Random theme assembly': '随机主题装配',
    'Casting · special trait': '角色铸造·特殊特质',
    'Casting · identity': '角色铸造·身份',
    'Casting · descriptor': '角色铸造·描述词',
    'Casting · related character roll': '角色铸造·关联角色掷骰',
    'Casting': '角色铸造',
    'Choose the most fitting character': '选择最合理的角色',
  };
}
