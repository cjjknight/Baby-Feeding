import SwiftUI
import Contacts

struct ContactSearchView: View {
    @Binding var selectedContacts: [CNContact]
    @Binding var isPresented: Bool
    @State private var searchText = ""
    @State private var searchResults: [CNContact] = []

    var body: some View {
        NavigationView {
            VStack {
                TextField("Search Contacts", text: $searchText, onEditingChanged: { _ in
                    searchContacts()
                })
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())

                List(searchResults, id: \.identifier) { contact in
                    Button(action: {
                        if !selectedContacts.contains(where: { $0.identifier == contact.identifier }) {
                            selectedContacts.append(contact)
                        }
                        isPresented = false
                    }) {
                        VStack(alignment: .leading) {
                            Text("\(contact.givenName) \(contact.familyName)")
                            if let phoneNumber = contact.phoneNumbers.first?.value.stringValue {
                                Text(phoneNumber)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Search Contacts")
            .navigationBarItems(trailing: Button("Cancel") {
                isPresented = false
            })
        }
    }

    private func searchContacts() {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }

        let store = CNContactStore()
        let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
        let predicate = CNContact.predicateForContacts(matchingName: searchText)

        do {
            searchResults = try store.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
        } catch {
            print("Failed to fetch contacts: \(error)")
        }
    }
}
