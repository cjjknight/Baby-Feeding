import SwiftUI
import Combine
import UserNotifications

struct TimerView: View {
    @Binding var feedingTimes: [Date]
    var feedingInterval: Int
    @State private var elapsedTime: String = "00:00:00"
    @State private var timerSubscription: AnyCancellable?
    @State private var buttonColor: Color = .green
    @State private var showingAlert = false

    var body: some View {
        VStack {
            Button(action: {
                let now = Date()
                if let lastFeeding = feedingTimes.last, now.timeIntervalSince(lastFeeding) < 300 {
                    showingAlert = true
                } else {
                    feedingTimes.append(now)
                    saveFeedingTimes()
                    updateElapsedTime()
                    startTimer()
                    scheduleNotification()
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
                loadFeedingTimes()
                updateElapsedTime()
                startTimer()
                scheduleNotification()
            }
            .background(Color.white.ignoresSafeArea())
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UpdateElapsedTime"))) { _ in
                updateElapsedTime()
            }
        }
    }

    private var lastFeedTime: Date? {
        feedingTimes.last
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
        content.body = "It's been \(feedingInterval) hours since the last feeding."
        content.sound = UNNotificationSound.default

        let nextFeedingTime = Calendar.current.date(byAdding: .hour, value: feedingInterval, to: lastFeedTime)!
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: nextFeedingTime.timeIntervalSinceNow, repeats: false)
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }

    private func saveFeedingTimes() {
        let encodedData = try? JSONEncoder().encode(feedingTimes)
        UserDefaults.standard.set(encodedData, forKey: "feedingTimes")
    }

    private func loadFeedingTimes() {
        if let savedData = UserDefaults.standard.data(forKey: "feedingTimes"),
           let decodedTimes = try? JSONDecoder().decode([Date].self, from: savedData) {
            feedingTimes = decodedTimes
        }
    }

    private func updateElapsedTime() {
        guard let lastFeedTime = lastFeedTime else { return }
        let interval = Date().timeIntervalSince(lastFeedTime)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        elapsedTime = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        
        // Update button color based on elapsed time
        if hours >= feedingInterval {
            buttonColor = .red
        } else if hours >= feedingInterval - 1 {
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
                if Int(interval) >= feedingInterval * 3600 {
                    scheduleNotification()
                }
            }
        }
    }
}
