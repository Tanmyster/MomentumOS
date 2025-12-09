import Foundation
import Combine

// MARK: - Storage Manager (Local + iCloud)
@MainActor
class StorageManager: ObservableObject {
    static let shared = StorageManager()
    
    @Published private(set) var isInitialized = false
    @Published private(set) var syncStatus: SyncStatus = .idle
    
    private let fileManager = FileManager.default
    private let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    private let iCloudContainerIdentifier = "iCloud.com.momentumos.app"
    private var iCloudURL: URL? {
        fileManager.url(forUbiquityContainerIdentifier: iCloudContainerIdentifier)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        Task {
            await initialize()
        }
    }
    
    private func initialize() async {
        // Create necessary directories
        let directories = [
            documentsURL.appendingPathComponent("MomentumOS"),
            documentsURL.appendingPathComponent("MomentumOS/User"),
            documentsURL.appendingPathComponent("MomentumOS/Habits"),
            documentsURL.appendingPathComponent("MomentumOS/Workouts"),
            documentsURL.appendingPathComponent("MomentumOS/Meals"),
            documentsURL.appendingPathComponent("MomentumOS/Tasks"),
            documentsURL.appendingPathComponent("MomentumOS/Cache"),
        ]
        
        for directory in directories {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        
        isInitialized = true
    }
    
    // MARK: - Generic Coding Methods
    func save<T: Encodable>(_ object: T, to filename: String) throws {
        let url = documentsURL.appendingPathComponent("MomentumOS/\(filename)")
        let data = try JSONEncoder().encode(object)
        try data.write(to: url, options: .atomic)
        
        // Sync to iCloud if available
        if let iCloudURL = iCloudContainerIdentifier.isEmpty ? nil : iCloudURL {
            let iCloudFileURL = iCloudURL.appendingPathComponent("MomentumOS/\(filename)")
            try data.write(to: iCloudFileURL, options: .atomic)
        }
    }
    
    func load<T: Decodable>(_ type: T.Type, from filename: String) throws -> T {
        let url = documentsURL.appendingPathComponent("MomentumOS/\(filename)")
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    func delete(_ filename: String) throws {
        let url = documentsURL.appendingPathComponent("MomentumOS/\(filename)")
        try fileManager.removeItem(at: url)
    }
    
    // MARK: - User Data Methods
    func saveUser(_ user: User) throws {
        try save(user, to: "User/profile.json")
    }
    
    func loadUser() throws -> User {
        try load(User.self, from: "User/profile.json")
    }
    
    // MARK: - Habit Methods
    func saveHabit(_ habit: Habit) throws {
        try save(habit, to: "Habits/\(habit.id).json")
    }
    
    func loadHabit(id: UUID) throws -> Habit {
        try load(Habit.self, from: "Habits/\(id).json")
    }
    
    func loadAllHabits() throws -> [Habit] {
        let url = documentsURL.appendingPathComponent("MomentumOS/Habits")
        let files = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        return try files.map { file in
            let data = try Data(contentsOf: file)
            return try JSONDecoder().decode(Habit.self, from: data)
        }
    }
    
    // MARK: - Workout Methods
    func saveWorkout(_ workout: WorkoutLog) throws {
        try save(workout, to: "Workouts/\(workout.id).json")
    }
    
    func loadWorkout(id: UUID) throws -> WorkoutLog {
        try load(WorkoutLog.self, from: "Workouts/\(id).json")
    }
    
    func loadWorkoutsForDate(_ date: Date) throws -> [WorkoutLog] {
        let url = documentsURL.appendingPathComponent("MomentumOS/Workouts")
        let files = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        let calendar = Calendar.current
        
        return try files.compactMap { file in
            let data = try Data(contentsOf: file)
            let workout = try JSONDecoder().decode(WorkoutLog.self, from: data)
            if calendar.isDate(workout.date, inSameDayAs: date) {
                return workout
            }
            return nil
        }
    }
    
    // MARK: - Meal Methods
    func saveMeal(_ meal: MealLog) throws {
        try save(meal, to: "Meals/\(meal.id).json")
    }
    
    func loadMeal(id: UUID) throws -> MealLog {
        try load(MealLog.self, from: "Meals/\(id).json")
    }
    
    func loadMealsForDate(_ date: Date) throws -> [MealLog] {
        let url = documentsURL.appendingPathComponent("MomentumOS/Meals")
        let files = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        let calendar = Calendar.current
        
        return try files.compactMap { file in
            let data = try Data(contentsOf: file)
            let meal = try JSONDecoder().decode(MealLog.self, from: data)
            if calendar.isDate(meal.date, inSameDayAs: date) {
                return meal
            }
            return nil
        }
    }
    
    // MARK: - Task Methods
    func saveTask(_ task: Task) throws {
        try save(task, to: "Tasks/\(task.id).json")
    }
    
    func loadTask(id: UUID) throws -> Task {
        try load(Task.self, from: "Tasks/\(id).json")
    }
    
    func loadAllTasks() throws -> [Task] {
        let url = documentsURL.appendingPathComponent("MomentumOS/Tasks")
        let files = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
        return try files.map { file in
            let data = try Data(contentsOf: file)
            return try JSONDecoder().decode(Task.self, from: data)
        }
    }
    
    // MARK: - Sync Status
    enum SyncStatus: String, Codable {
        case idle, syncing, synced, error
    }
    
    func triggerManualSync() async {
        await MainActor.run {
            syncStatus = .syncing
        }
        
        // Simulate sync delay
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        await MainActor.run {
            syncStatus = .synced
        }
    }
    
    // MARK: - Data Encryption (Optional)
    func encryptData(_ data: Data) throws -> Data {
        // TODO: Implement with CryptoKit for sensitive data
        return data
    }
    
    func decryptData(_ data: Data) throws -> Data {
        // TODO: Implement with CryptoKit
        return data
    }
}

// MARK: - Backup & Export
extension StorageManager {
    func exportUserData() throws -> Data {
        let url = documentsURL.appendingPathComponent("MomentumOS")
        let archiveURL = FileManager.default.temporaryDirectory.appendingPathComponent("MomentumOS_Backup.zip")
        
        // Create zip file of MomentumOS directory
        try fileManager.zipDirectory(at: url, to: archiveURL)
        return try Data(contentsOf: archiveURL)
    }
    
    func importUserData(from backup: Data) throws {
        let extractURL = documentsURL.appendingPathComponent("MomentumOS_Import")
        let backupFile = extractURL.appendingPathComponent("backup.zip")
        
        try? fileManager.createDirectory(at: extractURL, withIntermediateDirectories: true)
        try backup.write(to: backupFile)
        try fileManager.unzipFile(at: backupFile, to: extractURL)
    }
}

// MARK: - File Manager Extensions
extension FileManager {
    func zipDirectory(at sourceURL: URL, to destinationURL: URL) throws {
        // Simplified zip implementation - in production use ZipFoundation
        try contentsOfDirectory(at: sourceURL, includingPropertiesForKeys: nil)
    }
    
    func unzipFile(at sourceURL: URL, to destinationURL: URL) throws {
        // Simplified unzip implementation - in production use ZipFoundation
    }
}
