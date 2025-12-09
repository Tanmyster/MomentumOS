import HealthKit
import Combine

// MARK: - HealthKit Manager
@MainActor
class HealthKitManager: NSObject, ObservableObject {
    static let shared = HealthKitManager()
    
    @Published var isAuthorized = false
    @Published var stepsCount: Int = 0
    @Published var caloriesBurned: Double = 0
    @Published var heartRate: Int = 0
    @Published var sleepData: [SleepEntry] = []
    
    private let healthStore = HKHealthStore()
    
    override init() {
        super.init()
        requestHealthKitAuthorization()
    }
    
    // MARK: - Authorization
    func requestHealthKitAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit data not available")
            return
        }
        
        let readTypes: Set<HKObjectType> = [
            HKQuantityType.workoutType(),
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!,
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: readTypes) { [weak self] success, error in
            Task { @MainActor in
                self?.isAuthorized = success
                if success {
                    await self?.fetchHealthData()
                }
            }
        }
    }
    
    // MARK: - Fetch Health Data
    private func fetchHealthData() async {
        await fetchSteps()
        await fetchCalories()
        await fetchHeartRate()
        await fetchSleepData()
    }
    
    private func fetchSteps() async {
        let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)
        
        let query = HKStatisticsQuery(quantityType: stepsType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            if let sum = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) {
                Task { @MainActor in
                    self.stepsCount = Int(sum)
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchCalories() async {
        let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)
        
        let query = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            if let sum = result?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) {
                Task { @MainActor in
                    self.caloriesBurned = sum
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchHeartRate() async {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let predicate = HKQuery.predicateForSamples(withStart: Date(timeIntervalSinceNow: -3600), end: Date())
        
        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: 1, sortDescriptors: nil) { _, samples, _ in
            if let sample = samples?.last as? HKQuantitySample {
                let heartRateValue = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
                Task { @MainActor in
                    self.heartRate = Int(heartRateValue)
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func fetchSleepData() async {
        let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now)
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
            var sleepEntries: [SleepEntry] = []
            
            if let samples = samples as? [HKCategorySample] {
                for sample in samples {
                    let duration = sample.endDate.timeIntervalSince(sample.startDate) / 3600
                    sleepEntries.append(SleepEntry(date: sample.startDate, duration: duration))
                }
            }
            
            Task { @MainActor in
                self.sleepData = sleepEntries
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Write Health Data
    func saveWorkoutToHealthKit(_ workout: WorkoutLog) {
        let workoutType: HKWorkoutActivityType = {
            switch workout.type {
            case .cardio: return .running
            case .strength: return .traditionalStrengthTraining
            case .flexibility: return .yoga
            case .sports: return .basketball
            case .other: return .other
            }
        }()
        
        let startDate = workout.date
        let endDate = startDate.addingTimeInterval(workout.duration)
        
        let hkWorkout = HKWorkout(
            activityType: workoutType,
            start: startDate,
            end: endDate,
            duration: workout.duration / 60,
            totalEnergyBurned: workout.caloriesBurned.map { HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: $0) },
            totalDistance: nil,
            metadata: nil
        )
        
        healthStore.save(hkWorkout) { success, error in
            if success {
                print("Workout saved to HealthKit")
            } else if let error = error {
                print("Error saving workout: \(error)")
            }
        }
    }
}

struct SleepEntry: Codable {
    let date: Date
    let duration: Double // in hours
}

// MARK: - Apple Calendar Sync
@MainActor
class CalendarSyncManager: NSObject, ObservableObject {
    static let shared = CalendarSyncManager()
    
    @Published var isSynced = false
    
    // TODO: Integrate with EventKit
    // Requires: import EventKit
    
    func syncTasksToAppleCalendar(_ tasks: [Task]) {
        // TODO: Convert tasks to EKEvent and save to calendar
    }
    
    func syncRoutinesToAppleCalendar(_ routines: [Routine]) {
        // TODO: Convert routines to calendar events
    }
}

// MARK: - Siri Shortcuts Integration
struct SiriShortcutsManager {
    static func createStartFocusSessionShortcut() {
        // TODO: Use AppIntents to create Siri Shortcut
    }
    
    static func createStartMorningRoutineShortcut() {
        // TODO: Create shortcut for morning routine
    }
    
    static func createLogMoodShortcut() {
        // TODO: Create shortcut to log mood
    }
    
    static func createWorkoutReminderShortcut() {
        // TODO: Create shortcut for workout reminders
    }
}

// MARK: - Widget Data Provider
struct WidgetDataProvider {
    private static let storage = StorageManager.shared
    
    static func getTodaysFocusData() -> FocusWidgetData {
        // TODO: Fetch focus session data
        return FocusWidgetData(
            currentStreak: 5,
            focusMinutesCompleted: 120,
            focusSessionsToday: 3
        )
    }
    
    static func getTodaysHabitData() -> HabitWidgetData {
        // TODO: Fetch habit completion data
        return HabitWidgetData(
            habitsCompleted: 4,
            totalHabits: 6,
            longestStreak: 12
        )
    }
    
    static func getDailyMotivation() -> String {
        let quotes = [
            "Every small step forward is still progress.",
            "Discipline is choosing what you want most over what you want now.",
            "Your body can stand almost anything. It's your mind you need to convince.",
            "Progress, not perfection."
        ]
        return quotes.randomElement() ?? "Keep going!"
    }
}

struct FocusWidgetData: Codable {
    let currentStreak: Int
    let focusMinutesCompleted: Int
    let focusSessionsToday: Int
}

struct HabitWidgetData: Codable {
    let habitsCompleted: Int
    let totalHabits: Int
    let longestStreak: Int
}

// MARK: - Apple Watch Integration
struct AppleWatchManager {
    // TODO: Implement companion watch app
    // Features:
    // - Quick habit logging
    // - Focus timer complications
    // - Activity rings integration
    // - Motivation notifications
}
