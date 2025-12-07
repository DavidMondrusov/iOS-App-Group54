//
//  AI.swift
//  NDAssistant
//
//  Created by David Mondrusov on 10/4/25.
//

import SwiftUI
import OpenAI
import FirebaseAuth
import FirebaseDatabase

struct AIView: View {
    @State private var userMessage = ""
    @State private var messages: [ChatMessage] = []
    @State private var isLoading = false
    @State private var userContext = ""
    
    //let geminiBaseURL = URL(string: "https://generativelanguage.googleapis.com/v1beta/openai/")!
    
    //let openAI = OpenAI(apiToken: "AIzaSyC2ywV_yVmA51Yuyku7jIgRxnA36shBOLo", baseURL: geminiBaseURL)
    
    //Weird OpenAI toolkit configuration for Gemini but it works
    let configuration = OpenAI.Configuration(
        token: "AIzaSyCPUU_vuFa5mjPNpUT3G8010bka0xeKFoE",
        host: "generativelanguage.googleapis.com",
        basePath: "/v1beta/openai/"
    )
    let openAI: OpenAI
    
    init() {
        self.openAI = OpenAI(configuration: configuration)
        // Load cached messages on init
        _messages = State(initialValue: ChatMessage.loadMessages())
    }
    
    
    var body: some View {
        
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                        }
                        
                        if isLoading {
                            HStack {
                                ProgressView()
                                Text("Thinking...")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { oldValue, newValue in
                    if let lastMessage = messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
       
        
        Spacer()
            
            HStack {
                // Clear button
                Button(action: {
                    messages = []
                    ChatMessage.clearMessages()
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .padding(.leading)
                
                TextField("Ask Any Question Here!", text: $userMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(isLoading)
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(userMessage.isEmpty ? .gray : .blue)
                }
                .disabled(userMessage.isEmpty || isLoading)
                .padding(.trailing)
            }
        }
        .padding()
        .navigationTitle("AI")
        .onAppear {
            loadUserContext()
        }
    }
    
    func loadUserContext() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let ref = Database.database().reference().child("users").child(userId)
        ref.observeSingleEvent(of: .value) { snapshot in
            guard let userData = snapshot.value as? [String: Any] else { return }
            
            // Build context string from user data
            var context = "User Information:\n"
            
            if let user = userData["User"] as? [String: Any],
               let parentName = user["parent_name"] as? String {
                context += "Parent Name: \(parentName)\n"
            }
            
            if let childInfo = userData["Child_info"] as? [String: Any] {
                if let name = childInfo["Name"] as? String {
                    context += "Child's Name: \(name)\n"
                }
                if let age = childInfo["Age"] as? Int {
                    context += "Child's Age: \(age)\n"
                }
                if let medications = childInfo["Medications"] as? String, !medications.isEmpty {
                    context += "Medications: \(medications)\n"
                }
                if let conditions = childInfo["Conditions"] as? String, !conditions.isEmpty {
                    context += "Conditions: \(conditions)\n"
                }
                if let siblings = childInfo["Siblings"] as? Int {
                    context += "Number of Siblings: \(siblings)\n"
                }
                if let schooling = childInfo["Schooling"] as? String {
                    context += "Schooling: \(schooling)\n"
                }
            }
            
            if let familyInfo = userData["Family_info"] as? [String: Any] {
                if let maritalStatus = familyInfo["Marital_status"] as? String, !maritalStatus.isEmpty {
                    context += "Marital Status: \(maritalStatus)\n"
                }
                if let livingSituation = familyInfo["Living_situation"] as? String, !livingSituation.isEmpty {
                    context += "Living Situation: \(livingSituation)\n"
                }
                if let householdSize = familyInfo["Household_size"] as? Int {
                    context += "Household Size: \(householdSize)\n"
                }
            }
            
            if let location = userData["Location"] as? [String: Any] {
                if let city = location["City"] as? String, !city.isEmpty {
                    context += "City: \(city)\n"
                }
                if let state = location["State"] as? String, !state.isEmpty {
                    context += "State: \(state)\n"
                }
            }
            
            userContext = context
        }
    }
    
    
    func sendMessage() {
        guard !userMessage.isEmpty else { return }
        
        // Store the original message for display
        let displayMessage = userMessage
        
        // Create the modified message with instruction prefix and user context for the API
        var modifiedMessage = ""
        if !userContext.isEmpty {
            modifiedMessage = "\(userContext)\n\nGive a brief response to the query: \(userMessage)"
        } else {
            modifiedMessage = "Give a brief response to the query: \(userMessage)"
        }
        
        // Show original message in UI
        let userMsg = ChatMessage(role: "user", content: displayMessage)
        messages.append(userMsg)
        ChatMessage.saveMessages(messages)
        
        userMessage = ""
        isLoading = true
        
        Task {
            do {
                // Create query with all previous messages plus the modified current message
                var apiMessages: [ChatQuery.ChatCompletionMessageParam] = messages.dropLast().compactMap {
                    ChatQuery.ChatCompletionMessageParam(
                        role: $0.role == "user" ? .user : .assistant,
                        content: $0.content
                    )
                }
                
                // Add the current message with the instruction prefix and context
                if let modifiedParam = ChatQuery.ChatCompletionMessageParam(
                    role: .user,
                    content: modifiedMessage
                ) {
                    apiMessages.append(modifiedParam)
                }
                
                let query = ChatQuery(
                    messages: apiMessages,
                    model: .init("gemini-2.5-flash") //using this Gemini model because it's free!
                        //could use Gemini 2.0/2.5 Flash-(Lite) for more requests per minute but the current 10 seems fine
                )
                
                let result = try await openAI.chats(query: query)
                
                if let response = result.choices.first?.message.content {
                    let aiMsg = ChatMessage(role: "assistant", content: response)
                    await MainActor.run {
                        messages.append(aiMsg)
                        ChatMessage.saveMessages(messages)
                        isLoading = false
                    }
                }
            } catch {
                print("Full error details: \(error)")
                await MainActor.run {
                    let errorMsg = ChatMessage(role: "assistant", content: "Error: \(error.localizedDescription)")
                    messages.append(errorMsg)
                    isLoading = false
                }
            }
        }
    }
}

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let role: String  // user or assistant
    let content: String
    
    init(role: String, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
    }
    
    // Save messages to UserDefaults
    static func saveMessages(_ messages: [ChatMessage]) {
        if let encoded = try? JSONEncoder().encode(messages) {
            UserDefaults.standard.set(encoded, forKey: "chatMessages")
        }
    }
    
    // Load messages from UserDefaults
    static func loadMessages() -> [ChatMessage] {
        if let data = UserDefaults.standard.data(forKey: "chatMessages"),
           let decoded = try? JSONDecoder().decode([ChatMessage].self, from: data) {
            return decoded
        }
        return []
    }
    
    // Clear all messages
    static func clearMessages() {
        UserDefaults.standard.removeObject(forKey: "chatMessages")
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.role == "user" {
                Spacer()
            }
            
            Text(message.content)
                .padding(12)
                .background(message.role == "user" ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(message.role == "user" ? .white : .primary)
                .cornerRadius(16)
            
            if message.role == "assistant" {
                Spacer()
            }
        }
        .id(message.id)
    }
}


    
    #Preview {
        AIView()
    }
