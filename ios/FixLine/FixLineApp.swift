import SwiftUI
import SwiftData
import RevenueCat

@main
struct FixLineApp: App {
    @State private var network = NetworkMonitor.shared
    @State private var auth = AuthManager()
    @State private var store = StoreManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Equipment.self, DiagnosticSession.self, ManualDocument.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Theme.bg)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance

        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = UIColor(Theme.surface)
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab

        #if DEBUG
        let rcKey = Config.EXPO_PUBLIC_REVENUECAT_TEST_API_KEY
        #else
        let rcKey = Config.EXPO_PUBLIC_REVENUECAT_IOS_API_KEY
        #endif
        if !rcKey.isEmpty {
            Purchases.configure(withAPIKey: rcKey)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(network)
                .environment(auth)
                .environment(store)
        }
        .modelContainer(sharedModelContainer)
    }
}
