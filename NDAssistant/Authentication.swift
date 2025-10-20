//
//  Authentication.swift
//  NDAssistant
//
//  Created by David Mondrusov on 10/20/25.
//
import Foundation
import FirebaseAuth
import Combine

class AuthenticationManager: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var isNewUser: Bool = false
    
    init() {
        // Check if user is already logged in
        self.user = Auth.auth().currentUser
        self.isAuthenticated = user != nil
    }
    
    // Sign up with email
    func signUp(email: String, password: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        DispatchQueue.main.async {
            self.user = result.user
            self.isAuthenticated = true
            self.isNewUser = true
        }
    }
    
    // Sign in with email
    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        self.user = result.user
        self.isAuthenticated = true
    }
    
    // Sign out
    func signOut() throws {
        try Auth.auth().signOut()
        self.user = nil
        self.isAuthenticated = false
    }
}
