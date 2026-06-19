# HSK Wordbook Interface Specification

> 供后续 AI agent 填充 HSK2–HSK6 词汇数据使用。  
> 目标：将每个 stub JSON 中的 3 个占位词扩充至对应词汇量目标。

---

## 1. 词汇量目标

| 文件 | id | 目标词数 | 当前状态 |
|------|----|----------|----------|
| `wordbook_hsk1.json` | `hsk1` | 489 | **已完整** |
| `wordbook_hsk2.json` | `hsk2` | 150 | **STUB（3词）** |
| `wordbook_hsk3.json` | `hsk3` | 300 | **STUB（3词）** |
| `wordbook_hsk4.json` | `hsk4` | 600 | **STUB（3词）** |
| `wordbook_hsk5.json` | `hsk5` | 1300 | **STUB（3词）** |
| `wordbook_hsk6.json` | `hsk6` | 2500 | **STUB（3词）** |

---

## 2. 顶层文件结构

```json
{
  "id": "hsk2",
  "title": "HSK 2",
  "titleEn": "HSK 2",
  "titleMs": "HSK 2",
  "category": "hsk",
  "examType": "HSK 2",
  "coverUrl": "",
  "totalWords": 150,
  "includedWords": 150,
  "description": "Core vocabulary for HSK Level 2.",
  "wordIds": ["hsk2_000_b", "hsk2_001_ci", ...],
  "words": [ ...词条数组... ]
}
```

### 顶层字段说明

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | string | 是 | 词书唯一标识，格式 `hskN`（N=2-6） |
| `title` | string | 是 | 中文显示标题，固定 `"HSK N"` |
| `titleEn` | string | 是 | 英文标题，同 title |
| `titleMs` | string | 是 | 马来语标题，同 title |
| `category` | string | 是 | 固定值 `"hsk"` |
| `examType` | string | 是 | 考试类型标签，固定 `"HSK N"` |
| `coverUrl` | string | 否 | 封面图 URL，默认留空 `""` |
| `totalWords` | int | 是 | 该级别总词数目标（见上表） |
| `includedWords` | int | 是 | 本文件实际包含词数（填充完毕后等于 totalWords） |
| `description` | string | 否 | 简短描述，填充完毕后去掉 STUB 标注 |
| `wordIds` | string[] | 是 | 所有词条 id 的有序列表，与 `words` 数组顺序一致 |
| `words` | object[] | 是 | 词条对象数组（详见第 3 节） |

---

## 3. 词条字段说明

```json
{
  "id": "hsk2_000_b",
  "word": "把",
  "phoneticUK": "bǎ",
  "phoneticUS": "bǎ",
  "audioUKUrl": "https://dict.youdao.com/dictvoice?audio=%E6%8A%8A&type=1",
  "audioUSUrl": "https://dict.youdao.com/dictvoice?audio=%E6%8A%8A&type=2",
  "partOfSpeech": "prep/m/n/v",
  "definitions": ["(indicates an action to the object); to hold; to handle", "measure word for objects with handles"],
  "englishDefinitions": ["(indicates an action to the object); to hold; to handle", "measure word for objects with handles"],
  "malayDefinitions": [],
  "exampleSentences": [],
  "collocations": [],
  "synonyms": [],
  "antonyms": [],
  "derivatives": [],
  "rootAffix": "",
  "examTags": [],
  "difficulty": "Easy",
  "imageUrl": "",
  "hskLevel": 2
}
```

### 词条字段说明

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | string | 是 | 见第 4 节命名规则 |
| `word` | string | 是 | 汉字词汇 |
| `phoneticUK` | string | 是 | 拼音（带声调符号），中文无 UK/US 区别，两个字段填相同值 |
| `phoneticUS` | string | 是 | 拼音（带声调符号），同 phoneticUK |
| `audioUKUrl` | string | 是 | 有道朗读 URL，见第 6 节 |
| `audioUSUrl` | string | 是 | 有道朗读 URL（type=2），见第 6 节 |
| `partOfSpeech` | string | 是 | 词性，多个用 `/` 分隔，见第 5 节 |
| `definitions` | string[] | 是 | 主要释义列表（中英文均可，与 HSK1 保持英文） |
| `englishDefinitions` | string[] | 是 | 英文释义列表，与 `definitions` 内容相同 |
| `malayDefinitions` | string[] | 否 | 马来语释义，默认空数组 `[]` |
| `exampleSentences` | any[] | 否 | 例句列表，默认空数组 `[]` |
| `collocations` | any[] | 否 | 搭配列表，默认空数组 `[]` |
| `synonyms` | string[] | 否 | 近义词，默认空数组 `[]` |
| `antonyms` | string[] | 否 | 反义词，默认空数组 `[]` |
| `derivatives` | any[] | 否 | 派生词，默认空数组 `[]` |
| `rootAffix` | string | 否 | 词根/词缀，默认空字符串 `""` |
| `examTags` | string[] | 否 | 考试标签，默认空数组 `[]` |
| `difficulty` | string | 是 | 难度枚举，见第 7 节 |
| `imageUrl` | string | 否 | 配图 URL，默认空字符串 `""` |
| `hskLevel` | int | 是 | HSK 级别数字（2、3、4、5 或 6） |

---

## 4. 词条 ID 命名规则

格式：`hskN_INDEX_PINYINFIRST`

- `hskN`：级别前缀，如 `hsk2`、`hsk3`
- `INDEX`：三位数字序号，从 `000` 开始，按拼音字母序排列
- `PINYINFIRST`：取拼音首字母缩写（去掉声调），多音节取每个音节首字母

### 示例

| 词 | 拼音 | ID |
|----|------|----|
| 把 | bǎ | `hsk2_000_b` |
| 次 | cì | `hsk2_001_ci`（避免单字母冲突时可多取一个字母） |
| 等 | děng | `hsk2_002_dng` |
| 附近 | fù jìn | `hsk3_001_fjn` |
| 标准 | biāo zhǔn | `hsk4_000_biu` |

### 注意事项

- 同级别内 ID **全局唯一**，若缩写冲突则在末尾追加数字区分（如 `_b1`）
- 索引号 `INDEX` 按拼音升序排列，便于维护
- 填充新词时，在现有最大 INDEX 后续编
- 不要重用已存在的 ID，即使删除了某个词条也不复用其 INDEX

---

## 5. partOfSpeech 词性值列表

| 缩写 | 含义 |
|------|------|
| `n` | 名词 noun |
| `v` | 动词 verb |
| `adj` | 形容词 adjective |
| `adv` | 副词 adverb |
| `prep` | 介词 preposition |
| `conj` | 连词 conjunction |
| `pron` | 代词 pronoun |
| `num` | 数词 numeral |
| `m` | 量词 measure word |
| `aux` | 助词/助动词 auxiliary |
| `interj` | 感叹词 interjection |
| `vn` | 动名词（兼作名词的动词）|
| `b` | 区别词 |

多词性用 `/` 分隔，如 `"v/n"`、`"prep/m/n/v"`。

---

## 6. Audio URL 生成规则（有道词典）

```
UK（type=1）: https://dict.youdao.com/dictvoice?audio=URL_ENCODED_WORD&type=1
US（type=2）: https://dict.youdao.com/dictvoice?audio=URL_ENCODED_WORD&type=2
```

- 对汉字词进行 **UTF-8 百分比编码**（percent-encoding），与标准 URL encoding 相同
- Python 示例：`urllib.parse.quote("把")` → `%E6%8A%8A`
- JavaScript 示例：`encodeURIComponent("把")` → `%E6%8A%8A`
- Dart 示例：`Uri.encodeComponent("把")` → `%E6%8A%8A`

### 验证

在浏览器打开如下链接，应能播放朗读音频：

```
https://dict.youdao.com/dictvoice?audio=%E6%8A%8A&type=1
```

---

## 7. difficulty 枚举值

| 值 | 适用场景 |
|----|----------|
| `"Easy"` | HSK2 基础词，常用高频 |
| `"Medium"` | HSK3-4 中级词，需要一定语境 |
| `"Hard"` | HSK5-6 高级词，专业/低频/语义复杂 |

参考分配建议：

| 级别 | Easy | Medium | Hard |
|------|------|--------|------|
| HSK 2 | 80% | 20% | 0% |
| HSK 3 | 30% | 60% | 10% |
| HSK 4 | 10% | 60% | 30% |
| HSK 5 | 5% | 40% | 55% |
| HSK 6 | 0% | 20% | 80% |

---

## 8. 占位词扩充指南（给下一个 AI）

### 任务描述

每个 stub 文件当前只有 3 个占位词，需要扩充到目标词数。

### 操作步骤

1. **获取官方词表**：参考《HSK 课程与考试大纲（2021 版）》或权威来源（如 MDBG、CC-CEDICT）
2. **逐词填写**：按拼音升序排列词条，每个词条包含所有必填字段
3. **生成 audio URL**：对每个词的汉字字符串做 URL encode，代入模板
4. **更新顶层字段**：
   - `includedWords` 改为实际词数
   - `wordIds` 数组追加所有新词 ID
   - `description` 去掉 `[STUB — ...]` 标注
5. **验证 JSON**：确保文件是有效 JSON（可用 `python3 -m json.tool wordbook_hskN.json`）

### 批量生成示例（Python 伪代码）

```python
import urllib.parse
import json

def make_entry(hsk_level: int, index: int, word: str, pinyin: str, pos: str, defs: list, difficulty: str):
    # 生成 ID 的拼音首字母缩写（简化版）
    pinyin_abbr = ''.join(s[0] for s in pinyin.split() if s)
    entry_id = f"hsk{hsk_level}_{index:03d}_{pinyin_abbr}"
    encoded = urllib.parse.quote(word)
    return {
        "id": entry_id,
        "word": word,
        "phoneticUK": pinyin,
        "phoneticUS": pinyin,
        "audioUKUrl": f"https://dict.youdao.com/dictvoice?audio={encoded}&type=1",
        "audioUSUrl": f"https://dict.youdao.com/dictvoice?audio={encoded}&type=2",
        "partOfSpeech": pos,
        "definitions": defs,
        "englishDefinitions": defs,
        "malayDefinitions": [],
        "exampleSentences": [],
        "collocations": [],
        "synonyms": [],
        "antonyms": [],
        "derivatives": [],
        "rootAffix": "",
        "examTags": [],
        "difficulty": difficulty,
        "imageUrl": "",
        "hskLevel": hsk_level
    }
```

### 注意事项

- **不要修改** `wordbook_hsk1.json`（已完整）
- 新词条追加在现有 stub 词条之后，INDEX 续编
- 保持 `wordIds` 数组与 `words` 数组**顺序一致**
- 单次可以只填一个级别，不必一次完成全部 5 个级别
- JSON 必须通过 `flutter analyze` 不报资源错误（确保文件已在 pubspec.yaml 中注册）

---

## 9. 文件注册状态

以下文件均已在 `linguaquest/pubspec.yaml` 的 assets 节和
`linguaquest/lib/data/wordbook_asset_loader.dart` 的 `_bookIds` 列表中注册，
数据填充完毕后**无需修改**任何 Dart 代码。

```yaml
# pubspec.yaml assets 节（已配置）
assets:
  - lib/assets/image/
  - lib/assets/data/wordbook_hsk1.json
  - lib/assets/data/wordbook_hsk2.json
  - lib/assets/data/wordbook_hsk3.json
  - lib/assets/data/wordbook_hsk4.json
  - lib/assets/data/wordbook_hsk5.json
  - lib/assets/data/wordbook_hsk6.json
```

```dart
// wordbook_asset_loader.dart _bookIds（已配置）
static const _bookIds = [
  'hsk1',
  'hsk2',
  'hsk3',
  'hsk4',
  'hsk5',
  'hsk6',
];
```
