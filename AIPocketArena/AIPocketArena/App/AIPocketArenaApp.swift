// AIPocketArenaApp.swift — AI Pocket Arena
// @main entry point with SwiftData container

import SwiftUI
import SwiftData

@main
struct AIPocketArenaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [ConceptProgress.self, UserProfile.self])
    }
}
