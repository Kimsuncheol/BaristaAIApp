//
//  MenuViewModel.swift
//  BaristaAIApp
//
//  Created by 김선철 on 10/10/24.
//

import SwiftUI
import FirebaseFirestore

class MenuViewModel: ObservableObject {
    @Published var menu: [Drink] = []
    @Published var isLoading: Bool = false  // 로딩 상태 추가
    
    let db = Firestore.firestore()
    
//    init() {
//        // 초기화 시 기본 타입으로 메뉴를 불러올 수 있음
//        fetchMenu("Base") // 예시: "Base" 타입의 음료를 불러옴
//    }
    
    func fetchMenu(_ type: String) {
        guard !isLoading else { return }  // Prevent multiple calls
        
        isLoading = true
        db.collection("menu").whereField("type", isEqualTo: type).getDocuments { [weak self] snapshot, error in
            DispatchQueue.main.async {
                self?.isLoading = false // 로딩 상태 업데이트
                
                if let error = error {
                    print("Error fetching menu: \(error.localizedDescription)")
                    return
                }
                
                // 메뉴 목록 업데이트
                self?.menu = snapshot?.documents.compactMap { document -> Drink? in
                    try? document.data(as: Drink.self)
                } ?? []
            }
        }
    }
}
