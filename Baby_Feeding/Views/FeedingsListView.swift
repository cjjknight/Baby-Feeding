import SwiftUI

struct FeedingsListView: View {
    @Binding var feedingTimes: [Date]
    @State private var showingAddFeeding = false
    @State private var newFeedingDate = Date()
    @State private var showingEditFeeding = false
    @State private var selectedFeedingTime: Date?

    var body: some View {
        NavigationView {
            List {
                ForEach(feedingTimes, id: \.self) { feedingTime in
                    Button(action: {
                        selectedFeedingTime = feedingTime
                        showingEditFeeding.toggle()
                    }) {
                        Text("\(feedingTime, formatter: dateFormatter)")
                    }
                }
                .onDelete(perform: deleteFeeding)

                Button(action: {
                    showingAddFeeding.toggle()
                }) {
                    Text("Add Missed Feeding")
                        .foregroundColor(.blue)
                }
                .sheet(isPresented: $showingAddFeeding) {
                    VStack {
                        DatePicker("Feeding Time", selection: $newFeedingDate)
                        Button("Add") {
                            feedingTimes.append(newFeedingDate)
                            feedingTimes.sort()
                            saveFeedingTimes()
                            NotificationCenter.default.post(name: NSNotification.Name("UpdateElapsedTime"), object: nil)
                            showingAddFeeding = false
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Feeding Times")
            .sheet(isPresented: $showingEditFeeding) {
                if let selectedFeedingTime = selectedFeedingTime {
                    EditFeedingView(feedingTimes: $feedingTimes, feedingTime: Binding(
                        get: { selectedFeedingTime },
                        set: { self.selectedFeedingTime = $0 }
                    ))
                }
            }
        }
    }

    private func deleteFeeding(at offsets: IndexSet) {
        feedingTimes.remove(atOffsets: offsets)
        saveFeedingTimes()
        NotificationCenter.default.post(name: NSNotification.Name("UpdateElapsedTime"), object: nil)
    }

    private func saveFeedingTimes() {
        let encodedData = try? JSONEncoder().encode(feedingTimes)
        UserDefaults.standard.set(encodedData, forKey: "feedingTimes")
    }
}
