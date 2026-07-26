import SwiftUI

struct FocusTimerView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.scenePhase) private var scenePhase

    @State private var selectedMinutes = 25
    @State private var remaining: Int = 25 * 60
    @State private var isRunning = false
    @State private var endDate: Date?
    @State private var showDone = false

    private let presets = [15, 25, 45]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    SoftCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Focus Timer")
                                .font(.headline)
                                .foregroundStyle(ThemeColor.textPrimary)
                            Text("A gentle pomodoro. Completed time is saved to your practice minutes.")
                                .font(.subheadline)
                                .foregroundStyle(ThemeColor.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    ZStack {
                        Circle()
                            .stroke(ThemeColor.surface, lineWidth: 12)
                            .frame(width: 220, height: 220)
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                ThemeColor.primary,
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 220, height: 220)
                            .animation(.linear(duration: 0.2), value: progress)
                        VStack(spacing: 6) {
                            Text(timeLabel)
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(ThemeColor.textPrimary)
                            Text(isRunning ? "Stay with the breath" : "Ready when you are")
                                .font(.caption)
                                .foregroundStyle(ThemeColor.textSecondary)
                        }
                    }
                    .padding(.vertical, 8)

                    if !isRunning {
                        SoftCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Duration")
                                    .font(.headline)
                                    .foregroundStyle(ThemeColor.textPrimary)
                                HStack(spacing: 10) {
                                    ForEach(presets, id: \.self) { mins in
                                        Button {
                                            HapticService.light()
                                            selectedMinutes = mins
                                            remaining = mins * 60
                                        } label: {
                                            Text("\(mins)m")
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(ThemeColor.textPrimary)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 12)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                        .fill(selectedMinutes == mins ? ThemeColor.primary.opacity(0.35) : ThemeColor.background.opacity(0.5))
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                Stepper(value: $selectedMinutes, in: 5...90, step: 5) {
                                    Text("Custom: \(selectedMinutes) min")
                                        .foregroundStyle(ThemeColor.textPrimary)
                                }
                                .tint(ThemeColor.primary)
                                .onChange(of: selectedMinutes) { value in
                                    if !isRunning { remaining = value * 60 }
                                }
                            }
                        }
                    }

                    Button {
                        if isRunning {
                            stop(completed: false)
                        } else {
                            start()
                        }
                    } label: {
                        Text(isRunning ? "Stop" : "Start Focus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(16)
                .padding(.bottom, 24)
            }
            .navigationTitle("Focus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(ThemeColor.surface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .screenBackground()
            .onReceive(Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()) { date in
                guard isRunning, let endDate else { return }
                let left = max(0, Int(ceil(endDate.timeIntervalSince(date))))
                remaining = left
                if left == 0 {
                    stop(completed: true)
                }
            }
            .onChange(of: scenePhase) { phase in
                if phase != .active, isRunning {
                    stop(completed: false)
                }
            }
            .alert("Focus complete", isPresented: $showDone) {
                Button("Great") { HapticService.light() }
            } message: {
                Text("\(selectedMinutes) minutes were added to your practice.")
            }
        }
    }

    private var progress: CGFloat {
        let total = max(selectedMinutes * 60, 1)
        return CGFloat(total - remaining) / CGFloat(total)
    }

    private var timeLabel: String {
        let m = remaining / 60
        let s = remaining % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func start() {
        HapticService.medium()
        remaining = selectedMinutes * 60
        endDate = Date().addingTimeInterval(TimeInterval(remaining))
        isRunning = true
    }

    private func stop(completed: Bool) {
        isRunning = false
        endDate = nil
        if completed {
            store.completeFocusSession(minutes: selectedMinutes)
            showDone = true
            remaining = selectedMinutes * 60
        } else {
            HapticService.light()
            remaining = selectedMinutes * 60
        }
    }
}
