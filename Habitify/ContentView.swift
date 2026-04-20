import SwiftUI
import Combine
import Charts
import UserNotifications
import NaturalLanguage

// MARK: - Notification Manager
class NotificationManager {
    static let shared = NotificationManager()
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in
            if let error = error {
                print("Notification auth error: \(error.localizedDescription)")
            }
        }
    }
    
    func scheduleNotification(for habit: Habit) {
        cancelNotification(for: habit.id.uuidString)
        guard let reminderTime = habit.reminderTime else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Habit Reminder"
        content.body = "Time for your habit: \(habit.name)! Keep your streak going 🔥"
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(identifier: habit.id.uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    func cancelNotification(for id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
}

// MARK: - Models
enum TimeOfDay: String, Codable, CaseIterable {
    case morning = "Morning Routine"
    case afternoon = "Afternoon Tasks"
    case evening = "Evening Routine"
    case anytime = "Anytime"
    
    var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening: return "moon.stars.fill"
        case .anytime: return "clock.fill"
        }
    }
}

enum HabitCategory: String, Codable, CaseIterable {
    case health = "Health"
    case productivity = "Productivity"
    case mindfulness = "Mindfulness"
    case learning = "Learning"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .health: return "heart.fill"
        case .productivity: return "briefcase.fill"
        case .mindfulness: return "leaf.fill"
        case .learning: return "book.fill"
        case .other: return "star.fill"
        }
    }
}

enum FailureReason: String, Codable, CaseIterable {
    case lackOfTime = "Lack of Time"
    case lowEnergy = "Low Energy"
    case unexpectedEvent = "Unexpected Event"
    case forgot = "Forgot"
    case other = "Other"
}

struct FailureLog: Codable, Identifiable {
    var id = UUID()
    let date: Date
    let reason: FailureReason
}

struct DailyNote: Codable, Identifiable {
    var id = UUID()
    var date: Date
    var text: String
    var sentimentScore: Double = 0.0
}

struct MoodEntry: Identifiable, Codable {
    var id = UUID()
    var val: Int
    var label: String
    var timestamp: Date
    var contextTag: String?
    var weather: String?
}

enum MoodType: String, CaseIterable {
    case ecstatic, radiant, excited, productive, calm, neutral, tired, anxious, stressed, sad, lonely, low, frustrated, angry, overwhelmed
    
    var score: Int {
        switch self {
        case .ecstatic, .radiant, .excited: return 7
        case .productive, .calm: return 6
        case .neutral: return 5
        case .tired: return 4
        case .anxious, .stressed: return 3
        case .sad, .lonely, .low: return 2
        case .frustrated, .angry, .overwhelmed: return 1
        }
    }
    
    var label: String {
        return self.rawValue.capitalized
    }
    
    var color: Color {
        switch self.score {
        case 7: return .yellow
        case 6: return .green
        case 5: return .gray
        case 4: return .blue
        case 3: return .orange
        case 2: return .purple
        case 1: return .red
        default: return .gray
        }
    }
    
    var icon: String {
        switch self {
        case .ecstatic: return "star.fill"
        case .radiant: return "sun.max.fill"
        case .excited: return "sparkles"
        case .productive: return "bolt.fill"
        case .calm: return "leaf.fill"
        case .neutral: return "face.smiling"
        case .tired: return "zzz"
        case .anxious: return "wind"
        case .stressed: return "waveform.path.ecg"
        case .sad: return "cloud.rain.fill"
        case .lonely: return "person.fill.xmark"
        case .low: return "arrow.down.to.line"
        case .frustrated: return "exclamationmark.circle.fill"
        case .angry: return "flame.fill"
        case .overwhelmed: return "exclamationmark.triangle.fill"
        }
    }
}

struct MoodChartData: Identifiable {
    let id = UUID()
    let date: Date
    let avgVal: Double
    let dailyNotes: [DailyNote]
}

enum HabitFrequency: Codable {
    case daily
    case specificDays([Int])
    case timesPerWeek(Int)
    case onceAWeek
    case onceAMonth
    
    enum CodingKeys: String, CodingKey {
        case type
        case value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "daily": self = .daily
        case "specificDays":
            let days = try container.decode([Int].self, forKey: .value)
            self = .specificDays(days)
        case "timesPerWeek":
            let times = try container.decode(Int.self, forKey: .value)
            self = .timesPerWeek(times)
        case "onceAWeek": self = .onceAWeek
        case "onceAMonth": self = .onceAMonth
        default: self = .daily
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .daily: try container.encode("daily", forKey: .type)
        case .specificDays(let days):
            try container.encode("specificDays", forKey: .type)
            try container.encode(days, forKey: .value)
        case .timesPerWeek(let times):
            try container.encode("timesPerWeek", forKey: .type)
            try container.encode(times, forKey: .value)
        case .onceAWeek: try container.encode("onceAWeek", forKey: .type)
        case .onceAMonth: try container.encode("onceAMonth", forKey: .type)
        }
    }
}

struct Subtask: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
}

struct Habit: Identifiable, Codable {
    var id = UUID()
    var name: String
    var createdAt = Date()
    
    var category: HabitCategory
    var themeColorHex: String
    var frequency: HabitFrequency
    var timeOfDay: TimeOfDay = .anytime
    var reminderTime: Date?
    
    var completedDates: Set<Date> = []
    var skippedDates: Set<Date> = []
    
    var importanceWeight: Double = 3.0
    var failureLogs: [FailureLog] = []
    
    var targetCount: Int = 1
    var progressCounts: [String: Int] = [:] // "yyyy-MM-dd" -> count

    var subtasks: [Subtask] = []
    var subtaskProgress: [String: Set<UUID>] = [:]
    
    enum CodingKeys: String, CodingKey {
        case id, name, createdAt, category, themeColorHex, frequency, timeOfDay, reminderTime, completedDates, skippedDates, importanceWeight, failureLogs, targetCount, progressCounts, subtasks, subtaskProgress
    }
    
    init(id: UUID = UUID(), name: String, createdAt: Date = Date(), category: HabitCategory, themeColorHex: String, frequency: HabitFrequency, timeOfDay: TimeOfDay = .anytime, reminderTime: Date? = nil, importanceWeight: Double = 3.0, targetCount: Int = 1, subtasks: [Subtask] = []) {
        self.id = id; self.name = name; self.createdAt = createdAt; self.category = category; self.themeColorHex = themeColorHex; self.frequency = frequency; self.timeOfDay = timeOfDay; self.reminderTime = reminderTime; self.importanceWeight = importanceWeight; self.targetCount = targetCount; self.subtasks = subtasks
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        category = try container.decode(HabitCategory.self, forKey: .category)
        themeColorHex = try container.decode(String.self, forKey: .themeColorHex)
        frequency = try container.decode(HabitFrequency.self, forKey: .frequency)
        timeOfDay = try container.decodeIfPresent(TimeOfDay.self, forKey: .timeOfDay) ?? .anytime
        reminderTime = try container.decodeIfPresent(Date.self, forKey: .reminderTime)
        completedDates = try container.decodeIfPresent(Set<Date>.self, forKey: .completedDates) ?? []
        skippedDates = try container.decodeIfPresent(Set<Date>.self, forKey: .skippedDates) ?? []
        importanceWeight = try container.decodeIfPresent(Double.self, forKey: .importanceWeight) ?? 3.0
        failureLogs = try container.decodeIfPresent([FailureLog].self, forKey: .failureLogs) ?? []
        targetCount = try container.decodeIfPresent(Int.self, forKey: .targetCount) ?? 1
        progressCounts = try container.decodeIfPresent([String: Int].self, forKey: .progressCounts) ?? [:]
        subtasks = try container.decodeIfPresent([Subtask].self, forKey: .subtasks) ?? []
        subtaskProgress = try container.decodeIfPresent([String: Set<UUID>].self, forKey: .subtaskProgress) ?? [:]
    }
    
    func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    func dailyScore(for date: Date) -> Double {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        if completedDates.contains(normalizedDate) {
            return importanceWeight
        }
        return 0.0
    }
    
    var currentStreak: Int {
        var streak = 0
        var currentDate = Calendar.current.startOfDay(for: Date())
        
        // If today is not completed, check if yesterday was (to keep streak alive)
        if !completedDates.contains(currentDate) {
            if let prevDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate),
               completedDates.contains(prevDate) {
                currentDate = prevDate
            } else {
                return 0
            }
        }
        
        while completedDates.contains(currentDate) {
            streak += 1
            if let prevDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) {
                currentDate = prevDate
            } else {
                break
            }
            
            // Safety breakout to prevent any possible infinite loop
            if streak > 10000 { break }
        }
        
        return streak
    }
    
    var nextMilestone: Int {
        let milestones = [7, 14, 30, 50, 100, 365]
        return milestones.first(where: { $0 > currentStreak }) ?? currentStreak + 30
    }
    
    var taskHorizon: TaskHorizon {
        guard let date = reminderTime else { return .anytime }
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            return .today
        } else if cal.startOfDay(for: date) < cal.startOfDay(for: Date()) {
            return .overdue
        } else if cal.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            return .week
        } else if cal.isDate(date, equalTo: Date(), toGranularity: .month) {
            return .month
        }
        return .anytime
    }
}

struct BadHabit: Identifiable, Codable {
    var id = UUID()
    var name: String
    var startDate: Date = Date()
    var relapseDates: [Date] = []
    var themeColorHex: String = "FF3B30"
    
    var currentStreak: Int {
        let lastDate = relapseDates.max() ?? startDate
        let components = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: lastDate), to: Calendar.current.startOfDay(for: Date()))
        return max(0, components.day ?? 0)
    }
    
    var highestStreak: Int {
        var maxStreak = 0
        var previousDate = Calendar.current.startOfDay(for: startDate)
        
        let sortedRelapses = relapseDates.map { Calendar.current.startOfDay(for: $0) }.sorted()
        
        for relapse in sortedRelapses {
            let diff = Calendar.current.dateComponents([.day], from: previousDate, to: relapse).day ?? 0
            if diff > maxStreak { maxStreak = diff }
            previousDate = relapse
        }
        
        let diffNow = Calendar.current.dateComponents([.day], from: previousDate, to: Calendar.current.startOfDay(for: Date())).day ?? 0
        if diffNow > maxStreak { maxStreak = diffNow }
        
        return maxStreak
    }
}

enum AppTheme: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
}

enum TaskHorizon: String, CaseIterable {
    case overdue = "Pending / High Alert"
    case today = "Today's Tasks"
    case week = "This Week"
    case month = "This Month"
    case anytime = "Anytime / Daily"
    
    var icon: String {
        switch self {
        case .overdue: return "exclamationmark.triangle.fill"
        case .today: return "sun.max.fill"
        case .week: return "calendar"
        case .month: return "calendar.circle.fill"
        case .anytime: return "infinity"
        }
    }
}

// MARK: - ViewModel
class HabitTrackerViewModel: ObservableObject {
    @Published var habits: [Habit] = [] {
        didSet { saveHabits() }
    }
    
    @Published var badHabits: [BadHabit] = [] {
        didSet { saveBadHabits() }
    }
    
    @Published var dailyNotes: [DailyNote] = [] {
        didSet { saveNotes() }
    }
    
    @Published var moodEntries: [MoodEntry] = [] {
        didSet { saveMoodEntries() }
    }
    
    @Published var lastMoodLogDate: Date? {
        didSet { saveLastMoodLogDate() }
    }
    
    private let saveKey = "SavedHabits"
    private let badHabitsKey = "SavedBadHabits"
    private let notesKey = "SavedNotes"
    private let moodKey = "SavedMoodEntries"
    private let lastMoodLogKey = "LastMoodLogDateKey"
    
    init() {
        loadHabits()
        loadBadHabits()
        loadNotes()
        loadMoodEntries()
        loadLastMoodLogDate()
    }
    
    func addBadHabit(name: String, colorHex: String = "FF3B30") {
        badHabits.append(BadHabit(name: name, startDate: Date(), themeColorHex: colorHex))
    }
    
    func logRelapse(for badHabit: BadHabit) {
        if let index = badHabits.firstIndex(where: { $0.id == badHabit.id }) {
            badHabits[index].relapseDates.append(Date())
        }
    }
    
    func deleteBadHabit(at offsets: IndexSet) {
        badHabits.remove(atOffsets: offsets)
    }
    
    func logMood(type: MoodType, context: String, weather: String) {
        let entry = MoodEntry(val: type.score, label: type.label, timestamp: Date(), contextTag: context.isEmpty ? nil : context, weather: weather.isEmpty ? nil : weather)
        moodEntries.append(entry)
        lastMoodLogDate = Date()
    }

    func addHabit(name: String, category: HabitCategory, themeColorHex: String, frequency: HabitFrequency, timeOfDay: TimeOfDay, reminderTime: Date?, importanceWeight: Double, targetCount: Int = 1, subtasks: [Subtask] = []) {
        let newHabit = Habit(
            name: name,
            category: category,
            themeColorHex: themeColorHex,
            frequency: frequency,
            timeOfDay: timeOfDay,
            reminderTime: reminderTime,
            importanceWeight: importanceWeight,
            targetCount: max(1, targetCount),
            subtasks: subtasks
        )
        habits.append(newHabit)
        if reminderTime != nil {
            NotificationManager.shared.requestAuthorization()
            NotificationManager.shared.scheduleNotification(for: newHabit)
        }
    }
    
    func updateHabit(habit: Habit, name: String, category: HabitCategory, themeColorHex: String, frequency: HabitFrequency, timeOfDay: TimeOfDay, reminderTime: Date?, importanceWeight: Double, targetCount: Int, subtasks: [Subtask] = []) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            habits[index].name = name
            habits[index].category = category
            habits[index].themeColorHex = themeColorHex
            habits[index].frequency = frequency
            habits[index].timeOfDay = timeOfDay
            habits[index].reminderTime = reminderTime
            habits[index].importanceWeight = importanceWeight
            habits[index].targetCount = max(1, targetCount)
            habits[index].subtasks = subtasks
            
            NotificationManager.shared.cancelNotification(for: habit.id.uuidString)
            if reminderTime != nil {
                NotificationManager.shared.requestAuthorization()
                NotificationManager.shared.scheduleNotification(for: habits[index])
            }
        }
    }
    
    func logFailure(for habit: Habit, reason: FailureReason) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            let today = Calendar.current.startOfDay(for: Date())
            // Remove completion if exists
            habits[index].completedDates.remove(today)
            // Add failure log
            let log = FailureLog(date: today, reason: reason)
            habits[index].failureLogs.removeAll(where: { Calendar.current.isDate($0.date, inSameDayAs: today) })
            habits[index].failureLogs.append(log)
            habits[index].skippedDates.insert(today)
        }
    }
    
    func toggleSubtask(for habit: Habit, subtask: Subtask, date: Date = Date()) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            let today = Calendar.current.startOfDay(for: date)
            let dateKey = habits[index].dateKey(for: today)
            
            var progress = habits[index].subtaskProgress[dateKey] ?? Set<UUID>()
            if progress.contains(subtask.id) {
                progress.remove(subtask.id)
            } else {
                progress.insert(subtask.id)
            }
            habits[index].subtaskProgress[dateKey] = progress
            
            // Check if all subtasks are complete
            let allDone = habits[index].subtasks.allSatisfy { progress.contains($0.id) }
            
            if allDone {
                habits[index].completedDates.insert(today)
                habits[index].skippedDates.remove(today)
            } else {
                habits[index].completedDates.remove(today)
            }
        }
    }
    
    func toggleCompletion(for habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            var updatedHabit = habits[index]
            let today = Calendar.current.startOfDay(for: Date())
            let dateKey = updatedHabit.dateKey(for: today)
            
            if updatedHabit.completedDates.contains(today) {
                // If it was fully completed, reset it
                updatedHabit.completedDates.remove(today)
                updatedHabit.progressCounts[dateKey] = 0
            } else {
                let currentCount = updatedHabit.progressCounts[dateKey, default: 0]
                if currentCount + 1 >= updatedHabit.targetCount {
                    updatedHabit.completedDates.insert(today)
                    updatedHabit.progressCounts[dateKey] = updatedHabit.targetCount
                    updatedHabit.skippedDates.remove(today)
                    updatedHabit.failureLogs.removeAll(where: { Calendar.current.isDate($0.date, inSameDayAs: today) })
                } else {
                    updatedHabit.progressCounts[dateKey] = currentCount + 1
                    updatedHabit.skippedDates.remove(today)
                }
            }
            
            habits[index] = updatedHabit
        }
    }
    
    func markYesterdayComplete(for habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == habit.id }) {
            var updatedHabit = habits[index]
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date()))!
            let dateKey = updatedHabit.dateKey(for: yesterday)

            updatedHabit.completedDates.insert(yesterday)
            updatedHabit.progressCounts[dateKey] = updatedHabit.targetCount
            updatedHabit.skippedDates.remove(yesterday)
            updatedHabit.failureLogs.removeAll(where: { Calendar.current.isDate($0.date, inSameDayAs: yesterday) })
            
            habits[index] = updatedHabit
        }
    }
    
    func addDailyNote(text: String) {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text
        let (sentiment, _) = tagger.tag(at: text.startIndex, unit: .paragraph, scheme: .sentimentScore)
        let score = Double(sentiment?.rawValue ?? "0") ?? 0.0
        
        let newNote = DailyNote(date: Date(), text: text, sentimentScore: score)
        dailyNotes.append(newNote)
    }
    
    func deleteHabit(at offsets: IndexSet) {
        for index in offsets {
            NotificationManager.shared.cancelNotification(for: habits[index].id.uuidString)
        }
        for index in offsets {
            NotificationManager.shared.cancelNotification(for: habits[index].id.uuidString)
        }
        habits.remove(atOffsets: offsets)
    }
    
    private func saveHabits() {
        if let encoded = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func saveBadHabits() {
        if let encoded = try? JSONEncoder().encode(badHabits) {
            UserDefaults.standard.set(encoded, forKey: badHabitsKey)
        }
    }
    
    private func saveNotes() {
        if let encoded = try? JSONEncoder().encode(dailyNotes) {
            UserDefaults.standard.set(encoded, forKey: notesKey)
        }
    }
    
    private func saveMoodEntries() {
        if let encoded = try? JSONEncoder().encode(moodEntries) {
            UserDefaults.standard.set(encoded, forKey: moodKey)
        }
    }
    
    private func saveLastMoodLogDate() {
        if let date = lastMoodLogDate {
            UserDefaults.standard.set(date.timeIntervalSince1970, forKey: lastMoodLogKey)
        }
    }
    
    private func loadHabits() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Habit].self, from: data) {
            habits = decoded.map { habit in
                var normalizedHabit = habit
                normalizedHabit.completedDates = Set(habit.completedDates.map { Calendar.current.startOfDay(for: $0) })
                normalizedHabit.skippedDates = Set(habit.skippedDates.map { Calendar.current.startOfDay(for: $0) })
                return normalizedHabit
            }
        }
    }
    
    private func loadBadHabits() {
        if let data = UserDefaults.standard.data(forKey: badHabitsKey),
           let decoded = try? JSONDecoder().decode([BadHabit].self, from: data) {
            badHabits = decoded
        }
    }
    
    private func loadNotes() {
        if let data = UserDefaults.standard.data(forKey: notesKey),
           let decoded = try? JSONDecoder().decode([DailyNote].self, from: data) {
            dailyNotes = decoded
        }
    }
    
    private func loadMoodEntries() {
        if let data = UserDefaults.standard.data(forKey: moodKey),
           let decoded = try? JSONDecoder().decode([MoodEntry].self, from: data) {
            moodEntries = decoded
        }
    }
    
    private func loadLastMoodLogDate() {
        if let time = UserDefaults.standard.object(forKey: lastMoodLogKey) as? TimeInterval {
            lastMoodLogDate = Date(timeIntervalSince1970: time)
        }
    }
    
    // MARK: - Business Analytics Metrics
    struct DailyCompletion: Identifiable {
        let id = UUID()
        let date: Date
        let count: Int
    }
    
    struct CategoryCompletion: Identifiable {
        let id = UUID()
        let category: String
        let count: Int
    }
    
    struct PriorityData: Identifiable {
        let id: UUID
        let name: String
        let importance: Double
        let adherence: Double
        let colorHex: String
    }
    
    func getLast7DaysData() -> [DailyCompletion] {
        var data: [DailyCompletion] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        for i in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let count = habits.reduce(0) { total, habit in
                total + (habit.completedDates.contains(date) ? 1 : 0)
            }
            data.append(DailyCompletion(date: date, count: count))
        }
        return data
    }
    
    func getCategoryData() -> [CategoryCompletion] {
        var dict: [HabitCategory: Int] = [:]
        for habit in habits {
            dict[habit.category, default: 0] += habit.completedDates.count
        }
        return dict.map { CategoryCompletion(category: $0.key.rawValue, count: $0.value) }
    }
    
    var atRiskHabitsCount: Int {
        return habits.filter { adherenceRate(for: $0) < 0.4 }.count
    }
    
    func adherenceRate(for habit: Habit) -> Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = calendar.startOfDay(for: habit.createdAt)
        let daysSince = max(1, calendar.dateComponents([.day], from: start, to: today).day! + 1)
        let possibleDays = min(14, daysSince) // Last 14 days
        
        var completed = 0
        for i in 0..<possibleDays {
            if let d = calendar.date(byAdding: .day, value: -i, to: today), habit.completedDates.contains(d) {
                completed += 1
            }
        }
        return Double(completed) / Double(possibleDays)
    }
    
    func actionableRecommendations() -> [(habit: Habit, advice: String)] {
        var recs: [(Habit, String)] = []
        for habit in habits {
            let rate = adherenceRate(for: habit)
            if habit.importanceWeight >= 4.0 && rate < 0.4 {
                recs.append((habit, "High priority but low completion (\(Int(rate * 100))%). Consider lowering the target or adding a specific reminder time."))
            } else if habit.importanceWeight <= 2.0 && rate > 0.8 {
                recs.append((habit, "You effortlessly complete this low-priority habit. Consider increasing its difficulty or focus energy elsewhere."))
            } else if rate < 0.3 {
                recs.append((habit, "Consistently missed. Might be time to break this habit into smaller steps or re-evaluate if it's necessary right now."))
            }
        }
        return Array(recs.prefix(4))
    }
    
    var totalCompletionVolume: Int {
        habits.reduce(0) { $0 + $1.completedDates.count }
    }
    
    // Additional Insights
    func getLifeBalanceData() -> [(category: HabitCategory, percentage: Double, count: Int, color: String)] {
        var dict: [HabitCategory: Int] = [:]
        for cat in HabitCategory.allCases { dict[cat] = 0 }
        var total = 0
        for habit in habits {
            dict[habit.category, default: 0] += habit.completedDates.count
            total += habit.completedDates.count
        }
        var results: [(category: HabitCategory, percentage: Double, count: Int, color: String)] = []
        for (cat, count) in dict {
            let pct = total > 0 ? Double(count) / Double(total) : 0.0
            // Grab a representative color
            let fallbackColors: [HabitCategory: String] = [.health: "FF6B6B", .productivity: "F9C74F", .mindfulness: "4D908E", .learning: "277DA1", .other: "8395A7"]
            let color = habits.first(where: { $0.category == cat })?.themeColorHex ?? fallbackColors[cat] ?? "8395A7"
            results.append((category: cat, percentage: pct, count: count, color: color))
        }
        return results.sorted { a, b in
            return a.count > b.count
        }
    }
    
    var timeOfDayRhythm: [(time: TimeOfDay, count: Int)] {
        var counts: [TimeOfDay: Int] = [.morning: 0, .afternoon: 0, .evening: 0, .anytime: 0]
        for habit in habits {
            counts[habit.timeOfDay, default: 0] += habit.completedDates.count
        }
        return TimeOfDay.allCases.map { ($0, counts[$0] ?? 0) }
    }
    
    // Unique feature: Habit Synergy. Finds pairs of habits often completed together.
    func getHabitSynergy() -> [(habit1: Habit, habit2: Habit, count: Int)] {
        guard habits.count > 1 else { return [] }
        var synergyCounts: [(Habit, Habit, Int)] = []
        for i in 0..<habits.count {
            for j in (i+1)..<habits.count {
                let h1 = habits[i]
                let h2 = habits[j]
                let intersection = h1.completedDates.intersection(h2.completedDates)
                if intersection.count > 0 {
                    synergyCounts.append((h1, h2, intersection.count))
                }
            }
        }
        return synergyCounts.sorted { $0.2 > $1.2 }.prefix(3).map { $0 }
    }
    
    var optimalTimeOfDay: String {
        let sorted = timeOfDayRhythm.sorted { $0.count > $1.count }
        return sorted.first?.count ?? 0 > 0 ? sorted.first!.time.rawValue : "N/A"
    }
    
    // MARK: - Gamification Engine
    var totalXP: Int {
        totalCompletionVolume * 25
    }
    var currentLevel: Int {
        (totalXP / 500) + 1
    }
    var xpProgressToNext: Double {
        Double(totalXP % 500) / 500.0
    }
    
    var adherenceRate7Days: String {
        guard !habits.isEmpty else { return "0%" }
        let actual = getLast7DaysData().reduce(0) { $0 + $1.count }
        let potential = habits.count * 7
        guard potential > 0 else { return "0%" }
        let rate = (Double(actual) / Double(potential)) * 100
        return String(format: "%.1f%%", rate)
    }
    
    var bestPerformingDay: String {
        var weekdayCounts = [Int: Int]()
        let calendar = Calendar.current
        for habit in habits {
            for date in habit.completedDates {
                let weekday = calendar.component(.weekday, from: date)
                weekdayCounts[weekday, default: 0] += 1
            }
        }
        guard let best = weekdayCounts.max(by: { $0.value < $1.value }) else { return "N/A" }
        return calendar.weekdaySymbols[best.key - 1]
    }
    
    // MARK: - Advanced Features
    func getMoodTrendData() -> [MoodChartData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var data: [MoodChartData] = []
        
        for i in (0..<7).reversed() {
            guard let d = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let dayEntries = moodEntries.filter { calendar.isDate($0.timestamp, inSameDayAs: d) }
            if !dayEntries.isEmpty {
                let avg = Double(dayEntries.map { $0.val }.reduce(0, +)) / Double(dayEntries.count)
                let relatedNotes = dailyNotes.filter { calendar.isDate($0.date, inSameDayAs: d) }
                data.append(MoodChartData(date: d, avgVal: avg, dailyNotes: relatedNotes))
            }
        }
        return data
    }
    
    func identifyMoodPatterns() -> String {
        if moodEntries.isEmpty { return "Log your mood to see insights." }
        
        let negativeMoods = moodEntries.filter { $0.val <= 3 }
        let weatherNote = negativeMoods.filter { $0.weather?.lowercased().contains("rain") == true }.count > 0 ? " 'Rainy' days in Ireland heavily correlate with this mood!" : ""
        
        guard !negativeMoods.isEmpty else {
            return "You are glowing! No recurring negative moods detected. Keep it up."
        }
        
        let mostFrequentNegative = Dictionary(grouping: negativeMoods, by: { $0.label })
            .max(by: { $0.value.count < $1.value.count })?.key ?? "Stressed"
            
        let negativeDates = Set(negativeMoods.map { Calendar.current.startOfDay(for: $0.timestamp) })
        var totalMissed = 0
        for date in negativeDates {
            totalMissed += habits.filter { !$0.completedDates.contains(date) && date >= Calendar.current.startOfDay(for: $0.createdAt) }.count
        }
        let avgMissed = Double(totalMissed) / Double(max(1, negativeDates.count))
        
        return "Insight: Your most frequent negative mood is '\(mostFrequentNegative)'. On these days, you average \(String(format: "%.1f", avgMissed)) missed habits.\(weatherNote)"
    }

    func generateInsights() -> [String] {
        var insights = [String]()
        if habits.isEmpty { return ["Add some tasks to get advanced insights."] }
        
        // Churn Predictions
        for habit in habits {
            if let churnWarning = predictiveChurnAlert(for: habit) {
                insights.append(churnWarning)
            }
        }
        
        // Sentiment Correlation
        if !dailyNotes.isEmpty {
            let highWeightCompletions = habits.filter { $0.importanceWeight >= 4.0 }.reduce(0) { $0 + $1.completedDates.count }
            let avgSentiment = dailyNotes.map { $0.sentimentScore }.reduce(0, +) / Double(dailyNotes.count)
            
            if highWeightCompletions > 5 && avgSentiment > 0.3 {
                insights.append("🌟 Strong Correlation: Completing your high-priority habits is tied to a highly positive mood in your journals!")
            } else if avgSentiment < -0.2 {
                insights.append("📉 Notice: Your recent mood scores indicate stress. Try focusing only on high-priority habits today.")
            }
        }
        
        if let best = habits.max(by: { $0.currentStreak < $1.currentStreak }), best.currentStreak > 2 {
            insights.append("🔥 You're on fire with '\(best.name)'! Keep up the \(best.currentStreak)-day streak.")
        }
        
        if let worst = habits.min(by: { $0.completedDates.count < $1.completedDates.count }), worst.completedDates.isEmpty {
            insights.append("💡 Looks like '\(worst.name)' hasn't been started yet. Try knocking it out today!")
        }
        
        let rateStr = adherenceRate7Days.replacingOccurrences(of: "%", with: "")
        if let rate = Double(rateStr) {
            if rate > 80 {
                insights.append("📈 Outstanding! Your 7-day adherence is \(adherenceRate7Days). You are highly consistent.")
            } else if rate > 0 && rate < 40 {
                insights.append("📉 Your adherence is \(adherenceRate7Days). Consider breaking your tasks into smaller, manageable chunks.")
            }
        }
        
        if insights.count < 3 {
            insights.append("🧠 Keep tracking daily to generate deeper AI-driven behavior patterns.")
        }
        return insights
    }
    
    func predictiveChurnAlert(for habit: Habit) -> String? {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var consecutiveMisses = 0
        var totalMisses14Days = 0
        
        for i in 1...14 {
            guard let d = cal.date(byAdding: .day, value: -i, to: today) else { continue }
            // Only count if before creation date is false
            if d >= cal.startOfDay(for: habit.createdAt) {
                if !habit.completedDates.contains(d) {
                    totalMisses14Days += 1
                    if i == consecutiveMisses + 1 {
                        consecutiveMisses += 1
                    }
                }
            }
        }
        
        if consecutiveMisses >= 3 {
            let probability = min(0.99, (Double(consecutiveMisses) * 0.2) + (Double(totalMisses14Days) * 0.05))
            return "⚠️ Churn Risk: '\(habit.name)' has a \(Int(probability * 100))% relapse probability due to \(consecutiveMisses) consecutive misses. Get back on track today!"
        }
        return nil
    }
    
    func generateCSVURL() -> URL? {
        var csvString = "Habit Name,Category,Created At,Total Completions,Current Streak\n"
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        
        for habit in habits {
            let dateStr = formatter.string(from: habit.createdAt)
            // Quote name to handle commas
            let safeName = "\"\(habit.name.replacingOccurrences(of: "\"", with: "\"\""))\""
            csvString += "\(safeName),\(habit.category.rawValue),\(dateStr),\(habit.completedDates.count),\(habit.currentStreak)\n"
        }
        
        let fileName = "Habitify_Analytics_\(Int(Date().timeIntervalSince1970)).csv"
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try csvString.write(to: path, atomically: true, encoding: .utf8)
            return path
        } catch {
            print("Failed to create CSV")
            return nil
        }
    }
}

// MARK: - Views
struct RoundedCornerShape: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

struct ContentView: View {
    @StateObject private var viewModel = HabitTrackerViewModel()
    @AppStorage("appTheme") private var appTheme: AppTheme = .system
    
    var body: some View {
        TabView {
            DashboardView(viewModel: viewModel)
                .tabItem {
                    Label("Dashboard", systemImage: "square.grid.2x2.fill")
                }
            
            MoodLoggingView(viewModel: viewModel)
                .tabItem {
                    Label("Mood Lab", systemImage: "sparkles")
                }
            
            BusinessAnalyticsView(viewModel: viewModel)
                .tabItem {
                    Label("Insights", systemImage: "chart.bar.xaxis")
                }
            
            SettingsView(viewModel: viewModel)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .preferredColorScheme(appTheme == .system ? nil : (appTheme == .dark ? .dark : .light))
    }
}

struct DashboardView: View {
    @ObservedObject var viewModel: HabitTrackerViewModel
    @State private var showingAddHabitSheet = false
    @State private var habitToEdit: Habit? = nil
    @State private var showingJournalSheet = false
    @State private var showingHiddenJournals = false
    
    @AppStorage("isGridView") private var isGridView = false
    
    var body: some View {
        NavigationStack {
            Group {
                if isGridView {
                    ScrollView {
                        VStack(spacing: 20) {
                            DashboardHeaderView(viewModel: viewModel)
                                .padding(.top, 24)
                            
                            Button(action: {
                                showingJournalSheet = true
                            }) {
                                HStack {
                                    Image(systemName: "square.and.pencil")
                                        .foregroundColor(.indigo)
                                        .font(.title2)
                                    Text("Write Daily Journal")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(16)
                            }
                            .foregroundColor(.primary)
                            
                            buildGridContent()
                            
                            NavigationLink(destination: HabitDestroyerView(viewModel: viewModel)) {
                                HStack {
                                    Image(systemName: "shield.slash.fill")
                                        .foregroundColor(.red)
                                        .font(.title2)
                                    Text("Habit Destroyer")
                                        .fontWeight(.medium)
                                    Spacer()
                                        Text("\(viewModel.badHabits.count) tracked")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(Color(UIColor.secondarySystemGroupedBackground))
                                    .cornerRadius(16)
                                    .foregroundColor(.primary)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                        .background(Color(UIColor.systemGroupedBackground))
                        .transition(.opacity)
                        .id("grid_view")
                    } else {
                        List {
                            Section {
                                DashboardHeaderView(viewModel: viewModel)
                                    .padding(.vertical, 4)
                            }
                            
                            Section {
                                Button(action: {
                                    showingJournalSheet = true
                                }) {
                                    HStack {
                                        Image(systemName: "square.and.pencil")
                                            .foregroundColor(.indigo)
                                            .font(.title2)
                                        Text("Write Daily Journal")
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            
                            buildListContent()
                            
                            Section {
                                NavigationLink(destination: HabitDestroyerView(viewModel: viewModel)) {
                                    HStack {
                                        Image(systemName: "shield.slash.fill")
                                            .foregroundColor(.red)
                                            .font(.title2)
                                        Text("Habit Destroyer")
                                            .foregroundColor(.primary)
                                            .fontWeight(.medium)
                                        Spacer()
                                        Text("\(viewModel.badHabits.count) tracked")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        .background(Color(UIColor.systemGroupedBackground))
                        .scrollContentBackground(.hidden)
                        .listStyle(.insetGrouped)
                        .transition(.opacity)
                        .id("list_view")
                    }
            }
            .animation(.easeInOut(duration: 0.35), value: isGridView)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                    }) {
                        Text("🔥 Habitify")
                            .font(.system(size: 26, weight: .heavy))
                            .foregroundColor(.primary)
                            .fixedSize()
                    }
                    .buttonStyle(PlainButtonStyle())
                    .simultaneousGesture(TapGesture(count: 2).onEnded {
                        playHaptic(style: .heavy)
                        showingHiddenJournals = true
                    })
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                isGridView.toggle()
                            }
                        } label: {
                            Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                                .font(.title3)
                                .foregroundColor(.primary)
                        }
                        
                        Button {
                            showingAddHabitSheet = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(.indigo)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddHabitSheet) {
                AddHabitView(viewModel: viewModel)
            }
            .sheet(item: $habitToEdit) { habit in
                AddHabitView(viewModel: viewModel, editingHabit: habit)
            }
            .sheet(isPresented: $showingJournalSheet) {
                JournalEntrySheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showingHiddenJournals) {
                HiddenJournalArchiveView(viewModel: viewModel)
            }
        }
    }
    
    // MARK: - List Content
    @ViewBuilder
    private func buildListContent() -> some View {
        if viewModel.habits.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.indigo)
                
                Text("No habits yet")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Create your first habit by tapping the + icon above.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.vertical, 40)
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
        } else {
            let today = Calendar.current.startOfDay(for: Date())
            let activeHabits = viewModel.habits.filter { !$0.completedDates.contains(today) && !$0.skippedDates.contains(today) }
            let completedHabits = viewModel.habits.filter { $0.completedDates.contains(today) }
            let missedHabits = viewModel.habits.filter { $0.skippedDates.contains(today) && !$0.completedDates.contains(today) }
            
            if activeHabits.isEmpty {
                Text("No active tasks for today! Great job.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(TimeOfDay.allCases, id: \.self) { timeOfDay in
                    let sectionHabits = activeHabits.filter { $0.timeOfDay == timeOfDay }
                    if !sectionHabits.isEmpty {
                        Section {
                            ForEach(sectionHabits) { habit in
                                ZStack {
                                    NavigationLink(destination: HabitDetailView(habit: habit)) { EmptyView() }.opacity(0)
                                    HabitRowView(habit: habit, viewModel: viewModel) {
                                        withAnimation(.spring()) { viewModel.toggleCompletion(for: habit) }
                                    } editAction: { habitToEdit = habit }
                                }
                            }
                            .onDelete { offsets in deleteHabits(offsets, from: sectionHabits) }
                        } header: {
                            HStack {
                                Image(systemName: timeOfDay.icon)
                                Text(timeOfDay.rawValue)
                            }
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.bottom, 4)
                        }
                    }
                }
            }
            
            if !completedHabits.isEmpty {
                Section {
                    ForEach(completedHabits) { habit in
                        ZStack {
                            NavigationLink(destination: HabitDetailView(habit: habit)) { EmptyView() }.opacity(0)
                            HabitRowView(habit: habit, viewModel: viewModel) {
                                withAnimation(.spring()) { viewModel.toggleCompletion(for: habit) }
                            } editAction: { habitToEdit = habit }
                        }
                    }
                    .onDelete { offsets in deleteHabits(offsets, from: completedHabits) }
                } header: {
                    HStack { Image(systemName: "checkmark.seal.fill"); Text("Completed Today") }
                    .font(.headline).foregroundColor(.green).padding(.bottom, 4)
                }
            }
            
            if !missedHabits.isEmpty {
                Section {
                    ForEach(missedHabits) { habit in
                        ZStack {
                            NavigationLink(destination: HabitDetailView(habit: habit)) { EmptyView() }.opacity(0)
                            HabitRowView(habit: habit, viewModel: viewModel) {
                                withAnimation(.spring()) { viewModel.toggleCompletion(for: habit) }
                            } editAction: { habitToEdit = habit }
                        }
                    }
                    .onDelete { offsets in deleteHabits(offsets, from: missedHabits) }
                } header: {
                    HStack { Image(systemName: "xmark.octagon.fill"); Text("Missed Today") }
                    .font(.headline).foregroundColor(.red).padding(.bottom, 4)
                }
            }
        }
    }
    
    // MARK: - Grid Content
    @ViewBuilder
    private func buildGridContent() -> some View {
        if viewModel.habits.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.indigo)
                Text("No habits yet")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Create your first habit by tapping the + icon above.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.vertical, 40)
            .frame(maxWidth: .infinity)
        } else {
            let today = Calendar.current.startOfDay(for: Date())
            let activeHabits = viewModel.habits.filter { !$0.completedDates.contains(today) && !$0.skippedDates.contains(today) }
            let completedHabits = viewModel.habits.filter { $0.completedDates.contains(today) }
            let missedHabits = viewModel.habits.filter { $0.skippedDates.contains(today) && !$0.completedDates.contains(today) }
            
            let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
            
            if activeHabits.isEmpty {
                Text("No active tasks for today! Great job.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(TimeOfDay.allCases, id: \.self) { timeOfDay in
                    let sectionHabits = activeHabits.filter { $0.timeOfDay == timeOfDay }
                    if !sectionHabits.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: timeOfDay.icon)
                                Text(timeOfDay.rawValue)
                            }
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.leading, 4)
                            
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(sectionHabits) { habit in
                                    NavigationLink(destination: HabitDetailView(habit: habit)) {
                                        HabitCardView(habit: habit, viewModel: viewModel) {
                                            withAnimation(.spring()) { viewModel.toggleCompletion(for: habit) }
                                        } editAction: { habitToEdit = habit }
                                    }.buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding(.top, 10)
                    }
                }
            }
            
            if !completedHabits.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack { Image(systemName: "checkmark.seal.fill"); Text("Completed Today") }
                        .font(.headline).foregroundColor(.green).padding(.leading, 4)
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(completedHabits) { habit in
                            NavigationLink(destination: HabitDetailView(habit: habit)) {
                                HabitCardView(habit: habit, viewModel: viewModel) {
                                    withAnimation(.spring()) { viewModel.toggleCompletion(for: habit) }
                                } editAction: { habitToEdit = habit }
                            }.buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.top, 10)
            }
            
            if !missedHabits.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack { Image(systemName: "xmark.octagon.fill"); Text("Missed Today") }
                        .font(.headline).foregroundColor(.red).padding(.leading, 4)
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(missedHabits) { habit in
                            NavigationLink(destination: HabitDetailView(habit: habit)) {
                                HabitCardView(habit: habit, viewModel: viewModel) {
                                    withAnimation(.spring()) { viewModel.toggleCompletion(for: habit) }
                                } editAction: { habitToEdit = habit }
                            }.buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.top, 10)
            }
        }
    }
    
    private func deleteHabits(_ offsets: IndexSet, from subset: [Habit]) {
        for index in offsets {
            let habit = subset[index]
            if let idx = viewModel.habits.firstIndex(where: { $0.id == habit.id }) {
                viewModel.deleteHabit(at: IndexSet(integer: idx))
            }
        }
    }
}

struct HabitCardView: View {
    let habit: Habit
    @ObservedObject var viewModel: HabitTrackerViewModel
    let toggleAction: () -> Void
    let editAction: () -> Void
    @State private var showingFailureSheet = false
    
    var progressToday: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return habit.progressCounts[habit.dateKey(for: today), default: 0]
    }
    
    var isCompletedToday: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return habit.completedDates.contains(today)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 2) {
                        Text("\(habit.currentStreak)")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundColor(.primary)
                        Text("🔥").font(.title3)
                    }
                    Text("DAYS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    playHaptic(style: .light)
                    toggleAction()
                }) {
                    ZStack {
                        if isCompletedToday {
                            Image(systemName: "checkmark.circle.fill")
                                .resizable()
                                .frame(width: 28, height: 28)
                                .foregroundColor(Color(hex: habit.themeColorHex))
                        } else if progressToday > 0 {
                            Circle()
                                .stroke(Color.gray.opacity(0.4), lineWidth: 3)
                                .frame(width: 28, height: 28)
                            
                            Circle()
                                .trim(from: 0, to: CGFloat(progressToday) / CGFloat(habit.targetCount))
                                .stroke(Color(hex: habit.themeColorHex), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .frame(width: 28, height: 28)
                                .animation(.spring(), value: progressToday)
                            
                            Text("\(progressToday)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(hex: habit.themeColorHex))
                        } else {
                            Image(systemName: "circle")
                                .resizable()
                                .frame(width: 28, height: 28)
                                .foregroundColor(.gray.opacity(0.4))
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer(minLength: 16)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.headline)
                    .lineLimit(1)
                
                if habit.taskHorizon == .overdue {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("Overdue")
                    }
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.red)
                    .cornerRadius(6)
                    .padding(.top, 2)
                }
                
                if habit.currentStreak > 0 {
                    Text("🔥 \(habit.currentStreak) Day Streak")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let reminder = habit.reminderTime {
                    HStack(spacing: 4) {
                        Image(systemName: "bell")
                        Text(reminder, style: .time)
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
                }
                
                if habit.targetCount > 1 {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar.fill")
                        Text("\(progressToday) / \(habit.targetCount)")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
                }

                if !habit.subtasks.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(habit.subtasks) { subtask in
                            let isDone = habit.subtaskProgress[habit.dateKey(for: Calendar.current.startOfDay(for: Date()))]?.contains(subtask.id) ?? false
                            Button(action: {
                                playHaptic(style: .light)
                                withAnimation {
                                    viewModel.toggleSubtask(for: habit, subtask: subtask, date: Date())
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: isDone ? "checkmark.square.fill" : "square")
                                        .foregroundColor(isDone ? Color(hex: habit.themeColorHex) : .gray)
                                    Text(subtask.title)
                                        .font(.caption)
                                        .strikethrough(isDone)
                                        .foregroundColor(isDone ? .secondary : .primary)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
        .contextMenu {
            if Calendar.current.component(.hour, from: Date()) < 16 {
                let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date()))!
                if !habit.completedDates.contains(yesterday) {
                    Button {
                        withAnimation { viewModel.markYesterdayComplete(for: habit) }
                    } label: { Label("Complete for Yesterday", systemImage: "clock.arrow.circlepath") }
                }
            }
            
            Button { editAction() } label: { Label("Edit Habit", systemImage: "pencil") }
            Button(role: .destructive) {
                if let index = viewModel.habits.firstIndex(where: { $0.id == habit.id }) {
                    viewModel.deleteHabit(at: IndexSet(integer: index))
                }
            } label: { Label("Delete Habit", systemImage: "trash") }
            Button { showingFailureSheet = true } label: { Label("Mark as Missed", systemImage: "xmark.octagon") }
        }
        .confirmationDialog("Why did you miss this?", isPresented: $showingFailureSheet, titleVisibility: .visible) {
            ForEach(FailureReason.allCases, id: \.self) { reason in
                Button(reason.rawValue) { viewModel.logFailure(for: habit, reason: reason) }
            }
            Button("Cancel", role: .cancel) { }
        }
    }
}

struct DashboardHeaderView: View {
    @ObservedObject var viewModel: HabitTrackerViewModel
    
    var todayProgress: Double {
        guard !viewModel.habits.isEmpty else { return 0 }
        let today = Calendar.current.startOfDay(for: Date())
        let completedToday = viewModel.habits.filter { $0.completedDates.contains(today) }.count
        return Double(completedToday) / Double(viewModel.habits.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today's Progress")
                    .font(.headline)
                Spacer()
                Text("\(Int(todayProgress * 100))%")
                    .font(.headline)
                    .foregroundColor(.primary.opacity(0.8))
            }
            
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.08))
                    .frame(height: 14)
                
                GeometryReader { geometry in
                    Capsule()
                        .fill(Color.primary.opacity(0.75))
                        .frame(width: max(0, geometry.size.width * CGFloat(todayProgress)), height: 14)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: todayProgress)
                }
            }
            .frame(height: 14)
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 5, y: 2)
    }
}

struct SettingsView: View {
    @ObservedObject var viewModel: HabitTrackerViewModel
    @AppStorage("appTheme") private var appTheme: AppTheme = .system
    @State private var notificationsEnabled = true
    @State private var exportURL: URL?
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Appearance")) {
                    Picker("App Theme", selection: $appTheme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Preferences")) {
                    Toggle("Enable Global Notifications", isOn: $notificationsEnabled)
                        .tint(.indigo)
                }
                
                Section(header: Text("Data & Analytics"), footer: Text("Export your raw habit data to CSV for external business intelligence tools like Tableau or PowerBI.")) {
                    Button(action: {
                        if let url = viewModel.generateCSVURL() {
                            exportURL = url
                            showingShareSheet = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.indigo)
                            Text("Export Data (CSV)")
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Button(role: .destructive, action: {
                        viewModel.habits.removeAll()
                    }) {
                        Text("Reset All Analytics Data")
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingShareSheet, onDismiss: {
                exportURL = nil
            }) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct HabitRowView: View {
    let habit: Habit
    @ObservedObject var viewModel: HabitTrackerViewModel
    let toggleAction: () -> Void
    let editAction: () -> Void
    @State private var showingFailureSheet = false
    
    var progressToday: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return habit.progressCounts[habit.dateKey(for: today), default: 0]
    }
    
    var isCompletedToday: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return habit.completedDates.contains(today)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: habit.themeColorHex).opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: habit.category.icon)
                    .foregroundColor(Color(hex: habit.themeColorHex))
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.headline)
                    .lineLimit(1)
                
                if habit.taskHorizon == .overdue {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("Overdue")
                    }
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.red)
                    .cornerRadius(6)
                    .padding(.top, 2)
                }
                
                if habit.currentStreak > 0 {
                    Text("🔥 \(habit.currentStreak) Day Streak")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let reminder = habit.reminderTime {
                    HStack(spacing: 4) {
                        Image(systemName: "bell")
                        Text(reminder, style: .time)
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
                }
                
                if habit.targetCount > 1 {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar.fill")
                        Text("\(progressToday) / \(habit.targetCount)")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
                }

                if !habit.subtasks.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(habit.subtasks) { subtask in
                            let isDone = habit.subtaskProgress[habit.dateKey(for: Calendar.current.startOfDay(for: Date()))]?.contains(subtask.id) ?? false
                            Button(action: {
                                playHaptic(style: .light)
                                withAnimation {
                                    viewModel.toggleSubtask(for: habit, subtask: subtask, date: Date())
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: isDone ? "checkmark.square.fill" : "square")
                                        .foregroundColor(isDone ? Color(hex: habit.themeColorHex) : .gray)
                                    Text(subtask.title)
                                        .font(.caption)
                                        .strikethrough(isDone)
                                        .foregroundColor(isDone ? .secondary : .primary)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.top, 4)
                }
            }

            Spacer()

            Button(action: {
                playHaptic(style: .light)
                toggleAction()
            }) {
                ZStack {
                    if isCompletedToday {
                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .frame(width: 28, height: 28)
                            .foregroundColor(Color(hex: habit.themeColorHex))
                    } else if progressToday > 0 {
                        Circle()
                            .stroke(Color.gray.opacity(0.4), lineWidth: 3)
                            .frame(width: 28, height: 28)

                        Circle()
                            .trim(from: 0, to: CGFloat(progressToday) / CGFloat(habit.targetCount))
                            .stroke(Color(hex: habit.themeColorHex), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 28, height: 28)
                            .animation(.spring(), value: progressToday)

                        Text("\(progressToday)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(hex: habit.themeColorHex))
                    } else {
                        Image(systemName: "circle")
                            .resizable()
                            .frame(width: 28, height: 28)
                            .foregroundColor(.gray.opacity(0.4))
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel(isCompletedToday ? "Mark incomplete" : "Mark complete")
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .contextMenu {
            if Calendar.current.component(.hour, from: Date()) < 16 {
                let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date()))!
                if !habit.completedDates.contains(yesterday) {
                    Button {
                        withAnimation { viewModel.markYesterdayComplete(for: habit) }
                    } label: { Label("Complete for Yesterday", systemImage: "clock.arrow.circlepath") }
                }
            }

            Button {
                editAction()
            } label: {
                Label("Edit Habit", systemImage: "pencil")
            }

            Button(role: .destructive) {
                if let index = viewModel.habits.firstIndex(where: { $0.id == habit.id }) {
                    viewModel.deleteHabit(at: IndexSet(integer: index))
                }
            } label: {
                Label("Delete Habit", systemImage: "trash")
            }
            Button {
                showingFailureSheet = true
            } label: {
                Label("Mark as Missed", systemImage: "xmark.octagon")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                showingFailureSheet = true
            } label: {
                Label("Missed", systemImage: "xmark.octagon.fill")
            }
            .tint(.red)
        }
        .confirmationDialog("Why did you miss this?", isPresented: $showingFailureSheet, titleVisibility: .visible) {
            ForEach(FailureReason.allCases, id: \.self) { reason in
                Button(reason.rawValue) {
                    viewModel.logFailure(for: habit, reason: reason)
                }
            }
            Button("Cancel", role: .cancel) { }
        }
    }
}

struct HabitDetailView: View {
    let habit: Habit
    @State private var showingPomodoro = false
    
    let columns = [
        GridItem(.adaptive(minimum: 40))
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                ZStack {
                    Circle()
                        .fill(Color(hex: habit.themeColorHex).opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: habit.category.icon)
                        .foregroundColor(Color(hex: habit.themeColorHex))
                        .font(.system(size: 40))
                }
                .padding(.top, 20)
                
                Text(habit.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // Stats row
                HStack(spacing: 40) {
                    VStack {
                        Text("\(habit.currentStreak)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: habit.themeColorHex))
                        Text("Current Streak")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    VStack {
                        Text("\(habit.completedDates.count)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: habit.themeColorHex))
                        Text("All Time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    VStack {
                        Text("\(habit.nextMilestone)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: habit.themeColorHex))
                        Text("Next Badge \(!habit.completedDates.isEmpty ? "🏆" : "")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical)
                
                // History block (last 30 days)
                VStack(alignment: .leading) {
                    HStack {
                        Text("Last 30 Days")
                            .font(.headline)
                        Spacer()
                        Text(Date(), format: .dateTime.month(.wide))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach((0..<30).reversed(), id: \.self) { i in
                            let date = Calendar.current.date(byAdding: .day, value: -i, to: Date())!
                            let isCompleted = habit.completedDates.contains(Calendar.current.startOfDay(for: date))
                            
                            VStack {
                                Text("\(Calendar.current.component(.day, from: date))")
                                    .font(.system(size: 10, weight: .bold))
                                    .lineLimit(1)
                                    .foregroundColor(.secondary)
                                
                                Circle()
                                    .fill(isCompleted ? Color(hex: habit.themeColorHex) : Color.gray.opacity(0.2))
                                    .frame(width: 20, height: 20)
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Focus Mode Button
                Button {
                    showingPomodoro = true
                } label: {
                    HStack {
                        Image(systemName: "timer")
                        Text("Start Focus Session")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: habit.themeColorHex))
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    .shadow(color: Color(hex: habit.themeColorHex).opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.top, 10)
                
                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPomodoro) {
            PomodoroTimerView(habit: habit, colorHex: habit.themeColorHex)
        }
    }
}

// MARK: - Pomodoro Timer View
struct PomodoroTimerView: View {
    let habit: Habit
    let colorHex: String
    @Environment(\.dismiss) var dismiss
    
    @State private var timeRemaining = 25 * 60 // 25 mins
    @State private var isRunning = false
    @State private var timer: Timer? = nil
    
    var progress: Double {
        return 1.0 - (Double(timeRemaining) / Double(25 * 60))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Text("Focus on: \(habit.name)")
                    .font(.title2)
                    .fontWeight(.medium)
                
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 15)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color(hex: colorHex), style: StrokeStyle(lineWidth: 15, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: progress)
                    
                    Text(timeString(from: timeRemaining))
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
                .frame(width: 250, height: 250)
                .padding()
                
                HStack(spacing: 30) {
                    Button(action: {
                        if isRunning {
                            pauseTimer()
                        } else {
                            startTimer()
                        }
                    }) {
                        Image(systemName: isRunning ? "pause.fill" : "play.fill")
                            .font(.title)
                            .frame(width: 80, height: 80)
                            .background(Color(hex: colorHex))
                            .foregroundColor(.white)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    
                    Button(action: resetTimer) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title)
                            .frame(width: 80, height: 80)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .foregroundColor(.primary)
                            .clipShape(Circle())
                    }
                }
            }
            .navigationTitle("Pomodoro Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        pauseTimer()
                        dismiss()
                    }
                }
            }
            .onDisappear {
                pauseTimer()
            }
        }
    }
    
    func startTimer() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                pauseTimer()
            }
        }
    }
    
    func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    func resetTimer() {
        pauseTimer()
        timeRemaining = 25 * 60
    }
    
    func timeString(from remaining: Int) -> String {
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct AddHabitView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: HabitTrackerViewModel
    var editingHabit: Habit? = nil
    
    @State private var habitName = ""
    @FocusState private var isNameFocused: Bool
    @State private var selectedCategory: HabitCategory = .other
    @State private var selectedColorHex = "FF9500" // Default Orange
    @State private var selectedTimeOfDay: TimeOfDay = .anytime
    @State private var reminderEnabled = false
    @State private var reminderTime = Date()
    @State private var importanceWeight: Double = 3.0
    @State private var targetCount: Int = 1
    
    @State private var subtasks: [Subtask] = []
    @State private var newSubtaskTitle: String = ""
    
    enum FrequencyOption: String, CaseIterable {
        case daily = "Every Day"
        case specificDays = "Specific Days"
        case weekly = "Days per week"
        case onceAWeek = "Once a Week"
        case onceAMonth = "Once a Month"
    }
    
    @State private var frequencyOption: FrequencyOption = .daily
    @State private var selectedDays: Set<Int> = []
    @State private var timesPerWeek: Int = 3
    
    // Modern aesthetic palette
    let colors = [
        "FF6B6B", "FF9F43", "FDCB6E", "1DD1A1",
        "0ABDE3", "5F27CD", "FF9FF3", "8395A7",
        "222F3E", "10ACB4", "E15F41", "3D3D3D"
    ]
    
    struct HabitTemplate {
        let title: String
        let category: HabitCategory
        let colorHex: String
    }
    
    let quickTemplates = [
        HabitTemplate(title: "Read 15 Pages", category: .learning, colorHex: "007AFF"),
        HabitTemplate(title: "Drink Water", category: .health, colorHex: "32ADE6"),
        HabitTemplate(title: "Workout", category: .health, colorHex: "FF3B30"),
        HabitTemplate(title: "Meditate", category: .mindfulness, colorHex: "34C759"),
        HabitTemplate(title: "Plan Day", category: .productivity, colorHex: "FF9500")
    ]
    
struct QuickTemplateButton: View {
    let template: HabitTemplate
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: template.category.icon)
                    .font(.title2)
                    .foregroundColor(Color(hex: template.colorHex))
                Text(template.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .padding()
            .frame(width: 105)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

    var defaultTemplatesView: some View {
        Section(header: Text("Quick Templates")) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(quickTemplates, id: \.title) { template in
                        QuickTemplateButton(template: template) {
                            habitName = template.title
                            selectedCategory = template.category
                            selectedColorHex = template.colorHex
                            isNameFocused = true
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if editingHabit == nil {
                    defaultTemplatesView
                }
                
                Section(header: Text("Details")) {
                    TextField("Habit Name (e.g. Read 10 pages)", text: $habitName)
                        .focused($isNameFocused)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.words)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(HabitCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.rawValue)
                            }.tag(category)
                        }
                    }
                    
                    Picker("Time of Day", selection: $selectedTimeOfDay) {
                        ForEach(TimeOfDay.allCases, id: \.self) { time in
                            HStack {
                                Image(systemName: time.icon)
                                Text(time.rawValue)
                            }.tag(time)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Importance Weight: \(Int(importanceWeight))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: $importanceWeight, in: 1...5, step: 1)
                            .tint(Color(hex: selectedColorHex))
                    }
                }
                
                Section(header: Text("Subtasks (Checklist)"), footer: Text("Add smaller steps to complete this habit.")) {
                    ForEach($subtasks) { $subtask in
                        TextField("Subtask", text: $subtask.title)
                    }
                    .onDelete { subtasks.remove(atOffsets: $0) }
                    
                    HStack {
                        TextField("New Subtask", text: $newSubtaskTitle)
                        Button(action: {
                            let trimmed = newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty {
                                subtasks.append(Subtask(title: trimmed))
                                newSubtaskTitle = ""
                            }
                        }) {
                            Image(systemName: "plus.circle.fill").foregroundColor(Color(hex: selectedColorHex))
                        }
                        .disabled(newSubtaskTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                
                Section(header: Text("Schedule & Target"), footer: Text("Daily Target allows tracking quantity-based tasks like drinking multiple liters of water.")) {
                    Picker("Frequency", selection: $frequencyOption) {
                        ForEach(FrequencyOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    
                    if frequencyOption == .weekly {
                        Stepper("Goal: \(timesPerWeek) days / week", value: $timesPerWeek, in: 1...7)
                    } else if frequencyOption == .specificDays {
                        HStack(spacing: 8) {
                            ForEach(1...7, id: \.self) { day in
                                Text(Calendar.current.veryShortWeekdaySymbols[day - 1])
                                    .font(.caption)
                                    .frame(width: 32, height: 32)
                                    .background(selectedDays.contains(day) ? Color(hex: selectedColorHex) : Color(UIColor.tertiarySystemGroupedBackground))
                                    .foregroundColor(selectedDays.contains(day) ? .white : .primary)
                                    .clipShape(Circle())
                                    .onTapGesture {
                                        if selectedDays.contains(day) {
                                            selectedDays.remove(day)
                                        } else {
                                            selectedDays.insert(day)
                                        }
                                    }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 4)
                    }
                    
                    Stepper("Daily Target: \(targetCount)", value: $targetCount, in: 1...999)
                }
                
                Section(header: Text("Target Date & Reminder")) {
                    Toggle("Set specific date/time", isOn: $reminderEnabled)
                    if reminderEnabled {
                        DatePicker("Target Date", selection: $reminderTime, displayedComponents: [.date, .hourAndMinute])
                    }
                }
                
                Section(header: Text("Theme Color"), footer: Text("Choose a custom accent color for your tracking metrics.")) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 40))], spacing: 12) {
                        ForEach(colors, id: \.self) { hex in
                            let isSelected = (selectedColorHex == hex)
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(hex: hex))
                                    .frame(width: 44, height: 44)
                                    .shadow(color: Color(hex: hex).opacity(0.3), radius: isSelected ? 4 : 0, y: isSelected ? 3 : 0)
                                
                                if isSelected {
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.primary, lineWidth: 3)
                                        .frame(width: 52, height: 52)
                                        
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(Color.white)
                                }
                            }
                            .padding(4)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    selectedColorHex = hex
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle(editingHabit == nil ? "New Habit" : "Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveHabit()
                    }
                    .disabled(habitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if let habit = editingHabit {
                    habitName = habit.name
                    selectedCategory = habit.category
                    selectedColorHex = habit.themeColorHex
                    selectedTimeOfDay = habit.timeOfDay
                    
                    switch habit.frequency {
                    case .daily:
                        frequencyOption = .daily
                    case .specificDays(let days):
                        frequencyOption = .specificDays
                        selectedDays = Set(days)
                    case .timesPerWeek(let times):
                        frequencyOption = .weekly
                        timesPerWeek = times
                    case .onceAWeek:
                        frequencyOption = .onceAWeek
                    case .onceAMonth:
                        frequencyOption = .onceAMonth
                    }
                    
                    if let time = habit.reminderTime {
                        reminderEnabled = true
                        reminderTime = time
                    }
                    importanceWeight = habit.importanceWeight
                    targetCount = habit.targetCount
                    subtasks = habit.subtasks
                } else {
                    isNameFocused = true
                }
            }
        }
    }
    
    private func saveHabit() {
        let trimmedName = habitName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            let freq: HabitFrequency
            switch frequencyOption {
            case .daily: freq = .daily
            case .specificDays: freq = .specificDays(Array(selectedDays))
            case .weekly: freq = .timesPerWeek(timesPerWeek)
            case .onceAWeek: freq = .onceAWeek
            case .onceAMonth: freq = .onceAMonth
            }
            
            if let habit = editingHabit {
                viewModel.updateHabit(
                    habit: habit,
                    name: trimmedName,
                    category: selectedCategory,
                    themeColorHex: selectedColorHex,
                    frequency: freq,
                    timeOfDay: selectedTimeOfDay,
                    reminderTime: reminderEnabled ? reminderTime : nil,
                    importanceWeight: importanceWeight,
                    targetCount: targetCount,
                    subtasks: subtasks
                )
            } else {
                viewModel.addHabit(
                    name: trimmedName,
                    category: selectedCategory,
                    themeColorHex: selectedColorHex,
                    frequency: freq,
                    timeOfDay: selectedTimeOfDay,
                    reminderTime: reminderEnabled ? reminderTime : nil,
                    importanceWeight: importanceWeight,
                    targetCount: targetCount,
                    subtasks: subtasks
                )
            }
            dismiss()
        }
    }
}

// MARK: - Full Activity Calendar View
struct FullActivityCalendarView: View {
    @ObservedObject var viewModel: HabitTrackerViewModel
    @State private var timeRange: Int = 90
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Picker("Time Range", selection: $timeRange) {
                    Text("Last 30 Days").tag(30)
                    Text("Last 90 Days").tag(90)
                    Text("Last Year").tag(365)
                }
                .pickerStyle(.segmented)
                .padding()
                
                ActivityHeatmapView(viewModel: viewModel, days: timeRange)
            }
        }
        .navigationTitle("Activity History")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(UIColor.systemGroupedBackground))
    }
}

// MARK: - Business Analytics View
struct BusinessAnalyticsView: View {
    @ObservedObject var viewModel: HabitTrackerViewModel
    @State private var isInsightsExpanded = false
    @State private var isActionPlanExpanded = false
    @State private var selectedMoodDate: Date? = nil
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Dashboard Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Insights")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Visualize your progress and discover actionable patterns.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Activity Calendar Heatmap
                    NavigationLink(destination: FullActivityCalendarView(viewModel: viewModel)) {
                        ActivityHeatmapView(viewModel: viewModel, days: 90)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if !viewModel.habits.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        
                        // Actionable Recommendations
                        let recs = viewModel.actionableRecommendations()
                        if !recs.isEmpty {
                            Text("Action Plan")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 0) {
                                let visibleRecs = isActionPlanExpanded ? recs : Array(recs.prefix(1))
                                
                                VStack(spacing: 12) {
                                    ForEach(visibleRecs, id: \.habit.id) { rec in
                                        HStack(alignment: .top, spacing: 12) {
                                            Image(systemName: "arrow.right.circle.fill")
                                                .foregroundColor(.blue)
                                                .font(.title3)
                                                .padding(.top, 2)
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(rec.habit.name)
                                                    .font(.subheadline)
                                                    .fontWeight(.bold)
                                                Text(rec.advice)
                                                    .font(.footnote)
                                                    .foregroundColor(.secondary)
                                                    .fixedSize(horizontal: false, vertical: true)
                                            }
                                            Spacer()
                                        }
                                        .padding()
                                        .background(Color(UIColor.secondarySystemGroupedBackground))
                                        .cornerRadius(12)
                                    }
                                }
                                .mask(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.black, isActionPlanExpanded || recs.count <= 1 ? .black : .black.opacity(0.2)]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                
                                if recs.count > 1 {
                                    Button(action: {
                                        withAnimation(.easeInOut) {
                                            isActionPlanExpanded.toggle()
                                        }
                                    }) {
                                        Text(isActionPlanExpanded ? "Show Less" : "Reveal \(recs.count - 1) More Actions")
                                            .font(.footnote)
                                            .fontWeight(.bold)
                                            .foregroundColor(.blue)
                                            .padding(.top, 8)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        }
                    }
                } else {
                    Text("No data available to generate reports.")
                        .foregroundColor(.secondary)
                        .padding(.top, 40)
                }
                
                // AI Insights Engine
                VStack(alignment: .leading, spacing: 12) {
                    Text("AI Insights")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        let insights = viewModel.generateInsights()
                        let visibleInsights = isInsightsExpanded ? insights : Array(insights.prefix(1))
                        
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(visibleInsights, id: \.self) { insight in
                                HStack(alignment: .top) {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(.indigo)
                                        .padding(.top, 2)
                                    Text(insight)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(12)
                            }
                        }
                        .mask(
                            LinearGradient(
                                gradient: Gradient(colors: [.black, isInsightsExpanded || insights.count <= 1 ? .black : .black.opacity(0.2)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        
                        if insights.count > 1 {
                            Button(action: {
                                withAnimation(.easeInOut) {
                                    isInsightsExpanded.toggle()
                                }
                            }) {
                                Text(isInsightsExpanded ? "Show Less" : "Reveal \(insights.count - 1) More Insights")
                                    .font(.footnote)
                                    .fontWeight(.bold)
                                    .foregroundColor(.indigo)
                                    .padding(.top, 8)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Weekly Mood Insight
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.purple)
                        Text("Weekly Mood Insight")
                            .font(.headline)
                    }
                    Text(viewModel.identifyMoodPatterns())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // KPI Grid
                VStack(alignment: .leading, spacing: 16) {
                    Text("Habit Metrics")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                        KPICard(title: "At-Risk", value: "\(viewModel.atRiskHabitsCount)", icon: "exclamationmark.triangle.fill", color: .orange)
                        KPICard(title: "7-Day Consistency", value: viewModel.adherenceRate7Days, icon: "chart.bar.fill", color: .green)
                        KPICard(title: "Total Volume", value: "\(viewModel.totalCompletionVolume)", icon: "checkmark.seal.fill", color: .blue)
                        KPICard(title: "Active Streaks", value: "\(viewModel.habits.filter { $0.currentStreak > 0 }.count)", icon: "flame.fill", color: .red)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct KPICard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 18, weight: .bold))
                }
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(.title2, design: .rounded, weight: .heavy))
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 3)
    }
}

// MARK: - Activity Heatmap Component
struct ActivityHeatmapView: View {
    @ObservedObject var viewModel: HabitTrackerViewModel
    var days: Int = 90
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Activity Calendar (Last \(days) Days)")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                ScrollViewReader { proxy in
                    HStack(spacing: 4) {
                        let weeks = getCalendarWeeks()
                        ForEach(0..<weeks.count, id: \.self) { w in
                            VStack(spacing: 4) {
                                ForEach(0..<weeks[w].count, id: \.self) { d in
                                    let data = weeks[w][d]
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(color(for: data.count))
                                        .frame(width: 14, height: 14)
                                }
                            }
                            .id(w)
                        }
                    }
                    .padding(.horizontal)
                    .onAppear {
                        let weeks = getCalendarWeeks()
                        if let last = weeks.indices.last {
                            proxy.scrollTo(last, anchor: .trailing)
                        }
                    }
                }
            }
        }
        .padding(.vertical)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
        .contentShape(Rectangle())
    }
    
    func getCalendarWeeks() -> [[(date: Date, count: Int)]] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var daysData: [(date: Date, count: Int)] = []
        
        for i in (0..<days).reversed() { // 90 days backwards
            guard let d = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let c = viewModel.habits.reduce(0) { $0 + ($1.completedDates.contains(d) ? 1 : 0) }
            daysData.append((date: d, count: c))
        }
        
        var currentWeek: [(date: Date, count: Int)] = []
        var weeks: [[(date: Date, count: Int)]] = []
        
        if let first = daysData.first {
            let weekday = calendar.component(.weekday, from: first.date)
            let padCount = weekday - 1
            for _ in 0..<padCount {
                currentWeek.append((date: Date.distantPast, count: -1))
            }
        }
        
        for d in daysData {
            currentWeek.append(d)
            if currentWeek.count == 7 {
                weeks.append(currentWeek)
                currentWeek = []
            }
        }
        
        if !currentWeek.isEmpty {
            let remain = 7 - currentWeek.count
            for _ in 0..<remain {
                currentWeek.append((date: Date.distantPast, count: -1))
            }
            weeks.append(currentWeek)
        }
        
        return weeks
    }
    
    func color(for count: Int) -> Color {
        if count < 0 { return Color.clear }
        if count == 0 { return Color.gray.opacity(0.15) }
        if count < 2 { return Color.indigo.opacity(0.4) }
        if count < 4 { return Color.indigo.opacity(0.7) }
        return Color.indigo
    }
}

// MARK: - Color Helper
extension Color {
    init(hex: String) {
        let hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let r, g, b, a: Double
        let length = hexSanitized.count
        
        if length == 6 {
            r = Double((rgb & 0xFF0000) >> 16) / 255.0
            g = Double((rgb & 0x00FF00) >> 8) / 255.0
            b = Double(rgb & 0x0000FF) / 255.0
            a = 1.0
        } else if length == 8 {
            r = Double((rgb & 0xFF000000) >> 24) / 255.0
            g = Double((rgb & 0x00FF0000) >> 16) / 255.0
            b = Double((rgb & 0x0000FF00) >> 8) / 255.0
            a = Double(rgb & 0x000000FF) / 255.0
        } else {
            r = 0.5; g = 0.5; b = 0.5; a = 1.0 // default gray if parse fails
        }
        
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

// MARK: - Haptics Helper
func playHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
    let generator = UIImpactFeedbackGenerator(style: style)
    generator.impactOccurred()
}

// MARK: - Mood Logging View
struct MoodLoggingView: View {
    @ObservedObject var viewModel: HabitTrackerViewModel
    @State private var contextText = ""
    @State private var weatherText = ""
    @State private var selectedMood: MoodType? = nil
    @State private var showSuccessOverlay = false
    
    // Timer Logic for lockout
    @State private var remainingLockoutTime: TimeInterval = 0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var isLockedOut: Bool {
        if let lastDate = viewModel.lastMoodLogDate {
            return Date().timeIntervalSince(lastDate) < 3600 // 1 hour lockout
        }
        return false
    }
    
    let columns = [GridItem(.adaptive(minimum: 105, maximum: 140))]
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isLockedOut {
                    VStack(spacing: 24) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.indigo)
                        
                        Text("Mindful Break")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Thank you for charting your feelings! To ensure mindfulness, mood tracking is locked for a short while.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 30)
                        
                        VStack(spacing: 8) {
                            Text("Unlocks in:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                            
                            Text(timeString(from: remainingLockoutTime))
                                .font(.system(.title, design: .monospaced, weight: .bold))
                                .foregroundColor(.primary)
                                .padding()
                                .frame(width: 200)
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
                                .onTapGesture(count: 2) {
                                    viewModel.lastMoodLogDate = nil
                                    updateLockoutTimer()
                                }
                        }
                        .padding(.top, 20)
                    }
                    .padding()
                    .transition(.opacity.combined(with: .scale))
                    .onAppear {
                        updateLockoutTimer()
                    }
                    .onReceive(timer) { _ in
                        updateLockoutTimer()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 30) {
                            // Mood Grid Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("How are you feeling?")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                
                                LazyVGrid(columns: columns, spacing: 16) {
                                    ForEach(MoodType.allCases, id: \.self) { mood in
                                        let isSelected = selectedMood == mood
                                        Button(action: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                selectedMood = mood
                                            }
                                        }) {
                                            VStack(spacing: 12) {
                                                Image(systemName: mood.icon)
                                                    .font(.system(size: 36))
                                                    .foregroundColor(isSelected ? .white : mood.color)
                                                Text(mood.label)
                                                    .font(.subheadline)
                                                    .fontWeight(isSelected ? .bold : .medium)
                                                    .foregroundColor(isSelected ? .white : .primary)
                                            }
                                            .frame(height: 110)
                                            .frame(maxWidth: .infinity)
                                            .background(isSelected ? mood.color : Color(UIColor.secondarySystemGroupedBackground))
                                            .cornerRadius(20)
                                            .shadow(color: isSelected ? mood.color.opacity(0.4) : Color.black.opacity(0.05), radius: isSelected ? 8 : 4, y: isSelected ? 4 : 2)
                                            .scaleEffect(isSelected ? 1.05 : 1.0)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // Context & Weather Section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Details (Optional)")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                
                                VStack(spacing: 0) {
                                    HStack(spacing: 16) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.indigo.opacity(0.1))
                                                .frame(width: 36, height: 36)
                                            Image(systemName: "pencil.line")
                                                .foregroundColor(.indigo)
                                        }
                                        TextField("What's on your mind?", text: $contextText)
                                            .font(.body)
                                            .autocorrectionDisabled(true)
                                            .textInputAutocapitalization(.sentences)
                                    }
                                    .padding()
                                    
                                    Divider()
                                        .padding(.leading, 68)
                                    
                                    HStack(spacing: 16) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.blue.opacity(0.1))
                                                .frame(width: 36, height: 36)
                                            Image(systemName: "cloud.sun.fill")
                                                .foregroundColor(.blue)
                                        }
                                        TextField("Weather (e.g. Rainy, Overcast)", text: $weatherText)
                                            .font(.body)
                                            .autocorrectionDisabled(true)
                                            .textInputAutocapitalization(.words)
                                    }
                                    .padding()
                                }
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(20)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
                                .padding(.horizontal)
                            }
                            
                            // Save Button
                            Button(action: {
                                if let mood = selectedMood {
                                    // Show success animation instantly
                                    withAnimation(.spring()) {
                                        showSuccessOverlay = true
                                    }
                                    
                                    // Let animation hang for a second then log and trigger lock
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                        withAnimation(.easeInOut) {
                                            viewModel.logMood(type: mood, context: contextText, weather: weatherText)
                                            showSuccessOverlay = false
                                            selectedMood = nil
                                            contextText = ""
                                            weatherText = ""
                                            updateLockoutTimer()
                                        }
                                    }
                                }
                            }) {
                                Text("Save Entry")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(selectedMood != nil ? Color.indigo : Color.gray.opacity(0.3))
                                    .cornerRadius(16)
                                    .shadow(color: selectedMood != nil ? Color.indigo.opacity(0.3) : Color.clear, radius: 8, y: 4)
                            }
                            .disabled(selectedMood == nil)
                            .padding(.horizontal)
                            .padding(.top, 10)
                            .padding(.bottom, 30) // Extra padding for tab bar
                        }
                        .padding(.vertical)
                    }
                    
                    // Success Overlay
                    if showSuccessOverlay {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                            Text("Mood Logged!")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        .padding(30)
                        .background(Color(UIColor.secondarySystemGroupedBackground).opacity(0.95))
                        .cornerRadius(24)
                        .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(1)
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Mood Lab")
        }
    }
    
    private func updateLockoutTimer() {
        if let lastDate = viewModel.lastMoodLogDate {
            let elapsed = Date().timeIntervalSince(lastDate)
            remainingLockoutTime = max(0, 3600 - elapsed)
        } else {
            remainingLockoutTime = 0
        }
    }
    
    private func timeString(from interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Journal Entry Sheet
struct JournalEntrySheet: View {
    @ObservedObject var viewModel: HabitTrackerViewModel
    @Environment(\.dismiss) var dismiss
    @State private var text = ""
    
    var body: some View {
        NavigationStack {
            TextEditor(text: $text)
                .padding()
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.sentences)
                .background(Color(UIColor.systemBackground))
                .navigationTitle("New Entry")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                viewModel.addDailyNote(text: text)
                            }
                            dismiss()
                        }
                    }
                }
        }
    }
}

// MARK: - Hidden Archive
struct HiddenJournalArchiveView: View {
    @ObservedObject var viewModel: HabitTrackerViewModel
    @Environment(\.dismiss) var dismiss
    
    var sortedNotes: [DailyNote] {
        viewModel.dailyNotes.sorted(by: { $0.date > $1.date })
    }
    
    var body: some View {
        NavigationStack {
            List {
                if sortedNotes.isEmpty {
                    Text("No journal entries found.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(sortedNotes) { note in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(note.date.formatted(.dateTime.year().month().day()))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(note.text)
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            HStack {
                                Text("Automated Sentiment:")
                                    .font(.caption2)
                                Text(note.sentimentScore > 0 ? "Positive" : (note.sentimentScore < 0 ? "Negative" : "Neutral"))
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(note.sentimentScore > 0 ? .green : (note.sentimentScore < 0 ? .red : .gray))
                            }
                            .padding(.top, 2)
                        }
                        .padding(.vertical, 4)
                        .contextMenu {
                            Button(role: .destructive) {
                                withAnimation {
                                    viewModel.dailyNotes.removeAll(where: { $0.id == note.id })
                                }
                            } label: {
                                Label("Delete Entry", systemImage: "trash")
                            }
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            let note = sortedNotes[index]
                            viewModel.dailyNotes.removeAll(where: { $0.id == note.id })
                        }
                    }
                }
            }
            .navigationTitle("Secret Archive 🤫")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Analytics Components
struct MoodChartAnnotationView: View {
    let date: Date
    let avgVal: Double
    let firstNoteText: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(date, format: .dateTime.month().day())
                .font(.system(size: 10, weight: .bold))
            if avgVal > 0 {
                Text("Mood Avg: \(String(format: "%.1f", avgVal))")
                    .font(.system(size: 10))
            }
            if let note = firstNoteText {
                Text("Note: \"\(String(note.prefix(15)))...\"")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
        .padding(6)
        .background(Color(UIColor.tertiarySystemGroupedBackground).opacity(0.95))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.2), radius: 4)
    }
}

// MARK: - Habit Destroyer Views
struct HabitDestroyerView: View {
    @ObservedObject var viewModel: HabitTrackerViewModel
    @State private var showingAddSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.15))
                            .frame(width: 80, height: 80)
                        Image(systemName: "flame.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                    }
                    .padding(.top, 10)
                    
                    Text("Habit Destroyer")
                        .font(.title)
                        .fontWeight(.heavy)
                    
                    Text("Break the cycle and take back control of your life. Track your clean streaks and fight back.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                .padding(.bottom, 10)
                
                if viewModel.badHabits.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "shield.slash.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.red.opacity(0.5))
                        
                        Text("No targets identified")
                            .font(.headline)
                        
                        Text("Add a habit you want to quit, like smoking or drinking. Break the cycle!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(30)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(20)
                    .padding(.horizontal)
                    .padding(.top, 20)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.badHabits) { badHabit in
                            BadHabitRowView(badHabit: badHabit, viewModel: viewModel)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Destroyer")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddBadHabitView(viewModel: viewModel)
        }
    }
}

struct BadHabitRowView: View {
    let badHabit: BadHabit
    @ObservedObject var viewModel: HabitTrackerViewModel
    @State private var showingRelapseAlert = false
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(hex: badHabit.themeColorHex).opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Image(systemName: "xmark.shield.fill")
                    .foregroundColor(Color(hex: badHabit.themeColorHex))
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(badHabit.name)
                    .font(.headline)
                    .fontWeight(.bold)
                
                HStack(spacing: 4) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.caption2)
                    Text("Clean: \(badHabit.currentStreak)d")
                        .fontWeight(.semibold)
                }
                .font(.caption)
                .foregroundColor(badHabit.currentStreak == 0 ? .red : .primary)
                
                Text("Highest Streak: \(badHabit.highestStreak) days")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                playHaptic(style: .medium)
                showingRelapseAlert = true
            }) {
                VStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.title3)
                    Text("Relapse")
                        .font(.system(size: 10, weight: .bold))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemRed).opacity(0.15))
                .foregroundColor(.red)
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 5, y: 3)
        .contextMenu {
            Button(role: .destructive) {
                if let index = viewModel.badHabits.firstIndex(where: { $0.id == badHabit.id }) {
                    viewModel.deleteBadHabit(at: IndexSet(integer: index))
                }
            } label: {
                Label("Delete Tracker", systemImage: "trash")
            }
        }
        .alert("Did you slip up?", isPresented: $showingRelapseAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Yes, reset streak", role: .destructive) {
                withAnimation {
                    viewModel.logRelapse(for: badHabit)
                }
            }
        } message: {
            Text("This will reset your clean streak for '\(badHabit.name)' down to 0 days.")
        }
    }
}

struct AddBadHabitView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: HabitTrackerViewModel
    @State private var name = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Target"), footer: Text("Tracking bad habits explicitly helps break the cycle. Focus on beating your highest clean streak.")) {
                    TextField("e.g. Smoking, Drinking, Fast Food", text: $name)
                        .autocorrectionDisabled(true)
                }
            }
            .navigationTitle("Quit a Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if !name.trimmingCharacters(in: .whitespaces).isEmpty {
                            viewModel.addBadHabit(name: name.trimmingCharacters(in: .whitespaces))
                            dismiss()
                        }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
