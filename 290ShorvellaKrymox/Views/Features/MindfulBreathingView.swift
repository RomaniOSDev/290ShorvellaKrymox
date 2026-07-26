import SwiftUI

struct MindfulBreathingView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var isRunning = false
    @State private var sessionStart: Date?
    @State private var showParticles = false
    @State private var completedCycles = 0
    @State private var speedFactor: Double = 1.0
    @State private var lastPhase: String = ""
    @State private var showQuickMood = false

    private let targetCycles = 3

    private var inhale: Double { store.activeBreathTimings.inhale }
    private var hold: Double { store.activeBreathTimings.hold }
    private var exhale: Double { store.activeBreathTimings.exhale }
    private var holdAfter: Double { store.activeBreathTimings.holdAfter }

    var body: some View {
        NavigationStack {
            Group {
                if !isRunning && store.completedSessions == 0 && sessionStart == nil {
                    EmptyStateView(
                        symbol: "leaf.fill",
                        title: "Tap to Begin Your Breathing Journey",
                        message: "Choose a preset and follow the circle — inhale, hold, exhale.",
                        actionTitle: "Start Session"
                    ) {
                        startSession()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 22) {
                            BannerImageCard(imageName: "img_card", height: 100)

                            SoftCard {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Breathing Preset")
                                        .font(.headline)
                                        .foregroundStyle(ThemeColor.textPrimary)
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(BreathPreset.allCases) { preset in
                                                Button {
                                                    guard !isRunning else { return }
                                                    HapticService.light()
                                                    store.setBreathPreset(preset)
                                                } label: {
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text(preset.title)
                                                            .font(.subheadline.weight(.semibold))
                                                        Text(preset.detail)
                                                            .font(.caption2)
                                                            .lineLimit(2)
                                                            .minimumScaleFactor(0.7)
                                                    }
                                                    .foregroundStyle(ThemeColor.textPrimary)
                                                    .padding(10)
                                                    .frame(width: 140, alignment: .leading)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                            .fill(store.breathPreset == preset ? ThemeColor.primary.opacity(0.35) : ThemeColor.background.opacity(0.5))
                                                    )
                                                }
                                                .buttonStyle(.plain)
                                                .disabled(isRunning)
                                            }
                                        }
                                    }

                                    if store.breathPreset == .custom && !isRunning {
                                        VStack(spacing: 8) {
                                            timingStepper("Inhale", value: $store.customInhale)
                                            timingStepper("Hold", value: $store.customHold)
                                            timingStepper("Exhale", value: $store.customExhale)
                                            timingStepper("Hold after", value: $store.customHoldAfter)
                                        }
                                        .onChange(of: store.customInhale) { _ in store.setBreathPreset(.custom) }
                                        .onChange(of: store.customHold) { _ in store.setBreathPreset(.custom) }
                                        .onChange(of: store.customExhale) { _ in store.setBreathPreset(.custom) }
                                        .onChange(of: store.customHoldAfter) { _ in store.setBreathPreset(.custom) }
                                    }

                                    Text("Sessions completed: \(store.completedSessions)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(ThemeColor.accent)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            breathingCircle
                                .frame(height: 280)
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            let delta = value.translation.width / 200
                                            speedFactor = min(1.6, max(0.7, 1.0 + delta))
                                        }
                                )
                                .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { date in
                                    guard isRunning, let start = sessionStart else { return }
                                    let elapsed = date.timeIntervalSince(start) * speedFactor
                                    let cycle = inhale + hold + exhale + holdAfter
                                    guard cycle > 0 else { return }
                                    let cycleIndex = Int(elapsed / cycle)
                                    if cycleIndex != completedCycles {
                                        completedCycles = min(cycleIndex, targetCycles)
                                    }
                                    let phase = phaseProgress(at: date).phase.rawValue
                                    if phase != lastPhase {
                                        lastPhase = phase
                                        HapticService.breathCue()
                                    }
                                    if cycleIndex >= targetCycles {
                                        stopSession(completed: true)
                                    }
                                }

                            phaseLabel

                            if showParticles {
                                particleBurst
                                    .transition(.scale.combined(with: .opacity))
                            }

                            Button {
                                if isRunning {
                                    stopSession(completed: false)
                                } else {
                                    startSession()
                                }
                            } label: {
                                Text(isRunning ? "Stop Session" : "Start Session")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        }
                        .padding(16)
                        .padding(.bottom, 24)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Breathing Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(ThemeColor.surface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .screenBackground()
            .onChange(of: scenePhase) { phase in
                if phase != .active, isRunning {
                    stopSession(completed: false)
                }
            }
            .sheet(isPresented: $showQuickMood) {
                AddMoodSheet(selectedDate: Date(), isQuickLog: true)
                    .environmentObject(store)
            }
        }
    }

    private func timingStepper(_ title: String, value: Binding<Double>) -> some View {
        Stepper(value: value, in: 0...20, step: 1) {
            Text("\(title): \(Int(value.wrappedValue))s")
                .foregroundStyle(ThemeColor.textPrimary)
        }
        .tint(ThemeColor.primary)
    }

    private var breathingCircle: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: !isRunning)) { context in
            let progress = phaseProgress(at: context.date)
            let scale = circleScale(for: progress)
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                ThemeColor.primary.opacity(0.55),
                                ThemeColor.accent.opacity(0.18),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 140
                        )
                    )
                    .frame(width: 240, height: 240)
                    .scaleEffect(scale)
                    .animation(.easeInOut(duration: 0.2), value: scale)

                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [ThemeColor.primary, ThemeColor.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 6
                    )
                    .frame(width: 180, height: 180)
                    .scaleEffect(scale)

                VStack(spacing: 6) {
                    Text(progress.phase.rawValue)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(ThemeColor.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("\(progress.remaining)s")
                        .font(.title3.monospacedDigit().weight(.semibold))
                        .foregroundStyle(ThemeColor.accent)
                    Text("Cycle \(min(completedCycles + 1, targetCycles))/\(targetCycles)")
                        .font(.caption)
                        .foregroundStyle(ThemeColor.textSecondary)
                }
            }
        }
    }

    private var phaseLabel: some View {
        Group {
            if isRunning {
                Text("Follow the expanding circle. Breathe gently.")
            } else if store.completedSessions > 0 {
                Text("Ready for another calm session.")
            } else {
                Text("Tap Start Session when you are ready.")
            }
        }
        .font(.subheadline)
        .foregroundStyle(ThemeColor.textSecondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
    }

    private var particleBurst: some View {
        ZStack {
            ForEach(0..<10, id: \.self) { index in
                Circle()
                    .fill(ThemeColor.accent.opacity(0.75))
                    .frame(width: 8, height: 8)
                    .offset(
                        x: CGFloat(cos(Double(index) / 10 * .pi * 2)) * 70,
                        y: CGFloat(sin(Double(index) / 10 * .pi * 2)) * 70
                    )
            }
        }
        .frame(height: 40)
    }

    private func startSession() {
        HapticService.medium()
        completedCycles = 0
        showParticles = false
        lastPhase = ""
        sessionStart = Date()
        let t = store.activeBreathTimings
        store.breathCycleDuration = t.inhale + t.hold + t.exhale + t.holdAfter
        withAnimation(.easeInOut(duration: 0.3)) {
            isRunning = true
        }
    }

    private func stopSession(completed: Bool) {
        isRunning = false
        sessionStart = nil
        if completed {
            store.completeBreathingSession(cycles: targetCycles)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showParticles = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showParticles = false
                }
                showQuickMood = true
            }
        } else {
            HapticService.light()
        }
    }

    private struct PhaseProgress {
        enum Phase: String {
            case inhale = "Inhale"
            case hold = "Hold"
            case exhale = "Exhale"
            case holdAfter = "Rest"
        }
        let phase: Phase
        let remaining: Int
        let fraction: Double
        let cycleIndex: Int
    }

    private func phaseProgress(at date: Date) -> PhaseProgress {
        guard isRunning, let start = sessionStart else {
            return PhaseProgress(phase: .inhale, remaining: Int(inhale), fraction: 0, cycleIndex: 0)
        }
        let elapsed = date.timeIntervalSince(start) * speedFactor
        let cycle = max(inhale + hold + exhale + holdAfter, 1)
        let cycleIndex = min(Int(elapsed / cycle), targetCycles - 1)
        let within = elapsed.truncatingRemainder(dividingBy: cycle)

        if within < inhale {
            return PhaseProgress(phase: .inhale, remaining: max(1, Int(ceil(inhale - within))), fraction: within / max(inhale, 0.01), cycleIndex: cycleIndex)
        }
        if within < inhale + hold {
            let local = within - inhale
            return PhaseProgress(phase: .hold, remaining: max(1, Int(ceil(max(hold, 0.01) - local))), fraction: hold > 0 ? local / hold : 1, cycleIndex: cycleIndex)
        }
        if holdAfter <= 0 || within < inhale + hold + exhale {
            let local = max(0, within - inhale - hold)
            return PhaseProgress(phase: .exhale, remaining: max(1, Int(ceil(exhale - local))), fraction: local / max(exhale, 0.01), cycleIndex: cycleIndex)
        }
        let local = within - inhale - hold - exhale
        return PhaseProgress(phase: .holdAfter, remaining: max(1, Int(ceil(holdAfter - local))), fraction: local / holdAfter, cycleIndex: cycleIndex)
    }

    private func circleScale(for progress: PhaseProgress) -> CGFloat {
        switch progress.phase {
        case .inhale:
            return 0.75 + 0.35 * progress.fraction
        case .hold, .holdAfter:
            return progress.phase == .hold ? 1.1 : 0.75
        case .exhale:
            return 1.1 - 0.35 * progress.fraction
        }
    }
}
