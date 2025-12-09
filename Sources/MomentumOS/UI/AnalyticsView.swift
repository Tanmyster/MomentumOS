import SwiftUI
import Charts

// MARK: - Analytics Manager
@MainActor
class AnalyticsManager: ObservableObject {
    static let shared = AnalyticsManager()
    
    @Published var moodTrendData: [MoodTrendPoint] = []
    @Published var habitCompletionData: [HabitAnalytic] = []
    @Published var workoutStats: [WorkoutAnalytic] = []
    @Published var nutritionData: [NutritionAnalytic] = []
    @Published var sleepData: [SleepAnalytic] = []
    @Published var selectedPeriod: TimePeriod = .week
    @Published var isLoading = false
    
    private let storage = StorageManager.shared
    private let backendAPI = BackendAPIService.shared
    
    // MARK: - Data Models
    struct MoodTrendPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Int
        let trend: String
    }
    
    struct HabitAnalytic: Identifiable {
        let id: UUID
        let name: String
        let completionRate: Double
        let currentStreak: Int
        let bestStreak: Int
        let completionsByDay: [Double]
    }
    
    struct WorkoutAnalytic: Identifiable {
        let id = UUID()
        let date: Date
        let duration: Int
        let calories: Int
        let intensity: String
        let type: String
    }
    
    struct NutritionAnalytic: Identifiable {
        let id = UUID()
        let date: Date
        let calories: Int
        let protein: Int
        let carbs: Int
        let fat: Int
    }
    
    struct SleepAnalytic: Identifiable {
        let id = UUID()
        let date: Date
        let duration: Double
        let quality: Double
    }
    
    // MARK: - Load Analytics Data
    func loadAnalytics() async {
        isLoading = true
        
        await loadMoodTrend()
        await loadHabitAnalytics()
        await loadWorkoutAnalytics()
        await loadNutritionAnalytics()
        await loadSleepAnalytics()
        
        isLoading = false
    }
    
    private func loadMoodTrend() async {
        let days = selectedPeriod.dayCount
        var moodPoints: [MoodTrendPoint] = []
        
        for offset in (0..<days).reversed() {
            let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
            let mood = Int.random(in: 3...5) // Mock data
            
            moodPoints.append(MoodTrendPoint(
                date: date,
                value: mood,
                trend: offset == 0 ? "stable" : (mood > 3 ? "improving" : "declining")
            ))
        }
        
        self.moodTrendData = moodPoints
    }
    
    private func loadHabitAnalytics() async {
        let habitManager = HabitManager.shared
        var analytics: [HabitAnalytic] = []
        
        for habit in habitManager.allHabits {
            let streak = habitManager.getHabitStreak(habit)
            let bestStreak = habitManager.getHabitLongestStreak(habit)
            
            let completionDays = selectedPeriod.dayCount
            var completionByDay: [Double] = []
            
            for offset in (0..<completionDays).reversed() {
                let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
                let isCompleted = habit.completedDates.contains { Calendar.current.isDate($0, inSameDayAs: date) }
                completionByDay.append(isCompleted ? 1.0 : 0.0)
            }
            
            let completionRate = completionByDay.reduce(0, +) / Double(completionDays)
            
            analytics.append(HabitAnalytic(
                id: habit.id,
                name: habit.name,
                completionRate: completionRate,
                currentStreak: streak,
                bestStreak: bestStreak,
                completionsByDay: completionByDay
            ))
        }
        
        self.habitCompletionData = analytics
    }
    
    private func loadWorkoutAnalytics() async {
        let workoutManager = WorkoutManager.shared
        var workoutAnalytics: [WorkoutAnalytic] = []
        
        let days = selectedPeriod.dayCount
        for offset in (0..<days).reversed() {
            let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
            
            do {
                let workouts = try storage.loadWorkoutsForDate(date)
                for workout in workouts {
                    workoutAnalytics.append(WorkoutAnalytic(
                        date: workout.date,
                        duration: workout.duration,
                        calories: Int(workout.estimatedCalories),
                        intensity: workout.intensity.rawValue,
                        type: workout.type.rawValue
                    ))
                }
            } catch {
                continue
            }
        }
        
        self.workoutStats = workoutAnalytics
    }
    
    private func loadNutritionAnalytics() async {
        let foodManager = FoodManager.shared
        var nutritionAnalytics: [NutritionAnalytic] = []
        
        let days = selectedPeriod.dayCount
        for offset in (0..<days).reversed() {
            let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
            
            do {
                let meals = try storage.loadMealsForDate(date)
                let totalCalories = meals.reduce(0) { $0 + meals.count > 0 ? 1800 : 0 }
                let totalProtein = meals.reduce(0) { $0 + meals.count > 0 ? 120 : 0 }
                let totalCarbs = meals.reduce(0) { $0 + meals.count > 0 ? 200 : 0 }
                let totalFat = meals.reduce(0) { $0 + meals.count > 0 ? 60 : 0 }
                
                nutritionAnalytics.append(NutritionAnalytic(
                    date: date,
                    calories: totalCalories,
                    protein: totalProtein,
                    carbs: totalCarbs,
                    fat: totalFat
                ))
            } catch {
                continue
            }
        }
        
        self.nutritionData = nutritionAnalytics
    }
    
    private func loadSleepAnalytics() async {
        let healthKitManager = HealthKitManager.shared
        var sleepAnalytics: [SleepAnalytic] = []
        
        for entry in healthKitManager.sleepData {
            sleepAnalytics.append(SleepAnalytic(
                date: entry.date,
                duration: entry.duration,
                quality: Double.random(in: 0.6...1.0)
            ))
        }
        
        self.sleepData = sleepAnalytics
    }
}

// MARK: - Time Period
enum TimePeriod: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case quarter = "Quarter"
    case year = "Year"
    
    var dayCount: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        case .year: return 365
        }
    }
}

// MARK: - Analytics Views
struct AnalyticsView: View {
    @EnvironmentObject var analyticsManager: AnalyticsManager
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Period Selector
                Picker("Period", selection: $analyticsManager.selectedPeriod) {
                    ForEach(TimePeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                TabView(selection: $selectedTab) {
                    // Mood Analytics
                    MoodAnalyticsView()
                        .tag(0)
                    
                    // Habit Analytics
                    HabitAnalyticsView()
                        .tag(1)
                    
                    // Workout Analytics
                    WorkoutAnalyticsView()
                        .tag(2)
                    
                    // Nutrition Analytics
                    NutritionAnalyticsView()
                        .tag(3)
                    
                    // Sleep Analytics
                    SleepAnalyticsView()
                        .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                
                Spacer()
            }
            .navigationTitle("Analytics")
            .onAppear {
                Task {
                    await analyticsManager.loadAnalytics()
                }
            }
        }
    }
}

// MARK: - Mood Analytics
struct MoodAnalyticsView: View {
    @EnvironmentObject var analyticsManager: AnalyticsManager
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Mood Trend")
                .font(.headline)
                .padding(.horizontal)
            
            if !analyticsManager.moodTrendData.isEmpty {
                Chart {
                    ForEach(analyticsManager.moodTrendData) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Mood", point.value)
                        )
                        .foregroundStyle(by: .value("Trend", point.trend))
                    }
                }
                .chartYScale(domain: 1...5)
                .frame(height: 200)
                .padding()
            } else {
                Text("No mood data available")
                    .foregroundColor(.secondary)
                    .padding()
            }
            
            // Mood Stats
            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Average")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("3.8/5")
                        .font(.headline)
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("Trend")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up")
                            .foregroundColor(.green)
                        Text("Improving")
                            .font(.headline)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding()
            
            Spacer()
        }
    }
}

// MARK: - Habit Analytics
struct HabitAnalyticsView: View {
    @EnvironmentObject var analyticsManager: AnalyticsManager
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Habit Completion")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(analyticsManager.habitCompletionData) { habit in
                        HabitAnalyticCard(habit: habit)
                    }
                }
                .padding()
            }
        }
    }
}

struct HabitAnalyticCard: View {
    let habit: AnalyticsManager.HabitAnalytic
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(habit.name)
                        .font(.headline)
                    HStack(spacing: 16) {
                        Label("\(Int(habit.completionRate * 100))%", systemImage: "percent")
                            .font(.caption)
                        Label("\(habit.currentStreak) days", systemImage: "flame.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Best")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(habit.bestStreak)")
                        .font(.headline)
                }
            }
            
            // Completion heatmap
            Chart {
                ForEach(Array(habit.completionsByDay.enumerated()), id: \.offset) { offset, completion in
                    BarMark(
                        x: .value("Day", offset),
                        y: .value("Completion", completion)
                    )
                    .foregroundStyle(completion > 0 ? Color.green : Color.gray.opacity(0.3))
                }
            }
            .frame(height: 60)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Workout Analytics
struct WorkoutAnalyticsView: View {
    @EnvironmentObject var analyticsManager: AnalyticsManager
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Workout Summary")
                .font(.headline)
                .padding(.horizontal)
            
            // Summary Stats
            HStack(spacing: 12) {
                StatCard(
                    title: "Workouts",
                    value: "\(analyticsManager.workoutStats.count)",
                    icon: "dumbbell.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Duration",
                    value: "\(analyticsManager.workoutStats.reduce(0) { $0 + $1.duration })m",
                    icon: "clock.fill",
                    color: .purple
                )
                
                StatCard(
                    title: "Calories",
                    value: "\(analyticsManager.workoutStats.reduce(0) { $0 + $1.calories })",
                    icon: "flame.fill",
                    color: .orange
                )
            }
            .padding()
            
            // Workout type breakdown
            if !analyticsManager.workoutStats.isEmpty {
                Text("By Type")
                    .font(.headline)
                    .padding(.horizontal)
                
                Chart {
                    ForEach(Dictionary(grouping: analyticsManager.workoutStats, by: { $0.type }).sorted(by: { $0.key < $1.key }), id: \.key) { type, workouts in
                        SectorMark(
                            angle: .relative(Double(workouts.count)),
                            innerRadius: .ratio(0.6),
                            angularInset: 1.5
                        )
                        .foregroundStyle(by: .value("Type", type))
                        .opacity(0.8)
                    }
                }
                .frame(height: 200)
                .padding()
            }
            
            Spacer()
        }
    }
}

// MARK: - Nutrition Analytics
struct NutritionAnalyticsView: View {
    @EnvironmentObject var analyticsManager: AnalyticsManager
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Nutrition Overview")
                .font(.headline)
                .padding(.horizontal)
            
            if !analyticsManager.nutritionData.isEmpty {
                // Calorie intake chart
                Chart {
                    ForEach(analyticsManager.nutritionData) { data in
                        LineMark(
                            x: .value("Date", data.date),
                            y: .value("Calories", data.calories)
                        )
                        .foregroundStyle(.blue)
                    }
                }
                .frame(height: 180)
                .padding()
                
                // Macro breakdown
                VStack(spacing: 12) {
                    Text("Today's Macros")
                        .font(.headline)
                    
                    if let latest = analyticsManager.nutritionData.last {
                        MacroBar(
                            name: "Protein",
                            value: latest.protein,
                            max: 150,
                            color: .red
                        )
                        
                        MacroBar(
                            name: "Carbs",
                            value: latest.carbs,
                            max: 250,
                            color: .blue
                        )
                        
                        MacroBar(
                            name: "Fat",
                            value: latest.fat,
                            max: 65,
                            color: .yellow
                        )
                    }
                }
                .padding()
            }
            
            Spacer()
        }
    }
}

struct MacroBar: View {
    let name: String
    let value: Int
    let max: Int
    let color: Color
    
    var percentage: Double {
        Double(value) / Double(max)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name)
                    .font(.caption)
                Spacer()
                Text("\(value)g")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * min(percentage, 1.0))
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Sleep Analytics
struct SleepAnalyticsView: View {
    @EnvironmentObject var analyticsManager: AnalyticsManager
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Sleep Tracking")
                .font(.headline)
                .padding(.horizontal)
            
            if !analyticsManager.sleepData.isEmpty {
                Chart {
                    ForEach(analyticsManager.sleepData) { sleep in
                        BarMark(
                            x: .value("Date", sleep.date),
                            y: .value("Duration", sleep.duration)
                        )
                        .foregroundStyle(sleep.duration >= 7 ? Color.green : Color.orange)
                    }
                }
                .frame(height: 200)
                .padding()
                
                // Sleep stats
                HStack(spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("Average")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        let avgSleep = analyticsManager.sleepData.reduce(0) { $0 + $1.duration } / Double(analyticsManager.sleepData.count)
                        Text(String(format: "%.1f h", avgSleep))
                            .font(.headline)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Best Night")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let best = analyticsManager.sleepData.max(by: { $0.duration < $1.duration }) {
                            Text(String(format: "%.1f h", best.duration))
                                .font(.headline)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding()
            }
            
            Spacer()
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.headline)
            }
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Weekly Report
struct WeeklyReportView: View {
    @EnvironmentObject var analyticsManager: AnalyticsManager
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Weekly Report")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                ReportSection(
                    title: "Habits",
                    icon: "checkmark.circle.fill",
                    color: .green,
                    stat1: ("Completion", "78%"),
                    stat2: ("Current Streak", "5 days")
                )
                
                ReportSection(
                    title: "Workouts",
                    icon: "dumbbell.fill",
                    color: .blue,
                    stat1: ("Sessions", "4"),
                    stat2: ("Duration", "340 min")
                )
                
                ReportSection(
                    title: "Mood",
                    icon: "heart.fill",
                    color: .red,
                    stat1: ("Average", "3.8/5"),
                    stat2: ("Trend", "Improving ↗")
                )
                
                ReportSection(
                    title: "Sleep",
                    icon: "moon.stars.fill",
                    color: .purple,
                    stat1: ("Average", "7.2 hours"),
                    stat2: ("Quality", "Good")
                )
            }
            .padding()
        }
    }
}

struct ReportSection: View {
    let title: String
    let icon: String
    let color: Color
    let stat1: (String, String)
    let stat2: (String, String)
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(stat1.0)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(stat1.1)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(stat2.0)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(stat2.1)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
