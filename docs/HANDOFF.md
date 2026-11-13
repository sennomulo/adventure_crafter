# 交接文档（HANDOFF）

> 面向未来接手本项目的 AI 助手与开发者。内容以仓库代码与文档为准，提炼自开发历程。
> 最后核对：v1.1.0 发布时。

## 1. 项目概述

**Adventure Crafter（冒险工匠助手）** 是《The Adventure Crafter》（Tana Pigeon 著，Word Mill Games 出版）的非官方跑团辅助软件，覆盖书中"冒险工匠"工具的数字化使用：冒险管理、主题装配、情节线/角色列表、转折点与情节点掷骰、角色铸造、掷骰日志、实体骰模式、存档导出/导入。

- **参考项目**：[idispatch75/mythic-gme-adventures](https://github.com/idispatch75/mythic-gme-adventures)（Mythic GME 桌面助手）。本项目在其本地副本（`C:\Users\Administrator\Downloads\mythic-gme-adventures`）基础上大量借鉴其技术栈（Flutter + GetX）、模块划分、加权列表交互、查询弹窗、平台条件导入与窗口管理模式。两项目相互独立，无代码依赖。
- **非官方声明与许可**：软件代码以 PolyForm Noncommercial License 1.0.0 发布；《The Adventure Crafter》规则文本与表格（含 `assets/rules/` 数据文件）依据 Word Mill Games 官方 CC-BY-NC 政策按 CC BY-NC 4.0 使用；全书中文译文为维护者个人 AI 辅助翻译，仅供自用、不随软件分发。**完整定稿见 README「版权与许可 / Copyright & License」一节，与 About 页面保持一致，修改时两处必须同步。**

## 2. 技术栈与运行环境

| 项 | 内容 |
|---|---|
| Flutter | 3.38.10，位于 `C:\dev\flutter-3.38.10\flutter`（构建前需加入 PATH） |
| 镜像 | `FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn`、`PUB_HOSTED_URL=https://pub.flutter-io.cn` |
| 状态管理 | GetX 4.x（服务注册、Obx 响应式、tr/trParams 国际化） |
| 关键依赖 | window_manager（桌面窗口）、archive（zip 备份）、file_picker + flutter_file_dialog（跨平台文件）、web（Web 端文件传输）、shared_preferences、path_provider |
| Android 构建 | JDK：`C:\dev\jdk17\jdk-17.0.21.0.2+1`（设 `JAVA_HOME`）；Gradle wrapper 已固定为腾讯镜像 8.14.3-all（services.gradle.org 下载会 TLS 校验失败） |
| 平台 | Windows / Android / Web 三端（`web/`、`android/`、`windows/` 目录齐全） |

## 3. 项目结构

```
lib/
├── main.dart                    # 服务注册与启动；窗口管理；AppWindowListener（退出路径）；主题构造
├── data/
│   ├── rules.dart               # RulesService：加载 assets/rules/*.json；plotPoints（情节点×主题区间矩阵）、
│   │                            #   metaPlotPoints、traits/identities/descriptors、themePriorities、行默认提示
│   └── adventure.dart           # Adventure/PagedList/Slot/TurningPoint/RollLogEntry；schemaVersion；
│                                #   seedListsFrom（F14 延续预填）；情节线状态迁移（undecided→new）
├── helpers/
│   ├── engine.dart              # 纯规则引擎：themeForDieRoll（含交替指针）、randomThemeForRoll、prioritySlotForDie
│   ├── utils.dart               # rollDie/roll100/roll10、rowForRoll（⌈d100/4⌉）
│   └── app_exit.dart            # 条件导入：桌面 exit(0) 兜底退出 / Web 空实现
├── services/
│   ├── adventure_service.dart   # 冒险 CRUD、save()（唯一刷新信号）、rollPlotPoint（主题骰+情节点骰）
│   ├── backup_service.dart      # 导出单冒险(.json)/全量备份(.zip)/导入（ID 冲突自动重生成）
│   ├── settings_service.dart    # 全局设置（持久化）：权重上限、深色、语言、实体骰模式
│   └── roll_log_service.dart    # 掷骰日志门面（写入当前冒险的 rollLog，上限 200 条）
├── storage/
│   ├── app_storage*.dart        # 冒险存档：.io 文件系统 / .web 条件导入
│   ├── file_transfer*.dart      # 文件保存/选取：桌面 file_picker / Android flutter_file_dialog / Web blob 下载
│   └── storage_types.dart       # AdventureStorage 接口、AdventureMeta
├── i18n/translations.dart       # 英文原文作键 → 中文映射；新增界面文案必须同步加键
└── ui/
    ├── adventure_page.dart      # 冒险主界面：响应式三档导航 + IndexedStack；goToAdventureTab（跳转+关弹窗）
    ├── adventure_index/         # 初始页：冒险列表；新建对话框（F14 誊入来源选择）
    ├── themes/                  # 主题装配（单次装填+历史 Chip）、交替计数器展示
    ├── characters/              # 情节线/角色共用分页列表（网格、权重、掷骰、条目编辑弹窗）
    ├── turning_points/          # 转折点编辑器（聚焦情节线、状态、5 槽位、征引角色掷骰、元表掷骰）
    ├── cast_character/          # 角色铸造向导（三表、关联角色查询、"掷两个"提示与历史）
    ├── tables/                  # lookup_dialogs（情节点表：先选主题+索引定位；元表；三表；主题骰映射）、
    │                            #   list_roll_lookup（分页网格查询，可选确认模式）
    ├── roll_log/                # 掷骰日志页
    ├── global_settings/         # 设置页（全局设置、数据表浏览、数据管理、About 许可卡片）
    ├── help/                    # F17 用法指引（大纲/种子/开场场景/灵感）
    └── widgets/common.dart      # weightBadge、confirmDialog/textInputDialog、showSnack
assets/rules/*.json             # 规则表数据（只读，见第 6 节）
assets/fonts/NotoSansSC-*.ttf   # 中文字体（OFL 1.1），全局 fontFamilyFallback
tools/generate_rules.py         # 从中文全书文本生成规则数据 + 校验
docs/DESIGN.md                  # 设计方案与路线图（决策记录）
docs/RELEASE_NOTES_v*.md        # 历次发布说明
test/                           # 单元测试（engine、adventure 序列化/预填）
```

## 4. 核心设计决策（不可违背）

1. **软件只提供查询与展示，不替玩家做决定**。掷骰结果原样呈现；"改为最合理""选择情节线/角色"等处置永远由玩家手动触发。唯一例外：情节点掷出 96-100 自动打开元情节点表掷骰（仍由玩家掷）。
2. **实体骰模式**：全局开关。开启后所有掷骰按钮变为查询表入口，玩家自掷实体骰后在表中**点选行确认**（可选查询表），软件不产生随机数；掷骰日志仅记录"实体骰选定"。主题骰映射表中点选"10 → 交替位"行时，交替指针照常翻转（记录本次使用的主题）。设置页的纯浏览入口保持只读。
3. **退出无拦截弹窗**（已按设计决策移除，勿恢复）：自动保存足够及时（每次变更即写盘），弹窗得不偿失。退出走统一路径：窗口关闭 → 静默保存兜底 → `exit(0)`（详见第 5 节）。退出延迟实测：windowManager.destroy() 通道链约 6.4s、SystemNavigator.pop() 桌面端无法退出、exit(0) 约 150ms。
4. **情节线状态只有三种**：新情节线（new）/ 发展（development）/ 结束（conclusion）；"未定"（undecided）不是状态。新建默认 `new`；存量数据读取时 `undecided` 自动迁移为 `new`。
5. **F13 已从功能清单移除**：「忽略此结束」当「无」、「将下一转折点指定为结束」等编辑快捷操作不实现，相关操作交由玩家自行操作（DESIGN.md 最终决策 #1）。
6. **掷骰日志跟随冒险**：日志存在各冒险的 `rollLog` 内，初始页面没有公共日志。
7. **"新角色"处理机制（三种场景不同）**：
   - 角色列表页自身掷骰得"新角色" → 弹跳转"前往角色铸造"（列表页 UI 内，无弹窗滞留问题）；
   - 角色铸造关联角色查询得"新角色" → 按书中规则**转换为"选择最合理的角色"**（不跳转；处置由玩家）；
   - 转折点征引角色掷骰得"新角色" → 弹默认提示对话框，提供跳转铸造入口（复用跳转机制）。
8. **"掷两个"（rollTwo）**：身份/描述词掷出该条目时，条目本身**不进**历史记录列表，只置常驻提示标记；后续掷骰结果照常追加；入角色列表时以历史列表为准。
9. **列表分页制**：每页 25 行，行 n 覆盖 4n−3~4n；多页掷骰先 1d页数再 1d100；空行回退默认提示。
10. **权重 = 网格占行数**，仅由玩家手动 "+1" 增长，默认上限 3（设置可解除）。
11. **元情节点副作用只展示原文**，不自动执行。
12. **主题交替计数器自动追踪**：主题骰 10 → 使用当前交替位主题并翻转（4↔5），软件自动写盘。
13. **数字规则数据为中文**（源自中文译本；无英文数据表）。界面文字中英双语，切换只影响 UI。

## 5. 关键实现机制（防止改坏）

- **UI 状态刷新：数据变更即刷新，勿绕过**。`AdventureService.save()` 内的 `current.refresh()` 是唯一刷新信号；各页面用 `Obx` 包裹读取 `service.current.value` 的 UI。陷阱：
  - `LayoutBuilder.builder` 在布局阶段执行，**不在** Obx 响应式追踪上下文内——在其中读 `.value` 不会建立依赖（曾导致回归 B1）。需要响应式读取时必须在 Obx builder 内先取值再传入。
  - 直接改 Adventure 普通字段不会触发刷新，必须经 `changed()` → `save()`。
- **统一退出路径**：桌面窗口关闭由 `AppWindowListener.onWindowClose` 处理（`setPreventClose(true)` 拦截）→ 静默 `save()` → `forceExit()`（`dart:io exit(0)`，经 `lib/helpers/app_exit.dart` 条件导入保证 Web 可编译）。**勿改用 `windowManager.destroy()`（实测 ~6.4s）或 `SystemNavigator.pop()`（桌面端不退出进程）**。
- **跳转关闭源窗口**：所有跨页跳转必须走 `goToAdventureTab(index)`（`lib/ui/adventure_page.dart`），它会先 `popUntil(非 PopupRoute)` 关闭所有打开的对话框（转折点编辑器、掷骰结果弹窗等）再切页，避免源窗口滞留。新增跳转场景直接复用，不要自己 Navigator.push。
- **历史记录列表行为**：铸造页身份/描述词历史 Chip 支持逐条删除；"掷两个"条目本身不入列（见决策 8）；实体骰手动选定后出目标注清除（骰值归零），不得残留旧出目。
- **可选中查询表 vs 只读浏览**：`showNumberedLookup`/`showMetaTable`/`showListRollLookup` 的可选中行为由 `onSelect`/`onPick` 回调参数开启；设置页浏览入口不传回调，保持只读。新增查询表时沿用此模式。
- **深色主题**：必须独立构造（`ThemeData(brightness: Brightness.dark)`），**不可** `copyWith(colorScheme:)`——后者不重算 scaffoldBackgroundColor/dialogBackgroundColor/textTheme 等派生字段（曾导致深色模式全面错乱）。UI 中不得硬编码颜色，一律用 Material 3 色板语义角色。

## 6. 数据与规则资产

- 来源：`tools/generate_rules.py` 从《The Adventure Crafter》中文全书提取文本生成 `assets/rules/*.json`，生成时校验**各主题掷骰区间并集 = 1-100 无缝无叠**。
- 文件：`plot_points.json`（186 条情节点 × 5 主题区间矩阵；特殊 id：`meta`=元情节点触发段、`none`=「无」）、`meta_plot_points.json`、`character_traits/identities/descriptors.json`（含 `rollTwo` 标记）、`random_themes.json`、`theme_priorities.json`（1-4→优先1 / 5-7→优先2 / 8-9→优先3 / 10→交替位，JSON 键为 `slot`）、`list_defaults.json`（两列表各 25 行默认提示，**中文数据**，代码中以 `hint == '新角色'`/`'新情节线'` 比较触发联动——改数据需同步改比较逻辑）。
- 修改注意：改动区间后必须重跑校验（无缝无叠）；`meta`/`none` 特殊 id 与 `rollTwo` 标记被引擎与 UI 依赖；改完跑 `flutter analyze && flutter test`。
- 英文数据表为未来规划（GitHub issue #4 `[Future] 英文数据表`），实现时注意与界面语言切换联动。

## 7. 构建与发布流程

```powershell
# 环境（每次新 shell）
$env:Path = "C:\dev\flutter-3.38.10\flutter\bin;$env:Path"
$env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn"
$env:PUB_HOSTED_URL = "https://pub.flutter-io.cn"

flutter pub get
flutter analyze        # 必须零问题
flutter test           # 必须全部通过
flutter build windows --release   # 产物 build\windows\x64\runner\Release\
flutter build apk --release       # 需 $env:JAVA_HOME = "C:\dev\jdk17\jdk-17.0.21.0.2+1"
                                  # 产物 build\app\outputs\flutter-apk\app-release.apk
flutter build web --release       # 产物 build\web\
```

- **APK 签名**：当前无 keystore（`android/key.properties` 不存在），Release APK 使用 debug 签名（发布说明中须标注"测试版"）。正式签名需用户提供 keystore 路径与密码后配置 `key.properties` 与 `build.gradle.kts` 签名块——**不要自行生成 keystore**。
- **打包**：Windows/Web 用 `Compress-Archive` 压缩产物目录；APK 直接改名。SHA256 用 `Get-FileHash -Algorithm SHA256`。
- **Release 发布**：无 gh CLI，用 `curl.exe --ssl-no-revoke` + GitHub REST API（POST /releases → 上传 assets 到 upload_url）。JSON body 用 python `json.dumps(ensure_ascii=True)` 生成、`-Encoding Ascii` 写文件（避免 BOM）。推送用令牌 URL：`git push https://x-access-token:<token>@github.com/sennomulo/adventure_crafter.git main`（凭据管理器中的旧令牌已失效）。
- 版本号在 `pubspec.yaml`（如 `1.1.0+2`）；tag 与 Release 同名（v1.1.0）。

## 8. 路线图与遗留事项

- **当前阶段**：M0-M3 全部完成（MVP + 进阶 + 首次发布 v1.0.0）。路线图见 `docs/DESIGN.md` 第四节。
- **未实现/未来项**：
  - F13 永不实现（决策 5）
  - 英文数据表（issue #4，`[Future]` 前缀约定：新未来项用同格式建 issue 并打 enhancement）
  - Mythic GME 结合、自定义含义表/情节点表编辑器（DESIGN.md 未来扩展节）
  - APK 正式签名（待 keystore 材料）
- **已知问题**：
  - Android 真机未经充分实机验证（响应式布局、Android 端文件保存对话框）
  - 掷骰日志 detail 中的条目名跟随数据语言（中文），界面语言切换不影响数据
  - GitHub PAT 为临时令牌，使用后应撤销
