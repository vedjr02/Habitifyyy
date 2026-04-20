import re

with open('Habitify/ContentView.swift', 'r') as f:
    code = f.read()

# Replace TabView Analytics title
code = code.replace('Label("Analytics", systemImage: "chart.bar.xaxis")', 'Label("Journey & Insights", systemImage: "chart.bar.xaxis")')

# Generate the new BusinessAnalyticsView body
old_view_regex = r"(struct BusinessAnalyticsView: View \{.*?\n    var body: some View \{).*?(\n        \}\n        \.navigationTitle\(\"Analytics\"\)\n        \.navigationBarTitleDisplayMode\(\.inline\)\n    \}\n})"

new_view = """
        ScrollView {
            VStack(spacing: 24) {
                // Dashboard Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Journey & Insights")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Visualize your progress and discover actionable patterns.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // Activity Calendar Heatmap
                ActivityHeatmapView(viewModel: viewModel)
                
                // Action Plan
                if !viewModel.habits.isEmpty {
                    let recs = viewModel.actionableRecommendations()
                    if !recs.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
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
                        }
                    }
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
                
                // KPI Cards (Moved to bottom)
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        KPICard(title: "At-Risk Habits", value: "\\(viewModel.atRiskHabitsCount)", icon: "exclamationmark.triangle.fill", color: .orange)
                        KPICard(title: "7-Day Adherence", value: viewModel.adherenceRate7Days, icon: "percent", color: .green)
                    }
                    HStack(spacing: 16) {
                        KPICard(title: "Best Day", value: viewModel.bestPerformingDay, icon: "crown.fill", color: .indigo)
                        KPICard(title: "Active Streaks", value: "\\(viewModel.habits.filter { $0.currentStreak > 0 }.count)", icon: "flame.fill", color: .red)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)"""

code = re.sub(old_view_regex, r"\1" + new_view + r"\n        }\n        .navigationTitle(\"Journey & Insights\")\n        .navigationBarTitleDisplayMode(.inline)\n    }\n}", code, flags=re.DOTALL)

with open('Habitify/ContentView.swift', 'w') as f:
    f.write(code)
