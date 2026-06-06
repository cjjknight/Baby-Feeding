import SwiftUI
import Combine
import UserNotifications
import MessageUI
import Contacts

struct TimerView: View {
    @ObservedObject var store: FeedingStore
    @ObservedObject var dataModel: SharedDataModel
    @State private var elapsedTime: String = "00:00:00"
    @State private var timerSubscription: AnyCancellable?
    @State private var buttonColor: Color = .green
    @State private var showingAlert = false
    @State private var showingMessageComposer = false

    var body: some View {
        VStack {
            Button(action: {
                if let lastFeeding = store.lastFeedingDate, Date().timeIntervalSince(lastFeeding) < 300 {
                    showingAlert = true
                } else {
                    store.logFeeding()
                    updateElapsedTime()
                    startTimer()
                    scheduleNotification()
                    if dataModel.messagingEnabled {
                        sendMessage()
                    }
                }
            }) {
                Text(elapsedTime)
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding()
                    .background(buttonColor)
                    .cornerRadius(10)
            }
            .padding()
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Too Soon"), message: Text("A new feeding cannot be logged within 5 minutes of the last feeding."), dismissButton: .default(Text("OK")))
            }
            .onAppear {
                requestNotificationPermission()
                updateElapsedTime()
                startTimer()
                scheduleNotification()
            }
            .background(Color.white.ignoresSafeArea())
            .onChange(of: store.lastFeedingDate) { _, _ in
                // A manual edit/delete or an incoming sync can change the most
                // recent feeding — recompute the clock and the reminder.
                updateElapsedTime()
                scheduleNotification()
            }
        }
        .sheet(isPresented: $showingMessageComposer) {
            let phoneNumbers = dataModel.selectedContacts.compactMap { $0.phoneNumbers.first?.value.stringValue }
            if !phoneNumbers.isEmpty {
                MessageComposeView(recipients: phoneNumbers, body: "Troy is enjoying a meal in the most natural and healthy way possible. Troy hopes that the sight of him enjoying his meal makes you feel wonder at the awesome design of the human body rather than ashamed because centuries of puritan influences in the USA has stigmatized women's bodies", isPresented: $showingMessageComposer)
            }
        }
    }

    private var lastFeedTime: Date? {
        store.lastFeedingDate
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification permission: \(error)")
            }
        }
    }

    private func scheduleNotification() {
        // Remove all pending notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        guard let lastFeedTime = lastFeedTime else { return }

        let content = UNMutableNotificationContent()
        content.title = "Time to Feed"
        content.body = "It's been \(dataModel.feedingInterval) hours since the last feeding."
        content.sound = UNNotificationSound.default

        let nextFeedingTime = Calendar.current.date(byAdding: .hour, value: dataModel.feedingInterval, to: lastFeedTime)!

        let timeInterval = nextFeedingTime.timeIntervalSinceNow
        guard timeInterval > 0 else { return } // Ensure the time interval is greater than zero

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }

    private func updateElapsedTime() {
        guard let lastFeedTime = lastFeedTime else {
            elapsedTime = "00:00:00"
            buttonColor = .green
            return
        }
        let interval = Date().timeIntervalSince(lastFeedTime)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = (Int(interval) % 60)
        elapsedTime = String(format: "%02d:%02d:%02d", hours, minutes, seconds)

        // Update button color based on elapsed time
        if hours >= dataModel.feedingInterval {
            buttonColor = .red
        } else if hours >= dataModel.feedingInterval - 1 {
            let percentage = Double(minutes) / 60.0
            buttonColor = Color(red: 1.0, green: 1.0 - percentage, blue: 0.0)
        } else {
            let percentage = Double(minutes) / 60.0
            buttonColor = Color(red: percentage, green: 1.0, blue: 0.0)
        }
    }

    private func startTimer() {
        timerSubscription?.cancel()
        timerSubscription = Timer.publish(every: 1, on: .main, in: .common).autoconnect().sink { _ in
            updateElapsedTime()
            if let lastFeedTime = lastFeedTime {
                let interval = Date().timeIntervalSince(lastFeedTime)
                if Int(interval) >= dataModel.feedingInterval * 3600 {
                    scheduleNotification()
                }
            }
        }
    }

    private func sendMessage() {
        let phoneNumbers = dataModel.selectedContacts.compactMap { $0.phoneNumbers.first?.value.stringValue }
        if !phoneNumbers.isEmpty {
            showingMessageComposer = true
        }
    }
}

struct MessageComposeView: UIViewControllerRepresentable {
    var recipients: [String]
    var body: String
    @Binding var isPresented: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.recipients = recipients
        controller.body = body
        controller.messageComposeDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}

    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        var parent: MessageComposeView

        init(_ parent: MessageComposeView) {
            self.parent = parent
        }

        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            parent.isPresented = false
            controller.dismiss(animated: true, completion: nil)
        }
    }
}
