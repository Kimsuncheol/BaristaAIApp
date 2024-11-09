//
//  BaristaAIAppApp.swift
//  BaristaAIApp
//
//  Created by 김선철 on 9/26/24.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        // 알림 센터 위임 설정
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    // 앱이 포그라운드 상태일 때 알림 표시 메서드
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound]) // 배너와 소리로 알림 표시
    }
    
    // 구글의 인증프로세스가 끝날 때 앱이 수신하는 URL을 처리하는 역할
    func application(_ application: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

@main
struct BaristaAIAppApp: App {
    // register app delegate for Firebase setup
     @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var paymentHistoryViewModel = PaymentHistoryViewModel()
    @StateObject private var authViewModel = RegistrationViewModel()

    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
                    .environmentObject(paymentHistoryViewModel)
                    .environmentObject(authViewModel)
                    .preferredColorScheme(.light)
            }
        }
    }
}
