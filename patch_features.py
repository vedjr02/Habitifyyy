import re

file_path = "/Users/ved/MAINS/Maynooth UNI/Xcode/Habitify/Habitify/Habitify/ContentView.swift"
with open(file_path, "r") as f:
    content = f.read()

# Edit 1: Add Gamification Logic to ViewModel
s1_old = """    var totalCompletionVolume: Int {
        habits.reduce(0) { $0 + $1.completedDates.count }
    }"""
s1_new = """    var totalCompletionVolume: Int {
        habits.reduce(0) { $0 + $1.completedDates.count }
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
    }"""
content = content.replace(s1_old, s1_new)

# Edit 2: Add Gamification to DashboardHeaderView
s2_old = """            VStack(alignment: .leading, spacing: 4) {
                Text("Today's Progress")
                    .font(.headline)
                Text("\\(viewModel.habits.filter { $0.completedDates.contains(Calendar.current.startOfDay(for: Date())) }.count) of \\(viewModel.habits.count) habits completed")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }"""
s2_new = """            VStack(alignment: .leading, spacing: 4) {
                Text("Today's Progress")
                    .font(.headline)
                Text("\\(viewModel.habits.filter { $0.completedDates.contains(Calendar.current.startOfDay(for: Date())) }.count) of \\(viewModel.habits.count) habits completed")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    Text("Lvl \\(viewModel.currentLevel)")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 70, height: 6)
                    Capsule()
                        .fill(Color.indigo)
                        .frame(width: 70 * CGFloat(viewModel.xpProgressToNext), height: 6)
                }
                
                Text("\\(viewModel.totalXP) XP")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .fontWeight(.semibold)
            }
        }"""
content = content.replace(s2_old, s2_new)

# Edit 3: Add Quick Templates to AddHabitView
s3_old = """    // Quick predefined palette
    let colors = ["FF9500", "FF3B30", "34C759", "007AFF", "AF52DE", "FF2D55"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Details")) {"""
s3_new = """    // Quick predefined palette
    let colors = ["FF9500", "FF3B30", "34C759", "007AFF", "AF52DE", "FF2D55"]
    
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
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Quick Templates")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(quickTemplates, id: \\.title) { template in
                                Button(action: {
                                    habitName = template.title
                                    selectedCategory = template.category
                                    selectedColorHex = template.colorHex
                                    isNameFocused = true
                                }) {
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
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
                
                Section(header: Text("Details")) {"""
content = content.replace(s3_old, s3_new)

with open(file_path, "w") as f:
    f.write(content)

print("Features injected!")
