//
//  KoreanMorphologicalAnalyzer.swift
//  BaristaAIApp
//
//  Created by 김선철 on 11/19/24.
//

import Foundation
import FirebaseFirestore

struct Morph {
    let token: String
    let pos: String
}

class KoreanMorphologicalAnalyzer: ObservableObject {
    private var db = Firestore.firestore()
    
    // 어휘 사전
    private(set) var lexicon: [String: String] = [:]
    
    // 조사 패턴
    private let particlePatterns: [(String, String)] = [
        ("을", "목적격 조사"),
        ("를", "목적격 조사"),
        ("이", "주격 조사"),
        ("가", "주격 조사"),
        ("은", "보격 조사"),
        ("는", "보격 조사"),
        ("의", "관형격 조사")
    ]
    
    init() {
        fetchMenuCollection()
    }
    
    // Firestore에서 'menu' 컬렉션 데이터를 가져와 어휘 사전을 초기화한다.
    func fetchMenuCollection() {
        db.collection("menu").getDocuments { [weak self] (snapshot, error) in
            guard let self = self else { return }
            if let error = error {
                print("Error fetching menu collection: \(error)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No documents in menu collection")
                return
            }
            
            for document in documents {
                if let name = document.data()["name"] as? String {
                    self.lexicon[name] = "명사"
                }
            }
        }
    }
    
    // 토큰화 (공백 기준)
    func tokenize(_ sentence: String) -> [String] {
//        return text.split(separator: " ").map { String($0) }
        return sentence.components(separatedBy: " ")
    }
    
    // 조사 분리
    func parseParticle(_ token: String) -> [Morph] {
        for (suffix, pos) in particlePatterns {
            if token.hasSuffix(suffix) {
                let stem = String(token.dropLast(suffix.count))
                return [
                    Morph(token: stem, pos: lexicon[stem] ?? "알 수 없음"),
                    Morph(token: suffix, pos: pos)
                ]
            }
        }
        return [Morph(token: token, pos: lexicon[token] ?? "알 수 없음")]
    }
    
    // 형태소 분석
    func analyze(sentence: String) -> [Morph] {
        let tokens = tokenize(sentence)
        var result: [Morph] = []
        
        for token in tokens {
            let parsedMorphs = parseParticle(token)
            result.append(contentsOf: parsedMorphs)
        }
        
        return result
    }
}
