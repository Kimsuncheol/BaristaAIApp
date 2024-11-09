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
    private var lastListener: ListenerRegistration?
    
    init() {
        $query
            .removeDuplicates()
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                self?.fetchDrinks(query: query)
            }
            .store(in: &cancellables)
    }
    
    func fetchDrinks(query: String) {
        lastListener?.remove()
        lastListener = nil
        
        guard !query.isEmpty else {
            self.drinks = []
            return
        }
        
        let drinksRef = db.collection("menu")
        
        let optimizedQuery = drinksRef
            .order(by: "name")
            .start(at: [query])
            .end(at: [query + "\u{f8ff}"])
            .limit(to: 20)  // Limit the results to 20 items
        
        // Listen for real-time updates with a listener
        
        lastListener = optimizedQuery.addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                print("Error fetching drinks: \(error.localizedDescription)")
                self?.drinks = []
                return
            }
            
            guard let documents = snapshot?.documents else {
                self?.drinks = []
                return
            }
            
            // Map the documents to Drink objects
            let fetchedDrinks = documents.compactMap { document in
                try? document.data(as: Drink.self)
            }
            
            // Update the drinks on the main thread
            DispatchQueue.main.async {
                self?.drinks = fetchedDrinks
            }
        }
    }
}
