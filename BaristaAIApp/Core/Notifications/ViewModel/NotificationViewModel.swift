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
    private var listener: ListenerRegistration?
    
    // 알림 데이터 로드
    func loadNotifications(customerEmail: String?) async {
        guard let customerEmail = customerEmail else {
            await fetchNotifications(type: "roll-out")
            return
        }
        
        await fetchNotifications(customerEmail: customerEmail)
    }
    
    // 알림을 Firestore에서 가져오는 함수
    private func fetchNotifications(type: String? = nil, customerEmail: String? = nil) async {
        var query: Query = db.collection("notifications")
        
        // 필터링 조건 설정
        if let type = type {
            query = query.whereField("type", isEqualTo: type)
        }
        if let customerEmail = customerEmail {
            query = query.whereField("customerEmail", isEqualTo: customerEmail)
        }
        
        do {
            let snapshot = try await query.getDocuments()
            
            let notifications = snapshot.documents.compactMap { document -> NotificationModel? in
                let data = document.data()
                
                let time = (data["time"] as? Timestamp)?.dateValue() ?? Date()
                return NotificationModel(
                    id: document.documentID,
                    type: data["type"] as? String ?? "",
                    customerEmail: data["customerEmail"] as? String ?? "",
                    title: data["title"] as? String ?? "",
                    message: data["message"] as? String ?? "",
                    time: time,
                    isRead: data["isRead"] as? Bool ?? false,
                    status: data["status"] as? String ?? "",
                    isTakenout: data["isTakenout"] as? Bool ?? false
                )
            }
            
            DispatchQueue.main.async {
                self.notifications = notifications.sorted { $0.time > $1.time }
            }
        } catch {
            print("Error fetching notifications: \(error)")
        }
    }
    
    func startListeningForNotifications(customerEmail: String?) {
        guard let customerEmail = customerEmail else { return }
        
        stopListeningForNotifications()
        
        listener = db.collection("notifications")
            .whereField("customerEmail", isEqualTo: customerEmail)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let snapshot = snapshot else {
                    print("NotificationsViewModel - Error listening for notifications: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                Task {
                    await self?.processDocumentChanges(snapshot: snapshot)
                }
        }
    }
    
    private func processDocumentChanges(snapshot: QuerySnapshot) async {
//        print("NotificationViewModel - Processing document changes")
        for documentChange in snapshot.documentChanges {
            let data = documentChange.document.data()
            
            let time = (data["time"] as? Timestamp)?.dateValue() ?? Date()
            let updatedNotification = NotificationModel(
                id: documentChange.document.documentID,
                type: data["type"] as? String ?? "",
                customerEmail: data["customerEmail"] as? String ?? "",
                title: data["title"] as? String ?? "",
                message: data["message"] as? String ?? "",
                time: time,
                isRead: data["isRead"] as? Bool ?? false,
                status: data["status"] as? String ?? "",
                isTakenout: data["isTakenout"] as? Bool ?? false
            )
            
            switch documentChange.type {
            case .added
                where !self.notifications.contains(updatedNotification):
                DispatchQueue.main.async {
                    self.notifications.append(updatedNotification)
                }
//                self.notifications.append(updatedNotification)
            case .modified:
                if let index = self.notifications.firstIndex(where: { $0.id == updatedNotification.id }) {
                    if self.notifications[index].status != updatedNotification.status {
                        DispatchQueue.main.async {
                            self.notifications[index].status = updatedNotification.status
                        }
                    }
                }
            case .removed:
                DispatchQueue.main.async {
                    if let index = self.notifications.firstIndex(where: { $0.id == updatedNotification.id }) {
                        self.notifications.remove(at: index)
                    }
                }
            default:
                break
            }
        }
        
        // 시간 내림차순 정렬 후 업데이트
        DispatchQueue.main.async {
            self.notifications.sort { $0.time > $1.time }
        }
    }
    
    func stopListeningForNotifications() {
        listener?.remove()
        listener = nil
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
