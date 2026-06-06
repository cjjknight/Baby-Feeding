import SwiftUI

struct EditFeedingView: View {
    @ObservedObject var store: FeedingStore
    let feedingID: String
    @State private var date: Date
    @Environment(\.presentationMode) private var presentationMode

    init(store: FeedingStore, feeding: Feeding) {
        self.store = store
        self.feedingID = feeding.id
        _date = State(initialValue: feeding.date)
    }

    var body: some View {
        VStack {
            DatePicker("Edit Feeding Time", selection: $date)
                .padding()

            HStack {
                Button("Save") {
                    store.updateFeeding(id: feedingID, to: date)
                    presentationMode.wrappedValue.dismiss()
                }
                .padding()

                Button("Delete") {
                    store.deleteFeeding(id: feedingID)
                    presentationMode.wrappedValue.dismiss()
                }
                .padding()
                .foregroundColor(.red)
            }
        }
        .padding()
    }
}
