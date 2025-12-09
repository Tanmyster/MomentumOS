import SwiftUI
import Combine

// MARK: - Food Tracking Manager
@MainActor
class FoodManager: ObservableObject {
    static let shared = FoodManager()
    
    @Published var todaysMeals: [MealLog] = []
    @Published var dailyNutritionSummary: NutritionSummary = NutritionSummary()
    @Published var foodDatabase: [String: FoodNutritionInfo] = [:]
    
    private let storage = StorageManager.shared
    private let calorieGoal = 2000
    private let proteinGoal = 150
    private let carbsGoal = 250
    private let fatGoal = 65
    
    func addMeal(type: MealType, foods: [FoodItem]) {
        let meal = MealLog(
            mealType: type,
            foods: foods
        )
        
        meal.totalCalories = foods.reduce(0) { $0 + $1.calories }
        meal.totalProtein = foods.reduce(0) { $0 + $1.protein }
        meal.totalCarbs = foods.reduce(0) { $0 + $1.carbs }
        meal.totalFat = foods.reduce(0) { $0 + $1.fat }
        
        todaysMeals.append(meal)
        try? storage.save(meal, to: "Meals/\(meal.id).json")
        
        updateDailySummary()
    }
    
    func addFoodByBarcode(_ barcode: String) async {
        // TODO: Integrate with barcode database API
        // For now, use fallback data
        let food = FoodItem(
            name: "Unknown Food",
            quantity: 1,
            unit: "serving",
            calories: 100,
            protein: 5,
            carbs: 15,
            fat: 3
        )
        
        // Add to current or create meal
    }
    
    func analyzeFood(from image: Data) async {
        // TODO: Integrate with Vision framework or AI service for food recognition
        // Use cloud API for advanced recognition
    }
    
    func getMealSuggestion(basedOnMood mood: MoodLevel, energy: Int) {
        // Ask AI coach for personalized meal suggestion
        Task {
            do {
                let suggestion = try await AICoachService.shared.suggestMeal(
                    energyLevel: energy,
                    moodLevel: mood,
                    recentMeals: todaysMeals
                )
                // Display suggestion to user
            } catch {
                // Fallback
                let fallback = AICoachService.shared.getOfflineMealSuggestion(energyLevel: energy)
            }
        }
    }
    
    private func updateDailySummary() {
        let totalCalories = todaysMeals.reduce(0) { $0 + $1.totalCalories }
        let totalProtein = todaysMeals.reduce(0) { $0 + $1.totalProtein }
        let totalCarbs = todaysMeals.reduce(0) { $0 + $1.totalCarbs }
        let totalFat = todaysMeals.reduce(0) { $0 + $1.totalFat }
        
        dailyNutritionSummary = NutritionSummary(
            calories: Int(totalCalories),
            protein: Int(totalProtein),
            carbs: Int(totalCarbs),
            fat: Int(totalFat),
            calorieGoal: calorieGoal,
            proteinGoal: proteinGoal,
            carbsGoal: carbsGoal,
            fatGoal: fatGoal
        )
    }
    
    func getMacroDistribution() -> MacroDistribution {
        let total = dailyNutritionSummary.calories
        guard total > 0 else { return MacroDistribution() }
        
        let proteinCalories = dailyNutritionSummary.protein * 4
        let carbsCalories = dailyNutritionSummary.carbs * 4
        let fatCalories = dailyNutritionSummary.fat * 9
        
        return MacroDistribution(
            proteinPercent: Double(proteinCalories) / Double(total) * 100,
            carbsPercent: Double(carbsCalories) / Double(total) * 100,
            fatPercent: Double(fatCalories) / Double(total) * 100
        )
    }
}

struct NutritionSummary: Codable {
    var calories: Int = 0
    var protein: Int = 0
    var carbs: Int = 0
    var fat: Int = 0
    var calorieGoal: Int = 2000
    var proteinGoal: Int = 150
    var carbsGoal: Int = 250
    var fatGoal: Int = 65
    
    func caloriePercentage() -> Double {
        guard calorieGoal > 0 else { return 0 }
        return Double(calories) / Double(calorieGoal) * 100
    }
    
    func proteinPercentage() -> Double {
        guard proteinGoal > 0 else { return 0 }
        return Double(protein) / Double(proteinGoal) * 100
    }
    
    func carbsPercentage() -> Double {
        guard carbsGoal > 0 else { return 0 }
        return Double(carbs) / Double(carbsGoal) * 100
    }
    
    func fatPercentage() -> Double {
        guard fatGoal > 0 else { return 0 }
        return Double(fat) / Double(fatGoal) * 100
    }
}

struct MacroDistribution: Codable {
    var proteinPercent: Double = 0
    var carbsPercent: Double = 0
    var fatPercent: Double = 0
}

struct FoodNutritionInfo: Codable {
    var name: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var servingSize: String
}

// MARK: - Habit Manager
@MainActor
class HabitManager: ObservableObject {
    static let shared = HabitManager()
    
    @Published var allHabits: [Habit] = []
    @Published var todaysHabits: [Habit] = []
    @Published var completionPercentage: Double = 0
    
    private let storage = StorageManager.shared
    
    func createHabit(
        name: String,
        category: HabitCategory,
        frequency: HabitFrequency = .daily,
        icon: String = "star.fill"
    ) {
        let habit = Habit(
            name: name,
            category: category,
            frequency: frequency,
            icon: icon
        )
        
        allHabits.append(habit)
        try? storage.saveHabit(habit)
    }
    
    func toggleHabit(_ habit: Habit) {
        guard var mutableHabit = allHabits.first(where: { $0.id == habit.id }) else { return }
        
        let today = Calendar.current.startOfDay(for: Date())
        let existingLog = mutableHabit.logs.first { calendar in
            Calendar.current.isDate($0.date, inSameDayAs: today)
        }
        
        if existingLog != nil {
            mutableHabit.logs.removeAll { $0.date == today }
        } else {
            let log = HabitLog(habitId: mutableHabit.id, date: Date(), completed: true)
            mutableHabit.logs.append(log)
        }
        
        if let index = allHabits.firstIndex(where: { $0.id == habit.id }) {
            allHabits[index] = mutableHabit
            try? storage.saveHabit(mutableHabit)
        }
    }
    
    func getTodaysHabits() {
        let today = Calendar.current.startOfDay(for: Date())
        todaysHabits = allHabits.filter { habit in
            !habit.logs.contains { log in
                Calendar.current.isDate(log.date, inSameDayAs: today)
            } && habit.isActive
        }
        
        updateCompletionPercentage()
    }
    
    func loadAllHabits() {
        allHabits = (try? storage.loadAllHabits()) ?? []
    }
    
    private func updateCompletionPercentage() {
        guard !todaysHabits.isEmpty else { return }
        
        let today = Calendar.current.startOfDay(for: Date())
        let completed = todaysHabits.filter { habit in
            habit.logs.contains { log in
                Calendar.current.isDate(log.date, inSameDayAs: today) && log.completed
            }
        }.count
        
        completionPercentage = Double(completed) / Double(todaysHabits.count) * 100
    }
    
    func getHabitStreak(_ habit: Habit) -> Int {
        habit.currentStreak
    }
    
    func getHabitLongestStreak(_ habit: Habit) -> Int {
        habit.longestStreak
    }
}
