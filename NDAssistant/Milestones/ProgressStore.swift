//
//  ProgressStoreUpdate.swift
//  NDAssistant
//
//  Created by David Mondrusov on 11/15/25.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth
import Combine

@MainActor
final class ProgressStore: ObservableObject {
    @Published var goals: [Goal] = []
    
    private var ref: DatabaseReference? {
            guard let userId = Auth.auth().currentUser?.uid else {
                print("No signed-in user!")
                return nil
            }
            return Database.database().reference().child("users").child(userId).child("progress/goals")
        }

    init() {
        print("Store loaded")
        self.load()
    }

    // MARK: - Load from Firebase
    func load() {
        guard let ref = ref else {
            print("⚠️ load(): ref is nil")
            return
        }
        print(ref)

        ref.observe(.value) { snapshot in
            guard let value = snapshot.value as? [String: Any] else {
                self.goals = []
                print("⚠️ load(): No goals or wrong format")
                return
            }
            print(value)

            self.goals = value.compactMap { (_, data) in
                guard let dict = data as? [String: Any] else { return nil }
                return ProgressStore.goalFromDict(dict)
            }

            print(self.goals)
            print("✅ Loaded \(self.goals.count) goals")
        }
    }

    // MARK: - Save to Firebase
    func save() {
        guard let ref = ref else { return }

        // Dictionary keyed by goal.id
        let dict = Dictionary(uniqueKeysWithValues: goals.map { ($0.id.uuidString, ProgressStore.goalToDict($0)) })

        ref.setValue(dict) { error, _ in
            if let error = error {
                print("❌ Failed to save goals: \(error.localizedDescription)")
            } else {
                print("✅ Successfully saved goals for user \(Auth.auth().currentUser?.uid ?? "unknown")")
            }
        }
    }
    
    // MARK: - CRUD
    func addGoal(_ goal: Goal, completion: ((Error?) -> Void)? = nil) {
        guard let ref = ref else { completion?(nil); return }
        goals.append(goal)

        let goalDict = ProgressStore.goalToDict(goal)
        ref.child(goal.id.uuidString).setValue(goalDict) { error, _ in
            if let error = error {
                print("❌ Failed to add goal: \(error.localizedDescription)")
            } else {
                print("✅ Successfully added goal \(goal.id)")
            }
            completion?(error)
        }
    }

    func updateGoal(_ goal: Goal) {
        guard let ref = ref else { return }
        if let idx = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[idx] = goal
            ref.child(goal.id.uuidString).setValue(ProgressStore.goalToDict(goal)) { error, _ in
                if let error = error {
                    print("❌ Failed to update goal: \(error.localizedDescription)")
                } else {
                    print("✅ Successfully updated goal \(goal.id)")
                }
            }
        }
    }

    func deleteGoal(_ goal: Goal) {
        guard let ref = ref else { return }
        goals.removeAll { $0.id == goal.id }
        ref.child(goal.id.uuidString).removeValue { error, _ in
            if let error = error {
                print("❌ Failed to delete goal: \(error.localizedDescription)")
            } else {
                print("✅ Successfully deleted goal \(goal.id)")
            }
        }
    }
    
    func toggleMilestone(goalId: UUID, milestoneId: UUID) {
        guard let goalIndex = goals.firstIndex(where: { $0.id == goalId }),
              let milestoneIndex = goals[goalIndex].milestones.firstIndex(where: { $0.id == milestoneId }) else {
            print("⚠️ toggleMilestone: could not find goal or milestone")
            return
        }
        
        let currentStatus = goals[goalIndex].milestones[milestoneIndex].status
        let nextStatus: MilestoneStatus
        switch currentStatus {
        case .not_started: nextStatus = .in_progress
        case .in_progress: nextStatus = .done
        case .done: nextStatus = .not_started
        }
        
        goals[goalIndex].milestones[milestoneIndex].status = nextStatus
        save()
    }
        
    // Add a new check-in
    func addCheckIn(goalId: UUID, rating: Int, note: String?) {
        guard let goalIndex = goals.firstIndex(where: { $0.id == goalId }) else { return }
        let checkIn = CheckIn(goalId: goalId, rating: rating, note: note)
        goals[goalIndex].checkIns.append(checkIn)
        save()
    }

    // MARK: - Dictionary Conversion
    static func goalToDict(_ goal: Goal) -> [String: Any] {
        [
            "id": goal.id.uuidString,
            "title": goal.title,
            "domain": goal.domain.rawValue,
            "baseline": goal.baseline,
            "target": goal.target,
            "dueDate": goal.dueDate?.timeIntervalSince1970 as Any,
            "milestones": goal.milestones.map { milestoneToDict($0) },
            "checkIns": goal.checkIns.map { checkInToDict($0) },
            "createdAt": goal.createdAt.timeIntervalSince1970,
            "observedProgress": goal.observedProgress
        ]
    }

    static func goalFromDict(_ dict: [String: Any]) -> Goal? {
        guard let idStr = dict["id"] as? String,
              let title = dict["title"] as? String,
              let domainStr = dict["domain"] as? String,
              let domain = Domain(rawValue: domainStr),
              let baseline = dict["baseline"] as? String,
              let target = dict["target"] as? String
        else {
            print("⚠️ goalFromDict: missing required basic fields")
            return nil
        }
        let id = UUID(uuidString: idStr) ?? UUID()

        let milestonesArr = dict["milestones"] as? [[String: Any]] ?? []
        let checkInsArr = dict["checkIns"] as? [[String: Any]] ?? []

        // dueDate
        let dueDate: Date?
        if let ts = dict["dueDate"] as? TimeInterval {
            dueDate = Date(timeIntervalSince1970: ts)
        } else if let tsStr = dict["dueDate"] as? String, let ts = TimeInterval(tsStr) {
            dueDate = Date(timeIntervalSince1970: ts)
        } else {
            dueDate = nil
        }

        // createdAt
        let createdAt: Date
        if let ts = dict["createdAt"] as? TimeInterval {
            createdAt = Date(timeIntervalSince1970: ts)
        } else if let tsStr = dict["createdAt"] as? String, let ts = TimeInterval(tsStr) {
            createdAt = Date(timeIntervalSince1970: ts)
        } else {
            createdAt = Date()
        }

        let observedProgress = dict["observedProgress"] as? Int ?? 0

        return Goal(
            id: id,
            title: title,
            domain: domain,
            baseline: baseline,
            target: target,
            dueDate: dueDate,
            milestones: milestonesArr.compactMap { milestoneFromDict($0) },
            checkIns: checkInsArr.compactMap { checkInFromDict($0) },
            createdAt: createdAt,
            observedProgress: observedProgress
        )
    }
    
    // MARK: - Milestone Dictionary Conversion
    static func milestoneToDict(_ milestone: Milestone) -> [String: Any] {
        [
            "id": milestone.id.uuidString,
            "title": milestone.title,
            "targetDate": milestone.targetDate?.timeIntervalSince1970 as Any,
            "status": milestone.status.rawValue,
            "notes": milestone.notes ?? ""
        ]
    }

    static func milestoneFromDict(_ dict: [String: Any]) -> Milestone? {
        guard let idString = dict["id"] as? String else {
            print("⚠️ milestoneFromDict: missing id in dict: \(dict)")
            return nil
        }

        let id = UUID(uuidString: idString) ?? UUID()

        guard let title = dict["title"] as? String else {
            print("⚠️ milestoneFromDict: missing title in dict: \(dict)")
            return nil
        }

        let notes = dict["notes"] as? String
        let statusStr = dict["status"] as? String ?? "not_started"
        let status = MilestoneStatus(rawValue: statusStr) ?? .not_started

        var targetDate: Date? = nil
        if let ts = dict["targetDate"] as? TimeInterval {
            targetDate = Date(timeIntervalSince1970: ts)
        } else if let tsStr = dict["targetDate"] as? String, let ts = TimeInterval(tsStr) {
            targetDate = Date(timeIntervalSince1970: ts)
        }

        return Milestone(id: id, title: title, targetDate: targetDate, status: status, notes: notes)
    }
    // MARK: - CheckIn Dictionary Conversion
    static func checkInToDict(_ checkIn: CheckIn) -> [String: Any] {
        [
            "id": checkIn.id.uuidString,
            "goalId": checkIn.goalId.uuidString,
            "date": checkIn.date.timeIntervalSince1970,
            "rating": checkIn.rating,
            "note": checkIn.note ?? ""
        ]
    }

    static func checkInFromDict(_ dict: [String: Any]) -> CheckIn? {
        guard let idStr = dict["id"] as? String,
              let id = UUID(uuidString: idStr),
              let goalIdStr = dict["goalId"] as? String,
              let goalId = UUID(uuidString: goalIdStr),
              let dateTs = dict["date"] as? TimeInterval,
              let rating = dict["rating"] as? Int else { return nil }
        let note = dict["note"] as? String
        return CheckIn(id: id, goalId: goalId, date: Date(timeIntervalSince1970: dateTs), rating: rating, note: note)
    }
}
