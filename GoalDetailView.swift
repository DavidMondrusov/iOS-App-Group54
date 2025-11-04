import SwiftUI

struct GoalDetailView: View {
    let goal: Goal
    let child: Child?
    var onBack: () -> Void
    var onToggleMilestone: (UUID) -> Void
    var onAddCheckIn: (Int, String) -> Void

    private var lastCheckIn: CheckIn? {
        goal.checkIns.sorted(by: { $0.date > $1.date }).first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button("← Back") { onBack() }
                .buttonStyle(.plain)
                .foregroundStyle(.green)

            HStack(alignment: .center, spacing: 16) {
                ProgressRingView(percent: percentComplete(for: goal))
                    .frame(width: 120, height: 120)

                VStack(alignment: .leading, spacing: 6) {
                    Text(goal.title).font(.title3).bold()

                    HStack(spacing: 6) {
                        Chip(goal.domain.rawValue)
                        if let child { Chip("Child: \(child.name)") }
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
                Spacer()
            }

            Divider()

            Text("Milestones").font(.headline)
            MilestoneTimelineView(milestones: goal.milestones) { mid in
                onToggleMilestone(mid)
            }
            Text("Tip: tap a milestone to toggle Not started → In progress → Done.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Divider()

            Text("Log a Check-in").font(.headline)
            CheckInFormView { rating, note in
                onAddCheckIn(rating, note)
            }

            if !goal.checkIns.isEmpty {
                Text("History").font(.subheadline).padding(.top, 8)
                List(goal.checkIns.sorted(by: { $0.date > $1.date })) { ci in
                    HStack {
                        Text(dateFormatterShort.string(from: ci.date))
                            .frame(width: 90, alignment: .leading)
                        Text(String(repeating: "★", count: ci.rating) + String(repeating: "☆", count: 5 - ci.rating))
                            .accessibilityLabel("Rating \(ci.rating) out of 5")
                            .frame(width: 90, alignment: .leading)
                        if let note = ci.note, !note.isEmpty {
                            Text(note)
                        }
                    }.listRowInsets(EdgeInsets())
                }
                .frame(minHeight: 80, maxHeight: 220)
                .listStyle(.plain)
            }

            Spacer(minLength: 0)
        }
        .padding()
    }
}
