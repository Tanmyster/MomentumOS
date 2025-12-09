# MomentumOS - Implementation Guide

## 📋 Project Overview

MomentumOS is a fully-architected iOS life coaching app built with SwiftUI. This implementation includes:

- ✅ Complete data models for all features
- ✅ Feature managers with state management
- ✅ Authentication and user profiles
- ✅ Theme system with dark/light modes
- ✅ Local and iCloud persistence
- ✅ AI Coach integration layer
- ✅ Subscription & monetization framework
- ✅ Notification system
- ✅ HealthKit and Apple Calendar integration
- ✅ Bottom-tab navigation with 6 main modules

## 🎯 What's Included

### Core Architecture
- **MomentumOS.swift:** App entry point with DashboardView
- **Models.swift:** 30+ data structures for all features
- **StorageManager.swift:** Local/iCloud persistence layer
- **Theme.swift:** Design tokens, color scheme, accessible modifiers
- **Authentication.swift:** Multi-provider auth, profiles, onboarding

### Feature Managers
- **FocusManager:** Pomodoro timer, digital lockdown, focus sessions
- **MoodManager:** Mood tracking, energy, stress, sleep, trends
- **WorkoutManager:** Exercise logging, recovery score, stats
- **FoodManager:** Meal logging, macro tracking, nutrition summary
- **HabitManager:** Daily habits, streaks, completion tracking
- **CalendarManager:** Tasks, Eisenhower Matrix, routines
- **MotivationManager:** Quotes, affirmations, AI boosts
- **RoutineManager:** Time-based task sequences, AI generation

### Services
- **AICoachService.swift:** Cloud API client with offline fallbacks
- **SubscriptionManager.swift:** StoreKit 2, premium tier, paywall
- **NotificationManager.swift:** Gamified notifications, reminders, quiet hours
- **HealthKitIntegration.swift:** HealthKit sync, Apple Calendar, Siri Shortcuts

### UI Components
- Dashboard with 6 bottom-tab navigation
- Home, Focus, Mood, Workout, Food, Motivation tabs
- Habit cards with streaks
- Focus timer display
- Mood slider with emoji feedback
- Workout statistics
- Reusable design tokens and modifiers

## 🚀 Getting Started

### Prerequisites
```
- Xcode 15.4+
- Swift 6.0+
- iOS 16.0+ target
- CocoaPods (optional for external libraries)
```

### Installation

1. **Open Package.swift**
   - Dependencies are already configured
   - Includes Alamofire, AsyncAlgorithms, Crypto, Amplitude

2. **Build the Project**
   ```bash
   cd MomentumOS
   swift build
   ```

3. **Run on Simulator**
   ```bash
   swift run
   ```

### Key Files to Review

1. **MomentumOS.swift** - App structure and navigation
2. **Models.swift** - Data model reference
3. **Theme.swift** - Design system and modifiers
4. **StorageManager.swift** - Data persistence patterns
5. **FocusWorkoutMood.swift** - Feature manager examples

## 🏗️ Architecture Details

### State Management
- Each feature has its own `@MainActor` manager (ObservableObject)
- Managers are singletons with `.shared` access
- Views observe managers via `@EnvironmentObject`
- SwiftUI's built-in Combine integration handles updates

### Data Flow
```
User Action
    ↓
SwiftUI View
    ↓
Feature Manager (FocusManager, MoodManager, etc.)
    ↓
StorageManager (save/load JSON)
    ↓
Filesystem or iCloud
```

### Example: Logging a Habit
```swift
// User taps checkbox in UI
HabitManager.shared.toggleHabit(habit)

// Manager updates state
var updatedHabit = habit
updatedHabit.logs.append(HabitLog(...))
allHabits[index] = updatedHabit

// Persists to storage
try? storage.saveHabit(updatedHabit)

// SwiftUI automatically refreshes via @Published
```

## 💾 Data Persistence

### Current Implementation
- **Local Storage:** JSON files in Documents directory
- **iCloud Sync:** Automatic sync to iCloud container
- **Encryption:** Framework ready (CryptoKit integration)

### File Structure
```
Documents/
  MomentumOS/
    ├── User/
    │   └── profile.json
    ├── Habits/
    │   ├── {uuid}.json
    │   └── ...
    ├── Workouts/
    │   ├── {uuid}.json
    │   └── ...
    ├── Meals/
    │   ├── {uuid}.json
    │   └── ...
    ├── Tasks/
    │   ├── {uuid}.json
    │   └── ...
    └── Cache/
```

### Example: Save/Load
```swift
// Save
let habit = Habit(name: "Meditate", category: .meditation)
try? storage.saveHabit(habit)

// Load
if let habit = try? storage.loadHabit(id: habitId) {
    // Use habit
}

// Load all
let habits = try? storage.loadAllHabits()
```

## 🎨 Design System

### Colors
- **Primary:** Purple (RGB: 0.7, 0.4, 1.0)
- **Secondary:** Blue (RGB: 0.4, 0.7, 1.0)
- **Accent:** Pink (RGB: 1.0, 0.4, 0.7)
- **Dark Background:** RGB: 0.08, 0.08, 0.12
- **Light Background:** RGB: 0.95, 0.95, 0.97

### Spacing
```swift
.xs = 4    .sm = 8    .md = 16   .lg = 24   .xl = 32   .xxl = 48
```

### Typography
```swift
.titleLarge = 32pt bold
.titleMedium = 24pt bold
.titleSmall = 18pt semibold
.bodyLarge = 16pt regular
.bodyMedium = 14pt regular
.bodySmall = 12pt regular
```

### Reusable Modifiers
```swift
Text("Title").momentumTitle()
Text("Subtitle").momentumSubtitle()
VStack { ... }.momentumCard()
Button { ... }.momentumButton()
Button { ... }.momentumSecondaryButton()
```

## 🔐 Authentication

### Supported Methods
- Email/password
- Apple Sign-In
- Google Sign-In (framework ready)
- Facebook Sign-In (framework ready)

### Usage
```swift
// Sign up
await AuthenticationManager.shared.signUp(
    email: "user@example.com",
    password: "securePassword",
    name: "John Doe"
)

// Check authentication
if authManager.isAuthenticated {
    // Show main app
}
```

## 🤖 AI Coach Integration

### Current Implementation
- Framework ready with fallback offline responses
- API client for cloud-based suggestions
- Example endpoints: `/workout-plan`, `/meal-suggestion`, `/mood-support`

### Usage Example
```swift
// Request AI suggestion
let plan = try await AICoachService.shared.generateWorkoutPlan(
    goals: userGoals,
    preferences: preferences,
    recentWorkouts: workouts
)

// Or use offline fallback
let plan = AICoachService.shared.getOfflineWorkoutSuggestion(preferences: preferences)
```

## 📢 Notifications

### Setup
```swift
// Request permission
await notificationManager.requestAuthorization()

// Schedule habit reminder
notificationManager.scheduleHabitReminder(habitName: "Meditate", time: Date())
```

### Features
- Gamified messages ("Keep your streak going! 🔥")
- Quiet hours support
- Sound & haptic feedback
- Custom notification types

## 💳 Subscriptions

### StoreKit 2 Integration
```swift
// Load products
await subscriptionManager.loadProducts()

// Purchase
await subscriptionManager.purchaseSubscription(product)

// Check status
if subscriptionManager.isPremium {
    // Show premium features
}
```

### Paywall View
- Included `PaywallView()` component
- Feature list with benefits
- Product selection and pricing
- Restore purchases functionality

## 🏥 HealthKit Integration

### Setup
```swift
// Request authorization
await healthKitManager.requestHealthKitAuthorization()

// Save workout
healthKitManager.saveWorkoutToHealthKit(workout)
```

### Data Synced
- Steps, calories, active minutes
- Heart rate
- Sleep data (7-day history)

## 📱 Next Steps to Complete

### Immediate (Phase 1)
1. **Replace Placeholder Views**
   - FoodTrackingView (currently placeholder)
   - MotivationView (currently placeholder)
   - Expand HomeView with more widgets

2. **Complete Managers**
   - Add missing error handling
   - Implement retry logic
   - Add edge case handling

3. **UI Polish**
   - Add smooth transitions
   - Implement more animations
   - Create detailed views for each feature

### Short-term (Phase 2)
1. **Backend Integration**
   - Set up API server
   - Implement AI Coach endpoints
   - Add user authentication API

2. **HealthKit Complete**
   - Finish integration for all data types
   - Test Apple Health import/export
   - Add permissions handling

3. **Widget Implementation**
   - Create WidgetKit extension
   - Design lock screen widgets
   - Add live activity support

### Medium-term (Phase 3)
1. **Social Features**
   - Friends list implementation
   - Achievement system
   - Leaderboards

2. **Advanced Analytics**
   - Charts and graphs
   - Trend analysis
   - Predictive insights

3. **Siri Shortcuts**
   - Create AppIntents
   - Build shortcut commands
   - Voice interaction

### Long-term (Phase 4)
1. **Apple Watch**
   - Companion watch app
   - Complications
   - Activity ring integration

2. **Content Academy**
   - Educational videos
   - Fitness guides
   - Productivity courses

3. **Community**
   - Group challenges
   - Social sharing
   - Referral system

## 🧪 Testing

### Manual Testing Checklist
- [ ] Authentication flow (all providers)
- [ ] Habit creation and tracking
- [ ] Mood logging with trends
- [ ] Focus session timer
- [ ] Workout logging
- [ ] Food macro calculation
- [ ] Task creation and completion
- [ ] Theme switching (light/dark)
- [ ] Offline capability
- [ ] Data persistence (reload app)
- [ ] iCloud sync (multi-device)
- [ ] Notifications (all types)
- [ ] Subscription flow
- [ ] HealthKit integration

### Unit Test Structure
```swift
// Example test structure
class FocusManagerTests: XCTestCase {
    var focusManager: FocusManager!
    
    override func setUp() {
        focusManager = FocusManager.shared
    }
    
    func testStartFocusSession() {
        focusManager.startFocusSession(title: "Work", duration: 1500)
        XCTAssertNotNil(focusManager.currentSession)
        XCTAssert(focusManager.isRunning)
    }
}
```

## 🔗 External API Integration Points

### Ready to Implement
- **HealthKit API:** For fitness data
- **EventKit:** For calendar sync
- **StoreKit 2:** For subscriptions (framework ready)
- **UserNotifications:** For reminders (implemented)

### To Add
- Custom AI Coach backend (REST API)
- Todoist API (task sync)
- Fitbit API (fitness devices)
- Lifesum API (nutrition database)
- Google Calendar API (calendar sync)

## 📚 Documentation Files

- **README.md:** Feature overview and philosophy
- **ARCHITECTURE.md:** Technical deep dive
- **API_REFERENCE.md:** Manager and service documentation
- **DESIGN_SYSTEM.md:** UI/UX guidelines

## 🐛 Common Issues & Solutions

### Issue: Storage directory not found
```swift
// Solution: StorageManager creates directories automatically
let storage = StorageManager.shared
await storage.initialize() // Called in init
```

### Issue: iCloud sync not working
```swift
// Ensure entitlements are set in Xcode:
// - Capabilities > iCloud > CloudKit enabled
// - Container ID matches code
```

### Issue: Notifications not appearing
```swift
// Verify:
await notificationManager.requestAuthorization()
// Check notification settings in Settings app
```

## 🎓 Learning Resources

- SwiftUI Documentation: https://developer.apple.com/tutorials/swiftui
- Combine: https://developer.apple.com/documentation/combine
- HealthKit: https://developer.apple.com/documentation/healthkit
- StoreKit 2: https://developer.apple.com/documentation/storekit
- UserNotifications: https://developer.apple.com/documentation/usernotifications

## 📞 Support

For questions or issues:
1. Check the README.md
2. Review inline code comments
3. Check Apple developer documentation
4. Test with print statements in managers

---

**Happy Building! 🚀**

Remember: This is a fully modular architecture. You can extend any part independently without affecting others.
