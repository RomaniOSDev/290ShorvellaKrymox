import SwiftUI

struct RelaxationInsightsView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var showAdd = false
    @State private var selectedDay: Date?

    var body: some View {
        NavigationStack {
            Group {
                if store.relaxationEntries.isEmpty {
                    EmptyStateView(
                        symbol: "tortoise.fill",
                        title: "Tap 'Add Entry' to begin tracking your journey",
                        message: "Log relaxation minutes to fill your weekly chart and heatmap.",
                        actionTitle: "Add Entry"
                    ) {
                        showAdd = true
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            BannerImageCard(imageName: "img_banner", height: 100)
                            weeklyChartCard
                            heatmapCard
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
            .navigationTitle("Weekly Overview")
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

    private var weeklyChartCard: some View {
        SoftCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Weekly Relaxation")
                    .font(.headline)
                    .foregroundStyle(ThemeColor.textPrimary)
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

    private var recentEntriesCard: some View {
        SoftCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Sessions")
                    .font(.headline)
                    .foregroundStyle(ThemeColor.textPrimary)
                ForEach(store.relaxationEntries.prefix(8)) { entry in
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
                    if entry.id != store.relaxationEntries.prefix(8).last?.id {
                        Divider().background(ThemeColor.textSecondary.opacity(0.2))
                    }
                }
            }
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

    private func dayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct WeeklyBarChart: View {
    let values: [Double]

    var body: some View {
        Canvas { context, size in
            let maxVal = max(values.max() ?? 0, 1)
            let count = max(values.count, 1)
            let slot = size.width / CGFloat(count)
            let barWidth = slot * 0.55
            for (index, value) in values.enumerated() {
                let height = CGFloat(value / maxVal) * size.height
                let x = slot * CGFloat(index) + (slot - barWidth) / 2
                let rect = CGRect(
                    x: x,
                    y: size.height - height,
                    width: barWidth,
                    height: max(height, value > 0 ? 4 : 0)
                )
                let path = Path(roundedRect: rect, cornerRadius: 6)
                let opacity = 0.35 + min(value / maxVal, 1) * 0.65
                context.fill(path, with: .color(ThemeColor.primary.opacity(opacity)))
            }
        }
    }
}

struct HeatmapCanvas: View {
    let activity: [Date: Int]
    @Binding var selectedDay: Date?

    private var days: [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<35).compactMap { cal.date(byAdding: .day, value: $0 - 34, to: today) }
    }

    var body: some View {
        GeometryReader { geo in
            let columns = 7
            let spacing: CGFloat = 6
            let cellW = (geo.size.width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
            let cellH = (geo.size.height - spacing * 4) / 5

            Canvas { context, _ in
                for (index, day) in days.enumerated() {
                    let col = index % columns
                    let row = index / columns
                    let x = CGFloat(col) * (cellW + spacing)
                    let y = CGFloat(row) * (cellH + spacing)
                    let count = activity[day, default: 0]
                    let rect = CGRect(x: x, y: y, width: cellW, height: cellH)
                    let path = Path(roundedRect: rect, cornerRadius: 6)
                    context.fill(path, with: .color(color(for: count)))
                    let dayNum = Calendar.current.component(.day, from: day)
                    let label = Text("\(dayNum)").font(.system(size: 9, weight: .semibold))
                    context.draw(
                        label,
                        at: CGPoint(x: x + cellW / 2, y: y + cellH / 2),
                        anchor: .center
                    )
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        let col = min(max(Int(value.location.x / (cellW + spacing)), 0), columns - 1)
                        let row = min(max(Int(value.location.y / (cellH + spacing)), 0), 4)
                        let index = row * columns + col
                        guard days.indices.contains(index) else { return }
                        HapticService.light()
                        selectedDay = days[index]
                    }
            )
        }
    }

    private func color(for count: Int) -> Color {
        switch count {
        case 0: return ThemeColor.background.opacity(0.7)
        case 1: return ThemeColor.primary.opacity(0.35)
        case 2: return ThemeColor.primary.opacity(0.55)
        default: return ThemeColor.primary.opacity(0.85)
        }
    }
}

struct AddRelaxationSheet: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date()
    @State private var duration = 15
    @State private var note = ""
    @State private var shake: CGFloat = 0
    @State private var showError = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    SoftCard {
                        DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                            .tint(ThemeColor.primary)
                            .colorScheme(.dark)
                    }

                    SoftCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Duration (minutes)")
                                .font(.headline)
                                .foregroundStyle(ThemeColor.textPrimary)
                            Stepper(value: $duration, in: 1...180, step: 5) {
                                Text("\(duration) min")
                                    .foregroundStyle(ThemeColor.textPrimary)
                                    .lineLimit(1)
                            }
                            .tint(ThemeColor.primary)
                            .modifier(ShakeEffect(animatableData: shake))
                            if showError {
                                Text("Duration must be at least 1 minute.")
                                    .font(.caption)
                                    .foregroundStyle(Color.red.opacity(0.9))
                            }
                        }
                    }

                    SoftCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Note (optional)")
                                .font(.headline)
                                .foregroundStyle(ThemeColor.textPrimary)
                            TextField("What helped you relax?", text: $note, axis: .vertical)
                                .lineLimit(2...4)
                                .foregroundStyle(ThemeColor.textPrimary)
                                .padding(12)
                                .background(ThemeColor.background.opacity(0.55))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }

                    AccentButtonImage(title: "Save Entry") {
                        save()
                    }
                }
                .padding(16)
            }
            .navigationTitle("Relaxation Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticService.light()
                        dismiss()
                    }
                }
            }
            .toolbarBackground(ThemeColor.surface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .screenBackground()
        }
        .presentationDetents([.medium, .large])
    }

    private func save() {
        guard duration > 0 else {
            showError = true
            HapticService.warning()
            withAnimation(.default) { shake += 1 }
            return
        }
        showError = false
        _ = store.addRelaxation(date: date, duration: duration, note: note)
        dismiss()
    }
}
