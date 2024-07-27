import SwiftUI

struct SettingsView: View {
    @Binding var feedingInterval: Int

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
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true, completion: nil)
            })
        }
    }
}
