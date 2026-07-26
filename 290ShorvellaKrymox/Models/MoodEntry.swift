import Foundation

struct MoodEntry: Identifiable, Codable, Equatable {
    var id: UUID
    var date: Date
    var mood: String
    var description: String
    var tags: [String]

    init(id: UUID = UUID(), date: Date = Date(), mood: String, description: String, tags: [String] = []) {
        self.id = id
        self.date = date
        self.mood = mood
        self.description = description
        self.tags = tags
    }

    enum CodingKeys: String, CodingKey {
        case id, date, mood, description, tags
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        mood = try container.decode(String.self, forKey: .mood)
        description = try container.decode(String.self, forKey: .description)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
    }
}

enum MoodEmoji: String, CaseIterable, Identifiable {
    case calm = "😌"
    case happy = "😊"
    case peaceful = "🧘"
    case grateful = "🙏"
    case tired = "😴"
    case anxious = "😟"
    case sad = "😢"
    case energized = "⚡"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .calm: return "Calm"
        case .happy: return "Happy"
        case .peaceful: return "Peaceful"
        case .grateful: return "Grateful"
        case .tired: return "Tired"
        case .anxious: return "Anxious"
        case .sad: return "Sad"
        case .energized: return "Energized"
        }
    }
}
