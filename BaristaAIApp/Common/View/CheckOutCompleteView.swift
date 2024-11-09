//
//  CheckOutCompleteView.swift
//  BaristaAIApp
//
//  Created by 김선철 on 10/7/24.
//

import SwiftUI

struct CheckOutCompleteView: View {
//    @EnvironmentObject var navigationManager: NavigationManager // 네비게이션 매니저 접근
    let user: User?
    var purchasedCartItems: [Cart]
    var totalPrice: Int
    var totalCount: Int
    

    
    var body: some View {
        VStack(spacing: 20) {
            Text("Thank you for your order!")
                .font(.system(size: 40, weight: .bold))
                .multilineTextAlignment(.center)
            
            List {
                ForEach(purchasedCartItems, id: \.id) { item in
                    HStack(alignment: .top, spacing: 15) {
                        VStack {
                            // Placeholder for image
                        }
                        .frame(width: 80, height: 80)
                        .background(Color.red.opacity(0.2))
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("\(item.name)")
                                .font(.system(size: 20, weight: .bold))
                            
                            HStack(spacing: 40) {
                                Text("\(Int(item.price)) KRW")
                                    .font(.subheadline)
                                
                                Text("\(item.quantity)")
                                    .font(.subheadline)
                            }
                            
                            Text("\(Int(item.totalPrice)) KRW")
                                .font(.subheadline.bold())
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Summary")
                        .font(.system(size: 24, weight: .bold))
                    
                    Spacer()
                }
                .padding(.bottom, 10)
                
                HStack(spacing: 20) {
                    HStack {
                        Text("Price")
                        
                        Spacer()
                    }
                    .frame(width: 100)
                    
                    Text("\(totalPrice) KRW")
                }
                .font(.system(size: 20, weight: .bold))
                
                HStack(spacing: 20) {
                    HStack {
                        Text("Count")
                        
                        Spacer()
                    }
                    .frame(width: 100)
                    
                    Text("\(totalCount)")
                }
                .font(.system(size: 20, weight: .bold))
                .padding(.bottom, 10)
            }
            .padding(.bottom, 60)
            
            Button {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                    window.rootViewController = UIHostingController(rootView: MainTabView(user: user))
                        window.makeKeyAndVisible()
                    }
            } label: {
                Text("Checked Out")
                    .font(.system(size: 20, weight: .bold))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
//    CheckOutCompleteView()
    ContentView()
        .environmentObject(PaymentHistoryViewModel())
}
