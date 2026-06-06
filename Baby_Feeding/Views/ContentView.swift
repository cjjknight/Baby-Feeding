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

// MARK: - Diapers (calm log — no timer / notifications / messaging)

struct DiaperView: View {
    @StateObject private var store = DiaperStore()
    @Environment(\.scenePhase) private var scenePhase
    @State private var showingList = false

    var body: some View {
        VStack(spacing: 28) {
            Text("Diapers")
                .font(.largeTitle).bold()
                .padding(.top, 40)

            HStack(spacing: 48) {
                countColumn(value: store.todayCount(.pee), label: "wet today")
                countColumn(value: store.todayCount(.poop), label: "dirty today")
            }

            HStack(spacing: 24) {
                Button { store.logDiaper(.pee) } label: { logButton("💧", "Pee", .blue) }
                Button { store.logDiaper(.poop) } label: { logButton("💩", "Poop", .brown) }
            }

            Button("View / edit log") { showingList = true }
                .padding(.top, 8)

            Spacer()
        }
        .onAppear { store.syncNow() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { store.syncNow() }
        }
        .sheet(isPresented: $showingList) {
            DiaperListView(store: store)
        }
    }

    private func countColumn(value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text("\(value)").font(.system(size: 48, weight: .bold))
            Text(label).font(.subheadline).foregroundColor(.secondary)
        }
    }

    private func logButton(_ emoji: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 8) {
            Text(emoji).font(.system(size: 44))
            Text(label).font(.headline)
        }
        .frame(width: 130, height: 130)
        .background(color.opacity(0.15))
        .cornerRadius(18)
    }
}

struct DiaperListView: View {
    @ObservedObject var store: DiaperStore
    @State private var editing: Diaper?

    var body: some View {
        NavigationView {
            List {
                ForEach(store.activeDiapers) { diaper in
                    Button(action: { editing = diaper }) {
                        HStack {
                            Text(diaper.kind == .pee ? "💧 Pee" : "💩 Poop")
                            Spacer()
                            Text("\(diaper.date, formatter: dateFormatter)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteDiaper)
            }
            .navigationTitle("Diaper Log")
            .sheet(item: $editing) { diaper in
                DiaperEditView(store: store, diaper: diaper)
            }
        }
    }

    private func deleteDiaper(at offsets: IndexSet) {
        let ids = offsets.map { store.activeDiapers[$0].id }
        for id in ids { store.deleteDiaper(id: id) }
    }
}

struct DiaperEditView: View {
    @ObservedObject var store: DiaperStore
    let diaperID: String
    @State private var date: Date
    @Environment(\.presentationMode) private var presentationMode

    init(store: DiaperStore, diaper: Diaper) {
        self.store = store
        self.diaperID = diaper.id
        _date = State(initialValue: diaper.date)
    }

    var body: some View {
        VStack {
            DatePicker("Time", selection: $date)
                .padding()
            HStack {
                Button("Save") {
                    store.updateDiaper(id: diaperID, to: date)
                    presentationMode.wrappedValue.dismiss()
                }
                .padding()
                Button("Delete") {
                    store.deleteDiaper(id: diaperID)
                    presentationMode.wrappedValue.dismiss()
                }
                .padding()
                .foregroundColor(.red)
            }
        }
        .padding()
    }
}
