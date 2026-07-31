import Foundation

struct IPASpellingPatternItem: Identifiable {
    let symbol: String
    let graphemes: String
    let examples: String
    let playbackText: String

    var id: String { symbol + "-" + graphemes }
}

struct IPAEndingRuleItem: Identifiable {
    let id: String
    let pattern: String
    let pronunciation: String
    let rule: String
    let examples: String
    let playbackText: String
}

struct IPAMultiSoundItem: Identifiable {
    let spelling: String
    let mappings: String
    let examples: String

    var id: String { spelling }
}

struct IPAQuizItem: Identifiable {
    let id: String
    let prompt: String
    let choices: [String]
    let correctAnswer: String
    let analysis: String
}

enum IPASeedContent {
    static let vowelSpellingPatterns: [IPASpellingPatternItem] = [
        .init(symbol: "/iː/", graphemes: "ee, ea, e-e, ie, ei", examples: "see, teacher, compete, piece, receive", playbackText: "teacher"),
        .init(symbol: "/ɪ/", graphemes: "i, y, e, ui", examples: "sit, gym, pretty, build", playbackText: "sit"),
        .init(symbol: "/e/", graphemes: "e, ea, a, ai", examples: "bed, head, many, said", playbackText: "bed"),
        .init(symbol: "/æ/", graphemes: "a", examples: "cat, bag, map", playbackText: "cat"),
        .init(symbol: "/ɑː/", graphemes: "ar, a, al, au, ear", examples: "car, father, calm, laugh, heart", playbackText: "father"),
        .init(symbol: "/ɒ/", graphemes: "o, a, ou", examples: "hot, watch, cough", playbackText: "hot"),
        .init(symbol: "/ɔː/", graphemes: "or, ore, aw, au, al", examples: "short, more, law, author, talk", playbackText: "more"),
        .init(symbol: "/ʊ/", graphemes: "u, oo, ou", examples: "put, book, could", playbackText: "book"),
        .init(symbol: "/uː/", graphemes: "oo, u-e, ue, ui, ew, ou", examples: "food, flute, blue, fruit, new, group", playbackText: "blue"),
        .init(symbol: "/ʌ/", graphemes: "u, o, ou, oo", examples: "cup, love, young, blood", playbackText: "cup"),
        .init(symbol: "/ɜː/", graphemes: "ir, er, ur, ear, or", examples: "bird, term, nurse, learn, word", playbackText: "bird"),
        .init(symbol: "/ə/", graphemes: "a, e, i, o, u", examples: "about, problem, pencil, today, support", playbackText: "about")
    ]

    static let diphthongSpellingPatterns: [IPASpellingPatternItem] = [
        .init(symbol: "/eɪ/", graphemes: "a-e, ai, ay, ei, ey", examples: "name, rain, day, eight, they", playbackText: "name"),
        .init(symbol: "/aɪ/", graphemes: "i-e, igh, y, ie, i", examples: "time, light, my, tie, find", playbackText: "time"),
        .init(symbol: "/ɔɪ/", graphemes: "oi, oy", examples: "coin, boy", playbackText: "boy"),
        .init(symbol: "/əʊ/", graphemes: "o-e, oa, ow, o, oe, ou", examples: "home, boat, snow, go, toe, soul", playbackText: "home"),
        .init(symbol: "/aʊ/", graphemes: "ou, ow", examples: "out, now", playbackText: "out"),
        .init(symbol: "/ɪə/", graphemes: "ear, eer, ere, ea", examples: "near, deer, here, idea", playbackText: "near"),
        .init(symbol: "/eə/", graphemes: "air, are, ear, ere", examples: "air, care, bear, where", playbackText: "care"),
        .init(symbol: "/ʊə/", graphemes: "ure, our, oor", examples: "pure, tour, poor", playbackText: "pure")
    ]

    static let consonantSpellingPatterns: [IPASpellingPatternItem] = [
        .init(symbol: "/f/", graphemes: "f, ff, ph, gh", examples: "fun, coffee, photo, laugh", playbackText: "photo"),
        .init(symbol: "/k/", graphemes: "k, c, ck, ch, qu", examples: "kite, cat, back, school, queen", playbackText: "queen"),
        .init(symbol: "/s/", graphemes: "s, ss, c, ce, sc", examples: "sun, class, city, rice, science", playbackText: "science"),
        .init(symbol: "/z/", graphemes: "z, zz, s, se, x", examples: "zoo, puzzle, is, rose, exam", playbackText: "zoo"),
        .init(symbol: "/ʃ/", graphemes: "sh, ti, ci, si, ch", examples: "ship, nation, special, tension, machine", playbackText: "machine"),
        .init(symbol: "/ʒ/", graphemes: "s, si, g", examples: "measure, vision, genre", playbackText: "vision"),
        .init(symbol: "/tʃ/", graphemes: "ch, tch, -ture", examples: "chair, watch, nature", playbackText: "chair"),
        .init(symbol: "/dʒ/", graphemes: "j, g, dg", examples: "job, giant, bridge", playbackText: "job"),
        .init(symbol: "/θ/", graphemes: "th", examples: "think, bath, truth", playbackText: "think"),
        .init(symbol: "/ð/", graphemes: "th", examples: "this, mother, with", playbackText: "this")
    ]

    static let endingRules: [IPAEndingRuleItem] = [
        .init(
            id: "ending-s",
            pattern: "-s / -es",
            pronunciation: "/s/, /z/, /ɪz/",
            rule: "清辅音后读 /s/；浊辅音或元音后读 /z/；s/z/sh/ch/j 后读 /ɪz/。",
            examples: "cats /s/, dogs /z/, watches /ɪz/",
            playbackText: "watches"
        ),
        .init(
            id: "ending-ed",
            pattern: "-ed",
            pronunciation: "/t/, /d/, /ɪd/",
            rule: "清辅音后读 /t/；浊辅音或元音后读 /d/；词尾是 /t/ 或 /d/ 时读 /ɪd/。",
            examples: "worked /t/, played /d/, wanted /ɪd/",
            playbackText: "wanted"
        )
    ]

    static let multiSoundSpellings: [IPAMultiSoundItem] = [
        .init(spelling: "ea", mappings: "/iː/, /e/, /eɪ/", examples: "sea, head, great"),
        .init(spelling: "oo", mappings: "/uː/, /ʊ/, /ʌ/", examples: "food, book, blood"),
        .init(spelling: "ow", mappings: "/əʊ/ 或 /aʊ/", examples: "snow, cow"),
        .init(spelling: "ou", mappings: "/aʊ/, /ʌ/, /uː/, /ɔː/", examples: "out, young, group, four"),
        .init(spelling: "ch", mappings: "/tʃ/, /k/, /ʃ/", examples: "chair, school, machine"),
        .init(spelling: "th", mappings: "/θ/ 或 /ð/", examples: "think, this"),
        .init(spelling: "c", mappings: "/k/ 或 /s/", examples: "cat, city"),
        .init(spelling: "g", mappings: "/g/ 或 /dʒ/", examples: "go, giant")
    ]

    static let quizItems: [IPAQuizItem] = [
        .init(
            id: "ipa-q1",
            prompt: "food 的 oo 对应哪个音？",
            choices: ["/ʊ/", "/uː/", "/ʌ/"],
            correctAnswer: "/uː/",
            analysis: "food, moon, room 中 oo 高频读 /uː/。"
        ),
        .init(
            id: "ipa-q2",
            prompt: "book 的 oo 对应哪个音？",
            choices: ["/uː/", "/ʊ/", "/ɔː/"],
            correctAnswer: "/ʊ/",
            analysis: "book, good, foot 常见读 /ʊ/。"
        ),
        .init(
            id: "ipa-q3",
            prompt: "great 中 ea 的读音是：",
            choices: ["/e/", "/iː/", "/eɪ/"],
            correctAnswer: "/eɪ/",
            analysis: "ea 有多读音：sea /iː/，head /e/，great /eɪ/。"
        ),
        .init(
            id: "ipa-q4",
            prompt: "city 里的 c 通常读：",
            choices: ["/k/", "/s/", "/tʃ/"],
            correctAnswer: "/s/",
            analysis: "c 在 e/i/y 前常读 /s/，如 city, cent。"
        ),
        .init(
            id: "ipa-q5",
            prompt: "giant 里的 g 通常读：",
            choices: ["/g/", "/dʒ/", "/ʒ/"],
            correctAnswer: "/dʒ/",
            analysis: "g 在 e/i/y 前常读 /dʒ/，如 giant, age。"
        ),
        .init(
            id: "ipa-q6",
            prompt: "think 中 th 的读音是：",
            choices: ["/θ/", "/ð/", "/t/"],
            correctAnswer: "/θ/",
            analysis: "think, bath, truth 常读 /θ/；this, mother 常读 /ð/。"
        ),
        .init(
            id: "ipa-q7",
            prompt: "this 中 th 的读音是：",
            choices: ["/θ/", "/ð/", "/z/"],
            correctAnswer: "/ð/",
            analysis: "this, that, mother 中 th 常读 /ð/。"
        ),
        .init(
            id: "ipa-q8",
            prompt: "cats 的 -s 词尾读音是：",
            choices: ["/s/", "/z/", "/ɪz/"],
            correctAnswer: "/s/",
            analysis: "清辅音后 -s 常读 /s/，如 cats, books。"
        ),
        .init(
            id: "ipa-q9",
            prompt: "dogs 的 -s 词尾读音是：",
            choices: ["/s/", "/z/", "/ɪz/"],
            correctAnswer: "/z/",
            analysis: "浊辅音或元音后 -s 常读 /z/，如 dogs, plays。"
        ),
        .init(
            id: "ipa-q10",
            prompt: "watches 的 -es 词尾读音是：",
            choices: ["/s/", "/z/", "/ɪz/"],
            correctAnswer: "/ɪz/",
            analysis: "s/z/sh/ch/j 后加 -es 常读 /ɪz/。"
        ),
        .init(
            id: "ipa-q11",
            prompt: "worked 的 -ed 词尾读音是：",
            choices: ["/t/", "/d/", "/ɪd/"],
            correctAnswer: "/t/",
            analysis: "清辅音后 -ed 常读 /t/，如 worked, helped。"
        ),
        .init(
            id: "ipa-q12",
            prompt: "wanted 的 -ed 词尾读音是：",
            choices: ["/t/", "/d/", "/ɪd/"],
            correctAnswer: "/ɪd/",
            analysis: "词尾是 /t/ 或 /d/ 时，-ed 读 /ɪd/。"
        )
    ]
}
