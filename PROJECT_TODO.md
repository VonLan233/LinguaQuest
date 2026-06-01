# LinguaQuest Project Todo

最后审计日期：2026-06-02  
基线分支：`dev` (`d2fab8624e86b9cb6ea34c4d71b09be6be6b1998`)  
需求基线：`LinguaQuest_PRD_Development_Guide.md` v1.0  
相关待合并工作：PR #21 `[codex] Complete API-backed LinguaQuest app`

## 当前结论

`dev` 分支已经具备 Flutter 端主要页面骨架、5 栏导航、离线 mock 登录、基础新学/测验/复习、生词本 CRUD、基础后端账号与自定义词 API。  
距离 PRD 的最终目标仍有明显缺口：真实词书与 UserWord 进度、完整学习计划、混排复习调度、训练场、AI、通知、积分任务、抽奖、论坛、个人空间、排行榜、成就、弱项推荐、CI/发布/隐私风控都需要继续推进。

PR #21 覆盖大量 API 化和 P1/P2 功能，但尚未合并，且仍需要完整回归；本清单以当前 `dev` 为准，并把 PR #21 标记为“待合并验收”。

## P0 核心闭环

- [ ] [#22](https://github.com/VonLan233/LinguaQuest/issues/22) 建立真实词书/词库数据与词书切换闭环
- [ ] [#23](https://github.com/VonLan233/LinguaQuest/issues/23) 为目标词实现 UserWord 进度、掌握维度和复习队列
- [ ] [#24](https://github.com/VonLan233/LinguaQuest/issues/24) 完整实现学习计划设置页
- [ ] [#25](https://github.com/VonLan233/LinguaQuest/issues/25) 重构新学/复习 session 为混排、短间隔复现和错题回收
- [ ] [#26](https://github.com/VonLan233/LinguaQuest/issues/26) 补齐词典搜索与单词详情卡片内容质量
- [ ] [#27](https://github.com/VonLan233/LinguaQuest/issues/27) 合并并验收 API 后端/前端联动能力
- [ ] [#33](https://github.com/VonLan233/LinguaQuest/issues/33) 完成无障碍、音效/震动/高对比和离线体验

## P1 增强学习体验

- [ ] [#14](https://github.com/VonLan233/LinguaQuest/issues/14) 完成消息通知模块
- [ ] [#15](https://github.com/VonLan233/LinguaQuest/issues/15) 完成训练场基础玩法
- [ ] [#16](https://github.com/VonLan233/LinguaQuest/issues/16) 完成积分体系
- [ ] [#17](https://github.com/VonLan233/LinguaQuest/issues/17) 完成发现页任务系统
- [ ] [#18](https://github.com/VonLan233/LinguaQuest/issues/18) 完成积分抽奖
- [ ] [#19](https://github.com/VonLan233/LinguaQuest/issues/19) 完成 AI 学习基础功能
- [ ] [#20](https://github.com/VonLan233/LinguaQuest/issues/20) 扩展练习题型
- [ ] [#33](https://github.com/VonLan233/LinguaQuest/issues/33) 完成无障碍、音效/震动/高对比和离线体验

## P2 社区和个性化

- [ ] [#28](https://github.com/VonLan233/LinguaQuest/issues/28) 实现论坛社区生产闭环
- [ ] [#29](https://github.com/VonLan233/LinguaQuest/issues/29) 实现个人空间、公开资料和隐私设置
- [ ] [#30](https://github.com/VonLan233/LinguaQuest/issues/30) 实现排行榜、成就系统和学习分析真实数据
- [ ] [#31](https://github.com/VonLan233/LinguaQuest/issues/31) 实现个性化弱项分析和题型推荐
- [ ] [#32](https://github.com/VonLan233/LinguaQuest/issues/32) 完成 AI 作文批改、结构化输出和隐私说明
- [ ] [#35](https://github.com/VonLan233/LinguaQuest/issues/35) 补齐社区审核、举报、AI 安全和用户数据设置

## 工程化与发布

- [ ] [#34](https://github.com/VonLan233/LinguaQuest/issues/34) 建立 CI、测试矩阵、截图资产和发布验收
- [ ] [#36](https://github.com/VonLan233/LinguaQuest/issues/36) 补齐生产部署、环境配置和 Android 发布链路

## PR #21 验收重点

- [ ] 不把 PR #21 当作已完成进度，必须先合并或拆分 review。
- [ ] 验证新增数据库迁移能从当前 `dev` 后端安全升级。
- [ ] 验证新增 API 覆盖 PRD 数据模型：User、Word、WordBook、UserWord、StudyPlan、StudySession、ExerciseRecord、RewardTask、ForumPost、Notification。
- [ ] 验证训练场动态 lesson id，不再依赖 stale hardcoded route id。
- [ ] 验证 Flutter app 在无后端、后端不可用和 API mode 下都有明确行为。
- [ ] 跑通 server tests、Flutter analyze、Flutter tests、Android build smoke test。

## 已验证状态

- `dev` 分支 `server`: `dart test` 通过。
- `dev` 分支 `linguaquest`: `flutter analyze --no-pub` 通过。
- `dev` 分支 `linguaquest`: `flutter test` 被 Windows Developer Mode/symlink support 限制阻断，未进入测试本体。
- PR #21 worktree `server`: `dart test` 通过。
- PR #21 worktree `linguaquest`: `flutter analyze --no-pub` 通过；`flutter pub get` 同样被 symlink support 限制阻断。

## GitHub Project 同步说明

已同步到 GitHub Issues：#14-#20 已补充详细验收清单，#22-#36 已新建。  
如果仓库存在 GitHub Projects 看板 `project-todo`，当前 `gh` token 缺少 `read:project/project` scope，无法把 issues 批量加入看板。补充 scope 后，可按本文件顺序把所有 open PRD issues 加入项目看板。
