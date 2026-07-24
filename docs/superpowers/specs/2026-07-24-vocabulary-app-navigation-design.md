# Vocabulary App Navigation And Page Design

## Context

The current SwiftUI app starts directly in a single practice-focused view at [learning/Learning/Learning/ContentView.swift](learning/Learning/Learning/ContentView.swift). That view already contains pronunciation practice, custom word input, score display, dictionary lookup, and a path into practice statistics.

The SQLite schema already includes the core data surfaces needed for a broader vocabulary-learning product: wordbooks, wordbook membership, user progress, daily practice records, search history, and user settings in [learning/Learning/Learning/DatabaseManager.swift](learning/Learning/Learning/DatabaseManager.swift).

This design restructures the app into a three-tab product shell while preserving the current practice logic as the foundation of a dedicated StudyPage.

## Goals

- Replace the single-page entry with a three-tab main application structure.
- Preserve existing study and pronunciation logic by moving it into a dedicated StudyPage instead of rewriting it immediately.
- Define page responsibilities clearly so each screen has one primary job.
- Keep cross-page state consistent through shared stores or view models rather than page-to-page manual synchronization.
- Reuse the existing database schema wherever possible and add page-level query interfaces later.

## Non-Goals

- Rewriting all study logic in the same step as the navigation redesign.
- Finalizing backend API contracts for every page action.
- Introducing a second navigation system alongside the new one.
- Performing unrelated schema refactors outside the data needed for these pages.

## Recommended Approach

Three structural options were considered:

- Gradual shell migration: add a new main container with three tabs, move the current practice surface into StudyPage, and add the remaining product pages around it.
- Full page rewrite: rebuild all pages and state boundaries at once.
- Minimal enhancement: keep the current single-page entry and bolt on secondary pages.

The recommended approach is gradual shell migration. It matches the requested product structure, keeps implementation risk manageable, and reuses the existing study surface instead of discarding working logic.

## Main Navigation Design

The app root should become a MainPage implemented as a SwiftUI TabView with three tabs:

- HomePage
- CalendarPage
- ProfilePage

Each tab should host its own NavigationStack so push navigation remains isolated per tab and users can return to each tab without losing its navigation context.

The following pages should be pushed from those tab roots rather than included as bottom tabs:

- SearchPage
- WordDetailPage
- StudyPage
- WordbookPage
- WordbookDetailPage
- SettingsPage

This structure is the SwiftUI equivalent of using an IndexedStack-backed three-tab shell in Flutter. The product goal is stateful tab preservation, not framework-specific widget parity.

## Page Responsibilities

### HomePage

HomePage is the default landing page and should answer two questions quickly: what should the user do today, and where should they continue.

The page contains:

- a gradient header with greeting, lightweight progress summary, and a search entry
- a seven-day check-in grid with a fire-based completion indicator
- a summary card for consecutive days, total learning days, and today-versus-goal progress
- a single primary action button that pushes StudyPage
- a recent words list rendered as WordCard items

Search should not stay inline on HomePage. The header action should push SearchPage to keep HomePage focused on discovery and continuation.

Tapping a recent word card should push WordDetailPage.

### CalendarPage

CalendarPage is the review and backfill surface.

The page contains:

- a monthly calendar grid showing learned days, study intensity, and backfill markers
- a statistics card with total words, learning days, and consecutive days
- a backfill interaction flow for missed days

The backfill flow is:

1. user selects a missed date
2. a bottom sheet explains the action and its effect
3. a confirmation dialog asks for final confirmation
4. the write action runs against the API or persistence layer
5. the dashboard and calendar stores refresh from the source of truth

CalendarPage may offer a secondary action to continue today’s work, but it should not compete with HomePage’s main study call-to-action.

### ProfilePage

ProfilePage is the personal entry page, not a second dashboard.

The page contains:

- avatar and welcome content
- an optional compact learning badge or lightweight summary
- a primary entry to WordbookPage
- a primary entry to SettingsPage

ProfilePage should not duplicate the main calendar statistics card or the HomePage learning agenda.

### SearchPage

SearchPage uses a search field embedded in the top bar.

The page contains:

- initial search history loaded from the search history data source
- live or submit-driven result list
- a bottom-sheet form for custom word creation

Creating a custom word should update search history, the word list data source, and any recent-additions view model used by HomePage.

### WordDetailPage

WordDetailPage is the information-and-actions page for a single word.

The page contains:

- the word, phonetic spelling, and pronunciation playback
- grouped meaning cards for multiple parts of speech
- actions to add or remove the word from a wordbook
- an action to mark the word as forgotten
- an action to begin studying that word immediately

### StudyPage

StudyPage is the main learning workflow and remains the most complex page.

Its responsibilities are:

- switching among the three learning modes
- restoring and caching local study progress
- handling pronunciation or learning flow state
- submitting learning results

The current ContentView should be treated as the first extraction source for StudyPage rather than as a disposable prototype.

### WordbookPage And WordbookDetailPage

WordbookPage presents the user’s wordbook list.

WordbookDetailPage contains four filtering tabs:

- today’s tasks
- learning words
- not learned words
- easy words

These tabs are content filters inside a detail page, not part of the global app navigation.

### SettingsPage

SettingsPage should contain only settings that are immediately actionable:

- daily goal via dialog-based numeric input
- notification enabled state via switch
- notification time via time picker

Settings should save in place and avoid an additional confirmation page.

## State Design

State should be split into two categories:

- persistent business state shared across pages
- local UI state scoped to a single page

Persistent business state includes:

- streaks and aggregate study counts
- recent words
- calendar completion state
- wordbook membership state
- search history
- saved preferences

Local UI state includes:

- active search query text
- current bottom-sheet visibility
- selected calendar day
- selected study mode in the current session
- expanded meaning sections in WordDetailPage

Pages should trigger actions but should not compute or maintain business truth independently.

## Shared Store Boundaries

The page layer should be backed by focused stores or view models:

- DashboardStore for HomePage and CalendarPage aggregates
- StudySessionStore for StudyPage learning state and submission workflow
- WordbookStore for wordbook membership and filtered wordbook detail lists
- PreferencesStore for daily goal and notification settings

Stores are responsible for refreshing data after writes so other pages update from shared truth instead of relying on manual callback chains.

## Cross-Page Writeback Rules

Cross-page consistency should follow one rule: any action that changes shared truth writes once to the source of truth and then refreshes the affected store.

Examples:

- finishing a study action updates daily records and user progress, then refreshes DashboardStore
- backfilling a date updates the persistence layer, then refreshes the calendar and summary state
- adding a custom word updates the words table and search history, then refreshes recent additions and relevant lists
- adding or removing a wordbook membership updates WordbookStore, then any subscribed views reflect the change

Pages should not patch several sibling view states manually after a write.

## Data Mapping To Existing Schema

The current schema already supports most of the requested product model:

- daily_records powers calendar completion and daily summaries
- user_word_progress powers learning status segments and scheduling-related views
- search_history powers SearchPage history
- user_settings powers settings persistence
- wordbooks and wordbook_words power wordbook organization

The main missing layer is not schema. It is page-oriented queries and aggregation methods such as:

- recent seven-day completion summary
- recently added words list
- month-level calendar summary
- filtered wordbook detail queries by progress status

## Migration Strategy From The Current App

The redesign should be implemented as an extraction, not a rewrite.

Recommended migration order:

1. introduce MainPage as the new root
2. move the current practice-heavy ContentView responsibilities into StudyPage
3. keep the existing pronunciation scorer and practice state intact during the move
4. add lightweight HomePage, CalendarPage, and ProfilePage shells wired to shared stores
5. progressively replace direct state ownership in the old page with page-specific stores

This keeps working study behavior available while the broader app structure is added around it.

## Error Handling Rules

Any shared-state write should follow a consistent result pattern:

- show loading in the initiating page
- commit the write to the persistence or API layer
- refresh the owning store on success
- restore a usable page state and show a clear error on failure

Specific requirements:

- failed backfill keeps the selected date and allows retry
- failed wordbook membership changes must not leave the button in a false success state
- failed study-result submission should preserve local progress for retry or later sync

## Validation Requirements

The minimum validation scope for the eventual implementation is:

1. root navigation opens into the three-tab shell instead of the legacy single-page root
2. each tab preserves its own navigation state while push pages return correctly
3. shared summary state refreshes after study, search-add, wordbook membership, and backfill writes
4. extracting StudyPage from the current ContentView does not regress existing practice behavior

## Files Expected To Change Later

- [learning/Learning/Learning/LearningApp.swift](learning/Learning/Learning/LearningApp.swift)
- [learning/Learning/Learning/ContentView.swift](learning/Learning/Learning/ContentView.swift)
- [learning/Learning/Learning/DatabaseManager.swift](learning/Learning/Learning/DatabaseManager.swift)
- new SwiftUI page files for MainPage, HomePage, CalendarPage, ProfilePage, SearchPage, WordDetailPage, StudyPage, WordbookPage, WordbookDetailPage, and SettingsPage
- new store or view model files for dashboard, study session, wordbook, and preferences state

## Risks And Tradeoffs

- Keeping StudyPage as an extraction target reduces rewrite risk but means the first implementation phase may still carry legacy layout or state shape from the current ContentView.
- A store-based shared state model adds some structural overhead, but it avoids inconsistent cross-page updates once more pages are introduced.
- Reusing the current schema speeds delivery, but page-level query APIs will need careful design to avoid pushing aggregation logic back into the views.