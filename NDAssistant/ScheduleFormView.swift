//
//  ScheduleFormView.swift
//  NDAssistant
//
//  Created by David Mondrusov on 10/20/25.
//

import SwiftUI

struct ScheduleFormView: View {
    var selectedDate: Date?
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var notes = ""
    @State private var date = Date()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Details")) {
                    TextField("Title", text: $title)
                    TextField("Notes", text: $notes)
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
                
                Button("Save") {
                    // Save to local model or Firebase
                    dismiss()
                }
                .foregroundColor(.blue)
            }
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
