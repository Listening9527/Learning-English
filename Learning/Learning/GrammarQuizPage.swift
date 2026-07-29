import SwiftUI

struct GrammarQuizPage: View {
    let lesson: GrammarLesson
    @ObservedObject var progressStore: GrammarProgressStore
    @ObservedObject var reviewStore: GrammarReviewStore

    @State private var currentIndex = 0
    @State private var selectedAnswer = ""
    @State private var didSubmit = false
    @State private var answersByQuizItemID: [String: String] = [:]

    private var currentItem: GrammarQuizItem {
        lesson.quizItems[currentIndex]
    }

    private var isLastQuestion: Bool {
        currentIndex == lesson.quizItems.count - 1
    }

    var body: some View {
        List {
            Section("题目") {
                Text(currentItem.prompt)

                if currentItem.type == .multipleChoice {
                    ForEach(currentItem.choices, id: \.self) { choice in
                        Button(choice) {
                            selectedAnswer = choice
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    TextField("请输入答案", text: $selectedAnswer)
                        .textInputAutocapitalization(.never)
                }
            }

            Section {
                Button("提交答案") {
                    answersByQuizItemID[currentItem.id] = selectedAnswer
                    didSubmit = true

                    if selectedAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() != currentItem.correctAnswer.lowercased() {
                        reviewStore.recordWrongAnswer(lessonID: lesson.id, quizItemID: currentItem.id)
                    }

                    if isLastQuestion {
                        finishQuiz()
                    }
                }
                .disabled(selectedAnswer.isEmpty)
            }

            if didSubmit {
                Section("解析") {
                    Text(currentItem.analysis)
                    if !isLastQuestion {
                        Button("下一题") {
                            currentIndex += 1
                            selectedAnswer = ""
                            didSubmit = false
                        }
                    }
                }
            }
        }
        .navigationTitle("小测")
    }

    private func finishQuiz() {
        let correctCount = lesson.quizItems.reduce(0) { partialResult, item in
            let answer = answersByQuizItemID[item.id] ?? ""
            return partialResult + (answer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == item.correctAnswer.lowercased() ? 1 : 0)
        }

        let score = Int((Double(correctCount) / Double(lesson.quizItems.count)) * 100)
        progressStore.completeQuiz(lessonID: lesson.id, score: score)
    }
}
