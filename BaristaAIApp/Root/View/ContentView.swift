//
//  ContentView.swift
//  BaristaAI
//
//  Created by 김선철 on 9/15/24.
//

import SwiftUI
import UserNotifications
import Firebase

struct ContentView: View {
    @StateObject var viewModel = ContentViewModel()
    @StateObject var registrationViewModel = RegistrationViewModel()
    @StateObject var paymentHistoryViewModel = PaymentHistoryViewModel()

    var currentUser: User? {
        viewModel.currentUser
    }
    
    var body: some View {
        Group {
            MainTabView(user: currentUser ?? nil)
                .environmentObject(registrationViewModel)
                .environmentObject(viewModel)
                .onAppear {
                    requestNotificationPermission() // 알림 권한 요청
                }
        }
        .preferredColorScheme(.light)
    }
    
    func requestNotificationPermission() {
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

#Preview {
    ContentView()
}
