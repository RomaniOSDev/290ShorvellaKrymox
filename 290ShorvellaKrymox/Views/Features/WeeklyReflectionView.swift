import SwiftUI

struct WeeklyReflectionView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    SoftCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Weekly Reflection")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(ThemeColor.textPrimary)
                            Text("A soft look at your last seven days.")
                                .font(.subheadline)
                                .foregroundStyle(ThemeColor.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    SoftCard {
                        Text(store.weeklyReflectionSummary())
                            .font(.body)
                            .foregroundStyle(ThemeColor.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    AccentButtonImage(title: "Done") {
                        store.dismissWeeklyReflection(markSeen: true)
                        dismiss()
                    }
                }
                .padding(16)
            }
            .navigationTitle("Reflection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        store.dismissWeeklyReflection(markSeen: true)
                        dismiss()
                    }
                }
            }
            .toolbarBackground(ThemeColor.surface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .screenBackground()
        }
        .presentationDetents([.medium, .large])
    }
}
