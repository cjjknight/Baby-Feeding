import SwiftUI

struct EditFeedingView: View {
    @Binding var feedingTimes: [Date]
    @Binding var feedingTime: Date
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        VStack {
            DatePicker("Edit Feeding Time", selection: $feedingTime)
                .padding()

            HStack {
                Button("Save") {
                    if let index = feedingTimes.firstIndex(where: { $0 == feedingTime }) {
                        feedingTimes[index] = feedingTime
                    }
                    feedingTimes.sort()
                    saveFeedingTimes()
                    NotificationCenter.default.post(name: NSNotification.Name("UpdateElapsedTime"), object: nil)
                    presentationMode.wrappedValue.dismiss()
                }
                .padding()

                Button("Delete") {
                    if let index = feedingTimes.firstIndex(where: { $0 == feedingTime }) {
                        feedingTimes.remove(at: index)
                    }
                    saveFeedingTimes()
                    NotificationCenter.default.post(name: NSNotification.Name("UpdateElapsedTime"), object: nil)
                    presentationMode.wrappedValue.dismiss()
                }
                .padding()
                .foregroundColor(.red)
            }
        }
        .padding()
    }

    private func saveFeedingTimes() {
        let encodedData = try? JSONEncoder().encode(feedingTimes)
        UserDefaults.standard.set(encodedData, forKey: "feedingTimes")
    }
}
