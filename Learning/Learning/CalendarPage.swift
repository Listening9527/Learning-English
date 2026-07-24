import SwiftUI

struct CalendarPage: View {
    @ObservedObject var dashboardStore: DashboardStore

    @State private var displayedMonth = calendarUTC.startOfDay(for: Date())
    @State private var selectedBackfillDate = calendarUTC.startOfDay(for: Date())
    @State private var dailySummaries: [DailyCompletionSummary] = []
    @State private var isShowingBackfillSheet = false
    @State private var errorMessage: String?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    monthSummaryGrid
                }
                .padding()
            }
            .navigationTitle("日历")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("补录") {
                        selectedBackfillDate = calendarUTC.startOfDay(for: displayedMonth)
                        isShowingBackfillSheet = true
                    }
                }
            }
            .task(id: monthAnchorID) {
                await loadMonthlySummary()
            }
            .sheet(isPresented: $isShowingBackfillSheet) {
                NavigationStack {
                    VStack(spacing: 20) {
                        DatePicker(
                            "选择补录日期",
                            selection: $selectedBackfillDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)

                        Button("确认补录") {
                            Task {
                                await confirmBackfill()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .navigationTitle("补录练习")
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("取消") {
                                isShowingBackfillSheet = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
            .alert("操作失败", isPresented: errorAlertBinding) {
                Button("知道了", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(monthTitle)
                .font(.title2.weight(.semibold))
            Text("本月已完成 \(completedDateKeys.count) 天练习")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var monthSummaryGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(calendarCells.indices, id: \.self) { index in
                let cell = calendarCells[index]

                Group {
                    if let day = cell {
                        VStack(spacing: 6) {
                            Text(dayLabel(for: day))
                                .font(.headline)
                            Circle()
                                .fill(completedDateKeys.contains(dateKey(for: day)) ? Color.green : Color.gray.opacity(0.25))
                                .frame(width: 10, height: 10)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Color.clear
                            .frame(height: 58)
                    }
                }
            }
        }
    }

    private var completedDateKeys: Set<String> {
        Set(dailySummaries.filter(\.practiced).map(\.dateKey))
    }

    private var monthAnchorID: String {
        dateKey(for: displayedMonth)
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.calendar = calendarUTC
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = calendarUTC.timeZone
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: displayedMonth)
    }

    private var calendarCells: [Date?] {
        let monthDays = daysInMonth(for: displayedMonth)
        guard let firstDay = monthDays.first else {
            return []
        }

        let weekday = calendarUTC.component(.weekday, from: firstDay)
        let leadingEmptyCells = max(0, weekday - calendarUTC.firstWeekday)
        return Array(repeating: nil, count: leadingEmptyCells) + monthDays.map { Optional($0) }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
    }

    private func loadMonthlySummary() async {
        do {
            dailySummaries = try DatabaseManager.shared.fetchMonthlyCompletionSummary(for: displayedMonth)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func confirmBackfill() async {
        do {
            displayedMonth = selectedBackfillDate
            try DatabaseManager.shared.backfillPractice(on: selectedBackfillDate)
            dailySummaries = try DatabaseManager.shared.fetchMonthlyCompletionSummary(for: displayedMonth)
            await dashboardStore.refresh()
            isShowingBackfillSheet = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func daysInMonth(for date: Date) -> [Date] {
        let components = calendarUTC.dateComponents([.year, .month], from: date)
        guard
            let monthStart = calendarUTC.date(from: components),
            let dayRange = calendarUTC.range(of: .day, in: .month, for: monthStart)
        else {
            return []
        }

        return dayRange.compactMap { day in
            calendarUTC.date(byAdding: .day, value: day - 1, to: monthStart)
        }
    }

    private func dayLabel(for date: Date) -> String {
        String(calendarUTC.component(.day, from: date))
    }

    private func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendarUTC
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendarUTC.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

private let calendarUTC: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .current
    return calendar
}()