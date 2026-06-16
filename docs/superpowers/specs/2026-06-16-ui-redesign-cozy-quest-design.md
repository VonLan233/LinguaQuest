# LinguaQuest 前端重设计 · Cozy Quest 设计规范

> 状态：已通过 brainstorming，待用户复核 → writing-plans
> 日期：2026-06-16
> 分支基线：`feat/ui-friendly-quest-reskin`

## 1. 背景与目标

现有 Flutter 前端（`linguaquest/lib`）的"Friendly Quest"扁平风格被**弃用**。我们保留其全部**功能与数据层**，但**重做整套视觉系统与所有页面 UI**。

参考素材 `../LinguaQuest_UI_Single_Pages`（10 张）仅用于理解功能与信息架构，**严禁照抄实现或像素级复制**。新设计原创，并紧扣品牌 Logo（`linguaquest/lib/assets/image/icon.png`：天蓝圆角底、藏青猫脸、白色月牙眼、柠檬绿+橙点缀的友好蓝猫）。

### 确定的范围（brainstorming 结论）

- **范围**：全套设计系统 + 全部页面（约 40 个路由，见 §8）。
- **暗色模式**：本轮**仅做亮色**；暗色作为后续扩展，token 预留但不实现。
- **吉祥物**：蓝猫**贯穿式角色**，出现在问候、空状态、奖励、加载、连击鼓励等处。
- **平台**：**仅 Android**（同一套 Flutter UI，本轮不为 iOS 额外打磨）。

### 设计基调：Cozy Quest

一套融合方向：**A 温暖陪伴为主调，融入 B 的专业可信与 C 的年轻活力**。
暖底圆润是基调；蓝色担当信任主行动；高饱和色（橙/绿/珊瑚）只在 XP、连击、闯关进度等**小面积点睛**。

## 2. 设计原则（"乔布斯级"克制）

这些是评审每个页面的硬标准：

1. **背景隐形化** — 背景近白暖中性，衬托内容、不抢戏。
2. **单层柔阴影** — 每张卡只一层低透明柔影；禁止双重/锐利投影。
3. **舍得留白** — 元素更少、间距更大；一屏聚焦一件事。
4. **字阶克制** — 大号粗数字 + 小而淡的标签，强对比、去文字噪音。
5. **色彩有纪律** — 彩色仅用于有意义处（XP、进度、连击、状态）；其余皆中性。
6. **内容优先** — 装饰服务于可读性与可操作性，绝不为炫技牺牲清晰。

## 3. 颜色 Token（亮色）

> 落地为 `core/theme/app_tokens.dart` 的新版本（替换现有调色板），并由 `app_theme.dart` 构建 Material 3 ThemeData。命名沿用现有风格便于迁移。

### 中性/背景
| 角色 | Hex | 用途 |
| --- | --- | --- |
| `bgCanvas` | `#FAF8F5` | **暖瓷白**，页面背景（定稿） |
| `surface` | `#FFFFFF` | 卡片/容器 |
| `surfaceSunken` | `#F2EFEA` | 进度条槽、次级填充 |
| `hairline` | `#ECE7E0` | 1px 分隔线/描边 |
| `textPrimary` | `#233A66` | 藏青，标题/正文主色 |
| `textSecondary` | `#6B6B73` | 次要文字 |
| `textHint` | `#A59B8C` | 暖灰，提示/占位 |

### 品牌/功能色
| 角色 | Hex | 用途 |
| --- | --- | --- |
| `primary` (Azure) | `#2C7BE0` | **主行动/信任色**：主按钮、选中态、关键数字 |
| `primaryPressed` | `#1F5FAE` | 主按钮立体底边/按下态 |
| `sky` | `#8FD0F2` | 主色浅调：渐变、装饰、图标底 |
| `brandNavy` | `#233A66` | 深色块、英雄区背景（吉祥物场景） |
| `xp` (Mango) | `#FFB22E` | XP/奖励徽章、进度起点 |
| `success` (Lime) | `#5FB23C` | 达成/闯关/正确、进度终点 |
| `streak` (Coral) | `#FF6B5A` | 连击🔥、紧迫、错误 |

### 语义浅底（徽章/提示条背景）
| 角色 | Hex |
| --- | --- |
| `xpSoft` | `#FFF1D6` (文字 `#E08A00`) |
| `successSoft` | `#F2FAEC` (描边 `#DDEFCE`，文字 `#3F7A22`) |
| `streakSoft` | `#FFE2DC` (文字 `#E8503B`) |
| `primarySoft` | `#EAF2FC` (文字 `#2C7BE0`) |

进度条标准填充：`linear-gradient(90deg, #FFB22E → #5FB23C)`（橙到绿，象征"从开始到达成"）。

## 4. 排版 Token

- 字体：跟随系统（Android：Roboto / Noto Sans CJK）。标题偏圆润饱满，正文清晰。后续若引入自定义圆体字再评估。
- 字阶（sp）：`display 34/800` · `h1 22/800` · `h2 18/800` · `title 16/700` · `body 14/500` · `label 12/600` · `caption 11/500`。
- 数字强调：关键指标用 `display`/`h1` + `800` 字重 + `-1px` 字距；配套标签用 `caption`/`label` + `textHint`。

## 5. 形状 / 阴影 / 动效 Token

- 圆角：`radiusCard 22` · `radiusButton 18` · `radiusTile 18` · `radiusSheet 26` · `radiusChip 12` · `radiusPill 999`。
- 间距：沿用 4 基准 `s4 s8 s12 s16 s20 s24 s32`；卡片内边距默认 `s16`，卡片间距 `s12`。
- 阴影：`shadowCard = 0 6px 22px rgba(40,40,60,.06)`（单层柔影）；`shadowNav = 0 -2px 12px rgba(120,90,40,.06)`。
- 动效：`fast 180ms` · `medium 260ms`，标准曲线 `easeOutCubic`；按钮按下下沉 2px。

## 6. 组件语言

统一沉淀到 `core/widgets/`（替换/重写现有共享组件；废弃旧 `QuestPanel` 等扁平原语）。

- **主按钮 PrimaryButton**：Azure 实底、白字、`radiusButton`、轻微 3D 底边（`primaryPressed` 2px）、按下下沉。
- **次按钮 SecondaryButton**：白底、Azure 字、2px `primarySoft`/描边。
- **卡片 AppCard**：白底、`radiusCard`、`shadowCard`、内边距 `s16`。
- **徽章 Pill / 状态条**：胶囊，语义浅底 + 深字（XP/连击/状态）。
- **进度条 AppProgressBar**：`surfaceSunken` 槽 + 橙→绿渐变填充 + 圆头。
- **环形进度 ProgressRing**：用于完成度/正确率。
- **数据小卡 StatTile**：图标 + 大数字 + 小标签，三联横排。
- **底部导航 AppBottomNav**：白底、`shadowNav`、5 项、选中 Azure。
- **空状态 EmptyState**：蓝猫插画 + 一句鼓励 + 行动按钮。
- **输入框 / 列表行 / Sheet / Toast / 奖励弹窗**：统一圆角与色彩纪律。

> 图标：本轮先用 Material/Cupertino 图标统一线性风格；占位 emoji 仅用于 mockup，实现时替换为图标体系。

## 7. 吉祥物系统（蓝猫贯穿）

- **问候头像**：首页/我的的头像位以蓝猫呈现。
- **空状态**：词书空、错题空、搜索无结果等，用不同表情的蓝猫插画。
- **奖励与里程碑**：每日奖励、连击达成、升级弹窗由蓝猫"出场"庆祝。
- **加载/过渡**：蓝猫小动画作为 loading。
- **闯关鼓励**：训练/挑战中的正反馈由蓝猫表达。
- 资产：以现有 `assets/image/icon.png` 为形象基准，按需补充表情/姿态插画（实现阶段产出，列入计划）。

## 8. 导航与页面清单

**底部 5 Tab**（沿用 `ShellRoute`）：首页 `🏠` / 学习 `📚` / 训练场 `⚔️` / 复习 `🔁` / 我的 `🐱`。
（对应现有 `/home` `/ai-learning`(或学习入口) `/training` `/review` `/profile`，具体 Tab→路由映射在计划阶段定。）

全部待重做页面（按现有路由，功能不变）：

- **入门/认证**：`/`(splash) `/onboarding` `/login` `/register` `/goal-setup`
- **主 Tab**：`/home` `/training` `/ai-learning` `/discover` `/profile` `/quest`
- **学习流**：`/learn`(学习路径) `/lesson/:id`(预览) `/lesson/:id/quiz` `/lesson/:id/result` `/study/new` `/study/review`
- **训练**：`/training/:game` `/timed-test/:id`
- **复习**：`/review` `/mistake-book`
- **词书**：`/wordbook` `/wordbook/:id` `/custom-words` `/custom-words/new` `/custom-words/:id` `/custom-words/:id/edit`
- **任务中心/发现**：`/discover/xp-tasks` `/discover/lucky-draw` `/discover/community`
- **班级/排行/分析**：`/quest` `/leaderboard` `/progress` `/class-mode` `/class-progress` `/ai-tutor`
- **设置/其它**：`/settings` `/settings/study-plan` `/settings/theme` `/settings/reminder` `/help` `/about` `/notifications` `/search`

## 9. 保留 vs 弃用

**保留（不动）**：
- 数据层：`data/models/*`、`data/repositories/*`（Mock + Api 双实现）、`data/remote/api_client.dart`。
- 状态层：Riverpod、`AppController`/`AppState` 的业务逻辑与 provider 接线。
- 路由：GoRouter 结构与路径（屏幕实现替换，路由表基本沿用）。
- i18n：`l10n` 三语机制；新组件文案继续走 `AppLocalizations`。
- 后端 `server/`：**完全不改**，接口契约见 README 端点表与 `server/lib/src/routes.dart`。

**弃用/替换**：
- 旧视觉系统：`core/theme/app_tokens.dart` 调色板、`app_theme.dart` 主题构建 → 按本规范重写。
- 旧共享组件：`core/widgets/*` 扁平原语 → 按 §6 重写。
- **`test/ui_style_guard_test.dart`** 强制扁平风（禁阴影/渐变/卡片）→ **删除或重写**，因新风格刻意使用柔阴影与渐变点缀。
- 各 `features/*/` 屏幕 UI → 逐页重做。

## 10. 实现策略（交给 writing-plans 细化）

建议分层推进，先地基后页面：

1. **设计系统地基**：新 `app_tokens.dart` + `app_theme.dart` + §6 共享组件库 + 组件 widget 测试；同步删除/重写 `ui_style_guard_test.dart`。
2. **吉祥物资产**：补充蓝猫表情/空状态插画资产并登记 `pubspec.yaml`。
3. **核心流程页**：首页 → 学习路径 → 词卡/识别题 → 复习中心 → 我的（验证设计系统跑得通）。
4. **其余页面**：训练场、词书、任务中心/发现、班级/排行/分析、设置等批次推进。
5. 每批次：`flutter analyze` + `flutter test` 必须通过；UI 走查对照 §2 原则。

## 11. 非目标（本轮不做）

- 暗色模式实现（仅预留 token）。
- iOS 专项打磨。
- 后端/接口/数据模型变更。
- 新功能（仅重做现有功能的 UI）。

## 12. 风险

- **AppController 体量大**（~2200 行）：重做 UI 时尽量只改 view 层，避免牵动状态逻辑；若某页耦合过紧，作针对性解耦但不扩大范围。
- **i18n 回归**：替换组件时保持所有可见文案走 `AppLocalizations`，避免硬编码导致三语缺失。
- **截图/资产缺失**：蓝猫插画需新产出，列入计划工作量。
