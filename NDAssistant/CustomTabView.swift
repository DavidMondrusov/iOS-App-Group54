//
//  TabView.swift
//  NDAssistant
//
//  Created by David Mondrusov on 10/20/25.
//

import SwiftUI

enum Tab {
    case calendar
    case milestones
    case medical
    case ai
    case profile
}

let tabBarHeight: CGFloat = 100

struct CustomTabView: View {
    @State private var selectedTab: Tab = .calendar
    @EnvironmentObject var authManager: AuthenticationManager

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content
            Group {
                switch selectedTab {
                case .calendar:
                    CalendarView()
                case .milestones:
                    MilestoneView()
                case .medical:
                    MedicalView()
                case .ai:
                    AIView()
                case .profile:
                    ProfileView()
                }
            }
            .environmentObject(authManager)
            .padding(.bottom, tabBarHeight)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
                
            VStack {
                Spacer()
                ZStack {
                    HStack {
                        TabBarButton(icon: "calendar", tab: .calendar, selectedTab: $selectedTab)
                        TabBarButton(icon: "flag.checkered", tab: .milestones, selectedTab: $selectedTab)

                        Spacer(minLength: 60) // Space for center button

                        TabBarButton(icon: "cross.case", tab: .medical, selectedTab: $selectedTab)
                        TabBarButton(icon: "brain.head.profile", tab: .ai, selectedTab: $selectedTab)
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .padding(.bottom, 5)
                    .background(
                        Color(.systemBackground)
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: -2)
                    )

                    // Center Profile Button (on top of bar)
                    Button(action: {
                        selectedTab = .profile
                    }) {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 70, height: 70)
                            .foregroundColor(.gray)
                            .background(Circle().fill(Color.white))
                            .overlay(Circle().stroke(Color.white, lineWidth: 4))
                            .shadow(radius: 4)
                    }
                    .offset(y: -35)
                }
                .ignoresSafeArea(.all, edges: .bottom)
            }
        }
    }
}

struct TabBarButton: View {
    let icon: String
    let tab: Tab
    @Binding var selectedTab: Tab

    var body: some View {
        Button(action: {
            selectedTab = tab
        }) {
            Image(systemName: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 28, height: 28) // Bigger icon size
                .foregroundColor(selectedTab == tab ? .blue : .gray)
                .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    CustomTabView()
}
