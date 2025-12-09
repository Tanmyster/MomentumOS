import SwiftUI
import Combine

// MARK: - Focus Manager (Pomodoro + Digital Lockdown)
@MainActor
class FocusManager: ObservableObject {
    static let shared = FocusManager()
    
    @Published var currentSession: FocusSession?
    @Published var timeRemaining: TimeInterval = 0
    @Published var isRunning = false
    @Published var isLocked = false
    
    private var timer: Timer?
    private let storage = StorageManager.shared
    
    func startFocusSession(
        title: String,
        duration: TimeInterval,
        category: FocusCategory = .work
    ) {
        let session = FocusSession(
            title: title,
            duration: duration,
            startTime: Date(),
            category: category
        )
        
        currentSession = session
        timeRemaining = duration
        isRunning = true
        
        startTimer()
        try? storage.save(session, to: "Focus/\(session.id).json")
    }
    
    func pauseSession() {
        isRunning = false
        timer?.invalidate()
    }
    
    func resumeSession() {
        guard currentSession != nil else { return }
        isRunning = true
        startTimer()
    }
    
    func endSession() {
        timer?.invalidate()
        isRunning = false
        
        guard var session = currentSession else { return }
        session.endTime = Date()
        session.completed = true
        
        try? storage.save(session, to: "Focus/\(session.id).json")
        currentSession = nil
    }
    
    private func startTimer() {
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.timeRemaining -= 1
            
            if self?.timeRemaining ?? 0 <= 0 {
                self?.endSession()
            }
        }
    }
    
    func formatTimeRemaining() -> String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Digital Lockdown
    func activateLockdown(blockedApps: [String]) async {
        isLocked = true
        // TODO: Integrate with ManagedSettings API for app lockdown
    }
    
    func deactivateLockdown() async {
        isLocked = false
        // TODO: Deactivate ManagedSettings
    }
}

// MARK: - Mood Tracker Manager
@MainActor
class MoodManager: ObservableObject {
    static let shared = MoodManager()
    
    @Published var todaysMood: MoodEntry?
    @Published var recentMoods: [MoodEntry] = []
    @Published var moodTrend: MoodTrend = .stable
    
    private let storage = StorageManager.shared
    
    func logMood(
        level: MoodLevel,
        energy: Int,
        stress: Int,
        sleep: Int,
        notes: String?,
        triggers: [String]
    ) {
        let entry = MoodEntry(
            mood: level,
            energy: energy,
            stress: stress,
            sleep: sleep,
            notes: notes,
            triggers: triggers
        )
        
        todaysMood = entry
        try? storage.save(entry, to: "Mood/\(entry.id).json")
        
        // Analyze trend
        updateTrend()
    }
    
    func getMoodHistory(days: Int = 7) {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        // Load moods from storage
        // For now, using empty array - integrate with storage
        recentMoods = []
    }
    
    private func updateTrend() {
        guard recentMoods.count >= 2 else { return }
        
        let recent = recentMoods.suffix(7)
        let average = Double(recent.map { $0.mood.value }.reduce(0, +)) / Double(recent.count)
        
        if average > 3.5 {
            moodTrend = .improving
        } else if average < 2.5 {
            moodTrend = .declining
        } else {
            moodTrend = .stable
        }
    }
}

enum MoodTrend: String {
    case improving, declining, stable
}

extension MoodLevel {
    var value: Int {
        switch self {
        case .terrible: return 1
        case .sad: return 2
        case .neutral: return 3
        case .good: return 4
        case .excellent: return 5
        }
    }
}

// MARK: - Workout Manager
@MainActor
class WorkoutManager: ObservableObject {
    static let shared = WorkoutManager()
    
    @Published var currentWorkout: WorkoutLog?
    @Published var recentWorkouts: [WorkoutLog] = []
    @Published var totalVolume: Double = 0
    @Published var weeklyStats: WorkoutStats = WorkoutStats()
    
    private let storage = StorageManager.shared
    
    func startWorkout(type: WorkoutType, intensity: Intensity = .moderate) {
        let workout = WorkoutLog(
            type: type,
            duration: 0,
            intensity: intensity
        )
        currentWorkout = workout
    }
    
    func addExercise(to workout: inout WorkoutLog, exercise: Exercise) {
        workout.exercises.append(exercise)
    }
    
    func completeWorkout() {
        guard var workout = currentWorkout else { return }
        
        let duration = Date().timeIntervalSince(workout.date)
        workout.duration = duration
        
        // Calculate calories (rough estimate)
        workout.caloriesBurned = calculateCalories(
            duration: duration,
            intensity: workout.intensity,
            type: workout.type
        )
        
        // Save to storage
        try? storage.save(workout, to: "Workouts/\(workout.id).json")
        recentWorkouts.insert(workout, at: 0)
        currentWorkout = nil
        
        updateWeeklyStats()
    }
    
    private func calculateCalories(
        duration: TimeInterval,
        intensity: Intensity,
        type: WorkoutType
    ) -> Double {
        let baseCalories = 5.0 // calories per minute base
        let intensityMultiplier: Double = {
            switch intensity {
            case .light: return 0.8
            case .moderate: return 1.0
            case .high: return 1.3
            case .veryHigh: return 1.6
            }
        }()
        
        return (duration / 60) * baseCalories * intensityMultiplier
    }
    
    func getRecoveryScore() -> RecoveryScore {
        guard let latestWorkout = recentWorkouts.first else {
            return RecoveryScore(score: 100, status: .excellent)
        }
        
        let hoursSinceWorkout = Date().timeIntervalSince(latestWorkout.date) / 3600
        let score = min(100, Int(hoursSinceWorkout * 10))
        
        if score >= 80 {
            return RecoveryScore(score: score, status: .excellent)
        } else if score >= 50 {
            return RecoveryScore(score: score, status: .good)
        } else {
            return RecoveryScore(score: score, status: .recovering)
        }
    }
    
    private func updateWeeklyStats() {
        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        
        let weekWorkouts = recentWorkouts.filter { calendar.isDate($0.date, inSameDayAs: weekStart) }
        weeklyStats.totalWorkouts = weekWorkouts.count
        weeklyStats.totalMinutes = Int(weekWorkouts.reduce(0) { $0 + $1.duration / 60 })
        weeklyStats.totalCalories = Int(weekWorkouts.reduce(0) { $0 + ($1.caloriesBurned ?? 0) })
    }
}

struct WorkoutStats: Codable {
    var totalWorkouts: Int = 0
    var totalMinutes: Int = 0
    var totalCalories: Int = 0
    var averageIntensity: String = "Moderate"
}

struct RecoveryScore {
    var score: Int
    var status: RecoveryStatus
}

enum RecoveryStatus: String {
    case recovering, good, excellent
}
