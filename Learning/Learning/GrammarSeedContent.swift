import Foundation

enum GrammarSeedContent {
    static let topics: [GrammarTopic] = [
        GrammarTopic(
            id: "morphology",
            title: "词法系统",
            subtitle: "词性、限定词与核心词法规则",
            summary: "基于语法总览中的词法部分，先打牢词类识别与基本搭配。",
            order: 1,
            lessons: [
                GrammarLesson(
                    id: "morphology-pos-determiners",
                    topicID: "morphology",
                    title: "词类与限定词",
                    goal: "能够区分名词、代词、冠词、限定词，并在句子中正确使用。",
                    level: .foundation,
                    explanationSections: [
                        .init(
                            title: "词类基础",
                            body: "名词表示人/事/物，代词代替名词，冠词与限定词负责限定名词范围。学术阅读中，先识别限定词能快速定位名词短语边界。",
                            highlightRule: "同一名词前通常只保留一个中心限定词，如 this book / my book。"
                        ),
                        .init(
                            title: "冠词规则",
                            body: "a/an 表泛指，the 表特指或再次提及，复数泛指与不可数泛指常用零冠词。",
                            highlightRule: "an 用于元音音素前：an hour；a 用于辅音音素前：a university。"
                        )
                    ],
                    examplePairs: [
                        .init(
                            correctSentence: "I saw a dog. The dog was friendly.",
                            wrongSentence: "I saw dog. Dog was friendly.",
                            explanation: "首次提及可数名词单数通常需要冠词，再次提及常用 the 特指。"
                        ),
                        .init(
                            correctSentence: "Each student has a notebook.",
                            wrongSentence: "Each students have a notebook.",
                            explanation: "each 作限定词时，后接单数名词，谓语常用单数。"
                        )
                    ],
                    quizItems: [
                        .init(
                            id: "morphology-pos-determiners-q1",
                            type: .multipleChoice,
                            prompt: "___ honest student should avoid copying answers.",
                            choices: ["A", "An", "The"],
                            correctAnswer: "An",
                            analysis: "honest 以元音音素开头，泛指单数名词用 an。"
                        ),
                        .init(
                            id: "morphology-pos-determiners-q2",
                            type: .fillInBlank,
                            prompt: "Books are useful.（此处应填冠词还是零冠词）",
                            choices: [],
                            correctAnswer: "零冠词",
                            analysis: "复数名词泛指时通常不加冠词。"
                        )
                    ],
                    order: 1
                ),
                GrammarLesson(
                    id: "morphology-verb-adj-adv-prep",
                    topicID: "morphology",
                    title: "动词、形容词、副词与介词",
                    goal: "识别常见词性误用，避免句子主干和修饰关系错误。",
                    level: .foundation,
                    explanationSections: [
                        .init(
                            title: "动词与修饰语",
                            body: "动词决定句子谓语核心；形容词修饰名词，副词修饰动词/形容词/副词。",
                            highlightRule: "He speaks English fluently（副词修饰 speaks）。"
                        ),
                        .init(
                            title: "介词搭配",
                            body: "介词后常接名词、代词或动名词，常见固定搭配需要整体记忆，如 depend on, good at。",
                            highlightRule: "be good at doing sth. 中 at 后通常接名词或动名词。"
                        )
                    ],
                    examplePairs: [
                        .init(
                            correctSentence: "She is good at solving problems.",
                            wrongSentence: "She is good in solve problems.",
                            explanation: "固定搭配是 good at，且介词后应用动名词 solving。"
                        ),
                        .init(
                            correctSentence: "He answered the question quickly.",
                            wrongSentence: "He answered the question quick.",
                            explanation: "修饰动词 answered 需要副词 quickly。"
                        )
                    ],
                    quizItems: [
                        .init(
                            id: "morphology-verb-adj-adv-prep-q1",
                            type: .multipleChoice,
                            prompt: "Choose the correct sentence:",
                            choices: [
                                "The soup smells deliciously.",
                                "The soup smells delicious.",
                                "The soup smell delicious."
                            ],
                            correctAnswer: "The soup smells delicious.",
                            analysis: "smell 作连系动词，后接形容词 delicious。"
                        ),
                        .init(
                            id: "morphology-verb-adj-adv-prep-q2",
                            type: .fillInBlank,
                            prompt: "I am interested ___ linguistics.",
                            choices: [],
                            correctAnswer: "in",
                            analysis: "固定搭配 interested in。"
                        )
                    ],
                    order: 2
                )
            ]
        ),
        GrammarTopic(
            id: "sentence-structure",
            title: "句子结构",
            subtitle: "句子成分、五大句型与句子类型",
            summary: "先抓主干再看修饰，建立阅读和写作的骨架意识。",
            order: 2,
            lessons: [
                GrammarLesson(
                    id: "sentence-elements-patterns",
                    topicID: "sentence-structure",
                    title: "句子成分与五种基本句型",
                    goal: "能够识别 SV/SVO/SVC/SVOO/SVOC，并区分双宾语与宾补结构。",
                    level: .foundation,
                    explanationSections: [
                        .init(
                            title: "句子核心成分",
                            body: "主语+谓语是最小主干，宾语、表语、定语、状语、补语在主干上扩展信息。",
                            highlightRule: "先找谓语动词，再找主语，能快速定位主句。"
                        ),
                        .init(
                            title: "五种句型",
                            body: "SV 表动作发生；SVO 表动作作用对象；SVC 表状态；SVOO 表给予关系；SVOC 表对宾语补充说明。",
                            highlightRule: "SVOO 的后两项是两个宾语，SVOC 的最后一项是宾语补足语。"
                        )
                    ],
                    examplePairs: [
                        .init(
                            correctSentence: "She taught us English.",
                            wrongSentence: "She taught us happily English.",
                            explanation: "teach 常构成 SVOO（us 为间接宾语，English 为直接宾语），状语不应打断核心双宾结构。"
                        ),
                        .init(
                            correctSentence: "We found the room empty.",
                            wrongSentence: "We found the room.",
                            explanation: "此处 empty 是宾补，句型为 SVOC，表达“发现房间处于空的状态”。"
                        )
                    ],
                    quizItems: [
                        .init(
                            id: "sentence-elements-patterns-q1",
                            type: .multipleChoice,
                            prompt: "Which sentence is SVOC?",
                            choices: [
                                "Birds fly.",
                                "He gave me a gift.",
                                "They made him captain."
                            ],
                            correctAnswer: "They made him captain.",
                            analysis: "him 是宾语，captain 是宾补，补充说明 him 的身份。"
                        ),
                        .init(
                            id: "sentence-elements-patterns-q2",
                            type: .fillInBlank,
                            prompt: "He is tired. 这个句型是 S__C（填一个字母）",
                            choices: [],
                            correctAnswer: "V",
                            analysis: "is 为连系动词，因此是 SVC。"
                        )
                    ],
                    order: 1
                ),
                GrammarLesson(
                    id: "sentence-types-logic",
                    topicID: "sentence-structure",
                    title: "句子类型与逻辑连接",
                    goal: "掌握陈述/疑问/祈使/感叹与简单句/并列句/复合句的区别。",
                    level: .intermediate,
                    explanationSections: [
                        .init(
                            title: "按用途分类",
                            body: "陈述句用于说明信息；疑问句用于提问；祈使句用于命令建议；感叹句用于表达情绪。",
                            highlightRule: "感叹句常见 what/how 引导：What a nice day!"
                        ),
                        .init(
                            title: "按结构分类",
                            body: "简单句只有一个主谓；并列句由并列连词连接；复合句包含主句和从句。",
                            highlightRule: "识别 but/and/so 与 because/if/although 的差异，可快速判断句间逻辑。"
                        )
                    ],
                    examplePairs: [
                        .init(
                            correctSentence: "He was tired, but he kept working.",
                            wrongSentence: "He was tired, because he kept working.",
                            explanation: "语义是转折而非因果，应使用 but。"
                        ),
                        .init(
                            correctSentence: "Open the door, please.",
                            wrongSentence: "You open the door?",
                            explanation: "祈使句通常直接用动词原形开头。"
                        )
                    ],
                    quizItems: [
                        .init(
                            id: "sentence-types-logic-q1",
                            type: .multipleChoice,
                            prompt: "I called him, and he said that he would come. 该句属于：",
                            choices: ["简单句", "并列复合句", "祈使句"],
                            correctAnswer: "并列复合句",
                            analysis: "前后两个并列分句，后句中又含宾语从句。"
                        ),
                        .init(
                            id: "sentence-types-logic-q2",
                            type: .fillInBlank,
                            prompt: "___ a nice day!（填 what 或 because）",
                            choices: [],
                            correctAnswer: "what",
                            analysis: "感叹句常用 What a/an + 名词短语。"
                        )
                    ],
                    order: 2
                )
            ]
        ),
        GrammarTopic(
            id: "tense-voice-modal",
            title: "时态语态与情态",
            subtitle: "时间表达、被动结构与语气判断",
            summary: "从常用时态到被动语态，再到情态推测与义务表达。",
            order: 3,
            lessons: [
                GrammarLesson(
                    id: "tense-system-core",
                    topicID: "tense-voice-modal",
                    title: "高频时态主线",
                    goal: "区分一般、进行、完成三大状态在现在/过去/将来的核心用法。",
                    level: .intermediate,
                    explanationSections: [
                        .init(
                            title: "时间+状态",
                            body: "时态可理解为“时间（现在/过去/将来）+状态（一般/进行/完成）”。考试中先看时间标志词，再看动词形式。",
                            highlightRule: "by + 将来时间常触发将来完成时：will have done。"
                        ),
                        .init(
                            title: "常见对比",
                            body: "一般过去强调“发生并结束”；现在完成强调“过去到现在的关联”；现在完成进行强调“持续过程”。",
                            highlightRule: "for/since 常与完成时搭配。"
                        )
                    ],
                    examplePairs: [
                        .init(
                            correctSentence: "By next Friday, we will have finished the project.",
                            wrongSentence: "By next Friday, we finish the project.",
                            explanation: "by + 将来时间点前完成动作，常用将来完成时。"
                        ),
                        .init(
                            correctSentence: "She has been learning English for three years.",
                            wrongSentence: "She is learning English for three years.",
                            explanation: "强调持续到现在的过程，应使用现在完成进行时。"
                        )
                    ],
                    quizItems: [
                        .init(
                            id: "tense-system-core-q1",
                            type: .multipleChoice,
                            prompt: "He said he ___ call me that night.",
                            choices: ["will", "would", "has"],
                            correctAnswer: "would",
                            analysis: "过去视角中的将来，使用过去将来时 would do。"
                        ),
                        .init(
                            id: "tense-system-core-q2",
                            type: .fillInBlank,
                            prompt: "They ___ (study) now.（填完整形式）",
                            choices: [],
                            correctAnswer: "are studying",
                            analysis: "now 表示正在进行，主语复数对应 are studying。"
                        )
                    ],
                    order: 1
                ),
                GrammarLesson(
                    id: "voice-modal-core",
                    topicID: "tense-voice-modal",
                    title: "语态与情态动词",
                    goal: "理解主动/被动转换，并掌握 can/must/should/may 的核心语义。",
                    level: .intermediate,
                    explanationSections: [
                        .init(
                            title: "被动语态",
                            body: "当动作承受者更重要，或执行者未知时，使用 be + 过去分词。科技文体和说明文中非常高频。",
                            highlightRule: "被动结构可跨时态：is spoken / was built / will be finished。"
                        ),
                        .init(
                            title: "情态语义",
                            body: "can/could 表能力或请求；must 表义务或强推测；should 表建议；may/might 表较弱可能性。",
                            highlightRule: "must have done 表对过去事实的强推测。"
                        )
                    ],
                    examplePairs: [
                        .init(
                            correctSentence: "English is spoken in many countries.",
                            wrongSentence: "English speaks in many countries.",
                            explanation: "英语是“被说”，应使用被动语态 is spoken。"
                        ),
                        .init(
                            correctSentence: "You must wear a seat belt.",
                            wrongSentence: "You must to wear a seat belt.",
                            explanation: "情态动词后接动词原形，不加 to。"
                        )
                    ],
                    quizItems: [
                        .init(
                            id: "voice-modal-core-q1",
                            type: .multipleChoice,
                            prompt: "Which one shows passive voice?",
                            choices: [
                                "The team solved the problem.",
                                "The problem was solved yesterday.",
                                "The team is solving the problem."
                            ],
                            correctAnswer: "The problem was solved yesterday.",
                            analysis: "was solved = be + 过去分词，被动语态。"
                        ),
                        .init(
                            id: "voice-modal-core-q2",
                            type: .fillInBlank,
                            prompt: "He may ___ the bus.",
                            choices: [],
                            correctAnswer: "miss",
                            analysis: "情态动词 may 后接动词原形。"
                        )
                    ],
                    order: 2
                )
            ]
        ),
        GrammarTopic(
            id: "nonfinite-agreement",
            title: "非谓语与主谓一致",
            subtitle: "to do / doing / done 与一致性规则",
            summary: "解决非谓语混淆、三单遗漏和就近一致等高频错误。",
            order: 4,
            lessons: [
                GrammarLesson(
                    id: "nonfinite-core",
                    topicID: "nonfinite-agreement",
                    title: "非谓语动词核心对比",
                    goal: "掌握不定式、动名词、分词的语法功能及常见易混搭配。",
                    level: .intermediate,
                    explanationSections: [
                        .init(
                            title: "四类非谓语",
                            body: "to do 常表目的/将来；doing 可作动名词或现在分词；done 常表示被动或完成。",
                            highlightRule: "先判成分功能，再判时间和语态。"
                        ),
                        .init(
                            title: "高频易混",
                            body: "remember to do（记得去做）vs remember doing（记得做过）；stop to do（停下来去做）vs stop doing（停止做）。",
                            highlightRule: "意义变化源于后接形式不同，不只是“语法形式变化”。"
                        )
                    ],
                    examplePairs: [
                        .init(
                            correctSentence: "To finish the task on time is important.",
                            wrongSentence: "Finish the task on time is important.",
                            explanation: "句首作主语可用不定式短语。"
                        ),
                        .init(
                            correctSentence: "Encouraged by his teacher, he tried again.",
                            wrongSentence: "Encouraging by his teacher, he tried again.",
                            explanation: "被动含义应用过去分词 encouraged。"
                        )
                    ],
                    quizItems: [
                        .init(
                            id: "nonfinite-core-q1",
                            type: .multipleChoice,
                            prompt: "I remember ___ the movie before.",
                            choices: ["to watch", "watching", "watch"],
                            correctAnswer: "watching",
                            analysis: "remember doing 表“记得做过”。"
                        ),
                        .init(
                            id: "nonfinite-core-q2",
                            type: .fillInBlank,
                            prompt: "She stopped ___ (buy) some water.",
                            choices: [],
                            correctAnswer: "to buy",
                            analysis: "stop to do 表“停下当前动作去做另一件事”。"
                        )
                    ],
                    order: 1
                ),
                GrammarLesson(
                    id: "subject-verb-agreement",
                    topicID: "nonfinite-agreement",
                    title: "主谓一致与就近原则",
                    goal: "避免三单、并列主语和 either/neither 结构中的一致性错误。",
                    level: .foundation,
                    explanationSections: [
                        .init(
                            title: "一致总规则",
                            body: "单数主语配单数谓语，复数主语配复数谓语；时间/距离/金额作整体概念时常用单数。",
                            highlightRule: "Every/Each/Everyone/Somebody 等主语通常接单数谓语。"
                        ),
                        .init(
                            title: "就近一致",
                            body: "在 either...or..., neither...nor..., not only...but also... 里，谓语常和靠近它的主语一致。",
                            highlightRule: "Either my mother or my father is at home."
                        )
                    ],
                    examplePairs: [
                        .init(
                            correctSentence: "Tom and Jerry are good friends.",
                            wrongSentence: "Tom and Jerry is good friends.",
                            explanation: "and 连接并列主语通常视为复数。"
                        ),
                        .init(
                            correctSentence: "Neither Tom nor Jack was late.",
                            wrongSentence: "Neither Tom nor Jack were late.",
                            explanation: "就近一致，靠近谓语的是 Jack（单数），用 was。"
                        )
                    ],
                    quizItems: [
                        .init(
                            id: "subject-verb-agreement-q1",
                            type: .multipleChoice,
                            prompt: "Either my friends or my brother ___ coming.",
                            choices: ["is", "are", "be"],
                            correctAnswer: "is",
                            analysis: "就近主语 brother 为单数，用 is。"
                        ),
                        .init(
                            id: "subject-verb-agreement-q2",
                            type: .fillInBlank,
                            prompt: "Every student ___ a notebook.",
                            choices: [],
                            correctAnswer: "has",
                            analysis: "Every student 视为单数，谓语用 has。"
                        )
                    ],
                    order: 2
                )
            ]
        ),
        GrammarTopic(
            id: "clauses-advanced-patterns",
            title: "从句与高频结构",
            subtitle: "名词性从句、定语从句、状语从句与考试句型",
            summary: "结合长难句拆解策略，提升阅读分析与写作句式能力。",
            order: 5,
            lessons: [
                GrammarLesson(
                    id: "clauses-core",
                    topicID: "clauses-advanced-patterns",
                    title: "三大从句系统",
                    goal: "区分名词性从句、定语从句、状语从句并识别常见引导词。",
                    level: .intermediate,
                    explanationSections: [
                        .init(
                            title: "名词性从句",
                            body: "在句中作主语、宾语、表语、同位语，常由 that/whether/if/wh-词引导。",
                            highlightRule: "What he said is true. 中 What he said 整体作主语。"
                        ),
                        .init(
                            title: "定语与状语从句",
                            body: "定语从句修饰名词；状语从句表达时间、原因、条件、让步等逻辑关系。",
                            highlightRule: "先行词是人常用 who，物常用 which/that。"
                        )
                    ],
                    examplePairs: [
                        .init(
                            correctSentence: "The man who came yesterday is my teacher.",
                            wrongSentence: "The man which came yesterday is my teacher.",
                            explanation: "先行词是人，通常用 who。"
                        ),
                        .init(
                            correctSentence: "If it rains tomorrow, we will stay inside.",
                            wrongSentence: "If it will rain tomorrow, we will stay inside.",
                            explanation: "条件状语从句中常用一般现在时代替一般将来时。"
                        )
                    ],
                    quizItems: [
                        .init(
                            id: "clauses-core-q1",
                            type: .multipleChoice,
                            prompt: "Choose the correct relative word: The book ___ I bought is useful.",
                            choices: ["who", "that", "when"],
                            correctAnswer: "that",
                            analysis: "先行词是物，且从句缺宾语，可用 that。"
                        ),
                        .init(
                            id: "clauses-core-q2",
                            type: .fillInBlank,
                            prompt: "___ he said is true.",
                            choices: [],
                            correctAnswer: "What",
                            analysis: "What 引导主语从句并在从句中作 said 的宾语。"
                        )
                    ],
                    order: 1
                ),
                GrammarLesson(
                    id: "advanced-patterns-reading",
                    topicID: "clauses-advanced-patterns",
                    title: "高频特殊结构与长难句抓手",
                    goal: "掌握 not only...but also..., no sooner...than..., the+比较级... 等高频结构。",
                    level: .advanced,
                    explanationSections: [
                        .init(
                            title: "高频结构",
                            body: "not only...but also...、either...or...、too...to...、so...that...、such...that... 常用于逻辑组织与强调。",
                            highlightRule: "Not only 置于句首时常触发部分倒装。"
                        ),
                        .init(
                            title: "长难句拆解顺序",
                            body: "先主干后修饰：先找谓语与主语，再划出从句，再处理非谓语和介词短语。",
                            highlightRule: "先主句，后从句；先骨架，后细节。"
                        )
                    ],
                    examplePairs: [
                        .init(
                            correctSentence: "No sooner had I sat down than the phone rang.",
                            wrongSentence: "No sooner I had sat down than the phone rang.",
                            explanation: "no sooner...than... 置句首时需倒装：助动词在主语前。"
                        ),
                        .init(
                            correctSentence: "The more you read, the faster you improve.",
                            wrongSentence: "The more you read, you improve faster and faster.",
                            explanation: "该比较结构建议成对使用 the + 比较级..., the + 比较级...。"
                        )
                    ],
                    quizItems: [
                        .init(
                            id: "advanced-patterns-reading-q1",
                            type: .multipleChoice,
                            prompt: "Which sentence is correct?",
                            choices: [
                                "Not only he apologized, but he also fixed the problem.",
                                "Not only did he apologize, but he also fixed the problem.",
                                "He not only apologized, but also he fixed the problem did."
                            ],
                            correctAnswer: "Not only did he apologize, but he also fixed the problem.",
                            analysis: "Not only 前置时，前半句需要助动词 did 倒装。"
                        ),
                        .init(
                            id: "advanced-patterns-reading-q2",
                            type: .fillInBlank,
                            prompt: "The earlier you start, the ___ results you will get.",
                            choices: [],
                            correctAnswer: "better",
                            analysis: "固定比较结构：the + 比较级..., the + 比较级...。"
                        )
                    ],
                    order: 2
                )
            ]
        )
    ]
}
