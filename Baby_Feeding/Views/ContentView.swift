import SwiftUI

struct ContentView: View {
    @StateObject private var store = FeedingStore()
    @StateObject private var dataModel = SharedDataModel()
    @Environment(\.scenePhase) private var scenePhase
    @State private var showingFeedingsList = false
    @State private var showingSettings = false
    @State private var showingSummaryStats = false

    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    showingSummaryStats.toggle()
                }) {
                    Image(systemName: "chart.bar")
                        .font(.title)
                        .padding()
                }
                Spacer()
                Button(action: {
                    showingSettings.toggle()
                }) {
                    Image(systemName: "gear")
                        .font(.title)
                        .padding()
                }
            }
            Spacer()
            Text("🤱")
                .font(.system(size: 110))
                .frame(width: 150, height: 150)
                .padding(.bottom, 40)

            TimerView(store: store, dataModel: dataModel)
            Spacer()

            TimelineView(feedingTimes: store.activeDates) {
                showingFeedingsList.toggle()
            }
            .frame(height: 100)
            .padding([.leading, .trailing, .bottom])
            .sheet(isPresented: $showingFeedingsList) {
                FeedingsListView(store: store)
            }
        }
        .onAppear { store.syncNow() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { store.syncNow() }
        }
        .sheet(isPresented: $showingSummaryStats) {
            SummaryStatsView(feedingTimes: store.activeDates)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(dataModel: dataModel)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
