import Foundation

enum AchievementKind: String, Codable, CaseIterable {
    case firstEntry
    case weekStreak
    case calmExplorer
    case reflectionMaster
    case mindfulDedication
    case dailyDevotee
    case tranquilFocus
    case gettingGoing

    var title: String {
        switch self {
        case .firstEntry: return "First Entry"
        case .weekStreak: return "Week Streak"
        case .calmExplorer: return "Calm Explorer"
        case .reflectionMaster: return "Reflection Master"
        case .mindfulDedication: return "Mindful Dedication"
        case .dailyDevotee: return "Daily Devotee"
        case .tranquilFocus: return "Tranquil Focus"
        case .gettingGoing: return "Getting Going"
        }
    }

    var detail: String {
        switch self {
        case .firstEntry: return "You created your first entry in the journal."
        case .weekStreak: return "Logged entries for seven consecutive days."
        case .calmExplorer: return "Completed ten breathing sessions."
        case .reflectionMaster: return "Gained insights from twenty entries."
        case .mindfulDedication: return "Maintained a consistent practice for thirty days."
        case .dailyDevotee: return "Completed fifty breathing sessions."
        case .tranquilFocus: return "Spent over two hundred minutes in practice."
        case .gettingGoing: return "Reached 10 journal entries."
        }
    }

    var icon: String {
        switch self {
        case .firstEntry: return "pencil.and.outline"
        case .weekStreak: return "flame.fill"
        case .calmExplorer: return "leaf.fill"
        case .reflectionMaster: return "book.fill"
        case .mindfulDedication: return "calendar.badge.checkmark"
        case .dailyDevotee: return "star.fill"
        case .tranquilFocus: return "timer"
        case .gettingGoing: return "figure.walk"
        }
    }

    var goal: Int {
        switch self {
        case .firstEntry: return 1
        case .weekStreak: return 7
        case .calmExplorer: return 10
        case .reflectionMaster: return 20
        case .mindfulDedication: return 30
        case .dailyDevotee: return 50
        case .tranquilFocus: return 200
        case .gettingGoing: return 10
        }
    }

    func progress(stats: UserStats) -> Int {
        switch self {
        case .firstEntry, .reflectionMaster, .gettingGoing:
            return stats.entriesCreated
        case .weekStreak:
            return stats.streakDays
        case .calmExplorer, .dailyDevotee:
            return stats.sessionsCompleted
        case .mindfulDedication:
            return stats.longestStreak
        case .tranquilFocus:
            return stats.totalMinutesPracticed
        }
    }

    func isUnlocked(stats: UserStats) -> Bool {
        progress(stats: stats) >= goal
    }
}

struct UserStats: Codable, Equatable {
    var entriesCreated: Int = 0
    var sessionsCompleted: Int = 0
    var streakDays: Int = 0
    var longestStreak: Int = 0
    var totalMinutesPracticed: Int = 0
    var lastActiveDay: String = ""
    var streakFreezeRemaining: Int = 1
    var freezeWeekId: String = ""
    var lastFreezeUsedDay: String = ""

    enum CodingKeys: String, CodingKey {
        case entriesCreated, sessionsCompleted, streakDays, longestStreak
        case totalMinutesPracticed, lastActiveDay
        case streakFreezeRemaining, freezeWeekId, lastFreezeUsedDay
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        entriesCreated = try container.decodeIfPresent(Int.self, forKey: .entriesCreated) ?? 0
        sessionsCompleted = try container.decodeIfPresent(Int.self, forKey: .sessionsCompleted) ?? 0
        streakDays = try container.decodeIfPresent(Int.self, forKey: .streakDays) ?? 0
        longestStreak = try container.decodeIfPresent(Int.self, forKey: .longestStreak) ?? 0
        totalMinutesPracticed = try container.decodeIfPresent(Int.self, forKey: .totalMinutesPracticed) ?? 0
        lastActiveDay = try container.decodeIfPresent(String.self, forKey: .lastActiveDay) ?? ""
        streakFreezeRemaining = try container.decodeIfPresent(Int.self, forKey: .streakFreezeRemaining) ?? 1
        freezeWeekId = try container.decodeIfPresent(String.self, forKey: .freezeWeekId) ?? ""
        lastFreezeUsedDay = try container.decodeIfPresent(String.self, forKey: .lastFreezeUsedDay) ?? ""
    }
}

extension Notification.Name {
    static let dataReset = Notification.Name("dataReset")
}
