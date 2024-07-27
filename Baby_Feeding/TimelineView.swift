import SwiftUI

struct TimelineView: View {
    @Binding var feedingTimes: [Date]
    var onTimelineTap: () -> Void

    var body: some View {
        let now = Date()
        let startOfTimeline = now.addingTimeInterval(-24 * 3600)
        let mealsInPast24Hours = feedingTimes.filter { $0 >= startOfTimeline }.count
        
        return VStack {
            Text("\(mealsInPast24Hours) Meals in the past 24 hours")
                .font(.subheadline)
                .padding(.bottom, 8)

            GeometryReader { geometry in
                let timelineWidth = geometry.size.width
                let timelineHeight = geometry.size.height
                
                ZStack {
                    // Draw feeding times with bottle images
                    ForEach(feedingTimes.filter { $0 >= startOfTimeline }, id: \.self) { feedingTime in
                        let position = CGFloat(feedingTime.timeIntervalSince(startOfTimeline)) / (24 * 3600) * timelineWidth
                        Image("512")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .position(x: position, y: timelineHeight / 2)
                    }
                }
                .onTapGesture {
                    onTimelineTap()
                }
            }
        }
    }
}
