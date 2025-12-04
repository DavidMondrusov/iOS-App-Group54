import SwiftUI
import Combine
import FirebaseCore
import FirebaseAuth
import FirebaseDatabase   // ⬅️ 用 Realtime Database，不再用 Firestore

// MARK: - Models (不再依赖 Firestore 的 @DocumentID)

struct Medication: Identifiable {
    var id = UUID()
    var name: String
    var dose: String?
    var frequency: String?
    var notes: String?
}

struct InsurancePolicy {
    var provider: String
    var memberID: String
    var planName: String?
    var copay: String?
    var deductible: String?
    var hotline: String?
}

struct MedicalDocument: Identifiable {
    var id = UUID()
    var title: String
    var type: String?       // "PDF" / "Image" etc.
    var date: Date? = nil
    var storagePath: String? = nil
}

// MARK: - ViewModel: 从 Realtime DB 读数据（失败时用 mock）

@MainActor
final class MedicalOverviewVM: ObservableObject {
    @Published var query: String = ""
    @Published var meds: [Medication] = []
    @Published var policy: InsurancePolicy? = nil
    @Published var docs: [MedicalDocument] = []
    @Published var errorMessage: String?

    /// 顶层 Realtime Database 引用
    private var dbRef: DatabaseReference? {
        FirebaseApp.app() != nil ? Database.database().reference() : nil
    }

    /// 对外入口：在 View 的 onAppear 调用
    func load() {
        // 先放一点 mock，保证 UI 不空
        loadMock()

        guard let dbRef = dbRef else {
            errorMessage = "Firebase not configured – showing sample data."
            return
        }
        guard let user = Auth.auth().currentUser else {
            errorMessage = "User not signed in – showing sample data."
            return
        }

        loadFromRealtimeDB(ref: dbRef, uid: user.uid)
    }

    /// 读取 Realtime Database 中 Onboarding 写入的 Child_info
    private func loadFromRealtimeDB(ref: DatabaseReference, uid: String) {
        // 路径和 OnboardingForm submitForm 保持一致：
        // users/<userId>/Child_info/...
        let childInfoRef = ref.child("users").child(uid).child("Child_info")

        childInfoRef.observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? [String: Any] else {
                print("No Child_info found for user \(uid)")
                return        // 没数据就继续用 mock
            }

            let medsString = (value["Medications"] as? String) ?? ""
            let conditions = (value["Conditions"] as? String) ?? ""

            // 假设用户在表单里用逗号 / 分号 / 换行分隔多种药物
            let pieces = medsString
                .split { $0 == "," || $0 == ";" || $0 == "\n" }
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            let meds: [Medication]
            if pieces.isEmpty {
                meds = []     // 如果用户没填 Medications，就留空（UI 会显示 "No medications"）
            } else {
                meds = pieces.map { name in
                    Medication(
                        name: name,
                        notes: conditions.isEmpty ? nil : conditions
                    )
                }
            }

            Task { @MainActor in
                self.meds = meds
                // 保险和文档目前数据库里没有单独 schema，继续使用 mock 里那一份
                self.errorMessage = nil
            }
        }
    }

    // Mock 数据：Firebase 不可用 / 未登录 / 没有 Child_info 时使用
    func loadMock() {
        meds = [
            Medication(name: "Atorvastatin", dose: "10 mg", frequency: "QD"),
            Medication(name: "Metformin",   dose: "500 mg", frequency: "BID")
        ]
        policy = InsurancePolicy(
            provider: "Blue Cross",
            memberID: "G54-12345",
            planName: "PPO",
            copay: "$20",
            deductible: "$500",
            hotline: "800-123-4567"
        )
        docs = [
            MedicalDocument(title: "Lab Result 2025-10", type: "PDF"),
            MedicalDocument(title: "MRI Report",         type: "PDF")
        ]
    }

    // MARK: - 搜索过滤

    var filteredMeds: [Medication] {
        guard !query.isEmpty else { return meds }
        let q = query.lowercased()
        return meds.filter {
            $0.name.lowercased().contains(q)
            || ($0.notes ?? "").lowercased().contains(q)
        }
    }

    var filteredDocs: [MedicalDocument] {
        guard !query.isEmpty else { return docs }
        let q = query.lowercased()
        return docs.filter {
            $0.title.lowercased().contains(q)
            || ($0.type ?? "").lowercased().contains(q)
        }
    }
}

// MARK: - View

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

                                    if let notes = m.notes, !notes.isEmpty {
                                        Text(notes)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Divider().opacity(0.15)
                            }

                            if vm.filteredMeds.isEmpty {
                                Text("No medications").foregroundStyle(.secondary)
                            }
                        }
                    }

                    // Insurance Card（暂时用 mock）
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Insurance", systemImage: "shield.checkerboard")
                                .font(.headline)
                            if let p = vm.policy {
                                Text("\(p.provider) · \(p.memberID)")
                                if let plan = p.planName {
                                    Text("Plan: \(plan)").font(.caption).foregroundStyle(.secondary)
                                }
                                if let copay = p.copay {
                                    Text("Copay: \(copay)").font(.caption).foregroundStyle(.secondary)
                                }
                                if let ded = p.deductible {
                                    Text("Deductible: \(ded)").font(.caption).foregroundStyle(.secondary)
                                }
                            } else {
                                Text("No insurance info").foregroundStyle(.secondary)
                            }
                        }
                    }

                    // Documents Card（暂时用 mock）
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
                                        if let date = d.date {
                                            Text(date.formatted(date: .abbreviated, time: .omitted))
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.down.circle")
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
        }
        .onAppear {
            vm.load()   // ⬅️ 现在：先 mock，再尝试从 Realtime DB 覆盖 meds
        }
    }
}

#Preview {
    MedicalView()
}
