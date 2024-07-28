import SwiftUI
import Charts

struct SummaryStatsView: View {
    @Binding var feedingTimes: [Date]
    @State private var chartViewType: ChartViewType = .weekly
    @State private var isFullScreen: Bool = false
    @State private var fullScreenTitle: String = ""

    var body: some View {
        VStack {
            if isFullScreen {
                fullScreenChart
            } else {
                ScrollView {
                    VStack {
                        Text("Summary Stats")
                            .font(.largeTitle)
                            .padding()
                        
                        // Number of Meals Graph
                        chartView(title: "Number of Meals", valueType: .numberOfMeals)
                        
                        // Percentage of Meals Between 10am and 7pm Graph
                        chartView(title: "Percentage of Meals Between 10am-7pm", valueType: .percentageOfMealsBetween10amAnd7pm)
                        
                        // Longest Stretch Between Meals Graph
                        chartView(title: "Longest Stretch Between Meals", valueType: .longestStretchBetweenMeals)
                        
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
        }
        .onChange(of: chartViewType) { _ in
            updateChartData()
        }
    }
    
    private func chartView(title: String, valueType: ChartValueType) -> some View {
        VStack {
            Text("\(title) (\(chartViewType.rawValue.capitalized))")
                .font(.headline)
                .padding(.top)
            Chart {
                ForEach(chartData(), id: \.date) { stat in
                    BarMark(
                        x: .value("Date", stat.date),
                        y: .value(valueType.rawValue, valueType.value(from: stat))
                    )
                }
            }
            .chartXAxis {
                AxisMarks(values: xAxisValues()) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel(xAxisDateFormatter().string(from: date))
                    }
                }
            }
            .frame(height: 200)
            .gesture(
                TapGesture(count: 2)
                    .onEnded {
                        toggleChartViewType()
                    }
                    .simultaneously(with: LongPressGesture(minimumDuration: 0.5)
                        .onEnded { _ in
                            fullScreenTitle = title
                            isFullScreen.toggle()
                        }
                    )
            )
        }
    }
    
    private var fullScreenChart: some View {
        VStack {
            Button(action: {
                isFullScreen = false
            }) {
                Text("Close")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            Spacer()
            Text("\(fullScreenTitle) (\(chartViewType.rawValue.capitalized))")
                .font(.headline)
                .padding(.top)
            chartView(title: fullScreenTitle, valueType: .numberOfMeals)
                .frame(maxHeight: .infinity)
            Spacer()
        }
    }
    
    private func toggleChartViewType() {
        switch chartViewType {
        case .weekly:
            chartViewType = .monthly
        case .monthly:
            chartViewType = .annual
        case .annual:
            chartViewType = .weekly
        }
    }
    
    private func chartData() -> [DailyStats] {
        let stats = summaryStatsByDay()
        switch chartViewType {
        case .weekly:
            return Array(stats.suffix(7))
        case .monthly:
            return Array(stats.suffix(30))
        case .annual:
            return stats
        }
    }
    
    private func updateChartData() {
        // Perform any data updates needed when the chart view type changes
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
    
    private func xAxisValues() -> [Date] {
        let calendar = Calendar.current
        let stats = summaryStatsByDay()
        
        switch chartViewType {
        case .weekly:
            return Array(stats.suffix(7)).map { $0.date }
        case .monthly:
            return Array(stats.suffix(30)).map { $0.date }
        case .annual:
            return stats.filter { stat in
                let month = calendar.component(.month, from: stat.date)
                return month % 3 == 0
            }.map { $0.date }
        }
    }
    
    private func xAxisDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        switch chartViewType {
        case .weekly:
            formatter.dateFormat = "E"
        case .monthly:
            formatter.dateFormat = "M/dd"
        case .annual:
            formatter.dateFormat = "MMM"
        }
        return formatter
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}

enum ChartViewType: String {
    case weekly, monthly, annual
}

enum ChartValueType: String {
    case numberOfMeals = "Number of Meals"
    case percentageOfMealsBetween10amAnd7pm = "Percentage"
    case longestStretchBetweenMeals = "Hours"
    
    func value(from stat: DailyStats) -> Double {
        switch self {
        case .numberOfMeals:
            return Double(stat.numberOfMeals)
        case .percentageOfMealsBetween10amAnd7pm:
            return stat.percentageOfMealsBetween10amAnd7pm
        case .longestStretchBetweenMeals:
            return stat.longestStretchBetweenMeals
        }
    }
}

struct DailyStats {
    let date: Date
    let numberOfMeals: Int
    let percentageOfMealsBetween10amAnd7pm: Double
    let longestStretchBetweenMeals: Double
}
