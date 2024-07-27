import SwiftUI

struct ContentView: View {
    @State private var feedingTimes: [Date] = []
    @State private var showingFeedingsList = false
    @State private var showingSettings = false
    @AppStorage("feedingInterval") private var feedingInterval: Int = 3 // Default to 3 hours

    var body: some View {
        VStack {
            HStack {
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
            Image("babyBottle")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .padding(.bottom, 40)

            TimerView(feedingTimes: $feedingTimes, feedingInterval: feedingInterval) // Pass the wrapped value
            Spacer()

            TimelineView(feedingTimes: $feedingTimes) {
                showingFeedingsList.toggle()
            }
            .frame(height: 100)
            .padding([.leading, .trailing, .bottom])
            .sheet(isPresented: $showingFeedingsList) {
                FeedingsListView(feedingTimes: $feedingTimes)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(feedingInterval: $feedingInterval) // Pass the binding for settings
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
