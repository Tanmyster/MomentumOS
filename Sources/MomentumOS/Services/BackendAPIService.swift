import Foundation
import Combine

// MARK: - Backend API Configuration
struct BackendConfig {
    static let baseURL = "https://api.momentumos.com"
    static let apiVersion = "v1"
    static let timeout: TimeInterval = 30
    static let maxRetries = 3
    
    static func endpoint(_ path: String) -> URL? {
        URL(string: "\(baseURL)/\(apiVersion)\(path)")
    }
}

// MARK: - Backend API Service
@MainActor
class BackendAPIService: NSObject, ObservableObject {
    static let shared = BackendAPIService()
    
    @Published var isOnline = true
    @Published var lastError: APIError?
    @Published var isLoading = false
    @Published var syncInProgress = false
    
    private let session: URLSession
    private var networkMonitor: Any? // NWPathMonitor
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    override init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = BackendConfig.timeout
        config.timeoutIntervalForResource = BackendConfig.timeout * 2
        config.waitsForConnectivity = true
        config.httpMaximumConnectionsPerHost = 6
        
        self.session = URLSession(configuration: config)
        super.init()
        
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        
        setupNetworkMonitoring()
    }
    
    // MARK: - Network Monitoring
    private func setupNetworkMonitoring() {
        #if os(iOS)
        let monitor = URLSession.shared
        let req = URLRequest(url: BackendConfig.endpoint("/health") ?? URL(fileURLWithPath: "/"))
        
        let task = monitor.dataTask(with: req) { [weak self] _, response, error in
            DispatchQueue.main.async {
                self?.isOnline = (response as? HTTPURLResponse)?.statusCode == 200 && error == nil
            }
        }
        task.resume()
        #endif
    }
    
    // MARK: - Authentication Endpoints
    func loginWithEmail(email: String, password: String) async throws -> AuthResponse {
        let body = LoginRequest(email: email, password: password)
        return try await postRequest(body, endpoint: "/auth/login")
    }
    
    func registerUser(email: String, password: String, name: String) async throws -> AuthResponse {
        let body = RegisterRequest(email: email, password: password, name: name)
        return try await postRequest(body, endpoint: "/auth/register")
    }
    
    func refreshToken(refreshToken: String) async throws -> TokenResponse {
        let body = ["refreshToken": refreshToken]
        return try await postRequest(body, endpoint: "/auth/refresh")
    }
    
    func logout() async throws {
        _ = try await deleteRequest(endpoint: "/auth/logout")
    }
    
    // MARK: - User Profile Endpoints
    func getUserProfile() async throws -> UserProfile {
        try await getRequest(endpoint: "/users/me")
    }
    
    func updateUserProfile(profile: UserProfile) async throws -> UserProfile {
        try await putRequest(profile, endpoint: "/users/me")
    }
    
    func uploadProfileImage(imageData: Data) async throws -> ProfileImageResponse {
        let boundary = UUID().uuidString
        let body = createMultipartFormData(imageData: imageData, boundary: boundary)
        
        guard let url = BackendConfig.endpoint("/users/me/avatar") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(getAuthToken())", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        let (data, response) = try await session.data(for: request)
        return try decodeResponse(data: data, response: response)
    }
    
    // MARK: - Habit Endpoints
    func createHabit(_ habit: Habit) async throws -> Habit {
        try await postRequest(habit, endpoint: "/habits")
    }
    
    func updateHabit(_ habit: Habit) async throws -> Habit {
        try await putRequest(habit, endpoint: "/habits/\(habit.id)")
    }
    
    func deleteHabit(_ habitId: UUID) async throws {
        _ = try await deleteRequest(endpoint: "/habits/\(habitId)")
    }
    
    func getHabits(limit: Int = 50) async throws -> [Habit] {
        try await getRequest(endpoint: "/habits?limit=\(limit)")
    }
    
    func logHabitCompletion(_ habitId: UUID, date: Date) async throws -> HabitLog {
        let body = HabitCompletionRequest(habitId: habitId, completedAt: date)
        return try await postRequest(body, endpoint: "/habits/\(habitId)/log")
    }
    
    // MARK: - Mood Endpoints
    func logMood(_ mood: MoodEntry) async throws -> MoodEntry {
        try await postRequest(mood, endpoint: "/moods")
    }
    
    func getMoodEntries(days: Int = 7) async throws -> [MoodEntry] {
        try await getRequest(endpoint: "/moods?days=\(days)")
    }
    
    func getMoodStats() async throws -> MoodStats {
        try await getRequest(endpoint: "/moods/stats")
    }
    
    // MARK: - Workout Endpoints
    func createWorkout(_ workout: WorkoutLog) async throws -> WorkoutLog {
        try await postRequest(workout, endpoint: "/workouts")
    }
    
    func getWorkouts(limit: Int = 50) async throws -> [WorkoutLog] {
        try await getRequest(endpoint: "/workouts?limit=\(limit)")
    }
    
    func getWorkoutStats() async throws -> WorkoutStatsResponse {
        try await getRequest(endpoint: "/workouts/stats")
    }
    
    // MARK: - Meal Endpoints
    func logMeal(_ meal: MealLog) async throws -> MealLog {
        try await postRequest(meal, endpoint: "/meals")
    }
    
    func getMeals(date: Date) async throws -> [MealLog] {
        let formatter = ISO8601DateFormatter()
        let dateStr = formatter.string(from: date)
        return try await getRequest(endpoint: "/meals?date=\(dateStr)")
    }
    
    func getNutritionStats() async throws -> NutritionStatsResponse {
        try await getRequest(endpoint: "/nutrition/stats")
    }
    
    // MARK: - Task Endpoints
    func createTask(_ task: Task) async throws -> Task {
        try await postRequest(task, endpoint: "/tasks")
    }
    
    func updateTask(_ task: Task) async throws -> Task {
        try await putRequest(task, endpoint: "/tasks/\(task.id)")
    }
    
    func completeTask(_ taskId: UUID) async throws {
        _ = try await postRequest(["completedAt": Date()], endpoint: "/tasks/\(taskId)/complete")
    }
    
    func getTasks() async throws -> [Task] {
        try await getRequest(endpoint: "/tasks")
    }
    
    // MARK: - Sync Endpoints
    func syncData(_ syncRequest: SyncRequest) async throws -> SyncResponse {
        syncInProgress = true
        defer { syncInProgress = false }
        
        return try await postRequest(syncRequest, endpoint: "/sync")
    }
    
    func fullResync() async throws -> SyncResponse {
        let request = SyncRequest(
            habits: [],
            moods: [],
            workouts: [],
            meals: [],
            tasks: [],
            timestamp: Date()
        )
        return try await syncData(request)
    }
    
    // MARK: - Generic HTTP Methods
    private func getRequest<T: Decodable>(endpoint: String) async throws -> T {
        guard let url = BackendConfig.endpoint(endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(getAuthToken())", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        return try decodeResponse(data: data, response: response)
    }
    
    private func postRequest<B: Encodable, R: Decodable>(_ body: B, endpoint: String) async throws -> R {
        guard let url = BackendConfig.endpoint(endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(getAuthToken())", forHTTPHeaderField: "Authorization")
        request.httpBody = try encoder.encode(body)
        
        let (data, response) = try await session.data(for: request)
        return try decodeResponse(data: data, response: response)
    }
    
    private func putRequest<B: Encodable, R: Decodable>(_ body: B, endpoint: String) async throws -> R {
        guard let url = BackendConfig.endpoint(endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(getAuthToken())", forHTTPHeaderField: "Authorization")
        request.httpBody = try encoder.encode(body)
        
        let (data, response) = try await session.data(for: request)
        return try decodeResponse(data: data, response: response)
    }
    
    private func deleteRequest(endpoint: String) async throws -> [String: String] {
        guard let url = BackendConfig.endpoint(endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(getAuthToken())", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        return try decodeResponse(data: data, response: response)
    }
    
    // MARK: - Response Handling
    private func decodeResponse<T: Decodable>(data: Data, response: URLResponse) throws -> T {
        guard let httpResponse = response as? HTTPURLResponse else {
            lastError = .invalidResponse
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                lastError = .decodingError
                throw APIError.decodingError
            }
            
        case 401:
            lastError = .unauthorized
            throw APIError.unauthorized
            
        case 400...499:
            lastError = .clientError(httpResponse.statusCode)
            throw APIError.clientError(httpResponse.statusCode)
            
        case 500...599:
            lastError = .serverError(httpResponse.statusCode)
            throw APIError.serverError(httpResponse.statusCode)
            
        default:
            lastError = .unknownError
            throw APIError.unknownError
        }
    }
    
    // MARK: - Helpers
    private func getAuthToken() -> String {
        KeychainManager.shared.getToken() ?? ""
    }
    
    private func createMultipartFormData(imageData: Data, boundary: String) -> Data {
        var body = Data()
        
        body.append("--\(boundary)\r\n".data(using: .utf8) ?? Data())
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"avatar.jpg\"\r\n".data(using: .utf8) ?? Data())
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8) ?? Data())
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8) ?? Data())
        
        return body
    }
}

// MARK: - Request Models
struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let email: String
    let password: String
    let name: String
}

struct HabitCompletionRequest: Codable {
    let habitId: UUID
    let completedAt: Date
}

struct SyncRequest: Codable {
    let habits: [Habit]
    let moods: [MoodEntry]
    let workouts: [WorkoutLog]
    let meals: [MealLog]
    let tasks: [Task]
    let timestamp: Date
}

// MARK: - Response Models
struct AuthResponse: Codable {
    let user: UserProfile
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
}

struct TokenResponse: Codable {
    let accessToken: String
    let expiresIn: Int
}

struct UserProfile: Codable {
    let id: UUID
    let email: String
    let name: String
    let avatar: String?
    let bio: String?
    let createdAt: Date
    let lastSync: Date?
}

struct ProfileImageResponse: Codable {
    let url: String
    let uploadedAt: Date
}

struct MoodStats: Codable {
    let average: Double
    let trend: String
    let entriesThisWeek: Int
}

struct WorkoutStatsResponse: Codable {
    let totalWorkouts: Int
    let totalMinutes: Int
    let totalCalories: Int
    let averagePerWeek: Double
}

struct NutritionStatsResponse: Codable {
    let caloriesAverageTodayAll: Double
    let proteinGoal: Int
    let carbsGoal: Int
    let fatGoal: Int
}

struct SyncResponse: Codable {
    let habits: [Habit]
    let moods: [MoodEntry]
    let workouts: [WorkoutLog]
    let meals: [MealLog]
    let tasks: [Task]
    let timestamp: Date
}

// MARK: - Keychain Manager
class KeychainManager {
    static let shared = KeychainManager()
    
    private let serviceName = "com.momentumos.app"
    
    func saveToken(_ token: String) {
        let data = token.data(using: .utf8) ?? Data()
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: "authToken",
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func getToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: "authToken",
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        
        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    func deleteToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: "authToken"
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - API Error
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError
    case networkError
    case unauthorized
    case clientError(Int)
    case serverError(Int)
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL"
        case .invalidResponse: return "Invalid server response"
        case .decodingError: return "Failed to decode response"
        case .networkError: return "Network connection error"
        case .unauthorized: return "Unauthorized. Please log in again."
        case .clientError(let code): return "Request error (code: \(code))"
        case .serverError(let code): return "Server error (code: \(code))"
        case .unknownError: return "An unknown error occurred"
        }
    }
}
