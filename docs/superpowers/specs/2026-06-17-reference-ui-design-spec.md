# Reference UI Design Spec — Full Screen Rebuild

**Date:** 2026-06-17
**Author:** UI research pass over 10 reference comps
**Status:** Implementation-ready build target
**Source comps:** `/Users/lanyichen/Codes/Mobile/LinguaQuest_UI_Single_Pages/01..10.png`
**Current tokens:** `/Users/lanyichen/Codes/Mobile/ASM2/linguaquest/lib/core/theme/app_tokens.dart`

> Purpose: a single, concrete build target so a Flutter team can rebuild every screen to match the comps. Hex values are eyedropper estimates from the rendered PNGs (±a few points). Where the comp matches an existing `AppTokens` value, it is called out; where it does not, the gap is flagged.
>
> **Headline takeaway:** the comps are **denser, more colorful, and more information-rich** than the current minimalist "Cozy Quest" reskin. They are list-heavy with many small colored chips, thin hairline dividers, tight vertical rhythm (~8–12px gaps), and compact cards. The current build is too airy / whitespace-heavy; the target packs 6–10 list rows per screen with multi-metadata per row.

---

## A. Global design language (extracted from the comps)

### A.1 Palette

| Role | Comp hex (est.) | Existing `AppTokens` | Match? |
|---|---|---|---|
| Primary blue (buttons, active tab, headword, links) | `#2F6BF0` / `#2C6FE8` | `azure #2C7BE0` | ~Match (comp slightly more saturated/indigo; keep `azure`, consider a touch bluer) |
| Primary blue pressed | `#1F54C4` (est.) | `azurePressed #1F5FAE` | Close; comp pressed is a bit deeper |
| Hero/cover card blue gradient | `#3A6FE0 → #2453C4` (deep azure→indigo) | none | **GAP** — add a hero gradient token |
| Primary-soft chip bg (selected tag, info pill bg) | `#E8F0FE` / `#EAF2FF` | `primarySoft/chipLight #EAF2FC` | Match |
| Success green (correct option, 近义 synonym, 已学/已完成) | `#34B45A` / `#3FB45C` | `success #5FB23C` | Close-ish; comp green is a bit cooler/bluer than `#5FB23C`. Consider `#3FB45C`. |
| Success-soft bg | `#E7F7EC` | `successSoft #F2FAEC` | Match (comp a touch greener) |
| Synonym chip text/icon (近义词) | green `#2FA84F` | use success | derive |
| Antonym red (反义词, wrong/low-accuracy, 退出登录) | `#E5484D` / `#EB5757` | `coral #FF6B5A` | **GAP-ish** — comp antonym red is a truer red, less coral/orange. Add `danger #E5484D`. |
| Antonym-soft bg | `#FDECEC` | `streakSoft #FFE2DC` | Close; add a dedicated `dangerSoft #FDECEC` |
| XP / amber / mango (XP pills, stars, streak flame fill, mango accents) | `#F5A623` / `#FFB22E` | `mango #FFB22E`, `amber #F5A623` | Match |
| XP-soft pill bg | `#FFF3DC` | `xpSoft #FFF1D6` | Match |
| XP pill text | `#E08A00` | `xpSoftText #E08A00` | Match |
| Streak flame / streak number | orange-red `#FF7A3D`→`#FF5A3C` | `coral`, `streakSoftText #E8503B` | Close |
| Page background | `#F4F6FA` (cool very-light blue-gray) | `bgLight #FFFFFF` | **GAP** — comps use a cool off-white/very-light-blue page bg, NOT pure white. Cards float on it as white. Add `pageBg #F4F6FA`. |
| Card surface | `#FFFFFF` | `surfaceLight #FFFFFF` | Match |
| Sunken / option-row inactive bg | `#F2F4F8` | `surfaceSunken #F2EFEA` | comp sunken is cooler (blue-gray) vs warm. Consider `#F2F4F8`. |
| Hairline divider | `#ECEEF3` / `#EAEDF2` | `hairline #ECE7E0` | comp hairline is cooler (blue-gray) vs warm beige. Consider `#ECEEF3`. |
| Text primary (headings, headword) | `#1B2B4B` / near navy `#22324F` | `textPrimaryLight #233A66` / `brandNavy #233A66` | Match |
| Text secondary (subtitles, meta) | `#6B7280` (cool gray) | `textSecondaryLight #6B6B73` | Close (comp cooler/bluer gray) |
| Text hint (placeholder, faint meta) | `#9AA3B2` | `textHintLight #A59B8C` | comp hint is cool blue-gray vs warm; consider `#9AA3B2` |
| Star empty / mastery dot empty | `#D7DCE5` | none | derive from hairline |

**Net palette gaps to add as tokens:**
- `pageBg #F4F6FA` (cool page background — the single biggest visual shift; comps are NOT on white)
- `heroGradient` deep azure→indigo (`#3A6FE0 → #2453C4`) for the cover/hero card
- `danger #E5484D` + `dangerSoft #FDECEC` (true antonym/error red, distinct from warm `coral`)
- Cooler neutral variants: `hairline #ECEEF3`, `surfaceSunken #F2F4F8`, `textHint #9AA3B2`
- Synonym = `success`, antonym = `danger` (semantic aliasing)

> Overall the palette is **cool-blue-toned**, not warm-porcelain. The current Cozy Quest warm beige neutrals (`#FAF8F5`, `#ECE7E0`, `#A59B8C`) read warm; the comps read cool. Recommend a cool neutral ramp for this rebuild.

### A.2 Typography

System/SF-like sans throughout (Chinese uses default PingFang-equivalent). Weights and sizes (est.):

| Style | Size | Weight | Color | Used for |
|---|---|---|---|---|
| Headword / hero word | 30–34 | Bold (700) | text primary (navy) | `ambiguous`, `resilient` big card titles |
| Screen title (app bar) | 17–18 | Semibold (600) | text primary | 学习路径, 复习中心, 训练场, 发现, 我的 |
| Big number (stats) | 22–28 | Bold (700) | role color (blue/green/amber) | `3,582`, `2,196`, `12`, `62%`, streak day counts |
| Big number caption | 11–12 | Regular (400) | text secondary | label under the number |
| Card title / list-row title | 15–16 | Semibold (600) | text primary | wordbook name, word, task title |
| List-row subtitle / definition | 12–13 | Regular (400) | text secondary | phonetics, definitions, meta line |
| Section header ("今日词条", "今日 XP 任务", "薄弱列表") | 14–15 | Semibold (600) | text primary | section labels, often with trailing "更多/查看全部 ›" |
| Chip / pill label | 11–12 | Medium (500) | role color | 近义/反义, IELTS, 已学, +30 XP, 重点 |
| Phonetic (IPA) | 12–13 | Regular, often mono-ish | text secondary | `/əmˈbɪɡjuəs/` |
| Button label | 15–16 | Semibold (600) | white / blue | 开始学习, 进入识别题, 开始复习 |
| Big % ring center | 18–22 | Bold | role color | `65%`, `78%`, `62%` |

Numerals are emphasized (bold, larger, colored) — the comps lean on **colored big numbers** as the primary visual hierarchy device in stat strips.

### A.3 Spacing / radius / shadow / density

- **Page padding:** ~16px horizontal gutter; cards span gutter-to-gutter.
- **Card radius:** ~16px (comps look slightly tighter than current `radiusCard 22`). Hero/cover card ~18–20px. Pills 999. Chips/icon-chips ~8–10px (tighter than current `radiusChip 12`). Buttons ~12–14px (tighter than current `radiusButton 18`).
- **Card internal padding:** 12–16px (denser than airy 20–24).
- **Vertical rhythm:** **tight** — 8–12px between list rows, ~12–16px between cards/sections. List rows themselves are ~52–64px tall.
- **Dividers:** thin 1px hairline between list rows inside a card (not gaps). This is a key density signal — rows are separated by hairlines, not whitespace.
- **Shadow:** one soft, low, diffuse shadow on white cards over the cool page bg — matches the existing single `cardShadow` (`Color(0x0F28283C)`, blur 22, y+6). Keep it, maybe slightly tighter blur (~16–18). Many inner sub-rows have **no** shadow (flat on card).

**Density verdict:** target ~1.4–1.7× the information density of the current build. Reduce paddings ~25–30%, replace inter-row gaps with hairlines, allow multi-chip metadata rows.

### A.4 Reusable components seen across screens

Each is described tightly enough to become a widget. Proposed widget names in **bold**.

1. **`SearchTopBar`** — Home/Wordbook top bar. Leading circular avatar (32–36px). Center: rounded pill search field (`#F2F4F8` fill, radius 999 or ~14, magnifier icon + placeholder e.g. "查词 / 句子 / 词书"). Trailing: bell icon with a small red notification dot badge. Height ~48–52px, sits on page bg (no card).

2. **`StreakXpPillRow`** — a row of two info pills under the top bar (Home): left "连续打卡 28 天" with flame icon (streak-soft bg or transparent with flame), right "今日获得 126 XP" with XP/star icon (xp-soft bg). Pills are pill-radius, soft-fill, icon + label.

3. **`WordbookHeroCard`** — the flagship "current wordbook" card (Home + Profile). Layout: left = small cover-image thumbnail (rounded ~10px, ~56×72 portrait, network `coverUrl`); center = title (雅思核心词汇) + meta line(s) ("已学 842 / 2365", date "2026-02-10") + a thin horizontal **progress bar** with a "35%" label; right = a **circular percentage ring** (e.g. 65%) with a small caption ("64/98 词" or "今日完成"). On Home this card is white; the cover thumbnail itself is the deep-blue gradient book art. Below the meta there is often a 3-up mini stat row (see #5). Variant on Profile: full-width blue-gradient banner version (white text, "雅思核心词汇 / Unit 12 / 20 / 60% / 今日已学 15/45 / 每日目标提醒 20:30").

4. **`ProgressRing`** — circular ring, ~52–72px diameter, ~6–8px stroke, track `#E8ECF3`, fill role color (blue/green/amber) or a sweep. Center shows bold % + tiny caption below. Appears on Home hero (65%), Training (78%), Review (62%). (Current build has a `ProgressRing` — verify diameter/stroke match.)

5. **`StatStrip`** (3-up) — a horizontal strip of 3 equal cells, each = big colored number + small label below, separated by thin vertical hairlines. Examples: Home "新学今日 12 / 复习 8 / 累计 26", Profile "已学词汇 3,582 / 累计掌握 2,196 / 连续学习 28天", Training top stats. Numbers colored by role.

6. **`IconChip`** — a rounded-square (~36–40px, radius ~10) with a soft color-fill background and a centered line icon, color-coded by domain. Used as the leading element of list rows and as the quick-action tiles (Home "词书 / AI学习 / 学习路径" trio; Review/Discover row leads). Soft fills: blue-soft, green-soft, amber-soft, purple-soft, etc.

7. **`ListRowTile`** — the universal list row: **leading IconChip (or index number / avatar)** → **two-line block (title semibold + subtitle/meta secondary)** → **trailing cluster** (a pill, XP badge, status pill, mastery stars, ›chevron, or a small filled action button like "去做/领取/学习中"). Rows stack inside an `AppCard` separated by 1px hairlines. This is the workhorse — Wordbook word list, Review lists, Training drills, Discover tasks, Profile settings, Learning path steps all use variants.

8. **Semantic chips:**
   - **`SemanticChip`** — small soft-fill rounded-rect label. Green variant = 近义 (synonym), red/`danger` variant = 反义 (antonym). Seen on Word Detail. Icon optional.
   - **`TagPill`** — exam/category tag pills: `IELTS / TOEFL / GRE / CET4 / Beginner` (Wordbook filter row; selected = filled blue, unselected = outline/soft). Also word-level tags 重点/超纲/高频.
   - **`StatusPill`** — state badges with soft fill + role color: 已学(green), 复习中(amber), 未学(gray), 已完成(green), 学习中(blue), 未开始(gray), Coming soon(gray), 今日推荐(blue). Pill radius, 11–12px medium label.
   - **`MasteryStars`** — 1–3 (or 5) small stars, filled amber vs empty gray, indicating mastery level (Review list rows, Word Detail "考研核心词汇 ★★☆"). Also appears as a 3-state self-rating ("认识/模糊/不认识" segmented selector on Study card).
   - **`MasteryDots`** — alternate small filled/empty dots variant.

9. **`WordbookCoverCard`** — vertical cover card in a horizontal scroller (Wordbook overview filter/series row & elsewhere): book-cover image (deep blue gradient art, `coverUrl`), title, tiny meta (word count / progress). Rounded ~12px.

10. **Buttons:**
    - **`AppPrimaryButton`** — filled solid blue, white semibold label, radius ~12–14, full-width or wide. ("开始学习", "进入识别题", "开始复习(31)").
    - **`AppSecondaryButton`** — outline or soft-blue-fill, blue label ("仅识别", "查看提示", "切换计划").
    - **Bottom action bar** — Study/Quiz screens have a bottom row: small left/right icon buttons (收藏/笔记) flanking a wide primary CTA.

11. **`AppBottomNav` (ICON-ONLY)** — bottom tab bar. **Comp tab set (5 tabs), left→right with these labels/icons:**
    - 首页 (home/house icon)
    - 学习 (book/cap icon)
    - 训练场 (target/lightning icon) — **center, often emphasized**
    - 复习 (refresh/clock icon)
    - 我的 (person icon)

    Wordbook overview comp shows a 5-icon bar with the **wordbook (book) tab active** (center). Discover comp shows tabs 首页/学习/发现(compass, center, active)/复习?/我的 — **the discover comp swaps in a 发现/compass center tab**, indicating the tab set varies by comp.

    > **REPORT:** The comps' tab set (首页 / 学习 / 训练场 / 复习 / 我的, with a 发现/discover variant) **differs from the current app's five tabs** (`/home`, `/training`, `/ai-learning`, `/discover`, `/profile` per `app_router.dart`). Reconcile during build; do not assume 1:1. **Build requirement from product owner: ICON-ONLY tabs (no text labels).** Active tab = blue icon, inactive = gray icon. Provide accessible labels via semantics/tooltips even though text is hidden.

12. **`SocialPostRow`** (Discover feed) — leading circular avatar → name + a small level tag (e.g. "Lv.5" colored pill) → post text (1–2 lines) → footer row with like (♡ count) and comment (💬 count) actions, plus a "···" overflow. Separated by hairlines.

13. **`SegmentedSelector`** — pill/segmented control used for in-screen tabs: Study card self-rating (认识 / 模糊 / 不认识), Recognition screen top tabs (识别 / 复习回顾 / 正确率 83%), Review center filters (全部 / 到期 / 薄弱 / 错词). Selected segment = filled blue or blue-text-on-soft.

14. **`SectionHeader`** — small row: bold section title left, optional trailing muted action ("更多 ›", "查看全部 ›", "更多任务"). Ubiquitous above every list block.

15. **`AiTipCard`** — a distinct soft-tinted inset card with an "AI" badge/sparkle and a tip line (Word Detail "AI 记忆法", Study card "助记"). Light blue-violet tint.

16. **`LearningPathStep`** (timeline) — vertical connector line with a node (checkmark = done, play = current/学习中, lock or number = locked/upcoming) → step card: title (e.g. "1. 生活场景词汇") + meta chips (+30 XP / 25 词 / 30 min) + trailing status pill. Current step highlighted (blue node + 学习中 pill).

---

## B. Per-screen layout breakdown (all 10)

### B.1 — `01_home_today_dashboard.png` (Home / Today)

Top→bottom:
1. **`SearchTopBar`**: avatar (cartoon mascot) · search field "查词 / 句子 / 词书" · bell with red dot.
2. **`StreakXpPillRow`**: "🔥 连续打卡 28 天" (left) · "⭐ 今日获得 126 XP" (right).
3. **`WordbookHeroCard`** (white): left blue book cover thumb (雅思核心词汇 cover, `coverUrl`); title "雅思核心词汇" + "学习计划" link; meta "已学 842 / 2365" + "35%" horizontal progress bar + date "2026-02-10"; right **`ProgressRing`** "65%" caption "64/98 词" + "今日完成". Below inside same card: **`StatStrip`** 3-up "新学今日 12/40 · 复习 8/40 · 累计 26/词?" (numbers colored blue/amber/green). Footer of card: two buttons — primary "开始学习 (新学 12 复习 8)" + secondary "仅复习 (复习 31)".
4. **Quick-action trio**: three `IconChip`+label tiles in a row — "词书" (blue book), "AI 学习 个性化学习" (cube), "学习路径 进度追踪" (path). Each is icon-chip + 2-line text in a small white sub-card.
5. **Section "今日词条"** (`SectionHeader` + "更多 ›"): a featured word card "resilient /rɪˈzɪliənt/" with def "adj. 有韧性的；能恢复的" and a "认识 ✓" action; a small page-dot carousel indicator below.
6. **Section "薄弱词" / weak words** (`SectionHeader` + "查看全部 ›"): 3 `ListRowTile`s — `accommodate` (n. ... ) + status pill (上次复习…) ; `negotiate`; `consequence`. Each: word title + phonetic + def subtitle + trailing meta/status.
7. **Section "今日挑战"** (`SectionHeader`): a challenge card with target icon, "完成今日 X 道题…" progress + "去完成" button. Status "未完成".
8. **`AppBottomNav`** (icon-only): 首页(active) · 学习 · AI学习/训练 · 发现 · 我的.

### B.2 — `02_study_knowledge_card.png` (Study / Knowledge card)

1. **App bar**: back ‹ · title "今日混排学习包" · trailing icons (settings/cards) · "···".
2. **Progress header**: "06 / 24" segmented progress bar with sub-tabs "新学 12 · 复习 8" and "复习 18 分钟" timer chip; "下不再提示" link top-right.
3. **Big knowledge `AppCard`** (the flashcard, dominant): top-right star (favorite) + "下不再提示". Centered big **headword "ambiguous"** (bold ~32). Phonetic row "/æmˈbɪɡjuəs/ 🔊" with "UK / US" toggle chips + speaker. Part-of-speech chip "adj." + meaning "含糊的；不明确的". Sections inside card, each a labeled block:
   - **释义** "open to more than one interpretation; not having one clear meaning"
   - **例句** "The report was ambiguous, leaving the team confused…" + Chinese gloss.
   - **助记** (mnemonic) sub-rows: **联想** "a(向)+ big(大) + uous → 大而模糊，看不清楚", **词根** "-iguous = tending to; characterized by (倾向于…的)", **相关词组** "ambiguous 含糊的措辞 ›". These are small icon-led rows.
4. **"我的掌握"** self-rating **`SegmentedSelector`**: 3 options — **认识** (我已熟练掌握) / **模糊** (selected, blue) / **不认识** (完全不知道). Each with a sub-caption.
5. **Bottom action bar**: left icon "标记" · wide primary **"进入识别题"** · right icon "笔记".

### B.3 — `03_study_recognition_question.png` (Recognition / multiple choice)

1. **App bar**: back ‹ · title "短间隔回忆" · trailing "生词本".
2. **Progress + tabs**: "07 / 24" bar; `SegmentedSelector` tabs "识别 · 复习回顾 · 正确率 83%".
3. **Question card**: "ambiguous 在这句话中的含义是？" + example sentence "The wording of the contract is ambiguous." + Chinese gloss + a small "提示/翻译" link.
4. **Four option rows** (A/B/C/D), each a selectable `ListRowTile`-style card: letter badge (circle) + Chinese option text + sub-gloss + a right-side **percentage** (community answer distribution e.g. 8% / 83% / 5% / 4%):
   - A 明确的、清晰的 — 8%
   - **B 模糊的、含糊不清的 — 83%** (SELECTED: blue border + check ✓)
   - C 完全清晰、明确的 — 5%
   - D 无关紧要的、不重要的 — 4% (a ⊘ wrong marker)
   Selected = blue outline + filled check; correct/incorrect styling green/red.
5. Helper line: "错对会在 4 隔以后再出现 · 查看复习计划 ›".
6. **Bottom action bar**: wide primary **"检查"** + secondary **"看提示"**.
7. Footer meta strip: "学习中 24 · 已掌握 13 · 预计 12 分钟".

### B.4 — `04_learning_path.png` (Learning path / skill tree)

1. **App bar**: back ‹ · title "学习路径" · trailing "查看进度".
2. **Plan header card**: "雅思核心词汇 ›" + "842 / 2365 词汇量" + "35%" progress bar; right control cluster: **pause/play** buttons (暂停计划) + "调整计划".
3. **Vertical timeline** of **`LearningPathStep`** nodes (connector line on left). Each step: node icon (✓ done / ▶ current / number-locked), title, meta chips, status pill:
   - 1. 生活场景词汇 (+30 XP · 25 词 · 30 min) — **已完成** (green ✓)
   - 2. 人物与关系 — 已完成
   - 3. 饮食与健康 — 已完成
   - 4. 教育与学习 (+40 XP · 28 词 · 30 min) — **学习中** (blue ▶, highlighted card)
   - 5. 工作与职业 — 未开始/锁定
   - 6. 科技与设备 — 锁定
   - 7. 社会与文化 — 锁定
   - 8. 环境与可持续发展 — 锁定
   - 9. 学术与研究 — 锁定
   Locked steps are muted (gray node, gray title, lock).
4. **Bottom bar**: "打卡奖励" + "调整计划" actions.

### B.5 — `05_wordbook_overview.png` (Wordbook overview)

1. **App bar**: title "词书" · trailing search 🔍 + filter/sort icon.
2. **`WordbookHeroCard`** (blue gradient banner variant): cover art left, "雅思核心词汇" title, "每日 30 个 · 剩余 51 天", "842 / 2365 · 35%", date "2026-08-05"; right CTA "切换计划".
3. **Exam `TagPill` filter row** (horizontal scroller of `WordbookCoverCard`/tag combos): IELTS(active blue) · TOEFL · GRE · CET4 · Beginner — each shows count "842/2365" etc. Active = filled blue.
4. **List header**: "全部单词 (2365)" left + "未掌握优先" sort + a toggle/filter.
5. **Word `ListRowTile` list** (index-numbered), each: index "001" · word + phonetic + part-of-speech + def subtitle · trailing **StatusPill** (已学/平均/重点) + **star** favorite:
   - 001 resilient /rɪˈzɪliənt/ adj. 有韧性的 — "She showed remarkable attitude in the face of adversity." — 平均 · ★
   - 002 ambiguous — 含糊不清的 — 已学 · ★
   - 003 consequence — 后果 — 重点 · ★
   - 004 negotiate — 协商 — 高频 · ★
   - 005 accommodate — 容纳 — ★
6. **Floating action button** bottom-right: "生词本" / add (blue circle).
7. **`AppBottomNav`** icon-only, **词书/center tab active**.

### B.6 — `06_word_detail.png` (Word detail)

1. **App bar**: back ‹ · headword context · trailing star + "···".
2. **Header block**: big **headword "resilient"** (bold) + 🔊 · phonetic "/rɪˈzɪliənt/" with UK/US speaker toggles · top-right: **mountain illustration** (light line-art mountain/landscape decoration in the header — a hero illustration asset). Action chips below: "加入生词本" · "AI 学习" · "标记已背诵".
3. **词义 (Definitions)** card: "adj. 有韧性的；有弹性的；坚韧的；能适应逆境的" + example "She showed incredible resilience in the face of adversity." + 翻译 link.
4. **搭配/短语 (Collocations)** card — two-column phrase list: build resilience · resilient to change · resilient economy · bounce back; each with a small gloss.
5. **同义 / 反义 (Synonyms/Antonyms)** two columns with **`SemanticChip`**s:
   - **同义** (green header): tough · strong · sturdy …
   - **反义** (red/`danger` header): fragile · brittle · vulnerable …
6. **派生词 (Derivatives)** card: resilience (n.) · resiliently (adv.) …
7. **词根词缀 (Roots/affixes)** card: re- + -sili- + -ent breakdown.
8. **`AiTipCard`** "AI 记忆法": tinted card with AI badge + mnemonic tip "用 ... 联想 ..." .
9. **Footer**: "考研核心词汇 ★★☆" mastery stars + a "2 ?" count; prev/next word nav arrows "‹ 上一个 / 下一个 ›".

### B.7 — `07_training_arena.png` (Training arena)

1. **App bar**: title "训练场" · trailing "训练进度" + "历史记录".
2. **Top summary card**: "雅思核心词汇 · 限时测试" + left **big stat** "连续答对 12 天" (or 12) · right **`ProgressRing`** "78%" "训练准确率"; meta "350 / 600 XP" progress + "连续 23 天".
3. **Drill `ListRowTile` list**, each: leading colored `IconChip` + title + subtitle (rule/desc) + trailing **XP badge "+40 XP"** + status pill (今日推荐/已完成):
   - 限时测试 — 10 分钟快速测验，挑战手速反应 — +40 XP · 今日推荐
   - 拼写训练 (ABC icon) — 听写单词，强化拼写记忆 — +40 XP
   - 听音选词 (headphone) — 听发音选释义 — +30 XP
   - 完形填空 — 句子语境填空 — +40 XP
   - 速记训练 — 限时记忆，提升记忆速度 — +30 XP
   - 错词突击 — 集中攻克错词 — +40 XP · 推荐复习
   - 生词听写挑战 — +30 XP
   - 一站到底 (trophy) — 连续答题闯关 — XP
4. **Bottom progress card**: "完成 X 项训练 1/3" + total "120 / 350 XP" progress bar.
5. **`AppBottomNav`** icon-only (首页/学习/训练场-active/复习/我的).

### B.8 — `08_review_center.png` (Review center)

1. **App bar**: title "复习中心" · trailing layout/sort icon + "提醒已开".
2. **Banner**: pause notice "当前学习计划已暂停 — 每日复习与生词巩固进度保留" + "继续计划" link (info-tinted card with ⓘ).
3. **复习概览 `StatStrip`** + **`ProgressRing`**: "到期 31 · 薄弱 8 · 今日已复 12" (colored numbers) + right ring "62%".
4. Primary **`AppPrimaryButton`** full-width: **"开始复习 (31)"**.
5. **Filter `SegmentedSelector`**: 全部 · 到期 · 薄弱 · 错词 + trailing "按下次复习排序" sort.
6. **到期列队 (31) list** of `ListRowTile`s — word + def chips + **`MasteryStars`** (amber) + next-review meta:
   - accommodate · 到期 · ★★★ · 下次复习…
   - inevitable · ★★☆
   - contribute · ★★★
   - compare · ★★☆
   - promote · ★☆☆
   "查看全部到期单词 ›"
7. **薄弱列表 (8)**: perceive · fundamental · allocate · insight … with weak-state styling + "标记重点复习" action.
8. **错词本 / 加入错词** footer rows: "错词本 (… )" + "加入错词本" with counts and quick actions.

### B.9 — `09_discover_xp_tasks.png` (Discover / XP tasks + social)

1. **App bar**: title "发现" · trailing search 🔍 + bell.
2. **Top `StatStrip`**: "⭐ 1,280 我的 XP" · "🔥 12 天 学习连续" · "📅 今日已打卡/今日 XP" (colored pills/cells).
3. **Section "今日 XP 任务"** (`SectionHeader` + "更多任务 ›"): 4 task `ListRowTile`s with leading colored `IconChip`, title + progress + trailing XP badge + **action button** (领取/去完成/去查看):
   - 完成新学 (+30 XP) — 15/15 — **领取** (green, completed → claim)
   - 完成复习 (+50 XP) — 18/20 — 去完成
   - 错词清零 (+30 XP) — 6/10 — 去查看
   - 词书打卡 (+10 XP) — 1/1 — done
4. **每日幸运抽奖** row: "抽奖次数 2 次" + "买 1 送 1" + **"去抽奖"** button.
5. **Sub-tabs** "学习动态 · 精选话题" (`SegmentedSelector`) + "最新 ▾" sort.
6. **Social feed** — **`SocialPostRow`** list: avatar + name + level tag + post text + like ♡ / comment 💬 counts + "···":
   - Luna同学 (Lv.?) — "今天背了 100 个单词，感觉自己棒极了！" — ♡ · 💬
   - 词汇小能手 (Lv.5) — post — counts
   - Echo. — "每天坚持一点点，考研单词不再怕。" — counts
   - "你也想分享学习心得吗？发布动态 ›" prompt.
7. **`AppBottomNav`** icon-only — **发现/compass center tab active** (this comp's variant tab set).

### B.10 — `10_profile_settings.png` (Profile / settings)

1. **App bar**: title "我的" · trailing settings ⚙ + message 💬 icons.
2. **Profile card**: avatar + name "Winston" + edit ✎ + email "winston.lee@example.com" + an IELTS tag pill + "… / 500 XP" level progress.
3. **`StatStrip`** 3-up: "📘 已学词汇 3,582" · "✅ 累计掌握 2,196" · "🔥 连续学习 28 天" (colored).
4. **`WordbookHeroCard`** (blue gradient banner): "雅思核心词汇 — Unit 12 / 20 · 60% · 今日已学 15/45" + "每日提醒提醒 20:30" + chevron.
5. **Settings `ListRowTile` list** (icon-chip leading + title + trailing value/chevron), grouped, hairline-separated:
   - 学习计划 — 今日目标 40 ›
   - 词书 — 3 本 ›
   - 生词本 — 128 词 ›
   - 错词本 — 56 题 ›
   - 主题 — 跟随系统 ›
   - 每日提醒 — 20:30 ›
   - 语言 — 简体中文 ›
   - 帮助与反馈 ›
   - 关于 LinguaQuest — v1.2.0 ›
   - **退出登录** (red/`danger` text, no chevron)
6. **`AppBottomNav`** icon-only — **我的/person tab active**.

---

## C. Build notes

### C.1 Reusable vs. new

**Reusable from current `AppTokens` / Cozy Quest widgets (keep):**
- Spacing scale (`s2..s32`) — fine; just apply tighter.
- `radiusPill 999`, `cardShadow` (single soft shadow) — keep.
- `AppCard`, `AppPrimaryButton`, `AppSecondaryButton`, `AppPill`, `AppProgressBar` (mango→success gradient — but note many comp progress bars are **solid blue**, not gradient; add a solid-blue variant), `ProgressRing`, `StatTile`, `SegmentedTabs`, `WordChoiceButton`, `MascotImage`.
- Semantic palette: `azure`, `mango`/`amber`, `success`, `xpSoft/successSoft/primarySoft` — mostly match.

**NEW shared widgets to build (named):**
`SearchTopBar`, `StreakXpPillRow`, `WordbookHeroCard` (white + blue-banner variants), `ProgressRing` (verify or extend), `StatStrip` (3-up with hairline dividers), `IconChip`, `ListRowTile` (with leading/title/subtitle/trailing slots), `WordbookCoverCard`, `SemanticChip` (synonym/antonym), `TagPill`, `StatusPill`, `MasteryStars`/`MasteryDots`, `SocialPostRow`, `SegmentedSelector` (extend `SegmentedTabs`), `SectionHeader`, `AiTipCard`, `LearningPathStep` (timeline node + card), and an **icon-only** `AppBottomNav`.

**NEW token additions:**
- `pageBg #F4F6FA` (cool page bg — replace pure-white `bgLight` for this rebuild), cooler neutrals `hairline #ECEEF3`, `surfaceSunken #F2F4F8`, `textHint #9AA3B2`.
- `danger #E5484D` + `dangerSoft #FDECEC` (true antonym/error red).
- `heroGradient` (deep azure→indigo `#3A6FE0→#2453C4`) for hero/cover banner cards.
- Tighter radii constants: `radiusCard ~16`, `radiusButton ~13`, `radiusChip ~9` for this denser look.
- A **solid-blue** progress variant alongside the existing mango→success gradient.

### C.2 Imagery strategy

- **Wordbook covers** are deep-blue gradient book-art images sourced from a **`coverUrl` (network)** field in the wordbook JSON. Both the Home/Wordbook/Profile hero cards and the horizontal `WordbookCoverCard` scroller render these. Use `Image.network(coverUrl)` with a rounded clip + a gradient/placeholder fallback (blue gradient + book glyph) for offline/demo mode.
- **Word Detail header** uses a light line-art **mountain/landscape illustration** as a decorative banner — needs a bundled SVG/PNG asset (one per theme/word category, or a single generic one).
- **Avatars** (top bar, social feed, profile) are network or asset images with circular clip + fallback initials/mascot.
- **Mascot** appears less prominently than in current Cozy Quest build; comps are more "serious study app" than mascot-forward. Keep mascot for empty states only.
- Faithful reproduction **requires image assets / network images**. Plan an asset bundle (default covers, mountain illustration, placeholder avatar) + network loading with graceful fallbacks so demo/offline mode still looks right.

### C.3 Density shift (critical)

The prior reskin was **too airy/whitespace-heavy**. The target is **denser and more colorful**:
- Page sits on **cool off-white `#F4F6FA`**, not pure white; white cards float on it.
- **Replace inter-row gaps with 1px hairline dividers** inside cards; pack 6–10 rows per card.
- **Reduce paddings ~25–30%** (card padding 12–16, row height 52–64).
- **Color is hierarchy:** big colored numbers, many soft-fill chips/pills (blue/green/red/amber), status pills on nearly every row.
- **Multi-metadata rows:** a single list row routinely shows index + word + phonetic + def + status pill + XP/stars + chevron. Embrace the density.
- **Bottom nav is icon-only** (no labels) per product owner.

---

## Executive summary (design language, 10 lines)

1. Cool-blue-toned study app, NOT warm-porcelain — page bg is off-white `#F4F6FA`, white cards float on it.
2. Primary action color is a saturated azure `#2F6BF0` (≈ existing `azure`); pressed deeper indigo.
3. Semantic colors: green `#3FB45C` for synonym/已学/correct, true red `#E5484D` for antonym/error (NEW, distinct from coral), amber `#F5A623` for XP/stars/streak.
4. Typography leans on **bold colored big-numbers** as the main hierarchy device; headwords are bold ~32, body is compact 12–13.
5. **Dense and colorful**: hairline-separated list rows (not gaps), tighter ~16px card radius, 12–16px padding, soft-fill chips/pills everywhere.
6. Workhorse component is `ListRowTile`: leading icon-chip/index → two-line title+meta → trailing pill/XP/stars/chevron.
7. Hero "current wordbook" card recurs (Home/Wordbook/Profile): cover thumb (`coverUrl` network) + meta + progress bar + circular % ring.
8. Imagery matters: blue-gradient book covers, a mountain line-art illustration on Word Detail, network avatars — needs an asset/network strategy.
9. Bottom nav is **5 icons, ICON-ONLY** (首页/学习/训练场/复习/我的, with a 发现 variant) — reconcile against current app's tab set.
10. Most existing `AppTokens`/Cozy-Quest primitives are reusable; gaps are cool neutrals, `pageBg`, `danger`/`dangerSoft`, `heroGradient`, tighter radii, and ~17 new shared widgets.
