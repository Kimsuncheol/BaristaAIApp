//
//  DashBoardViewModel.swift
//  BaristaAIApp
//
//  Created by 김선철 on 10/10/24.
//

import SwiftUI
import FirebaseFirestore

class DashBoardViewModel: ObservableObject {
    @Published var drinks: [Drink] = []
    @Published var isLoading: Bool = false  // 로딩 상태 추가

    private var db = Firestore.firestore()
    
    init() {
        fetchDrinks()
    }
    
    func fetchDrinks() {
        guard !isLoading else { return }  // Prevent multiple calls
        
        isLoading = true
        db.collection("menu").getDocuments { [weak self] snapshot, error in
            DispatchQueue.main.async {
                self?.isLoading = false  // Set loading state to false
                
                // Check for errors
                if let error = error {
                    print("Error fetching drinks: \(error.localizedDescription)")
                    return
                }
                
                // Ensure you handle the snapshot safely
                guard let documents = snapshot?.documents else {
                    print("No documents found.")
                    return
                }
                
                // Safely unwrap and decode documents
                self?.drinks = documents.compactMap { document in            
                    do {
                        // Create a drink instance and set id from document ID
                        var drink = try document.data(as: Drink.self)
                        drink.id = document.documentID  // Set the ID
                        return drink
                    } catch {
                        print("Error decoding drink: \(error)")
                        return nil
                    }
                }

            }
        }
    }
}
