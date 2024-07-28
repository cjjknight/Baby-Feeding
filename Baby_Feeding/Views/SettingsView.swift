import SwiftUI
import Contacts

struct SettingsView: View {
    @Binding var feedingInterval: Int
    @State private var selectedContacts: [CNContact] = []
    @State private var isShowingContactSearch = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Feeding Interval")) {
                    Picker("Interval (hours)", selection: $feedingInterval) {
                        ForEach(1..<13) { hour in
                            Text("\(hour) hours").tag(hour)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                }

                Section(header: Text("Selected Contacts")) {
                    ForEach(selectedContacts, id: \.identifier) { contact in
                        Text("\(contact.givenName) \(contact.familyName)")
                    }

                    Button(action: {
                        isShowingContactSearch = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Add Contact")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                saveSelectedContacts()
                UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true, completion: nil)
            })
        }
        .onAppear {
            loadSelectedContacts()
        }
        .sheet(isPresented: $isShowingContactSearch) {
            ContactSearchView(selectedContacts: $selectedContacts, isPresented: $isShowingContactSearch)
        }
    }

    private func saveSelectedContacts() {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: selectedContacts, requiringSecureCoding: false)
            UserDefaults.standard.set(data, forKey: "selectedContacts")
            print("Saved contacts: \(selectedContacts.count)")
        } catch {
            print("Failed to save contacts: \(error)")
        }
    }

    private func loadSelectedContacts() {
        if let data = UserDefaults.standard.data(forKey: "selectedContacts"),
           let contacts = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [CNContact] {
            selectedContacts = contacts
            print("Loaded contacts: \(selectedContacts.count)")
        } else {
            print("No contacts to load")
        }
    }
}
