# MomentumOS - Quick Reference Guide

## 🚀 Quick Start (5 Minutes)

### 1. Open the Project
```bash
cd MomentumOS
swift build
```

### 2. Understand the Structure
```
Sources/MomentumOS/
├── MomentumOS.swift      ← Start here (main app)
├── Core/                 ← Authentication
├── Data/                 ← Models & Storage
├── Features/             ← Feature managers
├── Services/             ← API & integrations
└── UI/                   ← Design system
```

### 3. Review Key Files (30 mins)
1. README.md (philosophy)
2. Theme.swift (design)
3. Models.swift (data)
4. MomentumOS.swift (app)

---

## 📋 Core Managers Reference

### `FocusManager.shared`
```swift
// Start a focus session
focusManager.startFocusSession(title: "Work", duration: 25 * 60)

// Check status
if focusManager.isRunning {
    print(focusManager.formatTimeRemaining()) // "25:00"
}

// End session
focusManager.endSession()
```

### `MoodManager.shared`
```swift
// Log mood
moodManager.logMood(
    level: .good,
    energy: 8,
    stress: 3,
    sleep: 7,
    notes: nil,
    triggers: []
)

// Check trend
print(moodManager.moodTrend) // .improving, .stable, .declining
```

### `HabitManager.shared`
```swift
// Create habit
habitManager.createHabit(
    name: "Meditate",
    category: .meditation,
    frequency: .daily,
    icon: "heart.fill"
)

// Toggle completion
habitManager.toggleHabit(habit)

// Check streak
print(habit.currentStreak) // Number of consecutive days
```

### `WorkoutManager.shared`
```swift
// Start workout
workoutManager.startWorkout(type: .strength, intensity: .high)

// Complete workout
workoutManager.completeWorkout()

// Get stats
print(workoutManager.weeklyStats)
// WorkoutStats(totalWorkouts: 3, totalMinutes: 90, ...)
```

### `FoodManager.shared`
```swift
// Add meal
let foods = [
    FoodItem(name: "Chicken", calories: 300, protein: 50, ...),
    FoodItem(name: "Rice", calories: 200, carbs: 45, ...)
]
foodManager.addMeal(type: .lunch, foods: foods)

// Check nutrition
print(foodManager.dailyNutritionSummary.caloriePercentage())
```

### `CalendarManager.shared`
```swift
// Create task
calendarManager.addTask(
    title: "Write report",
    category: .work,
    priority: .high,
    quadrant: .urgentImportant
)

// Get Eisenhower Matrix
let matrix = calendarManager.eisenhowerMatrix
print(matrix.urgentImportant.count)
```

### `MotivationManager.shared`
```swift
// Load today's quote
motivationManager.loadTodaysQuote()
print(motivationManager.todaysQuote?.content)

// Add custom affirmation
motivationManager.addCustomAffirmation("I am capable")

// Get motivation boost
try await motivationManager.getMotivationalBoost(mood: .sad)
```

---

## 🔧 Service Usage

### Authentication
```swift
// Sign up
await AuthenticationManager.shared.signUp(
    email: "user@example.com",
    password: "password",
    name: "John"
)

// Check auth status
if AuthenticationManager.shared.isAuthenticated {
    print("User logged in")
}
```

### Subscriptions
```swift
// Load products
await SubscriptionManager.shared.loadProducts()

// Purchase
await SubscriptionManager.shared.purchaseSubscription(product)

// Check premium status
if SubscriptionManager.shared.isPremium {
    print("Premium features unlocked")
}
```

### Notifications
```swift
// Request permission
await NotificationManager.shared.requestAuthorization()

// Schedule habit reminder
NotificationManager.shared.scheduleHabitReminder(
    habitName: "Meditate",
    time: Date(timeIntervalSinceNow: 3600)
)
```

### AI Coach
```swift
// Get workout suggestion
let plan = try await AICoachService.shared.generateWorkoutPlan(
    goals: goals,
    preferences: preferences,
    recentWorkouts: workouts
)

// Or use offline fallback
let fallback = AICoachService.shared.getOfflineWorkoutSuggestion(
    preferences: preferences
)
```

### HealthKit
```swift
// Save workout to HealthKit
HealthKitManager.shared.saveWorkoutToHealthKit(workout)

// Check authorization
if HealthKitManager.shared.isAuthorized {
    print("HealthKit data available")
}
```

---

## 🎨 Design System Quick Reference

### Colors
```swift
MomentumColors.primary      // Purple
MomentumColors.secondary    // Blue
MomentumColors.accent       // Pink
MomentumColors.success      // Green
MomentumColors.warning      // Orange
MomentumColors.error        // Red
```

### Spacing
```swift
MomentumDesignTokens.xs     // 4pt
MomentumDesignTokens.sm     // 8pt
MomentumDesignTokens.md     // 16pt
MomentumDesignTokens.lg     // 24pt
MomentumDesignTokens.xl     // 32pt
MomentumDesignTokens.xxl    // 48pt
```

### Reusable Modifiers
```swift
.momentumTitle()             // 24pt bold
.momentumSubtitle()          // 14pt gray
.momentumCard()              // Rounded container
.momentumButton()            // Primary button
.momentumSecondaryButton()   // Secondary button
```

---

## 💾 Data Persistence

### Save Data
```swift
let habit = Habit(name: "Meditate")
try? StorageManager.shared.saveHabit(habit)

let mood = MoodEntry(mood: .good, energy: 8)
try? StorageManager.shared.save(mood, to: "Mood/\(mood.id).json")
```

### Load Data
```swift
let habit = try? StorageManager.shared.loadHabit(id: habitId)
let habits = try? StorageManager.shared.loadAllHabits()
```

### Data Structure
```
Documents/
  MomentumOS/
    ├── User/profile.json
    ├── Habits/{id}.json
    ├── Workouts/{id}.json
    ├── Meals/{id}.json
    ├── Tasks/{id}.json
    └── Cache/...
```

---

## 📱 Navigation Structure

### Bottom Tabs (6 Main Areas)
1. **Home** - Dashboard overview
2. **Focus** - Pomodoro timer
3. **Mood** - Emotion tracking
4. **Workout** - Exercise logging
5. **Food** - Nutrition tracking
6. **Motivation** - Quotes & affirmations

### Navigation Usage
```swift
@State private var selectedTab: DashboardView.TabType = .home

// Switch tab
selectedTab = .focus

// Current view updates automatically
```

---

## 🔐 Feature Gating

### Check Premium Status
```swift
@EnvironmentObject var subscriptionManager: SubscriptionManager

var body: some View {
    if subscriptionManager.isPremium {
        // Premium content
        PremiumFeature()
    } else {
        // Paywall
        PaywallView()
    }
}
```

### Use PremiumFeatureGate
```swift
PremiumFeatureGate("Upgrade for AI Coach") {
    AICoachView()
}
```

---

## 🧪 Testing Managers

### Unit Test Pattern
```swift
class HabitManagerTests: XCTestCase {
    let habitManager = HabitManager.shared
    
    func testCreateHabit() {
        habitManager.createHabit(
            name: "Test",
            category: .meditation
        )
        XCTAssertEqual(habitManager.allHabits.count, 1)
    }
}
```

### Manual Testing Checklist
- [ ] Create habit, toggle completion
- [ ] Log mood, check trends
- [ ] Start focus timer
- [ ] Log workout
- [ ] Add meal and check macros
- [ ] Create task
- [ ] Change theme (dark/light)
- [ ] Sign out and back in
- [ ] Close and reopen app (data persists)

---

## ⚡ Performance Tips

### Optimization Strategies
```swift
// Use @StateObject for managers
@StateObject var habitManager = HabitManager.shared

// Use computed properties for calculations
var completionPercentage: Double {
    guard !todaysHabits.isEmpty else { return 0 }
    return Double(completed) / Double(todaysHabits.count) * 100
}

// Batch updates
Task {
    for habit in habits {
        habitManager.toggleHabit(habit)
    }
}
```

---

## 🐛 Common Issues & Solutions

### Issue: App crashes on launch
```swift
// Solution: Check StorageManager initialization
let storage = StorageManager.shared
// Ensure Documents directory exists
```

### Issue: Data not persisting
```swift
// Solution: Check save is called
try? StorageManager.shared.saveHabit(habit)
// Verify file path in Documents/MomentumOS/
```

### Issue: Theme not changing
```swift
// Solution: Use ThemeManager
ThemeManager.shared.setTheme(.dark)
// Check preferredColorScheme in view
```

### Issue: Notifications not showing
```swift
// Solution: Request authorization first
await NotificationManager.shared.requestAuthorization()
// Check notification settings
```

---

## 📚 Documentation Links

- **README.md** - Full feature overview
- **IMPLEMENTATION_GUIDE.md** - Detailed dev guide
- **FILE_INVENTORY.md** - Complete file reference
- **PROJECT_SUMMARY.md** - Status and roadmap
- **Inline Comments** - Code documentation

---

## 🎯 Development Workflow

### 1. View Planning
```swift
struct NewFeatureView: View {
    @EnvironmentObject var featureManager: FeatureManager
    
    var body: some View {
        // Build UI here
    }
}
```

### 2. Manager Creation
```swift
@MainActor
class NewFeatureManager: ObservableObject {
    @Published var data: [Item] = []
    
    func addItem(_ item: Item) {
        data.append(item)
        // Save to storage
    }
}
```

### 3. Integration
```swift
// Add to DashboardView
.environmentObject(NewFeatureManager.shared)

// Use in view
@EnvironmentObject var manager: NewFeatureManager
```

### 4. Storage
```swift
// Add to Models.swift
struct NewItem: Codable { }

// Add to StorageManager
func saveNewItem(_ item: NewItem) throws {
    try save(item, to: "Items/\(item.id).json")
}
```

---

## 🚀 Build & Run

### Build for Simulator
```bash
swift build
```

### Run on Simulator
```bash
open -a Simulator
swift run
```

### Build for Device
```bash
# In Xcode:
# 1. Select device
# 2. Product > Build
# 3. Product > Run
```

---

## 📞 Quick Help

### "Where do I add a new feature?"
→ Create manager in `Features/`, view in `MomentumOS.swift`

### "How do I save data?"
→ Use `StorageManager.shared.save(item, to: path)`

### "How do I add a button?"
→ Use `.momentumButton()` modifier from `Theme.swift`

### "How do I check if user is premium?"
→ Check `SubscriptionManager.shared.isPremium`

### "How do I schedule a notification?"
→ Use `NotificationManager.shared.schedule...()`

---

## 🎉 You're Ready!

You have everything needed to:
✅ Build new features
✅ Manage state
✅ Persist data
✅ Integrate services
✅ Polish UI
✅ Deploy to App Store

**Start coding! 🚀**

---

*Quick Reference v1.0 - December 9, 2025*
