import SwiftUI
import Combine

// MARK: - Calendar & Task Manager
@MainActor
class CalendarManager: ObservableObject {
    static let shared = CalendarManager()
    
    @Published var allTasks: [Task] = []
    @Published var selectedDate: Date = Date()
    @Published var tasksForSelectedDate: [Task] = []
    @Published var eisenhowerMatrix: EisenhowerMatrix = EisenhowerMatrix()
    
    private let storage = StorageManager.shared
    
    func addTask(
        title: String,
        category: TaskCategory,
        priority: Priority = .medium,
        quadrant: EisenhowerQuadrant = .important,
        dueDate: Date? = nil
    ) {
        let task = Task(
            title: title,
            category: category,
            priority: priority,
            quadrant: quadrant,
            dueDate: dueDate
        )
        
        allTasks.append(task)
        try? storage.saveTask(task)
        updateEisenhowerMatrix()
    }
    
    func completeTask(_ task: Task) {
        guard var mutableTask = allTasks.first(where: { $0.id == task.id }) else { return }
        
        mutableTask.isCompleted = true
        mutableTask.completedAt = Date()
        
        if let index = allTasks.firstIndex(where: { $0.id == task.id }) {
            allTasks[index] = mutableTask
            try? storage.saveTask(mutableTask)
        }
    }
    
    func deleteTask(_ task: Task) {
        allTasks.removeAll { $0.id == task.id }
        try? storage.delete("Tasks/\(task.id).json")
    }
    
    func selectDate(_ date: Date) {
        selectedDate = date
        updateTasksForDate()
    }
    
    private func updateTasksForDate() {
        let calendar = Calendar.current
        tasksForSelectedDate = allTasks.filter { task in
            if let dueDate = task.dueDate {
                return calendar.isDate(dueDate, inSameDayAs: selectedDate)
            }
            return calendar.isDate(task.startDate, inSameDayAs: selectedDate)
        }
    }
    
    private func updateEisenhowerMatrix() {
        var urgentImportant: [Task] = []
        var notUrgentImportant: [Task] = []
        var urgentNotImportant: [Task] = []
        var notUrgentNotImportant: [Task] = []
        
        for task in allTasks {
            let isUrgent = task.priority == .high || task.priority == .critical
            let isImportant = task.quadrant == .important
            
            if isUrgent && isImportant {
                urgentImportant.append(task)
            } else if !isUrgent && isImportant {
                notUrgentImportant.append(task)
            } else if isUrgent && !isImportant {
                urgentNotImportant.append(task)
            } else {
                notUrgentNotImportant.append(task)
            }
        }
        
        eisenhowerMatrix = EisenhowerMatrix(
            urgentImportant: urgentImportant,
            notUrgentImportant: notUrgentImportant,
            urgentNotImportant: urgentNotImportant,
            notUrgentNotImportant: notUrgentNotImportant
        )
    }
    
    func loadAllTasks() {
        allTasks = (try? storage.loadAllTasks()) ?? []
        updateEisenhowerMatrix()
    }
}

struct EisenhowerMatrix: Codable {
    var urgentImportant: [Task] = []
    var notUrgentImportant: [Task] = []
    var urgentNotImportant: [Task] = []
    var notUrgentNotImportant: [Task] = []
}

// MARK: - Routine Manager
@MainActor
class RoutineManager: ObservableObject {
    static let shared = RoutineManager()
    
    @Published var morningRoutine: Routine?
    @Published var afternoonRoutine: Routine?
    @Published var eveningRoutine: Routine?
    @Published var allRoutines: [Routine] = []
    
    private let storage = StorageManager.shared
    
    func createRoutine(
        name: String,
        timeOfDay: RoutineTime,
        tasks: [RoutineTask]
    ) {
        let routine = Routine(
            name: name,
            timeOfDay: timeOfDay,
            tasks: tasks
        )
        
        allRoutines.append(routine)
        setRoutineForTime(routine)
        // TODO: Save to storage
    }
    
    func startRoutine(_ routine: Routine) {
        // Trigger first task
        // TODO: Integrate with Siri Shortcuts
    }
    
    func completeRoutineTask(_ taskId: UUID, in routine: inout Routine) {
        if let index = routine.tasks.firstIndex(where: { $0.id == taskId }) {
            routine.tasks[index].order += 1
        }
    }
    
    func generateAIRoutine(goals: [Goal]) async {
        do {
            let dayRoutine = try await AICoachService.shared.generateDayRoutine(
                goals: goals,
                habits: [],
                tasks: []
            )
            
            // Convert AI response to Routine objects
            let routine = convertToRoutine(dayRoutine: dayRoutine)
            allRoutines.append(routine)
        } catch {
            // Fallback to default routines
            createDefaultRoutines()
        }
    }
    
    private func convertToRoutine(dayRoutine: DayRoutine) -> Routine {
        let routineTasks = dayRoutine.timeBlocks.enumerated().map { index, timeBlock in
            RoutineTask(title: timeBlock.title, order: index)
        }
        
        return Routine(
            name: "AI Generated Routine",
            timeOfDay: .morning,
            tasks: routineTasks
        )
    }
    
    private func createDefaultRoutines() {
        let morningTasks = [
            RoutineTask(title: "Meditate", duration: 10 * 60, order: 1),
            RoutineTask(title: "Exercise", duration: 30 * 60, order: 2),
            RoutineTask(title: "Breakfast", duration: 15 * 60, order: 3)
        ]
        
        let morning = Routine(
            name: "Morning Routine",
            timeOfDay: .morning,
            tasks: morningTasks
        )
        
        morningRoutine = morning
    }
    
    private func setRoutineForTime(_ routine: Routine) {
        switch routine.timeOfDay {
        case .morning:
            morningRoutine = routine
        case .afternoon:
            afternoonRoutine = routine
        case .evening:
            eveningRoutine = routine
        default:
            break
        }
    }
}

// MARK: - Motivation Manager
@MainActor
class MotivationManager: ObservableObject {
    static let shared = MotivationManager()
    
    @Published var todaysQuote: MotivationEntry?
    @Published var customAffirmations: [Affirmation] = []
    @Published var allQuotes: [MotivationEntry] = []
    
    private let storage = StorageManager.shared
    private let quotes = [
        "Every small step forward is still progress.",
        "Discipline is choosing what you want most over what you want now.",
        "Your body can stand almost anything. It's your mind you need to convince.",
        "Progress, not perfection.",
        "Don't watch the clock; do what it does. Keep going.",
        "The only impossible journey is the one you never begin.",
        "You are capable of amazing things."
    ]
    
    func loadTodaysQuote() {
        let randomQuote = quotes.randomElement() ?? "Keep moving forward"
        todaysQuote = MotivationEntry(
            type: .quote,
            content: randomQuote,
            author: "MomentumOS",
            category: .general
        )
    }
    
    func addCustomAffirmation(_ text: String, category: MotivationCategory = .general) {
        let affirmation = Affirmation(text: text, category: category, isCustom: true)
        customAffirmations.append(affirmation)
        // TODO: Save to storage
    }
    
    func getMotivationalBoost(mood: MoodLevel) async {
        do {
            let response = try await AICoachService.shared.getMotivationalBoost(
                mood: mood,
                context: "User needs motivation"
            )
            
            let entry = MotivationEntry(
                type: .affirmation,
                content: response.message,
                category: response.category
            )
            
            allQuotes.insert(entry, at: 0)
        } catch {
            // Fallback
            let fallback = MotivationEntry(
                type: .affirmation,
                content: "You've got this!",
                category: .general
            )
            allQuotes.insert(fallback, at: 0)
        }
    }
    
    func getQuoteByCategory(_ category: MotivationCategory) -> MotivationEntry? {
        allQuotes.first { $0.category == category }
    }
}
