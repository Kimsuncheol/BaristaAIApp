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
//    @Published var collectionName: [String] = ["Cold", "Hot"]
    @Published var collectionName: [String]
    @Published var isLoading: Bool = false  // 로딩 상태 추가
    @Published var drinkSales: [String: Int] = [:] // Dictionary to store drink_id and its count
    @Published var topSellingDrinks: [String: [Drink]] = [:] // To store top-selling drinks per temperature

    private var db = Firestore.firestore()
    private var timer: Timer?
    
    init() {
        self.collectionName = ["Cold", "Hot"]
        startListeningForSalesData()
        startDailyResetTimer()
        Task {
            await self.fetchDrinks()
        }
    }
    
    func fetchDrinks() async {
        guard !isLoading else { return }  // Prevent multiple calls
        
        DispatchQueue.main.async {
            self.isLoading = true  // Set loading state
        }
        
        do {
//            let snapshot = try await db.collection("menu")
//                .whereField("temperature", in: collectionName)
//                .getDocuments()
            let query = db.collection("menu")
                        .whereField("temperature", in: collectionName)
            
            let snapshot = try await query.getDocuments()
            
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
                
                // Calculate top-selling drinks
                self.calculateTopSeller()   // 이 부분도 유의
            }
        } catch {
            print("Error fetching drinks: \(error.localizedDescription)")
        }
        
        DispatchQueue.main.async {
            self.isLoading = false  // Reset loading state
        }
    }
    
    func startListeningForSalesData() {
        print("startListeningForSalesData")
        db.collection("order_history")
            .whereField("status", isEqualTo: "Completed")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching sales data: \(error.localizedDescription)")
                    return
                }
                
                var salesData: [String: Int] = [:]
                
                print("-------snapshot: \(String(describing: snapshot))")
                
                snapshot?.documentChanges.forEach { change in
                    switch change.type {
                    case .added, .modified:
                        print("-------change: \(change.document.data())")
//                        if let drink_id = change.document.data()["drink_id"] as? String,
//                           let quantity = change.document.data()["quantity"] as? Int {
//                            salesData[drink_id, default: 0] += quantity
//                            print("-------salesData: \(salesData)")
//                        }
                        if let items = change.document.data()["items"] {
//                            let drink_id = items["drink_id"] as! String
                            for item in items as! [[String: Any]] {
                                let drink_id = item["drink_id"] as! String
                                let quantity = item["quantity"] as! Int
                                salesData[drink_id, default: 0] += quantity
                            }
//                            salesData[drink_id, default: 0] += quantity
                            print("-------salesData: \(salesData)")
                            print("-------salesDataCount: \(salesData.count)")
                        }
                    case .removed:
                        break
                    }
                }
                
                DispatchQueue.main.async {
                    self.drinkSales = salesData
                    self.calculateTopSeller()
                }
            }
        
        print("-- self.drinkSales: \(self.drinkSales)")
    }
    
    func calculateTopSeller() {
        var drinksByTemperature: [String: [Drink]] = ["Cold": [], "Hot": []]
        print("---------------------calculateTopSeller")
        
//        for drink in drinks {
//            print("-------------drink: \(drink)")
//            if let drinkId = drink.id, let sales = drinkSales[drinkId] {
//                var updatedDrink = drink
//                updatedDrink.sales = sales
//                print("-------------updatedDrink: \(updatedDrink)")
//                if drink.temperature == "Cold" {
//                    drinksByTemperature["Cold"]?.append(updatedDrink)
//                } else if drink.temperature == "Hot" {
//                    drinksByTemperature["Hot"]?.append(updatedDrink)
//                }
//            }
//        }
        
        for (drinkId, sales) in drinkSales {
            if let drink = drinks.first(where: { $0.id == drinkId }) {
                var updatedDrink = drink
                updatedDrink.sales = sales
                if drink.temperature == "Cold" {
                    drinksByTemperature["Cold"]?.append(updatedDrink)
                } else if drink.temperature == "Hot" {
                    drinksByTemperature["Hot"]?.append(updatedDrink)
                }
            }
        }
        
//        for (temperature, drinks) in drinksByTemperature {
//            print("drinks: \(drinks)")
//            let sortedDrinks = drinks.sorted { $0.sales > $1.sales }
//            self.topSellingDrinks[temperature] = Array(sortedDrinks.prefix(5))
//        }
        
        if collectionName.contains("Cold") && !collectionName.contains("Hot") {
            let sortedColdDrinks = drinksByTemperature["Cold"]?.sorted { $0.sales > $1.sales } ?? []
            self.topSellingDrinks = ["Cold": Array(sortedColdDrinks.prefix(5))]
        } else if !collectionName.contains("Cold") && collectionName.contains("Hot") {
            let sortedHotDrinks = drinksByTemperature["Hot"]?.sorted { $0.sales > $1.sales } ?? []
            self.topSellingDrinks = ["Hot": Array(sortedHotDrinks.prefix(5))]
        } else {
            let allDrinks = (drinksByTemperature["Cold"] ?? []) + (drinksByTemperature["Hot"] ?? [])
            let sortedAllDrinks = allDrinks.sorted { $0.sales > $1.sales }
            self.topSellingDrinks = ["All": Array(sortedAllDrinks.prefix(5))]
        }
        
        print("Top Selling Drinks: \(topSellingDrinks)")
    }
    
    func startDailyResetTimer() {
        let calendar = Calendar.current
        let now = Date()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let startOfDay = calendar.startOfDay(for: tomorrow)
        let timeInterval = startOfDay.timeIntervalSinceNow
        
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { _ in
            self.calculateTopSeller()
            self.startDailyResetTimer()
        }
    }
}
