import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var selected = 0

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $selected) {
                MoodMomentView()
                    .tabItem { Label("Mood", systemImage: "face.smiling") }
                    .tag(0)
                MindfulBreathingView()
                    .tabItem { Label("Breathe", systemImage: "wind") }
                    .tag(1)
                FocusTimerView()
                    .tabItem { Label("Focus", systemImage: "timer") }
                    .tag(2)
                StatsView()
                    .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
                    .tag(3)
                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                    .tag(4)
            }
            .tint(ThemeColor.primary)

            if let title = store.bannerTitle {
                AchievementBanner(title: title)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
                    .zIndex(10)
            }

            if store.showSuccessFlash {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(ThemeColor.accent)
                    .shadow(color: ThemeColor.accent.opacity(0.55), radius: 16)
                    .transition(.scale.combined(with: .opacity))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .allowsHitTesting(false)
                    .zIndex(9)
            }
        }
        .onAppear {
            applyChrome()
            store.refreshFreezeWeekIfNeeded()
            store.checkWeeklyReflection()
        }
        .onChange(of: store.appTheme) { _ in
            applyChrome()
        }
        .sheet(isPresented: $store.showWeeklyReflection) {
            WeeklyReflectionView()
                .environmentObject(store)
        }
    }

    private func applyChrome() {
        let surface = UIColor(ThemeColor.surface)
        let text = UIColor(ThemeColor.textPrimary)

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = surface
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance

        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = surface
        nav.titleTextAttributes = [.foregroundColor: text]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
    }
}
