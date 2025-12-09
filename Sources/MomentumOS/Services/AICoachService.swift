import Foundation
import Combine

// MARK: - AI Coach Service
@MainActor
class AICoachService: ObservableObject {
    static let shared = AICoachService()
    
    @Published var isLoading = false
    @Published var lastError: String?
    
    private let apiBaseURL = "https://api.momentumos.com/ai"
    private let session = URLSession.shared
    
    // MARK: - Workout Suggestions
    func generateWorkoutPlan(
        goals: [Goal],
        preferences: WorkoutPreferences,
        recentWorkouts: [WorkoutLog]
    ) async throws -> WorkoutPlan {
        isLoading = true
        defer { isLoading = false }
        
        let request = AICoachRequest(
            userId: UUID(),
            type: .workoutSuggestion,
            context: ["preferences": AnyCodable(value: preferences as Any)],
            recentData: RecentDataContext(recentWorkouts: recentWorkouts)
        )
        
        return try await postRequest(request, endpoint: "/workout-plan")
    }
    
    // MARK: - Nutrition Suggestions
    func suggestMeal(
        energyLevel: Int,
        moodLevel: MoodLevel,
        recentMeals: [MealLog]
    ) async throws -> MealSuggestion {
        isLoading = true
        defer { isLoading = false }
        
        let request = AICoachRequest(
            userId: UUID(),
            type: .mealPlan,
            context: [:],
            recentData: RecentDataContext(recentMeals: recentMeals)
        )
        
        return try await postRequest(request, endpoint: "/meal-suggestion")
    }
    
    // MARK: - Routine Generation
    func generateDayRoutine(
        goals: [Goal],
        habits: [Habit],
        tasks: [Task]
    ) async throws -> DayRoutine {
        isLoading = true
        defer { isLoading = false }
        
        let request = AICoachRequest(
            userId: UUID(),
            type: .routineSuggestion,
            context: [:],
            recentData: RecentDataContext(
                activeTasks: tasks,
                habits: habits
            )
        )
        
        return try await postRequest(request, endpoint: "/routine-suggestion")
    }
    
    // MARK: - Motivational Messages
    func getMotivationalBoost(
        mood: MoodLevel,
        context: String
    ) async throws -> MotivationalResponse {
        isLoading = true
        defer { isLoading = false }
        
        let request = AICoachRequest(
            userId: UUID(),
            type: .motivationalBoost,
            context: [:],
            recentData: RecentDataContext()
        )
        
        return try await postRequest(request, endpoint: "/motivational-boost")
    }
    
    // MARK: - Mood Support
    func getMoodSupport(
        moodEntries: [MoodEntry]
    ) async throws -> MoodSupportResponse {
        isLoading = true
        defer { isLoading = false }
        
        let request = AICoachRequest(
            userId: UUID(),
            type: .moodSupport,
            context: [:],
            recentData: RecentDataContext(recentMoods: moodEntries)
        )
        
        return try await postRequest(request, endpoint: "/mood-support")
    }
    
    // MARK: - Generate Insights
    func generateWeeklyInsights(
        workouts: [WorkoutLog],
        meals: [MealLog],
        moods: [MoodEntry],
        habits: [Habit]
    ) async throws -> WeeklyInsights {
        isLoading = true
        defer { isLoading = false }
        
        let request = AICoachRequest(
            userId: UUID(),
            type: .insightGeneration,
            context: [:],
            recentData: RecentDataContext(
                recentMoods: moods,
                recentWorkouts: workouts,
                recentMeals: meals,
                habits: habits
            )
        )
        
        return try await postRequest(request, endpoint: "/weekly-insights")
    }
    
    // MARK: - Fallback Methods (Offline)
    func getOfflineWorkoutSuggestion(preferences: WorkoutPreferences) -> WorkoutPlan {
        // Return default workout based on preferences
        return WorkoutPlan(
            name: "Quick Home Workout",
            duration: 30,
            exercises: [
                SuggestedExercise(name: "Push-ups", sets: 3, reps: 10),
                SuggestedExercise(name: "Squats", sets: 3, reps: 15),
                SuggestedExercise(name: "Plank", sets: 3, reps: 30)
            ]
        )
    }
    
    func getOfflineMealSuggestion(energyLevel: Int) -> MealSuggestion {
        return MealSuggestion(
            name: "Balanced Meal",
            description: "Protein + Carbs + Vegetables",
            estimatedCalories: 600,
            ingredients: ["Chicken", "Rice", "Broccoli"]
        )
    }
    
    // MARK: - Generic Request Handler
    private func postRequest<T: Decodable>(
        _ request: AICoachRequest,
        endpoint: String
    ) async throws -> T {
        guard let url = URL(string: "\(apiBaseURL)\(endpoint)") else {
            throw AICoachError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(getAuthToken())", forHTTPHeaderField: "Authorization")
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            lastError = "Server error"
            throw AICoachError.serverError
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
    
    private func getAuthToken() -> String {
        return UserDefaults.standard.string(forKey: "momentumOS.authToken") ?? ""
    }
}

// MARK: - Error Handling
enum AICoachError: LocalizedError {
    case invalidURL
    case serverError
    case decodingError
    case networkError
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .serverError:
            return "Server error - please try again"
        case .decodingError:
            return "Failed to decode response"
        case .networkError:
            return "Network connection error"
        case .unauthorized:
            return "Unauthorized access"
        }
    }
}

// MARK: - AI Response Models
struct WorkoutPlan: Codable {
    var name: String
    var duration: Int // minutes
    var exercises: [SuggestedExercise]
    var notes: String?
}

struct SuggestedExercise: Codable {
    var name: String
    var sets: Int?
    var reps: Int?
    var duration: Int? // seconds
    var notes: String?
}

struct WorkoutPreferences: Codable {
    var location: WorkoutLocation
    var equipment: [String]
    var focusArea: MuscleGroup
    var duration: Int // minutes
}

enum WorkoutLocation: String, Codable {
    case home, gym, outdoor, anywhere
}

struct MealSuggestion: Codable {
    var name: String
    var description: String
    var estimatedCalories: Double
    var ingredients: [String]
    var prepTime: Int? // minutes
    var macros: MacroBreakdown?
}

struct MacroBreakdown: Codable {
    var protein: Double
    var carbs: Double
    var fat: Double
}

struct DayRoutine: Codable {
    var timeBlocks: [TimeBlock]
    var priorities: [String]
    var notes: String?
}

struct MotivationalResponse: Codable {
    var message: String
    var category: MotivationCategory
    var affirmation: String?
    var actionableTip: String?
}

struct MoodSupportResponse: Codable {
    var supportMessage: String
    var recommendations: [String]
    var copingStrategies: [String]
    var shouldSeekHelp: Bool
}

struct WeeklyInsights: Codable {
    var summary: String
    var highlights: [String]
    var areasForImprovement: [String]
    var trends: [Trend]
    var recommendations: [String]
}

struct Trend: Codable {
    var name: String
    var direction: TrendDirection
    var magnitude: Double // percentage change
}

enum TrendDirection: String, Codable {
    case improving, declining, stable
}
