# Adventure Crafter（冒险工匠助手）

基于《The Adventure Crafter》（Tana Pigeon 著，Word Mill Games 出版）的桌面跑团辅助软件。

> 非官方粉丝工具。规则表数据来自该书中文译本，原著及规则版权归 Word Mill Games 所有。

## 使用条款

- 本软件免费，**不可用于任何商业盈利目的**，详见 [LICENSE](LICENSE)（PolyForm Noncommercial 1.0.0）。

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
