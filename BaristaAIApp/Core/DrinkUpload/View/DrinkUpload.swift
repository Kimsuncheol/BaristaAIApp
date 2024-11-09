//
//  DrinkUpload.swift
//  BaristaAIApp
//
//  Created by 김선철 on 10/10/24.
//

import SwiftUI

struct DrinkUpload: View {
    @StateObject private var viewModel = DrinkUploadViewModel() // ViewModel 인스턴스 생성

    var body: some View {
        VStack {
            Text("음료 업로드")
                .font(.largeTitle)
                .padding()

            // 음료 목록 표시
            List(viewModel.drinkItems) { drink in
                VStack(alignment: .leading) {
                    Text(drink.name)
                        .font(.headline)
                    Text(drink.description)
                        .font(.subheadline)
                    Text("\(drink.price) KRW")
                        .font(.subheadline)
                }
            }
            .listStyle(PlainListStyle())
            
            // 음료 업로드 버튼
            Button(action: {
                viewModel.uploadDrink() // 음료 업로드 메서드 호출
            }) {
                Text("음료 업로드")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .padding()
            
            // 모든 음료 삭제 버튼
            Button(action: {
                viewModel.deleteAllDrinks() // 모든 음료 삭제 메서드 호출
            }) {
                Text("모든 음료 삭제")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(8)
            }
            .padding()
        }
        .navigationTitle("Drink Upload")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ContentView()
//    DrinkUpload()
}
