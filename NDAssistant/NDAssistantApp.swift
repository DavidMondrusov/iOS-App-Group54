//
//  NDAssistantApp.swift
//  NDAssistant
//
//  Created by David Mondrusov on 10/4/25.
//

import SwiftUI
import FirebaseCore

@main
struct NDAssistantApp: App {
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
