import SwiftUI
import Contacts

class SharedDataModel: ObservableObject {
    @Published var feedingInterval: Int
    @Published var selectedContacts: [CNContact] = []

    init(feedingInterval: Int = 4) {
        self.feedingInterval = feedingInterval
        loadSelectedContacts()
    }

    func saveSelectedContacts() {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: selectedContacts, requiringSecureCoding: false)
            UserDefaults.standard.set(data, forKey: "selectedContacts")
            print("Saved contacts: \(selectedContacts.count)")
        } catch {
            print("Failed to save contacts: \(error)")
        }
    }

    func loadSelectedContacts() {
        if let data = UserDefaults.standard.data(forKey: "selectedContacts"),
           let contacts = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [CNContact] {
            selectedContacts = contacts
            print("Loaded contacts: \(selectedContacts.count)")
        } else {
            print("No contacts to load")
        }
    }
}
