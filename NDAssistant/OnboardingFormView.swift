//
//  OnboardingFormView.swift
//  NDAssistant
//
//  Created by David Mondrusov on 10/20/25.
//
import SwiftUI
import FirebaseAuth
import FirebaseDatabase

struct OnboardingFormView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    // User Info
    @State private var parentName = ""
    @State private var password = ""
    
    // Child Info
    @State private var childName = ""
    @State private var medications = ""
    @State private var conditions = ""
    @State private var age = ""
    @State private var siblings = ""
    @State private var parentalStatus = ""
    @State private var schooling = "Public"
    
    // Family Info
    @State private var income = ""
    @State private var maritalStatus = ""
    @State private var livingSituation = ""
    @State private var householdSize = ""
    @State private var occupation = ""
    
    // Location
    @State private var locationName = ""
    @State private var state = ""
    @State private var city = ""
    @State private var zipCode = ""
    
    @State private var isSubmitting = false
    @State private var showConfirmation = false
    @State private var errorMessage = ""
    @State private var currentSection = 0
    
    let schoolingOptions = ["Public", "Private", "Homeschool", "Charter", "Online"]
    let sections = ["Basic Info", "Child Details", "Family Info", "Location"]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Finish Signing Up")
                .font(.title)
                .bold()
            
            // Progress indicator
            HStack {
                ForEach(0..<sections.count, id: \.self) { index in
                    Circle()
                        .fill(index <= currentSection ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 10, height: 10)
                }
            }
            .padding(.bottom, 10)
            
            Text(sections[currentSection])
                .font(.headline)
            
            ScrollView {
                VStack(spacing: 15) {
                    switch currentSection {
                    case 0:
                        basicInfoSection
                    case 1:
                        childInfoSection
                    case 2:
                        familyInfoSection
                    case 3:
                        locationSection
                    default:
                        EmptyView()
                    }
                }
                .padding(.horizontal)
            }
            
            // Navigation buttons
            HStack {
                if currentSection > 0 {
                    Button("Previous") {
                        currentSection -= 1
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.3))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    if currentSection < sections.count - 1 {
                        currentSection += 1
                    } else {
                        submitForm()
                    }
                }) {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Text(currentSection < sections.count - 1 ? "Next" : "Submit")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canProceed() ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .disabled(!canProceed() || isSubmitting)
            }
            .padding(.horizontal)
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
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
    
    var basicInfoSection: some View {
        VStack(spacing: 15) {
            TextField("Parent's Name *", text: $parentName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
    
    var childInfoSection: some View {
        VStack(spacing: 15) {
            TextField("Child's Name *", text: $childName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Age", text: $age)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Medications", text: $medications)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextEditor(text: $conditions)
                .frame(height: 80)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.5)))
                .background(Color(.systemGray6))
                .cornerRadius(8)
            Text("Conditions/Notes")
                .font(.caption)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            TextField("Number of Siblings", text: $siblings)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Parental Status", text: $parentalStatus)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Picker("Schooling", selection: $schooling) {
                ForEach(schoolingOptions, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    var familyInfoSection: some View {
        VStack(spacing: 15) {
            TextField("Household Income", text: $income)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Marital Status", text: $maritalStatus)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Living Situation", text: $livingSituation)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Household Size", text: $householdSize)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Occupation", text: $occupation)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
    
    var locationSection: some View {
        VStack(spacing: 15) {
            TextField("Location Name", text: $locationName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("City", text: $city)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("State", text: $state)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Zip Code", text: $zipCode)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
    
    func canProceed() -> Bool {
        switch currentSection {
        case 0:
            return !parentName.isEmpty
        case 1:
            return !childName.isEmpty
        case 2, 3:
            return true
        default:
            return false
        }
    }
    
    func submitForm() {
        guard let userId = authManager.user?.uid else {
            errorMessage = "User ID not found."
            return
        }
        
        isSubmitting = true
        let ref = Database.database().reference()
        
        // Helper function to convert optional strings to Any
        func stringToAny(_ value: String) -> Any {
            return value.isEmpty ? NSNull() : value
        }
        
        // Helper function to convert optional ints to Any
        func intToAny(_ value: String) -> Any {
            if let intValue = Int(value) {
                return intValue
            }
            return NSNull()
        }
        
        // Prepare user data structure matching Supabase schema
        let userData: [String: Any] = [
            "User": [
                "created_at": ServerValue.timestamp(),
                "parent_name": parentName
            ],
            "Child_info": [
                "Medications": stringToAny(medications),
                "Conditions": stringToAny(conditions),
                "Age": intToAny(age),
                "Siblings": intToAny(siblings),
                "Parental_status": stringToAny(parentalStatus),
                "Schooling": schooling
            ],
            "Family_info": [
                "Income": intToAny(income),
                "Martial_status": stringToAny(maritalStatus),
                "Living_situation": stringToAny(livingSituation),
                "Household_size": intToAny(householdSize),
                "Occupation": stringToAny(occupation)
            ],
            "Location": [
                "Location_name": stringToAny(locationName),
                "State": stringToAny(state),
                "City": stringToAny(city),
                "Zip_code": intToAny(zipCode)
            ]
        ]
        
        ref.child("users").child(userId).setValue(userData) { error, _ in
            isSubmitting = false
            if let error = error {
                errorMessage = "Failed to save: \(error.localizedDescription)"
            } else {
                showConfirmation = true
            }
        }
    }
}
