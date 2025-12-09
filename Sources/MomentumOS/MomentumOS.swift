import SwiftUI

@main
struct MomentumOSApp: App {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var storageManager = StorageManager.shared
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                DashboardView()
                    .preferredColorScheme(themeManager.currentTheme == .light ? .light : .dark)
                    .environmentObject(authManager)
                    .environmentObject(themeManager)
            } else {
                if authManager.currentUser == nil {
                    OnboardingView()
                        .environmentObject(authManager)
                        .environmentObject(themeManager)
                } else {
                    AuthenticationView()
                        .environmentObject(authManager)
                        .environmentObject(themeManager)
                }
            }
        }
    }
}

// MARK: - Main Dashboard View
struct DashboardView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var themeManager: ThemeManager
    
    @StateObject private var focusManager = FocusManager.shared
    @StateObject private var moodManager = MoodManager.shared
    @StateObject private var workoutManager = WorkoutManager.shared
    @StateObject private var habitManager = HabitManager.shared
    @StateObject private var foodManager = FoodManager.shared
    @StateObject private var motivationManager = MotivationManager.shared
    @StateObject private var calendarManager = CalendarManager.shared
    @StateObject private var routineManager = RoutineManager.shared
    
    @State private var selectedTab: TabType = .home
    @Environment(\.colorScheme) var colorScheme
    
    enum TabType {
        case home, focus, mood, workout, food, motivation
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(MomentumColors.backgroundDark)
                    : UIColor(MomentumColors.backgroundLight)
            })
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Content
                Group {
                    switch selectedTab {
                    case .home:
                        HomeView()
                    case .focus:
                        FocusView()
                    case .mood:
                        MoodTrackingView()
                    case .workout:
                        WorkoutView()
                    case .food:
                        FoodTrackingView()
                    case .motivation:
                        MotivationView()
                    }
                }
                
                Spacer()
                
                // Bottom Navigation
                BottomNavigationBar(selectedTab: $selectedTab)
            }
        }
        .environmentObject(focusManager)
        .environmentObject(moodManager)
        .environmentObject(workoutManager)
        .environmentObject(habitManager)
        .environmentObject(foodManager)
        .environmentObject(motivationManager)
        .environmentObject(calendarManager)
        .environmentObject(routineManager)
    }
}

// MARK: - Bottom Navigation Bar
struct BottomNavigationBar: View {
    @Binding var selectedTab: DashboardView.TabType
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(MomentumColors.primary.opacity(0.2))
            
            HStack(spacing: 0) {
                NavBarItem(
                    icon: "house.fill",
                    label: "Home",
                    isSelected: selectedTab == .home,
                    action: { selectedTab = .home }
                )
                
                NavBarItem(
                    icon: "timer",
                    label: "Focus",
                    isSelected: selectedTab == .focus,
                    action: { selectedTab = .focus }
                )
                
                NavBarItem(
                    icon: "heart.fill",
                    label: "Mood",
                    isSelected: selectedTab == .mood,
                    action: { selectedTab = .mood }
                )
                
                NavBarItem(
                    icon: "dumbbell.fill",
                    label: "Workout",
                    isSelected: selectedTab == .workout,
                    action: { selectedTab = .workout }
                )
                
                NavBarItem(
                    icon: "fork.knife",
                    label: "Food",
                    isSelected: selectedTab == .food,
                    action: { selectedTab = .food }
                )
                
                NavBarItem(
                    icon: "sparkles",
                    label: "Motivation",
                    isSelected: selectedTab == .motivation,
                    action: { selectedTab = .motivation }
                )
            }
            .frame(height: 60)
            .background(
                Color(UIColor { traitCollection in
                    traitCollection.userInterfaceStyle == .dark
                        ? UIColor(MomentumColors.surfaceDark)
                        : UIColor(MomentumColors.surfaceLight)
                })
            )
        }
    }
}

// MARK: - Navigation Bar Item
struct NavBarItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundColor(isSelected ? MomentumColors.primary : .gray)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
    }
}

// MARK: - Home View
struct HomeView: View {
    @EnvironmentObject var habitManager: HabitManager
    @EnvironmentObject var motivationManager: MotivationManager
    @EnvironmentObject var moodManager: MoodManager
    @EnvironmentObject var foodManager: FoodManager
    @EnvironmentObject var focusManager: FocusManager
    
    @State private var expandedHabitId: UUID?
    
    var body: some View {
        ScrollView {
            VStack(spacing: MomentumDesignTokens.lg) {
                VStack(alignment: .leading, spacing: MomentumDesignTokens.md) {
                    Text("Welcome Back")
                        .momentumTitle()
                    
                    Text("Let's make today count")
                        .momentumSubtitle()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(MomentumDesignTokens.md)
                
                // Quick Stats
                HStack(spacing: MomentumDesignTokens.md) {
                    QuickStatCard(
                        title: "Habits",
                        value: "\(habitManager.todaysHabits.filter { habit in
                            habit.logs.contains { Calendar.current.isDateInToday($0.completedAt) }
                        }.count)",
                        subtitle: "of \(habitManager.todaysHabits.count)",
                        icon: "checkmark.circle.fill",
                        color: MomentumColors.primary
                    )
                    
                    QuickStatCard(
                        title: "Calories",
                        value: "\(foodManager.dailyNutritionSummary.calories)",
                        subtitle: "of \(foodManager.dailyNutritionSummary.calorieGoal)",
                        icon: "flame.fill",
                        color: MomentumColors.accent
                    )
                    
                    QuickStatCard(
                        title: "Mood",
                        value: moodManager.todaysMood?.level.rawValue.capitalized ?? "—",
                        subtitle: "logged today",
                        icon: "smiley.fill",
                        color: MomentumColors.secondary
                    )
                }
                .padding(MomentumDesignTokens.md)
                
                // Daily Quote
                VStack(alignment: .leading, spacing: MomentumDesignTokens.sm) {
                    Text("Today's Motivation")
                        .font(MomentumDesignTokens.bodyMedium)
                        .fontWeight(.semibold)
                    
                    if let quote = motivationManager.todaysQuote {
                        VStack(alignment: .leading, spacing: MomentumDesignTokens.sm) {
                            HStack(spacing: 8) {
                                Image(systemName: "quote.opening")
                                    .font(.system(size: 14))
                                    .foregroundColor(MomentumColors.primary)
                                
                                Text(quote.content)
                                    .font(MomentumDesignTokens.bodyMedium)
                                    .lineLimit(3)
                            }
                            
                            if let author = quote.author {
                                Text("— \(author)")
                                    .font(MomentumDesignTokens.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(MomentumDesignTokens.md)
                        .momentumCard()
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    } else {
                        Text("Every day is a new opportunity")
                            .font(MomentumDesignTokens.bodyMedium)
                            .padding(MomentumDesignTokens.md)
                            .momentumCard()
                    }
                }
                .padding(MomentumDesignTokens.md)
                
                // Habit Progress
                VStack(alignment: .leading, spacing: MomentumDesignTokens.md) {
                    HStack {
                        Text("Today's Habits")
                            .font(MomentumDesignTokens.bodyMedium)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text("\(habitManager.todaysHabits.count) total")
                            .font(MomentumDesignTokens.bodySmall)
                            .foregroundColor(.gray)
                    }
                    
                    if habitManager.todaysHabits.isEmpty {
                        VStack(spacing: MomentumDesignTokens.md) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.gray)
                            
                            Text("No habits for today")
                                .font(MomentumDesignTokens.bodyMedium)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(MomentumDesignTokens.lg)
                        .momentumCard()
                    } else {
                        ForEach(habitManager.todaysHabits) { habit in
                            ExpandableHabitCard(
                                habit: habit,
                                isExpanded: expandedHabitId == habit.id,
                                onTap: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        expandedHabitId = expandedHabitId == habit.id ? nil : habit.id
                                    }
                                }
                            )
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }
                    }
                }
                .padding(MomentumDesignTokens.md)
                
                // Quick Actions
                VStack(alignment: .leading, spacing: MomentumDesignTokens.md) {
                    Text("Quick Actions")
                        .font(MomentumDesignTokens.bodyMedium)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: MomentumDesignTokens.sm) {
                        if !focusManager.isRunning {
                            QuickActionButton(
                                title: "Start Focus",
                                subtitle: "25 min session",
                                icon: "hourglass.tophalf.fill",
                                action: {
                                    focusManager.startFocusSession(title: "Quick Focus", duration: 25 * 60)
                                }
                            )
                        }
                        
                        QuickActionButton(
                            title: "Log Mood",
                            subtitle: "Check in with yourself",
                            icon: "smiley.fill",
                            action: {
                                // Navigate to mood view
                            }
                        )
                        
                        QuickActionButton(
                            title: "Add Meal",
                            subtitle: "Track your nutrition",
                            icon: "fork.knife",
                            action: {
                                // Navigate to food view
                            }
                        )
                    }
                }
                .padding(MomentumDesignTokens.md)
            }
            .padding(.vertical, MomentumDesignTokens.md)
        }
        .onAppear {
            motivationManager.loadTodaysQuote()
        }
    }
}

// MARK: - Quick Stat Card
struct QuickStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: MomentumDesignTokens.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(title)
                .font(MomentumDesignTokens.bodySmall)
                .foregroundColor(.gray)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(MomentumDesignTokens.titleSmall)
                    .fontWeight(.bold)
                
                Text(subtitle)
                    .font(MomentumDesignTokens.caption)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(MomentumDesignTokens.md)
        .momentumCard()
    }
}

// MARK: - Expandable Habit Card
struct ExpandableHabitCard: View {
    let habit: Habit
    let isExpanded: Bool
    let onTap: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    onTap()
                }
            }) {
                HStack(spacing: MomentumDesignTokens.md) {
                    Image(systemName: habit.icon)
                        .font(.system(size: 20))
                        .foregroundColor(MomentumColors.primary)
                    
                    VStack(alignment: .leading, spacing: MomentumDesignTokens.xs) {
                        Text(habit.name)
                            .font(MomentumDesignTokens.bodyMedium)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("Streak: \(habit.currentStreak) days")
                            .font(MomentumDesignTokens.bodySmall)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.gray)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    }
                }
                .padding(MomentumDesignTokens.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                Divider()
                    .padding(.horizontal, MomentumDesignTokens.md)
                
                VStack(alignment: .leading, spacing: MomentumDesignTokens.md) {
                    HStack {
                        Text("Category")
                            .font(MomentumDesignTokens.bodySmall)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text(habit.category.rawValue.capitalized)
                            .font(MomentumDesignTokens.bodySmall)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Frequency")
                            .font(MomentumDesignTokens.bodySmall)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text(habit.frequency.rawValue.capitalized)
                            .font(MomentumDesignTokens.bodySmall)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Longest Streak")
                            .font(MomentumDesignTokens.bodySmall)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        Text("\(habit.longestStreak) days")
                            .font(MomentumDesignTokens.bodySmall)
                            .fontWeight(.semibold)
                    }
                    
                    // Progress Bar
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Progress")
                                .font(MomentumDesignTokens.bodySmall)
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            let completedDays = habit.logs.count
                            let completedPercentage = completedDays > 0 ? Double(completedDays) / 30.0 : 0.0
                            Text("\(Int(completedPercentage * 100))%")
                                .font(MomentumDesignTokens.bodySmall)
                                .fontWeight(.semibold)
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.gray.opacity(0.2))
                                
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [MomentumColors.primary, MomentumColors.accent]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * min(Double(habit.logs.count) / 30.0, 1.0))
                                    .animation(.easeInOut(duration: 0.5), value: habit.logs.count)
                            }
                        }
                        .frame(height: 6)
                    }
                }
                .padding(MomentumDesignTokens.md)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .momentumCard()
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: MomentumDesignTokens.md) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(MomentumColors.primary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(MomentumDesignTokens.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(MomentumDesignTokens.bodySmall)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray)
            }
            .padding(MomentumDesignTokens.md)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(MomentumDesignTokens.cornerMedium)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct FocusView: View {
    @EnvironmentObject var focusManager: FocusManager
    @EnvironmentObject var motivationManager: MotivationManager
    
    @State private var title = ""
    @State private var duration: Double = 25 * 60
    @State private var selectedCategory: FocusCategory = .work
    @State private var showFocusHistory = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: MomentumDesignTokens.lg) {
                    if focusManager.isRunning, let session = focusManager.currentSession {
                        // Active Session View
                        VStack(spacing: MomentumDesignTokens.xl) {
                            Spacer()
                            
                            // Timer Display
                            VStack(spacing: MomentumDesignTokens.md) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                                    
                                    Circle()
                                        .trim(from: 0, to: focusManager.timeRemaining / (session.duration > 0 ? session.duration : 1))
                                        .stroke(
                                            LinearGradient(
                                                gradient: Gradient(colors: [MomentumColors.primary, MomentumColors.accent]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                                        )
                                        .rotationEffect(.degrees(-90))
                                        .animation(.linear, value: focusManager.timeRemaining)
                                    
                                    VStack(spacing: 8) {
                                        Text(focusManager.formatTimeRemaining())
                                            .font(.system(size: 64, weight: .bold))
                                            .foregroundColor(MomentumColors.primary)
                                        
                                        Text("seconds")
                                            .font(MomentumDesignTokens.bodySmall)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .frame(width: 240, height: 240)
                            }
                            
                            // Session Info
                            VStack(spacing: MomentumDesignTokens.sm) {
                                Text(session.title)
                                    .font(MomentumDesignTokens.titleSmall)
                                    .fontWeight(.bold)
                                
                                Text(session.category.rawValue.capitalized)
                                    .font(MomentumDesignTokens.bodySmall)
                                    .foregroundColor(.gray)
                            }
                            
                            // Control Buttons
                            HStack(spacing: MomentumDesignTokens.md) {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        if focusManager.isRunning {
                                            focusManager.pauseSession()
                                        } else {
                                            focusManager.resumeSession()
                                        }
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: focusManager.isRunning ? "pause.fill" : "play.fill")
                                            .font(.system(size: 16, weight: .semibold))
                                        
                                        Text(focusManager.isRunning ? "Pause" : "Resume")
                                            .fontWeight(.semibold)
                                    }
                                    .momentumButton()
                                }
                                
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        focusManager.endSession()
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 14, weight: .semibold))
                                        
                                        Text("End")
                                            .fontWeight(.semibold)
                                    }
                                    .momentumSecondaryButton()
                                }
                            }
                            .padding(MomentumDesignTokens.lg)
                            
                            Spacer()
                        }
                        .padding(MomentumDesignTokens.lg)
                    } else {
                        // Setup Session View
                        VStack(spacing: MomentumDesignTokens.lg) {
                            VStack(alignment: .leading, spacing: MomentumDesignTokens.md) {
                                Text("Focus Session")
                                    .momentumTitle()
                                
                                Text("Get in the zone and minimize distractions")
                                    .momentumSubtitle()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(MomentumDesignTokens.md)
                            
                            // Input Form
                            VStack(spacing: MomentumDesignTokens.md) {
                                // Title Input
                                VStack(alignment: .leading, spacing: MomentumDesignTokens.sm) {
                                    Text("What are you focusing on?")
                                        .font(MomentumDesignTokens.bodyMedium)
                                        .fontWeight(.semibold)
                                    
                                    TextField("e.g., Deep work, studying", text: $title)
                                        .padding(MomentumDesignTokens.md)
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(MomentumDesignTokens.cornerMedium)
                                }
                                
                                // Category Selector
                                VStack(alignment: .leading, spacing: MomentumDesignTokens.sm) {
                                    Text("Category")
                                        .font(MomentumDesignTokens.bodyMedium)
                                        .fontWeight(.semibold)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: MomentumDesignTokens.sm) {
                                            ForEach(FocusCategory.allCases, id: \.self) { category in
                                                Button(action: {
                                                    withAnimation(.easeInOut(duration: 0.2)) {
                                                        selectedCategory = category
                                                    }
                                                }) {
                                                    Text(category.rawValue.capitalized)
                                                        .font(MomentumDesignTokens.bodySmall)
                                                        .fontWeight(.semibold)
                                                        .padding(.horizontal, MomentumDesignTokens.md)
                                                        .padding(.vertical, MomentumDesignTokens.sm)
                                                        .background(selectedCategory == category ? MomentumColors.primary : Color.gray.opacity(0.2))
                                                        .foregroundColor(selectedCategory == category ? .white : .gray)
                                                        .cornerRadius(MomentumDesignTokens.cornerMedium)
                                                }
                                            }
                                        }
                                        .padding(.horizontal, MomentumDesignTokens.md)
                                    }
                                }
                                
                                // Duration Selector
                                VStack(alignment: .leading, spacing: MomentumDesignTokens.md) {
                                    HStack {
                                        Text("Duration")
                                            .font(MomentumDesignTokens.bodyMedium)
                                            .fontWeight(.semibold)
                                        
                                        Spacer()
                                        
                                        Text("\(Int(duration / 60)) min")
                                            .font(MomentumDesignTokens.bodyMedium)
                                            .fontWeight(.semibold)
                                            .foregroundColor(MomentumColors.primary)
                                    }
                                    
                                    Slider(value: $duration, in: 300...3600, step: 300)
                                        .tint(MomentumColors.primary)
                                    
                                    HStack(spacing: MomentumDesignTokens.sm) {
                                        ForEach([300.0, 900.0, 1500.0, 1800.0], id: \.self) { min in
                                            Button(action: {
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    duration = min
                                                }
                                            }) {
                                                Text("\(Int(min / 60))m")
                                                    .font(MomentumDesignTokens.bodySmall)
                                                    .fontWeight(.semibold)
                                                    .frame(maxWidth: .infinity)
                                                    .padding(MomentumDesignTokens.sm)
                                                    .background(duration == min ? MomentumColors.primary.opacity(0.2) : Color.gray.opacity(0.1))
                                                    .foregroundColor(duration == min ? MomentumColors.primary : .gray)
                                                    .cornerRadius(MomentumDesignTokens.cornerSmall)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(MomentumDesignTokens.md)
                            .momentumCard()
                            
                            // Start Button
                            Button(action: startSession) {
                                HStack(spacing: 8) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                    
                                    Text("Start Focus Session")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .momentumButton()
                            }
                            .padding(MomentumDesignTokens.md)
                            .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                            .opacity(title.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
                            
                            Spacer()
                        }
                    }
                }
            }
        }
        .alert("Focus Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
    }
    
    private func startSession() {
        do {
            let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
            guard !trimmedTitle.isEmpty else {
                throw FocusValidationError.emptyTitle
            }
            
            guard duration > 0 else {
                throw FocusValidationError.invalidDuration
            }
            
            focusManager.startFocusSession(title: trimmedTitle, duration: duration, category: selectedCategory)
            title = ""
            duration = 25 * 60
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

enum FocusValidationError: LocalizedError {
    case emptyTitle
    case invalidDuration
    
    var errorDescription: String? {
        switch self {
        case .emptyTitle: return "Please enter what you're focusing on"
        case .invalidDuration: return "Please select a valid duration"
        }
    }
}

struct MoodTrackingView: View {
    @EnvironmentObject var moodManager: MoodManager
    @State private var selectedMood: MoodLevel = .neutral
    @State private var energy = 5
    @State private var stress = 5
    @State private var sleep = 7
    @State private var notes = ""
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showSuccessMessage = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: MomentumDesignTokens.lg) {
                VStack(alignment: .leading, spacing: MomentumDesignTokens.md) {
                    Text("How are you feeling?")
                        .momentumTitle()
                    
                    Text("Share your current state of mind")
                        .momentumSubtitle()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(MomentumDesignTokens.md)
                
                // Mood Selection
                VStack(spacing: MomentumDesignTokens.md) {
                    HStack(spacing: MomentumDesignTokens.md) {
                        ForEach([MoodLevel.terrible, .sad, .neutral, .good, .excellent], id: \.self) { mood in
                            VStack(spacing: MomentumDesignTokens.xs) {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedMood = mood
                                    }
                                }) {
                                    VStack(spacing: 4) {
                                        Text(moodEmoji(mood))
                                            .font(.system(size: 28))
                                        
                                        Text(moodLabelForLevel(mood))
                                            .font(MomentumDesignTokens.caption)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(MomentumDesignTokens.md)
                                    .background(selectedMood == mood ? MomentumColors.primary.opacity(0.2) : Color.gray.opacity(0.1))
                                    .cornerRadius(MomentumDesignTokens.cornerMedium)
                                    .scaleEffect(selectedMood == mood ? 1.08 : 1.0)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                .padding(MomentumDesignTokens.md)
                
                // Energy, Stress, Sleep
                VStack(spacing: MomentumDesignTokens.lg) {
                    MoodSliderCard(
                        label: "Energy Level",
                        value: $energy,
                        range: 1...10,
                        icon: "bolt.fill",
                        color: MomentumColors.secondary
                    )
                    
                    MoodSliderCard(
                        label: "Stress Level",
                        value: $stress,
                        range: 1...10,
                        icon: "exclamationmark.circle.fill",
                        color: MomentumColors.accent
                    )
                    
                    MoodSliderCard(
                        label: "Sleep Hours",
                        value: $sleep,
                        range: 0...12,
                        icon: "moon.fill",
                        color: MomentumColors.primary
                    )
                }
                .padding(MomentumDesignTokens.md)
                
                // Notes
                VStack(alignment: .leading, spacing: MomentumDesignTokens.sm) {
                    Text("Notes (optional)")
                        .font(MomentumDesignTokens.bodyMedium)
                        .fontWeight(.semibold)
                    
                    TextEditor(text: $notes)
                        .font(MomentumDesignTokens.bodyMedium)
                        .padding(MomentumDesignTokens.md)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(MomentumDesignTokens.cornerMedium)
                        .frame(minHeight: 100)
                }
                .padding(MomentumDesignTokens.md)
                
                // Save Button
                Button(action: saveMood) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .semibold))
                        
                        Text("Save Mood Check-in")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .momentumButton()
                }
                .padding(MomentumDesignTokens.md)
                
                if showSuccessMessage {
                    VStack(spacing: MomentumDesignTokens.sm) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            
                            Text("Mood saved successfully!")
                                .font(MomentumDesignTokens.bodySmall)
                                .fontWeight(.semibold)
                            
                            Spacer()
                        }
                    }
                    .padding(MomentumDesignTokens.md)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(MomentumDesignTokens.cornerMedium)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .padding(MomentumDesignTokens.md)
                }
            }
            .padding(.vertical, MomentumDesignTokens.md)
        }
        .alert("Mood Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
    }
    
    private func saveMood() {
        do {
            moodManager.logMood(
                level: selectedMood,
                energy: energy,
                stress: stress,
                sleepHours: sleep,
                triggers: []
            )
            
            withAnimation(.easeInOut(duration: 0.3)) {
                showSuccessMessage = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showSuccessMessage = false
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func moodEmoji(_ mood: MoodLevel) -> String {
        switch mood {
        case .terrible: return "😩"
        case .sad: return "😢"
        case .neutral: return "😐"
        case .good: return "😊"
        case .excellent: return "🤩"
        }
    }
    
    private func moodLabelForLevel(_ mood: MoodLevel) -> String {
        mood.rawValue.capitalized
    }
}

// MARK: - Mood Slider Card
struct MoodSliderCard: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: MomentumDesignTokens.md) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)
                    
                    Text(label)
                        .font(MomentumDesignTokens.bodyMedium)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                Text("\(value)")
                    .font(MomentumDesignTokens.bodyMedium)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            Slider(value: Binding<Double>(
                get: { Double(value) },
                set: { value = Int($0) }
            ), in: Double(range.lowerBound)...Double(range.upperBound), step: 1)
                .tint(color)
        }
        .padding(MomentumDesignTokens.md)
        .momentumCard()
    }
}

struct WorkoutView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var selectedWorkoutType: WorkoutType = .strength
    @State private var intensity: Intensity = .moderate
    @State private var duration = 30
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var isStarting = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: MomentumDesignTokens.lg) {
                VStack(alignment: .leading, spacing: MomentumDesignTokens.md) {
                    Text("Workout Tracker")
                        .momentumTitle()
                    
                    Text("Log your exercise and track progress")
                        .momentumSubtitle()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(MomentumDesignTokens.md)
                
                // Weekly Stats
                if workoutManager.weeklyStats.totalWorkouts > 0 {
                    VStack(spacing: MomentumDesignTokens.md) {
                        HStack {
                            Text("This Week")
                                .font(MomentumDesignTokens.bodyMedium)
                                .fontWeight(.semibold)
                            
                            Spacer()
                        }
                        
                        HStack(spacing: MomentumDesignTokens.md) {
                            QuickStatCard(
                                title: "Workouts",
                                value: "\(workoutManager.weeklyStats.totalWorkouts)",
                                subtitle: "sessions",
                                icon: "dumbbell.fill",
                                color: MomentumColors.primary
                            )
                            
                            QuickStatCard(
                                title: "Minutes",
                                value: "\(workoutManager.weeklyStats.totalMinutes)",
                                subtitle: "total",
                                icon: "timer",
                                color: MomentumColors.secondary
                            )
                            
                            QuickStatCard(
                                title: "Calories",
                                value: "\(workoutManager.weeklyStats.totalCalories)",
                                subtitle: "burned",
                                icon: "flame.fill",
                                color: MomentumColors.accent
                            )
                        }
                    }
                    .padding(MomentumDesignTokens.md)
                }
                
                // Workout Form
                VStack(spacing: MomentumDesignTokens.lg) {
                    // Type Selector
                    VStack(alignment: .leading, spacing: MomentumDesignTokens.sm) {
                        Text("Workout Type")
                            .font(MomentumDesignTokens.bodyMedium)
                            .fontWeight(.semibold)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: MomentumDesignTokens.sm) {
                                ForEach(WorkoutType.allCases, id: \.self) { type in
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedWorkoutType = type
                                        }
                                    }) {
                                        Text(type.rawValue.capitalized)
                                            .font(MomentumDesignTokens.bodySmall)
                                            .fontWeight(.semibold)
                                            .padding(.horizontal, MomentumDesignTokens.md)
                                            .padding(.vertical, MomentumDesignTokens.sm)
                                            .background(selectedWorkoutType == type ? MomentumColors.primary : Color.gray.opacity(0.2))
                                            .foregroundColor(selectedWorkoutType == type ? .white : .gray)
                                            .cornerRadius(MomentumDesignTokens.cornerMedium)
                                    }
                                }
                            }
                            .padding(.horizontal, MomentumDesignTokens.md)
                        }
                    }
                    
                    // Intensity Selector
                    VStack(alignment: .leading, spacing: MomentumDesignTokens.sm) {
                        Text("Intensity")
                            .font(MomentumDesignTokens.bodyMedium)
                            .fontWeight(.semibold)
                        
                        Picker("Intensity", selection: $intensity) {
                            ForEach(Intensity.allCases, id: \.self) { level in
                                Text(level.rawValue.capitalized).tag(level)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // Duration
                    MoodSliderCard(
                        label: "Duration",
                        value: Binding<Int>(
                            get: { duration },
                            set: { duration = $0 }
                        ),
                        range: 5...180,
                        icon: "timer",
                        color: MomentumColors.secondary
                    )
                    
                    // Start Button
                    Button(action: startWorkout) {
                        HStack(spacing: 8) {
                            if isStarting {
                                ProgressView()
                                    .tint(MomentumColors.primary)
                            } else {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            
                            Text("Start Workout")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .momentumButton()
                    }
                    .disabled(isStarting)
                }
                .padding(MomentumDesignTokens.md)
                .momentumCard()
            }
            .padding(.vertical, MomentumDesignTokens.md)
        }
        .alert("Workout Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
    }
    
    private func startWorkout() {
        do {
            guard duration > 0 else {
                throw WorkoutValidationError.invalidDuration
            }
            
            isStarting = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                workoutManager.startWorkout(type: selectedWorkoutType, intensity: intensity)
                isStarting = false
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

enum WorkoutValidationError: LocalizedError {
    case invalidDuration
    
    var errorDescription: String? {
        switch self {
        case .invalidDuration: return "Please select a valid duration"
        }
    }
}

struct WorkoutView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    
    var body: some View {
        VStack(spacing: MomentumDesignTokens.lg) {
            Text("Workouts")
                .momentumTitle()
            
            if workoutManager.currentWorkout == nil {
                VStack(spacing: MomentumDesignTokens.md) {
                    Button(action: {
                        workoutManager.startWorkout(type: .strength)
                    }) {
                        Text("Start Workout")
                    }
                    .momentumButton()
                }
            }
            
            // Weekly stats
            VStack(alignment: .leading, spacing: MomentumDesignTokens.sm) {
                Text("This Week")
                    .font(MomentumDesignTokens.bodyMedium)
                
                HStack(spacing: MomentumDesignTokens.md) {
                    StatCard(label: "Workouts", value: "\(workoutManager.weeklyStats.totalWorkouts)")
                    StatCard(label: "Minutes", value: "\(workoutManager.weeklyStats.totalMinutes)")
                    StatCard(label: "Calories", value: "\(workoutManager.weeklyStats.totalCalories)")
                }
            }
            .padding(MomentumDesignTokens.md)
        }
        .padding(MomentumDesignTokens.md)
    }
}

struct StatCard: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: MomentumDesignTokens.xs) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(MomentumColors.primary)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(MomentumDesignTokens.md)
        .momentumCard()
    }
}

// MARK: - Food Tracking View
struct FoodTrackingView: View {
    @EnvironmentObject var foodManager: FoodManager
    @State private var selectedDate = Date()
    @State private var showAddMealSheet = false
    @State private var selectedMealType: MealType = .lunch
    @State private var mealName = ""
    @State private var calories = 0
    @State private var protein = 0
    @State private var carbs = 0
    @State private var fat = 0
    @State private var errorMessage: String?
    @State private var showError = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: MomentumDesignTokens.lg) {
                // Header
                VStack(alignment: .leading, spacing: MomentumDesignTokens.md) {
                    Text("Nutrition Hub")
                        .momentumTitle()
                    
                    HStack {
                        Button(action: { selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(MomentumColors.primary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .center, spacing: 2) {
                            Text(dateFormatter.string(from: selectedDate))
                                .font(MomentumDesignTokens.bodyMedium)
                                .fontWeight(.semibold)
                            
                            if Calendar.current.isDateInToday(selectedDate) {
                                Text("Today")
                                    .font(MomentumDesignTokens.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                        
                        Button(action: { selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(MomentumColors.primary)
                        }
                    }
                }
                .padding(MomentumDesignTokens.md)
                
                // Daily Summary Card
                VStack(spacing: MomentumDesignTokens.md) {
                    HStack {
                        VStack(alignment: .leading, spacing: MomentumDesignTokens.xs) {
                            Text("Daily Goal")
                                .font(MomentumDesignTokens.bodySmall)
                                .foregroundColor(.gray)
                            Text("\(foodManager.dailyNutritionSummary.calories) cal")
                                .font(MomentumDesignTokens.titleSmall)
                        }
                        
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                            
                            Circle()
                                .trim(from: 0, to: min(Double(foodManager.dailyNutritionSummary.caloriePercentage()), 1.0))
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [MomentumColors.primary, MomentumColors.accent]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                )
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 0.5), value: foodManager.dailyNutritionSummary.calories)
                            
                            VStack(spacing: 2) {
                                Text("\(Int(foodManager.dailyNutritionSummary.caloriePercentage() * 100))%")
                                    .font(MomentumDesignTokens.bodySmall)
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(width: 80, height: 80)
                    }
                    
                    // Macro Breakdown
                    VStack(spacing: MomentumDesignTokens.sm) {
                        MacroBar(
                            label: "Protein",
                            value: Double(foodManager.dailyNutritionSummary.protein),
                            goal: Double(foodManager.dailyNutritionSummary.proteinGoal),
                            color: MomentumColors.primary
                        )
                        
                        MacroBar(
                            label: "Carbs",
                            value: Double(foodManager.dailyNutritionSummary.carbs),
                            goal: Double(foodManager.dailyNutritionSummary.carbsGoal),
                            color: MomentumColors.secondary
                        )
                        
                        MacroBar(
                            label: "Fat",
                            value: Double(foodManager.dailyNutritionSummary.fat),
                            goal: Double(foodManager.dailyNutritionSummary.fatGoal),
                            color: MomentumColors.accent
                        )
                    }
                }
                .padding(MomentumDesignTokens.md)
                .momentumCard()
                
                // Meals Section
                VStack(alignment: .leading, spacing: MomentumDesignTokens.md) {
                    HStack {
                        Text("Meals Today")
                            .font(MomentumDesignTokens.bodyMedium)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button(action: { showAddMealSheet = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                Text("Add")
                            }
                            .font(MomentumDesignTokens.bodySmall)
                            .foregroundColor(MomentumColors.primary)
                        }
                    }
                    
                    if foodManager.todaysMeals.isEmpty {
                        VStack(spacing: MomentumDesignTokens.md) {
                            Image(systemName: "fork.knife")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            
                            Text("No meals logged yet")
                                .font(MomentumDesignTokens.bodyMedium)
                                .foregroundColor(.gray)
                            
                            Text("Add your meals to track nutrition")
                                .font(MomentumDesignTokens.bodySmall)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(MomentumDesignTokens.lg)
                        .momentumCard()
                    } else {
                        ForEach(MealType.allCases, id: \.self) { mealType in
                            let mealsOfType = foodManager.todaysMeals.filter { $0.type == mealType }
                            
                            if !mealsOfType.isEmpty {
                                VStack(alignment: .leading, spacing: MomentumDesignTokens.sm) {
                                    HStack {
                                        Image(systemName: mealTypeIcon(mealType))
                                            .foregroundColor(MomentumColors.primary)
                                        
                                        Text(mealType.rawValue.capitalized)
                                            .font(MomentumDesignTokens.bodyMedium)
                                            .fontWeight(.semibold)
                                        
                                        Spacer()
                                        
                                        Text("\(mealsOfType.reduce(0) { $0 + Int($1.totalCalories) }) cal")
                                            .font(MomentumDesignTokens.bodySmall)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    ForEach(mealsOfType) { meal in
                                        MealCard(meal: meal)
                                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(MomentumDesignTokens.md)
            }
            .padding(.vertical, MomentumDesignTokens.md)
        }
        .sheet(isPresented: $showAddMealSheet) {
            AddMealSheet(
                isPresented: $showAddMealSheet,
                mealName: $mealName,
                selectedMealType: $selectedMealType,
                calories: $calories,
                protein: $protein,
                carbs: $carbs,
                fat: $fat,
                onSave: addMeal,
                errorMessage: $errorMessage
            )
        }
        .alert("Nutrition Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .onAppear {
            foodManager.dailyNutritionSummary = NutritionSummary()
        }
    }
    
    private func addMeal() {
        do {
            guard !mealName.trimmingCharacters(in: .whitespaces).isEmpty else {
                throw MealValidationError.emptyName
            }
            
            guard calories > 0 else {
                throw MealValidationError.invalidCalories
            }
            
            let foodItem = FoodItem(
                name: mealName,
                calories: Double(calories),
                protein: Double(protein),
                carbs: Double(carbs),
                fat: Double(fat),
                servingSize: "1 serving"
            )
            
            foodManager.addMeal(type: selectedMealType, foods: [foodItem])
            
            mealName = ""
            calories = 0
            protein = 0
            carbs = 0
            fat = 0
            showAddMealSheet = false
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func mealTypeIcon(_ type: MealType) -> String {
        switch type {
        case .breakfast: return "sun.max.fill"
        case .lunch: return "sun.max"
        case .dinner: return "moon.fill"
        case .snack: return "star.fill"
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()
}

enum MealValidationError: LocalizedError {
    case emptyName
    case invalidCalories
    
    var errorDescription: String? {
        switch self {
        case .emptyName: return "Please enter a meal name"
        case .invalidCalories: return "Please enter calories greater than 0"
        }
    }
}

// MARK: - Add Meal Sheet
struct AddMealSheet: View {
    @Binding var isPresented: Bool
    @Binding var mealName: String
    @Binding var selectedMealType: MealType
    @Binding var calories: Int
    @Binding var protein: Int
    @Binding var carbs: Int
    @Binding var fat: Int
    var onSave: () -> Void
    @Binding var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section("Meal Details") {
                    TextField("Meal name", text: $mealName)
                    
                    Picker("Type", selection: $selectedMealType) {
                        ForEach(MealType.allCases, id: \.self) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                    }
                }
                
                Section("Nutrition") {
                    Stepper("Calories: \(calories)", value: $calories, in: 0...5000, step: 10)
                    Stepper("Protein: \(protein)g", value: $protein, in: 0...200, step: 5)
                    Stepper("Carbs: \(carbs)g", value: $carbs, in: 0...500, step: 10)
                    Stepper("Fat: \(fat)g", value: $fat, in: 0...200, step: 5)
                }
            }
            .navigationTitle("Add Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Macro Bar Component
struct MacroBar: View {
    let label: String
    let value: Double
    let goal: Double
    let color: Color
    
    var percentage: Double {
        min(value / goal, 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(MomentumDesignTokens.bodySmall)
                
                Spacer()
                
                Text("\(Int(value))g / \(Int(goal))g")
                    .font(MomentumDesignTokens.bodySmall)
                    .fontWeight(.semibold)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(color.opacity(0.2))
                    
                    Capsule()
                        .fill(color)
                        .frame(width: geometry.size.width * percentage)
                        .animation(.easeInOut(duration: 0.3), value: percentage)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Meal Card
struct MealCard: View {
    let meal: MealLog
    
    var body: some View {
        VStack(alignment: .leading, spacing: MomentumDesignTokens.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Meal")
                        .font(MomentumDesignTokens.bodySmall)
                        .foregroundColor(.gray)
                    
                    Text("\(Int(meal.totalCalories)) cal")
                        .font(MomentumDesignTokens.bodyMedium)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: MomentumDesignTokens.sm) {
                        Label("\(Int(meal.totalProtein))g", systemImage: "bolt.fill")
                            .font(MomentumDesignTokens.caption)
                            .foregroundColor(MomentumColors.primary)
                        
                        Label("\(Int(meal.totalCarbs))g", systemImage: "flame.fill")
                            .font(MomentumDesignTokens.caption)
                            .foregroundColor(MomentumColors.secondary)
                    }
                }
            }
        }
        .padding(MomentumDesignTokens.md)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(MomentumDesignTokens.cornerMedium)
    }
}

// MARK: - Motivation View
struct MotivationView: View {
    @EnvironmentObject var motivationManager: MotivationManager
    @EnvironmentObject var aiCoachService: AICoachService
    @EnvironmentObject var moodManager: MoodManager
    
    @State private var selectedCategory: MotivationCategory = .general
    @State private var showAddAffirmation = false
    @State private var affirmationText = ""
    @State private var isLoadingBoost = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var selectedQuoteIndex = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: MomentumDesignTokens.lg) {
                // Header
                VStack(alignment: .leading, spacing: MomentumDesignTokens.md) {
                    Text("Motivation Hub")
                        .momentumTitle()
                    
                    Text("Stay inspired and focused on your goals")
                        .momentumSubtitle()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(MomentumDesignTokens.md)
                
                // Daily Quote
                if let quote = motivationManager.todaysQuote {
                    VStack(spacing: MomentumDesignTokens.md) {
                        VStack(alignment: .leading, spacing: MomentumDesignTokens.md) {
                            HStack {
                                Image(systemName: "quote.opening")
                                    .font(.system(size: 20))
                                    .foregroundColor(MomentumColors.primary)
                                
                                Spacer()
                                
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        motivationManager.loadTodaysQuote()
                                    }
                                }) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(MomentumColors.primary)
                                }
                            }
                            
                            Text(quote.content)
                                .font(MomentumDesignTokens.titleSmall)
                                .fontWeight(.semibold)
                                .lineLimit(nil)
                            
                            if let author = quote.author {
                                Text("— \(author)")
                                    .font(MomentumDesignTokens.bodySmall)
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                        .padding(MomentumDesignTokens.lg)
                        .momentumCard()
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                    .padding(MomentumDesignTokens.md)
                }
                
                // AI Motivation Boost
                VStack(spacing: MomentumDesignTokens.md) {
                    Text("Need a Boost?")
                        .font(MomentumDesignTokens.bodyMedium)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Button(action: requestMotivationBoost) {
                        HStack(spacing: MomentumDesignTokens.md) {
                            if isLoadingBoost {
                                ProgressView()
                                    .tint(MomentumColors.primary)
                            } else {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            
                            Text(isLoadingBoost ? "Getting boost..." : "Get AI Motivation")
                                .fontWeight(.semibold)
                            
                            Spacer()
                        }
                        .momentumButton()
                    }
                    .disabled(isLoadingBoost)
                }
                .padding(MomentumDesignTokens.md)
                
                // Category Filter
                VStack(alignment: .leading, spacing: MomentumDesignTokens.md) {
                    Text("Categories")
                        .font(MomentumDesignTokens.bodyMedium)
                        .fontWeight(.semibold)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: MomentumDesignTokens.sm) {
                            ForEach(MotivationCategory.allCases, id: \.self) { category in
                                Button(action: { selectedCategory = category }) {
                                    Text(category.rawValue.capitalized)
                                        .font(MomentumDesignTokens.bodySmall)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, MomentumDesignTokens.md)
                                        .padding(.vertical, MomentumDesignTokens.sm)
                                        .background(selectedCategory == category ? MomentumColors.primary : Color.gray.opacity(0.2))
                                        .foregroundColor(selectedCategory == category ? .white : .gray)
                                        .cornerRadius(MomentumDesignTokens.cornerMedium)
                                }
                                .animation(.easeInOut(duration: 0.2), value: selectedCategory)
                            }
                        }
                        .padding(.horizontal, MomentumDesignTokens.md)
                    }
                }
                
                // Custom Affirmations
                VStack(alignment: .leading, spacing: MomentumDesignTokens.md) {
                    HStack {
                        Text("My Affirmations")
                            .font(MomentumDesignTokens.bodyMedium)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button(action: { showAddAffirmation = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(MomentumColors.primary)
                        }
                    }
                    
                    if motivationManager.customAffirmations.isEmpty {
                        VStack(spacing: MomentumDesignTokens.md) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.gray)
                            
                            Text("No affirmations yet")
                                .font(MomentumDesignTokens.bodyMedium)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(MomentumDesignTokens.lg)
                        .momentumCard()
                    } else {
                        ForEach(motivationManager.customAffirmations) { affirmation in
                            AffirmationCard(affirmation: affirmation)
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }
                    }
                }
                .padding(MomentumDesignTokens.md)
            }
            .padding(.vertical, MomentumDesignTokens.md)
        }
        .sheet(isPresented: $showAddAffirmation) {
            AddAffirmationSheet(
                isPresented: $showAddAffirmation,
                affirmationText: $affirmationText,
                onSave: addAffirmation
            )
        }
        .alert("Motivation Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .onAppear {
            motivationManager.loadTodaysQuote()
        }
    }
    
    private func requestMotivationBoost() {
        isLoadingBoost = true
        
        Task {
            do {
                let mood = moodManager.todaysMood?.level ?? .neutral
                try await motivationManager.getMotivationalBoost(mood: mood)
                isLoadingBoost = false
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                isLoadingBoost = false
            }
        }
    }
    
    private func addAffirmation() {
        do {
            guard !affirmationText.trimmingCharacters(in: .whitespaces).isEmpty else {
                throw AffirmationValidationError.emptyText
            }
            
            motivationManager.addCustomAffirmation(affirmationText)
            affirmationText = ""
            showAddAffirmation = false
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

enum AffirmationValidationError: LocalizedError {
    case emptyText
    
    var errorDescription: String? {
        switch self {
        case .emptyText: return "Please enter an affirmation"
        }
    }
}

// MARK: - Add Affirmation Sheet
struct AddAffirmationSheet: View {
    @Binding var isPresented: Bool
    @Binding var affirmationText: String
    var onSave: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: MomentumDesignTokens.lg) {
                TextEditor(text: $affirmationText)
                    .font(MomentumDesignTokens.bodyMedium)
                    .padding(MomentumDesignTokens.md)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(MomentumDesignTokens.cornerMedium)
                    .frame(minHeight: 150)
                
                Spacer()
            }
            .padding(MomentumDesignTokens.md)
            .navigationTitle("Add Affirmation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Affirmation Card
struct AffirmationCard: View {
    let affirmation: Affirmation
    
    var body: some View {
        VStack(alignment: .leading, spacing: MomentumDesignTokens.sm) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(MomentumColors.accent)
                
                Text(affirmation.text)
                    .font(MomentumDesignTokens.bodyMedium)
                    .lineLimit(nil)
                
                Spacer()
            }
            
            Text(dateFormatter.string(from: affirmation.createdAt))
                .font(MomentumDesignTokens.caption)
                .foregroundColor(.gray)
        }
        .padding(MomentumDesignTokens.md)
        .background(MomentumColors.accent.opacity(0.1))
        .cornerRadius(MomentumDesignTokens.cornerMedium)
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
}

// MARK: - Authentication View
struct AuthenticationView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        VStack(spacing: MomentumDesignTokens.lg) {
            Text("MomentumOS")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(MomentumColors.primary)
            
            Text("Your Personal OS for Self-Improvement")
                .font(MomentumDesignTokens.bodyMedium)
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Onboarding View
struct OnboardingView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        VStack(spacing: MomentumDesignTokens.lg) {
            Text("Welcome to MomentumOS")
                .momentumTitle()
            
            Text("Your personal operating system for self-improvement")
                .momentumSubtitle()
            
            Button(action: {}) {
                Text("Get Started")
            }
            .momentumButton()
        }
        .padding(MomentumDesignTokens.lg)
    }
}

#Preview {
    MomentumOSApp()
}
