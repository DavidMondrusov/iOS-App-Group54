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
    //@State private var events: [Event] = []

    private var calendar = Calendar.current
    private var range: ClosedRange<Date> {
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .year, value: 1, to: start)!
        return start...end
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                Text("Your Calendar")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)

                CalendarViewRepresentable(
                    calendar: calendar,
                    visibleDateRange: range,
                    monthsLayout: .vertical(options: VerticalMonthsLayoutOptions()),
                    dataDependency: nil,
                )
                .onDaySelection { day in
                                    selectedDate = calendar.date(from: day.components)
                                }
                .days { [selectedDate, /*events*/] day in
                    let date = calendar.date(from: day.components)
                    /*let hasEvent = (date != nil) && events.contains { calendar.isDate($0.start, inSameDayAs: date!) }*/
                    let hasEvent = false
                    let isSelected = (date != nil) && (selectedDate != nil) && calendar.isDate(date!, inSameDayAs: selectedDate!)

                    let borderColor: UIColor = date == selectedDate ? .systemRed : .systemBlue
                    /*if isSelected {
                        borderColor = .systemRed
                    } else if hasEvent {
                        borderColor = .systemBlue
                    } else {
                        borderColor = .clear // or .systemGray4 if you want a faint border for empty days
                    }*/

                    Text("\(day.day)")
                        .font(.system(size: 18))
                        .foregroundColor(Color(UIColor.label))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(4)
                        .background(isSelected ? Color(UIColor.systemRed).opacity(0.12) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color(borderColor), lineWidth: borderColor == .clear ? 0 : 1)
                        )
                }
                .verticalDayMargin(8)
                .horizontalDayMargin(8)
                .padding(.horizontal)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .shadow(radius: 4)
            }
            .padding()
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showScheduler = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showScheduler) {
                ScheduleFormView(selectedDate: selectedDate)
            }
        }
    }
}

struct DayEventsView: View {
    var date: Date

    var body: some View {
        VStack(spacing: 12) {
            Text("Events on \(formatted(date))")
                .font(.title3)
                .bold()

            // Replace with your actual event lookup
            Text("No events found.")
                .foregroundColor(.gray)

            Spacer()
        }
        .padding()
    }

    private func formatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
}

#Preview {
    CalendarView()
}
