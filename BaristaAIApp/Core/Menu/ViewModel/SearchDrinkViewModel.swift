//
//  SearchDrinkViewModel.swift
//  BaristaAIApp
//
//  Created by 김선철 on 11/2/24.
//

import Combine
import Foundation
import FirebaseFirestore

class SearchDrinkViewModel: ObservableObject {
    @Published var drinks: [Drink] = []
    @Published var query: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    private let db = Firestore.firestore()
    private var allDrinks: [Drink] = [] // Firestore에서 가져온 전체 데이터 저장
    
    init() {
        $query
            .removeDuplicates()
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                self?.searchDrinks(query: query)
            }
            .store(in: &cancellables)
        
        fetchAllDrinks()
    }
    
    func fetchAllDrinks() {
        db.collection("menu").getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("Error fetching drinks: \(error)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            let fetchedDrinks = documents.compactMap { document in
                try? document.data(as: Drink.self)
            }
            
            DispatchQueue.main.async {
                self?.allDrinks = fetchedDrinks
                self?.drinks = fetchedDrinks
            }
        }
    }
    
    // 검색 기능 구현
    func searchDrinks(query: String) {
        guard !query.isEmpty else {
            DispatchQueue.main.async {
                self.drinks = []
            }
            return
        }
        
        // 검색어 토큰화
        let queryTokens = tokenize(query)
        
        // Firestore 데이터와 코사인 유사도 계산
        let sortedDrinks = allDrinks
            .map { drink -> (Drink, Double) in
                let drinkTokens = generateSubstrings(for: drink.name)
                let similarity = calculateCosineSimilarity(queryTokens: queryTokens, drinkTokens: drinkTokens)
                return (drink, similarity)
            }
            .filter { $0.1 > 0.0 } // 유사도가 0 이상인 항목만 필터링
            .sorted { $0.1 > $1.1 } // 유사도 내림차순 정렬
            .map { $0.0 }        // Drink 객체로 변환
        
        DispatchQueue.main.async {
            self.drinks = sortedDrinks
        }
    }
    
    // 코사인 유사도 계산
    private func calculateCosineSimilarity(queryTokens: [String], drinkTokens: [String]) -> Double {
       let allTokens = Array(Set(queryTokens + drinkTokens)) // 전체 고유 토큰 집합 생성
       let queryVector = allTokens.map { queryTokens.contains($0) ? 1.0 : 0.0 }
       let drinkVector = allTokens.map { drinkTokens.contains($0) ? 1.0 : 0.0 }
       
       let dotProduct = zip(queryVector, drinkVector).map(*).reduce(0.0, +)
       let magnitudeQuery = sqrt(queryVector.map { $0 * $0 }.reduce(0.0, +))
       let magnitudeDrink = sqrt(drinkVector.map { $0 * $0 }.reduce(0.0, +))
       
       guard magnitudeQuery > 0 && magnitudeDrink > 0 else { return 0.0 }
       
       return dotProduct / (magnitudeQuery * magnitudeDrink)
    }

    // 문자열에서 모든 부분 문자열 생성
    private func generateSubstrings(for text: String) -> [String] {
       var substrings: [String] = []
       let characters = Array(text)
       
       for i in 0..<characters.count {
           for j in i..<characters.count {
               substrings.append(String(characters[i...j]))
           }
       }
       
       return substrings
    }

    // 검색어를 토큰화
    private func tokenize(_ text: String) -> [String] {
        return [text.lowercased()] // 검색어 자체를 그대로 사용
    }
}
