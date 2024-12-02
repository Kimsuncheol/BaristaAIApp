//
//  SplashView.swift
//  BaristaAIApp
//
//  Created by 김선철 on 11/24/24.
//

import SwiftUI
import Combine
import UserNotifications

struct SplashView: View {
    @EnvironmentObject private var splashViewModel: SplashViewModel
    @EnvironmentObject private var dashBoardViewModel: DashBoardViewModel
    @EnvironmentObject private var myFavoriteViewModel: MyFavoriteViewModel
    @EnvironmentObject private var menuViewModel: MenuViewModel
    @StateObject var registrationViewModel = RegistrationViewModel()
    @StateObject var paymentHistoryViewModel = PaymentHistoryViewModel()
    @StateObject var viewModel = ContentViewModel()

    var currentUser: User? {
        viewModel.currentUser
    }

//    @State private var navigateToMainTab: Bool = false

    var body: some View {
        Group {
            if !splashViewModel.navigateToMainTab {
                VStack {
                    Image("AIBaristaSplashImage")
                        .resizable()
                        .scaledToFit()
                        .frame(width: .logoImageSideLength, height: .logoImageSideLength)
                    ProgressView("Loading data...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(red: 62 / 255, green: 46 / 255, blue: 34 / 255))
                .onAppear {
//                    setupFetchAndNavigation()
//                    requestNotificationPermission() // 알림 권한 요청
                    splashViewModel.initializeData()
                }
            } else {
                MainTabView(user: currentUser ?? nil) // MainTabView로 전환
                    .environmentObject(registrationViewModel)
                    .environmentObject(paymentHistoryViewModel)
                    .environmentObject(dashBoardViewModel)
                    .environmentObject(myFavoriteViewModel)
                    .environmentObject(menuViewModel)
                    .environmentObject(viewModel)
                    .onAppear {
                        requestNotificationPermission() // 알림 권한 요청
                    }
            }
        }
        .animation(.easeInOut(duration: 2), value: splashViewModel.navigateToMainTab)
    }
    
    private func initializeApp() {
//        setupFetchAndNavigation()
        requestNotificationPermission()
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            } else if granted {
                print("Notification permission granted.")
            } else {
                print("Notification permission denied.")
            }
        }
    }
}
