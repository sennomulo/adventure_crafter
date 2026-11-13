# Adventure Crafter（冒险工匠助手）

基于《The Adventure Crafter》（Tana Pigeon 著，Word Mill Games 出版）的桌面跑团辅助软件。

> 交接文档（面向开发者/AI 助手）：[docs/HANDOFF.md](docs/HANDOFF.md)；AI 编程工具约定：[AGENTS.md](AGENTS.md)。

> 非官方粉丝工具。版权与许可详见下文「[版权与许可](#版权与许可--copyright--license)」一节。

## 版权与许可 / Copyright & License

本软件（非官方粉丝工具）基于 **《The Adventure Crafter》**（**Tana Pigeon** 著，**Word Mill Games** 出版）。来自该书的规则文本与表格内容的使用，依据 Word Mill Games 官方 [CC-BY-NC 政策](https://www.wordmillgames.com/license.html)，按 [Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)](https://creativecommons.org/licenses/by-nc/4.0/) 许可进行；该许可仅覆盖文本，不含美术与装帧设计。了解详情请访问 [www.wordmillgames.com](https://www.wordmillgames.com/)。

**修改说明**：本软件将原书中的**部分规则表格与文本**翻译为中文并整合进软件（含随软件一并分发的 `assets/rules/` 数据文件，同样按 CC BY-NC 4.0 提供）。原书全书中文译文由本仓库维护者个人借助 AI 工具完成，仅供译者自用，**不随本软件发布**，亦不对外提供。

**非官方声明**：本软件为爱好者制作的非官方项目，与 Word Mill Games 或 Tana Pigeon 无隶属关系，亦未获得其官方认可。各第三方商标归其各自所有者所有。

本仓库的软件代码以 [PolyForm Noncommercial License 1.0.0](LICENSE) 发布；其中来自《The Adventure Crafter》的规则文本与表格内容（含 `assets/rules/` 数据文件）的使用与再分发，依据上述 CC BY-NC 4.0 许可进行。

---

This software (an unofficial fan tool) is based on **The Adventure Crafter** by **Tana Pigeon**, published by **Word Mill Games**. Rule text and table content from the book are used under the [Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)](https://creativecommons.org/licenses/by-nc/4.0/) license, pursuant to Word Mill Games' official [CC-BY-NC policy](https://www.wordmillgames.com/license.html); the license covers text only, not art or trade dress. Find out more at [www.wordmillgames.com](https://www.wordmillgames.com/).

**Modification notice**: Selected rule tables and texts from the book were translated into Chinese and integrated into this software (including the data files under `assets/rules/`, which are distributed under CC BY-NC 4.0 as well). The full Chinese translation of the book was produced by the repository maintainer with AI assistance for personal use only; it is **not distributed** with this software.

**Disclaimer**: This is an unofficial fan project, not affiliated with or endorsed by Word Mill Games or Tana Pigeon. All third-party trademarks belong to their respective owners.

The software code in this repository is released under the [PolyForm Noncommercial License 1.0.0](LICENSE); the rule text and table content from The Adventure Crafter (including the `assets/rules/` data files) are used and redistributed under the CC BY-NC 4.0 license above.

## 开发说明

- 本软件受 [idispatch75/mythic-gme-adventures](https://github.com/idispatch75/mythic-gme-adventures) 启发，并在很大程度上借鉴了该项目（技术栈、模块划分、加权列表交互、查询弹窗等模式）。
- **本软件基于 AI 开发**。
- 内置中文字体为 Noto Sans SC（SIL Open Font License 1.1，见 `assets/fonts/NotoSans-OFL.txt`）。

## 功能（MVP）

- 冒险管理：新建 / 打开 / 重命名 / 删除，多冒险并存，自动保存
- 冒险主题装配：手动指定或掷骰自动填充（重复主题环形顺延），主题骰 10 交替指针自动追踪
- 情节线 / 角色列表：分页网格（每页 25 行，行 n 覆盖 4n−3~4n）、条目权重计数器（默认上限 3，可在设置解除）、列表掷骰（1d页数 + 1d100）、空行默认提示
- 转折点：聚焦情节线掷骰、状态三态、5 个情节点槽位、征引角色、笔记
- 情节点掷骰：1d100 + 1d10 主题骰；96-100 自动触发元情节点表（副作用仅展示原文）
- 角色铸造向导：特殊特质 → 身份 → 描述词三表掷骰（93-100 可掷角色列表查询关联角色；「掷两个」结果由玩家自行记录），命名后加入角色列表
- 「我不知道」操作：重掷 / 改「无」 / 改最合理
- 情节点表 / 元情节点表 / 角色三表查询弹窗；掷骰日志
- 退出软件时弹出保存确认
- 本地持久化（桌面文件系统 / Web 存储）+ schemaVersion

## 开发

```bash
flutter pub get
flutter analyze
flutter test
flutter build windows --release
```

- `docs/DESIGN.md`：已确认的设计方案
- `assets/rules/`：规则表数据（由 `tools/generate_rules.py` 从中文译本提取生成，含区间覆盖校验）
- `tools/`：数据生成与校验脚本
