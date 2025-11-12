import SwiftUI

struct MilestoneView: View {
    @StateObject private var store = ProgressStore()

    @State private var selectedChildId: UUID? = nil
    @State private var selectedDomain: Domain? = nil
    @State private var openGoalId: UUID? = nil

    private var openGoal: Goal? {
        store.goals.first(where: { $0.id == openGoalId })
    }
    private var openChild: Child? {
        guard let gid = openGoalId, let goal = store.goals.first(where: { $0.id == gid }) else { return nil }
        return store.children.first(where: { $0.id == goal.childId })
    }

    private var filtered: [Goal] {
        store.goals.filter { g in
            let childOK = selectedChildId == nil ? true : g.childId == selectedChildId
            let domainOK = selectedDomain == nil ? true : g.domain == selectedDomain
            return childOK && domainOK
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Progress Tracker").font(.title3).bold()
                Spacer()
                Button("+ New Goal") {
                    store.createQuickGoal(for: selectedChildId ?? store.children.first?.id, domain: selectedDomain)
                    openGoalId = store.goals.first?.id
                }
                .buttonStyle(.bordered)
            }

            if openGoal == nil {
                FiltersView(children: store.children, selectedChildId: $selectedChildId, selectedDomain: $selectedDomain)

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
                                GoalCardView(goal: g, child: store.children.first(where: { $0.id == g.childId })) {
                                    openGoalId = g.id
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            } else if let goal = openGoal {
                GoalDetailView(
                    goal: goal,
                    child: openChild,
                    onBack: { openGoalId = nil },
                    onToggleMilestone: { mid in store.toggleMilestone(goalId: goal.id, milestoneId: mid) },
                    onAddCheckIn: { rating, note in store.addCheckIn(goalId: goal.id, rating: rating, note: note) }
                )
            }

            Spacer(minLength: 0)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
