import SwiftUI

struct SettingsView: View {
    @Binding var feedingInterval: Int
    @State private var phoneNumbers: [String] = UserDefaults.standard.stringArray(forKey: "phoneNumbers") ?? []
    @State private var newPhoneNumber = ""

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

                Section(header: Text("Phone Numbers")) {
                    ForEach(phoneNumbers, id: \.self) { phoneNumber in
                        HStack {
                            Text(phoneNumber)
                            Spacer()
                            Button(action: {
                                if let index = phoneNumbers.firstIndex(of: phoneNumber) {
                                    phoneNumbers.remove(at: index)
                                    savePhoneNumbers()
                                }
                            }) {
                                Image(systemName: "minus.circle")
                                    .foregroundColor(.red)
                            }
                        }
                    }

                    HStack {
                        TextField("New Phone Number", text: $newPhoneNumber)
                            .keyboardType(.phonePad)
                        Button(action: {
                            if !newPhoneNumber.isEmpty && !phoneNumbers.contains(newPhoneNumber) {
                                phoneNumbers.append(newPhoneNumber)
                                savePhoneNumbers()
                                newPhoneNumber = ""
                            }
                        }) {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true, completion: nil)
            })
        }
    }

    private func savePhoneNumbers() {
        UserDefaults.standard.set(phoneNumbers, forKey: "phoneNumbers")
    }
}
