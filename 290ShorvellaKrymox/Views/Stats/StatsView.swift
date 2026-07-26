import SwiftUI

struct StatsView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var showAdd = false
    @State private var selectedDay: Date?

    var body: some View {
        NavigationStack {
            Group {
                if store.moodEntries.isEmpty && store.relaxationEntries.isEmpty && store.stats.sessionsCompleted == 0 {
                    EmptyStateView(
                        symbol: "chart.bar.fill",
                        title: "Your stats will appear here",
                        message: "Log a mood or relaxation session to unlock charts and trends.",
                        actionTitle: "Add Relaxation"
                    ) {
                        showAdd = true
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            summaryCard
                            reflectionCard
                            moodDistributionCard
                            weeklyMinutesCard
                            moodTrendCard
                            heatmapCard
                            streakCard
                            recentEntriesCard
                        }
                        .padding(16)
                        .padding(.bottom, 80)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                AccentButtonImage(title: "Add Entry") {
                    showAdd = true
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(ThemeColor.surface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .screenBackground()
            .sheet(isPresented: $showAdd) {
                AddRelaxationSheet()
                    .environmentObject(store)
            }
        }
    }

    private var summaryCard: some View {
        SoftCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Overview")
                    .font(.headline)
                    .foregroundStyle(ThemeColor.textPrimary)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    summaryCell(title: "Mood logs", value: "\(store.moodEntries.count)", icon: "face.smiling")
                    summaryCell(title: "Sessions", value: "\(store.stats.sessionsCompleted)", icon: "wind")
                    summaryCell(title: "Minutes", value: "\(store.stats.totalMinutesPracticed)", icon: "clock.fill")
                    summaryCell(title: "Streak", value: "\(store.stats.streakDays)d", icon: "flame.fill")
                }
            }
        }
    }

    private var reflectionCard: some View {
        SoftCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Weekly Reflection")
                    .font(.headline)
                    .foregroundStyle(ThemeColor.textPrimary)
                Text(store.weeklyReflectionSummary())
                    .font(.subheadline)
                    .foregroundStyle(ThemeColor.textSecondary)
                    .lineLimit(5)
                Button {
                    HapticService.light()
                    store.showWeeklyReflection = true
                } label: {
                    Text("Read full reflection")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(ThemeColor.primary)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var moodDistributionCard: some View {
        SoftCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Mood Mix")
                    .font(.headline)
                    .foregroundStyle(ThemeColor.textPrimary)
                if moodCounts.isEmpty {
                    Text("Log moods to see your distribution.")
                        .font(.subheadline)
                        .foregroundStyle(ThemeColor.textSecondary)
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)
                } else {
                    MoodDonutChart(counts: moodCounts)
                        .frame(height: 180)
                    VStack(spacing: 8) {
                        ForEach(moodCounts.prefix(5), id: \.emoji) { item in
                            HStack(spacing: 10) {
                                Text(item.emoji)
                                Text(item.label)
                                    .font(.subheadline)
                                    .foregroundStyle(ThemeColor.textPrimary)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(item.count)")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(ThemeColor.accent)
                                Text(percent(item.count))
                                    .font(.caption)
                                    .foregroundStyle(ThemeColor.textSecondary)
                                    .frame(width: 40, alignment: .trailing)
                            }
                        }
                    }
                }
            }
        }
    }

    private var weeklyMinutesCard: some View {
        SoftCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Weekly Minutes")
                        .font(.headline)
                        .foregroundStyle(ThemeColor.textPrimary)
                    Spacer()
                    Text("\(store.weeklySummary.reduce(0, +)) min")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ThemeColor.accent)
                }
                WeeklyBarChart(values: store.weeklySummary.map(Double.init))
                    .frame(height: 150)
                HStack {
                    ForEach(weekLabels, id: \.self) { label in
                        Text(label)
                            .font(.caption2)
                            .foregroundStyle(ThemeColor.textSecondary)
                            .frame(maxWidth: .infinity)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                }
            }
        }
    }

    private var moodTrendCard: some View {
        SoftCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Mood Activity (14 days)")
                    .font(.headline)
                    .foregroundStyle(ThemeColor.textPrimary)
                if moodTrend.allSatisfy({ $0 == 0 }) {
                    Text("No mood activity in the last two weeks.")
                        .font(.subheadline)
                        .foregroundStyle(ThemeColor.textSecondary)
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)
                } else {
                    MoodLineChart(values: moodTrend)
                        .frame(height: 140)
                }
            }
        }
    }

    private var heatmapCard: some View {
        SoftCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Activity Heatmap")
                    .font(.headline)
                    .foregroundStyle(ThemeColor.textPrimary)
                HeatmapCanvas(activity: store.relaxationHeatmap, selectedDay: $selectedDay)
                    .frame(height: 160)
                if let selectedDay {
                    let count = store.relaxationHeatmap[Calendar.current.startOfDay(for: selectedDay), default: 0]
                    Text("\(dayLabel(selectedDay)) · \(count) activit\(count == 1 ? "y" : "ies")")
                        .font(.caption)
                        .foregroundStyle(ThemeColor.textSecondary)
                }
            }
        }
    }

    private var streakCard: some View {
        SoftCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Consistency")
                    .font(.headline)
                    .foregroundStyle(ThemeColor.textPrimary)
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current streak")
                            .font(.caption)
                            .foregroundStyle(ThemeColor.textSecondary)
                        Text("\(store.stats.streakDays) days")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(ThemeColor.primary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Best streak")
                            .font(.caption)
                            .foregroundStyle(ThemeColor.textSecondary)
                        Text("\(store.stats.longestStreak) days")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(ThemeColor.accent)
                    }
                }
                ProgressView(
                    value: Double(min(store.stats.streakDays, max(store.stats.longestStreak, 1))),
                    total: Double(max(store.stats.longestStreak, 1))
                )
                .tint(ThemeColor.primary)
            }
        }
    }

    private var recentEntriesCard: some View {
        SoftCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Sessions")
                    .font(.headline)
                    .foregroundStyle(ThemeColor.textPrimary)
                if store.relaxationEntries.isEmpty {
                    Text("No relaxation entries yet.")
                        .font(.subheadline)
                        .foregroundStyle(ThemeColor.textSecondary)
                } else {
                    ForEach(store.relaxationEntries.prefix(6)) { entry in
                        HStack {
                            Image(systemName: "hourglass")
                                .foregroundStyle(ThemeColor.primary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(entry.duration) min")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(ThemeColor.textPrimary)
                                Text(dayLabel(entry.date))
                                    .font(.caption)
                                    .foregroundStyle(ThemeColor.textSecondary)
                            }
                            Spacer()
                            if !entry.note.isEmpty {
                                Text(entry.note)
                                    .font(.caption)
                                    .foregroundStyle(ThemeColor.textSecondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            Button {
                                store.deleteRelaxation(entry)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(Color.red.opacity(0.85))
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)
                        }
                        if entry.id != store.relaxationEntries.prefix(6).last?.id {
                            Divider().background(ThemeColor.textSecondary.opacity(0.2))
                        }
                    }
                }
            }
        }
    }

    private func summaryCell(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(ThemeColor.primary)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .foregroundStyle(ThemeColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(ThemeColor.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(ThemeColor.background.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var moodCounts: [(emoji: String, label: String, count: Int)] {
        var map: [String: Int] = [:]
        for entry in store.moodEntries {
            map[entry.mood, default: 0] += 1
        }
        return map
            .map { emoji, count in
                let label = MoodEmoji(rawValue: emoji)?.label ?? "Other"
                return (emoji, label, count)
            }
            .sorted { $0.count > $1.count }
    }

    private var moodTrend: [Double] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<14).map { offset in
            guard let day = cal.date(byAdding: .day, value: offset - 13, to: today) else { return 0 }
            return Double(store.moods(on: day).count)
        }
    }

    private var weekLabels: [String] {
        let cal = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE"
        let today = cal.startOfDay(for: Date())
        return (0..<7).compactMap { offset in
            guard let day = cal.date(byAdding: .day, value: offset - 6, to: today) else { return nil }
            return formatter.string(from: day)
        }
    }

    private func percent(_ count: Int) -> String {
        let total = max(store.moodEntries.count, 1)
        return "\(Int((Double(count) / Double(total) * 100).rounded()))%"
    }

    private func dayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct MoodDonutChart: View {
    let counts: [(emoji: String, label: String, count: Int)]

    private var total: Double {
        Double(max(counts.reduce(0) { $0 + $1.count }, 1))
    }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                    Circle()
                        .trim(from: segment.start, to: segment.end)
                        .stroke(
                            ThemeColor.primary.opacity(0.35 + Double(index) * 0.12),
                            style: StrokeStyle(lineWidth: size * 0.16, lineCap: .butt)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: size * 0.78, height: size * 0.78)
                }
                VStack(spacing: 2) {
                    Text("\(counts.reduce(0) { $0 + $1.count })")
                        .font(.title.weight(.bold))
                        .foregroundStyle(ThemeColor.textPrimary)
                    Text("entries")
                        .font(.caption)
                        .foregroundStyle(ThemeColor.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var segments: [(start: CGFloat, end: CGFloat)] {
        var cursor: CGFloat = 0
        var result: [(CGFloat, CGFloat)] = []
        for item in counts {
            let share = CGFloat(Double(item.count) / total)
            result.append((cursor, cursor + share))
            cursor += share
        }
        return result
    }
}

struct MoodLineChart: View {
    let values: [Double]

    var body: some View {
        Canvas { context, size in
            let maxVal = max(values.max() ?? 0, 1)
            let count = max(values.count - 1, 1)
            var path = Path()
            var fill = Path()

            for (index, value) in values.enumerated() {
                let x = size.width * CGFloat(index) / CGFloat(count)
                let y = size.height - CGFloat(value / maxVal) * (size.height - 8) - 4
                let point = CGPoint(x: x, y: y)
                if index == 0 {
                    path.move(to: point)
                    fill.move(to: CGPoint(x: x, y: size.height))
                    fill.addLine(to: point)
                } else {
                    path.addLine(to: point)
                    fill.addLine(to: point)
                }
            }
            if let lastX = values.indices.last.map({ size.width * CGFloat($0) / CGFloat(count) }) {
                fill.addLine(to: CGPoint(x: lastX, y: size.height))
                fill.closeSubpath()
            }

            context.fill(fill, with: .color(ThemeColor.primary.opacity(0.18)))
            context.stroke(
                path,
                with: .color(ThemeColor.accent),
                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
            )

            for (index, value) in values.enumerated() where value > 0 {
                let x = size.width * CGFloat(index) / CGFloat(count)
                let y = size.height - CGFloat(value / maxVal) * (size.height - 8) - 4
                let dot = Path(ellipseIn: CGRect(x: x - 3.5, y: y - 3.5, width: 7, height: 7))
                context.fill(dot, with: .color(ThemeColor.primary))
            }
        }
    }
}
