# AGENTS.md

> AI 编程助手必读。完整背景见 `docs/HANDOFF.md`（交接文档）；本文件只收录必须遵守的规则。
> 项目：Adventure Crafter——《The Adventure Crafter》（Word Mill Games）非官方跑团辅助软件，Flutter 3.38.10 + GetX，Windows/Android/Web 三端。代码与 UI 文案（GetX tr）均可改；以下决策与机制不可违背。

## 不可违背的设计决策

1. **软件只查询与展示，不替玩家做决定**：掷骰结果原样呈现；所有处置（改最合理、选情节线/角色等）由玩家手动触发。
2. **实体骰模式**：掷骰按钮变为查询表，玩家自掷实体骰后点选行确认；软件零随机；日志记"实体骰选定"；点选"10 → 交替位"行时交替指针照常翻转。设置页浏览入口保持只读（无 onSelect 回调）。
3. **退出无拦截弹窗**：统一路径 = 窗口关闭 → 静默 save() → `exit(0)`（`lib/helpers/app_exit.dart` 条件导入）。勿用 `windowManager.destroy()`（实测 ~6.4s）或 `SystemNavigator.pop()`（Windows 不退出进程）。
4. **情节线状态只有三种**：new（新情节线）/ development（发展）/ conclusion（结束）。没有"未定"；新建默认 new；读取时 undecided 自动迁移为 new。
5. **F13 不实现**（编辑规则快捷操作交由玩家）。
6. **掷骰日志跟随冒险**（存于各冒险 rollLog），无全局公共日志。
7. **"新角色"三种处理**：角色列表页掷骰 → 跳转铸造；铸造关联角色查询 → 转换为"选择最合理的角色"（书中规则，不跳转）；转折点征引掷骰 → 默认提示对话框带跳转入口。
8. **"掷两个"（rollTwo）条目本身不入历史记录**，只置常驻提示；后续结果照常追加。
9. **元情节点/特殊特质 93-100 的副作用只展示原文**，不自动执行。
10. **权重 = 网格占行数**，玩家手动 +1，默认上限 3（设置可解除）。
11. **UI 不得硬编码颜色**，一律 Material 3 色板语义角色；深色主题必须 `ThemeData(brightness: Brightness.dark)` 独立构造，**禁止** `copyWith(colorScheme:)`。
12. 新增界面文案：英文原文作键，同步在 `lib/i18n/translations.dart` 加中文映射。

## 勿改的实现机制

- **刷新机制**：`AdventureService.save()` 内 `current.refresh()` 是唯一 UI 刷新信号；数据变更必须经 `changed()` → `save()`。`Obx` 必须在 builder 内读 `.value` 才建立追踪——**`LayoutBuilder.builder` 不在追踪上下文内，在其中读 observable 无效**（曾致回归）。读值后作为参数传入。
- **跳转**：跨页跳转一律走 `goToAdventureTab(index)`（自动关闭所有 PopupRoute 弹窗再切页），勿自行 Navigator.push。
- **退出**：只经 `AppWindowListener.onWindowClose`（见上）。
- **查询表**：可选中模式由 `onSelect`/`onPick` 可选参数开启；列表掷骰空行走默认提示分支。
- **数据联动比较**：代码以 `hint == '新角色'` / `'新情节线'`（中文数据值）触发跳转/联动，改数据需同步。

## 数据资产（assets/rules/*.json）

- 由 `tools/generate_rules.py` 生成，校验标准：各主题区间并集 = 1-100 无缝无叠；改动后必须重跑校验 + `flutter analyze && flutter test`。
- 特殊约定：`plot_points.json` 特殊 id `meta`/`none`；`theme_priorities.json` 优先级键名为 `slot`；三张角色表含 `rollTwo`；`list_defaults.json` 为中文默认提示。
- 英文数据表是 `[Future]` issue（#4），未实现前勿混入。

## 构建与发布速查

```powershell
$env:Path = "C:\dev\flutter-3.38.10\flutter\bin;$env:Path"
$env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn"
$env:PUB_HOSTED_URL = "https://pub.flutter-io.cn"
flutter analyze ; flutter test
flutter build windows --release
flutter build apk --release   # 另需 $env:JAVA_HOME = "C:\dev\jdk17\jdk-17.0.21.0.2+1"
flutter build web --release
```

- APK 当前为 debug 签名（无 keystore；**不要自行生成**，材料齐备后配置 `android/key.properties`）。
- 推送：`git push https://x-access-token:<token>@github.com/sennomulo/adventure_crafter.git main`（凭据管理器旧令牌已失效）。
- Release：无 gh CLI，用 `curl.exe --ssl-no-revoke` + GitHub REST API；JSON 用 python `json.dumps(ensure_ascii=True)` + `Set-Content -Encoding Ascii` 写入（避免 BOM）。
- 版本：`pubspec.yaml` `x.y.z+build`；tag = `v x.y.z`。
