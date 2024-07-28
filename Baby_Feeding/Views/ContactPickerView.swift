import SwiftUI
import ContactsUI

struct ContactPickerView: UIViewControllerRepresentable {
    @Binding var selectedContacts: [CNContact]
    @Binding var isPresented: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let contactPicker = CNContactPickerViewController()
        contactPicker.delegate = context.coordinator
        return contactPicker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    class Coordinator: NSObject, CNContactPickerDelegate {
        var parent: ContactPickerView

        init(_ parent: ContactPickerView) {
            self.parent = parent
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
            parent.selectedContacts.append(contentsOf: contacts)
            parent.isPresented = false
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            parent.isPresented = false
        }
    }
}
