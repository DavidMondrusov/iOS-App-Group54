import SwiftUI
import Combine

// --- Minimal models ---
struct Medication: Identifiable {
    var id = UUID()
    var name: String
    var dose: String?
    var frequency: String?
}

struct InsurancePolicy {
    var provider: String
    var memberID: String
    var planName: String?
}

struct MedicalDocument: Identifiable {
    var id = UUID()
    var title: String
    var type: String?   // "PDF" / "Image" etc.
}

// --- Simple ViewModel with mock data ---
@MainActor
final class MedicalOverviewVM: ObservableObject {
    @Published var query: String = ""
       @Published var meds: [Medication] = []
       @Published var policy: InsurancePolicy? = nil
       @Published var docs: [MedicalDocument] = []

    func loadMock() {
        meds = [
            .init(name: "Atorvastatin", dose: "10 mg", frequency: "QD"),
            .init(name: "Metformin",   dose: "500 mg", frequency: "BID")
        ]
        policy = .init(provider: "Blue Cross", memberID: "G54-12345", planName: "PPO")
        docs = [
            .init(title: "Lab Result 2025-10", type: "PDF"),
            .init(title: "MRI Report",         type: "PDF")
        ]
    }

    var filteredMeds: [Medication] {
        guard !query.isEmpty else { return meds }
        let q = query.lowercased()
        return meds.filter { $0.name.lowercased().contains(q) }
    }

    var filteredDocs: [MedicalDocument] {
        guard !query.isEmpty else { return docs }
        let q = query.lowercased()
        return docs.filter { $0.title.lowercased().contains(q) || ($0.type ?? "").lowercased().contains(q) }
    }
}

// --- The Dashboard view ---
struct MedicalView: View {
    @StateObject private var vm = MedicalOverviewVM()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    // Search
                    TextField("Search medications / documents…", text: $vm.query)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel("Search medical info")

                    // Medications Card
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Medications", systemImage: "pills")
                                .font(.headline)

                            ForEach(vm.filteredMeds) { m in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(m.name).bold()
                                    HStack(spacing: 16) {
                                        if let d = m.dose { Text(d) }
                                        if let f = m.frequency { Text(f) }
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                                Divider().opacity(0.15)
                            }

                            if vm.filteredMeds.isEmpty {
                                Text("No medications").foregroundStyle(.secondary)
                            }
                        }
                    }

                    // Insurance Card
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Insurance", systemImage: "shield.checkerboard")
                                .font(.headline)
                            if let p = vm.policy {
                                Text("\(p.provider) · \(p.memberID)")
                                if let plan = p.planName {
                                    Text("Plan: \(plan)").font(.caption).foregroundStyle(.secondary)
                                }
                            } else {
                                Text("No insurance info").foregroundStyle(.secondary)
                            }
                        }
                    }

                    // Documents Card
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Documents", systemImage: "doc.on.doc")
                                .font(.headline)

                            ForEach(vm.filteredDocs) { d in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(d.title).bold()
                                        if let t = d.type {
                                            Text(t).font(.caption).foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.down.circle") // placeholder
                                }
                                Divider().opacity(0.15)
                            }

                            if vm.filteredDocs.isEmpty {
                                Text("No documents").foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Medical Overview")
            .onAppear { if vm.meds.isEmpty { vm.loadMock() } }
        }
    }
}

#Preview { MedicalView() }

