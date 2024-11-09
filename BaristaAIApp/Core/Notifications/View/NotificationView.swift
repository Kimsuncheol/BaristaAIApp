//
//  NotificationsView.swift
//  BaristaAIApp
//
//  Created by 김선철 on 9/28/24.
//

import SwiftUI
import Combine

struct NotificationView: View {
    let user: User?
    @StateObject private var viewModel = NotificationViewModel()
    @State private var selectedNotification: NotificationModel?
    @State private var isNavigatingToQRCode = false
    
    var body: some View {
        VStack {
            if viewModel.notifications.isEmpty {
                Text("No notifications")
                    .font(.headline.bold())
                    .foregroundColor(.gray)
            } else {
                List {
                    ForEach(viewModel.notifications) { notification in
                        NotificationRow(notification: notification, viewModel: viewModel, isNavigatingToQRCode: $isNavigatingToQRCode, selectedNotification: $selectedNotification)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadNotifications(customerEmail: user?.email)
            PaymentHistoryViewModel().startListeningForOrderStatus(customerEmail: user?.email ?? "")
        }
        .onDisappear {
            PaymentHistoryViewModel().stopListeningForOrderStatus()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: CartView(user: user)) {
                    Image(systemName: "cart")
                        .resizable()
                        .frame(width: 24, height: 24)
                }
            }
        }
        .navigationDestination(isPresented: $isNavigatingToQRCode) {
            if let selectedNotification = selectedNotification {
                QRCodeGenerationView(notification: selectedNotification)
            }
        }
    }
}

#Preview {
    ContentView()
//    NotificationsView()
}

struct NotificationRow: View {
    var notification: NotificationModel
    @ObservedObject var viewModel = NotificationViewModel()
    @Binding var isNavigatingToQRCode: Bool
    @Binding var selectedNotification: NotificationModel?
    @State private var isRead: Bool
    @State private var formattedTime: String
    
    init(notification: NotificationModel, viewModel: NotificationViewModel, isNavigatingToQRCode: Binding<Bool>, selectedNotification: Binding<NotificationModel?>) {
        self.notification = notification
        self.viewModel = viewModel
        self._isRead = State(initialValue: notification.isRead)
        self._formattedTime = State(initialValue: NotificationRow.formatNotificationTime(notification.time))
        self._isNavigatingToQRCode = isNavigatingToQRCode
        self._selectedNotification = selectedNotification
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(notification.isTakenout ? "You have taken out this item" : notification.title)
                    .font(.headline)
                
                Text(notification.message)
                    .font(.subheadline)
                
                Text("Order status: \(notification.status)")
                    .font(.subheadline)
                    .foregroundColor(notification.status == "Completed" ? .green : .red)
                
                Text(formattedTime)
                    .font(.caption)
                    .foregroundColor(.gray)
                
//                Text(notification.isTakenout ? "Taken out" : "Not taken out")
//                
//                if notification.isTakenout {
//                    Text("\(String(describing: notification.takenoutTime))")
//                }
            }
            .foregroundColor(isRead ? .gray : .black)
            
            Spacer()
            
            if !isRead {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 10, height: 10)
            }
        }
        .padding()
        .background(isRead ? Color.white : Color(UIColor.systemGray6))
        .cornerRadius(8)
        .swipeActions(allowsFullSwipe: true) {
            Button(role: .destructive) {
                Task {
                    await viewModel.removeNotification(notification)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .onTapGesture {
            if !notification.isTakenout, notification.status != "Cancelled", notification.status != "Rejected" {
                selectedNotification = notification
                isNavigatingToQRCode = true
            }
            if !notification.isRead {
                Task {
                    await viewModel.readNotification(notification)
                    isRead = true
                }
            }
        }
        .contentShape(Rectangle())
        .onAppear {
            formattedTime = NotificationRow.formatNotificationTime(notification.time)
        }
    }
    
    private static func formatNotificationTime(_ time: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(time)
        
        let minutes = Int(timeInterval / 60)
        let hours = Int(timeInterval / 3600)
        let days = Int(timeInterval / 86400)
        let weeks = Int(timeInterval / 604800)
        let months = Int(timeInterval / 2592000)
        let years = Int(timeInterval / 31536000)
        
        if minutes < 1 {
            return "just now"
        } else if minutes < 60  {
            return "\(minutes)m ago"
        } else if hours < 24  {
            return "\(hours)h ago"
        } else if days < 7  {
            return days == 1 ? "Yesterday" : "\(days)d ago"
        } else if weeks < 4  {
            return weeks == 1 ? "Last week" : "\(weeks)w ago"
        } else if months < 12  {
            return months == 1 ? "Last month" : "\(months)m ago"
        } else {
            return years == 1 ? "Last year" : "\(years)y ago"
        }
    }
}
