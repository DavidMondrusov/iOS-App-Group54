import SwiftUI

struct GoalDetailView: View {
    let goal: Goal
    let onBack: () -> Void
    let onToggleMilestone: (UUID) -> Void
    let onAddCheckIn: (Int, String?) -> Void
    @ObservedObject var store: ProgressStore
    @ObservedObject var templateStore: TemplateStore

    @State private var showDeleteAlert = false
    @State private var showEditGoalForm = false

    private var lastCheckIn: CheckIn? {
        goal.checkIns.sorted(by: { $0.date > $1.date }).first
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Top buttons
                HStack {
                    Button("← Back") { onBack() }
                        .buttonStyle(.bordered)
                        .tint(.green)
                    Spacer()
                    Button("Update") { showEditGoalForm = true }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    Button(role: .destructive) { showDeleteAlert = true } label: {
                        Text("Delete")
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }

                // Goal Info
                VStack(alignment: .leading, spacing: 8) {
                    Text(goal.title)
                        .font(.title3)
                        .bold()

                    HStack(spacing: 8) {
                        Chip(goal.domain.rawValue)
                        if let due = goal.dueDate { Chip("Due: \(dateFormatterShort.string(from: due))") }
                    }

                    Text("Baseline: \(goal.baseline)")
                    Text("Target: \(goal.target)")

                    if let last = lastCheckIn {
                        Text("Last check-in: \(dateFormatterShort.string(from: last.date)) • Rating \(last.rating)/5")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                // Progress
                ProgressBarView(percent: percentComplete(for: goal))
                    .frame(height: 20)

                Divider()

                // Milestones
                VStack(alignment: .leading, spacing: 8) {
                    Text("Milestones").font(.headline)
                    MilestoneTimelineView(milestones: goal.milestones, onToggle: onToggleMilestone)
                    Text("Tip: tap a milestone to toggle Not started → In progress → Done.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Divider()

                // Check-ins
                VStack(alignment: .leading, spacing: 8) {
                    Text("Log a Check-in").font(.headline)
                    CheckInFormView(onAddCheckIn: onAddCheckIn)

                    if !goal.checkIns.isEmpty {
                        Text("History").font(.subheadline).padding(.top, 4)
                        ForEach(goal.checkIns.sorted(by: { $0.date > $1.date })) { ci in
                            HStack(spacing: 8) {
                                Text(dateFormatterShort.string(from: ci.date))
                                    .frame(width: 90, alignment: .leading)
                                Text(String(repeating: "★", count: ci.rating) + String(repeating: "☆", count: 5 - ci.rating))
                                    .accessibilityLabel("Rating \(ci.rating) out of 5")
                                    .frame(width: 90, alignment: .leading)
                                if let note = ci.note, !note.isEmpty {
                                    Text(note)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .alert("Delete Goal?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                store.deleteGoal(goal)
                onBack()
            }
        } message: {
            Text("This will remove the goal permanently.")
        }
        .sheet(isPresented: $showEditGoalForm) {
            GoalFormView(store: store, templateStore: templateStore, goalToEdit: goal) { _ in
                showEditGoalForm = false
            }
        }
    }
}

private struct Chip: View {
    var text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.vertical, 2)
            .padding(.horizontal, 8)
            .background(RoundedRectangle(cornerRadius: 999).stroke(Color.gray.opacity(0.3)))
    }
}
