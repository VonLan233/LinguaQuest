#!/usr/bin/env python3
"""#C2: 给阅读理解题补英文提示字段（promptEn/optionsEn/explanationEn）。
一次性迁移，就地改写 articles_hsk1.json / articles_jlpt_n5.json。optionsEn 顺序与 options 一一对应。"""
import json, os

BASE = os.path.join(os.path.dirname(__file__), "..", "linguaquest", "lib", "assets", "data")

EN = {
  "zh_hsk1_life_001_q1": {
    "promptEn": "What time does the writer get up every day?",
    "optionsEn": ["6 o'clock", "7 o'clock", "8 o'clock", "10 o'clock"],
    "explanationEn": "The text says 'I get up at 7 every day.'"},
  "zh_hsk1_life_001_q2": {
    "promptEn": "Who does the writer have lunch with?",
    "optionsEn": ["Teacher", "Family", "Friends", "Alone"],
    "explanationEn": "The text says 'At noon I eat with friends.'"},
  "zh_hsk1_life_001_q3": {
    "promptEn": "The writer goes to bed at 10 pm. Is this correct?",
    "optionsEn": ["Correct", "Incorrect"],
    "explanationEn": "The text says 'In the evening I read, and sleep at 10.'"},
  "zh_hsk1_travel_001_q1": {
    "promptEn": "Who does the writer go to Beijing with?",
    "optionsEn": ["Friend", "Mother", "Teacher", "Older brother"],
    "explanationEn": "The text says 'I go to Beijing with my mother.'"},
  "zh_hsk1_travel_001_q2": {
    "promptEn": "How do they go to Beijing?",
    "optionsEn": ["By plane", "By train", "By car", "On foot"],
    "explanationEn": "The text says 'We go by plane.'"},
  "zh_hsk1_travel_001_q3": {
    "promptEn": "Beijing is very small. Is this correct?",
    "optionsEn": ["Correct", "Incorrect"],
    "explanationEn": "The text says 'Beijing is very big.'"},
  "zh_hsk1_campus_001_q1": {
    "promptEn": "What is the teacher's surname?",
    "optionsEn": ["Wang", "Li", "Zhang", "Chen"],
    "explanationEn": "The text says 'She is called Teacher Wang.'"},
  "zh_hsk1_campus_001_q2": {
    "promptEn": "How does the teacher speak Chinese?",
    "optionsEn": ["Very fast", "Very slow", "Very quiet", "Very loud"],
    "explanationEn": "The text says 'She speaks very slowly.'"},
  "zh_hsk1_campus_001_q3": {
    "promptEn": "The students do not like the teacher. Is this correct?",
    "optionsEn": ["Correct", "Incorrect"],
    "explanationEn": "The text says 'We all like her very much.'"},
  "ja_n5_life_001_q1": {
    "promptEn": "What time do I get up every morning?",
    "optionsEn": ["5 o'clock", "6 o'clock", "7 o'clock", "8 o'clock"],
    "explanationEn": "It says 'I get up at 6 every morning.'"},
  "ja_n5_life_001_q2": {
    "promptEn": "What is breakfast?",
    "optionsEn": ["Rice and fish", "Bread and eggs", "Ramen", "Salad"],
    "explanationEn": "It says 'Breakfast is bread and eggs.'"},
  "ja_n5_life_001_q3": {
    "promptEn": "I go to work by car. Is this correct?",
    "optionsEn": ["Yes", "No"],
    "explanationEn": "It says 'I go to work by train.'"},
  "ja_n5_travel_001_q1": {
    "promptEn": "Who do you go to Kyoto with?",
    "optionsEn": ["Family", "Friend", "Teacher", "Alone"],
    "explanationEn": "It says 'I go to Kyoto with a friend.'"},
  "ja_n5_travel_001_q2": {
    "promptEn": "How do you go to Kyoto?",
    "optionsEn": ["Bus", "Airplane", "Bullet train", "Car"],
    "explanationEn": "It says 'I go by bullet train.'"},
  "ja_n5_travel_001_q3": {
    "promptEn": "There are many temples in Kyoto. Is this correct?",
    "optionsEn": ["Yes", "No"],
    "explanationEn": "It says 'There are many old temples.'"},
}

def apply(fname):
  path = os.path.join(BASE, fname)
  data = json.load(open(path, encoding="utf-8"))
  arts = data if isinstance(data, list) else data.get("articles", data)
  n = 0
  for a in arts:
    for q in a.get("comprehension", []):
      en = EN.get(q.get("id"))
      if not en:
        raise SystemExit(f"缺英文映射: {q.get('id')}")
      if len(en["optionsEn"]) != len(q.get("options", [])):
        raise SystemExit(f"optionsEn 长度不匹配: {q['id']}")
      q.update(en)
      n += 1
  json.dump(data, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
  print(f"{fname}: 更新 {n} 题")

for f in ("articles_hsk1.json", "articles_jlpt_n5.json"):
  apply(f)
