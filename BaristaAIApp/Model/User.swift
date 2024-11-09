//
//  User.swift
//  InstagramTutorial
//
//  Created by 김선철 on 8/27/24.
//

import Foundation
import FirebaseAuth

struct User: Identifiable, Hashable, Codable {
    let id: String
    var username: String
    let email: String
    var nickname: String
    var useNickname: Bool
    
    var isCurrentUser: Bool {
        guard let currentUid = Auth.auth().currentUser?.uid else { return false }
        return currentUid == id
    }
}
