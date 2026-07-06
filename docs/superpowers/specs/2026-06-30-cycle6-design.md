# Cycle 6 设计：TTS/模型/训练平铺/每日词/删 Study Map+Spot/学习计划/复习量/Me 设置/Daily Article/社区

- **日期：** 2026-06-30
- **分支：** `feat/P2-roadmap`
- **来源：** 用户「修改要求.md」18 项。本 spec 只覆盖**剩余 12 项**；下列已完成/取消项不在范围。

## 已完成 / 取消（不实做，仅记录）
- **#5** 词书完整（HSK1-6 + JLPT N5-N1 数据齐 + 客户端已加载）— 已完成。
- **#11** 写作 exam type 已是 General/Academic/Business/Casual — 已完成。
- **#2 的 cloze 部分** 已部署 deepseek-v4-flash — 已完成（本 spec 扩展到其余 AI）。
- **#12** 取消（用户决定保留全部 6 种语言选项，不删 en/es/fr）。
- **#16** 无需改动（语言选择器与世界地图当前都已是 6 种，本就一致；用户要"与选择器一致"= 维持现状）。

---

## 全局约束（Global Constraints）
- 全程中文回复；commit **不带 Co-Authored-By**。
- App 为 light-only 基础上的深色 reskin；新增/改动 UI 用主题 token，保证深色背景可读。
- 服务端改动用户**已预授权部署**到 `api.vonlan233.top`（rsync + `deploy/vps_deploy.sh`，保留远程 `.env`/`.env.prod` 与 db 卷）。
- 现有测试保持绿：`flutter test`/`flutter analyze`（client，在 `linguaquest/`）；`dart test`/`dart analyze`（server，在 `server/`）。
- 删除功能（#6/#7）必须前后端引用清理干净，`flutter analyze`/`dart analyze` 无 unused/dangling。
- 测试 harness 复用 `_FakeAppController extends AppController { build() => state }` + ProviderScope override 模式。

---

## #1 + #15：中文发音只用本地 flutter_tts
**现状：** `pronunciation_service.dart` 对所有语言走"有道音频 URL → 失败回退 flutter_tts"。有道是网络请求，慢/不稳（#1）。
**方案：** 中文（`language=='zh'` 或 CJK 检测为中文）场景**跳过有道音频，直接用 flutter_tts**（本地、即时、稳定）。非中文（en 等）维持"有道→回退"不变。
- 改 `lib/core/services/pronunciation_service.dart` 的 `play()`：当目标语言为中文时，不尝试 audioUrl，直接走 tts(zh-CN)。
- 客户端给非中文的有道音频播放加一个较短超时（如 6s）后即回退 tts，避免 #1 的长等待（复用现有 receiveTimeout 或在播放层加超时）。
**验收：** 单测：中文词调用 `play()` 不触发 url 播放、直接 tts；非中文仍优先 url。设备：中文发音即时响应。

## #2：全部 AI 功能改用更快模型
**现状：** 仅 cloze 用 `AI_CLOZE_MODEL=deepseek-v4-flash`（线上已部署）；其余 6 功能用默认 `aiModel='deepseek-v4-flash-free'`（慢）。
**方案：** 把服务端**默认 `aiModel` 改为 `deepseek-v4-flash`**（已验证 ~9s 稳定、格式兼容），令 chat/sentence-analysis/confusion/sentence-gen/reading-explain/writing-review 全部提速。`AI_CLOZE_MODEL` 可保留或清空（默认已是 flash，cloze 一致）。
- 改 `server/lib/src/config.dart`：`aiModel` 默认 `'deepseek-v4-flash-free'` → `'deepseek-v4-flash'`；同时部署时设环境变量 `AI_MODEL=deepseek-v4-flash`（env 覆盖默认）。
- `.env.example` 记录 `AI_MODEL`。
**验收：** server 单测改 model 断言；部署后用 token 实测 `/ai/confusion` 或 `/ai/sentence` 明显快于免费模型。需部署。

## #3：Training 页面全部训练项平铺
**现状：** `training_screen.dart` 三个分组：Campus Section(45) / Timed Tests(60) / Special Drills(73)，共 6 个 `_TrainingGameRow`（Campus Sprint、Speed Game、Survivor、Spelling、Passage Cloze、Listening）。
**方案：** 删除全部 3 个 `SectionHeader` 与分组间距，6 个训练项合并进**单个 `_TrainingGameList`** 平铺。各项路由/玩法不变。
**验收：** widget 测试断言无 SectionHeader、6 个训练项都在；点击路由不变。

## #4：每日一词按日轮换
**现状：** `home_screen.dart:49-51` 取 `currentLesson.words.first`（固定）。
**方案：** 用**当日日期种子**确定性选词：`words[dayIndex % words.length]`，`dayIndex = 本地日期的 epochDay`（同一天稳定、跨天变化）。词池用 currentLesson.words（与现状同源，避免空池）。不引入随机不可复现。
**验收：** 单测：纯函数 `wordOfDayIndex(epochDay, len)` 同日同值、跨日变化、len=0 安全；设备隔日不同词。

## #6：彻底删除 Study Map（仅前端）
**删除清单：**
- `lib/features/map/study_map_screen.dart`（整文件）
- `app_router.dart`：第 60 行 import + 第 234 行 `/map` 路由
- `app_drawer.dart`：第 33 行 "Study Map" 菜单项
- `test/features/study_map_smoke_test.dart`（整文件）
> 注意：`language_map_screen.dart`（选语言世界地图）**不删**，与本项无关。
**验收：** `flutter analyze` 无 unused import/dangling；`flutter test` 绿；侧边栏无 Study Map 入口。

## #7：彻底删除 Study Spot（前端 + 后端）
**前端删除：**
- 文件：`lib/data/models/study_spot.dart`、`lib/data/repositories/study_spot_repository.dart`、`lib/features/map/study_spots_list_screen.dart`、`test/data/study_spot_test.dart`、`test/data/mock_study_spot_repository_test.dart`、`test/data/study_spot_record_visit_test.dart`、`test/data/study_spot_state_test.dart`、`test/features/study_spots_list_test.dart`。
- 代码点：`app_router.dart:61` import + `:235` `/map/spots` 路由；`app_drawer.dart:34` 菜单项；`app_controller.dart` 的 import(43,45)、`studySpotRepositoryProvider`(151-155)、`loadStudySpots/saveStudySpot`(2940-2947)、`deleteStudySpot`(2950-2952)、`recordVisit` 内对 loadStudySpots 的调用(2978-2979)；`app_state.dart` import(17)、`studySpots` 字段(144,188,371,422,457)。
- mock/api repositories 里的 StudySpot 仓库实现一并删。
**后端删除：**
- 文件：`server/lib/src/study_spot_policy.dart`、`server/test/study_spot_policy_test.dart`。
- 代码点：`database.dart:8` import、`:459-473` CREATE TABLE study_spots+索引+ALTER、`:2059-2143` listStudySpots/recordStudySpot/deleteStudySpot；`routes.dart:28` import、`:1398-1429` GET/POST/DELETE `/study-spots` 三端点。
> 不删 study_spots 表的**已存数据迁移**：保留 `CREATE TABLE IF NOT EXISTS` 删除即可（新部署不再建表；已存表留着无害，不写删表迁移以免误删数据）。`ponytail:` 仅停用代码路径，不 DROP 线上表。
**验收：** `flutter analyze`/`dart analyze` 无 unused/dangling；`flutter test`/`dart test` 绿（删掉相关测试后）；侧边栏无 Study Spot；后端无 `/study-spots` 端点（curl 404）。

## #8 + #10：移除 completion date 显示
**现状：** Cycle 5 已删手填日期、改 `studyPlanAutoFinishDate` 自动推算，但 `targetFinishDate` 字段 + hero 的 "X days left" 徽章(study_plan_settings_screen.dart:150-152,518-520) + 后端必填校验仍在；#10 的中文日期显示即来自这些显示点。
**方案：** **UI 彻底不显示 completion date**：
- 删 `_PlanHeroCard` 的 daysLeft pill 及其入参（150-152、518-520）。
- `targetFinishDate` 字段**保留**（后端 `validateStudyPlanPayload` 仍必填 startDate+targetFinishDate），由 `studyPlanAutoFinishDate` 自动算并随 plan 保存——纯内部，用户看不到 → #10 中文显示问题随之消失。
- 不动后端校验（保持 plan 合法）。若 `daysLeft()`/`studyPlanDaysLeft` l10n 变成全无引用，则删（analyze 驱动）。
**验收：** 设置页与首页无任何"完成日期/剩余天数"显示；`flutter analyze` 干净；study_plan 相关测试调整后绿。

## #9：每日复习数量系统自动生成
**现状：** `study_plan_settings_screen.dart` 有 "Daily Review Limit" 手填框(_dailyReviewController, 183-191) → plan.dailyReviewLimit。
**方案：** 删除该手填框；`dailyReviewLimit` 改为**系统按当前到期待复习词数自动确定**：保存计划时 `dailyReviewLimit = dueWords.length`（上限保护，如 clamp(.,0,200)）。app_state 的复习队列读该值。后端 `dailyReviewLimit` 校验保持（仍传一个自动算的合法值）。
**验收：** 单测：给定 dueWords 数 → 自动 limit 正确（含上限）；设置页无复习数输入框；保存的 plan 通过后端校验。

## #13：Me 页面新增 Settings 入口
**现状：** Settings 仅侧边栏可进(`app_drawer.dart:37` → `/settings`)；`profile_screen.dart` 只有分散子项，无总 Settings 入口。
**方案：** 在 `profile_screen.dart` 加一个 `_SettingsItem`（icon=AppIcons.settings，title 用现有/新增 l10n，`onTap: context.push('/settings')`），复用现有列表样式。
**验收：** widget 测试：Me 页存在跳 `/settings` 的入口；`flutter analyze` 干净。

## #14：Daily Article 跳转修正
**现状：** `home_screen.dart:196` Daily Article `onTap: context.go('/ai-learning')`（错）。正确短文阅读路由 `app_router.dart:141-143` `/reading` → `ReadingListScreen`。
**方案：** 改为 `context.push('/reading')`。
**验收：** 点击 Daily Article 进入短文阅读列表，不再进 AI Learning；widget/路由测试可断言目标。

## #17：社区帖子"过一天消失"——排查 + 修复
**现状：** 后端**未发现** DELETE/TTL/定时清理代码；`listForumPosts` 按 `created_at DESC` 返回全部（可选 status 过滤）。根因未定。
**方案（systematic-debugging）：** 先复现/定位：检查 (a) 帖子创建时的 `status` 默认值与列表查询是否按 status 过滤（pending/hidden 导致看不到）；(b) `moderation_policy` 是否自动改状态；(c) 部署是否曾重建 db 卷致数据丢失（当前 deploy 脚本 `--no-recreate db`，应不会）。定位后针对性修复或确认非代码问题（出报告）。
**验收：** 给出根因证据；若为代码问题则修复 + 回归测试（创建帖子→重取仍在）；若确认非代码（如历史部署重置）则书面说明并加防护（如列表不按致隐藏的 status 过滤）。

## #18：社区发帖用真实昵称 + 头像
**现状：** 前端 `forum.dart` 已支持 `authorName`（缺省 'Anonymous'），列表已显示 `post.authorName`；但后端 `_forumPostDto`(routes.dart:1438-1457) 只返回 `authorId`，不返回 authorName；users 表无 avatar 字段。
**方案：**
- 后端：`listForumPosts`/`getForumPost`(database.dart:2153-2171) 改为 `LEFT JOIN users` 取 `name`（和头像）；`_forumPostDto` 增加 `authorName`（+ `authorAvatar`）。
- 头像：users 表若无头像列，加 `avatar TEXT`（或复用注册时的 avatar 字段——实现时核实 users 表结构与注册是否已存头像）；DTO 返回 `authorAvatar`。
- 前端：`forum.dart` 增加 `authorAvatar` 字段；社区列表/详情展示头像（无头像用默认占位）。发帖时作者取当前登录用户（已有 author_id），无需匿名。
**验收：** 后端单测：DTO 含 authorName/authorAvatar；前端展示真实昵称+头像；发帖后显示自己的昵称而非 Anonymous。需部署（后端）。

---

## 任务分解预览（writing-plans 细化）
1. #14 Daily Article 跳转（1 行 + 测试）— 最小。
2. #13 Me 页 Settings 入口。
3. #3 Training 平铺。
4. #4 每日一词按日轮换（纯函数 + 接线 + 测试）。
5. #1+#15 中文 TTS 本地化。
6. #8+#10 移除 completion date 显示。
7. #9 复习数自动（与 #6 同改 study_plan_settings，注意顺序）。
8. #6 删 Study Map（前端）。
9. #7 删 Study Spot（前端 + 后端）。
10. #2 服务端默认模型→flash（+部署）。
11. #18 社区昵称+头像（前后端 + 部署）。
12. #17 社区帖子消失排查（systematic-debugging）+ 修复。
13. 验证 + 设备复测 + 服务端部署（#2/#7/#18 需部署）。

> #6/#7 同域（features/map、app_drawer、app_router、StudySpot 被两者用）需一并处理；#8/#9 同改 study_plan_settings_screen 需顺序。
