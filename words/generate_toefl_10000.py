import re
from collections import defaultdict

import eng_to_ipa as ipa
import nltk
import pyphen
from nltk.corpus import wordnet as wn
from wordfreq import top_n_list, zipf_frequency

OUTPUT_PATH = "/Users/lisl/workspace/learning/words/words.md"
TARGET_ROWS = 10000
CANDIDATE_WORDS = 120000

POS_ORDER = ["n", "v", "a", "r", "s"]
POS_EN = {
    "n": "noun",
    "v": "verb",
    "a": "adjective",
    "r": "adverb",
    "s": "adjective satellite",
    "det": "determiner",
    "prep": "preposition",
    "conj": "conjunction",
    "pron": "pronoun",
    "aux": "auxiliary verb",
    "modal": "modal verb",
    "particle": "particle",
    "num": "numeral",
    "interj": "interjection",
    "u": "unknown",
}
POS_ZH = {
    "n": "名词",
    "v": "动词",
    "a": "形容词",
    "r": "副词",
    "s": "形容词",
    "det": "限定词",
    "prep": "介词",
    "conj": "连词",
    "pron": "代词",
    "aux": "助动词",
    "modal": "情态动词",
    "particle": "小品词",
    "num": "数词",
    "interj": "感叹词",
    "u": "未知词性",
}
WN_POS_MAP = {
    "n": "n",
    "v": "v",
    "a": "a",
    "r": "r",
    "s": "a",
}

# Filter out noisy dictionary senses that hurt TOEFL usefulness.
BAD_DEF_PATTERNS = (
    "chemical element",
    "metallic element",
    "atomic number",
    "halogen",
    "metric unit",
    "unit of length",
    "unit of surface area",
    "roman numeral",
    "letter of the alphabet",
    "abbreviation for",
    "symbol for",
)

FUNCTION_WORDS = {
    "the", "to", "and", "of", "a", "in", "for", "that", "you", "it",
    "on", "with", "this", "as", "at", "by", "from", "or", "an", "be",
    "are", "is", "was", "were", "been", "being", "if", "than", "then",
    "he", "she", "they", "we", "i", "me", "my", "your", "our", "their",
    "his", "her", "its", "do", "does", "did", "have", "has", "had",
    "can", "could", "will", "would", "shall", "should", "may", "might",
    "must", "not", "no", "so", "up", "out", "about", "into", "over",
    "under", "before", "after", "here", "there", "when", "where", "what",
    "which", "who", "whom", "why", "how", "all", "any", "some", "more",
    "most", "only", "just", "also", "new", "other", "one", "two", "three",
}

POS_HINTS = {
    "det": {
        "the", "a", "an", "this", "that", "these", "those", "some", "any", "each",
        "every", "either", "neither", "much", "many", "few", "little", "another", "other",
        "same", "such", "no", "enough", "all", "both", "half", "several", "various",
    },
    "prep": {
        "in", "on", "at", "by", "for", "from", "with", "about", "into", "over", "under",
        "through", "across", "between", "among", "during", "before", "after", "since", "until",
        "without", "within", "toward", "towards", "against", "via", "around", "near", "off",
        "beside", "besides", "despite", "beyond", "inside", "outside", "upon", "of", "to",
    },
    "conj": {
        "and", "or", "but", "nor", "yet", "so", "because", "although", "though", "while",
        "whereas", "if", "unless", "since", "once", "than", "whether", "as",
    },
    "pron": {
        "i", "you", "he", "she", "it", "we", "they", "me", "him", "her", "us", "them",
        "my", "your", "his", "its", "our", "their", "mine", "yours", "hers", "ours", "theirs",
        "myself", "yourself", "himself", "herself", "itself", "ourselves", "themselves", "who",
        "whom", "whose", "which", "what", "someone", "somebody", "anyone", "anybody", "everyone",
        "everybody", "none", "one", "ones", "another", "others", "this", "that", "these", "those",
    },
    "aux": {
        "am", "is", "are", "was", "were", "be", "been", "being", "do", "does", "did",
        "have", "has", "had",
    },
    "modal": {
        "can", "could", "may", "might", "must", "shall", "should", "will", "would",
    },
    "particle": {"not", "n't", "up", "out", "off", "away", "back", "down", "on"},
    "num": {
        "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
        "first", "second", "third", "fourth", "fifth", "hundred", "thousand", "million",
    },
    "interj": {"oh", "ah", "wow", "hey", "yes", "no"},
}

GRAMMAR_PRIORITY = ["aux", "modal", "particle", "det", "prep", "conj", "pron", "num", "interj"]

GRAMMAR_DEF_EN = {
    "det": "A function word that introduces or limits a noun phrase.",
    "prep": "A function word that links a noun phrase to another element in the sentence.",
    "conj": "A function word that connects words, phrases, or clauses.",
    "pron": "A function word used in place of a noun phrase.",
    "aux": "A helping verb used with a main verb to express tense, voice, or aspect.",
    "modal": "A modal auxiliary verb expressing possibility, ability, permission, or obligation.",
    "particle": "A short function word used in phrasal or grammatical constructions.",
    "num": "A word used to express number, quantity, or order.",
    "interj": "A short exclamation used to express emotion or reaction.",
}

GRAMMAR_DEF_ZH = {
    "det": "限定名词短语范围的功能词。",
    "prep": "连接名词短语与句中其他成分的功能词。",
    "conj": "连接词、短语或从句的功能词。",
    "pron": "代替名词短语使用的功能词。",
    "aux": "与实义动词连用，表达时态、语态或体的助动词。",
    "modal": "表达可能性、能力、许可或义务的情态助动词。",
    "particle": "用于短语或语法结构中的短功能词。",
    "num": "表示数量或顺序的数词。",
    "interj": "表达情感或反应的感叹词。",
}

NOISY_SUFFIXES = ("'s", "'re", "'ve", "'d", "'ll", "n't")
NOISY_TOKENS = {
    "gonna", "wanna", "gotta", "lol", "haha", "ya", "yo", "im", "dont", "thats",
    "etc", "dr", "st", "mr", "mrs", "ms", "jr", "sr", "ltd", "uk", "bbc", "nfl",
    "facebook", "youtube",
}


def is_noisy_candidate(word: str) -> bool:
    if word in NOISY_TOKENS:
        return True
    if word.endswith(NOISY_SUFFIXES):
        return True
    # Filter single-letter symbols except valid pronoun/indefinite article.
    if len(word) == 1 and word not in {"a", "i"}:
        return True
    return False


def sanitize(text: str) -> str:
    if not text:
        return ""
    return str(text).replace("|", "\\|").replace("\n", " ").strip()


def choose_synset_by_pos(word: str):
    synsets = wn.synsets(word)
    grouped = defaultdict(list)
    for syn in synsets:
        if not is_noisy_synset(word, syn.pos(), syn):
            grouped[syn.pos()].append(syn)
    return grouped


def is_noisy_synset(word: str, pos_code: str, syn) -> bool:
    definition = syn.definition().lower()
    lexname = syn.lexname().lower()

    if any(pat in definition for pat in BAD_DEF_PATTERNS):
        return True

    # High-frequency function words often get technical noun senses in WordNet.
    if word in FUNCTION_WORDS and pos_code == "n" and (
        lexname.startswith("noun.") or "unit" in definition or "element" in definition
    ):
        return True

    # Very short tokens are especially prone to technical symbol/unit noun senses.
    if len(word) <= 2 and pos_code == "n" and (
        "unit" in definition or "element" in definition or "letter" in definition
    ):
        return True

    return False


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
    grammar_examples = {
        "det": (
            f"{word.title()} data set in the report supports the main hypothesis.",
            "报告中的该数据集支持主要假设。",
            f"The lecturer highlighted {word} key factor before presenting the model.",
            "讲师在展示模型前强调了一个关键因素。",
            f"In TOEFL passages, {word} noun phrase often signals specific reference.",
            f"在托福文章中，含“{word}”的名词短语通常表示特指。",
        ),
        "prep": (
            f"The experiment was conducted {word} a controlled environment.",
            f"该实验是在受控环境中进行的（对应介词“{word}”）。",
            f"Students compared two theories {word} the discussion section.",
            f"学生在讨论部分比较了两种理论（使用介词“{word}”）。",
            f"Using {word} accurately helps connect ideas in TOEFL writing.",
            f"准确使用“{word}”有助于在托福写作中衔接观点。",
        ),
        "conj": (
            f"The sample size was small, {word} the trend was still meaningful.",
            f"样本量很小，但这一趋势仍有意义（连词“{word}”）。",
            f"You should note the cause {word} the effect in the passage.",
            f"你应在文章中关注原因与结果的连接关系（如“{word}”）。",
            f"A strong TOEFL response uses {word} to build clear logic.",
            f"高质量托福作答会用“{word}”构建清晰逻辑。",
        ),
        "pron": (
            f"When evidence is limited, {word} should evaluate each claim carefully.",
            f"当证据有限时，应谨慎评估每个论点（代词“{word}”）。",
            f"In the lecture, {word} refers back to the previous concept.",
            f"在讲座中，“{word}”回指前面的概念。",
            f"Recognizing what {word} refers to improves TOEFL listening accuracy.",
            f"识别“{word}”的指代对象能提升托福听力准确率。",
        ),
        "aux": (
            f"Researchers {word} collecting data before testing the hypothesis.",
            f"研究者在检验假设前已开始收集数据（助动词“{word}”）。",
            f"The policy {word} revised after the committee review.",
            f"该政策在委员会审查后被修订（含助动词“{word}”）。",
            f"In TOEFL grammar tasks, {word} helps mark tense and aspect.",
            f"在托福语法任务中，“{word}”有助于标记时态和体。",
        ),
        "modal": (
            f"The results {word} indicate a stronger correlation than expected.",
            f"结果可能表明相关性比预期更强（情态词“{word}”）。",
            f"A speaker {word} disagree while still acknowledging the evidence.",
            f"说话者可以在承认证据的同时提出不同意见（“{word}”）。",
            f"Choosing {word} precisely makes your TOEFL argument more accurate.",
            f"准确选择“{word}”会让你的托福论证更严谨。",
        ),
        "particle": (
            f"Please write {word} the final conclusion in one clear sentence.",
            f"请把最终结论完整写成一句清晰的话（对应小品词“{word}”）。",
            f"The professor pointed {word} a limitation of the earlier study.",
            f"教授指出了早期研究的一个局限（短语中使用“{word}”）。",
            f"Mastering particles such as {word} improves natural fluency.",
            f"掌握像“{word}”这样的词有助于提升表达自然度。",
        ),
        "num": (
            f"The article presents {word} major reasons for climate migration.",
            f"这篇文章提出了若干个气候迁移的主要原因（数词“{word}”）。",
            f"In the chart, {word} categories show steady growth.",
            f"在图表中，若干类别呈现稳定增长（对应“{word}”）。",
            f"Using {word} correctly helps describe data trends in TOEFL writing.",
            f"正确使用“{word}”有助于在托福写作中描述数据趋势。",
        ),
        "interj": (
            f"{word.title()}, that result was different from the initial prediction.",
            f"哎呀，这个结果与最初预测不同（感叹词“{word}”）。",
            f"{word.title()}, the speaker just changed the main claim.",
            f"注意，说话者刚刚改变了核心论点（提示词“{word}”）。",
            f"Understanding cues like {word} can help in TOEFL listening.",
            f"理解像“{word}”这样的提示词有助于托福听力。",
        ),
    }

    if pos_code in grammar_examples:
        return grammar_examples[pos_code]

    pos_zh = POS_ZH.get(pos_code, POS_ZH["u"])
    ex1 = f"The TOEFL reading passage uses '{word}' as a {POS_EN.get(pos_code, POS_EN['u'])}."
    ex1_zh = f"这篇托福阅读文章把“{word}”当作{pos_zh}使用。"

    ex2 = f"In the lecture, the speaker uses '{word}' to support the central idea."
    ex2_zh = f"在讲座中，说话者用“{word}”来支持核心观点。"

    ex3 = f"Using '{word}' correctly can improve your TOEFL writing score."
    ex3_zh = f"正确使用“{word}”可以提升你的托福写作分数。"

    return ex1, ex1_zh, ex2, ex2_zh, ex3, ex3_zh


def guess_function_pos(word: str) -> str:
    for pos_code, words in POS_HINTS.items():
        if word in words:
            return pos_code
    return "u"


def grammar_pos_for_word(word: str):
    labels = []
    for code in GRAMMAR_PRIORITY:
        if word in POS_HINTS.get(code, set()):
            labels.append(code)
    return labels


def main():
    # Prefer local corpora. If they are missing, fail fast with a clear message.
    try:
        nltk.data.find("corpora/wordnet")
    except LookupError as exc:
        raise SystemExit("Missing corpus: wordnet") from exc

    dic = pyphen.Pyphen(lang="en_US")
    rows = []

    words = top_n_list("en", CANDIDATE_WORDS)
    word_re = re.compile(r"^[a-z]+$")

    for word in words:
        if len(rows) >= TARGET_ROWS:
            break
        if not word_re.match(word):
            continue
        if is_noisy_candidate(word):
            continue

        freq = zipf_frequency(word, "en")
        grouped = choose_synset_by_pos(word)

        pos_list = [p for p in POS_ORDER if grouped.get(p)]
        g_pos = grammar_pos_for_word(word)
        for code in reversed(g_pos):
            if code not in pos_list:
                pos_list.insert(0, code)

        if not pos_list:
            guessed = guess_function_pos(word)
            if guessed == "u":
                continue
            pos_list = [guessed]

        for pos_code in pos_list:
            if len(rows) >= TARGET_ROWS:
                break

            syn = grouped[pos_code][0] if grouped.get(pos_code) else None
            word_ipa = ipa.convert(word)
            if "*" in word_ipa:
                word_ipa = ""

            syllable = dic.inserted(word)

            if pos_code == "u" or pos_code not in WN_POS_MAP:
                root = wn.morphy(word) or word
            else:
                root = wn.morphy(word, WN_POS_MAP[pos_code]) or wn.morphy(word) or word

            if pos_code in GRAMMAR_DEF_EN:
                en_def = GRAMMAR_DEF_EN[pos_code]
            else:
                en_def = syn.definition() if syn else "High-frequency English word used in academic and daily contexts."

            zh_gloss = first_chinese_gloss(syn)
            if pos_code in GRAMMAR_DEF_ZH:
                zh_gloss = GRAMMAR_DEF_ZH[pos_code]
            elif not zh_gloss:
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
