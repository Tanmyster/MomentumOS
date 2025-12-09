import WidgetKit
import SwiftUI

// MARK: - Widget Data Models
struct WidgetEntry: TimelineEntry {
    let date: Date
    let focusStats: FocusWidgetStats
    let habitStats: HabitWidgetStats
    let moodData: MoodWidgetData
    let configuration: ConfigurationIntent
}

struct FocusWidgetStats: Codable {
    let currentSessionMinutes: Int
    let todaysSessions: Int
    let currentStreak: Int
    let isSessionActive: Bool
}

struct HabitWidgetStats: Codable {
    let completedToday: Int
    let total: Int
    let longestStreak: Int
    let nextHabit: String?
    let completionPercentage: Double
}

struct MoodWidgetData: Codable {
    let todaysMood: String?
    let trend: String
    let emoji: String
}

// MARK: - Widget Configuration Intent
struct ConfigurationIntent: AppIntent, WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "MomentumOS Widget"
    static var description: LocalizedStringResource = "Track your progress at a glance"
    
    @Parameter(title: "Widget Type", default: .habits)
    var widgetType: WidgetTypeOption
}

enum WidgetTypeOption: String, AppEnum {
    case habits = "habits"
    case focus = "focus"
    case mood = "mood"
    case combined = "combined"
    
    var displayName: LocalizedStringResource {
        switch self {
        case .habits: return "Habits"
        case .focus: return "Focus Timer"
        case .mood: return "Mood"
        case .combined: return "Combined"
        }
    }
}

// MARK: - Widget Timeline Provider
struct MomentumWidgetProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry {
        let focusStats = FocusWidgetStats(
            currentSessionMinutes: 15,
            todaysSessions: 1,
            currentStreak: 5,
            isSessionActive: false
        )
        
        let habitStats = HabitWidgetStats(
            completedToday: 3,
            total: 5,
            longestStreak: 12,
            nextHabit: "Meditation",
            completionPercentage: 0.6
        )
        
        let moodData = MoodWidgetData(
            todaysMood: "good",
            trend: "improving",
            emoji: "😊"
        )
        
        return WidgetEntry(
            date: Date(),
            focusStats: focusStats,
            habitStats: habitStats,
            moodData: moodData,
            configuration: ConfigurationIntent()
        )
    }
    
    func recommendations() -> [AppIntentRecommendation<ConfigurationIntent>] {
        [
            AppIntentRecommendation(ConfigurationIntent(widgetType: .habits), description: "Track Daily Habits"),
            AppIntentRecommendation(ConfigurationIntent(widgetType: .focus), description: "Focus Timer Widget"),
            AppIntentRecommendation(ConfigurationIntent(widgetType: .mood), description: "Mood Tracker Widget")
        ]
    }
    
    func timeline(for configuration: ConfigurationIntent, in context: Context) async -> Timeline<WidgetEntry> {
        var entries: [WidgetEntry] = []
        
        let focusStats = getFocusStats()
        let habitStats = getHabitStats()
        let moodData = getMoodData()
        
        // Create entries for the next 4 hours, updating every 15 minutes
        let startDate = Date()
        for offset in 0..<16 {
            let entryDate = startDate.addingTimeInterval(TimeInterval(offset * 15 * 60))
            let entry = WidgetEntry(
                date: entryDate,
                focusStats: focusStats,
                habitStats: habitStats,
                moodData: moodData,
                configuration: configuration
            )
            entries.append(entry)
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        return timeline
    }
    
    private func getFocusStats() -> FocusWidgetStats {
        let focusManager = FocusManager.shared
        return FocusWidgetStats(
            currentSessionMinutes: Int(focusManager.timeRemaining / 60),
            todaysSessions: 1,
            currentStreak: 5,
            isSessionActive: focusManager.isRunning
        )
    }
    
    private func getHabitStats() -> HabitWidgetStats {
        let habitManager = HabitManager.shared
        let completed = habitManager.todaysHabits.filter { habit in
            habit.completedDates.contains(Calendar.current.startOfDay(for: Date()))
        }.count
        
        return HabitWidgetStats(
            completedToday: completed,
            total: habitManager.todaysHabits.count,
            longestStreak: 12,
            nextHabit: habitManager.todaysHabits.first?.name,
            completionPercentage: Double(completed) / Double(max(habitManager.todaysHabits.count, 1))
        )
    }
    
    private func getMoodData() -> MoodWidgetData {
        let moodManager = MoodManager.shared
        let mood = moodManager.todaysMood
        
        return MoodWidgetData(
            todaysMood: mood?.level.rawValue,
            trend: moodManager.moodTrend.rawValue,
            emoji: getMoodEmoji(mood?.level ?? .neutral)
        )
    }
    
    private func getMoodEmoji(_ mood: MoodLevel) -> String {
        switch mood {
        case .terrible: return "😩"
        case .sad: return "😔"
        case .neutral: return "😐"
        case .good: return "😊"
        case .excellent: return "🤩"
        }
    }
}

// MARK: - Small Widget View
struct HabitSmallWidgetView: View {
    let entry: WidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Habits Today")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text("\(entry.habitStats.completedToday)")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("/ \(entry.habitStats.total)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                    
                    Circle()
                        .trim(from: 0, to: entry.habitStats.completionPercentage)
                        .stroke(Color.blue, lineWidth: 3)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(entry.habitStats.completionPercentage * 100))%")
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                .frame(width: 50, height: 50)
            }
            
            Divider()
            
            if let nextHabit = entry.habitStats.nextHabit {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(nextHabit)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Focus Timer Widget View
struct FocusSmallWidgetView: View {
    let entry: WidgetEntry
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Focus Timer")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ZStack {
                Circle()
                    .fill(Color(.systemGray6))
                
                Circle()
                    .trim(from: 0, to: min(Double(entry.focusStats.currentSessionMinutes) / 25, 1.0))
                    .stroke(Color.purple, lineWidth: 4)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 4) {
                    Text("\(entry.focusStats.currentSessionMinutes)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 8) {
                Label("\(entry.focusStats.currentStreak)", systemImage: "flame.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Spacer()
                
                Label("\(entry.focusStats.todaysSessions)", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            .font(.caption)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Mood Widget View
struct MoodSmallWidgetView: View {
    let entry: WidgetEntry
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Today's Mood")
                .font(.caption)
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(entry.moodData.emoji)
                    .font(.system(size: 40))
                
                if let mood = entry.moodData.todaysMood {
                    Text(mood.capitalized)
                        .font(.caption)
                        .fontWeight(.semibold)
                } else {
                    Text("Not logged")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Image(systemName: "arrow.trend.up")
                    .font(.caption)
                    .foregroundColor(.green)
                Text(entry.moodData.trend.capitalized)
                    .font(.caption)
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Combined Widget View
struct CombinedWidgetView: View {
    let entry: WidgetEntry
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Habits mini card
                VStack(alignment: .leading, spacing: 4) {
                    Text("Habits")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    HStack {
                        Text("\(entry.habitStats.completedToday)/\(entry.habitStats.total)")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                
                // Mood mini card
                VStack(alignment: .center, spacing: 4) {
                    Text(entry.moodData.emoji)
                        .font(.system(size: 24))
                    Text(entry.moodData.trend.prefix(3).uppercased())
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                
                // Focus mini card
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Focus")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.red)
                        Text("\(entry.focusStats.currentStreak)")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Widget Bundle
@main
struct MomentumOSWidgets: WidgetBundle {
    var body: some Widget {
        HabitTrackerWidget()
        FocusTimerWidget()
        MoodTrackerWidget()
        CombinedDashboardWidget()
    }
}

// MARK: - Habit Tracker Widget
struct HabitTrackerWidget: Widget {
    let kind: String = "com.momentumos.habit-widget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationIntent.self,
            provider: MomentumWidgetProvider()
        ) { entry in
            HabitSmallWidgetView(entry: entry)
                .containerBackground(.fill, for: .widget)
        }
        .configurationDisplayName("Habit Tracker")
        .description("Track your daily habits")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Focus Timer Widget
struct FocusTimerWidget: Widget {
    let kind: String = "com.momentumos.focus-widget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationIntent.self,
            provider: MomentumWidgetProvider()
        ) { entry in
            FocusSmallWidgetView(entry: entry)
                .containerBackground(.fill, for: .widget)
        }
        .configurationDisplayName("Focus Timer")
        .description("Quick access to focus sessions")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Mood Tracker Widget
struct MoodTrackerWidget: Widget {
    let kind: String = "com.momentumos.mood-widget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationIntent.self,
            provider: MomentumWidgetProvider()
        ) { entry in
            MoodSmallWidgetView(entry: entry)
                .containerBackground(.fill, for: .widget)
        }
        .configurationDisplayName("Mood Tracker")
        .description("Log and track your mood")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Combined Dashboard Widget
struct CombinedDashboardWidget: Widget {
    let kind: String = "com.momentumos.combined-widget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationIntent.self,
            provider: MomentumWidgetProvider()
        ) { entry in
            CombinedWidgetView(entry: entry)
                .containerBackground(.fill, for: .widget)
        }
        .configurationDisplayName("MomentumOS Dashboard")
        .description("All-in-one daily stats")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Widget Preview
#Preview(as: .systemSmall) {
    HabitTrackerWidget()
} timeline: {
    WidgetEntry(
        date: Date(),
        focusStats: FocusWidgetStats(currentSessionMinutes: 15, todaysSessions: 1, currentStreak: 5, isSessionActive: false),
        habitStats: HabitWidgetStats(completedToday: 3, total: 5, longestStreak: 12, nextHabit: "Meditation", completionPercentage: 0.6),
        moodData: MoodWidgetData(todaysMood: "good", trend: "improving", emoji: "😊"),
        configuration: ConfigurationIntent()
    )
}
