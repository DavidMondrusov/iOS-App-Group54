import Foundation

enum Domain: String, CaseIterable, Codable, Identifiable {
    case Developmental, Educational, Therapeutic, Other
    var id: String { rawValue }
}

struct Child: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
}

enum MilestoneStatus: String, Codable, CaseIterable {
    case not_started, in_progress, done
}

struct Milestone: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var targetDate: Date? = nil
    var status: MilestoneStatus = .not_started
    var notes: String? = nil
}

struct CheckIn: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var goalId: UUID
    var date: Date = Date()
    var rating: Int // 1...5
    var note: String? = nil
}

struct Goal: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var childId: UUID
    var title: String
    var domain: Domain
    var baseline: String
    var target: String
    var dueDate: Date? = nil
    var milestones: [Milestone] = []
    var checkIns: [CheckIn] = []
    var createdAt: Date = Date()
}

struct AppData: Codable {
    var children: [Child] = []
    var goals: [Goal] = []
}
