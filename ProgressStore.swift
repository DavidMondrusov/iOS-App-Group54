import Foundation
import SwiftUI

@MainActor
final class ProgressStore: ObservableObject {
    @Published var children: [Child] = []
    @Published var goals: [Goal] = []

    private let fileName = "progress_data.json"

    init() {
        Task { await load() }
    }

    // MARK: - Persistence

    private var fileURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent(fileName)
    }

    func load() async {
        do {
            let url = fileURL
            if !FileManager.default.fileExists(atPath: url.path) {
                seedIfEmpty()
                try await save()
                return
            }
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(AppData.self, from: data)
            self.children = decoded.children
            self.goals = decoded.goals
        } catch {
            // If load fails, start fresh with seed
            seedIfEmpty()
            try? await save()
        }
    }

    func save() async throws {
        let data = try JSONEncoder().encode(AppData(children: children, goals: goals))
        try data.write(to: fileURL, options: [.atomic])
    }

    // MARK: - Seed

    func seedIfEmpty() {
        guard children.isEmpty && goals.isEmpty else { return }

        let aiden = Child(name: "Aiden")
        let maya = Child(name: "Maya")
        children = [aiden, maya]

        let g1 = Goal(
            childId: aiden.id,
            title: "Morning Routine Independence",
            domain: .Developmental,
            baseline: "Needs 5+ prompts for each step.",
            target: "Completes routine with ≤1 prompt per step.",
            dueDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
            milestones: [
                Milestone(title: "Brush teeth with 2 prompts", status: .done),
                Milestone(title: "Dress with 2 prompts", status: .in_progress),
                Milestone(title: "Pack backpack independently", status: .not_started)
            ],
            checkIns: []
        )

        goals = [g1]
    }

    // MARK: - Mutations

    func createQuickGoal(for childId: UUID?, domain: Domain?) {
        guard let childId = childId ?? children.first?.id else { return }
        var new = Goal(
            childId: childId,
            title: "New Goal",
            domain: domain ?? .Other,
            baseline: "Describe current performance…",
            target: "Describe desired outcome…",
            milestones: [
                Milestone(title: "Milestone 1"),
                Milestone(title: "Milestone 2")
            ]
        )
        goals.insert(new, at: 0)
        Task { try? await save() }
    }

    func toggleMilestone(goalId: UUID, milestoneId: UUID) {
        guard let gi = goals.firstIndex(where: { $0.id == goalId }),
              let mi = goals[gi].milestones.firstIndex(where: { $0.id == milestoneId }) else { return }
        let status = goals[gi].milestones[mi].status
        let next: MilestoneStatus = status == .not_started ? .in_progress : status == .in_progress ? .done : .not_started
        goals[gi].milestones[mi].status = next
        Task { try? await save() }
    }

    func addCheckIn(goalId: UUID, rating: Int, note: String?) {
        guard let gi = goals.firstIndex(where: { $0.id == goalId }) else { return }
        let ci = CheckIn(goalId: goalId, rating: max(1, min(5, rating)), note: note?.trimmingCharacters(in: .whitespacesAndNewlines))
        goals[gi].checkIns.append(ci)
        Task { try? await save() }
    }
}
