import SwiftUI

struct SummaryStatsView: View {
    @Binding var feedingTimes: [Date]
    
    var body: some View {
        VStack {
            Text("Summary Stats")
                .font(.largeTitle)
                .padding()

            List {
                ForEach(summaryStatsByDay(), id: \.date) { stat in
                    VStack(alignment: .leading) {
                        Text("Date: \(stat.date, formatter: dateFormatter)")
                            .font(.headline)
                        Text("Number of Meals: \(stat.numberOfMeals)")
                        Text("Percentage of Meals Between 10am-7pm: \(stat.percentageOfMealsBetween10amAnd7pm, specifier: "%.2f")%")
                        Text("Longest Stretch Between Meals: \(stat.longestStretchBetweenMeals, specifier: "%.2f") hours")
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .padding()
    }
    
    private func summaryStatsByDay() -> [DailyStats] {
        var dailyStats: [DailyStats] = []
        let calendar = Calendar.current
        
        // Group feedings by day
        let groupedByDay = Dictionary(grouping: feedingTimes) { (date) -> Date in
            return calendar.startOfDay(for: date)
        }
        
        for (date, feedings) in groupedByDay {
            let sortedFeedings = feedings.sorted()
            let numberOfMeals = sortedFeedings.count
            
            // Calculate percentage of meals between 10am and 7pm
            let mealsBetween10amAnd7pm = sortedFeedings.filter { date in
                let hour = calendar.component(.hour, from: date)
                return hour >= 10 && hour < 19
            }.count
            let percentageOfMealsBetween10amAnd7pm = (Double(mealsBetween10amAnd7pm) / Double(numberOfMeals)) * 100
            
            // Calculate longest stretch between meals
            var longestStretch: TimeInterval = 0
            for i in 1..<sortedFeedings.count {
                let stretch = sortedFeedings[i].timeIntervalSince(sortedFeedings[i - 1])
                if stretch > longestStretch {
                    longestStretch = stretch
                }
            }
            let longestStretchInHours = longestStretch / 3600
            
            let dailyStat = DailyStats(
                date: date,
                numberOfMeals: numberOfMeals,
                percentageOfMealsBetween10amAnd7pm: percentageOfMealsBetween10amAnd7pm,
                longestStretchBetweenMeals: longestStretchInHours
            )
            dailyStats.append(dailyStat)
        }
        
        return dailyStats
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}

struct DailyStats {
    let date: Date
    let numberOfMeals: Int
    let percentageOfMealsBetween10amAnd7pm: Double
    let longestStretchBetweenMeals: Double
}
