import SwiftUI
import Contacts

struct SettingsView: View {
    @ObservedObject var dataModel: SharedDataModel
    @State private var isShowingContactSearch = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Feeding Interval")) {
                    Picker("Interval (hours)", selection: $dataModel.feedingInterval) {
                        ForEach(1..<13) { hour in
                            Text("\(hour) hours").tag(hour)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                }

                Section(header: Text("Selected Contacts")) {
                    List {
                        ForEach(dataModel.selectedContacts, id: \.identifier) { contact in
                            VStack(alignment: .leading) {
                                Text("\(contact.givenName) \(contact.familyName)")
                                if let phoneNumber = contact.phoneNumbers.first?.value.stringValue {
                                    Text(phoneNumber)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .onDelete(perform: deleteContact)
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
                dataModel.saveSelectedContacts()
                UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true, completion: nil)
            })
        }
        .sheet(isPresented: $isShowingContactSearch) {
            ContactSearchView(selectedContacts: $dataModel.selectedContacts, isPresented: $isShowingContactSearch)
        }
    }

    private func deleteContact(at offsets: IndexSet) {
        dataModel.selectedContacts.remove(atOffsets: offsets)
        dataModel.saveSelectedContacts()
    }
}
