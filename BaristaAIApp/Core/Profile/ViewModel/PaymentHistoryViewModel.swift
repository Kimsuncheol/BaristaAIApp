//
//  PaymentHistoryViewModel.swift
//  BaristaAIApp
//
//  Created by 김선철 on 10/9/24.
//

import SwiftUI
import FirebaseFirestore
import UserNotifications
import PassKit

@MainActor
class PaymentHistoryViewModel: ObservableObject {
    @Published var notifications: [NotificationModel] = []
    @Published var paymentsByDate: [String: [PaymentHistory]] = [:]  // 결제 내역을 날짜별로 그룹화
    @Published var sortedDates: [String] = []  // 정렬된 날짜 배열
    @Published var orderStatusMessage: String = ""  // 주문 상태 메시지
    private var listener: ListenerRegistration? // Real-time listener
    private let db = Firestore.firestore()
    
    private var paymentHistoryCollectionName: String = "payment_history"
    private var orderHistoryCollectionName: String = "order_history"
    private var notificationsCollectionName: String = "notifications"
    
    private var previousStatuses: [String: String] = [:] // 각 주문의 이전 상태를 저장

//    init() {
//        startListeningForOrderStatus(customerEmail: AuthService.shared.currentUser?.email ?? "")
//    }
    
//    deinit {
//        listener?.remove()
//        listener = nil
//            stopListeningForOrderStatus()
//        Task {
//            await stopListeningForOrderStatus()
//        }
//    }

    // Firestore에서 결제 내역을 가져오는 비동기 함수
    func fetchPaymentHistory() async {
        do {
            let snapshot = try await db.collection(paymentHistoryCollectionName).order(by: "timestamp").getDocuments()
            let payments = snapshot.documents.compactMap { document -> PaymentHistory? in
                PaymentHistory(document: document.data())
            }
            
            // 결제 내역을 날짜별로 그룹화
            let groupedPayments = Dictionary(grouping: payments) { payment in
                self.dateFormatter.string(from: payment.timestamp)
            }
            
            self.paymentsByDate = groupedPayments
            self.sortedDates = groupedPayments.keys.sorted {
                guard let date1 = self.dateFormatter.date(from: $0),
                      let date2 = self.dateFormatter.date(from: $1) else { return false }
                return date1 > date2
            }
        } catch {
            print("Error fetching payment history: \(error.localizedDescription)")
        }
    }
    
    // 결제 내역 저장 함수 (async/await 적용)
    func savePaymentHistory(items: [Cart], totalPrice: Int, customerEmail: String, paymentToken: PKPaymentToken) async {
        let paymentID = UUID().uuidString
        let paymentHistory = PaymentHistory(
            id: paymentID,
            customerEmail: customerEmail,
            items: items,
            totalPrice: totalPrice,
            timestamp: Date(),
            status: "Pending",
            paymentTokenData: paymentToken.paymentData
        )
        
        do {
            try await db.collection(paymentHistoryCollectionName).document(paymentID).setData(paymentHistory.dictionary)
            
            var orderData = paymentHistory.dictionary
            orderData["customerEmail"] = customerEmail  // 고객 이메일 추가
            orderData["isChecked"] = false
            
            try await db.collection(orderHistoryCollectionName).document(paymentID).setData(orderData)
            
            print("Payment history saved successfully.")
            let type = "order"      // 이거 유의
            // paymentID 전달
            await createOrderCompletionNotification(notificationId: paymentID, items: items, totalPrice: totalPrice, customerEmail: customerEmail, type: type)
        } catch {
            print("Error saving payment history: \(error.localizedDescription)")
        }
    }

    // 주문 상태 실시간 업데이트 리스너 설정
    func startListeningForOrderStatus(customerEmail: String) {
        print("Starting listener for customerEmail: \(customerEmail)")

        var isInitialLoad = true // 초기 로드 여부를 추적

//        listener?.remove()
        listener = db.collection(notificationsCollectionName)
            .whereField("customerEmail", isEqualTo: customerEmail)
            .addSnapshotListener { [weak self] snapshot, error in
                
                if let error = error {
                    print("Error listening for order status: \(error.localizedDescription)")
                    return
                }
                
                guard let self = self else { return }
                guard let snapshot = snapshot else {
                    print("No snapshot received.")
                    return
                }
                
                for diff in snapshot.documentChanges {
                    let document = diff.document
                    let data = document.data()
                    print("--------- 121 1212 \(data)")
                    guard let paymentHistory = PaymentHistory(document: data) else { continue }
                    
                    let documentID = document.documentID
                    let curretStatus = paymentHistory.status
                    
                    let previousStatus = self.previousStatuses[documentID]
                    
                    self.previousStatuses[documentID] = curretStatus
                    
                    if isInitialLoad {
                        continue
                    }
                    
                    if previousStatus == curretStatus {
                        continue
                    }
                    
                    self.handleOrderStatusChange(paymentHistory: paymentHistory)
//                    if diff.type == .modified {
//                        print("제발 좀....")
//                        // 주문 상태 변경 감지
//                        self.handleOrderStatusChange(paymentHistory: paymentHistory)
////                        self?.handleOrderStatusChange(notification: notification)
//                    }
                }
                isInitialLoad = false
            }
    }
    
    // 주문 상태 변경 처리 함수
    private func handleOrderStatusChange(paymentHistory: PaymentHistory) {
//        let status = notification.status
        let status = paymentHistory.status
        var title = ""
        var message = ""
        
        switch status {
        case "Preparing to brew":
            title = "Order Accepted"
            message = "Your order is now being prepared"
        case "Completed":
            title = "Order Completed"
            message = "Your order is ready for pickup"
        case "Rejected", "Cancelled":
            title = "Order \(status)"
            message = "Your order has been \(status.lowercased())."
        default:
            title = "Pending"
            message = "Your order is now \(status.lowercased())."
        }
        
        self.orderStatusMessage = message
        print(orderStatusMessage)
        
        // 상태에 따라 로컬 알림 또는 UI 업데이트 수행
        Task {
            let notification = NotificationModel(
//                id: UUID().uuidString,      // 이걸 유의  -> 얘는 절대 쓰면 안됨
                id: paymentHistory.id,      // 이걸 유의 -> 아마 이걸 써야 할 듯 한데...
                type: "order",
                customerEmail: paymentHistory.customerEmail,
                title: title,
                message: message,
                time: Date(),
                isRead: false,
                status: status,
                isTakenout: false       // 이렇게 해도 될까..
            )
            await saveNotification(notification: notification, customerEmail: paymentHistory.customerEmail)
            await triggerLocalNotification(title: title, message: message)
        }
    }
    
    // 주문 완료 알림 생성 및 저장 (async/await 적용)
    private func createOrderCompletionNotification(notificationId: String, items: [Cart], totalPrice: Int, customerEmail: String, type: String) async {
        let title = "Order Completed"                       // 이것도 유의
        let itemNames = items.map { $0.name }.joined(separator: ", ")
        let message = "Your order for \(itemNames) totaling \(totalPrice) KRW has been completed."
        let currentTime = Date()

        let notification = NotificationModel(id: notificationId, type: type, customerEmail: customerEmail, title: title, message: message, time: currentTime, isRead: false, status: "Pending", isTakenout: false)
        
        // Firestore에 알림 저장
        await saveNotification(notification: notification, customerEmail: customerEmail)
        
        // 로컬 알림 트리거
        await triggerLocalNotification(title: title, message: message)
    }

    // 알림을 Firestore에 저장하는 함수 (async/await 적용)
    private func saveNotification(notification: NotificationModel, customerEmail: String) async {
        // 중복성 검사해야 함..
        do {
            try await db.collection(notificationsCollectionName).document(notification.id).setData([
                "id": notification.id,
                "type": notification.type,
                "customerEmail": notification.customerEmail,
                "title": notification.title,
                "message": notification.message,
                "time": notification.time,
                "isRead": notification.isRead,
                "isChecked": notification.isChecked,     // by manager
                "status": notification.status,
                "isTakenout": notification.isTakenout
            ])
            print("Notification saved successfully.")
        } catch {
            print("Error saving notification: \(error.localizedDescription)")
        }
    }

    // 로컬 알림 트리거 함수 추가
    private func triggerLocalNotification(title: String, message: String) async {
        // 알림 내용 설정
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = UNNotificationSound.default
        
        // 알림 트리거 설정 (즉시 실행)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // 알림 요청 생성
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        // 알림 센터에 알림 요청 추가
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Local notification scheduled successfully.")
        } catch {
            print("Error scheduling local notification: \(error.localizedDescription)")
        }
    }

    // 리스너 제거 함수 (필요한 경우)
    func stopListeningForOrderStatus() {
        listener?.remove()
        listener = nil
    }

    // 날짜별 그룹화를 위한 DateFormatter
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }

    // 시간 표시를 위한 TimeFormatter
    var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }
}
