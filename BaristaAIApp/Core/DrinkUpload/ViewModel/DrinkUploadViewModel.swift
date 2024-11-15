//
//  DrinkUploadViewModel.swift
//  BaristaAIApp
//
//  Created by 김선철 on 10/10/24.
//

import SwiftUI
import FirebaseFirestore

class DrinkUploadViewModel: ObservableObject {
    @Published var drinkItems: [Drink] = []
    
    let db = Firestore.firestore()
        
    init() {
        self.drinkItems = Drink.MOCK_Menu
    }
    
    func uploadDrink() {
        let group = DispatchGroup() // DispatchGroup을 사용하여 비동기 작업 관리
        let batch = db.batch()
        
        for drink in drinkItems {
            group.enter() // 비동기 작업 시작
            
            // 중복성 검사: Firestore에서 이미 존재하는 음료인지 확인
            db.collection("menu").document(drink.id).getDocument { (document, error) in
                if let error = error {
                    print("Error checking document: \(error.localizedDescription)")
                    group.leave() // 작업 완료
                    return
                }
                
                if let document = document, document.exists {
                    print("Drink \(drink.name) already exists. Skipping upload.")
                } else {
                    let docRef = self.db.collection("menu").document(drink.id)
                    batch.setData(drink.dictionary, forDocument: docRef)
                    print("Adding drink: \(drink.name)")
                }
                group.leave() // 작업 완료
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            // 모든 작업이 완료된 후 배치 커밋
            batch.commit { error in
                if let error = error {
                    print("Error committing batch: \(error.localizedDescription)")
                } else {
                    print("Batch write succeeded. Uploaded \(self?.drinkItems.count ?? 0) drinks.")
                }
            }
        }
    }
    
    // Update an existing drink in Firestore
    func updateDrink(_ drink: Drink) {
        do {
            try db.collection("menu").document(drink.id).setData(from: drink) { error in
                if let error = error {
                    print("Error updating drink: \(error.localizedDescription)")
                } else {
                    print("Drink updated successfully.")
                }
            }
        } catch {
            print("Error encoding drink: \(error.localizedDescription)")
        }
    }
    
    // Delete a drink from Firestore
    func deleteDrink(_ drink: Drink) {
        db.collection("menu").document(drink.id).delete { error in
            if let error = error {
                print("Error deleting drink: \(error.localizedDescription)")
            } else {
                print("Drink deleted successfully.")
                self.drinkItems.removeAll { $0.id == drink.id } // Remove from local array
            }
        }
    }
    
    // Delete all drinks from Firestore
    func deleteAllDrinks() {
        db.collection("drink").getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching drinks for deletion: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No drinks found to delete.")
                return
            }
            
            let batch = self.db.batch()
            for document in documents {
                batch.deleteDocument(document.reference)
            }
            
            batch.commit { error in
                if let error = error {
                    print("Error committing batch delete: \(error.localizedDescription)")
                } else {
                    print("All drinks deleted successfully.")
                    self.drinkItems.removeAll() // Clear local array
                }
            }
        }
    }
}
