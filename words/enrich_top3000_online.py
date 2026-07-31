import json
import html
import os
import re
import time
from dataclasses import dataclass
from typing import Dict, List, Optional, Tuple
from urllib.parse import quote

import requests

WORDS_MD = "/Users/lisl/workspace/learning/words/words.md"
TOP_N = 3000
START_ROW = int(os.getenv("START_ROW", "1"))
END_ROW = int(os.getenv("END_ROW", str(TOP_N)))
ENABLE_TRANSLATION = os.getenv("ENABLE_TRANSLATION", "0") == "1"
HTTP_TIMEOUT = float(os.getenv("HTTP_TIMEOUT", "6"))
HTTP_RETRIES = int(os.getenv("HTTP_RETRIES", "2"))

POS_MAP = {
    "noun": "noun",
    "verb": "verb",
    "adjective": "adjective",
    "adjective satellite": "adjective",
    "adverb": "adverb",
    "preposition": "preposition",
    "conjunction": "conjunction",
    "pronoun": "pronoun",
    "determiner": "determiner",
    "auxiliary verb": "verb",
    "modal verb": "verb",
    "particle": "particle",
    "numeral": "numeral",
    "interjection": "interjection",
}

EXAMPLE_BAN_PATTERNS = (
    "toefl",
    "in the passage",
    "in the reading passage",
    "the lecturer uses",
    "learning '",
    "marks an important relationship between ideas",
    "to keep the argument coherent",
    "academic writing clearer",
    "when describing a method or result",
    "appears in the explanation of the main claim",
    "helps you express actions precisely in academic english",
)


def fallback_examples(word: str, pos: str) -> Tuple[List[str], List[str]]:
    pos_norm = POS_MAP.get(pos, pos)
    curated = {
        ("the", "determiner"): (
            [
                "The results of the experiment were published last year.",
                "The professor explained the model in simple terms.",
                "The article shows how the climate is changing over time.",
            ],
            [
                "这项实验的结果于去年发表。",
                "教授用简单的方式解释了这个模型。",
                "这篇文章展示了气候如何随时间变化。",
            ],
        ),
        ("a", "determiner"): (
            [
                "A new study challenged the older explanation.",
                "The speaker gave a clear example in class.",
                "A careful reader can see the difference immediately.",
            ],
            [
                "一项新研究挑战了旧有解释。",
                "讲者在课堂上举了一个清晰的例子。",
                "细心的读者可以立刻看出区别。",
            ],
        ),
        ("and", "conjunction"): (
            [
                "The lecture compared urban growth and environmental change.",
                "The article explains the cause and the effect in detail.",
                "Students must read carefully and answer precisely.",
            ],
            [
                "这场讲座比较了城市增长与环境变化。",
                "这篇文章详细解释了原因和结果。",
                "学生必须认真阅读并准确作答。",
            ],
        ),
        ("of", "preposition"): (
            [
                "The results of the survey surprised the researchers.",
                "Most of the evidence supports the main claim.",
                "The history of the region is discussed in the final section.",
            ],
            [
                "调查结果让研究人员感到意外。",
                "大多数证据支持核心论点。",
                "该地区的历史在最后一节中被讨论。",
            ],
        ),
        ("in", "preposition"): (
            [
                "Many marine species live in cold water.",
                "In the lecture, the professor described a new theory.",
                "The data were collected in three different cities.",
            ],
            [
                "许多海洋物种生活在冷水中。",
                "在讲座中，教授介绍了一个新理论。",
                "这些数据是在三个不同城市收集的。",
            ],
        ),
        ("i", "pronoun"): (
            [
                "I think the author is making a reasonable argument.",
                "I noticed that the second graph showed a different trend.",
                "I would summarize the lecture in one sentence first.",
            ],
            [
                "我认为作者提出了一个合理的论点。",
                "我注意到第二张图呈现出不同的趋势。",
                "我会先用一句话概括这场讲座。",
            ],
        ),
        ("you", "pronoun"): (
            [
                "If you compare the two charts, the pattern becomes clear.",
                "You can understand the passage better by tracking the examples.",
                "When you organize your notes well, the lecture is easier to recall.",
            ],
            [
                "如果你比较这两张图表，规律就会变得清晰。",
                "通过追踪例子，你能更好地理解这篇文章。",
                "当你把笔记整理好时，这场讲座会更容易回忆。",
            ],
        ),
        ("on", "particle"): (
            [
                "Please turn on the recorder before the lecture begins.",
                "The discussion went on for another twenty minutes.",
                "Once the experiment was on, the team monitored every change.",
            ],
            [
                "请在讲座开始前打开录音设备。",
                "讨论又继续了二十分钟。",
                "实验一开始，团队就监测每一个变化。",
            ],
        ),
    }

    curated_key = (word, pos_norm)
    if curated_key in curated:
        return curated[curated_key]

    if pos == "auxiliary verb":
        en = [
            f"The auxiliary form '{word}' helps mark tense or aspect in the sentence.",
            f"In the lecture transcript, '{word}' appears in a clause describing an ongoing process.",
            f"Recognizing auxiliary verbs like '{word}' improves grammatical accuracy in TOEFL tasks.",
        ]
        zh = [
            f"助动词形式“{word}”有助于在句子中标记时态或体。",
            f"在讲座文本中，“{word}”出现在描述持续过程的从句里。",
            f"识别像“{word}”这样的助动词有助于提升托福题目的语法准确性。",
        ]
        return en, zh

    if pos == "modal verb":
        en = [
            f"The modal verb '{word}' adds possibility, intention, or prediction to the statement.",
            f"Writers use '{word}' when they want to qualify the strength of a claim.",
            f"Understanding modal verbs like '{word}' helps you interpret tone more precisely.",
        ]
        zh = [
            f"情态动词“{word}”为陈述增加可能性、意图或预测含义。",
            f"当作者想限制一个论断的力度时，会使用“{word}”。",
            f"理解像“{word}”这样的情态动词有助于你更准确地把握语气。",
        ]
        return en, zh

    if pos_norm == "determiner":
        en = [
            f"The determiner '{word}' helps specify the noun that follows it.",
            f"Writers use '{word}' to make reference clearer for the reader.",
            f"Correct use of determiners like '{word}' improves precision in academic writing.",
        ]
        zh = [
            f"限定词“{word}”有助于明确其后名词的所指。",
            f"作者使用“{word}”来让读者更清楚地理解指代对象。",
            f"正确使用像“{word}”这样的限定词能提升学术表达的精确性。",
        ]
        return en, zh

    if pos_norm == "pronoun":
        en = [
            f"The pronoun '{word}' refers to a person, thing, or idea mentioned in context.",
            f"Readers must track what '{word}' points to in the surrounding sentences.",
            f"Accurate use of pronouns like '{word}' helps avoid repetition in academic writing.",
        ]
        zh = [
            f"代词“{word}”指代语境中已经提到的人、事物或概念。",
            f"读者需要根据上下文判断“{word}”具体指向什么。",
            f"准确使用像“{word}”这样的代词有助于避免学术写作中的重复。",
        ]
        return en, zh

    if pos_norm == "preposition":
        en = [
            f"The preposition '{word}' links a noun phrase to time, place, or logical relation.",
            f"Writers use '{word}' to connect one part of the sentence with another.",
            f"Mastering prepositions like '{word}' helps you build clearer sentence structure in academic English.",
        ]
        zh = [
            f"介词“{word}”用于连接名词短语与时间、地点或逻辑关系。",
            f"作者使用“{word}”来连接句中的不同成分。",
            f"掌握像“{word}”这样的介词有助于你在学术英语中构建更清晰的句子结构。",
        ]
        return en, zh

    if pos_norm == "conjunction":
        en = [
            f"The writer uses '{word}' to connect two related claims.",
            f"A conjunction like '{word}' helps the argument move smoothly from one idea to the next.",
            f"Recognizing '{word}' makes the logical structure of the passage easier to follow.",
        ]
        zh = [
            f"作者使用“{word}”来连接两个相关论点。",
            f"像“{word}”这样的连词能让论证从一个观点自然过渡到下一个观点。",
            f"识别“{word}”能让文章的逻辑结构更容易理解。",
        ]
        return en, zh

    if pos_norm == "particle":
        en = [
            f"In phrasal expressions, '{word}' can change the meaning of the verb.",
            f"The listener needs to notice how '{word}' works inside the full expression.",
            f"Understanding particles like '{word}' improves natural comprehension of spoken English.",
        ]
        zh = [
            f"在短语表达中，“{word}”会改变动词的含义。",
            f"听者需要注意“{word}”在完整表达中的作用。",
            f"理解像“{word}”这样的虚词有助于更自然地理解英语口语。",
        ]
        return en, zh

    if pos_norm in {"interjection", "numeral"}:
        en = [
            f"The passage includes '{word}' in a short but meaningful expression.",
            f"In context, '{word}' adds information that shapes the reader's interpretation.",
            f"Using '{word}' correctly helps keep the sentence accurate and natural.",
        ]
        zh = [
            f"文章在一个简短但有意义的表达中使用了“{word}”。",
            f"在语境中，“{word}”补充了影响读者理解的信息。",
            f"正确使用“{word}”有助于保持句子准确自然。",
        ]
        return en, zh

    if pos_norm == "verb":
        en = [
            f"Researchers often use {word} when describing a method or result.",
            f"In the lecture, {word} appears in the explanation of the main claim.",
            f"Mastering {word} helps you express actions precisely in academic English.",
        ]
        zh = [
            f"研究者在描述方法或结果时常会用到 {word}。",
            f"在讲座中，{word} 出现在对核心观点的解释里。",
            f"掌握 {word} 有助于你在学术英语中更准确地表达动作。",
        ]
        return en, zh

    if pos_norm == "adjective":
        en = [
            f"The author chose {word} to qualify the central concept.",
            f"This study compares two {word} interpretations of the same data.",
            f"Using {word} well can make your analysis more precise.",
        ]
        zh = [
            f"作者选择 {word} 来限定核心概念。",
            f"这项研究比较了同一数据的两种 {word} 解读。",
            f"恰当使用 {word} 能让你的分析更精确。",
        ]
        return en, zh

    if pos_norm == "adverb":
        en = [
            f"The speaker used {word} to adjust the strength of the statement.",
            f"In academic writing, {word} can change the nuance of an argument.",
            f"Recognizing {word} helps you understand the writer's stance.",
        ]
        zh = [
            f"说话者使用 {word} 来调整陈述的力度。",
            f"在学术写作中，{word} 会改变论证的语气细微差别。",
            f"识别 {word} 有助于你理解作者立场。",
        ]
        return en, zh

    # noun and other defaults
    en = [
        f"The passage introduces {word} as a key concept in the discussion.",
        f"The professor explained how {word} relates to the final conclusion.",
        f"Using {word} precisely can strengthen your TOEFL response.",
    ]
    zh = [
        f"文章把 {word} 作为讨论中的关键概念提出。",
        f"教授解释了 {word} 与最终结论之间的关系。",
        f"准确使用 {word} 能增强你的托福作答。",
    ]
    return en, zh


@dataclass
class Row:
    original: str
    cols: List[str]


def parse_table_row(line: str) -> Optional[Row]:
    if not line.startswith("| "):
        return None
    cols = [c.strip() for c in line.strip().strip("|").split("|")]
    if len(cols) != 14:
        return None
    return Row(original=line, cols=cols)


def build_table_row(cols: List[str]) -> str:
    safe = [c.replace("|", "\\|").replace("\n", " ").strip() for c in cols]
    return "| " + " | ".join(safe) + " |\n"


def is_templated_example(text: str) -> bool:
    t = text.lower()
    return any(p in t for p in EXAMPLE_BAN_PATTERNS)


def normalize_sentence(s: str) -> str:
    s = re.sub(r"\s+", " ", s).strip()
    if not s:
        return s
    if s[0].islower():
        s = s[0].upper() + s[1:]
    if s[-1] not in ".!?":
        s += "."
    return s


def strip_html(text: str) -> str:
    text = html.unescape(text)
    text = re.sub(r"<[^>]+>", "", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text


def is_good_example(s: str, word: str) -> bool:
    s2 = s.strip()
    if len(s2) < 20 or len(s2) > 180:
        return False
    low = s2.lower()
    if any(p in low for p in EXAMPLE_BAN_PATTERNS):
        return False
    # Prefer examples containing the target word (allow simple boundary match)
    return re.search(rf"\b{re.escape(word.lower())}\b", low) is not None


def fetch_dict_entry(session: requests.Session, word: str) -> Optional[dict]:
    url = f"https://api.dictionaryapi.dev/api/v2/entries/en/{quote(word)}"
    for _ in range(HTTP_RETRIES):
        try:
            resp = session.get(url, timeout=HTTP_TIMEOUT)
            if resp.status_code == 200:
                data = resp.json()
                if isinstance(data, list) and data:
                    return data[0]
                return None
            if resp.status_code in (404, 429):
                return None
        except requests.RequestException:
            time.sleep(0.4)
    return None


def fetch_wiktionary_entry(session: requests.Session, word: str) -> Optional[dict]:
    url = f"https://en.wiktionary.org/api/rest_v1/page/definition/{quote(word)}"
    for _ in range(HTTP_RETRIES):
        try:
            resp = session.get(url, timeout=HTTP_TIMEOUT)
            if resp.status_code == 200:
                data = resp.json()
                en = data.get("en", [])
                if isinstance(en, list) and en:
                    return data
                return None
            if resp.status_code in (404, 429, 403):
                return None
        except (requests.RequestException, json.JSONDecodeError):
            time.sleep(0.4)
    return None


def choose_meaning(entry: dict, pos: str) -> Tuple[Optional[str], List[str]]:
    target = POS_MAP.get(pos, "")
    meanings = entry.get("meanings", [])

    def extract_defs_examples(meaning: dict) -> Tuple[List[str], List[str]]:
        defs = []
        exs = []
        for d in meaning.get("definitions", []):
            dv = d.get("definition", "").strip()
            ev = d.get("example", "").strip()
            if dv:
                defs.append(dv)
            if ev:
                exs.append(ev)
        return defs, exs

    selected_defs: List[str] = []
    selected_exs: List[str] = []

    # exact pos first
    if target:
        for m in meanings:
            if m.get("partOfSpeech", "").strip().lower() == target:
                defs, exs = extract_defs_examples(m)
                selected_defs.extend(defs)
                selected_exs.extend(exs)
                break

    # fallback all meanings
    if not selected_defs:
        for m in meanings:
            defs, exs = extract_defs_examples(m)
            selected_defs.extend(defs)
            selected_exs.extend(exs)

    definition = selected_defs[0] if selected_defs else None
    uniq_exs = []
    seen = set()
    for e in selected_exs:
        n = normalize_sentence(e)
        key = n.lower()
        if key not in seen:
            seen.add(key)
            uniq_exs.append(n)
    return definition, uniq_exs


def choose_wiktionary_meaning(entry: dict, pos: str) -> Tuple[Optional[str], List[str]]:
    target = POS_MAP.get(pos, "")
    en = entry.get("en", [])
    if not isinstance(en, list):
        return None, []

    chosen = None
    for item in en:
        if not isinstance(item, dict):
            continue
        if item.get("partOfSpeech", "").strip().lower() == target:
            chosen = item
            break
    if chosen is None and en:
        chosen = en[0]

    if not chosen:
        return None, []

    defs = []
    exs = []
    for d in chosen.get("definitions", []):
        if not isinstance(d, dict):
            continue
        definition = strip_html(d.get("definition", "")).strip()
        if definition:
            defs.append(definition)
        for ex in d.get("examples", []) or []:
            ex_text = ""
            if isinstance(ex, dict):
                ex_text = ex.get("example") or ex.get("text") or ""
            elif isinstance(ex, str):
                ex_text = ex
            ex_text = strip_html(ex_text)
            if ex_text:
                exs.append(normalize_sentence(ex_text))
        for ex in d.get("parsedExamples", []) or []:
            ex_text = ""
            if isinstance(ex, dict):
                ex_text = ex.get("example") or ex.get("text") or ""
            elif isinstance(ex, str):
                ex_text = ex
            ex_text = strip_html(ex_text)
            if ex_text:
                exs.append(normalize_sentence(ex_text))

    definition = defs[0] if defs else None
    uniq_exs = []
    seen = set()
    for e in exs:
        key = e.lower()
        if key not in seen:
            seen.add(key)
            uniq_exs.append(e)
    return definition, uniq_exs


def translate_en_zh(session: requests.Session, text: str, cache: Dict[str, str]) -> str:
    if text in cache:
        return cache[text]

    url = (
        "https://translate.googleapis.com/translate_a/single"
        f"?client=gtx&sl=en&tl=zh-CN&dt=t&q={quote(text)}"
    )
    for _ in range(HTTP_RETRIES):
        try:
            r = session.get(url, timeout=HTTP_TIMEOUT)
            if r.status_code == 200:
                data = r.json()
                # standard shape: [[['translated', 'src', ...], ...], ...]
                translated = "".join(seg[0] for seg in data[0] if seg and seg[0])
                translated = translated.strip()
                if translated:
                    cache[text] = translated
                    return translated
                break
            if r.status_code in (429, 403):
                break
        except (requests.RequestException, json.JSONDecodeError):
            time.sleep(0.4)

    # fallback: keep original Chinese slot if translation fails
    cache[text] = ""
    return ""


def main() -> None:
    with open(WORDS_MD, "r", encoding="utf-8") as f:
        lines = f.readlines()

    session = requests.Session()
    session.headers.update({"User-Agent": "CopilotVocabularyBuilder/1.0 (contact: local)"})

    word_cache: Dict[str, Optional[dict]] = {}
    trans_cache: Dict[str, str] = {}

    data_row_count = 0
    changed = 0

    print("start: scanning top 3000 rows", flush=True)

    for idx, line in enumerate(lines):
        row = parse_table_row(line)
        if not row:
            continue

        # skip header and separator rows
        if data_row_count == 0 and row.cols[0] == "单词":
            continue
        if row.cols[0].startswith("---"):
            continue

        data_row_count += 1
        if data_row_count > TOP_N:
            continue
        if data_row_count < START_ROW or data_row_count > END_ROW:
            continue

        if data_row_count % 100 == 0:
            print(f"heartbeat: scanned_data_rows={data_row_count}, changed={changed}", flush=True)

        word = row.cols[0].strip().lower()
        pos = row.cols[5].strip().lower()

        # only refine clearly templated rows to avoid over-editing good rows
        if not (
            is_templated_example(row.cols[8])
            or is_templated_example(row.cols[10])
            or is_templated_example(row.cols[12])
        ):
            continue

        if word not in word_cache:
            word_cache[word] = fetch_dict_entry(session, word)
        entry = word_cache[word]

        wik_entry = fetch_wiktionary_entry(session, word)

        if not entry and not wik_entry:
            continue

        # IPA补齐
        if entry and not row.cols[1]:
            for p in entry.get("phonetics", []):
                t = (p.get("text") or "").strip()
                if t:
                    row.cols[1] = t
                    break

        definition = None
        examples: List[str] = []
        if entry:
            definition, examples = choose_meaning(entry, pos)
        if (not definition or len(examples) < 3) and wik_entry:
            w_def, w_examples = choose_wiktionary_meaning(wik_entry, pos)
            if w_def and (not definition or len(w_def) > len(definition)):
                definition = w_def
            if len(w_examples) > len(examples):
                examples = w_examples
        if definition:
            row.cols[6] = definition

        picked: List[str] = []
        for ex in examples:
            if is_good_example(ex, word):
                picked.append(ex)
            if len(picked) == 3:
                break

        # fallback: allow non-word-containing but natural examples
        if len(picked) < 3:
            for ex in examples:
                n = normalize_sentence(ex)
                if len(n) >= 20 and len(n) <= 180 and n not in picked:
                    picked.append(n)
                if len(picked) == 3:
                    break

        used_fallback = False
        fallback_zh: List[str] = []
        if len(picked) < 3:
            fb_en, fb_zh = fallback_examples(word, pos)
            picked = fb_en
            fallback_zh = fb_zh
            used_fallback = True

        # update examples and zh translations
        row.cols[8], row.cols[10], row.cols[12] = picked[0], picked[1], picked[2]

        if ENABLE_TRANSLATION and not used_fallback:
            zh1 = translate_en_zh(session, picked[0], trans_cache)
            zh2 = translate_en_zh(session, picked[1], trans_cache)
            zh3 = translate_en_zh(session, picked[2], trans_cache)

            if zh1:
                row.cols[9] = zh1
            if zh2:
                row.cols[11] = zh2
            if zh3:
                row.cols[13] = zh3
        elif used_fallback:
            row.cols[9], row.cols[11], row.cols[13] = fallback_zh[0], fallback_zh[1], fallback_zh[2]

        lines[idx] = build_table_row(row.cols)
        changed += 1

        if changed % 50 == 0:
            print(f"changed={changed}, scanned_data_rows={data_row_count}", flush=True)

    with open(WORDS_MD, "w", encoding="utf-8") as f:
        f.writelines(lines)

    print(
        f"done: changed_rows={changed}, scanned_data_rows={min(data_row_count, TOP_N)}, "
        f"row_window={START_ROW}-{END_ROW}, translation={ENABLE_TRANSLATION}",
        flush=True,
    )


if __name__ == "__main__":
    main()
