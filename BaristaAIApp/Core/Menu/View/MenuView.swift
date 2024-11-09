//
//  MenuView.swift
//  BaristaAIApp
//
//  Created by 김선철 on 9/26/24.
//

import SwiftUI

struct MenuView: View {
    let user: User?
    @State var NavigateToLogin: Bool = false
    @State var typeList: [[String: Any]] = [
        ["title": "Base", "tap": true],
        ["title": "Frappuccino", "tap": false],
        ["title": "Drink", "tap": false],
        ["title": "Tea", "tap": false],
        ["title": "Latte", "tap": false],
        ["title": "Refresher", "tap": false],
        ["title": "Macchiato", "tap": false],
        ["title": "Hot Chocolate", "tap": false],
        ["title": "Smoothie", "tap": false]
    ]
    @StateObject private var viewModel = MenuViewModel() // Initialize view model here
    @StateObject var myFavoriteViewModel = MyFavoriteViewModel()
    
    @State private var isSelectedTopicIndex: Int = 0
    
    var body: some View {
        VStack {
            NavigationLink(destination: SearchDrinkView(user: user)) {
                MockSearchBar()
            }
            .padding()
            
            ScrollView(.horizontal, showsIndicators: false) {
                Header(typeList: $typeList, isTopicSelectedIndex: $isSelectedTopicIndex)
            }
            .padding()
            
            Spacer()
            
            // Assuming MenuSubView is already implemented to accept a topic type
            MenuSubView(user: user, type: typeList[isSelectedTopicIndex]["title"] as! String, isTopicSelectedIndex: isSelectedTopicIndex, NavigateToLogin: $NavigateToLogin, viewModel: viewModel, myFavoriteViewModel: myFavoriteViewModel)
            
        }
        .padding(.vertical, 1)
        .fullScreenCover(isPresented: $NavigateToLogin) {
            LoginView()
        }
        .onChange(of: isSelectedTopicIndex) {
            viewModel.fetchMenu( typeList[isSelectedTopicIndex]["title"] as! String)
            myFavoriteViewModel.fetchFavorites(customerEmail: user?.email ?? "")
        }
    }
}

#Preview {
    ContentView()
}

struct Header: View {
    @Binding var typeList: [[String: Any]]
    @Binding var isTopicSelectedIndex: Int
    
    var body: some View {
        HStack(spacing: 20) {
            ForEach(0..<typeList.count, id: \.self) { index in
                Button {
                    // Update the selected index
                    isTopicSelectedIndex = index
                    
                    // Reset all tap states to false and set the selected one to true
                    for i in 0..<typeList.count {
                        typeList[i]["tap"] = (i == index) // Set the tap state for selected
                    }
                } label: {
                    Text(typeList[index]["title"] as? String ?? "")
                        .font(.system(size: 20).bold())
                        .foregroundColor(typeList[index]["tap"] as? Bool == true ? .blue : .primary) // Highlight selected topic
                        .padding()
                }
            }
        }
    }
}
