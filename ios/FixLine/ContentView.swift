import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthManager.self) private var auth
    @Query private var equipment: [Equipment]

    var body: some View {
        Group {
            if auth.isLoading {
                ZStack {
                    Theme.bg.ignoresSafeArea()
                    ProgressView()
                        .controlSize(.large)
                        .tint(Theme.primary)
                }
            } else if auth.user == nil {
                LoginView()
            } else {
                mainTabs
            }
        }
        .tint(Theme.primary)
        .preferredColorScheme(.dark)
    }

    private var mainTabs: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            NavigationStack {
                EquipmentLibraryView()
            }
            .tabItem { Label("Equipment", systemImage: "gearshape.2.fill") }

            NavigationStack {
                VibrationCheckView()
            }
            .tabItem { Label("Vibration", systemImage: "gyroscope") }

            NavigationStack {
                HistoryView()
            }
            .tabItem { Label("History", systemImage: "clock.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "slider.horizontal.3") }
        }
        .task {
            seedIfNeeded()
        }
    }

    private func seedIfNeeded() {
        guard equipment.isEmpty else { return }
        for eq in SeedData.equipment() {
            modelContext.insert(eq)
        }
        try? modelContext.save()
    }
}
