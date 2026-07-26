import SwiftUI

enum AppThemeOption: String, CaseIterable, Identifiable {
    case forest
    case ocean
    case dusk

    var id: String { rawValue }

    var title: String {
        switch self {
        case .forest: return "Forest"
        case .ocean: return "Ocean"
        case .dusk: return "Dusk"
        }
    }

    var detail: String {
        switch self {
        case .forest: return "Soft moss greens"
        case .ocean: return "Calm teal waters"
        case .dusk: return "Warm amber evening"
        }
    }

    var palette: ThemePalette {
        switch self {
        case .forest:
            return ThemePalette(
                primary: Color(red: 0.18, green: 0.67, blue: 0.32),
                accent: Color(red: 0.35, green: 0.73, blue: 0.46),
                background: Color(red: 0.07, green: 0.09, blue: 0.12),
                surface: Color(red: 0.12, green: 0.15, blue: 0.18),
                textPrimary: Color(red: 0.95, green: 0.96, blue: 0.97),
                textSecondary: Color(red: 0.65, green: 0.70, blue: 0.74),
                buttonTop: Color(red: 0.20, green: 0.62, blue: 0.38),
                buttonMid: Color(red: 0.12, green: 0.42, blue: 0.28),
                buttonBottom: Color(red: 0.10, green: 0.36, blue: 0.26)
            )
        case .ocean:
            return ThemePalette(
                primary: Color(red: 0.20, green: 0.55, blue: 0.70),
                accent: Color(red: 0.35, green: 0.72, blue: 0.78),
                background: Color(red: 0.05, green: 0.09, blue: 0.14),
                surface: Color(red: 0.10, green: 0.16, blue: 0.22),
                textPrimary: Color(red: 0.93, green: 0.96, blue: 0.98),
                textSecondary: Color(red: 0.62, green: 0.72, blue: 0.78),
                buttonTop: Color(red: 0.22, green: 0.58, blue: 0.72),
                buttonMid: Color(red: 0.12, green: 0.40, blue: 0.55),
                buttonBottom: Color(red: 0.08, green: 0.30, blue: 0.42)
            )
        case .dusk:
            return ThemePalette(
                primary: Color(red: 0.82, green: 0.48, blue: 0.28),
                accent: Color(red: 0.90, green: 0.62, blue: 0.38),
                background: Color(red: 0.10, green: 0.07, blue: 0.10),
                surface: Color(red: 0.18, green: 0.12, blue: 0.14),
                textPrimary: Color(red: 0.97, green: 0.94, blue: 0.90),
                textSecondary: Color(red: 0.74, green: 0.66, blue: 0.60),
                buttonTop: Color(red: 0.85, green: 0.50, blue: 0.30),
                buttonMid: Color(red: 0.62, green: 0.32, blue: 0.22),
                buttonBottom: Color(red: 0.45, green: 0.22, blue: 0.18)
            )
        }
    }
}

struct ThemePalette {
    let primary: Color
    let accent: Color
    let background: Color
    let surface: Color
    let textPrimary: Color
    let textSecondary: Color
    let buttonTop: Color
    let buttonMid: Color
    let buttonBottom: Color
}

enum ThemeColor {
    static var primary: Color { AppDataStore.shared.appTheme.palette.primary }
    static var accent: Color { AppDataStore.shared.appTheme.palette.accent }
    static var background: Color { AppDataStore.shared.appTheme.palette.background }
    static var surface: Color { AppDataStore.shared.appTheme.palette.surface }
    static var textPrimary: Color { AppDataStore.shared.appTheme.palette.textPrimary }
    static var textSecondary: Color { AppDataStore.shared.appTheme.palette.textSecondary }
    static var buttonTop: Color { AppDataStore.shared.appTheme.palette.buttonTop }
    static var buttonMid: Color { AppDataStore.shared.appTheme.palette.buttonMid }
    static var buttonBottom: Color { AppDataStore.shared.appTheme.palette.buttonBottom }
}

enum BreathPreset: String, CaseIterable, Identifiable {
    case fourSevenEight
    case box
    case equal
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fourSevenEight: return "4-7-8"
        case .box: return "Box"
        case .equal: return "Equal 4-4-4"
        case .custom: return "Custom"
        }
    }

    var detail: String {
        switch self {
        case .fourSevenEight: return "Inhale 4 · Hold 7 · Exhale 8"
        case .box: return "Inhale 4 · Hold 4 · Exhale 4 · Hold 4"
        case .equal: return "Inhale 4 · Hold 4 · Exhale 4"
        case .custom: return "Set your own timings"
        }
    }

    var inhale: Double {
        switch self {
        case .fourSevenEight, .box, .equal: return 4
        case .custom: return 0
        }
    }

    var hold: Double {
        switch self {
        case .fourSevenEight: return 7
        case .box, .equal: return 4
        case .custom: return 0
        }
    }

    var exhale: Double {
        switch self {
        case .fourSevenEight: return 8
        case .box, .equal: return 4
        case .custom: return 0
        }
    }

    var holdAfter: Double {
        switch self {
        case .box: return 4
        default: return 0
        }
    }
}

enum MoodTag: String, CaseIterable, Identifiable {
    case sleep = "Sleep"
    case work = "Work"
    case nature = "Nature"
    case social = "Social"
    case health = "Health"
    case home = "Home"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .sleep: return "moon.zzz.fill"
        case .work: return "briefcase.fill"
        case .nature: return "leaf.fill"
        case .social: return "person.2.fill"
        case .health: return "heart.fill"
        case .home: return "house.fill"
        }
    }
}

enum JournalPrompt {
    static let all: [String] = [
        "What helped you feel calmer today?",
        "Name one thing you are grateful for right now.",
        "What is your body asking for in this moment?",
        "Which worry can you set down until tomorrow?",
        "Describe a small moment of ease you noticed.",
        "What would kindness toward yourself look like now?",
        "What emotion is loudest — and what does it need?"
    ]

    static func prompt(for date: Date = Date()) -> String {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 0
        return all[day % all.count]
    }
}
