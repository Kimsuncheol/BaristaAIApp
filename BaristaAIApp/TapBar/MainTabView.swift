//
//  MainTabView.swift
//  BaristaAI
//
//  Created by 김선철 on 9/15/24.
//

import SwiftUI

struct MainTabView: View {
    let user: User?
    @State private var selectedIndex = 0
    @StateObject var registrationViewModel = RegistrationViewModel()
    @State private var showLogin = false
    
    var body: some View {
        NavigationStack {
            
            TabView(selection: $selectedIndex) {
                DashBoardView(user: user)
                    .tabItem { Image(systemName: "house") }
                    .tag(0)
                
                MyFavoriteView(user: user)
                    .tabItem { Image(systemName: "heart") }
                    .tag(1)
                
                TalkView(user: user)
                    .tabItem { Image(systemName: "message") }
                    .tag(2)
                
                MenuView(user: user)
                    .tabItem { Image(systemName: "book") }
                    .tag(3)
                
                ProfileView(user: user)
                    .tabItem { Image(systemName: "person") }
                    .tag(4)
            }
            .onChange(of: selectedIndex) {
                if user == nil {
                    if selectedIndex == 1 || selectedIndex == 2 || selectedIndex == 4 {
                        showLogin = true
                    } else {
                        showLogin = false
                    }
                }
            }
            .fullScreenCover(isPresented: $showLogin) {
                LoginView()
            }
            .gesture(
                DragGesture()
                    .onEnded { value in
                        withAnimation(.easeInOut) { // Apply animation to the swipe
                            // Right to left swipe
                            if value.translation.width < -50 {
                                selectedIndex = min(selectedIndex + 1, 4)
                            }
                            // Left to right swipe
                            if value.translation.width > 50 {
                                selectedIndex = max(selectedIndex - 1, 0)
                            }
                        }
                    }
            )
            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    NavigationLink(destination: DrinkUpload()) {
//                        Text("Add/Delete")
//                    }
//                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if user == nil {
                        Button {
                            showLogin = true
                        } label: {
                            Image(systemName: "person.slash")
                                .resizable()
                                .frame(width: 24, height: 24)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: CartView(user: user)) {
                        Image(systemName: "cart")
                            .resizable()
                            .frame(width: 24, height: 24)
                    }
                }
                
                // 로그인한 경우 주문 상황까지도
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: NotificationView(user: user)) {
                        // "bell.badge"
                        Image(systemName: "bell")
                            .resizable()
                            .frame(width: 24, height: 24)
                    }
                }
            }
        }
        
    }
}

#Preview {
    ContentView()
        .environmentObject(PaymentHistoryViewModel())
}
