import Foundation

// MARK: - User Profile
struct User: Codable, Identifiable {
    var id: UUID = UUID()
    var email: String
    var name: String
    var profileImage: Data?
    var bio: String = ""
    var birthDate: Date?
    var gender: Gender?
    var goals: [Goal] = []
    var createdAt: Date = Date()
    var isPremium: Bool = false
    var premiumExpiresAt: Date?
    var theme: ThemePreference = .auto
}

enum Gender: String, Codable {
    case male, female, other, preferNotToSay
}

enum ThemePreference: String, Codable {
    case light, dark, auto
}

struct Goal: Codable, Identifiable {
    var id: UUID = UUID()
    var category: GoalCategory
    var title: String
    var description: String?
    var targetValue: Double?
    var currentValue: Double = 0
    var timeframe: TimeInterval
    var createdAt: Date = Date()
    var completedAt: Date?
    var priority: Priority = .medium
}

enum GoalCategory: String, Codable {
    case fitness, productivity, nutrition, mentalHealth, relationships, sleep
}

enum Priority: String, Codable {
    case low, medium, high, critical
}

// MARK: - Habit & Mood Tracking
struct Habit: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var description: String?
    var category: HabitCategory
    var frequency: HabitFrequency = .daily
    var createdAt: Date = Date()
    var isActive: Bool = true
    var color: String = "purple"
    var icon: String = "star.fill"
    var logs: [HabitLog] = []
    
    var currentStreak: Int {
        calculateStreak()
    }
    
    var longestStreak: Int {
        calculateLongestStreak()
    }
    
    private func calculateStreak() -> Int {
        let sortedLogs = logs.sorted { $0.date > $1.date }
        var streak = 0
        let calendar = Calendar.current
        var checkDate = calendar.startOfDay(for: Date())
        
        for log in sortedLogs {
            let logDate = calendar.startOfDay(for: log.date)
            if logDate == checkDate && log.completed {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
        }
        return streak
    }
    
    private func calculateLongestStreak() -> Int {
        let sortedLogs = logs.sorted { $0.date > $1.date }
        var longestStreak = 0
        var currentStreak = 0
        let calendar = Calendar.current
        var previousDate: Date?
        
        for log in sortedLogs.reversed() {
            if log.completed {
                if let previous = previousDate {
                    let dayDifference = calendar.dateComponents([.day], from: log.date, to: previous).day ?? 0
                    if dayDifference == 1 {
                        currentStreak += 1
                    } else {
                        longestStreak = max(longestStreak, currentStreak)
                        currentStreak = 1
                    }
                } else {
                    currentStreak = 1
                }
                previousDate = log.date
            }
        }
        return max(longestStreak, currentStreak)
    }
}

enum HabitCategory: String, Codable {
    case fitness, nutrition, productivity, meditation, reading, hydration, sleep, gratitude, exercise, other
}

enum HabitFrequency: String, Codable {
    case daily, weekly, monthly
}

struct HabitLog: Codable, Identifiable {
    var id: UUID = UUID()
    var habitId: UUID
    var date: Date = Date()
    var completed: Bool = true
    var notes: String?
}

struct MoodEntry: Codable, Identifiable {
    var id: UUID = UUID()
    var date: Date = Date()
    var mood: MoodLevel
    var energy: Int = 5 // 1-10
    var stress: Int = 5 // 1-10
    var sleep: Int = 7 // hours
    var notes: String?
    var triggers: [String] = []
}

enum MoodLevel: String, Codable {
    case terrible = "😢"
    case sad = "😟"
    case neutral = "😐"
    case good = "😊"
    case excellent = "🤩"
}

// MARK: - Focus & Timer
struct FocusSession: Codable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var duration: TimeInterval
    var startTime: Date
    var endTime: Date?
    var completed: Bool = false
    var category: FocusCategory = .work
    var notes: String?
}

enum FocusCategory: String, Codable {
    case work, study, creative, health, personal, other
}

struct PomodoroTimer: Codable {
    var workDuration: TimeInterval = 25 * 60
    var breakDuration: TimeInterval = 5 * 60
    var longBreakDuration: TimeInterval = 15 * 60
    var sessionsBeforeLongBreak: Int = 4
}

// MARK: - Workout & Recovery
struct WorkoutLog: Codable, Identifiable {
    var id: UUID = UUID()
    var date: Date = Date()
    var type: WorkoutType
    var duration: TimeInterval // in seconds
    var intensity: Intensity = .moderate
    var caloriesBurned: Double?
    var exercises: [Exercise] = []
    var notes: String?
    var recoveryNotes: String?
}

enum WorkoutType: String, Codable {
    case cardio, strength, flexibility, sports, other
}

enum Intensity: String, Codable {
    case light, moderate, high, veryHigh
}

struct Exercise: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var muscleGroup: MuscleGroup
    var sets: [ExerciseSet] = []
    var notes: String?
}

enum MuscleGroup: String, Codable {
    case chest, back, shoulders, biceps, triceps, forearms, legs, quadriceps, hamstrings, glutes, calves, core, full
}

struct ExerciseSet: Codable, Identifiable {
    var id: UUID = UUID()
    var reps: Int?
    var weight: Double? // in pounds
    var duration: TimeInterval? // in seconds
    var notes: String?
}

struct RecoveryData: Codable {
    var date: Date = Date()
    var sleepHours: Double = 0
    var sleepQuality: Int = 5 // 1-10
    var soreness: Int = 5 // 1-10
    var motivation: Int = 5 // 1-10
    var notes: String?
}

// MARK: - Food Tracking
struct MealLog: Codable, Identifiable {
    var id: UUID = UUID()
    var date: Date = Date()
    var mealType: MealType
    var foods: [FoodItem] = []
    var totalCalories: Double = 0
    var totalProtein: Double = 0
    var totalCarbs: Double = 0
    var totalFat: Double = 0
    var notes: String?
    var mood: MoodLevel?
    var energyAfter: Int? // 1-10
}

enum MealType: String, Codable {
    case breakfast, lunch, dinner, snack, other
}

struct FoodItem: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var quantity: Double
    var unit: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var barcode: String?
    var imageData: Data?
    var nutrients: [String: Double]?
}

// MARK: - Calendar & Tasks
struct Task: Codable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var description: String?
    var dueDate: Date?
    var startDate: Date = Date()
    var category: TaskCategory = .general
    var priority: Priority = .medium
    var quadrant: EisenhowerQuadrant = .important
    var isCompleted: Bool = false
    var completedAt: Date?
    var estimatedDuration: TimeInterval?
    var tags: [String] = []
}

enum TaskCategory: String, Codable {
    case general, work, health, personal, learning, relationships
}

enum EisenhowerQuadrant: String, Codable {
    case important, notImportant
}

struct TimeBlock: Codable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var startTime: Date
    var endTime: Date
    var category: FocusCategory = .work
    var isRecurring: Bool = false
    var notes: String?
}

struct Routine: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var description: String?
    var timeOfDay: RoutineTime
    var tasks: [RoutineTask] = []
    var estimatedDuration: TimeInterval?
    var isActive: Bool = true
}

enum RoutineTime: String, Codable {
    case morning, afternoon, evening, night, custom
}

struct RoutineTask: Codable, Identifiable {
    var id: UUID = UUID()
    var title: String
    var duration: TimeInterval?
    var order: Int
}

// MARK: - Motivation
struct MotivationEntry: Codable, Identifiable {
    var id: UUID = UUID()
    var date: Date = Date()
    var type: MotivationType
    var content: String
    var author: String?
    var category: MotivationCategory = .general
    var isCustom: Bool = false
}

enum MotivationType: String, Codable {
    case quote, affirmation, tip, challenge, milestone
}

enum MotivationCategory: String, Codable {
    case fitness, productivity, mindfulness, resilience, gratitude, relationships, learning, general
}

struct Affirmation: Codable, Identifiable {
    var id: UUID = UUID()
    var text: String
    var category: MotivationCategory = .general
    var isCustom: Bool = false
    var daysTested: Int = 0
}

// MARK: - AI Coach Requests/Responses
struct AICoachRequest: Codable {
    var userId: UUID
    var type: AICoachType
    var context: [String: String]
    var recentData: RecentDataContext
}

enum AICoachType: String, Codable {
    case workoutSuggestion, mealPlan, routineSuggestion, motivationalBoost, moodSupport, insightGeneration
}

struct RecentDataContext: Codable {
    var recentMoods: [MoodEntry] = []
    var recentWorkouts: [WorkoutLog] = []
    var recentMeals: [MealLog] = []
    var activeTasks: [Task] = []
    var habits: [Habit] = []
    var averageEnergy: Double = 5
}

struct AnyCodable: Codable {
    let value: Any
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) {
            value = intVal
        } else if let doubleVal = try? container.decode(Double.self) {
            value = doubleVal
        } else if let boolVal = try? container.decode(Bool.self) {
            value = boolVal
        } else if let stringVal = try? container.decode(String.self) {
            value = stringVal
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let intVal = value as? Int {
            try container.encode(intVal)
        } else if let doubleVal = value as? Double {
            try container.encode(doubleVal)
        } else if let boolVal = value as? Bool {
            try container.encode(boolVal)
        } else if let stringVal = value as? String {
            try container.encode(stringVal)
        }
    }
}

// MARK: - Social & Gamification
struct Achievement: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var description: String
    var icon: String
    var category: AchievementCategory
    var unlockedAt: Date?
    var progress: Double = 0 // 0-1
}

enum AchievementCategory: String, Codable {
    case streak, total, social, milestone, special
}

struct SocialProfile: Codable, Identifiable {
    var id: UUID = UUID()
    var userId: UUID
    var displayName: String
    var profileImage: Data?
    var bio: String?
    var friends: [UUID] = []
    var followers: [UUID] = []
    var following: [UUID] = []
    var publicStats: Bool = true
}
