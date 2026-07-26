import SwiftUI
import StoreKit

struct SettingsView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var showResetAlert = false
    @State private var reminderEnabled = ReminderService.isEnabled
    @State private var reminderTime = SettingsView.makeReminderDate()
    @State private var reminderDenied = false

    private var soundBinding: Binding<Bool> {
        Binding(
            get: { HapticService.soundEnabled },
            set: { newValue in
                HapticService.soundEnabled = newValue
                if newValue { HapticService.play(1104) }
                ReminderService.refreshSchedule()
            }
        )
    }

    private var hapticsBinding: Binding<Bool> {
        Binding(
            get: { HapticService.hapticsEnabled },
            set: { newValue in
                HapticService.hapticsEnabled = newValue
                if newValue {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    SoftCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Theme")
                                .font(.headline)
                                .foregroundStyle(ThemeColor.textPrimary)
                            ForEach(AppThemeOption.allCases) { theme in
                                Button {
                                    HapticService.light()
                                    store.setTheme(theme)
                                } label: {
                                    HStack(spacing: 12) {
                                        Circle()
                                            .fill(theme.palette.primary)
                                            .frame(width: 18, height: 18)
                                            .overlay(Circle().stroke(theme.palette.accent, lineWidth: 2))
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(theme.title)
                                                .foregroundStyle(ThemeColor.textPrimary)
                                            Text(theme.detail)
                                                .font(.caption)
                                                .foregroundStyle(ThemeColor.textSecondary)
                                        }
                                        Spacer()
                                        if store.appTheme == theme {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(ThemeColor.primary)
                                        }
                                    }
                                    .frame(minHeight: 44)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    SoftCard {
                        VStack(spacing: 0) {
                            Toggle(isOn: $reminderEnabled) {
                                Label {
                                    Text("Daily Reminder")
                                        .foregroundStyle(ThemeColor.textPrimary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                } icon: {
                                    Image(systemName: "bell.fill")
                                        .foregroundStyle(ThemeColor.primary)
                                        .frame(width: 28)
                                }
                            }
                            .tint(ThemeColor.primary)
                            .frame(minHeight: 44)
                            .padding(.vertical, 6)
                            .onChange(of: reminderEnabled) { value in
                                ReminderService.setEnabled(value) { granted in
                                    if value && !granted {
                                        reminderEnabled = false
                                        reminderDenied = true
                                    }
                                }
                            }

                            if reminderEnabled {
                                Divider().background(ThemeColor.textSecondary.opacity(0.25))
                                DatePicker(
                                    "Reminder time",
                                    selection: $reminderTime,
                                    displayedComponents: .hourAndMinute
                                )
                                .tint(ThemeColor.primary)
                                .foregroundStyle(ThemeColor.textPrimary)
                                .colorScheme(.dark)
                                .frame(minHeight: 44)
                                .padding(.vertical, 6)
                                .onChange(of: reminderTime) { date in
                                    let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                                    ReminderService.updateTime(hour: comps.hour ?? 20, minute: comps.minute ?? 0)
                                }
                            }
                        }
                    }

                    SoftCard {
                        VStack(spacing: 0) {
                            Toggle(isOn: soundBinding) {
                                Label {
                                    Text("Sound Effects")
                                        .foregroundStyle(ThemeColor.textPrimary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                } icon: {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .foregroundStyle(ThemeColor.primary)
                                        .frame(width: 28)
                                }
                            }
                            .tint(ThemeColor.primary)
                            .frame(minHeight: 44)
                            .padding(.vertical, 6)

                            Divider().background(ThemeColor.textSecondary.opacity(0.25))

                            Toggle(isOn: hapticsBinding) {
                                Label {
                                    Text("Haptic Feedback")
                                        .foregroundStyle(ThemeColor.textPrimary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                } icon: {
                                    Image(systemName: "hand.tap.fill")
                                        .foregroundStyle(ThemeColor.primary)
                                        .frame(width: 28)
                                }
                            }
                            .tint(ThemeColor.primary)
                            .frame(minHeight: 44)
                            .padding(.vertical, 6)
                        }
                    }

                    SoftCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Streak Freeze", systemImage: "snowflake")
                                .font(.headline)
                                .foregroundStyle(ThemeColor.textPrimary)
                            Text(store.stats.streakFreezeRemaining > 0
                                 ? "You have 1 freeze left this week. Miss a day once and your streak stays alive."
                                 : "Your weekly freeze was used. A new one arrives next week.")
                                .font(.subheadline)
                                .foregroundStyle(ThemeColor.textSecondary)
                            Text("Current streak: \(store.stats.streakDays) days")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(ThemeColor.accent)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    SoftCard {
                        VStack(spacing: 0) {
                            NavigationLink {
                                AchievementsView()
                            } label: {
                                settingsRow(title: "Achievements", systemImage: "trophy.fill")
                            }
                            .simultaneousGesture(TapGesture().onEnded { HapticService.light() })

                            Divider().background(ThemeColor.textSecondary.opacity(0.25))

                            Button {
                                HapticService.light()
                                store.showWeeklyReflection = true
                            } label: {
                                settingsRow(title: "Weekly Reflection", systemImage: "text.book.closed.fill")
                            }
                            .buttonStyle(.plain)

                            Divider().background(ThemeColor.textSecondary.opacity(0.25))
                            settingsButton(title: "Rate Us", systemImage: "star.fill") {
                                rateApp()
                            }
                            Divider().background(ThemeColor.textSecondary.opacity(0.25))
                            settingsButton(title: "Privacy Policy", systemImage: "hand.raised.fill") {
                                openURL(AppLinks.privacyPolicy)
                            }
                            Divider().background(ThemeColor.textSecondary.opacity(0.25))
                            settingsButton(title: "Terms of Use", systemImage: "doc.text.fill") {
                                openURL(AppLinks.termsOfUse)
                            }
                        }
                    }

                    Button {
                        HapticService.warning()
                        showResetAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Reset All Data")
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Spacer()
                        }
                        .font(.headline)
                        .foregroundStyle(Color.red.opacity(0.95))
                        .padding(16)
                        .background(ThemeColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: .black.opacity(0.3), radius: 10, y: 6)
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 24)
                }
                .padding(16)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(ThemeColor.surface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .screenBackground()
            .alert("Reset All Data?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    store.resetAll()
                }
            } message: {
                Text("This clears mood logs, relaxation entries, sessions, and achievements on this device.")
            }
            .alert("Notifications Off", isPresented: $reminderDenied) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Enable notifications in iOS Settings to receive a daily mood reminder.")
            }
        }
    }

    private func settingsRow(title: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(ThemeColor.primary)
                .frame(width: 28)
            Text(title)
                .foregroundStyle(ThemeColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(ThemeColor.textSecondary)
        }
        .frame(minHeight: 44)
        .padding(.vertical, 6)
    }

    private func settingsButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticService.light()
            action()
        } label: {
            settingsRow(title: title, systemImage: systemImage)
        }
        .buttonStyle(.plain)
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }

    private static func makeReminderDate() -> Date {
        var comps = DateComponents()
        comps.hour = ReminderService.hour
        comps.minute = ReminderService.minute
        return Calendar.current.date(from: comps) ?? Date()
    }
}
