import HealthKit
import Combine

// MARK: - HealthKit Manager (Complete Implementation)
@MainActor
class HealthKitManager: NSObject, ObservableObject {
    static let shared = HealthKitManager()
    
    @Published var isAuthorized = false
    @Published var authorizationStatus: [HKObjectType: HKAuthorizationStatus] = [:]
    
    @Published var stepsCount: Int = 0
    @Published var caloriesBurned: Double = 0
    @Published var heartRate: Int = 0
    @Published var sleepData: [SleepEntry] = []
    @Published var activeEnergy: Double = 0
    @Published var standHours: Int = 0
    @Published var exerciseMinutes: Int = 0
    
    @Published var isLoading = false
    @Published var lastError: String?
    @Published var lastSync: Date?
    
    private let healthStore = HKHealthStore()
    private var queries: [HKQuery] = []
    
    override init() {
        super.init()
        requestHealthKitAuthorization()
    }
    
    // MARK: - Authorization
    func requestHealthKitAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            lastError = "HealthKit is not available on this device"
            return
        }
        
        let readTypes: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .sleepAnalysis)!,
            HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!,
            HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned)!,
            HKWorkoutType.workoutType(),
        ]
        
        let writeTypes: Set<HKSampleType> = [
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKWorkoutType.workoutType(),
        ]
        
        healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.isAuthorized = true
                    self?.checkAuthorizationStatus()
                    self?.fetchAllHealthData()
                } else {
                    self?.lastError = error?.localizedDescription ?? "Authorization failed"
                }
            }
        }
    }
    
    private func checkAuthorizationStatus() {
        let types: [HKObjectType] = [
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .sleepAnalysis)!,
        ]
        
        for type in types {
            let status = healthStore.authorizationStatus(for: type)
            authorizationStatus[type] = status
        }
    }
    
    // MARK: - Fetch All Health Data
    func fetchAllHealthData() {
        Task {
            isLoading = true
            
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.fetchSteps() }
                group.addTask { await self.fetchCalories() }
                group.addTask { await self.fetchHeartRate() }
                group.addTask { await self.fetchSleepData() }
                group.addTask { await self.fetchExerciseTime() }
                group.addTask { await self.fetchActiveEnergyTrend() }
            }
            
            isLoading = false
            lastSync = Date()
        }
    }
    
    // MARK: - Fetch Steps
    func fetchSteps() async {
        let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)
        
        let query = HKStatisticsQuery(quantityType: stepsType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.lastError = "Failed to fetch steps: \(error.localizedDescription)"
                    return
                }
                
                if let result = result, let sum = result.sumQuantity() {
                    self?.stepsCount = Int(sum.doubleValue(for: HKUnit.count()))
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Fetch Calories
    func fetchCalories() async {
        let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)
        
        let query = HKStatisticsQuery(quantityType: caloriesType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.lastError = "Failed to fetch calories: \(error.localizedDescription)"
                    return
                }
                
                if let result = result, let sum = result.sumQuantity() {
                    self?.caloriesBurned = sum.doubleValue(for: HKUnit.kilocalorie())
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Fetch Heart Rate
    func fetchHeartRate() async {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let calendar = Calendar.current
        let now = Date()
        let onehourAgo = calendar.date(byAdding: .hour, value: -1, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: onehourAgo, end: now)
        
        let query = HKStatisticsQuery(quantityType: heartRateType, quantitySamplePredicate: predicate, options: .discreteAverage) { [weak self] _, result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.lastError = "Failed to fetch heart rate: \(error.localizedDescription)"
                    return
                }
                
                if let result = result, let average = result.averageQuantity() {
                    self?.heartRate = Int(average.doubleValue(for: HKUnit(from: "count/min")))
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Fetch Sleep Data
    func fetchSleepData() async {
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let calendar = Calendar.current
        let now = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: sevenDaysAgo, end: now)
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { [weak self] _, samples, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.lastError = "Failed to fetch sleep: \(error.localizedDescription)"
                    return
                }
                
                guard let sleepSamples = samples as? [HKCategorySample] else { return }
                
                var sleepEntries: [SleepEntry] = []
                for sample in sleepSamples {
                    if sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue {
                        let duration = sample.endDate.timeIntervalSince(sample.startDate) / 3600
                        sleepEntries.append(SleepEntry(date: sample.startDate, duration: duration))
                    }
                }
                
                self?.sleepData = sleepEntries
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Fetch Exercise Time
    func fetchExerciseTime() async {
        let exerciseType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)
        
        let query = HKStatisticsQuery(quantityType: exerciseType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.lastError = "Failed to fetch exercise time: \(error.localizedDescription)"
                    return
                }
                
                if let result = result, let sum = result.sumQuantity() {
                    self?.exerciseMinutes = Int(sum.doubleValue(for: HKUnit.minute()))
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Fetch Active Energy Trend
    func fetchActiveEnergyTrend() async {
        let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let calendar = Calendar.current
        let now = Date()
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: thirtyDaysAgo, end: now)
        
        let query = HKStatisticsCollectionQuery(quantityType: activeEnergyType, quantitySamplePredicate: predicate, options: .cumulativeSum, anchorDate: thirtyDaysAgo, intervalComponents: DateComponents(day: 1))
        
        query.initialResultsHandler = { [weak self] _, results, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.lastError = "Failed to fetch trend: \(error.localizedDescription)"
                    return
                }
                
                // Store trend data for analytics
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Save Workout to HealthKit
    func saveWorkoutToHealthKit(_ workout: WorkoutLog) async throws {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }
        
        let workoutType = mapWorkoutType(workout.type)
        let duration = Double(workout.duration) / 60.0 // Convert to minutes
        let calories = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: Double(workout.estimatedCalories))
        
        let workoutSample = HKWorkout(
            activityType: workoutType,
            start: workout.startTime,
            end: workout.endTime ?? Date(),
            duration: duration,
            totalEnergyBurned: calories,
            totalDistance: nil,
            metadata: ["intensity": workout.intensity.rawValue]
        )
        
        try await withCheckedThrowingContinuation { continuation in
            healthStore.save(workoutSample) { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? HealthKitError.saveFailed)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func mapWorkoutType(_ type: WorkoutType) -> HKWorkoutActivityType {
        switch type {
        case .strength: return .traditionalStrengthTraining
        case .cardio: return .running
        case .flexibility: return .yoga
        case .sports: return .soccer
        case .hiit: return .highIntensityIntervalTraining
        }
    }
    
    func stopQuery(query: HKQuery) {
        healthStore.stop(query)
        queries.removeAll { $0 == query }
    }
    
    func stopAllQueries() {
        queries.forEach { healthStore.stop($0) }
        queries.removeAll()
    }
    
    deinit {
        stopAllQueries()
    }
}

// MARK: - Models
struct SleepEntry: Codable, Identifiable {
    let id = UUID()
    let date: Date
    let duration: Double // in hours
}

enum HealthKitError: LocalizedError {
    case notAuthorized
    case saveFailed
    case queryFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized: return "HealthKit authorization required"
        case .saveFailed: return "Failed to save workout"
        case .queryFailed: return "Failed to query health data"
        }
    }
}
