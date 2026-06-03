List<Map<String, dynamic>> lessonCatalog() {
  final examWords = [
    _word(
      id: 'w-allocate',
      word: 'allocate',
      phonetic: '/al-uh-keit/',
      meaning: '分配',
      definition: 'to give something officially for a particular purpose',
      partOfSpeech: 'verb',
      exampleSentence: 'The school will allocate more time for revision.',
      exampleTranslation: '学校会分配更多时间用于复习。',
      imageCue: '📊',
      difficulty: 'Medium',
      tags: ['exam', 'academic'],
    ),
    _word(
      id: 'w-evaluate',
      word: 'evaluate',
      phonetic: '/ih-val-yu-eit/',
      meaning: '评估',
      definition: 'to judge the value or quality of something',
      partOfSpeech: 'verb',
      exampleSentence: 'The essay asks students to evaluate two opinions.',
      exampleTranslation: '这篇作文要求学生评估两种观点。',
      imageCue: '🧪',
      difficulty: 'Hard',
      tags: ['exam'],
    ),
    _word(
      id: 'w-contrast',
      word: 'contrast',
      phonetic: '/kon-trast/',
      meaning: '对比',
      definition: 'to compare two things to show differences',
      partOfSpeech: 'verb',
      exampleSentence: 'Contrast the writer’s view with the speaker’s view.',
      exampleTranslation: '对比作者和说话者的观点。',
      imageCue: '⚖️',
      difficulty: 'Medium',
      tags: ['exam', 'writing'],
    ),
  ];
  final travelWords = [
    _word(
      id: 'w-itinerary',
      word: 'itinerary',
      phonetic: '/ai-ti-ne-re-ri/',
      meaning: '旅行计划',
      definition: 'a planned route or journey',
      partOfSpeech: 'noun',
      exampleSentence: 'Our itinerary includes a museum and a night market.',
      exampleTranslation: '我们的行程包括博物馆和夜市。',
      imageCue: '🗺',
      difficulty: 'Hard',
      tags: ['travel'],
    ),
    _word(
      id: 'w-departure',
      word: 'departure',
      phonetic: '/di-par-cher/',
      meaning: '出发',
      definition: 'the act of leaving a place',
      partOfSpeech: 'noun',
      exampleSentence: 'Please check the departure gate.',
      exampleTranslation: '请查看登机口。',
      imageCue: '✈',
      difficulty: 'Medium',
      tags: ['travel'],
    ),
    _word(
      id: 'w-luggage',
      word: 'luggage',
      phonetic: '/lug-ij/',
      meaning: '行李',
      definition: 'bags and cases used for travel',
      partOfSpeech: 'noun',
      exampleSentence: 'Her luggage was too heavy to carry.',
      exampleTranslation: '她的行李太重，拿不动。',
      imageCue: '🧳',
      difficulty: 'Easy',
      tags: ['travel'],
    ),
  ];
  final workWords = [
    _word(
      id: 'w-brief',
      word: 'brief',
      phonetic: '/bri:f/',
      meaning: '简短的；摘要',
      definition: 'short and containing only the most important information',
      partOfSpeech: 'adjective',
      exampleSentence: 'Please give me a brief update before lunch.',
      exampleTranslation: '午饭前请给我一个简短更新。',
      imageCue: '📝',
      difficulty: 'Easy',
      tags: ['business'],
    ),
    _word(
      id: 'w-negotiate',
      word: 'negotiate',
      phonetic: '/ni-go-shi-eit/',
      meaning: '谈判；协商',
      definition: 'to discuss something in order to reach an agreement',
      partOfSpeech: 'verb',
      exampleSentence: 'We need to negotiate a better delivery date.',
      exampleTranslation: '我们需要协商一个更好的交付日期。',
      imageCue: '🤝',
      difficulty: 'Hard',
      tags: ['business'],
    ),
    _word(
      id: 'w-priority',
      word: 'priority',
      phonetic: '/prai-or-i-ti/',
      meaning: '优先事项',
      definition: 'something that is more important than other things',
      partOfSpeech: 'noun',
      exampleSentence: 'Customer support is our top priority.',
      exampleTranslation: '客户支持是我们的首要任务。',
      imageCue: '⭐',
      difficulty: 'Medium',
      tags: ['business'],
    ),
  ];
  final foodWords = [
    _word(
      id: 'w-appetite',
      word: 'appetite',
      phonetic: '/ap-i-tait/',
      meaning: '食欲',
      definition: 'the feeling of wanting to eat food',
      partOfSpeech: 'noun',
      exampleSentence: 'A short walk gave me a better appetite.',
      exampleTranslation: '短暂散步让我更有食欲。',
      imageCue: '🍜',
      difficulty: 'Medium',
      tags: ['daily', 'food'],
    ),
    _word(
      id: 'w-ingredient',
      word: 'ingredient',
      phonetic: '/in-gree-dee-ent/',
      meaning: '食材；成分',
      definition: 'one of the things used to make food or a product',
      partOfSpeech: 'noun',
      exampleSentence: 'Garlic is the key ingredient in this sauce.',
      exampleTranslation: '大蒜是这个酱汁的关键食材。',
      imageCue: '🧄',
      difficulty: 'Easy',
      tags: ['food'],
    ),
    _word(
      id: 'w-flavor',
      word: 'flavor',
      phonetic: '/flei-ver/',
      meaning: '味道',
      definition: 'the taste of a food or drink',
      partOfSpeech: 'noun',
      exampleSentence: 'The soup has a rich flavor.',
      exampleTranslation: '这汤味道浓郁。',
      imageCue: '🥣',
      difficulty: 'Easy',
      tags: ['food', 'daily'],
    ),
  ];
  final healthWords = [
    _word(
      id: 'w-recover',
      word: 'recover',
      phonetic: '/ri-kuh-ver/',
      meaning: '恢复',
      definition: 'to become well again after illness or difficulty',
      partOfSpeech: 'verb',
      exampleSentence: 'She needs rest to recover from the flu.',
      exampleTranslation: '她需要休息来从流感中恢复。',
      imageCue: '💪',
      difficulty: 'Easy',
      tags: ['health'],
    ),
    _word(
      id: 'w-symptom',
      word: 'symptom',
      phonetic: '/simp-tum/',
      meaning: '症状',
      definition: 'a sign that someone has an illness',
      partOfSpeech: 'noun',
      exampleSentence: 'A headache can be a symptom of stress.',
      exampleTranslation: '头痛可能是压力的症状。',
      imageCue: '🤒',
      difficulty: 'Medium',
      tags: ['health'],
    ),
    _word(
      id: 'w-prevent',
      word: 'prevent',
      phonetic: '/pri-vent/',
      meaning: '预防；阻止',
      definition: 'to stop something from happening',
      partOfSpeech: 'verb',
      exampleSentence: 'Regular exercise helps prevent many health problems.',
      exampleTranslation: '规律运动有助于预防许多健康问题。',
      imageCue: '🛡️',
      difficulty: 'Medium',
      tags: ['health', 'daily'],
    ),
  ];
  final campusWords = [
    _word(
      id: 'w-commute',
      word: 'commute',
      phonetic: '/ke-mju:t/',
      meaning: '通勤',
      definition: 'to travel regularly between home and work or school',
      partOfSpeech: 'verb',
      exampleSentence: 'I commute to campus by train every morning.',
      exampleTranslation: '我每天早上坐火车去校园。',
      imageCue: '🚆',
      difficulty: 'Medium',
      tags: ['campus', 'daily'],
    ),
    _word(
      id: 'w-lecture',
      word: 'lecture',
      phonetic: '/lek-cher/',
      meaning: '讲座；授课',
      definition: 'a talk that teaches people about a subject',
      partOfSpeech: 'noun',
      exampleSentence: 'The biology lecture starts at nine.',
      exampleTranslation: '生物讲座九点开始。',
      imageCue: '🎓',
      difficulty: 'Easy',
      tags: ['campus'],
    ),
    _word(
      id: 'w-deadline',
      word: 'deadline',
      phonetic: '/ded-lain/',
      meaning: '截止日期',
      definition: 'the latest time by which something must be finished',
      partOfSpeech: 'noun',
      exampleSentence: 'The essay deadline is Friday.',
      exampleTranslation: '论文截止日期是星期五。',
      imageCue: '📅',
      difficulty: 'Easy',
      tags: ['study'],
    ),
  ];
  final allWords = [
    ...examWords,
    ...travelWords,
    ...workWords,
    ...foodWords,
    ...healthWords,
    ...campusWords,
  ];

  return [
    _lesson(
      id: 'lesson-exam-1',
      title: '考试信号词',
      section: '考试高频',
      description: '阅读、写作和题干里常见的学术动词。',
      status: 'current',
      xpReward: 30,
      words: examWords,
      distractorWords: allWords,
    ),
    _lesson(
      id: 'lesson-travel-1',
      title: '旅行基础',
      section: '旅行英语',
      description: '机场、行程和短对话中最常用的旅行词。',
      status: 'locked',
      xpReward: 25,
      words: travelWords,
      distractorWords: allWords,
    ),
    _lesson(
      id: 'lesson-work-1',
      title: '职场表达',
      section: '商务英语',
      description: '会议、协作和项目更新中的高频表达。',
      status: 'locked',
      xpReward: 30,
      words: workWords,
      distractorWords: allWords,
    ),
    _lesson(
      id: 'lesson-food-1',
      title: '饮食场景',
      section: '日常英语',
      description: '用餐、餐厅和日常安排里会遇到的实用词。',
      status: 'locked',
      xpReward: 20,
      words: foodWords,
      distractorWords: allWords,
    ),
    _lesson(
      id: 'lesson-health-1',
      title: '健康表达',
      section: '日常英语',
      description: '健康、恢复和日常求助场景里的常用词。',
      status: 'locked',
      xpReward: 20,
      words: healthWords,
      distractorWords: allWords,
    ),
    _lesson(
      id: 'lesson-campus-1',
      title: '校园速测词包',
      section: '训练场',
      description: '校园生活词汇保留给限时测试，不作为默认新学入口。',
      status: 'locked',
      xpReward: 20,
      words: campusWords,
      distractorWords: allWords,
    ),
  ];
}

Map<String, dynamic> _word({
  required String id,
  required String word,
  required String phonetic,
  required String meaning,
  required String definition,
  required String partOfSpeech,
  required String exampleSentence,
  required String exampleTranslation,
  required String imageCue,
  required String difficulty,
  required List<String> tags,
}) {
  return {
    'id': id,
    'word': word,
    'phonetic': phonetic,
    'meaning': meaning,
    'definition': definition,
    'partOfSpeech': partOfSpeech,
    'exampleSentence': exampleSentence,
    'exampleTranslation': exampleTranslation,
    'imageCue': imageCue,
    'difficulty': difficulty,
    'tags': tags,
  };
}

Map<String, dynamic> _lesson({
  required String id,
  required String title,
  required String section,
  required String description,
  required String status,
  required int xpReward,
  required List<Map<String, dynamic>> words,
  required List<Map<String, dynamic>> distractorWords,
}) {
  return {
    'id': id,
    'title': title,
    'section': section,
    'description': description,
    'status': status,
    'xpReward': xpReward,
    'estimatedMinutes': 5,
    'words': words,
    'questions': [
      _question(
        id: '$id-q1',
        type: 'meaningChoice',
        prompt: '选择“${words[0]['word']}”的中文释义。',
        answer: words[0]['meaning'] as String,
        options: _choiceOptions(
          answer: words[0]['meaning'] as String,
          localDistractors: [
            words[1]['meaning'] as String,
            words[2]['meaning'] as String,
          ],
          fallbackDistractors: distractorWords.map(
            (word) => word['meaning'] as String,
          ),
        ),
        explanation:
            '“${words[0]['word']}”的意思是${words[0]['meaning']}。${words[0]['exampleSentence']}',
        word: words[0],
      ),
      _question(
        id: '$id-q2',
        type: 'chineseChoice',
        prompt: '根据中文释义选择英文单词：${words[1]['meaning']}',
        answer: words[1]['word'] as String,
        options: _choiceOptions(
          answer: words[1]['word'] as String,
          localDistractors: [
            words[0]['word'] as String,
            words[2]['word'] as String,
          ],
          fallbackDistractors: distractorWords.map(
            (word) => word['word'] as String,
          ),
        ),
        explanation:
            '“${words[1]['meaning']}”对应“${words[1]['word']}”。${words[1]['exampleSentence']}',
        word: words[1],
      ),
      _question(
        id: '$id-q3',
        type: 'contextChoice',
        prompt:
            '根据语境选择“${words[2]['word']}”的中文释义：${words[2]['exampleSentence']}',
        answer: words[2]['meaning'] as String,
        options: _choiceOptions(
          answer: words[2]['meaning'] as String,
          localDistractors: [
            words[0]['meaning'] as String,
            words[1]['meaning'] as String,
          ],
          fallbackDistractors: distractorWords.map(
            (word) => word['meaning'] as String,
          ),
        ),
        explanation:
            '这句话里“${words[2]['word']}”表示${words[2]['meaning']}。${words[2]['exampleTranslation']}',
        word: words[2],
      ),
      _question(
        id: '$id-q4',
        type: 'spelling',
        prompt: '根据释义拼写单词：${words[2]['meaning']}',
        answer: words[2]['word'] as String,
        options: const [],
        explanation: '正确拼写是“${words[2]['word']}”。',
        word: words[2],
      ),
    ],
  };
}

Map<String, dynamic> _question({
  required String id,
  required String type,
  required String prompt,
  required String answer,
  required List<String> options,
  required String explanation,
  required Map<String, dynamic> word,
}) {
  return {
    'id': id,
    'type': type,
    'prompt': prompt,
    'answer': answer,
    'options': options,
    'explanation': explanation,
    'word': word,
  };
}

List<String> _choiceOptions({
  required String answer,
  required Iterable<String> localDistractors,
  required Iterable<String> fallbackDistractors,
}) {
  final options = <String>[];
  final seen = <String>{};

  void addOption(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return;
    final key = cleaned.toLowerCase();
    if (seen.add(key)) options.add(cleaned);
  }

  addOption(answer);
  for (final option in localDistractors) {
    addOption(option);
    if (options.length == 4) return List.unmodifiable(options);
  }
  for (final option in fallbackDistractors) {
    addOption(option);
    if (options.length == 4) return List.unmodifiable(options);
  }

  return List.unmodifiable(options);
}
