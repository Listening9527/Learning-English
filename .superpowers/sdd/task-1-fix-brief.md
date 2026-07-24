# Task 1 Fix Brief

Fix the Important findings from Task 1 review.

Files you may modify:
- learning/Learning/Learning/MainPage.swift
- learning/Learning/Learning.xcodeproj/project.pbxproj
- learning/.superpowers/sdd/task-1-report.md

Review findings to address:
1. MainPage switched the app root, but the existing study/pronunciation flow in ContentView became unreachable because the home tab is only placeholder text. Task 1 must preserve access to the current main study flow until Task 2 extracts StudyPage.
2. The new LearningTests target introduced inconsistent DEVELOPMENT_TEAM values between Debug and Release. Remove that inconsistency and minimize environment-specific signing noise.

Requirements for the fix:
- Keep Task 1 scope minimal.
- Do not modify ContentView.swift in this fix.
- Preserve DatabaseManager initialization in LearningApp.
- Make the current study flow reachable from the new shell immediately after launch, using a minimal transitional approach.
- Keep the existing focused test green:
  cd /Users/lisl/workspace/learning/Learning && xcodebuild test -project Learning.xcodeproj -scheme Learning -destination 'platform=iOS Simulator,OS=18.5,name=iPhone 16' -only-testing:LearningTests/NavigationShellTests/test_mainPage_defaults_to_home_tab
- Append your fix report to /Users/lisl/workspace/learning/.superpowers/sdd/task-1-report.md

Your appended fix report must include:
- Status
- Files changed in fix
- Exact test command run
- Test result
- How you restored current study-flow reachability
- How you resolved DEVELOPMENT_TEAM inconsistency
