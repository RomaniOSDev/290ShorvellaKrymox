import SwiftUI

struct SoftCard<Content: View>: View {
    var content: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    var body: some View {
        content()
            .padding(16)
            .background(
                LinearGradient(
                    colors: [ThemeColor.surface, ThemeColor.surface.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 8)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [ThemeColor.accent.opacity(0.45), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(Color.white)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .background(CalmButtonFill(isPressed: configuration.isPressed))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(configuration.isPressed ? 0.12 : 0.28),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: ThemeColor.primary.opacity(0.35), radius: configuration.isPressed ? 3 : 8, x: 0, y: configuration.isPressed ? 2 : 5)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.18), value: configuration.isPressed)
    }
}

/// Soft moss/leaf fill — no photo texture, readable on dark UI.
private struct CalmButtonFill: View {
    var isPressed: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    ThemeColor.buttonTop,
                    ThemeColor.buttonMid,
                    ThemeColor.buttonBottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            LinearGradient(
                colors: [
                    Color.white.opacity(isPressed ? 0.06 : 0.18),
                    Color.clear,
                    Color.black.opacity(0.18)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            // Fine vertical grain so the fill feels like soft fabric, not flat neon.
            Canvas { context, size in
                for i in stride(from: 0, to: Int(size.width), by: 3) {
                    let rect = CGRect(x: CGFloat(i), y: 0, width: 1, height: size.height)
                    context.fill(Path(rect), with: .color(Color.white.opacity(0.035)))
                }
            }
            .blendMode(.softLight)
            .allowsHitTesting(false)
        }
    }
}

struct AchievementBanner: View {
    let title: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "star.circle.fill")
                .font(.title2)
                .foregroundStyle(ThemeColor.primary)
            VStack(alignment: .leading, spacing: 2) {
                Text(title == "Streak Freeze Used" ? "Streak Protected" : "Achievement Unlocked")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ThemeColor.textSecondary)
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(ThemeColor.textPrimary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            LinearGradient(colors: [ThemeColor.surface, ThemeColor.background], startPoint: .top, endPoint: .bottom)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.4), radius: 14, y: 8)
        .padding(.horizontal, 16)
    }
}

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String
    let actionTitle: String
    var action: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: symbol)
                .font(.system(size: 58))
                .foregroundStyle(ThemeColor.primary)
                .shadow(color: ThemeColor.primary.opacity(0.45), radius: 14)
            Text(title)
                .font(.headline)
                .foregroundStyle(ThemeColor.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 28)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(ThemeColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button(actionTitle) {
                HapticService.light()
                action()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 40)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct BannerImageCard: View {
    var imageName: String = "img_banner"
    var height: CGFloat = 120

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.35), radius: 10, y: 6)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(ThemeColor.accent.opacity(0.35), lineWidth: 1)
            )
    }
}

struct AccentButtonImage: View {
    var title: String
    var imageName: String = "img_accent"
    var action: () -> Void

    var body: some View {
        Button(action: {
            HapticService.light()
            action()
        }) {
            ZStack {
                CalmButtonFill(isPressed: false)
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.28), Color.white.opacity(0.06)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: ThemeColor.primary.opacity(0.32), radius: 8, y: 5)
        }
        .buttonStyle(.plain)
    }
}
