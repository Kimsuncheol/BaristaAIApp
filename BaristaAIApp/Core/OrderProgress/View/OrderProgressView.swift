//
//  OrderProgressView.swift
//  BaristaAIApp
//
//  Created by 김선철 on 10/9/24.
//

import SwiftUI

struct OrderProgressView: View {
    @State private var currentStep: Int = 3
    
    var body: some View {
        VStack {
            HStack(alignment: .top, spacing: 20) {
                // 주문이
                ProgressStepView(stepNumber: 1, title: "Order\nReceived", isCompleted: currentStep >= 1, previousStepCompleted: currentStep == 0)
                ProgressStepView(stepNumber: 2, title: "Preparing", isCompleted: currentStep >= 2, previousStepCompleted: currentStep == 1)
                ProgressStepView(stepNumber: 3, title: "Completed", isCompleted: currentStep >= 3, previousStepCompleted: currentStep == 2)
            }
        }
    }
}

struct ProgressStepView: View {
    var stepNumber: Int
    var title: String
    var isCompleted: Bool
    var imageName: [String] = ["order-received", "preparing"]
    var previousStepCompleted: Bool
    
    @State private var shake = false // 애니메이션을 위한 상태
    
    var body: some View {
        VStack(spacing: 20) {
            if stepNumber == 3 {
                // SF Symbols 아이콘 사용
                Image(systemName: "mug")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .opacity(isCompleted ? 1.0 : 0.3)
                    .rotationEffect(Angle.degrees(shake ? 20 : 0))
                    .animation(
                        previousStepCompleted ? Animation.easeInOut(duration: 0.2).repeatForever(autoreverses: true) : .default,
                        value: shake
                    )
                    .onAppear {
                        if previousStepCompleted && !isCompleted {
                            shake = true // 이전 단계가 완료되고 현재 단계가 완료되지 않은 경우 흔들림 시작
                        }
                    }
                    .onChange(of: previousStepCompleted) {
                        if !isCompleted {
                            shake = true // 바로 이전 단계가 완료되면 애니메이션 활성화
                        } else {
                            shake = false // 애니메이션 중지
                        }
                    }
            } else {
                // 제공된 이미지 사용
                Image(imageName[stepNumber - 1])
                    .resizable()
                    .frame(width: 50, height: 50)
                    .scaledToFit()
                    .opacity(isCompleted ? 1.0 : 0.3)
                    .rotationEffect(Angle.degrees(shake ? 20 : 0))
                    .animation(
                        previousStepCompleted ? Animation.easeInOut(duration: 0.2).repeatForever(autoreverses: true) : .default,
                        value: shake
                    )
                    .onAppear {
                        if previousStepCompleted && !isCompleted {
                            shake = true // 이전 단계가 완료되고 현재 단계가 완료되지 않은 경우 흔들림 시작
                        }
                    }
                    .onChange(of: previousStepCompleted) {
                        if previousStepCompleted && !isCompleted {
                            shake = true // 바로 이전 단계가 완료되면 애니메이션 활성화
                        } else {
                            shake = false // 애니메이션 중지
                        }
                    }
            }
            
            Text(title)
                .font(.headline)
                .foregroundColor(isCompleted ? .green : .black.opacity(0.3))
                .multilineTextAlignment(.center)
                .padding(10)
        }
    }
}

#Preview {
    OrderProgressView()
}
