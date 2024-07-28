import SwiftUI
import Charts

struct SummaryStatsView: View {
    @Binding var feedingTimes: [Date]
    
    var body: some View {
        ScrollView {
            VStack {
                Text("Summary Stats")
                    .font(.largeTitle)
                    .padding()

                // Number of Meals Graph
                Text("Number of Meals (Past 7 Days)")
                    .font(.headline)
                    .padding(.top)
                Chart {
                    ForEach(summaryStatsByDay().suffix(7), id: \.date) { stat in
                        BarMark(
                            x: .value("Date", stat.date, unit: .day),
                            y: .value("Number of Meals", stat.numberOfMeals)
                        )
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 1)) { value in
                        AxisValueLabel(format: .dateTime.weekday())
                    }
                }
                .frame(height: 200)

                // Percentage of Meals Between 10am and 7pm Graph
                Text("Percentage of Meals Between 10am-7pm (Past 7 Days)")
                    .font(.headline)
                    .padding(.top)
                Chart {
                    ForEach(summaryStatsByDay().suffix(7), id: \.date) { stat in
                        BarMark(
                            x: .value("Date", stat.date, unit: .day),
                            y: .value("Percentage", stat.percentageOfMealsBetween10amAnd7pm)
                        )
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .stride(by: 10)) { value in
                        AxisValueLabel("\(value.as(Int.self) ?? 0)%")
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 1)) { value in
                        AxisValueLabel(format: .dateTime.weekday())
                    }
                }
                .frame(height: 200)

                // Longest Stretch Between Meals Graph
                Text("Longest Stretch Between Meals (Past 7 Days)")
                    .font(.headline)
                    .padding(.top)
                Chart {
                    ForEach(summaryStatsByDay().suffix(7), id: \.date) { stat in
                        BarMark(
                            x: .value("Date", stat.date, unit: .day),
                            y: .value("Hours", stat.longestStretchBetweenMeals)
                        )
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 1)) { value in
                        AxisValueLabel(format: .dateTime.weekday())
                    }
                }
                .frame(height: 200)

                List {
                    ForEach(summaryStatsByDay().reversed(), id: \.date) { stat in
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
                .frame(height: 400) // Limit the height of the list to ensure scrolling works
            }
            .padding()
        }
    }
    
    private func summaryStatsByDay() -> [DailyStats] {
        var dailyStats: [DailyStats] = []
        let calendar = Calendar.current
        
        guard let earliestFeeding = feedingTimes.min() else {
            return dailyStats // Return empty list if no feedings
        }
        
        let startDay = calendar.startOfDay(for: earliestFeeding)
        let endDay = calendar.startOfDay(for: Date())
        
        let daysRange = calendar.dateComponents([.day], from: startDay, to: endDay).day! + 1
        
        // Create date components for each day in the range
        let allDays = (0..<daysRange).map { calendar.date(byAdding: .day, value: $0, to: startDay)! }
        
        // Group feedings by day
        let groupedByDay = Dictionary(grouping: feedingTimes) { (date) -> Date in
            return calendar.startOfDay(for: date)
        }
        
        for day in allDays {
            let feedings = groupedByDay[day, default: []]
            let sortedFeedings = feedings.sorted()
            let numberOfMeals = sortedFeedings.count
            
            // Calculate percentage of meals between 10am and 7pm
            let mealsBetween10amAnd7pm = sortedFeedings.filter { date in
                let hour = calendar.component(.hour, from: date)
                return hour >= 10 && hour < 19
            }.count
            let percentageOfMealsBetween10amAnd7pm = numberOfMeals > 0 ? (Double(mealsBetween10amAnd7pm) / Double(numberOfMeals)) * 100 : 0
            
            // Calculate longest stretch between meals
            var longestStretch: TimeInterval = 0
            if sortedFeedings.count > 1 {
                for i in 1..<sortedFeedings.count {
                    let stretch = sortedFeedings[i].timeIntervalSince(sortedFeedings[i - 1])
                    if stretch > longestStretch {
                        longestStretch = stretch
                    }
                }
            }
            let longestStretchInHours = longestStretch / 3600
            
            let dailyStat = DailyStats(
                date: day,
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
