# Task 2 Brief

Task: Extract StudyPage from the current ContentView.

Files:
- Modify: learning/Learning/Learning/ContentView.swift
- Create: learning/Learning/Learning/StudyPage.swift
- Modify: learning/Learning/Learning/PronunciationScorer.swift only if needed for access control or compatibility
- Create: learning/Learning/LearningTests/StudySessionStoreTests.swift

Consumes:
- PronunciationScorer
- AccentOption
- current dictionary lookup behavior
- the current practice state now living in ContentView

Produces:
- struct StudyPage: View
- struct LegacyStudyContent: View if a transitional wrapper is needed
- struct ContentView: View that forwards to StudyPage during the migration
- extension StudyPage { static func makeForTesting(scorer: PronunciationScorer) -> StudyPage }

Required failing test:
```swift
import XCTest
@testable import Learning

final class StudySessionStoreTests: XCTestCase {
    func test_studyPage_preserves_injected_scorer_instance() {
        let scorer = PronunciationScorer()
        let view = StudyPage.makeForTesting(scorer: scorer)

        XCTAssertEqual(ObjectIdentifier(view.scorer), ObjectIdentifier(scorer))
    }
}
```

Required fail command:
cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'platform=iOS Simulator,OS=18.5,name=iPhone 16' -only-testing:LearningTests/StudySessionStoreTests/test_studyPage_preserves_injected_scorer_instance

Expected fail reason:
- StudyPage does not exist yet.

Required minimal implementation:
```swift
import SwiftUI

struct StudyPage: View {
    @ObservedObject var scorer: PronunciationScorer

    static func makeForTesting(scorer: PronunciationScorer) -> StudyPage {
        StudyPage(scorer: scorer)
    }

    var body: some View {
        LegacyStudyContent(scorer: scorer)
    }
}
```

```swift
import SwiftUI

struct ContentView: View {
    @StateObject private var scorer = PronunciationScorer()

    var body: some View {
        StudyPage(scorer: scorer)
    }
}
```

Implementation note:
- Move the current ContentView state, helper methods, and nested types into LegacyStudyContent inside StudyPage.swift, preserving behavior before any visual redesign.
- Keep current behavior intact. This is an extraction, not a redesign.
- Home tab currently renders ContentView from MainPage as the transitional shell. After this task, that path must keep working and reach the extracted StudyPage flow.
- Preserve existing local user changes in ContentView, including the dictionary pronunciation comment.

Required pass command:
cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'platform=iOS Simulator,OS=18.5,name=iPhone 16' -only-testing:LearningTests/StudySessionStoreTests/test_studyPage_preserves_injected_scorer_instance

Constraints:
- Do not modify MainPage.swift in this task unless a minimal compile fix is strictly required by the extraction.
- Do not rewrite logic; move it into StudyPage.swift / LegacyStudyContent with minimal surface changes.
- Keep the solution focused on Task 2 only.
- Use TDD: write the failing test first, observe failure, then implement minimal code, then rerun the same focused test.
