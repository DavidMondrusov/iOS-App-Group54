//
//  ContentView.swift
//  NDAssistant
//
//  Created by David Mondrusov on 10/4/25.

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
            
            MilestoneView()
                .tabItem {
                    Label("Milestones", systemImage: "flag.checkered")
                }
            
            MedicalView()
                .tabItem {
                    Label("Medical", systemImage: "cross.case")
                }
            
            AIView()
                .tabItem {
                    Label("AI", systemImage: "brain.head.profile")
                }
        }
    }
}

#Preview {
    ContentView()
}
