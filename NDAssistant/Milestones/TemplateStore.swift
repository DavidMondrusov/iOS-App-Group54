import Foundation
import FirebaseDatabase
import Combine

@MainActor
final class TemplateStore: ObservableObject {
    @Published var templates: [String: Goal] = [:] // key = Goal.id.uuidString

    private var ref: DatabaseReference {
        Database.database().reference().child("examples/goals")
    }

    init() {
        print("TemplateStore loaded")
        loadTemplates()
    }

    func loadTemplates() {
        ref.observe(.value) { snapshot in
            guard let value = snapshot.value as? [String: Any] else {
                self.templates = [:]
                print("⚠️ loadTemplates(): No templates or wrong format")
                return
            }

            var loadedTemplates: [String: Goal] = [:]

            for (key, data) in value {
                if let dict = data as? [String: Any],
                   let goal = ProgressStore.goalFromDict(dict) {
                    loadedTemplates[key] = goal
                    print(goal)
                } else {
                    print("⚠️ Failed to parse goal for key: \(key)")
                }
            }

            self.templates = loadedTemplates
            print("✅ Loaded \(self.templates.count) templates")
        }
    }

    func getTemplate(by id: String) -> Goal? {
        templates[id]
    }
}
