//
//  ContentView.swift
//  NDAssistant
//
//  Created by David Mondrusov on 10/4/25.

import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthenticationManager()
    var body: some View {
        Group{
            if authManager.isAuthenticated {
                if authManager.isNewUser {
                    OnboardingFormView()
                        .environmentObject(authManager)
                } else {
                    CustomTabView()
                        .environmentObject(authManager)
                }
            } else {
                LoginView().environmentObject(authManager)
            }
        }
        .onChange(of: authManager.isAuthenticated) { oldValue, newValue in
            print("Auth status changed from \(oldValue) to \(newValue)")
        }
    }
    
}

#Preview {
    ContentView()
}
