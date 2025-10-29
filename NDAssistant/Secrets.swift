//
//  Secrets.swift
//  NDAssistant
//
//  Created by Brendan Barnes on 10/29/25.
//

import Foundation

// Struct to securely load configuration values from Secrets.plist
struct Secrets {
    
    // 1. Throw a fatal error if the file isn't found (better than a crash later)
    private static var infoDictionary: [String: Any] {
        guard let dict = Bundle.main.infoDictionary else {
            fatalError("Plist file not found.")
        }
        return dict
    }
    
    // 2. Define the key name used in the plist
    private static let apiKeyKey = "Gemini_Key"
    
    // 3. Computed property to retrieve and force-unwrap the API key
    static var geminiAPIKey: String {
        guard let apiKey = infoDictionary[apiKeyKey] as? String else {
            fatalError("Gemini Key not set in Secrets.plist")
        }
        return apiKey
    }
}

