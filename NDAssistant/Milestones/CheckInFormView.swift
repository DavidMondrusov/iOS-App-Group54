import SwiftUI

struct CheckInFormView: View {
    var onAddCheckIn: (Int, String?) -> Void
    @State private var rating: Int = 5
    @State private var note: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick check-in").font(.headline)

            HStack {
                Text("Rating")
                Spacer()
                Picker("Rating", selection: $rating) {
                    ForEach(1...5, id: \.self) { n in
                        Text("\(n)").tag(n)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 260)
            }

            TextField("Notes (optional)", text: $note, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...3)

            HStack {
                Spacer()
                Button("Log check-in") {
                    onAddCheckIn(rating, note.isEmpty ? nil : note)
                    note = ""
                    rating = 5
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2)))
    }
}
