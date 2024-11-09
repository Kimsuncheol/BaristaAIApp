//
//  AuthService.swift
//  BaristaAI
//
//  Created by 김선철 on 9/15/24.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Firebase

class AuthService: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: User?
    
    static let shared = AuthService()
    
    init() {
        Task {
            try await loadUserData()
        }
    }
    
    @MainActor
    func login(withEmail email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            print("DEBUG: Successfully logged in as user \(result.user.uid)")
            self.userSession = result.user
            try await loadUserData()
            //
        } catch {
            print("DEBUG: Failed to log in user with error \(error.localizedDescription)")
            throw error
        }
    }
    
    @MainActor
    func createUser(email: String, password: String, username: String, nickname: String, useNickname: Bool) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.userSession = result.user
            await self.uploadUserData(uid: result.user.uid, email: email, username: username, nickname: nickname, useNickname: useNickname)
        } catch {
            print("DEBUG: -- Failed to register user with error \(error.localizedDescription)")
            throw error
        }
    }
    
    @MainActor
    func loadUserData() async throws {
        self.userSession = Auth.auth().currentUser
//        print("DEBUG: userSession: \(String(describing: self.userSession))")

        guard let currentUid = userSession?.uid else { return }
        self.currentUser = try await UserService.fetchUser(withUid: currentUid)
//        print("DEBUG: currentUser: \(String(describing: self.currentUser))")
    }
    
    func signout() {
        try? Auth.auth().signOut()
        self.userSession = nil
        self.currentUser = nil
    }
    
    private func uploadUserData(uid: String, email: String, username: String, nickname: String, useNickname: Bool) async {
        let user = User(id: uid, username: username, email: email, nickname: nickname, useNickname: useNickname)
        self.currentUser = user
        guard let encodeUser = try? Firestore.Encoder().encode(user) else { return }
        try? await Firestore.firestore().collection("customer").document(user.id).setData(encodeUser)
    }
    
}
