import SwiftUI

// MARK: - MilestoneView

struct MilestoneView: View {
    @StateObject private var store = ProgressStore()
    @StateObject private var templateStore = TemplateStore()
    
    @State private var selectedDomain: Domain? = nil
    @State private var openGoalId: UUID? = nil
    @State private var showGoalForm = false
    
    private var openGoal: Goal? {
        store.goals.first(where: { $0.id == openGoalId })
    }
    
    private var filtered: [Goal] {
        store.goals.filter { selectedDomain == nil || $0.domain == selectedDomain }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header + New Goal
            HStack {
                Text("Progress Tracker")
                    .font(.title3)
                    .bold()
                Spacer()
                Button("+ New Goal") {
                    showGoalForm = true
                }
                .buttonStyle(.bordered)
                .sheet(isPresented: $showGoalForm) {
                    GoalFormView(store: store, templateStore: templateStore) { newGoalId in
                        openGoalId = newGoalId
                    }
                }
            }
            
            // Detail or List
            if let goal = openGoal {
                GoalDetailView(
                    goal: goal,
                    onBack: { openGoalId = nil },
                    onToggleMilestone: { milestoneId in
                        store.toggleMilestone(goalId: goal.id, milestoneId: milestoneId)
                    },
                    onAddCheckIn: { rating, note in
                        store.addCheckIn(goalId: goal.id, rating: rating, note: note)
                    },
                    store: store,
                    templateStore: templateStore// must be last if that’s how the view is defined
                )
            } else {
                // Filters + List
                FiltersView(selectedDomain: $selectedDomain)
                
                if filtered.isEmpty {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4]))
                        .frame(maxWidth: .infinity, minHeight: 80)
                        .overlay(
                            Text("No goals yet. Create one to start tracking milestones and check-ins.")
                                .foregroundStyle(.secondary)
                        )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filtered) { g in
                                GoalCardView(goal: g) {
                                    openGoalId = g.id
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
