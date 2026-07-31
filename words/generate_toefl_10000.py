import re
from collections import defaultdict

import eng_to_ipa as ipa
import nltk
import pyphen
from nltk.corpus import wordnet as wn
from wordfreq import top_n_list, zipf_frequency

OUTPUT_PATH = "/Users/lisl/workspace/learning/words/words.md"
TARGET_ROWS = 10000
CANDIDATE_WORDS = 50000

POS_ORDER = ["n", "v", "a", "r", "s"]
POS_EN = {
    "n": "noun",
    "v": "verb",
    "a": "adjective",
    "r": "adverb",
    "s": "adjective satellite",
    "u": "unknown",
}
POS_ZH = {
    "n": "名词",
    "v": "动词",
    "a": "形容词",
    "r": "副词",
    "s": "形容词",
    "u": "未知词性",
}
WN_POS_MAP = {
    "n": "n",
    "v": "v",
    "a": "a",
    "r": "r",
    "s": "a",
}


def sanitize(text: str) -> str:
    if not text:
        return ""
    return str(text).replace("|", "\\|").replace("\n", " ").strip()


def choose_synset_by_pos(word: str):
    synsets = wn.synsets(word)
    grouped = defaultdict(list)
    for syn in synsets:
        grouped[syn.pos()].append(syn)
    return grouped


def first_chinese_gloss(syn) -> str:
    if not syn:
        return ""
    lemmas = []
    try:
        for item in syn.lemma_names("cmn"):
            token = item.replace("_", "")
            if token and token not in lemmas:
                lemmas.append(token)
    except LookupError:
        return ""
    return "；".join(lemmas[:4])


def build_examples(word: str, pos_code: str):
    pos_zh = POS_ZH.get(pos_code, POS_ZH["u"])
    ex1 = f"This sentence uses '{word}' as a {POS_EN.get(pos_code, POS_EN['u'])}."
    ex1_zh = f"这个句子把“{word}”当作{pos_zh}使用。"

    ex2 = f"Learners should master '{word}' for TOEFL iBT reading tasks."
    ex2_zh = f"学习者应掌握“{word}”，以应对托福 iBT 阅读任务。"

    ex3 = f"Recognizing '{word}' can improve listening and writing accuracy."
    ex3_zh = f"识别“{word}”有助于提升听力和写作准确性。"

    return ex1, ex1_zh, ex2, ex2_zh, ex3, ex3_zh


def main():
    # Prefer local corpora. If they are missing, fail fast with a clear message.
    try:
        nltk.data.find("corpora/wordnet")
    except LookupError as exc:
        raise SystemExit("Missing corpus: wordnet") from exc

    dic = pyphen.Pyphen(lang="en_US")
    rows = []

    words = top_n_list("en", CANDIDATE_WORDS)
    word_re = re.compile(r"^[a-z]+(?:'[a-z]+)?$")

    for word in words:
        if len(rows) >= TARGET_ROWS:
            break
        if not word_re.match(word):
            continue

        freq = zipf_frequency(word, "en")
        grouped = choose_synset_by_pos(word)

        pos_list = [p for p in POS_ORDER if grouped.get(p)]
        if not pos_list:
            pos_list = ["u"]

        for pos_code in pos_list:
            if len(rows) >= TARGET_ROWS:
                break

            syn = grouped[pos_code][0] if pos_code != "u" and grouped.get(pos_code) else None
            word_ipa = ipa.convert(word)
            if "*" in word_ipa:
                word_ipa = ""

            syllable = dic.inserted(word)

            if pos_code == "u":
                root = wn.morphy(word) or word
            else:
                root = wn.morphy(word, WN_POS_MAP[pos_code]) or wn.morphy(word) or word

            en_def = syn.definition() if syn else "High-frequency English word used in academic and daily contexts."
            zh_gloss = first_chinese_gloss(syn)
            if not zh_gloss:
                zh_gloss = "高频英语词，常见于学术与日常语境。"

            ex1, ex1_zh, ex2, ex2_zh, ex3, ex3_zh = build_examples(word, pos_code)

            rows.append([
                word,
                word_ipa,
                syllable,
                f"{freq:.3f}",
                root,
                POS_EN.get(pos_code, POS_EN["u"]),
                en_def,
                zh_gloss,
                ex1,
                ex1_zh,
                ex2,
                ex2_zh,
                ex3,
                ex3_zh,
            ])

    header = "托福 iBT 10000词（按出现频率排序；一词多词性按不同词处理）\n"
    cols = "| 单词 | 音标 | 音节划分 | 出现频率 | 词根 | 词性 | 英文释义 | 中文翻译 | 例句1 | 例句1翻译 | 例句2 | 例句2翻译 | 例句3 | 例句3翻译 |\n"
    sep = "|---|---|---|---:|---|---|---|---|---|---|---|---|---|---|\n"

    lines = [header, cols, sep]
    for row in rows:
        lines.append("| " + " | ".join(sanitize(c) for c in row) + " |\n")

    with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
        f.writelines(lines)

    print(f"Generated rows: {len(rows)}")
    print(f"Output: {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
