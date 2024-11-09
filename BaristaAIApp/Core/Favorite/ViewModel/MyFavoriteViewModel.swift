//
//  MyFavoriteViewModel.swift
//  BaristaAIApp
//
//  Created by 김선철 on 10/9/24.
//
import SwiftUI
import FirebaseFirestore

class MyFavoriteViewModel: ObservableObject {
    @Published var favorites: [MyFavorite] = [] // 즐겨찾기 항목 저장
    @Published var isLoading: Bool = false  // 로딩 상태
    
    private let db = Firestore.firestore()
    private let collectionName = "my_favorites"
    
    // Firestore에서 사용자 이메일과 일치하는 즐겨찾기 목록 가져오기
    func fetchFavorites(customerEmail: String?) {
        isLoading = true
        db.collection(collectionName)
            .whereField("customerEmail", isEqualTo: customerEmail ?? "") // 이메일 필터 추가
            .getDocuments { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                
                if let error = error {
                    print("Error fetching favorites: \(error.localizedDescription)")
                    return
                }
                
                // Firestore에서 가져온 데이터를 변환
                self.favorites = querySnapshot?.documents.compactMap { document in
                    try? document.data(as: MyFavorite.self)
                } ?? []
            }
    }
    
    // 즐겨찾기 추가
    // 일단은 다시 MyFavorite가 아닌 Drink로 대체했음
    func addFavorite(drink: Drink, customerEmail: String?) {
//        guard let userEmail = userEmail else { return } // 사용자 이메일이 없으면 리턴
        // 바깥에서 newMyFavoriteItem 선언하고 이 함수에 대입한 결과..
        // 추가하려는 음료의 데이터 id(drink_id가 아님)가 오류의 원인
        // 중복 확인 (사용자 이메일과 음료 ID로 중복 확인)
        
        // drinkID에 myfavorite.drink_id 대입했었음
        checkForDuplicate(drinkID: drink.id!, customerEmail: customerEmail!) { [weak self] exists in
            guard let self = self else { return }
            if exists {
                print("\(drink.name) is already in favorites. Removing from favorites.")
                
                // 시뮬레이터 껐다 키면 이 코드가 작동 안됨
                // 즉 favorites에 있는 데이터 다 날라간다는 의미
                print("from MyFavoriteViewModel: favorite - \(self.favorites)")
                if let favoriteToRemove = self.favorites.first(where: { $0.drink_id == drink.id && $0.customerEmail == customerEmail }) {
                    self.removeFavorite(id: favoriteToRemove.id, customerEmail: customerEmail!)
                }
                return
            }
            
            let newFavoriteItem = MyFavorite(
                id: UUID().uuidString,
                drink_id: drink.id!,
                customerEmail: customerEmail!, // 현재 사용자의 이메일로 설정
                name: drink.name,
                image: drink.image,
                flavor_profile: drink.flavor_profile,
                type: drink.type,
                temperature: drink.temperature,
                is_lactose_free: drink.is_lactose_free,
                description: drink.description,
                price: drink.price,
                is_favorite: true
            )
            
            // Firestore에 즐겨찾기 추가
            do {
                try self.db.collection(self.collectionName).document(newFavoriteItem.id).setData(from: newFavoriteItem) { error in
                    if let error = error {
                        print("Error adding favorite: \(error.localizedDescription)")
                        return
                    }
                    DispatchQueue.main.async {
                        self.favorites.append(newFavoriteItem)
                    }
                }
                
            } catch {
                print("Error adding favorite: \(error.localizedDescription)")
            }
        }
    }
    
    // Firestore에서 중복 확인 (사용자 이메일과 음료 ID로 확인)
    private func checkForDuplicate(drinkID: String, customerEmail: String, completion: @escaping (Bool) -> Void) {
        db.collection(collectionName)
            .whereField("customerEmail", isEqualTo: customerEmail) // 사용자 이메일로 필터링
            .whereField("drink_id", isEqualTo: drinkID)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    print("Error checking for duplicate: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                // 문서가 존재하면 중복으로 간주
                if let documents = querySnapshot?.documents, !documents.isEmpty {
                    completion(true)
                } else {
                    completion(false)
                }
            }
    }
    
    // 즐겨찾기에서 제거
    func removeFavorite(id: String, customerEmail: String) {
        let favoriteItemId = id
        
        // Firestore에서 즐겨찾기 제거
        db.collection(collectionName).document(favoriteItemId).delete { [weak self] error in
            if let error = error {
                print("Error removing favorite: \(error.localizedDescription)")
                return
            }
            DispatchQueue.main.async {
                self?.favorites.removeAll { $0.id == favoriteItemId && $0.customerEmail == customerEmail }
            }
        }
    }
    
    // 즐겨찾기 전체 삭제 (배치 처리 사용)
    func clearFavorites(customerEmail: String?) {
//        guard let customerEmail = customerEmail else { return } // 사용자 이메일이 없으면 리턴
        
        db.collection(collectionName)
            .whereField("customerEmail", isEqualTo: customerEmail ?? "") // 사용자 이메일로 필터링
            .getDocuments { [weak self] querySnapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error clearing favorites: \(error.localizedDescription)")
                    return
                }
                
                let batch = self.db.batch()
                querySnapshot?.documents.forEach { document in
                    batch.deleteDocument(document.reference)
                }
                
                // 배치 처리로 모든 즐겨찾기 항목 삭제
                batch.commit { [weak self] error in
                    if let error = error {
                        print("Error committing batch delete: \(error.localizedDescription)")
                        return
                    }
                    DispatchQueue.main.async {
                        self?.favorites.removeAll()
                    }
                }
            }
    }
}
