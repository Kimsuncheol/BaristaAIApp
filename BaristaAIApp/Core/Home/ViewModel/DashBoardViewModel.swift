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
    @Published var collectionName: [String]
    @Published var isLoading: Bool = false  // 로딩 상태 추가

    private var db = Firestore.firestore()
    private var timer: Timer?
    
    init() {
        self.collectionName = ["Cold", "Hot"]
        fetechTop5DrinksByTemperature()
    }
    
    func fetechTop5DrinksByTemperature() {
        let query = db.collection("menu")
                    .whereField("temperature", in: collectionName)
                    .order(by: "sales", descending: true)
                    .limit(to: 5)
        
        query.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                print("Error listening for real-time updates: \(error.localizedDescription)")
                return
            }

            guard let snapshot = snapshot else { return }

            DispatchQueue.main.async {
                self.drinks = snapshot.documents.compactMap { document in
                    do {
                        var drink = try document.data(as: Drink.self)
                        drink.id = document.documentID
                        return drink
                    } catch {
                        print("Error decoding drink: \(error.localizedDescription)")
                        return nil
                    }
                }
            }
        }
    }
}

