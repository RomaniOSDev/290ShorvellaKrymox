import SwiftUI

struct ContentView: View {
    @StateObject private var store = AppDataStore.shared
    var body: some View {
        Group {
            if store.hasSeenOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .preferredColorScheme(.dark)
        .environmentObject(store)
        .id(store.appTheme.rawValue)
        .onAppear {
            ReminderService.refreshSchedule()
        }
    }
}
