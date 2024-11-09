//
//  NotificationsViewModel.swift
//  BaristaAIApp
//
//  Created by 김선철 on 10/9/24.
//

import FirebaseAuth
import FirebaseFirestore
import SwiftUI

class NotificationViewModel: ObservableObject {
    @Published var notifications: [NotificationModel] = []
    
    let db = Firestore.firestore()
    
    // 알림 데이터 로드
    func loadNotifications(customerEmail: String?) {
//        print("notificationViewModel customerEmail: \(Auth.auth().currentUser?.email ?? "no user")")
//        
//        guard let currentUser = Auth.auth().currentUser else {
//            // 사용자가 로그인하지 않은 경우 "roll-out" 타입의 알림만 가져오기
//            fetchNotifications(type: "roll-out") { [weak self] notifications in
//                DispatchQueue.main.async {
//                    // 시간 내림차순 정렬
//                    self?.notifications = notifications.sorted { $0.time > $1.time }
//                }
//            }
//            return
//        }
        guard let customerEmail = customerEmail else {
            fetchNotifications(type: "roll-out") { [weak self] notifications in
                DispatchQueue.main.async {
                    // 시간 내림차순 정렬
                    self?.notifications = notifications.sorted { $0.time > $1.time }
                }
            }
            return
        }
        
        // 사용자가 로그인한 경우 해당 사용자의 알림만 가져오기
//        fetchNotifications(customerEmail: currentUser.email) { [weak self] notifications in
//            DispatchQueue.main.async {
//                // 시간 내림차순 정렬
//                self?.notifications = notifications.sorted { $0.time > $1.time }
//            }
//        }
        fetchNotifications(customerEmail: customerEmail) { [weak self] notifications in
            DispatchQueue.main.async {
                // 시간 내림차순 정렬
                self?.notifications = notifications.sorted { $0.time > $1.time }
            }
        }
    }
    
    // 알림을 Firestore에서 가져오는 함수
    private func fetchNotifications(type: String? = nil, customerEmail: String? = nil, completion: @escaping ([NotificationModel]) -> Void) {
        var query: Query = db.collection("notifications")
        
        // 필터링 조건 설정
        if let type = type {
            query = query.whereField("type", isEqualTo: type)
        }
        if let customerEmail = customerEmail {
            query = query.whereField("customerEmail", isEqualTo: customerEmail)
        }
        
        query.getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching notifications: \(error)")
                completion([])
            } else {
                let notifications = snapshot?.documents.compactMap { doc -> NotificationModel? in
                    let data = doc.data()
                    
                    let time = (data["time"] as? Timestamp)?.dateValue() ?? Date()
                    
                    return NotificationModel(
                        id: doc.documentID,
                        type: data["type"] as? String ?? "",
                        customerEmail: data["customerEmail"] as? String ?? "",
                        title: data["title"] as? String ?? "",
                        message: data["message"] as? String ?? "",
                        time: time,
                        isRead: data["isRead"] as? Bool ?? false,
                        status: data["status"] as? String ?? "",
                        isTakenout: data["isTakenout"] as? Bool ?? false
                    )
                } ?? []
                completion(notifications)
            }
        }
    }
    
    // 알림 삭제 함수
    func removeNotification(_ notification: NotificationModel) async {
        let notificationId = notification.id
        
        do {
            try await db.collection("notifications").document(notificationId).delete()
        } catch {
            print("Error removing notification: \(error)")
        }
    }
    
    // 알림 읽음 표시 함수
    func readNotification(_ notification: NotificationModel) async {
        let notificationId = notification.id
        
        do {
            try await db.collection("notifications").document(notificationId).updateData(["isRead": true])
        } catch {
            print("Error reading notification: \(error)")
        }
    }
}
