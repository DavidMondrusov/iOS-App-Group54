//
//  AI.swift
//  NDAssistant
//
//  Created by David Mondrusov on 10/4/25.
//

import SwiftUI
import OpenAI

struct AIView: View {
    @State private var userMessage = ""
    @State private var messages: [ChatMessage] = []
    @State private var isLoading = false
    
    //Weird OpenAI toolkit configuration for Gemini but it works
    let configuration = OpenAI.Configuration(
            token: Secrets.geminiAPIKey,
            host: "generativelanguage.googleapis.com",
            basePath: "/v1beta/openai/"
        )
        let openAI: OpenAI
    
    init() {
            self.openAI = OpenAI(configuration: configuration)
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
    }
    
    
    func sendMessage() {
        guard !userMessage.isEmpty else { return }
        
        let userMsg = ChatMessage(role: "user", content: userMessage)
        messages.append(userMsg)
        
        userMessage = ""
        isLoading = true
        
        Task {
            do {
                let query = ChatQuery(
                    messages: messages.compactMap {
                        ChatQuery.ChatCompletionMessageParam(
                            role: $0.role == "user" ? .user : .assistant,
                            content: $0.content
                        )
                    },
                    model: .init("gemini-2.5-flash") //using this Gemini model because it's free!
                        //could use Gemini 2.0/2.5 Flash-(Lite) for more requests per minute but the current 10 seems fine
                )
                
                let result = try await openAI.chats(query: query)
                
                if let response = result.choices.first?.message.content {
                    let aiMsg = ChatMessage(role: "assistant", content: response)
                    await MainActor.run {
                        messages.append(aiMsg)
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    let errorMsg = ChatMessage(role: "assistant", content: "Error: \(error.localizedDescription)")
                    messages.append(errorMsg)
                    isLoading = false
                }
            }
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: String  // user or assistant
    let content: String
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


