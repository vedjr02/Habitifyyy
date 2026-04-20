import sys

path = "/Users/ved/MAINS/Maynooth UNI/Xcode/Habitify/Habitify/Habitify/ContentView.swift"

with open(path, "r") as f:
    text = f.read()

# Add UserNotifications import
if "import UserNotifications" not in text:
    text = text.replace("import Charts\n", "import Charts\nimport UserNotifications\n")

# Add NotificationManager
notification_manager = """
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
"""

if "class NotificationManager" not in text:
    text = text.replace("// MARK: - Models", notification_manager + "\n// MARK: - Models")

# Add TimeOfDay enum
time_of_day_enum = """enum TimeOfDay: String, Codable, CaseIterable {
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
"""

if "enum TimeOfDay" not in text:
    text = text.replace("enum HabitCategory:", time_of_day_enum + "\nenum HabitCategory:")

# Update Habit struct
if "var timeOfDay: TimeOfDay = .anytime" not in text:
    text = text.replace("var frequency: HabitFrequency", "var frequency: HabitFrequency\n    var timeOfDay: TimeOfDay = .anytime")

# Add AppTheme
if "enum AppTheme: String, CaseIterable" not in text:
    text = text.replace("// MARK: - ViewModel", """enum AppTheme: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
}

// MARK: - ViewModel""")

# Add to HabitTrackerViewModel mapping
if "loadHabits()" in text and "NotificationManager.shared.requestAuthorization()" not in text:
    text = text.replace("init() {\n        loadHabits()\n    }", "init() {\n        loadHabits()\n        NotificationManager.shared.requestAuthorization()\n    }")

# Update addHabit
text = text.replace("func addHabit(name: String, category: HabitCategory, themeColorHex: String, frequency: HabitFrequency) {", "func addHabit(name: String, category: HabitCategory, themeColorHex: String, frequency: HabitFrequency, timeOfDay: TimeOfDay, reminderTime: Date?) {")
text = text.replace("frequency: frequency\n        )", "frequency: frequency,\n            reminderTime: reminderTime,\n            timeOfDay: timeOfDay\n        )")
text = text.replace("habits.append(newHabit)", "habits.append(newHabit)\n        if reminderTime != nil {\n            NotificationManager.shared.scheduleNotification(for: newHabit)\n        }")

# Update deleteHabit
text = text.replace("habits.remove(atOffsets: offsets)", "for index in offsets {\n            NotificationManager.shared.cancelNotification(for: habits[index].id.uuidString)\n        }\n        habits.remove(atOffsets: offsets)")

# Rename ContentView -> DashboardView, replace body completely
dash_body_new = """struct DashboardView: View {
    @ObservedObject var viewModel: HabitTrackerViewModel
    @State private var showingAddHabitSheet = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DashboardHeaderView(viewModel: viewModel)
                    .padding(.bottom, 8)
                
                List {
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
                        ForEach(TimeOfDay.allCases, id: \.self) { timeOfDay in
                            let sectionHabits = viewModel.habits.filter { $0.timeOfDay == timeOfDay }
                            if !sectionHabits.isEmpty {
                                Section {
                                    ForEach(sectionHabits) { habit in
                                        ZStack {
                                            NavigationLink(destination: HabitDetailView(habit: habit)) {
                                                EmptyView()
                                            }
                                            .opacity(0)
                                            
                                            HabitRowView(habit: habit) {
                                                withAnimation(.spring()) {
                                                    viewModel.toggleCompletion(for: habit)
                                                }
                                            }
                                        }
                                    }
                                    .onDelete { offsets in
                                        // Map section offsets to global habits array offsets
                                        let habitsToDelete = offsets.map { sectionHabits[$0] }
                                        for habit in habitsToDelete {
                                            if let index = viewModel.habits.firstIndex(where: { $0.id == habit.id }) {
                                                viewModel.deleteHabit(at: IndexSet(integer: index))
                                            }
                                        }
                                    }
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
                }
                .listStyle(.insetGrouped)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddHabitSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.indigo)
                    }
                }
            }
            .sheet(isPresented: $showingAddHabitSheet) {
                AddHabitView(viewModel: viewModel)
            }
        }
    }
}
"""

# Extract the old ContentView starting from struct ContentView: View to its end. 
# We'll use simple search-replace.
import re

content_view_pattern = re.compile(r'struct ContentView: View \{.*?\n\}\n', re.DOTALL)
match = content_view_pattern.search(text)
if match:
    text = text[:match.start()] + dash_body_new + "\n" + text[match.end():]

# Now insert the new ContentView (as TabView) right before DashboardView
new_content_view = """struct ContentView: View {
    @StateObject private var viewModel = HabitTrackerViewModel()
    @AppStorage("appTheme") private var appTheme: AppTheme = .system
    
    var body: some View {
        TabView {
            DashboardView(viewModel: viewModel)
                .tabItem {
                    Label("Dashboard", systemImage: "square.grid.2x2.fill")
                }
            
            BusinessAnalyticsView(viewModel: viewModel)
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.xaxis")
                }
            
            SettingsView(viewModel: viewModel)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .preferredColorScheme(appTheme == .system ? nil : (appTheme == .dark ? .dark : .light))
    }
}

"""
text = text.replace("struct DashboardView:", new_content_view + "struct DashboardView:")

# AddHabitView enhancements
add_habit_body_top = """    @State private var habitName = ""
    @State private var selectedCategory: HabitCategory = .other
    @State private var selectedColorHex = "FF9500" // Default Orange
    @State private var selectedTimeOfDay: TimeOfDay = .anytime
    @State private var reminderEnabled = false
    @State private var reminderTime = Date()"""

add_habit_body_old = """    @State private var habitName = ""
    @State private var selectedCategory: HabitCategory = .other
    @State private var selectedColorHex = "FF9500" // Default Orange"""
text = text.replace(add_habit_body_old, add_habit_body_top)

time_picker = """                    Picker("Time of Day", selection: $selectedTimeOfDay) {
                        ForEach(TimeOfDay.allCases, id: \.self) { time in
                            HStack {
                                Image(systemName: time.icon)
                                Text(time.rawValue)
                            }.tag(time)
                        }
                    }"""
text = text.replace('Picker("Category", selection: $selectedCategory) {\n                        ForEach(HabitCategory.allCases, id: \\.self) {\n                            HStack {\n                                Image(systemName: category.icon)\n                                Text(category.rawValue)\n                            }.tag(category)\n                        }\n                    }', 'Picker("Category", selection: $selectedCategory) {\n                        ForEach(HabitCategory.allCases, id: \\.self) { category in\n                            HStack {\n                                Image(systemName: category.icon)\n                                Text(category.rawValue)\n                            }.tag(category)\n                        }\n                    }\n                    \n' + time_picker)

reminder_section = """                Section(header: Text("Reminder & Schedule")) {
                    Toggle("Enable Reminder", isOn: $reminderEnabled)
                    if reminderEnabled {
                        DatePicker("Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                }
"""
text = text.replace("                Section(header: Text(\"Color\")) {", reminder_section + "                Section(header: Text(\"Color\")) {")

text = text.replace("frequency: .daily // Default to daily for now until frequency selector is built", "frequency: .daily,\n                                timeOfDay: selectedTimeOfDay,\n                                reminderTime: reminderEnabled ? reminderTime : nil")

# Now update SettingsView
settings_new = """struct SettingsView: View {
    @ObservedObject var viewModel: HabitTrackerViewModel
    @AppStorage("appTheme") private var appTheme: AppTheme = .system
    @State private var notificationsEnabled = true
    
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
                        // Placeholder
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
        }
    }
}
"""
text = re.sub(r'struct SettingsView: View \{.*?\n\}\n', settings_new, text, flags=re.DOTALL)

with open(path, "w") as f:
    f.write(text)

print("UPDATED!")
