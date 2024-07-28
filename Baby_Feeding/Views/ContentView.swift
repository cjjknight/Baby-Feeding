import SwiftUI

struct ContentView: View {
    @StateObject private var dataModel = SharedDataModel()
    @State private var feedingTimes: [Date] = []
    @State private var showingFeedingsList = false
    @State private var showingSettings = false

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

            TimerView(dataModel: dataModel, feedingTimes: $feedingTimes)
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
            SettingsView(dataModel: dataModel)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
