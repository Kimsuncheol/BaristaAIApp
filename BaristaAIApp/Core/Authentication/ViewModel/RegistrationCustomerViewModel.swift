//
//  RegistrationViewModel.swift
//  BaristaAI
//
//  Created by 김선철 on 9/16/24.
//

import SwiftUI
import Foundation
import FirebaseFirestore

class RegistrationViewModel: ObservableObject {
    @Published var username = ""
    @Published var email = ""
    @Published var password = ""
    @Published var nickname = ""
    @Published var useNickname: Bool = false

    private let db = Firestore.firestore()
    private var emailCheckCache = [String: Bool]()
    private var usernameCheckCache = [String: Bool]()
    private var nicknameCheckCache = [String: Bool]()

    // 중복 이메일 체크 함수
    func isEmailDuplicate(email: String) async -> Bool {
        if let cachedResult = emailCheckCache[email] {
            return cachedResult
        }
        return await performDuplicateCheck(for: "email", value: email, cache: &emailCheckCache)
    }
    
    // 중복 닉네임 체크 함수
    func isNicknameDuplicate(nickname: String) async -> Bool {
        if let cachedResult = nicknameCheckCache[nickname] {
            return cachedResult
        }
        return await performDuplicateCheck(for: "nickname", value: nickname, cache: &nicknameCheckCache)
    }
    
    // 공통 중복 체크 메서드 (캐시 지원)
    private func performDuplicateCheck(for field: String, value: String, cache: inout [String: Bool]) async -> Bool {
        do {
            let snapshot = try await db.collection("customer")
                .whereField(field, isEqualTo: value)
                .getDocuments()
            let isDuplicate = !snapshot.documents.isEmpty
            cache[value] = isDuplicate  // 캐싱
            return isDuplicate
        } catch {
            print("DEBUG: Failed to check \(field) duplication: \(error.localizedDescription)")
            return false
        }
    }
    
    // 사용자 생성 함수 (중복 체크 후 트랜잭션 실행)
    func createUser() async throws {
        // 중복성 체크
        let isEmailDuplicate = await isEmailDuplicate(email: email)
        let isNicknameDuplicate = await isNicknameDuplicate(nickname: nickname)

        guard !isEmailDuplicate, !isNicknameDuplicate else {
            print("DEBUG: Duplicate values found. Cannot create user.")
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Duplicate fields detected"])
        }
        
        // Firestore 트랜잭션을 사용하지 않고 단순한 데이터 추가로 사용자 생성
        try await AuthService.shared.createUser(
            email: self.email,
            password: self.password,
            username: self.username,
            nickname: self.nickname,
            useNickname: self.useNickname
        )
        
        DispatchQueue.main.async {
            self.email = ""
            self.password = ""
            self.username = ""
            self.nickname = ""
            self.useNickname = false
        }
    }
}
