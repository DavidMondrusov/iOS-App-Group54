import SwiftUI

struct MilestoneTimelineView: View {
    let milestones: [Milestone]
    var onToggle: (UUID) -> Void

    private func statusColor(_ s: MilestoneStatus) -> Color {
        switch s {
        case .not_started: return .gray
        case .in_progress: return .blue
        case .done: return .green
        }
    }

    private func borderColor(_ s: MilestoneStatus) -> Color {
        switch s {
        case .not_started: return .gray.opacity(0.25)
        case .in_progress: return .blue.opacity(0.35)
        case .done: return .green.opacity(0.35)
        }
    }

    private func fillColor(_ s: MilestoneStatus) -> Color {
        switch s {
        case .not_started: return .white
        case .in_progress: return Color(uiColor: UIColor.systemBlue.withAlphaComponent(0.05))
        case .done: return Color(uiColor: UIColor.systemGreen.withAlphaComponent(0.06))
        }
    }


    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(milestones) { m in
                Button {
                    onToggle(m.id) // pass String id if your toggle expects String
                } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(statusColor(m.status))
                            .frame(width: 10, height: 10)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(m.title)
                                .font(.subheadline).bold()
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                            if let td = m.targetDate {
                                Text(dateFormatterShort.string(from: td))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(borderColor(m.status))
                            .background(RoundedRectangle(cornerRadius: 10).fill(fillColor(m.status)))
                    )
                }
                .buttonStyle(.plain)
                .accessibilityHint("Toggles milestone status")
            }
        }
        .padding(.vertical, 4)
    }
}
