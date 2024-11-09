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
    @FocusState var isFocused
    
    // 음성 인식을 위한 프로퍼티
    @State private var speechRecognizer = SFSpeechRecognizer()
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var audioEngine = AVAudioEngine()
    
    var onSend: (String) -> Void
    
    var body: some View {
        ZStack(alignment: .trailing) {
            TextField("", text: $text)
                .padding(.leading)
                .frame(width: UIScreen.main.bounds.width - 40, height: 50)
                .focused($isFocused)
                .background(Color.gray.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            HStack(spacing: 10) {
                if text.isEmpty {
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
                        onSend(text) // 전송 버튼 클릭 시 클로저 실행
                    } label: {
                        Image(systemName: "arrow.up")
                            .resizable()
                            .frame(width: 15, height: 15)
                    }
                }
                .frame(width: 30, height: 30)
                .background(Color.yellow)
                .clipShape(Circle())
            }
            .padding(.trailing, 8)
        }
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
