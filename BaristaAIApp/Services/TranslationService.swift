//
//  TranslationService.swift
//  BaristaAIAppForManager
//
//  Created by 김선철 on 11/27/24.
//

import Foundation

class TranslationService {
    private let apiKey = "AIzaSyCYu9OA91eqiMlBHbphKrzPcPu7Zt1Voaw" // 안전한 방법으로 관리해야 합니다.
    private let baseURL = "https://translation.googleapis.com/language/translate/v2"
    
    func translate(text: String, targetLanguage: String = "en") async throws -> String {
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            throw NSError(domain: "TranslationServiceError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "q": text,
            "target": targetLanguage
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let response = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataObject = response["data"] as? [String: Any],
              let translations = dataObject["translations"] as? [[String: Any]],
              let translatedText = translations.first?["translatedText"] as? String else {
            throw NSError(domain: "TranslationServiceError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse translation response"])
        }
        
        return translatedText
    }
}
