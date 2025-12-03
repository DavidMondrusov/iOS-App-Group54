//
//  ProgressRingView.swift
//  NDAssistant
//
//  Created by David Mondrusov on 11/17/25.
//
import SwiftUI

struct ProgressRingView: View {
    var percent: Int // 0...100
    var size: CGFloat = 88
    var line: CGFloat = 8
    var label: String? = nil

    var backgroundColor: Color = Color.gray.opacity(0.15)
    var foregroundColor: Color = .blue

    var clamped: Double { Double(min(100, max(0, percent))) / 100.0 }

    var body: some View {
        ZStack {
            Circle()
                .stroke(backgroundColor, lineWidth: line)

            Circle()
                .trim(from: 0, to: clamped)
                .stroke(foregroundColor, style: StrokeStyle(lineWidth: line, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: clamped)

            Text("\(Int(clamped * 100))%")
                .font(.system(size: size * 0.24, weight: .semibold))
                .monospacedDigit()
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(label ?? "Progress"))
        .accessibilityValue(Text("\(Int(clamped * 100)) percent"))
    }
}
