import SwiftUI

struct CheckInFormView: View {
    var onAddCheckIn: (String) -> Void
    @State private var note: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick check-in").font(.headline)

            TextField("Notes", text: $note, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...3)

            HStack {
                Spacer()
                Button("Log check-in") {
                    onAddCheckIn(note)
                    note = ""
                }
                .buttonStyle(.borderedProminent)
                .disabled(note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2)))
    }
}
