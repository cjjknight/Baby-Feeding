import SwiftUI
import Contacts

class SharedDataModel: ObservableObject {
    @Published var feedingInterval: Int {
        didSet { UserDefaults.standard.set(feedingInterval, forKey: "feedingInterval") }
    }
    @Published var selectedContacts: [CNContact] = []
    /// When off (the default), logging a feeding never opens Messages. Opt-in
    /// in Settings keeps the "announce the feeding" feature available without
    /// interrupting every tap.
    @Published var messagingEnabled: Bool {
        didSet { UserDefaults.standard.set(messagingEnabled, forKey: "messagingEnabled") }
    }

    init(feedingInterval defaultInterval: Int = 4) {
        let savedInterval = UserDefaults.standard.object(forKey: "feedingInterval") as? Int
        self.feedingInterval = savedInterval ?? defaultInterval
        self.messagingEnabled = UserDefaults.standard.bool(forKey: "messagingEnabled") // defaults to false
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
