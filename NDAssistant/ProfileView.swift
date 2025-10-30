//
//  ProfileView.swift
//  NDAssistant
//
//  Created by David Mondrusov on 10/20/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    @State private var parentName: String = ""
    @State private var email: String = ""
    @State private var childName: String = ""
    @State private var city: String = ""
    @State private var isLoading = true
    @State private var errorMessage: String?

    private let ref = Database.database().reference()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Profile")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            if isLoading {
                ProgressView("Loading profile...")
            } else if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Parent Name: \(parentName)")
                    Text("Email: \(email)")
                    Text("Child Name: \(childName)")
                    Text("City: \(city)")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            Spacer()
            
            Button(action: {
                do {
                    try authManager.signOut()
                    print("Successfully signed out")
                } catch let signOutError as NSError {
                    print("Error signing out: %@", signOutError)
                }
            }) {
                Text("Log Out")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(10)
            }
            .padding()
        }
        .padding()
        .onAppear {
            fetchUserData()
        }
    }
    
    private func fetchUserData() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "No logged in user"
            isLoading = false
            return
        }

        let userRef = ref.child("users").child(userId)
        
        userRef.observeSingleEvent(of: .value) { snapshot in
            isLoading = false
            guard let value = snapshot.value as? [String: Any] else {
                errorMessage = "User data not found."
                return
            }
            
            if let user = value["User"] as? [String: Any] {
                parentName = user["parent_name"] as? String ?? "N/A"
            }
            
            if let childInfo = value["Child_info"] as? [String: Any] {
                childName = childInfo["Name"] as? String ?? "N/A"
            }
            
            if let location = value["Location"] as? [String: Any] {
                city = location["City"] as? String ?? "N/A"
            }
            
            email = Auth.auth().currentUser?.email ?? "N/A"
        }
    }
}
