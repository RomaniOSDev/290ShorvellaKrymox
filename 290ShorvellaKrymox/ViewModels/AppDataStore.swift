import Foundation
import SwiftUI
import Combine

final class AppDataStore: ObservableObject {
    static let shared = AppDataStore()

    @Published var moodEntries: [MoodEntry] = []
    @Published var relaxationEntries: [RelaxationEntry] = []
    @Published var stats: UserStats = UserStats()
    @Published var unlockedAchievements: Set<String> = []
    @Published var hasSeenOnboarding: Bool = false
    @Published var bannerTitle: String?
    @Published var showSuccessFlash: Bool = false
    @Published var completedSessions: Int = 0
    @Published var lastSessionDate: Date?
    @Published var breathCycleDuration: Double = 19.0
    @Published var appTheme: AppThemeOption = .forest
    @Published var breathPreset: BreathPreset = .fourSevenEight
    @Published var customInhale: Double = 4
    @Published var customHold: Double = 4
    @Published var customExhale: Double = 4
    @Published var customHoldAfter: Double = 0
    @Published var lastReflectionWeekId: String = ""
    @Published var showWeeklyReflection: Bool = false

    private let defaults = UserDefaults.standard
    private let moodsKey = "le_moods"
    private let relaxKey = "le_relax"
    private let statsKey = "le_stats"
    private let unlockedKey = "le_unlocked"
    private let onboardingKey = "le_onboarding"
    private let sessionsKey = "le_sessions"
    private let lastSessionKey = "le_last_session"
    private let cycleKey = "le_cycle_duration"
    private let themeKey = "le_theme"
    private let presetKey = "le_breath_preset"
    private let customInhaleKey = "le_custom_inhale"
    private let customHoldKey = "le_custom_hold"
    private let customExhaleKey = "le_custom_exhale"
    private let customHoldAfterKey = "le_custom_hold_after"
    private let reflectionWeekKey = "le_reflection_week"

    private var bannerQueue: [String] = []
    private var isShowingBanner = false

    private init() {
        load()
        refreshFreezeWeekIfNeeded()
    }

    // MARK: - Mood

    @discardableResult
    func addMood(date: Date, mood: String, description: String, tags: [String] = []) -> MoodEntry? {
        let text = description.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !mood.isEmpty else { return nil }
        let entry = MoodEntry(date: date, mood: mood, description: text, tags: tags)
        moodEntries.insert(entry, at: 0)
        stats.entriesCreated += 1
        recordActivity()
        persist()
        flashSuccess()
        evaluateAchievements()
        HapticService.medium()
        return entry
    }

    func deleteMood(_ entry: MoodEntry) {
        moodEntries.removeAll { $0.id == entry.id }
        persist()
        HapticService.warning()
    }

    func moods(on day: Date) -> [MoodEntry] {
        let cal = Calendar.current
        return moodEntries
            .filter { cal.isDate($0.date, inSameDayAs: day) }
            .sorted { $0.date > $1.date }
    }

    // MARK: - Breathing

    func completeBreathingSession(cycles: Int = 3) {
        let seconds = max(1, Int(breathCycleDuration * Double(max(cycles, 1))))
        let minutes = max(1, Int(ceil(Double(seconds) / 60.0)))
        completedSessions += 1
        stats.sessionsCompleted = completedSessions
        stats.totalMinutesPracticed += minutes
        lastSessionDate = Date()
        recordActivity()
        persist()
        flashSuccess()
        evaluateAchievements()
        HapticService.success()
    }

    var activeBreathTimings: (inhale: Double, hold: Double, exhale: Double, holdAfter: Double) {
        if breathPreset == .custom {
            return (
                max(2, customInhale),
                max(0, customHold),
                max(2, customExhale),
                max(0, customHoldAfter)
            )
        }
        return (breathPreset.inhale, breathPreset.hold, breathPreset.exhale, breathPreset.holdAfter)
    }

    func setBreathPreset(_ preset: BreathPreset) {
        breathPreset = preset
        let t = activeBreathTimings
        breathCycleDuration = t.inhale + t.hold + t.exhale + t.holdAfter
        persist()
    }

    // MARK: - Relaxation / Focus

    @discardableResult
    func addRelaxation(date: Date, duration: Int, note: String = "") -> RelaxationEntry? {
        guard duration > 0 else { return nil }
        let entry = RelaxationEntry(
            date: date,
            duration: duration,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        relaxationEntries.insert(entry, at: 0)
        stats.entriesCreated += 1
        stats.totalMinutesPracticed += duration
        recordActivity()
        persist()
        flashSuccess()
        evaluateAchievements()
        HapticService.medium()
        return entry
    }

    func completeFocusSession(minutes: Int) {
        _ = addRelaxation(date: Date(), duration: max(1, minutes), note: "Focus session")
    }

    func deleteRelaxation(_ entry: RelaxationEntry) {
        relaxationEntries.removeAll { $0.id == entry.id }
        persist()
        HapticService.warning()
    }

    var weeklySummary: [Int] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<7).map { offset -> Int in
            guard let day = cal.date(byAdding: .day, value: offset - 6, to: today) else { return 0 }
            return relaxationEntries
                .filter { cal.isDate($0.date, inSameDayAs: day) }
                .reduce(0) { $0 + $1.duration }
        }
    }

    var relaxationHeatmap: [Date: Int] {
        let cal = Calendar.current
        var map: [Date: Int] = [:]
        for entry in relaxationEntries {
            let day = cal.startOfDay(for: entry.date)
            map[day, default: 0] += 1
        }
        for entry in moodEntries {
            let day = cal.startOfDay(for: entry.date)
            map[day, default: 0] += 1
        }
        return map
    }

    // MARK: - Theme

    func setTheme(_ theme: AppThemeOption) {
        appTheme = theme
        defaults.set(theme.rawValue, forKey: themeKey)
        objectWillChange.send()
    }

    // MARK: - Weekly reflection

    var currentWeekId: String {
        let cal = Calendar.current
        let week = cal.component(.weekOfYear, from: Date())
        let year = cal.component(.yearForWeekOfYear, from: Date())
        return "\(year)-W\(week)"
    }

    func weeklyReflectionSummary() -> String {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let start = cal.date(byAdding: .day, value: -6, to: today) else {
            return "Keep logging to unlock your weekly reflection."
        }
        let moods = moodEntries.filter { $0.date >= start }
        let relax = relaxationEntries.filter { $0.date >= start }
        let minutes = relax.reduce(0) { $0 + $1.duration }
        var moodMap: [String: Int] = [:]
        for entry in moods {
            moodMap[entry.mood, default: 0] += 1
        }
        let topMood = moodMap.max(by: { $0.value < $1.value })?.key
        let topLabel = topMood.flatMap { MoodEmoji(rawValue: $0)?.label } ?? "varied"
        let tagCounts = Dictionary(grouping: moods.flatMap(\.tags), by: { $0 }).mapValues(\.count)
        let topTag = tagCounts.max(by: { $0.value < $1.value })?.key

        var lines: [String] = []
        lines.append("This week you logged \(moods.count) mood\(moods.count == 1 ? "" : "s") and \(relax.count) calm session\(relax.count == 1 ? "" : "s").")
        lines.append("You practiced about \(minutes) minute\(minutes == 1 ? "" : "s") in total.")
        if moods.isEmpty {
            lines.append("Your most common mood will appear once you start journaling.")
        } else {
            lines.append("Your most frequent mood was \(topMood ?? "") \(topLabel).")
        }
        if let topTag {
            lines.append("You often tagged moments around \(topTag.lowercased()).")
        }
        if stats.streakDays > 0 {
            lines.append("Current streak: \(stats.streakDays) day\(stats.streakDays == 1 ? "" : "s"). Keep the gentle rhythm going.")
        }
        return lines.joined(separator: "\n\n")
    }

    func checkWeeklyReflection() {
        let week = currentWeekId
        // Offer reflection from Friday onward once per week.
        let weekday = Calendar.current.component(.weekday, from: Date())
        guard weekday == 1 || weekday >= 6 else { return } // Fri/Sat/Sun
        guard lastReflectionWeekId != week else { return }
        guard !moodEntries.isEmpty || !relaxationEntries.isEmpty else { return }
        showWeeklyReflection = true
    }

    func dismissWeeklyReflection(markSeen: Bool) {
        showWeeklyReflection = false
        if markSeen {
            lastReflectionWeekId = currentWeekId
            defaults.set(lastReflectionWeekId, forKey: reflectionWeekKey)
        }
    }

    // MARK: - Onboarding / Reset

    func completeOnboarding() {
        hasSeenOnboarding = true
        defaults.set(true, forKey: onboardingKey)
        HapticService.success()
    }

    func resetAll() {
        moodEntries = []
        relaxationEntries = []
        stats = UserStats()
        unlockedAchievements = []
        completedSessions = 0
        lastSessionDate = nil
        breathCycleDuration = 19.0
        breathPreset = .fourSevenEight
        customInhale = 4
        customHold = 4
        customExhale = 4
        customHoldAfter = 0
        lastReflectionWeekId = ""
        showWeeklyReflection = false
        bannerTitle = nil
        bannerQueue.removeAll()
        isShowingBanner = false
        refreshFreezeWeekIfNeeded()
        persist()
        NotificationCenter.default.post(name: .dataReset, object: nil)
        HapticService.warning()
    }

    // MARK: - Achievements

    func evaluateAchievements() {
        for kind in AchievementKind.allCases {
            guard kind.isUnlocked(stats: stats) else { continue }
            let key = kind.rawValue
            guard !unlockedAchievements.contains(key) else { continue }
            unlockedAchievements.insert(key)
            enqueueBanner(kind.title)
        }
        persist()
    }

    private func enqueueBanner(_ title: String) {
        bannerQueue.append(title)
        presentNextBannerIfNeeded()
    }

    private func presentNextBannerIfNeeded() {
        guard !isShowingBanner, let next = bannerQueue.first else { return }
        bannerQueue.removeFirst()
        isShowingBanner = true
        HapticService.success()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            bannerTitle = next
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            withAnimation(.easeOut(duration: 0.35)) {
                self?.bannerTitle = nil
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self?.isShowingBanner = false
                self?.presentNextBannerIfNeeded()
            }
        }
    }

    func flashSuccess() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            showSuccessFlash = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            withAnimation(.easeOut(duration: 0.3)) {
                self?.showSuccessFlash = false
            }
        }
    }

    // MARK: - Streak / Freeze

    func refreshFreezeWeekIfNeeded() {
        let week = currentWeekId
        if stats.freezeWeekId != week {
            stats.freezeWeekId = week
            stats.streakFreezeRemaining = 1
            persist()
        }
    }

    private func dayString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func recordActivity() {
        refreshFreezeWeekIfNeeded()
        let today = dayString(Date())
        if stats.lastActiveDay.isEmpty {
            stats.streakDays = 1
            stats.longestStreak = max(stats.longestStreak, 1)
            stats.lastActiveDay = today
            return
        }
        if stats.lastActiveDay == today { return }

        let cal = Calendar.current
        if let yesterday = cal.date(byAdding: .day, value: -1, to: Date()),
           dayString(yesterday) == stats.lastActiveDay {
            stats.streakDays += 1
        } else if let twoDaysAgo = cal.date(byAdding: .day, value: -2, to: Date()),
                  dayString(twoDaysAgo) == stats.lastActiveDay,
                  stats.streakFreezeRemaining > 0 {
            // Missed exactly one day — spend weekly freeze.
            stats.streakFreezeRemaining = 0
            stats.lastFreezeUsedDay = today
            stats.streakDays += 1
            enqueueBanner("Streak Freeze Used")
        } else {
            stats.streakDays = 1
        }
        stats.longestStreak = max(stats.longestStreak, stats.streakDays)
        stats.lastActiveDay = today
    }

    // MARK: - Persistence

    private func load() {
        hasSeenOnboarding = defaults.bool(forKey: onboardingKey)
        completedSessions = defaults.integer(forKey: sessionsKey)
        if defaults.object(forKey: cycleKey) != nil {
            breathCycleDuration = defaults.double(forKey: cycleKey)
        }
        if let interval = defaults.object(forKey: lastSessionKey) as? Double {
            lastSessionDate = Date(timeIntervalSince1970: interval)
        }
        if let data = defaults.data(forKey: moodsKey),
           let decoded = try? JSONDecoder().decode([MoodEntry].self, from: data) {
            moodEntries = decoded
        }
        if let data = defaults.data(forKey: relaxKey),
           let decoded = try? JSONDecoder().decode([RelaxationEntry].self, from: data) {
            relaxationEntries = decoded
        }
        if let data = defaults.data(forKey: statsKey),
           let decoded = try? JSONDecoder().decode(UserStats.self, from: data) {
            stats = decoded
        }
        if let arr = defaults.array(forKey: unlockedKey) as? [String] {
            unlockedAchievements = Set(arr)
        }
        if let raw = defaults.string(forKey: themeKey),
           let theme = AppThemeOption(rawValue: raw) {
            appTheme = theme
        }
        if let raw = defaults.string(forKey: presetKey),
           let preset = BreathPreset(rawValue: raw) {
            breathPreset = preset
        }
        if defaults.object(forKey: customInhaleKey) != nil {
            customInhale = defaults.double(forKey: customInhaleKey)
            customHold = defaults.double(forKey: customHoldKey)
            customExhale = defaults.double(forKey: customExhaleKey)
            customHoldAfter = defaults.double(forKey: customHoldAfterKey)
        }
        lastReflectionWeekId = defaults.string(forKey: reflectionWeekKey) ?? ""
        stats.sessionsCompleted = max(stats.sessionsCompleted, completedSessions)
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(moodEntries) {
            defaults.set(data, forKey: moodsKey)
        }
        if let data = try? JSONEncoder().encode(relaxationEntries) {
            defaults.set(data, forKey: relaxKey)
        }
        if let data = try? JSONEncoder().encode(stats) {
            defaults.set(data, forKey: statsKey)
        }
        defaults.set(Array(unlockedAchievements), forKey: unlockedKey)
        defaults.set(hasSeenOnboarding, forKey: onboardingKey)
        defaults.set(completedSessions, forKey: sessionsKey)
        defaults.set(breathCycleDuration, forKey: cycleKey)
        defaults.set(appTheme.rawValue, forKey: themeKey)
        defaults.set(breathPreset.rawValue, forKey: presetKey)
        defaults.set(customInhale, forKey: customInhaleKey)
        defaults.set(customHold, forKey: customHoldKey)
        defaults.set(customExhale, forKey: customExhaleKey)
        defaults.set(customHoldAfter, forKey: customHoldAfterKey)
        defaults.set(lastReflectionWeekId, forKey: reflectionWeekKey)
        if let lastSessionDate {
            defaults.set(lastSessionDate.timeIntervalSince1970, forKey: lastSessionKey)
        } else {
            defaults.removeObject(forKey: lastSessionKey)
        }
    }
}
