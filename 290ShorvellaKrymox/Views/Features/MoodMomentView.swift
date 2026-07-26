import SwiftUI

struct MoodMomentView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var selectedDate = Date()
    @State private var showAdd = false
    @State private var displayedMonth = Date()

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        NavigationStack {
            Group {
                if store.moodEntries.isEmpty {
                    EmptyStateView(
                        symbol: "face.smiling",
                        title: "Tap + to log your first mood",
                        message: "Pick a date on the calendar and capture how you feel.",
                        actionTitle: "Log Mood"
                    ) {
                        showAdd = true
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            BannerImageCard(height: 110)
                            calendarCard
                            entriesCard
                        }
                        .padding(16)
                        .padding(.bottom, 72)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay(alignment: .bottomTrailing) {
                Button {
                    HapticService.light()
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(ThemeColor.textPrimary)
                        .frame(width: 56, height: 56)
                        .background(
                            LinearGradient(
                                colors: [ThemeColor.primary, ThemeColor.accent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: ThemeColor.primary.opacity(0.45), radius: 12, y: 6)
                }
                .padding(20)
                .accessibilityLabel("Add mood")
            }
            .navigationTitle("Mood Moment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(ThemeColor.surface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .screenBackground()
            .sheet(isPresented: $showAdd) {
                AddMoodSheet(selectedDate: selectedDate)
                    .environmentObject(store)
            }
        }
    }

    private var calendarCard: some View {
        SoftCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Button {
                        HapticService.light()
                        shiftMonth(-1)
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(ThemeColor.primary)
                            .frame(width: 44, height: 44)
                    }
                    Spacer()
                    Text(monthTitle)
                        .font(.headline)
                        .foregroundStyle(ThemeColor.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer()
                    Button {
                        HapticService.light()
                        shiftMonth(1)
                    } label: {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(ThemeColor.primary)
                            .frame(width: 44, height: 44)
                    }
                }

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(Array(["M", "T", "W", "T", "F", "S", "S"].enumerated()), id: \.offset) { _, day in
                        Text(day)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(ThemeColor.textSecondary)
                            .frame(maxWidth: .infinity)
                    }
                    ForEach(monthDays) { day in
                        Button {
                            guard day.inMonth else { return }
                            HapticService.light()
                            selectedDate = day.date
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(fill(for: day))
                                VStack(spacing: 2) {
                                    Text(day.inMonth ? "\(day.dayNumber)" : "")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(ThemeColor.textPrimary)
                                    if let emoji = day.emoji {
                                        Text(emoji)
                                            .font(.system(size: 11))
                                    }
                                }
                            }
                            .frame(height: 42)
                            .opacity(day.inMonth ? 1 : 0)
                        }
                        .buttonStyle(.plain)
                        .disabled(!day.inMonth)
                    }
                }
            }
        }
    }

    private var entriesCard: some View {
        SoftCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(dayTitle)
                    .font(.headline)
                    .foregroundStyle(ThemeColor.textPrimary)
                let entries = store.moods(on: selectedDate)
                if entries.isEmpty {
                    Text("No mood logged for this day.")
                        .font(.subheadline)
                        .foregroundStyle(ThemeColor.textSecondary)
                        .padding(.vertical, 8)
                } else {
                    ForEach(entries) { entry in
                        HStack(spacing: 12) {
                            Text(entry.mood)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(timeLabel(entry.date))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(ThemeColor.primary)
                                Text(entry.description.isEmpty ? "No note" : entry.description)
                                    .font(.subheadline)
                                    .foregroundStyle(ThemeColor.textPrimary)
                                    .lineLimit(3)
                                    .minimumScaleFactor(0.8)
                                if !entry.tags.isEmpty {
                                    Text(entry.tags.joined(separator: " · "))
                                        .font(.caption2)
                                        .foregroundStyle(ThemeColor.accent)
                                        .lineLimit(1)
                                }
                            }
                            Spacer(minLength: 0)
                            Button {
                                store.deleteMood(entry)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(Color.red.opacity(0.85))
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                        if entry.id != entries.last?.id {
                            Divider().background(ThemeColor.textSecondary.opacity(0.2))
                        }
                    }
                }
            }
        }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    private var dayTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateStyle = .medium
        return formatter.string(from: selectedDate)
    }

    private func timeLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func shiftMonth(_ value: Int) {
        if let next = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = next
        }
    }

    private func fill(for day: CalendarDay) -> Color {
        if calendar.isDate(day.date, inSameDayAs: selectedDate) {
            return ThemeColor.primary.opacity(0.45)
        }
        if day.emoji != nil {
            return ThemeColor.accent.opacity(0.22)
        }
        return ThemeColor.background.opacity(0.4)
    }

    private var monthDays: [CalendarDay] {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)),
              let range = calendar.range(of: .day, in: .month, for: displayedMonth) else {
            return []
        }
        let weekday = calendar.component(.weekday, from: monthStart)
        let mondayBased = (weekday + 5) % 7
        var days: [CalendarDay] = []
        for _ in 0..<mondayBased {
            days.append(CalendarDay(id: UUID(), date: monthStart, dayNumber: 0, emoji: nil, inMonth: false))
        }
        for day in range {
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) else { continue }
            let emoji = store.moods(on: date).first?.mood
            days.append(CalendarDay(id: UUID(), date: date, dayNumber: day, emoji: emoji, inMonth: true))
        }
        return days
    }
}

private struct CalendarDay: Identifiable {
    let id: UUID
    let date: Date
    let dayNumber: Int
    let emoji: String?
    let inMonth: Bool
}

struct AddMoodSheet: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    @State var selectedDate: Date
    var isQuickLog: Bool = false
    @State private var selectedMood = MoodEmoji.calm.rawValue
    @State private var description = ""
    @State private var selectedTags: Set<String> = []
    @State private var shake: CGFloat = 0
    @State private var showError = false
    @State private var prompt = JournalPrompt.prompt()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if isQuickLog {
                        SoftCard {
                            Text("Quick check-in after your breathing session.")
                                .font(.subheadline)
                                .foregroundStyle(ThemeColor.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    } else {
                        SoftCard {
                            DatePicker("Date", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.compact)
                                .tint(ThemeColor.primary)
                                .foregroundStyle(ThemeColor.textPrimary)
                                .colorScheme(.dark)
                        }
                    }

                    SoftCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Mood")
                                .font(.headline)
                                .foregroundStyle(ThemeColor.textPrimary)
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 10)], spacing: 10) {
                                ForEach(MoodEmoji.allCases) { option in
                                    Button {
                                        HapticService.light()
                                        selectedMood = option.rawValue
                                    } label: {
                                        VStack(spacing: 6) {
                                            Text(option.rawValue)
                                                .font(.title)
                                            Text(option.label)
                                                .font(.caption2.weight(.semibold))
                                                .foregroundStyle(ThemeColor.textPrimary)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.7)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(selectedMood == option.rawValue ? ThemeColor.primary.opacity(0.3) : ThemeColor.background.opacity(0.5))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(selectedMood == option.rawValue ? ThemeColor.primary : Color.clear, lineWidth: 1.5)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    SoftCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tags")
                                .font(.headline)
                                .foregroundStyle(ThemeColor.textPrimary)
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)], spacing: 8) {
                                ForEach(MoodTag.allCases) { tag in
                                    Button {
                                        HapticService.light()
                                        if selectedTags.contains(tag.rawValue) {
                                            selectedTags.remove(tag.rawValue)
                                        } else {
                                            selectedTags.insert(tag.rawValue)
                                        }
                                    } label: {
                                        Label(tag.rawValue, systemImage: tag.icon)
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(ThemeColor.textPrimary)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.7)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 10)
                                            .frame(maxWidth: .infinity)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                    .fill(selectedTags.contains(tag.rawValue) ? ThemeColor.primary.opacity(0.35) : ThemeColor.background.opacity(0.5))
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    SoftCard {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Journal prompt")
                                    .font(.headline)
                                    .foregroundStyle(ThemeColor.textPrimary)
                                Spacer()
                                Button {
                                    HapticService.light()
                                    let next = JournalPrompt.all.filter { $0 != prompt }.randomElement() ?? prompt
                                    prompt = next
                                    if description.isEmpty || JournalPrompt.all.contains(description) {
                                        description = ""
                                    }
                                } label: {
                                    Image(systemName: "arrow.clockwise")
                                        .foregroundStyle(ThemeColor.primary)
                                        .frame(width: 44, height: 32)
                                }
                                .buttonStyle(.plain)
                            }
                            Text(prompt)
                                .font(.subheadline)
                                .foregroundStyle(ThemeColor.accent)
                            TextField("Write a short answer…", text: $description, axis: .vertical)
                                .lineLimit(3...6)
                                .foregroundStyle(ThemeColor.textPrimary)
                                .padding(12)
                                .background(ThemeColor.background.opacity(0.55))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .modifier(ShakeEffect(animatableData: shake))
                            if showError {
                                Text("Add a short description to save.")
                                    .font(.caption)
                                    .foregroundStyle(Color.red.opacity(0.9))
                            }
                        }
                    }

                    AccentButtonImage(title: isQuickLog ? "Save Check-in" : "Save Mood") {
                        save()
                    }
                }
                .padding(16)
            }
            .navigationTitle(isQuickLog ? "Quick Mood" : "New Mood")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isQuickLog ? "Skip" : "Cancel") {
                        HapticService.light()
                        dismiss()
                    }
                }
            }
            .toolbarBackground(ThemeColor.surface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .screenBackground()
        }
        .presentationDetents([.large])
    }

    private func save() {
        let text = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            showError = true
            HapticService.warning()
            withAnimation(.default) { shake += 1 }
            return
        }
        showError = false
        _ = store.addMood(
            date: selectedDate,
            mood: selectedMood,
            description: text,
            tags: Array(selectedTags).sorted()
        )
        dismiss()
    }
}
