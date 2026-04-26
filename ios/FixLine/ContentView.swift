import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var equipment: [Equipment]

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            NavigationStack {
                EquipmentLibraryView()
            }
            .tabItem { Label("Equipment", systemImage: "gearshape.2.fill") }

            NavigationStack {
                HistoryView()
            }
            .tabItem { Label("History", systemImage: "clock.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "slider.horizontal.3") }
        }
        .tint(Theme.primary)
        .preferredColorScheme(.dark)
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
