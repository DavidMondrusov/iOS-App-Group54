//
//  Authentication.swift
//  NDAssistant
//
//  Created by David Mondrusov on 10/20/25.
//

import Foundation
import FirebaseCore
import FirebaseAuth
import Combine

enum AuthError: LocalizedError {
    case firebaseNotConfigured
    var errorDescription: String? {
        switch self {
        case .firebaseNotConfigured:
            return "Firebase not configured (missing GoogleService-Info.plist)."
        }
    }
}

final class AuthenticationManager: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var isNewUser = false

    /// 只有在 Firebase 已经 configure 成功时才会返回 Auth，避免崩溃
    private var auth: Auth? {
        FirebaseApp.app() != nil ? Auth.auth() : nil
    }

    init() {
        // ⚠️ 不能直接调用 Auth.auth() — 在未配置时会崩
        if let auth = auth {
            self.user = auth.currentUser
            self.isAuthenticated = (auth.currentUser != nil)
        } else {
            // UI-only 模式：允许界面加载，但没有登录能力
            self.user = nil
            self.isAuthenticated = false
            print("⚠️ Firebase not configured – running in UI-only mode.")
        }
    }

    // MARK: - API

    func signUp(email: String, password: String) async throws {
        guard let auth = auth else { throw AuthError.firebaseNotConfigured }
        let result = try await auth.createUser(withEmail: email, password: password)
        await MainActor.run {
            self.user = result.user
            self.isAuthenticated = true
            self.isNewUser = true
        }
    }

    func signIn(email: String, password: String) async throws {
        guard let auth = auth else { throw AuthError.firebaseNotConfigured }
        let result = try await auth.signIn(withEmail: email, password: password)
        await MainActor.run {
            self.user = result.user
            self.isAuthenticated = true
        }
    }

    func signOut() throws {
        guard let auth = auth else { throw AuthError.firebaseNotConfigured }
        try auth.signOut()
        self.user = nil
        self.isAuthenticated = false
    }
}

