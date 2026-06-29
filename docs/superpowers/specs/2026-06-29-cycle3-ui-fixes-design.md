# Cycle 3 UI 修复 — 设计

日期：2026-06-29
分支：feat/P2-roadmap
范围：三个从设备测试中报告的 UI 缺陷 —— 语言选择器药丸对齐、词书 Current 状态不跟随切换、发帖/社区 chip 文字在 light mode 下白底白字。

约束：无新依赖；不破坏 light/dark 两套主题；改动后 `flutter analyze` + `flutter test` 全绿。UI 文案沿用现有 l10n / 硬编码英文惯例（本轮不新增文案）。

---

## 问题 1 — 语言选择器右侧药丸不对齐

### 根因
`lib/core/widgets/language_wordbook_picker.dart` 的 `_LanguageRow.build`（约 357 行起）布局为：
```
Row(children: [
  Flexible(child: Text(label)),
  const Spacer(),
  if (isCurrent) AppPill(Current) else if (!isActive) AppPill(ComingSoon),
  if (isActive && !isCurrent) Padding(chevron),
])
```
`Flexible`（flex 1, loose）与 `Spacer`（flex 1）同时存在、平分弹性空间，导致药丸的水平位置随 label 长度浮动、右缘参差。对照之下，词书行 `_WordbookRow` 用的是 `Expanded(child: Text)`（无 Spacer），所以词书列表的右侧 Current 是对齐的。

### 修复
把 `_LanguageRow` 的 `Flexible(child: Text)` 改为 `Expanded(child: Text)` 并删除其后的 `const Spacer()`，与 `_WordbookRow` 一致。这样 Text 占满左侧剩余空间，药丸/箭头紧贴右内边距，6 行右缘严格对齐。

### 验证
- 选择器 widget 测试：渲染 level-1 语言列表，断言每行药丸右缘一致（或更稳妥地断言 `_LanguageRow` 子树中不再有 `Spacer`，且 `Expanded` 存在）。
- 视觉：Chinese 的 Current 与 en/es/fr/ms 的 Coming Soon 药丸右缘对齐。

---

## 问题 2 — 词书 "Current" 不跟随选择切换

### 根因（两层）
1. **看不到变化（主因）**：`_onBookSelected`（picker:134-171）在切换成功后**立即调用 `widget.onDismiss()` 关闭 sheet**（line 162），用户没有机会看到选中词书亮起 Current、其余熄灭。
2. **可能回退（次因）**：`bootstrap` 计算最终 `currentWordBookId`（`lib/core/state/app_controller.dart:290-295`）的 `savedId` 只用 `studyPlan?.wordBookId ?? prefs.getString(_currentWordBookIdKey)`，**漏读 per-language 键** `_currentWordBookIdForLangKey(currentLanguage)`；而保存端 `_saveCurrentWordBookId`（2322-2328）是**双键写入**。读写不对称，在全局键与 per-language 键不一致（保存竞态、或仅离线写入某一键）时，重启后可能读到旧词书。

切换本身（`switchWordBook` 688-760 / `switchScope` 816-827）逻辑正确：更新 `state.currentWordBookId`、双键持久化、API 模式下 `save(studyPlan)`。选择器 `_WordbookRow.isCurrent = book.id == currentWordBookId`（452）与 `ref.watch`（176）均正确，state 变化会触发重建。

### 修复
- **(a) UX 即时反馈**：`_onBookSelected` 切换成功后**不再立即 `onDismiss()`**。改为 `setState(() {})` 触发选择器重建——此时 `state.currentWordBookId` 已更新，选中词书行即时高亮 Current、其余熄灭。保留成功 snackbar。用户自行点 ✕ / 返回关闭 sheet。
  - 失败分支（`pickerSwitchFailed`）行为不变。
  - 从地图进入（`switchScope` 切换了语言）时同样适用：切换后停留在词书步、显示新 Current。
- **(b) 读写对称**：`bootstrap` 第 290-295 行的 `savedId` 改为
  `studyPlan?.wordBookId ?? prefs.getString(_currentWordBookIdForLangKey(currentLanguage)) ?? prefs.getString(_currentWordBookIdKey)`，
  与保存端双键写入对称，重启后稳定保持上次选择。

### 验证
- 选择器 widget 测试：在含 hsk1（current）+ hsk2 的状态下打开词书步，点击 hsk2，断言 sheet 未关闭且 hsk2 行显示 Current 徽章、hsk1 不再显示。
- app_controller 测试：在仅写入 per-language 键的前提下 bootstrap，断言 `currentWordBookId` 取到 per-language 键的值（而非默认 hsk1）。
- 设备实测（release build）：选不同词书 → Current 即时跟随；重启 app → 保持上次选择。

---

## 问题 3 — 发帖/社区 chip 文字在 light mode 下白底白字

### 根因
两处 chip 均为原生 `ChoiceChip`、无自定义样式，完全继承全局 `ChipThemeData`：
- 发帖页 Tag：`lib/features/discover/forum_compose_screen.dart:132-142`
- 社区筛选：`lib/features/discover/community_screen.dart:140-149`

全局 `ChipThemeData.labelStyle`（`lib/core/theme/app_theme.dart:221-232`）被设为
`chipLabelStyle = WidgetStateTextStyle.resolveWith((states) => ...)`（124-137）。
**实测探测**（渲染 `ChoiceChip` 取其 `RichText` 的 effective `style.color`）在 light/dark × selected/unselected 四种情况下**全部为 `null`** —— 即 `ChoiceChip` 并不 resolve 这个 `WidgetStateTextStyle`，label 颜色未受控，回退到默认色，在 light 白底上呈现为不可见的浅色（dark 下碰巧可见）。commit 96a50c3 当初想用 `WidgetStateTextStyle` 让 selected 变色，但该方案在 `ChoiceChip` 上无效。

### 修复
把 `chipLabelStyle` 从 `WidgetStateTextStyle` 改为**带确定颜色的普通 `TextStyle`**：
`chipBaseStyle.copyWith(color: scheme.onSurface, fontWeight: FontWeight.w600)`。
- 普通 TextStyle 的 color 会被 `ChoiceChip` 正确应用（不依赖 resolve）。
- light：`onSurface = 0xFF233A66`（深蓝）→ 可读；dark：`onSurface = 0xFF E6EEF8`（浅）→ 在暗底可读。
- selected 态：保留现有 `selectedColor`（light `mint` 浅蓝底 / dark `primaryContainer` 深蓝底）作为视觉区分；selected 文字同为 `onSurface`，与各自背景对比充足（light 深蓝字配浅蓝底、dark 浅字配深蓝底）均可读。
- `secondaryLabelStyle` 同步改为同一普通 TextStyle。
- 不再区分 selected 的高亮 primary 色 / 加粗差异（可读性优先；selected 已有背景色区分）。

> 影响面：全局所有 `ChoiceChip` 统一变为受控可读颜色 —— 这是修复，不是回归。`app_theme_test.dart` 中锁定旧 `WidgetStateTextStyle`/选中态颜色的断言需相应更新为新行为（断言 labelStyle 为可解析的非空 onSurface 颜色）。

### 验证
- 主题测试：渲染 `ChoiceChip` under `AppTheme.light()` 与 `AppTheme.dark()`，断言其 label 的 effective color **非 null** 且等于对应 `onSurface`（light=textPrimaryLight，dark=textPrimaryDark）。
- 设备实测：发帖页 Tag chips、社区筛选 chips 在 light 下文字清晰可见（深色）。

---

## 不在本轮范围
- 不改 chip 的形状/背景/选中色逻辑（仅修文字颜色受控问题）。
- 不动语言/词书的切换业务逻辑（仅修 UX 关闭时机 + bootstrap 读取对称）。
- 服务器无改动；无需部署。客户端改动随 APK 生效。

## 计划分解（预览）
1. 问题 1：`_LanguageRow` Expanded 化（+ picker 测试）。
2. 问题 2：`_onBookSelected` 不立即关闭 + `setState`；bootstrap savedId 补 per-language 键（+ picker / controller 测试）。
3. 问题 3：`chipLabelStyle` 改普通 TextStyle（+ 更新 app_theme_test 断言）。
