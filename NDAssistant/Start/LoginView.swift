//
//  LoginView.swift
//  NDAssistant
//
//  Created by David Mondrusov on 10/20/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isSignUp = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text(isSignUp ? "Sign Up" : "Login")
                .font(.largeTitle)
                .bold()
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Button(action: authenticate) {
                Text(isSignUp ? "Sign Up" : "Login")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            
            Button(action: { isSignUp.toggle() }) {
                Text(isSignUp ? "Already have an account? Login" : "Don't have an account? Sign Up")
                    .foregroundColor(.blue)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .padding()
    }
    
    func authenticate() {
        Task {
            do {
                if isSignUp {
                    try await authManager.signUp(email: email, password: password)
                    print("Signed up successfully")
                } else {
                    try await authManager.signIn(email: email, password: password)
                    print("Logged in successfully")
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}
