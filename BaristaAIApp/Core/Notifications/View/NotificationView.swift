//
//  NotificationsView.swift
//  BaristaAIApp
//
//  Created by 김선철 on 9/28/24.
//

import SwiftUI
import Combine
// status가 Completed 경우에만 QRCode를 생성하도록 수정
struct NotificationView: View {
    let user: User?
    @ObservedObject private var viewModel = NotificationViewModel()
    @State private var selectedNotification: NotificationModel?
    @State private var selectedNotificationInParent: NotificationModel?
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
                        NotificationRow(viewModel: viewModel, isNavigatingToQRCode: $isNavigatingToQRCode, selectedNotification: getBindingForNotification(notification), selectedNotificationInParent: $selectedNotificationInParent
                        )
                        
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
//        .task {
//            await viewModel.loadNotifications(customerEmail: user?.email)
//            viewModel.startListeningForNotifications(customerEmail: user?.email)
//        }
        .onAppear {
            Task {
                await viewModel.loadNotifications(customerEmail: user?.email)
            }
            viewModel.startListeningForNotifications(customerEmail: user?.email)
        }
        .onDisappear {
            viewModel.stopListeningForNotifications()
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
            // 아무것도 전달이 안되어 저 뷰에 진입 시 아무것도 표시되지 않음
            if let selectedNotificationInParent = selectedNotificationInParent {
                QRCodeGenerationView(id: selectedNotificationInParent.id, customerEmail: selectedNotificationInParent.customerEmail, time: selectedNotificationInParent.time, status: "Completed")
            } else {
//                print(selectedNotification)
                Text("\(String(describing: selectedNotificationInParent))")
            }
        }
    }
    
    // Function to create Binding for selectedNotification
    private func getBindingForNotification(_ notification: NotificationModel) -> Binding<NotificationModel> {
        return Binding(
            get: { notification },
            set: { updatedNotification in
                if let index = viewModel.notifications.firstIndex(where: { $0.id == updatedNotification.id }) {
                    viewModel.notifications[index] = updatedNotification
                }
            }
        )
    }
}

#Preview {
    ContentView()
//    NotificationsView()
}

struct NotificationRow: View {
    @ObservedObject var viewModel: NotificationViewModel
    @Binding var isNavigatingToQRCode: Bool
    @Binding var selectedNotification: NotificationModel
    @Binding var selectedNotificationInParent: NotificationModel?
    @State private var isRead: Bool
    @State private var formattedTime: String
    
    init(viewModel: NotificationViewModel, isNavigatingToQRCode: Binding<Bool>, selectedNotification: Binding<NotificationModel>, selectedNotificationInParent: Binding<NotificationModel?>) {
        self.viewModel = viewModel
        self._isRead = State(initialValue: selectedNotification.wrappedValue.isRead)
        self._formattedTime = State(initialValue: NotificationRow.formatNotificationTime(selectedNotification.wrappedValue.time))
        self._isNavigatingToQRCode = isNavigatingToQRCode
        self._selectedNotification = selectedNotification
        self._selectedNotificationInParent = selectedNotificationInParent
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(selectedNotification.isTakenout ? "You have taken out this item" : selectedNotification.title)
                    .font(.headline)
                
                Text(selectedNotification.message)
                    .font(.subheadline)
                
                Text("Order status: \(selectedNotification.status)")
                    .font(.subheadline)
                    .foregroundColor(selectedNotification.status == "Completed" ? .green : .red)
                
                Text(formattedTime)
                    .font(.caption)
                    .foregroundColor(.gray)
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
                    await viewModel.removeNotification(selectedNotification)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .onTapGesture {
//            if !selectedNotification.isTakenout, selectedNotification.status != "Cancelled", selectedNotification.status != "Rejected" {
//                selectedNotificationInParent = selectedNotification
//                
//                isNavigatingToQRCode = true
//            }
            if !selectedNotification.isTakenout && selectedNotification.status == "Completed" {
                selectedNotificationInParent = selectedNotification
                
                isNavigatingToQRCode = true
            }
            
            // 위 아래 쫌이따 순서 변경할 거
            if !selectedNotification.isRead {
                Task {
                    await viewModel.readNotification(selectedNotification)
                    isRead = true
                }
            }
        }
        .contentShape(Rectangle())
        .onAppear {
            formattedTime = NotificationRow.formatNotificationTime(selectedNotification.time)
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
