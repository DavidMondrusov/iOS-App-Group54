import SwiftUI

struct ProgressBarView: View {
    var percent: Int // 0...100
    var height: CGFloat = 8
    var label: String? = nil
    var foregroundColor: Color = .blue
    var backgroundColor: Color = .gray.opacity(0.3)

    var clamped: Double { Double(min(100, max(0, percent))) / 100.0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let label {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(backgroundColor)
                        .frame(height: height)

                    Capsule()
                        .fill(foregroundColor)
                        .frame(width: geo.size.width * CGFloat(clamped), height: height)
                        .animation(.easeInOut(duration: 0.3), value: clamped)
                }
            }
            .frame(height: height) // Fix GeometryReader height

            Text("\(Int(clamped * 100))%")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(label ?? "Progress"))
        .accessibilityValue(Text("\(Int(clamped * 100)) percent"))
        .padding(.vertical, 4)
    }
}
