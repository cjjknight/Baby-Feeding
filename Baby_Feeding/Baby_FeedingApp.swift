import SwiftUI

@main
struct BabyFeedingApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem { Label("Feeding", systemImage: "clock") }
                DiaperView()
                    .tabItem { Label("Diapers", systemImage: "drop") }
            }
        }
    }
}
