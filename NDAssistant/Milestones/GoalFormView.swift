import SwiftUI

struct GoalFormView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var store: ProgressStore
    @ObservedObject var templateStore: TemplateStore
    let onSave: (UUID) -> Void
    var goalToEdit: Goal? = nil

    @State private var title: String = ""
    @State private var domain: Domain = .Other
    @State private var baseline: String = ""
    @State private var target: String = ""
    @State private var dueDate: Date? = nil
    @State private var milestones: [Milestone] = []

    @State private var selectedTemplateId: String? = nil

    init(store: ProgressStore, templateStore: TemplateStore, goalToEdit: Goal? = nil, onSave: @escaping (UUID) -> Void) {
        self.store = store
        self.templateStore = templateStore
        self.goalToEdit = goalToEdit
        self.onSave = onSave

        _title = State(initialValue: goalToEdit?.title ?? "")
        _domain = State(initialValue: goalToEdit?.domain ?? .Other)
        _baseline = State(initialValue: goalToEdit?.baseline ?? "")
        _target = State(initialValue: goalToEdit?.target ?? "")
        _dueDate = State(initialValue: goalToEdit?.dueDate)
        _milestones = State(initialValue: goalToEdit?.milestones ?? [])
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Templates / Examples Picker
                Section(header: Text("Templates / Examples")) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Domain.allCases, id: \.self) { domain in
                            let domainTemplates = templateStore.templates.values
                                .filter { $0.domain == domain }
                                .sorted { $0.title < $1.title }

                            if !domainTemplates.isEmpty {
                                DisclosureGroup(domain.rawValue) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        ForEach(domainTemplates, id: \.id) { template in
                                            Button(action: {
                                                // Toggle selection
                                                if selectedTemplateId == template.id.uuidString {
                                                    selectedTemplateId = nil
                                                    clearForm()
                                                } else {
                                                    selectedTemplateId = template.id.uuidString
                                                    applyTemplate(template)
                                                }
                                            }) {
                                                HStack {
                                                    Text(template.title)
                                                        .foregroundColor(.primary)
                                                    Spacer()
                                                    if selectedTemplateId == template.id.uuidString {
                                                        Image(systemName: "checkmark")
                                                            .foregroundColor(.blue)
                                                            .transition(.opacity) // animate only the checkmark
                                                    }
                                                }
                                                .padding(.vertical, 6)
                                                .padding(.horizontal, 8)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 6)
                                                        .fill(selectedTemplateId == template.id.uuidString ? Color.blue.opacity(0.2) : Color.clear)
                                                )
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                                .accentColor(.primary) // keeps disclosure arrow dark
                                .padding(.vertical, 2)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }

                // MARK: - Goal Info
                Section(header: Text("Goal Info")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Title").font(.caption).foregroundColor(.gray)
                        TextField("", text: $title)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Domain").font(.caption).foregroundColor(.gray)
                        Picker("Domain", selection: $domain) {
                            ForEach(Domain.allCases) { d in
                                Text(d.rawValue).tag(d)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Baseline").font(.caption).foregroundColor(.gray)
                        TextField("", text: $baseline)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Target").font(.caption).foregroundColor(.gray)
                        TextField("", text: $target)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    Toggle("Set Due Date", isOn: Binding(
                        get: { dueDate != nil },
                        set: { dueDate = $0 ? (dueDate ?? Date()) : nil }
                    ))
                    if dueDate != nil {
                        DatePicker(
                            "Due Date",
                            selection: $dueDate.unwrapped,
                            displayedComponents: .date
                        )
                    }
                }

                // MARK: - Milestones
                MilestonesSection(milestones: $milestones)
            }
            .navigationTitle(goalToEdit == nil ? "New Goal" : "Edit Goal")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveGoal() }
                        .disabled(title.isEmpty || baseline.isEmpty || target.isEmpty)
                }
            }
        }
    }
    
    struct MilestonesSection: View {
        @Binding var milestones: [Milestone]

        var body: some View {
            Section(header: Text("Milestones")) {
                ForEach($milestones, id: \.id) { $milestone in
                    MilestoneRow(milestone: $milestone) {
                        deleteMilestone(id: milestone.id)
                    }
                }

                Button("Add Milestone") {
                    let new = Milestone(id: UUID(), title: "", targetDate: nil, status: .not_started, notes: nil)
                    milestones.append(new)
                }
                .buttonStyle(.borderedProminent)
            }
        }

        private func deleteMilestone(id: UUID) {
            DispatchQueue.main.async {
                if let idx = milestones.firstIndex(where: { $0.id == id }) {
                    milestones.remove(at: idx)
                }
            }
        }
    }

    struct MilestoneRow: View {
        @Binding var milestone: Milestone
        var onDelete: () -> Void

        var body: some View {
            VStack(alignment: .leading) {
                HStack {
                    TextField("Milestone Title", text: $milestone.title)
                        .textFieldStyle(.roundedBorder)
                    Spacer()
                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash")
                    }
                }

                Toggle("Set Target Date", isOn: Binding(
                    get: { milestone.targetDate != nil },
                    set: { milestone.targetDate = $0 ? (milestone.targetDate ?? Date()) : nil }
                ))

                if milestone.targetDate != nil {
                    DatePicker(
                        "Target Date",
                        selection: $milestone.targetDate.unwrapped,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Helpers
    private func saveGoal() {
        let goal = Goal(
            id: goalToEdit?.id ?? UUID(),
            title: title,
            domain: domain,
            baseline: baseline,
            target: target,
            dueDate: dueDate,
            milestones: milestones,
            checkIns: goalToEdit?.checkIns ?? [],
            createdAt: goalToEdit?.createdAt ?? Date(),
            observedProgress: goalToEdit?.observedProgress ?? 0
        )

        if goalToEdit != nil {
            store.updateGoal(goal)
        } else {
            store.addGoal(goal)
        }

        onSave(goal.id)
        dismiss()
    }

    private func applyTemplate(_ template: Goal) {
        title = template.title
        domain = template.domain
        baseline = template.baseline
        target = template.target
        dueDate = template.dueDate

        DispatchQueue.main.async {
            self.milestones = template.milestones.map {
                Milestone(id: $0.id, title: $0.title, targetDate: $0.targetDate, status: $0.status, notes: $0.notes)
            }
        }
    }

    private func clearForm() {
        title = ""
        domain = .Other
        baseline = ""
        target = ""
        dueDate = nil
        milestones = []
    }
}

// MARK: - Optional Date Binding
extension Binding where Value == Date? {
    var unwrapped: Binding<Date> {
        Binding<Date>(
            get: { self.wrappedValue ?? Date() },
            set: { self.wrappedValue = $0 }
        )
    }
}
