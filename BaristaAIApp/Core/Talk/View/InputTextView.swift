//
//  InputTextView.swift
//  BaristaAIApp
//
//  Created by 김선철 on 10/4/24.
//

import SwiftUI
import Speech

struct InputTextView: View {
    @Binding var text: String
    @Binding var isFocused: Bool
    @FocusState var textFieldIsFocused
    // 음성 인식을 위한 프로퍼티
    @State private var speechRecognizer = SFSpeechRecognizer()
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var audioEngine = AVAudioEngine()
    
    var onSend: (String) -> Void
    
    private let maxEditorHeight: CGFloat = 120
    @State private var textHeight: CGFloat = 50
    
    var body: some View {
        HStack(alignment: .bottom) {
            TextField("", text: $text, axis: .vertical)
                .focused($textFieldIsFocused)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .lineLimit(7)
//                .frame(maxWidth: .infinity)
                .padding(8)
                .padding(.leading, 3)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                )
                .onChange(of: textFieldIsFocused) {
                    isFocused = textFieldIsFocused
                }
                .onChange(of: isFocused) {
                    textFieldIsFocused = isFocused
                }
            
            // 음성인식 관련 코드 점검해야 함. 작동 안됨... 누르면 앱이 멈춰버림
            HStack(spacing: 10) {
                if !textFieldIsFocused {
                    Button {
                        startRecording()
                    } label: {
                        Image(systemName: "microphone.circle")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundStyle(.secondary)
                    }
                }
                
                HStack(alignment: .center) {
                    Button {
                        onSend(text)
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .resizable()
                            .frame(width: 15, height: 15)
                    }
                }
                .frame(width: 30, height: 30)
                .background(Color.yellow)
                .clipShape(Circle())
            }
//            .padding(.trailing, 8)
        }
        .frame(width: UIScreen.main.bounds.width - 20)
    }
    
    private func calculateTextHeight() {
           let textRect = text.boundingRect(
               with: CGSize(width: UIScreen.main.bounds.width - 98, height: .greatestFiniteMagnitude),
               options: .usesLineFragmentOrigin,
               attributes: [.font: UIFont.systemFont(ofSize: 17)],
               context: nil
           )
           textHeight = textRect.height + 20 // Additional padding for text height
       }

    // 음성 인식 시작 함수
    private func startRecording() {
        // 권한 요청
        SFSpeechRecognizer.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                break // 권한 승인됨
            default:
                return // 다른 상태에서는 기능 수행 안함
            }
        }
        
        // 오디오 세션 설정
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("오디오 세션 설정 에러: \(error.localizedDescription)")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        
        let inputNode = audioEngine.inputNode
        recognitionRequest.shouldReportPartialResults = true
        
        // 음성 인식 시작
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                self.text = result.bestTranscription.formattedString
            }
            if error != nil || result?.isFinal == true {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("오디오 엔진 시작 에러: \(error.localizedDescription)")
        }
    }
}

#Preview {
//    TalkView()
    ContentView()
}


//TextField("", text: $text)
//    .padding(.leading)
//    .frame(width: textFieldIsFocused ? geometry.size.width - 58 : geometry.size.width - 98, height: geometry.size.height)
//    .focused($textFieldIsFocused)
//    .padding(.trailing)
//    .autocapitalization(.none)
//    .disableAutocorrection(true)
//    .onChange(of: textFieldIsFocused) {
//        isFocused = textFieldIsFocused
//    }
//    .onChange(of: isFocused) {
//        textFieldIsFocused = isFocused
//    }


//TextEditor("",text: $text, axis: .vertical)
//    .focused($textFieldIsFocused)
//    .padding()
//    .frame(
////                            width: textFieldIsFocused ? geometry.size.width - 58 : geometry.size.width - 98,
//        height: min(CGFloat(textLineCount()) * 50, maxEditorHeight)
//    )
//    .scrollContentBackground(.hidden)
//    .background(Color.clear)
//    .autocapitalization(.none)
//    .disableAutocorrection(true)
//    .onChange(of: textFieldIsFocused) {
//        isFocused = textFieldIsFocused
//    }
//    .onChange(of: isFocused) {
//        textFieldIsFocused = isFocused
//    }
