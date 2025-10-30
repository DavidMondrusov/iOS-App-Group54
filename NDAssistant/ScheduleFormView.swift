//
//  ScheduleFormView.swift
//  NDAssistant
//
//  Created by David Mondrusov on 10/20/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct ScheduleFormView: View {
    @Binding var selectedDate: Date?
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var notes = ""
    @State private var date = Date()
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    
    init(selectedDate: Binding<Date?>) {
        self._selectedDate = selectedDate
        self._date = State(initialValue: selectedDate.wrappedValue ?? Date())
    }
    
    private var ref = Database.database().reference()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Details")) {
                    TextField("Title", text: $title)
                    TextField("Notes", text: $notes)
                    DatePicker(
                        "Date",
                        selection: $date,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
            }
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSubmitting ? "Saving..." : "Save") {
                        saveEvent()
                    }
                    .disabled(isSubmitting)
                }
            }
        }
    }
    private func saveEvent() {
           guard let userId = Auth.auth().currentUser?.uid else {
               errorMessage = "You must be logged in to save an event."
               return
           }
           
           isSubmitting = true
           errorMessage = nil
           
           // Create the event data structure
           let eventData: [String: Any] = [
               "title": title,
               "notes": notes,
               "date": date.timeIntervalSince1970,
               "created_at": ServerValue.timestamp()
           ]
           
           ref.child("users")
               .child(userId)
               .child("events")
               .childByAutoId()
               .setValue(eventData) { error, _ in
                   isSubmitting = false
                   
                   if let error = error {
                       errorMessage = "Failed to save: \(error.localizedDescription)"
                       print("Firebase Error:", error)
                   } else {
                       print("Event saved successfully")
                       selectedDate = date
                       dismiss()
                   }
               }
       }
}
