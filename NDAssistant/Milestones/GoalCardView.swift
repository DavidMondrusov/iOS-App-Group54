import SwiftUI

struct GoalCardView: View {
    let goal: Goal
    var onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 12) {
                ProgressRingView(percent: percentComplete(for: goal))
                    .frame(width: 96, height: 96)

                VStack(alignment: .leading, spacing: 6) {
                    Text(goal.title)
                        .font(.headline)

                    HStack(spacing: 6) {
                        Chip(goal.domain.rawValue)
                        if let due = goal.dueDate {
                            Chip("Due: \(dateFormatterShort.string(from: due))")
                        }
                    }

                    Text("Baseline: \(goal.baseline) • Target: \(goal.target)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.gray.opacity(0.2))
                    .background(RoundedRectangle(cornerRadius: 12).fill(.white))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open goal \(goal.title)")
    }
}

private struct Chip: View {
    var text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.vertical, 2).padding(.horizontal, 8)
            .background(RoundedRectangle(cornerRadius: 999).stroke(Color.gray.opacity(0.3)))
    }
}
