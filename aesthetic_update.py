import sys

path = "/Users/ved/MAINS/Maynooth UNI/Xcode/Habitify/Habitify/Habitify/ContentView.swift"
with open(path, "r") as f:
    text = f.read()

dashboard_view = """struct DashboardView: View {
    @ObservedObject var viewModel: HabitTrackerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Progress")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 20) {
                // Circular Progress
                ZStack {
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: CGFloat(viewModel.todayProgress))
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(), value: viewModel.todayProgress)
                    
                    Text("\(Int(viewModel.todayProgress * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .frame(width: 80, height: 80)
                
                // Stats
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(viewModel.totalActiveStreaks) Active Streaks")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    HStack {
                        Image(systemName: "checklist")
                            .foregroundColor(.green)
                        Text("\(viewModel.habits.count) Tracked Habits")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
            )
        }
        .padding(.horizontal)
    }
}
"""

# Insert DashboardView before ContentView
text = text.replace("// MARK: - Views\nstruct ContentView", "// MARK: - Views\n" + dashboard_view + "\nstruct ContentView")

# Redesign ContentView entirely
content_view_old = """struct ContentView: View {
    @StateObject private var viewModel = HabitTrackerViewModel()
    @State private var showingAddHabitSheet = false
    
    var body: some View {
        NavigationStack {
            List {
                if viewModel.habits.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "star.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.orange)
                        
                        Text("No habits yet")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Create your first habit by tapping the + icon above to start building your streak!")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.vertical, 40)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(viewModel.habits) { habit in
                        ZStack {
                            NavigationLink(destination: HabitDetailView(habit: habit)) {
                                EmptyView()
                            }
                            .opacity(0)
                            
                            HabitRowView(habit: habit) {
                                viewModel.toggleCompletion(for: habit)
                            }
                        }
                    }
                    .onDelete(perform: viewModel.deleteHabit)
                }
            }
            .navigationTitle("My Habits")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddHabitSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showingAddHabitSheet) {
                AddHabitView(viewModel: viewModel)
            }
        }
    }
}"""

content_view_new = """struct ContentView: View {
    @StateObject private var viewModel = HabitTrackerViewModel()
    @State private var showingAddHabitSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        DashboardView(viewModel: viewModel)
                            .padding(.top, 10)
                        
                        if viewModel.habits.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "star.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.orange)
                                
                                Text("No habits yet")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("Create your first habit by tapping the + icon above to start building your streak!")
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .padding(.vertical, 60)
                            .frame(maxWidth: .infinity)
                        } else {
                            VStack(spacing: 16) {
                                ForEach(viewModel.habits) { habit in
                                    NavigationLink(destination: HabitDetailView(habit: habit)) {
                                        HabitRowView(habit: habit) {
                                            viewModel.toggleCompletion(for: habit)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            withAnimation {
                                                viewModel.deleteHabit(habit)
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("My Habits")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddHabitSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingAddHabitSheet) {
                AddHabitView(viewModel: viewModel)
            }
        }
    }
}"""

text = text.replace(content_view_old, content_view_new)

# Redesign HabitRowView
row_view_old = """struct HabitRowView: View {
    let habit: Habit
    let toggleAction: () -> Void
    
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
                
                Text("🔥 Streak: \(habit.currentStreak)  •  Next Badge: \(habit.nextMilestone)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: toggleAction) {
                Image(systemName: isCompletedToday ? "checkmark.circle.fill" : "circle")
                    .resizable()
                    .frame(width: 28, height: 28)
                    .foregroundColor(isCompletedToday ? Color(hex: habit.themeColorHex) : .gray.opacity(0.4))
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel(isCompletedToday ? "Mark incomplete" : "Mark complete")
        }
        .padding(.vertical, 6)
    }
}"""

row_view_new = """struct HabitRowView: View {
    let habit: Habit
    let toggleAction: () -> Void
    
    var isCompletedToday: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return habit.completedDates.contains(today)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: habit.themeColorHex).opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: habit.category.icon)
                    .foregroundColor(Color(hex: habit.themeColorHex))
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(habit.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 12) {
                    Label("\(habit.currentStreak)", systemImage: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.subheadline.bold())
                    
                    if let reminderTime = habit.reminderTime {
                        Label(reminderTime.formatted(date: .omitted, time: .shortened), systemImage: "bell.fill")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
            
            Spacer()
            
            Button {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    toggleAction()
                }
            } label: {
                Image(systemName: isCompletedToday ? "checkmark.circle.fill" : "circle")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(isCompletedToday ? Color(hex: habit.themeColorHex) : .gray.opacity(0.3))
                    .scaleEffect(isCompletedToday ? 1.1 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel(isCompletedToday ? "Mark incomplete" : "Mark complete")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
    }
}"""

text = text.replace(row_view_old, row_view_new)

with open(path, "w") as f:
    f.write(text)

print("AESTHETIC UPDATE SUCCESS")
