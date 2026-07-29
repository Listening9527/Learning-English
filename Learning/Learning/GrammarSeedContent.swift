import Foundation

enum GrammarSeedContent {
    static let topics: [GrammarTopic] = [
        GrammarTopic(
            id: "tenses",
            title: "时态与语态",
            subtitle: "先掌握英语句子的时间表达",
            summary: "覆盖一般时、进行时和完成时的首批课时。",
            order: 1,
            lessons: [
                GrammarLesson(
                    id: "tenses-present-simple",
                    topicID: "tenses",
                    title: "一般现在时",
                    goal: "理解一般现在时的基本用法。",
                    explanationSections: [
                        .init(
                            title: "规则",
                            body: "一般现在时用于描述习惯、事实和普遍规律。",
                            highlightRule: "主语为第三人称单数时，动词通常加 s 或 es。"
                        )
                    ],
                    examplePairs: [
                        .init(
                            correctSentence: "She goes to school by bus.",
                            wrongSentence: "She go to school by bus.",
                            explanation: "第三人称单数作主语时，谓语动词需要加 s。"
                        )
                    ],
                    quizItems: [
                        .init(
                            id: "tenses-present-simple-q1",
                            type: .multipleChoice,
                            prompt: "He ___ to work every day.",
                            choices: ["go", "goes", "going"],
                            correctAnswer: "goes",
                            analysis: "第三人称单数 he 对应 goes。"
                        )
                    ],
                    order: 1
                )
            ]
        ),
        GrammarTopic(
            id: "relative-clauses",
            title: "定语从句",
            subtitle: "先掌握关系词与句子修饰结构",
            summary: "覆盖 who、which、that 的首批课时。",
            order: 2,
            lessons: [
                GrammarLesson(
                    id: "relative-clauses-basic",
                    topicID: "relative-clauses",
                    title: "关系代词基础",
                    goal: "理解 who、which、that 的基本作用。",
                    explanationSections: [
                        .init(
                            title: "规则",
                            body: "关系代词连接先行词与从句，并在从句中充当成分。",
                            highlightRule: "人通常用 who，物通常用 which，that 可在部分场景中通用。"
                        )
                    ],
                    examplePairs: [
                        .init(
                            correctSentence: "The boy who is running is my brother.",
                            wrongSentence: "The boy which is running is my brother.",
                            explanation: "先行词是人时，通常使用 who。"
                        )
                    ],
                    quizItems: [
                        .init(
                            id: "relative-clauses-basic-q1",
                            type: .fillInBlank,
                            prompt: "The book ___ is on the desk is mine.",
                            choices: [],
                            correctAnswer: "that",
                            analysis: "先行词是物，此处可用 that。"
                        )
                    ],
                    order: 1
                )
            ]
        )
    ]
}
