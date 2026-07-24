Status: DONE

Files changed:
- /Users/lisl/workspace/learning/Learning/Learning/DatabaseManager.swift
- /Users/lisl/workspace/learning/Learning/Learning/DashboardStore.swift
- /Users/lisl/workspace/learning/Learning/Learning/PageModels.swift
- /Users/lisl/workspace/learning/Learning/LearningTests/DatabaseManagerPageQueryTests.swift

Exact test command(s) run:
- cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'platform=iOS Simulator,OS=18.5,name=iPhone 16' -only-testing:LearningTests/DatabaseManagerPageQueryTests/test_recentWordsQuery_returns_latest_words_first
- cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'platform=iOS Simulator,OS=18.5,name=iPhone 16' -only-testing:LearningTests/DatabaseManagerPageQueryTests/test_recentWordsQuery_returns_latest_words_first
- cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'platform=iOS Simulator,OS=18.5,name=iPhone 16' -only-testing:LearningTests/DatabaseManagerPageQueryTests/test_recentWordsQuery_returns_latest_words_first
- cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'platform=iOS Simulator,OS=18.5,name=iPhone 16' -only-testing:LearningTests/DatabaseManagerPageQueryTests/test_recentWordsQuery_returns_latest_words_first

Result of the failing test run:
- Initial sandboxed run was blocked from accessing CoreSimulator and could not resolve the requested simulator destination.
- The first successful unsandboxed red-phase run failed during compilation exactly because the new APIs/models did not exist yet:
  - DatabaseManager had no member insertWordForTesting
  - DatabaseManager had no member fetchRecentWordSummaries
  - the test could not infer \.word because the return model was missing

Result of the passing test run:
- Test Suite 'DatabaseManagerPageQueryTests' passed.
- Test Case '-[LearningTests.DatabaseManagerPageQueryTests test_recentWordsQuery_returns_latest_words_first]' passed (0.014 seconds).
- Executed 1 test, with 0 failures (0 unexpected) in 0.014 seconds.
- ** TEST SUCCEEDED **

Any concerns:
- xcodebuild test for this iOS simulator target required unsandboxed execution because CoreSimulator and Xcode DerivedData are outside the workspace sandbox.

