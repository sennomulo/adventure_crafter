# Adventure Crafter v1.0.0（MVP + M2 进阶 + M3 发布）

《The Adventure Crafter》（Tana Pigeon 著，Word Mill Games 出版）的非官方跑团辅助软件首个发布版。

## 更新说明 / What's new

### M1 MVP（核心功能）
- 冒险管理（新建/打开/重命名/删除，多冒险并存，自动保存）
- 冒险主题装配（手动/掷骰，主题骰 10 交替指针自动追踪）
- 情节线/角色列表（分页网格、权重计数器、列表掷骰、空行默认提示）
- 转折点结构化记录（聚焦情节线、三态状态、5 情节点槽位、征引角色、笔记）
- 情节点掷骰（1d100+1d10，96-100 触发元情节点表）
- 角色铸造向导（特质/身份/描述词三表，关联角色查询，"掷两个"提示）
- 「我不知道」操作（重掷/改「无」/改最合理）、掷骰日志、界面中英双语、深色模式

### M2 进阶
- **延续冒险预填**：新建冒险时可选从上一冒险誊入情节线/角色列表（含权重）
- **用法指引**：内置冒险大纲/冒险种子/开场场景/灵感四种用法说明
- **实体骰模式**：全局开关，掷骰按钮变为查询表，玩家掷实体骰后点选确认（MVP 轮次实现并多轮优化）
- **响应式三档布局**：窄屏底部导航栏 / 中屏导航轨 / 宽屏扩展导航轨
- **桌面窗口管理**：默认 1280×800，最小 400×600

### M3 发布
- **冒险存档导出/导入**：单冒险导出为 .json；全量备份打包为 .zip；支持导入恢复（设置页「数据管理」）
- 三平台构建产物 + SHA256 校验值

## 下载 / Downloads

| 文件 | 说明 |
|---|---|
| `adventure_crafter_1.0.0_windows.zip` | Windows 桌面版，解压后运行 `adventure_crafter.exe` |
| `adventure_crafter_1.0.0_android.apk` | Android 版（**debug 签名测试版**，仅供安装试用；正式签名版待密钥材料齐备后发布） |
| `adventure_crafter_1.0.0_web.zip` | Web 版静态文件，解压后对目录起任意静态服务器即可访问 |

## SHA256

```
db5024874e0aa4173b62ca3cae96b999f783ed15fe29d7f2725bf9d0ceb8e8f4  adventure_crafter_1.0.0_android.apk
d67ec4a1d7796e99d6723777f948eb448fc09815b0b641129f46cb61cf97e40c  adventure_crafter_1.0.0_web.zip
fc0ed0010a5d20163e040f9adfd95d05a2fd8d8306977f31ba3e1bb6a5e2cc1f  adventure_crafter_1.0.0_windows.zip
```

## 版权 / License

- 软件代码：[PolyForm Noncommercial License 1.0.0](LICENSE)
- 《The Adventure Crafter》规则文本与表格：依据 [Word Mill Games CC-BY-NC 政策](https://www.wordmillgames.com/license.html)按 [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/) 使用
- 非官方粉丝工具，与 Word Mill Games 或 Tana Pigeon 无隶属关系；**不可商用**
