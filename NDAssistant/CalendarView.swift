//
//  File.swift
//  NDAssistant
//
//  Created by David Mondrusov on 10/4/25.
//

import SwiftUI
import HorizonCalendar

struct CalendarView: View {
    @State private var selectedDate: Date? = nil
    @State private var showScheduler = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Your Calendar")
                .font(.title2)
                .bold()
                .foregroundColor(.white)
                .padding(.top)

            CalendarViewRepresentable(
                calendar: Calendar.current,
                visibleDateRange: Date()...Date().addingTimeInterval(60*60*24*365),
                monthsLayout: .vertical(options: VerticalMonthsLayoutOptions()),
                dataDependency: nil
            )
            .padding(.horizontal)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .shadow(radius: 4)

            Button(action: {
                showScheduler = true
            }) {
                Text("Schedule Something")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .sheet(isPresented: $showScheduler) {
            ScheduleFormView(selectedDate: selectedDate)
        }
    }
}

#Preview {
    CalendarView()
}
