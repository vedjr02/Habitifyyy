import re

file_path = "/Users/ved/MAINS/Maynooth UNI/Xcode/Habitify/Habitify/Habitify/ContentView.swift"
with open(file_path, "r") as f:
    content = f.read()

# Edit 1: Add Search
s1_old = """struct DashboardView: View {
    @ObservedObject var viewModel: HabitTrackerViewModel
    @State private var showingAddHabitSheet = false
    
    var body: some View {"""
    
s1_new = """struct DashboardView: View {
    @ObservedObject var viewModel: HabitTrackerViewModel
    @State private var showingAddHabitSheet = false
    @State private var searchText = ""
    
    var body: some View {"""

content = content.replace(s1_old, s1_new)

s2_old = """                    } else {
                        ForEach(TaskHorizon.allCases, id: \\.self) { horizon in
                            let sectionHabits = viewModel.habits.filter { $0.taskHorizon == horizon }
                            if !sectionHabits.isEmpty {"""

s2_new = """                    } else {
                        let filteredHabits = viewModel.habits.filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }
                        
                        ForEach(TaskHorizon.allCases, id: \\.self) { horizon in
                            let sectionHabits = filteredHabits.filter { $0.taskHorizon == horizon }
                            if !sectionHabits.isEmpty {"""

content = content.replace(s2_old, s2_new)

s3_old = """                }
                .listStyle(.insetGrouped)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Habitify")"""

s3_new = """                }
                .listStyle(.insetGrouped)
                .searchable(text: $searchText, prompt: "Search tasks...")
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Habitify")"""

content = content.replace(s3_old, s3_new)

# Edit 2: Add Motivational Text
s4_old = """    var todayProgress: Double {
        guard !viewModel.habits.isEmpty else { return 0 }
        let today = Calendar.current.startOfDay(for: Date())
        let completedToday = viewModel.habits.filter { $0.completedDates.contains(today) }.count
        return Double(completedToday) / Double(viewModel.habits.count)
    }
    
    var body: some View {"""

s4_new = """    var todayProgress: Double {
        guard !viewModel.habits.isEmpty else { return 0 }
        let today = Calendar.current.startOfDay(for: Date())
        let completedToday = viewModel.habits.filter { $0.completedDates.contains(today) }.count
        return Double(completedToday) / Double(viewModel.habits.count)
    }
    
    var motivationalText: String {
        if viewModel.habits.isEmpty { return "Set up your first task!" }
        if todayProgress == 0 { return "Ready to start the day?" }
        if todayProgress < 0.5 { return "Making steady progress!" }
        if todayProgress < 1.0 { return "Almost done, finish strong!" }
        return "All tasks complete! 🌟"
    }
    
    var body: some View {"""

content = content.replace(s4_old, s4_new)

s5_old = """            VStack(alignment: .leading, spacing: 4) {
                Text("Today's Progress")
                    .font(.headline)
                Text("\\(viewModel.habits.filter { $0.completedDates.contains(Calendar.current.startOfDay(for: Date())) }.count) of \\(viewModel.habits.count) habits completed")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }"""

s5_new = """            VStack(alignment: .leading, spacing: 4) {
                Text("Today's Progress")
                    .font(.headline)
                Text("\\(viewModel.habits.filter { $0.completedDates.contains(Calendar.current.startOfDay(for: Date())) }.count) of \\(viewModel.habits.count) habits completed")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(motivationalText)
                    .font(.caption)
                    .foregroundColor(.indigo)
                    .fontWeight(.semibold)
                    .padding(.top, 2)
            }"""

content = content.replace(s5_old, s5_new)

# Edit 3: Add Frequency Type
s6_old = """    @State private var reminderEnabled = false
    @State private var reminderTime = Date()
    
    // Quick predefined palette"""

s6_new = """    @State private var reminderEnabled = false
    @State private var reminderTime = Date()
    
    enum FrequencySelectorType: String, CaseIterable {
        case daily = "Daily"
        case specific = "Specific Days"
        case weekly = "Times/Week"
    }
    @State private var frequencyType: FrequencySelectorType = .daily
    @State private var selectedDays: Set<Int> = [1, 2, 3, 4, 5] // Default weekday selection
    @State private var timesPerWeek: Int = 3
    
    // Quick predefined palette"""

content = content.replace(s6_old, s6_new)

s7_old = """                Section(header: Text("Details")) {
                    TextField("Habit Name (e.g. Read 10 pages)", text: $habitName)
                        .focused($isNameFocused)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(HabitCategory.allCases, id: \\.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.rawValue)
                            }.tag(category)
                        }
                    }
                }
                
                Section(header: Text("Reminder & Schedule")) {"""

s7_new = """                Section(header: Text("Details")) {
                    TextField("Habit Name (e.g. Read 10 pages)", text: $habitName)
                        .focused($isNameFocused)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(HabitCategory.allCases, id: \\.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.rawValue)
                            }.tag(category)
                        }
                    }
                }
                
                Section(header: Text("Frequency")) {
                    Picker("Frequency Type", selection: $frequencyType) {
                        ForEach(FrequencySelectorType.allCases, id: \\.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    if frequencyType == .specific {
                        HStack {
                            Spacer()
                            ForEach(0..<7, id: \\.self) { index in
                                let dayId = index + 1
                                let isSelected = selectedDays.contains(dayId)
                                Text(Calendar.current.veryShortWeekdaySymbols[index])
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .frame(width: 32, height: 32)
                                    .background(isSelected ? Color.indigo : Color.gray.opacity(0.2))
                                    .foregroundColor(isSelected ? .white : .primary)
                                    .clipShape(Circle())
                                    .onTapGesture {
                                        if isSelected && selectedDays.count > 1 {
                                            selectedDays.remove(dayId)
                                        } else {
                                            selectedDays.insert(dayId)
                                        }
                                    }
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    } else if frequencyType == .weekly {
                        Stepper("\\(timesPerWeek) times per week", value: $timesPerWeek, in: 1...7)
                    }
                }
                
                Section(header: Text("Reminder & Schedule")) {"""

content = content.replace(s7_old, s7_new)

s8_old = """                            viewModel.addHabit(
                                name: trimmedName,
                                category: selectedCategory,
                                themeColorHex: selectedColorHex,
                                frequency: .daily,
                                timeOfDay: selectedTimeOfDay,
                                reminderTime: reminderEnabled ? reminderTime : nil
                            )"""

s8_new = """                            let finalFrequency: HabitFrequency
                            switch frequencyType {
                            case .daily:
                                finalFrequency = .daily
                            case .specific:
                                finalFrequency = .specificDays(Array(selectedDays).sorted())
                            case .weekly:
                                finalFrequency = .timesPerWeek(timesPerWeek)
                            }
                            
                            viewModel.addHabit(
                                name: trimmedName,
                                category: selectedCategory,
                                themeColorHex: selectedColorHex,
                                frequency: finalFrequency,
                                timeOfDay: selectedTimeOfDay,
                                reminderTime: reminderEnabled ? reminderTime : nil
                            )"""

content = content.replace(s8_old, s8_new)

with open(file_path, "w") as f:
    f.write(content)

print("Patch applied.")
