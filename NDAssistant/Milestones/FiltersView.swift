import SwiftUI

struct FiltersView: View {
    @Binding var selectedDomain: Domain?

    var body: some View {
        HStack(spacing: 16) {

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
