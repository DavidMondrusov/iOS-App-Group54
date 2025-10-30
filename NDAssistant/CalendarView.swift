//
//  File.swift
//  NDAssistant
//
//  Created by David Mondrusov on 10/4/25.
//

import SwiftUI
import HorizonCalendar
import FirebaseAuth
import FirebaseDatabase

struct Event: Identifiable, Hashable {
    let id: String
    let title: String
    let notes: String
    let date: Date
}

struct CalendarView: View {
    @State private var selectedDate: Date? = nil
    @State private var showScheduler = false
    @State private var firebaseEvents: [Event] = []

    private var calendar = Calendar.current
    private var range: ClosedRange<Date> {
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .year, value: 1, to: start)!
        return start...end
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                Text("Calendar")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)

                CalendarViewRepresentable(
                    calendar: calendar,
                    visibleDateRange: range,
                    monthsLayout: .vertical(options: VerticalMonthsLayoutOptions()),
                    dataDependency: firebaseEvents // reloads when events change
                )
                .onDaySelection { day in
                    selectedDate = calendar.date(from: day.components)
                }
                .days { [selectedDate, firebaseEvents] day in
                    let date = calendar.date(from: day.components)
                    let hasEvent = date != nil && firebaseEvents.contains { calendar.isDate($0.date, inSameDayAs: date!) }
                    let isSelected = date != nil && selectedDate != nil && calendar.isDate(date!, inSameDayAs: selectedDate!)

                    let borderColor: UIColor = isSelected && hasEvent ? .systemPurple :
                                                isSelected ? .systemRed :
                                                hasEvent ? .systemBlue :
                                                .clear

                    Text("\(day.day)")
                        .font(.system(size: 18))
                        .foregroundColor(Color(UIColor.label))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(4)
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

                VStack(alignment: .leading, spacing: 8) {
                    if let selected = selectedDate {
                        Text("Events on \(formatted(selected))")
                            .font(.headline)
                            .foregroundColor(.black)
                        let eventsForSelectedDate = firebaseEvents.filter { calendar.isDate($0.date, inSameDayAs: selected) }
                        if eventsForSelectedDate.isEmpty {
                            Text("No events")
                                .foregroundColor(.gray)
                        } else {
                            ForEach(eventsForSelectedDate) { event in
                                VStack(alignment: .leading) {
                                    Text(event.title)
                                        .bold()
                                    if !event.notes.isEmpty {
                                        Text(event.notes)
                                            .foregroundColor(.gray)
                                            .font(.subheadline)
                                    }
                                }
                                .padding(4)
                                .background(Color(.systemGray5))
                                .cornerRadius(8)
                            }
                        }
                    } else {
                        Text("Select a day to see events")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                Spacer()
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
                ScheduleFormView(selectedDate: $selectedDate)
            }
            .task {
                loadEvents()
            }
        }
    }
    
    private func formatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
    
    private func loadEvents() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let ref = Database.database().reference()
        ref.child("users").child(userId).child("events")
            .observe(.value) { snapshot in
                var events: [Event] = []

                for child in snapshot.children {
                    if let snap = child as? DataSnapshot,
                       let data = snap.value as? [String: Any],
                       let timestamp = data["date"] as? TimeInterval,
                       let title = data["title"] as? String {
                        let notes = data["notes"] as? String ?? ""
                        let event = Event(id: snap.key, title: title, notes: notes, date: Date(timeIntervalSince1970: timestamp))
                        events.append(event)
                    }
                }

                firebaseEvents = events
            }
    }
}

#Preview {
    CalendarView()
}
