//
//  ChatMessageView.swift
//  BaristaAIApp
//
//  Created by 김선철 on 10/6/24.
//

import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    var filename: String
    var loopMode: LottieLoopMode = .loop

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)

        let animationView = LottieAnimationView(name: filename)
        animationView.loopMode = loopMode
        animationView.play()

        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)

        NSLayoutConstraint.activate([
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // 애니메이션 업데이트가 필요할 경우 구현
    }
}

struct ChatMessageView: View {
    let user: User?
    @ObservedObject var viewModel: ChatViewModel
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if message.senderId == user?.email {
                // 현재 사용자가 보낸 메시지
                Spacer()
                
                HStack(alignment: .bottom) {
                    Text(message.formattedTime())
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(message.text)
                        .padding(10)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                }
            } else {
                // 대화형 엔진이 보낸 메시지
                Image("bot")
                    .resizable()
                    .frame(width: 45, height: 45)
                
                VStack(alignment: .leading) {
                    Text(viewModel.chatbotName)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    var showResponse = message.senderId == viewModel.chatbotId && viewModel.isLoadingResponse && message.id == viewModel.messages.last?.id
                    
                    ZStack(alignment: .leading) {
                        LottieView(filename: "Animation - 1731824848115")
                            .frame(width: 56, height: 56)
                            .opacity(showResponse ? 1 : 0)
                        
                        HStack(alignment: .bottom) {
                            Text(message.text)
                                .padding(10)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                                .transition(.opacity)
                            
                            
                            Text(message.formattedTime())
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .fixedSize(horizontal: false, vertical: true)
                                .transition(.opacity)
                            
                            //                            if let matchDrinks = viewModel.
                        }
                        .opacity(showResponse ? 0 : 1)
                    }
                    .animation(.easeInOut, value: viewModel.isLoadingResponse)
                }
                Spacer()
            }
        }
    }
}

#Preview {
    ContentView()
}
