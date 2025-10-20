//
//  OnboardingFormView.swift
//  NDAssistant
//
//  Created by David Mondrusov on 10/20/25.
//
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct OnboardingFormView: View {
    @EnvironmentObject var authManager: AuthenticationManager

    @State private var parentName = ""
    @State private var childName = ""
    @State private var description = ""
    @State private var isSubmitting = false
    @State private var showConfirmation = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Finish Signing Up")
                .font(.title)
                .bold()

            TextField("Parent's Name", text: $parentName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            TextField("Child's Name", text: $childName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)

            TextEditor(text: $description)
                .frame(height: 120)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5)))
                .padding(.horizontal)
                .background(Color(.systemGray6))
                .cornerRadius(8)

            Button(action: submitForm) {
                if isSubmitting {
                    ProgressView()
                } else {
                    Text("Submit")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .disabled(isSubmitting || parentName.isEmpty || childName.isEmpty || description.isEmpty)
            .padding(.horizontal)

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.top)
            }
        }
        .padding()
        .alert("Thank You!", isPresented: $showConfirmation) {
            Button("Continue") {
                authManager.isNewUser = false
            }
        } message: {
            Text("Your profile has been saved.")
        }
    }

    func submitForm() {
        guard let userId = authManager.user?.uid else {
            errorMessage = "User ID not found."
            return
        }

        isSubmitting = true
        let db = Firestore.firestore()
        let userData: [String: Any] = [
            "parentName": parentName,
            "childName": childName,
            "description": description,
            "createdAt": FieldValue.serverTimestamp()
        ]

        db.collection("users").document(userId).setData(userData) { error in
            isSubmitting = false
            if let error = error {
                errorMessage = "Failed to save: \(error.localizedDescription)"
            } else {
                showConfirmation = true
            }
        }
    }
}
