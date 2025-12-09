# MomentumOS - Personal Operating System for Self-Improvement
DM ME ON @tanmyster. ON DISCORD IF INTERESTED IN HELPING

MomentumOS is a comprehensive iOS life coaching app that combines productivity, fitness, nutrition, mood tracking, and motivation into a unified platform. Built with SwiftUI, it features an AI-powered life coach, offline-first capability, and seamless integration with Apple services.

## 🎉 Latest Updates (December 2025)

### ✨ UI/UX Enhancements
- **Detailed Feature Views**: All placeholder views replaced with production-ready implementations
- **Smooth Animations**: 
  - Opacity + scale transitions for cards
  - Button scale feedback on press
  - Circular progress ring animations
  - Expandable card animations
- **Error Handling**: Comprehensive validation on all forms with user-friendly error messages
- **Loading States**: Progress indicators for async operations
- **Success Feedback**: Confirmation messages for user actions

### 📱 New Components
- Expandable habit cards with progress bars
- Interactive mood selector with emojis
- Macro breakdown visualization with animated bars
- Quick action buttons on home screen
- Nutrition summary with circular progress
- Focus session customization with duration presets
- Motivation category filtering
- Custom affirmation management

### 📊 Visual Improvements
- Real-time stat cards on home screen
- Weekly workout statistics display
- Daily nutrition tracking with date navigation
- Quote carousel with refresh functionality
- Enhanced form layouts with better spacing
- Empty state messaging
- Consistent use of design tokens

## 🎯 Overview

**What is MomentumOS?**
Your personal operating system for self-improvement. Think of it as a modular life coach that sits on your iPhone, helping you optimize fitness, productivity, nutrition, mental health, and personal growth.

**Target Audience:**
- Males aged 13–30 seeking lifestyle improvement
- Those interested in fitness, productivity, and mental wellness
- Users wanting AI-powered personalized coaching
- People who value privacy and offline-first features

## 🏗️ Architecture

### Core Layers

```
┌─────────────────────────────────┐
│    SwiftUI Views (UI Layer)    │
├─────────────────────────────────┤
│   Feature Managers (State)      │
│ - Focus, Mood, Workout,         │
│ - Food, Habits, Motivation      │
├─────────────────────────────────┤
│   Services (Core Logic)         │
│ - AI Coach, Notifications       │
│ - Subscription, HealthKit       │
├─────────────────────────────────┤
│   Data Layer                    │
│ - Models, StorageManager        │
│ - iCloud Sync, Encryption       │
└─────────────────────────────────┘
```

### Module Structure

```
Sources/MomentumOS/
├── MomentumOS.swift              # App entry point
├── Core/
│   └── Authentication.swift      # User auth, profiles, onboarding
├── Data/
│   ├── Models.swift             # All data structures
│   └── StorageManager.swift      # Local + iCloud persistence
├── Features/
│   ├── FocusWorkoutMood.swift   # Focus timer, workouts, mood tracking
│   ├── FoodHabit.swift          # Food logging, habits
│   └── CalendarMotivation.swift # Tasks, routines, motivation
├── Services/
│   ├── AICoachService.swift     # AI integration
│   ├── SubscriptionManager.swift # StoreKit 2 + paywall
│   ├── NotificationManager.swift # Notifications + engagement
│   └── HealthKitIntegration.swift # Health sync + widgets
└── UI/
    └── Theme.swift              # Colors, design tokens, modifiers
```

## ✨ Core Features

### 📅 Habit + Mood + Mind Tracking
- **Mood Logging:** Emoji-based mood slider (terrible to excellent)
- **Habit Streaks:** Track daily habits with streak visualization
- **Sleep/Energy/Stress:** Log sleep hours, energy levels, stress metrics
- **Journaling:** Link journal entries to mood logs
- **Mind Energy Meter:** AI-estimated focus/clarity score
- **Analytics:** 7-day, 30-day, and yearly trends with charts

### 🎯 Focus Timer + Digital Lockdown
- **Pomodoro Timer:** 25/5/15-minute preset with custom durations
- **App Lockdown:** ManagedSettings API for blocking distracting apps
- **Focus Sessions:** Track deep work with notes and categories
- **Recovery Rings:** Apple Health integration
- **Siri Shortcuts:** Voice-activate focus sessions
- **Weekly Reports:** Screen time summaries and productivity insights

### 💪 Workout & Recovery
- **Manual Logging:** Sets, reps, weight, duration tracking
- **Muscle Groups:** Chest, back, shoulders, legs, core, etc.
- **Recovery Meter:** Soreness, motivation, and readiness scores
- **Heat Maps:** Weekly workout distribution visualization
- **Apple Health Sync:** Auto-sync calories and active minutes
- **Smart Suggestions:** AI suggests exercises based on recovery state

### 🍽️ Food Tracking
- **Manual Meal Logs:** Breakfast, lunch, dinner, snacks
- **Barcode Scanner:** Quick nutrition lookups via barcode
- **AI Image Recognition:** Photo-based food identification (cloud API)
- **Macro Tracking:** Protein, carbs, fats with daily progress
- **Adaptive Feedback:** Meal suggestions based on mood and energy
- **Apple Health Integration:** Calorie sync and export

### 🧘 Motivation Hub
- **Daily Quotes:** Curated motivational quotes (fitness, productivity, gratitude)
- **Custom Affirmations:** User-created personalized mantras
- **AI Boosts:** Context-aware motivation based on mood and streaks
- **Themed Content:** Focus, resilience, gratitude, relationships
- **Audio Clips:** Optional motivational audio (premium feature)

### 🗓️ Calendar & Routines
- **In-App Calendar:** Task and routine scheduling
- **Eisenhower Matrix:** 4-quadrant task prioritization
- **Sync-Out:** Apple Calendar, Google Calendar, Todoist
- **Time Blocking:** Manual or AI-assisted time allocation
- **Routines:** Morning, afternoon, evening workflows
- **Siri Integration:** "Hey Siri, start my morning routine"

### 🔗 Widgets & Shortcuts
- **Home Screen Widgets:** Focus timer, habit streaks, daily quotes
- **Lock Screen Widgets:** Quick habit logging, motivation
- **Siri Shortcuts:** Automated routines and actions
- **Customizable:** Choose which widgets to display

### 👥 Profiles & Social
- **Account Creation:** Email, phone, Apple, Google, Facebook
- **Public Profiles:** Share achievements and stats
- **Friends & Communities:** Follow users, join groups
- **Achievements:** Badges, streaks, milestones
- **Leaderboards:** Compete with friends (optional)

### 🤖 AI Life Coach
The central intelligence layer adapting across all modules:

**Fitness Coach**
- Adaptive workout plans based on recovery and goals
- Home vs. gym exercise alternatives
- Smart suggestions: "Your soreness is high, try lighter weight"

**Nutrition Coach**
- Personalized meal suggestions
- Energy/mood-based recommendations
- Macro target adjustments
- Integration with popular food databases

**Productivity Coach**
- Smart routine generation
- Eisenhower Matrix auto-prioritization
- Adaptive Pomodoro timing
- Time-blocking suggestions

**Mental Health Coach**
- Mood pattern analysis
- Stress and sleep recommendations
- Journaling insights
- Motivational conversations

**Insights & Reports**
- Daily check-ins
- Weekly reviews with actionable tips
- Monthly PDF-style reports
- Burnout and plateau detection

## 🔐 Privacy & Security

- **Offline-First:** All core features work without internet
- **iCloud Sync:** End-to-end encrypted cloud backup
- **Zero-Knowledge Journaling:** Optional privacy mode
- **GDPR/CCPA Compliant:** Full data export/deletion
- **User Control:** Disable AI data collection
- **No Ads Tracking:** Minimal, non-intrusive ads (free tier)

## 💰 Monetization

### Free Tier
- Habit tracking, mood logging, basic workouts
- Manual focus sessions (no advanced features)
- Basic motivation quotes
- Standard notifications
- Limited AI insights

### Premium Tier ($4.99/month, $49.99/year, 7-day free trial)
- **AI Life Coach:** Full personalized recommendations
- **Academy:** Educational courses on fitness, productivity, nutrition
- **Advanced Reports:** PDF exports, predictive insights
- **Premium Themes:** Exclusive color schemes and designs
- **No Ads:** Ad-free experience
- **Priority Support:** Direct app support

### In-App Purchases
- Exclusive theme packs
- Specialized content packs (e.g., "Burnout Recovery Guide")
- Advanced widget customization

## 🚀 Technical Stack

- **Language:** Swift 6.0+
- **Framework:** SwiftUI + AppIntents
- **Minimum iOS:** 16+
- **Database:** FileSystem + iCloud (SwiftData optional)
- **Networking:** URLSession + custom API client
- **Notifications:** UserNotifications + UNUserNotificationCenter
- **HealthKit:** HKHealthStore integration
- **Payments:** StoreKit 2
- **Authentication:** AuthenticationServices (Apple/Google/Facebook)

## 📊 Data Models

### Key Entities
- **User:** Profile, goals, settings, achievements
- **Habit:** Daily tracking with streaks and logs
- **Mood:** Mood level, energy, stress, sleep, triggers
- **Workout:** Type, duration, exercises, recovery data
- **Meal:** Foods, macros, meal type, mood linkage
- **Task:** Title, priority, quadrant, due date
- **Routine:** Time-based task sequences
- **Achievement:** Badges, progress, unlock conditions

## 🔄 Data Flow

```
User Action → Feature Manager → StorageManager → Local/iCloud
                                  ↓
                          AI Coach Service (if online)
                                  ↓
                          Health Kit / Notifications
```

## 🛠️ Development Roadmap

### Phase 1 (Core) ✅
- Core feature managers (Focus, Mood, Workout, Food, Habits)
- Basic UI and navigation
- StorageManager + local persistence
- Theme system
- Authentication scaffolding

### Phase 2 (AI & Integration)
- AI Coach API integration
- HealthKit sync
- Notifications system
- Subscription/paywall
- Siri Shortcuts

### Phase 3 (Polish & Scale)
- WidgetKit implementation
- Watch companion app
- Advanced analytics
- Social features
- Premium content academy

### Phase 4 (Expansion)
- Voice input support
- AR/VR features
- Deep wearable integration
- Community challenges
- Advanced gamification

## 🎮 UI/UX Philosophy

- **Minimal Design:** Clean, functional interfaces
- **Dark-First:** Purple, blue, pink color scheme
- **Smooth Animations:** 300-500ms transitions
- **Functional-First:** Prioritize usability over aesthetics
- **Customizable:** Theme preferences, widget selection
- **Accessible:** WCAG compliant, VoiceOver support

## 🔄 Sync Strategy

- **Offline-First:** All data cached locally
- **Sync-Out Only:** Optional push to Apple Calendar, HealthKit, etc.
- **iCloud Sync:** Automatic cloud backup with encryption
- **Conflict Resolution:** Latest timestamp wins
- **Bandwidth Efficient:** Delta syncs only

## 📱 Supported Devices

- iPhone SE and above
- iOS 16+ required
- Optimized for iPhone 14/15 sizes
- iPad support (future)
- Apple Watch (future)

## 🔗 External Integrations

### Ready to Integrate
- Apple HealthKit (steps, calories, sleep, heart rate)
- Apple Calendar (sync tasks and routines)
- Apple Health (export data)
- Todoist (task sync)

### Planned
- Fitbit API
- Lifesum (nutrition database)
- Google Calendar
- Strava (fitness activities)
- Notion (journaling export)

## 📚 File Locations

- **App Entry:** `Sources/MomentumOS/MomentumOS.swift`
- **Models:** `Sources/MomentumOS/Data/Models.swift`
- **Storage:** `Sources/MomentumOS/Data/StorageManager.swift`
- **Feature Managers:** `Sources/MomentumOS/Features/`
- **Services:** `Sources/MomentumOS/Services/`
- **UI/Theme:** `Sources/MomentumOS/UI/Theme.swift`

## 🤝 Contributing

Future: Contribution guidelines for open-source expansion.

## 📄 License

Proprietary - © 2025 MomentumOS

---

**Built with ❤️ for self-improvement enthusiasts**
