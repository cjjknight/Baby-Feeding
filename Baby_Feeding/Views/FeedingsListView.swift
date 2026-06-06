import SwiftUI

struct FeedingsListView: View {
    @ObservedObject var store: FeedingStore
    @State private var showingAddFeeding = false
    @State private var newFeedingDate = Date()
    @State private var showingEditFeeding = false
    @State private var selectedFeeding: Feeding?

    var body: some View {
        NavigationView {
            List {
                // Add new feeding button at the top
                Button(action: {
                    newFeedingDate = Date()
                    showingAddFeeding.toggle()
                }) {
                    Text("Add New Feeding")
                        .foregroundColor(.blue)
                }
                .sheet(isPresented: $showingAddFeeding) {
                    VStack {
                        DatePicker("Feeding Time", selection: $newFeedingDate)
                        Button("Add") {
                            store.logFeeding(at: newFeedingDate)
                            showingAddFeeding = false
                        }
                    }
                    .padding()
                }

                // Display feeding times, newest first (the store keeps the order)
                ForEach(store.activeFeedings) { feeding in
                    Button(action: {
                        selectedFeeding = feeding
                        showingEditFeeding.toggle()
                    }) {
                        Text("\(feeding.date, formatter: dateFormatter)")
                    }
                }
                .onDelete(perform: deleteFeeding)
            }
            .navigationTitle("Feeding Times")
            .sheet(isPresented: $showingEditFeeding) {
                if let selectedFeeding = selectedFeeding {
                    EditFeedingView(store: store, feeding: selectedFeeding)
                }
            }
        }
    }

    private func deleteFeeding(at offsets: IndexSet) {
        let ids = offsets.map { store.activeFeedings[$0].id }
        for id in ids {
            store.deleteFeeding(id: id)
        }
    }
}
