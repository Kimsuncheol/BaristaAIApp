//
//  UserService.swift
//  InstagramTutorial
//
//  Created by 김선철 on 8/28/24.
//

import Foundation
import FirebaseFirestore

struct UserService {
    
    static func fetchUser(withUid uid: String) async throws -> User {
        let snapshot = try await Firestore.firestore().collection("customer").document(uid).getDocument()
        return try snapshot.data(as: User.self)
    }
    
    static func fetchAllUsers() async throws -> [User] {
        let snapshot = try await Firestore.firestore().collection("customer").getDocuments()
        return snapshot.documents.compactMap({ try? $0.data(as: User.self) })
    }
}
