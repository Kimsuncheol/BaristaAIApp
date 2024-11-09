//
//  PaymentHistoryView.swift
//  BaristaAIApp
//
//  Created by 김선철 on 10/7/24.
//

import SwiftUI
import FirebaseFirestore

struct PaymentHistoryView: View {
    @StateObject private var viewModel = PaymentHistoryViewModel()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.sortedDates, id: \.self) { date in
                    Section(header: Text(date)) {
                        ForEach(viewModel.paymentsByDate[date] ?? [], id: \.id) { payment in
                            DisclosureGroup {
                                VStack(alignment: .leading) {
                                    ForEach(payment.items, id: \.id) { item in
                                        Text("Item: \(item.name)")
                                        Text("Quantity: \(item.quantity)")
                                        Text("Price: \(item.price) KRW")
                                        Divider()
                                    }
                                    Text("Total Price: \(payment.totalPrice) KRW")
                                    Text("Timestamp: \(payment.timestamp, formatter: viewModel.dateFormatter)")
                                }
                                .padding()
                            } label: {
                                HStack {
                                    Text(payment.timestamp, formatter: viewModel.timeFormatter)
                                    Spacer()
                                    Text("\(payment.totalPrice) KRW")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Payment History")
            .onAppear {
                Task {
                    await viewModel.fetchPaymentHistory()
                }
            }
        }
    }
}

#Preview {
    PaymentHistoryView()
}
