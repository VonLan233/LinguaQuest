# CLAUDE.md

Always answer in Chinese

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A mobile-development coursework workspace (not a git repo). It holds several independent
projects plus lecture material. There is no top-level build — `cd` into a subproject and
work there. Each Flutter subproject is its own self-contained app.

## Layout

- `ASM2/` — **LinguaQuest**, the main active project: a Flutter app (`linguaquest/`) + optional
  Dart `shelf`/Postgres backend (`server/`). Has its own detailed `ASM2/CLAUDE.md` —
  **read it before touching anything in `ASM2/`.**
- `restaurant_app/` — small standalone Flutter app (course exercise).
- `Dice/dic/` — small standalone Flutter app (course exercise).
- `ASM1/` — LaTeX coursework (assignment write-up, EN + ZH), not code.
- `notes/`, `*.pdf`, `LinguaQuest_*` docs/PNGs — lecture material, PRDs, and UI mockups (reference only).
- `flutter/` — a full Flutter SDK checkout. **This is the toolchain, not a project** — its
  `bin/` is on PATH (`flutter` = 3.41.6 stable). Do not edit or build it.

## Common commands

Toolchain is the bundled `flutter/bin/flutter` (already on PATH). From inside any Flutter
subproject (`restaurant_app/`, `Dice/dic/`, or `ASM2/linguaquest/`):

```bash
flutter pub get
flutter run
flutter analyze
flutter test
flutter test test/<file>_test.dart        # single test file
flutter test --name "<test name>"          # single test by name
```

For LinguaQuest specifics (offline demo mode, backend, localization, design system) see
`ASM2/CLAUDE.md` — that project has conventions the others don't.

## Working rule

Run commands from the relevant subproject directory, never the workspace root. Treat each
subproject as independent — a change in one never affects another.

## 工程质量优先原则

**用时间和 token 换取工程质量。不允许为了节省 token 而偷懒。少写不必要的代码，但绝不少做必要的工程动作。**

### 反偷懒铁律

以下行为**绝对禁止**，违者即为偷懒：

1. **禁止跳过流程步骤** — 任何非平凡任务必须走完完整流程：brainstorming → design → plan → implement → review → verify。跳过任一环节 = 偷懒。
2. **禁止无证据断言** — 绝不可以说"测试通过"、"编译成功"、"服务正常"而不贴出实际运行输出。Claims require evidence, always.
3. **禁止代码摘要** — 不可以写"// 同上"、"similar to above"、"依此类推"来省略实际代码。每一步都必须给出完整可运行的代码。
4. **禁止跳过 Review** — Spec compliance review 和 Code quality review 缺一不可。Review 发现的问题必须修复并重新 review，不可跳过 re-review。
5. **禁止假执行** — 不要"假装"运行了命令。每次运行命令必须展示实际输出。如果命令会失败，展示失败并解释。
6. **禁止偷工减料的实现** — 必须按照 spec/plan 完整实现，不可自行删减需求。YAGNI 是去掉不需要的东西，不是去掉需要的东西。
7. **禁止过度工程** — 不为"未来可能需要"创建接口、基类、工厂、策略层、插件系统、包装层、配置层或目录结构。没有真实重复和真实复杂度，就不抽象。
8. **禁止无必要依赖** — 标准库、平台原生能力或项目已有依赖能解决时，不添加新包、不重造轮子。
9. **禁止聪明化实现** — 优先选择 boring、直接、可维护的方案；能在现有文件内清楚完成时，不新增文件；能用一行清晰代码解决时，不写样板代码。
10. **禁止代码高尔夫** — 追求必要代码最少，不追求晦涩代码最短。可读性、正确性、安全性和可维护性不能被牺牲。

### 必要代码纪律

写任何代码前，必须按顺序停在第一个成立的答案上：

1. **这个东西真的需要存在吗？** — 如果目标可以通过不新增代码、删除代码、复用现有流程或调整需求边界来满足，就不要新增实现。
2. **标准库已经能做吗？** — 优先使用语言和运行时自带能力，不要重新发明。
3. **平台原生能力已经覆盖吗？** — 浏览器、操作系统、数据库、框架原生功能能解决时，优先使用原生能力。
4. **项目已有依赖已经能做吗？** — 如果依赖已经安装并适合当前问题，复用它；不要新增重复依赖。
5. **一行代码能正确表达吗？** — 能用清晰的一行完成时，不要引入包装层、工具类、配置文件或样板代码。
6. **最后才写最小可工作的实现** — 只有前五级都不成立，才新增代码；新增代码必须是满足当前 spec 的最小实现。

复杂需求必须先反问：用户要求复杂方案时，先确认是否真的需要 X，或现有流程、标准库、平台能力、已有依赖 Y 是否已足够。反问是为了找到更小、更稳、更直接的实现路径，不是为了拖延或拒绝用户明确要求。用户确认复杂方案确实需要后，必须按 spec 完整实现，不能继续用 YAGNI 缩水。

有意简化必须用 `ponytail:` 注释标明边界和升级路径，例如全局锁、O(n²) 扫描、朴素启发式、单进程假设、内存数据结构等。标注不是免责：被标注的简化仍必须满足当前 spec、通过验证，并且不能触碰安全、数据完整性或信任边界。

### 不可偷懒区域

以下内容**绝不可因为 YAGNI、少写代码或使用 Ponytail 思路而删减**：

- **信任边界输入校验** — 用户输入、外部 API、文件、网络、数据库结果都必须按风险校验。
- **防止数据丢失的错误处理** — 写入、删除、迁移、支付、权限、并发和恢复路径不能省。
- **安全要求** — 鉴权、授权、注入防护、敏感信息处理、依赖安全和权限边界不能省。
- **无障碍要求** — UI 交互、语义、键盘可达性、焦点管理、标签和对比度不能省。
- **用户明确要求的功能** — YAGNI 只能删除未要求的东西，不能删除已要求的东西。
- **必要验证** — 非平凡逻辑必须留下最小可运行检查；可以小，但不能没有。

### 流程纪律

- **Brainstorming 必须做** — 任何 feature/功能开发，无论多"简单"，必须先 brainstorming。看似简单的东西最容易因为未检查的假设而浪费大量时间。
- **Plan 必须完整** — 计划中每一个 task 必须包含精确的文件路径、完整的代码块、确切的运行命令和预期输出。TBD/TODO/占位符 = 计划失败。
- **TDD 默认开启** — 除非项目无测试框架，否则先写 failing test → 再写最小实现 → 验证 pass。
- **Review 不可跳过** — 每个 task 完成后：spec compliance review → fix → re-review → code quality review → fix → re-review。两阶段都要过。
- **Review 必须查过度工程** — Review 不只检查是否正确，也要检查是否存在可以删除、可以用标准库替代、可以用平台原生能力替代、可以复用已有依赖替代的代码。能删而不损害 spec、验证、安全、错误处理和可访问性的代码，必须列入 delete-list。

### 验证纪律

- 每次声称"完成"前，必须运行验证命令并贴出输出。
- 每次声称"测试通过"前，必须实际运行测试并贴出结果。
- 每次声称"服务正常"前，必须 curl/wget 并展示 HTTP 状态码和响应。
- 不可仅凭 TypeScript 编译通过就声称"没问题"——lint、build、runtime 行为都需要验证。
- 不可用"代码更少"代替验证。少写代码只是实现策略，不是质量证据。

### Token 预算态度

- **不设上限** — 用户明确表示愿意用时间和 token 换工程质量。宁可多花 token 把事做对，不可为了省 token 留下隐患。
- **多 agent 并行** — 独立的探索、review、验证任务应该并行派发 agent，而不是串行省 token。
- **完整 review** — Review agent 必须完整读取所有改动文件，不可只看 diff 就下结论。
- **少写代码，不少做流程** — 可以删除不必要实现、复用标准库、复用平台能力、复用已有依赖，但不能删除 brainstorming、design、plan、implement、review、verify 中任何必要步骤。
