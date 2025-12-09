import SwiftUI
import Combine
import AuthenticationServices

// MARK: - Authentication Manager
@MainActor
class AuthenticationManager: NSObject, ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: String?
    
    private let storage = StorageManager.shared
    
    override init() {
        super.init()
        loadUser()
    }
    
    // MARK: - Email/Password Sign Up
    func signUp(
        email: String,
        password: String,
        name: String
    ) async {
        isLoading = true
        defer { isLoading = false }
        
        guard isValidEmail(email) else {
            error = "Invalid email address"
            return
        }
        
        guard password.count >= 8 else {
            error = "Password must be at least 8 characters"
            return
        }
        
        // TODO: Integrate with backend API
        let user = User(
            email: email,
            name: name
        )
        
        currentUser = user
        isAuthenticated = true
        
        try? storage.saveUser(user)
        saveAuthToken()
    }
    
    // MARK: - Email/Password Sign In
    func signIn(email: String, password: String) async {
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Integrate with backend API
        guard let user = (try? storage.loadUser()) else {
            error = "Invalid credentials"
            return
        }
        
        currentUser = user
        isAuthenticated = true
        saveAuthToken()
    }
    
    // MARK: - Apple Sign In
    func signInWithApple(_ credential: ASAuthorizationAppleIDCredential) async {
        isLoading = true
        defer { isLoading = false }
        
        let user = User(
            email: credential.email ?? "",
            name: credential.fullName?.givenName ?? "User"
        )
        
        currentUser = user
        isAuthenticated = true
        
        try? storage.saveUser(user)
        saveAuthToken()
    }
    
    // MARK: - Google Sign In
    func signInWithGoogle() async {
        // TODO: Integrate with Google Sign-In SDK
        isLoading = true
        defer { isLoading = false }
    }
    
    // MARK: - Facebook Sign In
    func signInWithFacebook() async {
        // TODO: Integrate with Facebook SDK
        isLoading = true
        defer { isLoading = false }
    }
    
    // MARK: - Sign Out
    func signOut() {
        currentUser = nil
        isAuthenticated = false
        clearAuthToken()
        try? storage.delete("User/profile.json")
    }
    
    // MARK: - Password Reset
    func resetPassword(email: String) async {
        // TODO: Integrate with backend API
    }
    
    // MARK: - Update Profile
    func updateProfile(
        name: String?,
        bio: String?,
        image: Data?
    ) async {
        guard var user = currentUser else { return }
        
        if let name = name {
            user.name = name
        }
        if let bio = bio {
            user.bio = bio
        }
        if let image = image {
            user.profileImage = image
        }
        
        currentUser = user
        try? storage.saveUser(user)
    }
    
    // MARK: - Helper Methods
    private func loadUser() {
        if let user = try? storage.loadUser() {
            currentUser = user
            isAuthenticated = true
        }
    }
    
    private func saveAuthToken() {
        let token = UUID().uuidString
        UserDefaults.standard.set(token, forKey: "momentumOS.authToken")
    }
    
    private func clearAuthToken() {
        UserDefaults.standard.removeObject(forKey: "momentumOS.authToken")
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
}

// MARK: - Apple Sign In Coordinator
struct AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            return
        }
        
        Task {
            await AuthenticationManager.shared.signInWithApple(appleIDCredential)
        }
    }
    
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        print("Apple Sign In error: \(error.localizedDescription)")
    }
}

// MARK: - Profile Manager
@MainActor
class ProfileManager: ObservableObject {
    static let shared = ProfileManager()
    
    @Published var profile: SocialProfile?
    @Published var friends: [SocialProfile] = []
    @Published var achievements: [Achievement] = []
    @Published var totalPoints: Int = 0
    
    private let storage = StorageManager.shared
    
    func createProfile(displayName: String, bio: String? = nil) {
        guard let user = AuthenticationManager.shared.currentUser else { return }
        
        let profile = SocialProfile(
            userId: user.id,
            displayName: displayName,
            bio: bio
        )
        
        self.profile = profile
        // TODO: Save to storage
    }
    
    func addFriend(_ friendId: UUID) {
        guard var profile = profile else { return }
        if !profile.friends.contains(friendId) {
            profile.friends.append(friendId)
        }
    }
    
    func removeFriend(_ friendId: UUID) {
        guard var profile = profile else { return }
        profile.friends.removeAll { $0 == friendId }
    }
    
    func unlockAchievement(_ achievement: Achievement) {
        var mutableAchievement = achievement
        mutableAchievement.unlockedAt = Date()
        
        if !achievements.contains(where: { $0.id == achievement.id }) {
            achievements.append(mutableAchievement)
            updateTotalPoints()
        }
    }
    
    func updateAchievementProgress(_ achievementId: UUID, progress: Double) {
        if let index = achievements.firstIndex(where: { $0.id == achievementId }) {
            achievements[index].progress = min(1.0, progress)
            
            if achievements[index].progress >= 1.0 {
                achievements[index].unlockedAt = Date()
                updateTotalPoints()
            }
        }
    }
    
    private func updateTotalPoints() {
        totalPoints = achievements.filter({ $0.unlockedAt != nil }).count * 10
    }
    
    func getLeaderboardPosition() -> Int {
        // TODO: Fetch from backend
        return 1
    }
}

// MARK: - Onboarding Manager
@MainActor
class OnboardingManager: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var userGoals: [Goal] = []
    @Published var selectedHabits: [String] = []
    @Published var workoutPreferences: WorkoutPreferences?
    
    enum OnboardingStep {
        case welcome
        case goals
        case habits
        case preferences
        case workout
        case nutrition
        case complete
    }
    
    func nextStep() {
        switch currentStep {
        case .welcome:
            currentStep = .goals
        case .goals:
            currentStep = .habits
        case .habits:
            currentStep = .preferences
        case .preferences:
            currentStep = .workout
        case .workout:
            currentStep = .nutrition
        case .nutrition:
            currentStep = .complete
        case .complete:
            break
        }
    }
    
    func previousStep() {
        switch currentStep {
        case .welcome:
            break
        case .goals:
            currentStep = .welcome
        case .habits:
            currentStep = .goals
        case .preferences:
            currentStep = .habits
        case .workout:
            currentStep = .preferences
        case .nutrition:
            currentStep = .workout
        case .complete:
            currentStep = .nutrition
        }
    }
    
    func addGoal(_ goal: Goal) {
        userGoals.append(goal)
    }
    
    func toggleHabit(_ habitName: String) {
        if selectedHabits.contains(habitName) {
            selectedHabits.removeAll { $0 == habitName }
        } else {
            selectedHabits.append(habitName)
        }
    }
    
    func completeOnboarding() {
        Task {
            // Generate AI routines based on onboarding data
            let routineManager = RoutineManager.shared
            await routineManager.generateAIRoutine(goals: userGoals)
        }
    }
}
