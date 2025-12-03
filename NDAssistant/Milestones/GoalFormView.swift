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

    // Debug alert
    @State private var debugAlertMessage: String? = nil

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

    // MARK: - Stable Binding for Due Date
    private var hasDueDate: Binding<Bool> {
        Binding<Bool>(
            get: { dueDate != nil },
            set: { newValue in
                if newValue {
                    if dueDate == nil { dueDate = Date() }
                } else {
                    dueDate = nil
                }
            }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                templatesSection
                goalInfoSection
                milestonesSection
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
            .alert("Debug", isPresented: Binding<Bool>(
                get: { debugAlertMessage != nil },
                set: { if !$0 { debugAlertMessage = nil } }
            )) {
                Button("OK", role: .cancel) { debugAlertMessage = nil }
            } message: {
                Text(debugAlertMessage ?? "unknown")
            }
        }
    }

    // MARK: - Sections

    private var templatesSection: some View {
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
                                        if selectedTemplateId == template.id.uuidString {
                                            selectedTemplateId = nil
                                            clearForm()
                                        } else {
                                            selectedTemplateId = template.id.uuidString
                                            applyTemplate(template)
                                        }
                                    }) {
                                        HStack {
                                            Text(template.title).foregroundColor(.primary)
                                            Spacer()
                                            if selectedTemplateId == template.id.uuidString {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.blue)
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
                        .accentColor(.primary)
                        .padding(.vertical, 2)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var goalInfoSection: some View {
        Section(header: Text("Goal Info")) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Title").font(.caption).foregroundColor(.gray)
                TextField("", text: $title).textFieldStyle(.roundedBorder)
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
                TextField("", text: $baseline).textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Target").font(.caption).foregroundColor(.gray)
                TextField("", text: $target).textFieldStyle(.roundedBorder)
            }

            Toggle("Set Due Date", isOn: hasDueDate)

            if dueDate != nil {
                DatePicker("Due Date", selection: $dueDate.unwrapped, displayedComponents: .date)
            }
        }
    }

    private var milestonesSection: some View {
        Section(header: Text("Milestones")) {
            ForEach(milestones) { milestone in
                MilestoneRow(
                    milestone: binding(for: milestone),
                    onDelete: { deleteMilestone(milestone) }
                )
            }

            Button("Add Milestone") {
                let new = Milestone(id: UUID(), title: "", targetDate: nil, status: .not_started, notes: nil)
                print("[Milestones] Adding new milestone id=\(new.id.uuidString), beforeCount=\(milestones.count)")
                milestones.append(new)
                print("[Milestones] afterCount=\(milestones.count)")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Milestone Helpers

    private func binding(for milestone: Milestone) -> Binding<Milestone> {
        guard let index = milestones.firstIndex(where: { $0.id == milestone.id }) else {
            fatalError("Milestone binding not found")
        }
        return $milestones[index]
    }

    private func deleteMilestone(_ milestone: Milestone) {
        guard let index = milestones.firstIndex(where: { $0.id == milestone.id }) else {
            debugAlertMessage = "[BUG] Delete milestone not found"
            return
        }
        withAnimation {
            milestones.remove(at: index)
        }
        print("[Delete] removed milestone id=\(milestone.id.uuidString) newCount=\(milestones.count)")
    }

    // MARK: - Save
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

    // MARK: - Template Helpers
    private func applyTemplate(_ template: Goal) {
        title = template.title
        domain = template.domain
        baseline = template.baseline
        target = template.target
        dueDate = template.dueDate
        milestones = template.milestones
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

// MARK: - MilestoneRow
struct MilestoneRow: View {
    @Binding var milestone: Milestone
    var onDelete: () -> Void

    private var hasTargetDate: Binding<Bool> {
        Binding<Bool>(
            get: { milestone.targetDate != nil },
            set: { hasDate in
                if hasDate {
                    if milestone.targetDate == nil { milestone.targetDate = Date() }
                } else {
                    milestone.targetDate = nil
                }
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                TextField("Milestone Title", text: $milestone.title)
                    .textFieldStyle(.roundedBorder)

                Button(role: .destructive) {
                    print("[MilestoneRow] delete tapped id=\(milestone.id.uuidString)")
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                }
            }

            Toggle("Set Target Date", isOn: hasTargetDate)

            if milestone.targetDate != nil {
                DatePicker("Target Date", selection: $milestone.targetDate.unwrapped, displayedComponents: .date)
                    .datePickerStyle(.compact)
            }
        }
        .padding(.vertical, 4)
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
