import sys

path = "/Users/ved/MAINS/Maynooth UNI/Xcode/Habitify/Habitify/Habitify/ContentView.swift"

with open(path, "r") as f:
    text = f.read()

# Add Notification Manager
old_str = "import SwiftUI\nimport Combine\n\n// MARK: - Models"
new_str = """import SwiftUI\nimport Combine\nimport UserNotifications\n\n// MARK: - Notification Manager\nclass NotificationManager {\n    static let shared = NotificationManager()\n    \n    func requestAuthorization() {\n        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { success, error in\n            if let error = error {\n                print("Notification auth error: \\(error.localizedDescription)")\n            }\n        }\n    }\n    \n    func scheduleNotification(for habit: Habit) {\n        cancelNotification(for: habit.id.uuidString)\n        guard let reminderTime = habit.reminderTime else { return }\n        \n        let content = UNMutableNotificationContent()\n        content.title = "Habit Reminder"\n        content.body = "Time for \\(habit.name)! Keep your streak going 🔥"\n        content.sound = .default\n        \n        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)\n        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)\n        \n        let request = UNNotificationRequest(identifier: habit.id.uuidString, content: content, trigger: trigger)\n        UNUserNotificationCenter.current().add(request) { error in\n            if let error = error {\n                print("Error scheduling notification: \\(error.localizedDescription)")\n            }\n        }\n    }\n    \n    func cancelNotification(for id: String) {\n        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])\n    }\n}\n\n// MARK: - Models"""

text = text.replace(old_str, new_str)

vm_init_old = "    init() {\n        loadHabits()\n    }"
vm_init_new = """    var todayProgress: Double {\n        guard !habits.isEmpty else { return 0 }\n        let today = Calendar.current.startOfDay(for: Date())\n        let completed = habits.filter { $0.completedDates.contains(today) }.count\n        return Double(completed) / Double(habits.count)\n    }\n    \n    var totalActiveStreaks: Int {\n        habits.filter { $0.currentStreak > 0 }.count\n    }\n\n    init() {\n        loadHabits()\n        NotificationManager.shared.requestAuthorization()\n    }"""
text = text.replace(vm_init_old, vm_init_new)

add_habit_old = "func addHabit(name: String, category: HabitCategory, themeColorHex: String, frequency: HabitFrequency) {"
add_habit_new = "func addHabit(name: String, category: HabitCategory, themeColorHex: String, frequency: HabitFrequency, reminderTime: Date?) {"
text = text.replace(add_habit_old, add_habit_new)

add_habit_body_old = "themeColorHex: themeColorHex,\n            frequency: frequency\n        )\n        habits.append(newHabit)"
add_habit_body_new = "themeColorHex: themeColorHex,\n            frequency: frequency,\n            reminderTime: reminderTime\n        )\n        habits.append(newHabit)\n        if reminderTime != nil {\n            NotificationManager.shared.scheduleNotification(for: newHabit)\n        }"
text = text.replace(add_habit_body_old, add_habit_body_new)

delete_habit_old = "    func deleteHabit(at offsets: IndexSet) {\n        habits.remove(atOffsets: offsets)\n    }"
delete_habit_new = """    func deleteHabit(at offsets: IndexSet) {\n        for index in offsets {\n            NotificationManager.shared.cancelNotification(for: habits[index].id.uuidString)\n        }\n        habits.remove(atOffsets: offsets)\n    }\n    \n    func deleteHabit(_ habit: Habit) {\n        if let index = habits.firstIndex(where: { $0.id == habit.id }) {\n            NotificationManager.shared.cancelNotification(for: habit.id.uuidString)\n            habits.remove(at: index)\n        }\n    }"""
text = text.replace(delete_habit_old, delete_habit_new)

# Fix addHabit usage in AddHabitView
add_habit_call_old = "frequency: .daily // Default to daily for now until frequency selector is built\n                            )"
add_habit_call_new = "frequency: .daily,\n                                reminderTime: reminderEnabled ? reminderTime : nil\n                            )"
text = text.replace(add_habit_call_old, add_habit_call_new)

# Add Toggle and DatePicker to AddHabitView
form_section_old = "    @State private var habitName = \"\"\n    @State private var selectedCategory: HabitCategory = .other\n    @State private var selectedColorHex = \"FF9500\" // Default Orange"
form_section_new = "    @State private var habitName = \"\"\n    @State private var selectedCategory: HabitCategory = .other\n    @State private var selectedColorHex = \"FF9500\" // Default Orange\n    @State private var reminderEnabled = false\n    @State private var reminderTime = Date()"
text = text.replace(form_section_old, form_section_new)

color_section_end_old = "                        .padding(.vertical, 8)\n                    }\n                }\n            }"
color_section_end_new = "                        .padding(.vertical, 8)\n                    }\n                }\n                \n                Section(header: Text(\"Reminder\")) {\n                    Toggle(\"Enable Reminder\", isOn: $reminderEnabled)\n                    if reminderEnabled {\n                        DatePicker(\"Time\", selection: $reminderTime, displayedComponents: .hourAndMinute)\n                    }\n                }\n            }"
text = text.replace(color_section_end_old, color_section_end_new)

with open(path, "w") as f:
    f.write(text)

print("SUCCESS")
