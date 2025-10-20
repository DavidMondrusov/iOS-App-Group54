//
//  ProfileView.swift
//  NDAssistant
//
//  Created by David Mondrusov on 10/20/25.
//

import SwiftUI
import FirebaseAuth



struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        VStack {
            Text("Profile")
                .navigationTitle("Profile")
            Button(action: {
                do {
                    try authManager.signOut()
                    print("Succesfully signed out")
                    
                } catch let signOutError as NSError {
                    print("Error signing out: %@", signOutError)
                }
            }) {
                Text("Log Out")
                    .foregroundColor(.red)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
    }
}

#Preview {
    ProfileView()
}
