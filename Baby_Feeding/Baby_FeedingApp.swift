import SwiftUI

@main
struct BabyFeedingApp: App {
    // Defaults to the Feeding tab. Launch with `-startTab diapers` to open on
    // Diapers (used by the headless simulator verification flow; harmless in
    // normal use).
    @State private var selection: Int = CommandLine.arguments.contains("diapers") ? 1 : 0

    var body: some Scene {
        WindowGroup {
            TabView(selection: $selection) {
                ContentView()
                    .tabItem { Label("Feeding", systemImage: "clock") }
                    .tag(0)
                DiaperView()
                    .tabItem { Label("Diapers", systemImage: "drop") }
                    .tag(1)
            }
        }
    }
}
