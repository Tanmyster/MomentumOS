import Foundation
import AppIntents

// MARK: - Siri Shortcuts
struct StartFocusSessionShortcut: AppIntent {
    static var title: LocalizedStringResource = "Start Focus Session"
    static var description: LocalizedStringResource = "Start a new focus session"
    static var openAppWhenRun = true
    
    @Parameter(title: "Title", description: "Session title")
    var sessionTitle: String = "Focus Time"
    
    @Parameter(title: "Duration", description: "Session duration in minutes", default: 25)
    var duration: Int = 25
    
    @Parameter(title: "Category", description: "Focus category")
    var category: String = "work"
    
    func perform() async throws -> some IntentResult {
        let focusManager = FocusManager.shared
        let durationInterval = TimeInterval(duration * 60)
        
        let focusCategory = FocusCategory(rawValue: category) ?? .work
        focusManager.startFocusSession(title: sessionTitle, duration: durationInterval, category: focusCategory)
        
        return .result(value: "Started \(duration)-minute focus session: \(sessionTitle)")
    }
}

struct LogMoodShortcut: AppIntent {
    static var title: LocalizedStringResource = "Log Mood"
    static var description: LocalizedStringResource = "Log your current mood"
    static var openAppWhenRun = true
    
    @Parameter(title: "Mood", description: "Your current mood")
    var mood: String = "good"
    
    @Parameter(title: "Energy", description: "Energy level (1-10)", default: 5)
    var energy: Int = 5
    
    @Parameter(title: "Stress", description: "Stress level (1-10)", default: 5)
    var stress: Int = 5
    
    @Parameter(title: "Notes", description: "Optional notes")
    var notes: String = ""
    
    func perform() async throws -> some IntentResult {
        let moodManager = MoodManager.shared
        let moodLevel = MoodLevel(rawValue: mood) ?? .good
        
        moodManager.logMood(
            level: moodLevel,
            energy: energy,
            stress: stress,
            sleep: 0,
            triggers: []
        )
        
        return .result(value: "Mood logged: \(mood)")
    }
}

struct LogHabitShortcut: AppIntent {
    static var title: LocalizedStringResource = "Log Habit"
    static var description: LocalizedStringResource = "Mark a habit as completed"
    static var openAppWhenRun = true
    
    @Parameter(title: "Habit", description: "Habit to log")
    var habitName: String
    
    func perform() async throws -> some IntentResult {
        let habitManager = HabitManager.shared
        let habits = try? await Task {
            habitManager.loadAllHabits()
        }.value
        
        if let habit = habits?.first(where: { $0.name == habitName }) {
            habitManager.toggleHabit(habit)
            return .result(value: "Logged habit: \(habitName)")
        }
        
        return .result(value: "Habit not found: \(habitName)")
    }
}

struct LogWorkoutShortcut: AppIntent {
    static var title: LocalizedStringResource = "Start Workout"
    static var description: LocalizedStringResource = "Start a new workout session"
    static var openAppWhenRun = true
    
    @Parameter(title: "Workout Type", description: "Type of workout")
    var workoutType: String = "strength"
    
    @Parameter(title: "Intensity", description: "Workout intensity")
    var intensity: String = "moderate"
    
    func perform() async throws -> some IntentResult {
        let workoutManager = WorkoutManager.shared
        let type = WorkoutType(rawValue: workoutType) ?? .strength
        let level = Intensity(rawValue: intensity) ?? .moderate
        
        workoutManager.startWorkout(type: type, intensity: level)
        
        return .result(value: "Started \(workoutType) workout")
    }
}

struct StartMorningRoutineShortcut: AppIntent {
    static var title: LocalizedStringResource = "Start Morning Routine"
    static var description: LocalizedStringResource = "Begin your morning routine"
    static var openAppWhenRun = true
    
    func perform() async throws -> some IntentResult {
        let routineManager = RoutineManager.shared
        
        if let morningRoutine = routineManager.morningRoutine {
            routineManager.startRoutine(morningRoutine)
            return .result(value: "Morning routine started!")
        }
        
        return .result(value: "No morning routine configured")
    }
}

struct StartEveningRoutineShortcut: AppIntent {
    static var title: LocalizedStringResource = "Start Evening Routine"
    static var description: LocalizedStringResource = "Begin your evening routine"
    static var openAppWhenRun = true
    
    func perform() async throws -> some IntentResult {
        let routineManager = RoutineManager.shared
        
        if let eveningRoutine = routineManager.eveningRoutine {
            routineManager.startRoutine(eveningRoutine)
            return .result(value: "Evening routine started!")
        }
        
        return .result(value: "No evening routine configured")
    }
}

struct LogMealShortcut: AppIntent {
    static var title: LocalizedStringResource = "Log Meal"
    static var description: LocalizedStringResource = "Log a meal for today"
    static var openAppWhenRun = true
    
    @Parameter(title: "Meal Type", description: "Type of meal")
    var mealType: String = "lunch"
    
    @Parameter(title: "Calories", description: "Estimated calories", default: 500)
    var calories: Int = 500
    
    func perform() async throws -> some IntentResult {
        let foodManager = FoodManager.shared
        let type = MealType(rawValue: mealType) ?? .lunch
        
        let foodItem = FoodItem(id: UUID(), name: "Custom Meal", calories: Double(calories), protein: 0, carbs: 0, fat: 0)
        foodManager.addMeal(type: type, foods: [foodItem])
        
        return .result(value: "Logged \(mealType) - \(calories) calories")
    }
}

struct GetDailyStatsShortcut: AppIntent {
    static var title: LocalizedStringResource = "Get Daily Stats"
    static var description: LocalizedStringResource = "Get today's statistics"
    
    func perform() async throws -> some IntentResult {
        let habitManager = HabitManager.shared
        let foodManager = FoodManager.shared
        
        let stats = """
        Today's Stats:
        - Habits: \(habitManager.todaysHabits.filter { $0.completedDates.contains(Date()) }.count)/\(habitManager.todaysHabits.count)
        - Calories: \(Int(foodManager.dailyNutritionSummary.calories))
        - Mood: \(habitManager.todaysHabits.count > 0 ? "Tracked" : "Not logged")
        """
        
        return .result(value: stats)
    }
}

struct GetStreakInfoShortcut: AppIntent {
    static var title: LocalizedStringResource = "Get Streak"
    static var description: LocalizedStringResource = "Check your current streaks"
    
    @Parameter(title: "Habit", description: "Habit to check")
    var habitName: String
    
    func perform() async throws -> some IntentResult {
        let habitManager = HabitManager.shared
        let habits = try? await Task {
            habitManager.loadAllHabits()
        }.value
        
        if let habit = habits?.first(where: { $0.name == habitName }) {
            let streak = habitManager.getHabitStreak(habit)
            return .result(value: "Current streak: \(streak) days")
        }
        
        return .result(value: "Habit not found")
    }
}

// MARK: - Siri Shortcuts Container
struct MomentumOSShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        [
            AppShortcut(
                intent: StartFocusSessionShortcut(),
                phrases: [
                    "Start a focus session in \(.applicationName)",
                    "Begin focus session in \(.applicationName)",
                    "Start focus in \(.applicationName)"
                ],
                shortTitle: "Start Focus",
                systemImageName: "clock.fill"
            ),
            
            AppShortcut(
                intent: LogMoodShortcut(),
                phrases: [
                    "Log my mood in \(.applicationName)",
                    "Track my mood in \(.applicationName)",
                    "How am I feeling in \(.applicationName)"
                ],
                shortTitle: "Log Mood",
                systemImageName: "heart.fill"
            ),
            
            AppShortcut(
                intent: LogHabitShortcut(),
                phrases: [
                    "Complete my habit in \(.applicationName)",
                    "Log habit in \(.applicationName)",
                    "Check off habit in \(.applicationName)"
                ],
                shortTitle: "Log Habit",
                systemImageName: "checkmark.circle.fill"
            ),
            
            AppShortcut(
                intent: LogWorkoutShortcut(),
                phrases: [
                    "Start workout in \(.applicationName)",
                    "Begin exercise in \(.applicationName)",
                    "Log workout in \(.applicationName)"
                ],
                shortTitle: "Start Workout",
                systemImageName: "dumbbell.fill"
            ),
            
            AppShortcut(
                intent: StartMorningRoutineShortcut(),
                phrases: [
                    "Start morning routine in \(.applicationName)",
                    "Begin my morning in \(.applicationName)",
                    "Morning ritual in \(.applicationName)"
                ],
                shortTitle: "Morning Routine",
                systemImageName: "sunrise.fill"
            ),
            
            AppShortcut(
                intent: StartEveningRoutineShortcut(),
                phrases: [
                    "Start evening routine in \(.applicationName)",
                    "Begin my evening in \(.applicationName)",
                    "Evening ritual in \(.applicationName)"
                ],
                shortTitle: "Evening Routine",
                systemImageName: "moon.stars.fill"
            ),
            
            AppShortcut(
                intent: LogMealShortcut(),
                phrases: [
                    "Log my meal in \(.applicationName)",
                    "Track meal in \(.applicationName)",
                    "Log food in \(.applicationName)"
                ],
                shortTitle: "Log Meal",
                systemImageName: "fork.knife"
            ),
            
            AppShortcut(
                intent: GetDailyStatsShortcut(),
                phrases: [
                    "What's my status in \(.applicationName)",
                    "Show my stats in \(.applicationName)",
                    "Daily summary in \(.applicationName)"
                ],
                shortTitle: "Daily Stats",
                systemImageName: "chart.bar.fill"
            ),
            
            AppShortcut(
                intent: GetStreakInfoShortcut(),
                phrases: [
                    "Check my streak in \(.applicationName)",
                    "How long is my streak in \(.applicationName)",
                    "Streak status in \(.applicationName)"
                ],
                shortTitle: "Check Streak",
                systemImageName: "flame.fill"
            )
        ]
    }
}
