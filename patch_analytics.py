import re

with open('Habitify/ContentView.swift', 'r') as f:
    code = f.read()

# 1. Add adherenceRate(for:) and actionableRecommendations to HabitTrackerViewModel
adherence_regex = r"(func getCategoryData.*?\{.*?\n    \})"

adherence_code = """func getCategoryData() -> [CategoryCompletion] {
        var dict: [HabitCategory: Int] = [:]
        for habit in habits {
            dict[habit.category, default: 0] += habit.completedDates.count
        }
        return dict.map { CategoryCompletion(category: $0.key.rawValue, count: $0.value) }
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
    }"""

code = re.sub(adherence_regex, adherence_code, code, flags=re.DOTALL)

# 2. Replace the AnalyticsView body
analytics_regex = r"(struct BusinessAnalyticsView: View \{.*?\n        var body: some View \{).*?(        \}\n        \.navigationTitle\(\"Analytics\"\))"

analytics_body = """
        ScrollView {
            VStack(spacing: 24) {
                // Dashboard Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Executive Overview")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Turn your data into actionable insights.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // KPI Cards
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        let atRisk = viewModel.habits.filter { viewModel.adherenceRate(for: $0) < 0.4 }.count
                        KPICard(title: "At-Risk Habits", value: "\(atRisk)", icon: "exclamationmark.triangle.fill", color: .orange)
                        KPICard(title: "7-Day Adherence", value: viewModel.adherenceRate7Days, icon: "percent", color: .green)
                    }
                    HStack(spacing: 16) {
                        KPICard(title: "Best Day", value: viewModel.bestPerformingDay, icon: "crown.fill", color: .indigo)
                        KPICard(title: "Active Streaks", value: "\(viewModel.habits.filter { $0.currentStreak > 0 }.count)", icon: "flame.fill", color: .red)
                    }
                }
                .padding(.horizontal)
                
                // AI Insights Engine
                VStack(alignment: .leading, spacing: 12) {
                    Text("AI Insights")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        let insights = viewModel.generateInsights()
                        let visibleInsights = isInsightsExpanded ? insights : Array(insights.prefix(1))
                        
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(visibleInsights, id: \\.self) { insight in
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
                                Text(isInsightsExpanded ? "Show Less" : "Reveal \\(insights.count - 1) More Insights")
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
                
                if !viewModel.habits.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        
                        // Actionable Recommendations
                        let recs = viewModel.actionableRecommendations()
                        if !recs.isEmpty {
                            Text("Action Plan")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                ForEach(recs, id: \\.habit.id) { rec in
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
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        }

                        // Priority / Focus Matrix
                        Text("Priority vs. Adherence Matrix")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Text("Top left means high importance but low completion. Focus there!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        Chart {
                            ForEach(viewModel.habits) { habit in
                                PointMark(
                                    x: .value("Importance", habit.importanceWeight),
                                    y: .value("Adherence", viewModel.adherenceRate(for: habit) * 100)
                                )
                                .foregroundStyle(Color(hex: habit.themeColorHex, default: .indigo))
                                .annotation(position: .top) {
                                    Text(habit.name)
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .chartXScale(domain: 0...6)
                        .chartYScale(domain: -10...110)
                        .chartXAxisLabel("Importance Weight")
                        .chartYAxisLabel("Completion %")
                        .frame(height: 250)
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        Text("Volume by Category")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        Chart {
                            ForEach(viewModel.getCategoryData()) { item in
                                BarMark(
                                    x: .value("Completions", item.count),
                                    y: .value("Category", item.category)
                                )
                                .foregroundStyle(by: .value("Category", item.category))
                            }
                        }
                        .chartLegend(position: .bottom)
                        .frame(height: 200)
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                } else {
                    Text("No data available to generate reports.")
                        .foregroundColor(.secondary)
                        .padding(.top, 40)
                }
            }
            .padding(.vertical)"""

code = re.sub(analytics_regex, r"\1" + analytics_body + r"\n\2", code, flags=re.DOTALL)

with open('Habitify/ContentView.swift', 'w') as f:
    f.write(code)

