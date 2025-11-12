import SwiftUI

struct FiltersView: View {
    let children: [Child]
    @Binding var selectedChildId: UUID?
    @Binding var selectedDomain: Domain?

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading) {
                Text("Child").font(.caption).foregroundStyle(.secondary)
                Picker("Child", selection: Binding(
                    get: { selectedChildId ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000") },
                    set: { new in
                        if let zero = UUID(uuidString: "00000000-0000-0000-0000-000000000000"), new == zero {
                            selectedChildId = nil
                        } else {
                            selectedChildId = new
                        }
                    })) {
                    Text("All").tag(UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
                    ForEach(children) { c in
                        Text(c.name).tag(c.id)
                    }
                }
                .pickerStyle(.menu)
            }

            VStack(alignment: .leading) {
                Text("Domain").font(.caption).foregroundStyle(.secondary)
                Picker("Domain", selection: Binding(
                    get: { selectedDomain ?? .Other },
                    set: { new in
                        selectedDomain = new == .Other ? nil : new
                    })) {
                    Text("All").tag(Domain.Other)
                    ForEach(Domain.allCases, id: \.self) { d in
                        Text(d.rawValue).tag(d)
                    }
                }
                .pickerStyle(.menu)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
