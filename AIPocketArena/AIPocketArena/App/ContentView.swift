// ContentView.swift — AI Pocket Arena
// Root tab navigation: Dashboard, Browse, Settings

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Arena", systemImage: "gamecontroller.fill", value: 0) {
                NavigationStack {
                    DashboardView()
                }
            }

            Tab("Browse", systemImage: "book.fill", value: 1) {
                NavigationStack {
                    ConceptBrowserView()
                }
            }

            Tab("Settings", systemImage: "gearshape.fill", value: 2) {
                NavigationStack {
                    SettingsView()
                }
            }
        }
        .tint(DesignTokens.accent)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [ConceptProgress.self, UserProfile.self], inMemory: true)
}
