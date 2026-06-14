//
//  GeminiClient.swift
//  LIFT
//

import Foundation
import UIKit

class GeminiClient {
    static let shared = GeminiClient()
    
    private var apiKey: String { Secrets.geminiApiKey }
    private let modelName = "gemini-3.1-flash-lite"
    
    private var endpointURL: URL? {
        URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent?key=\(apiKey)")
    }
    
    struct GeminiMealResult: Codable {
        let name: String
        let mealType: String // "Breakfast", "Lunch", "Dinner", "Snack"
        let calories: Int
        let protein: Double // in grams
        let carbs: Double // in grams
        let fat: Double // in grams
        let explanation: String
    }
    
    // System Instruction to force Gemini to return valid, formatted JSON
    private let systemPrompt = """
    You are LIFT Nutrition AI, a highly accurate calorie and macronutrient estimation assistant.
    Your task is to analyze the user's food description, voice transcript, or meal photo, estimate the calories and macronutrients (protein, carbs, fat) in grams, categorize it into a meal type (Breakfast, Lunch, Dinner, Snack), and write a short, encouraging explanation for the athlete.
    
    You must ALWAYS reply with a single, parseable JSON object matching this schema. Do NOT wrap the JSON in markdown formatting (no ```json code blocks). Just return the raw JSON object.
    
    JSON Schema:
    {
      "name": "Short descriptive name of the food",
      "mealType": "Breakfast" | "Lunch" | "Dinner" | "Snack",
      "calories": integer value (kcal),
      "protein": double value (g),
      "carbs": double value (g),
      "fat": double value (g),
      "explanation": "A friendly, encouraging, and brief response explaining the food estimate (max 2 sentences)."
    }
    
    If you cannot identify any food, return:
    {
      "name": "Unknown Food",
      "mealType": "Snack",
      "calories": 0,
      "protein": 0.0,
      "carbs": 0.0,
      "fat": 0.0,
      "explanation": "I couldn't identify any food from the input. Could you please specify in detail what you ate?"
    }
    """
    
    // System Instruction to force Gemini to return valid, formatted food search results
    private let searchSystemPrompt = """
    You are LIFT Nutrition AI Search Engine.
    Your task is to take a food search query, find or estimate matching food items, and return a JSON array of up to 5 matching products.
    For each product, estimate the calories and macronutrients (protein, carbs, fat) *per 100 grams* of the food.
    
    You must ALWAYS reply with a single, parseable JSON array matching this schema. Do NOT wrap the JSON in markdown formatting (no ```json code blocks). Just return the raw JSON array.
    
    JSON Schema:
    [
      {
        "code": "unique_string_identifier",
        "product_name_en": "Name of the food product",
        "nutriments": {
          "energy-kcal_100g": double value (kcal per 100g),
          "proteins_100g": double value (g protein per 100g),
          "carbohydrates_100g": double value (g carbs per 100g),
          "fat_100g": double value (g fat per 100g)
        }
      }
    ]
    """
    
    // Call Gemini with text (spoken or typed)
    @discardableResult
    func analyzeText(_ text: String, completion: @escaping (Result<GeminiMealResult, Error>) -> Void) -> URLSessionDataTask? {
        guard let url = endpointURL else {
            completion(.failure(NSError(domain: "GeminiClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid API endpoint"])))
            return nil
        }
        
        let requestBody = GeminiRequest(
            contents: [
                GeminiRequest.Content(parts: [
                    GeminiRequest.Part(text: text, inlineData: nil)
                ])
            ],
            systemInstruction: GeminiRequest.SystemInstruction(parts: [
                GeminiRequest.Part(text: systemPrompt, inlineData: nil)
            ]),
            generationConfig: GeminiRequest.GenerationConfig(responseMimeType: "application/json")
        )
        
        return sendRequest(url: url, body: requestBody, completion: completion)
    }
    
    // Call Gemini to search foods
    @discardableResult
    func searchFoods(query: String, completion: @escaping (Result<[OpenFoodFactsClient.Product], Error>) -> Void) -> URLSessionDataTask? {
        guard let url = endpointURL else {
            completion(.failure(NSError(domain: "GeminiClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid API endpoint"])))
            return nil
        }
        
        let prompt = "Search query: \"\(query)\". Find up to 5 most relevant matching food items."
        
        let requestBody = GeminiRequest(
            contents: [
                GeminiRequest.Content(parts: [
                    GeminiRequest.Part(text: prompt, inlineData: nil)
                ])
            ],
            systemInstruction: GeminiRequest.SystemInstruction(parts: [
                GeminiRequest.Part(text: searchSystemPrompt, inlineData: nil)
            ]),
            generationConfig: GeminiRequest.GenerationConfig(responseMimeType: "application/json")
        )
        
        return sendSearchRequest(url: url, body: requestBody, completion: completion)
    }
    
    // Call Gemini with an image
    @discardableResult
    func analyzeImage(_ image: UIImage, userPrompt: String = "Analyze this meal photo.", completion: @escaping (Result<GeminiMealResult, Error>) -> Void) -> URLSessionDataTask? {
        guard let url = endpointURL else {
            completion(.failure(NSError(domain: "GeminiClient", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid API endpoint"])))
            return nil
        }
        
        // Downscale image to max 512px and compress to 0.5 quality to reduce network transfer latency
        guard let resizedImage = resizeImage(image, targetSize: CGSize(width: 512, height: 512)),
              let imageData = resizedImage.jpegData(compressionQuality: 0.5) else {
            completion(.failure(NSError(domain: "GeminiClient", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to process image"])))
            return nil
        }
        
        let base64ImageString = imageData.base64EncodedString()
        
        let requestBody = GeminiRequest(
            contents: [
                GeminiRequest.Content(parts: [
                    GeminiRequest.Part(text: userPrompt, inlineData: nil),
                    GeminiRequest.Part(text: nil, inlineData: GeminiRequest.InlineData(mimeType: "image/jpeg", data: base64ImageString))
                ])
            ],
            systemInstruction: GeminiRequest.SystemInstruction(parts: [
                GeminiRequest.Part(text: systemPrompt, inlineData: nil)
            ]),
            generationConfig: GeminiRequest.GenerationConfig(responseMimeType: "application/json")
        )
        
        return sendRequest(url: url, body: requestBody, completion: completion)
    }
    
    // Helper network request method for Text/Image analysis
    @discardableResult
    private func sendRequest(url: URL, body: GeminiRequest, completion: @escaping (Result<GeminiMealResult, Error>) -> Void) -> URLSessionDataTask? {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let encoder = JSONEncoder()
            let requestData = try encoder.encode(body)
            request.httpBody = requestData
            
            // Explicitly set Content-Length and User-Agent to avoid early connection drops by proxies or API gateways
            request.setValue("\(requestData.count)", forHTTPHeaderField: "Content-Length")
            request.setValue("LIFTWorkoutApp/1.0 (nihar@lift.com)", forHTTPHeaderField: "User-Agent")
        } catch {
            completion(.failure(error))
            return nil
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                if (error as NSError).code == NSURLErrorCancelled {
                    return // Silent return on cancel
                }
                print("LIFT AI Network Error: \(error.localizedDescription) (Code: \((error as NSError).code))")
                if let httpResponse = response as? HTTPURLResponse {
                    print("LIFT AI HTTP Status on Error: \(httpResponse.statusCode)")
                }
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "GeminiClient", code: -6, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response object"])))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "GeminiClient", code: -3, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                }
                return
            }
            
            // Handle HTTP error statuses (like 400, 403, 429, 500)
            if httpResponse.statusCode != 200 {
                let errorBody = String(data: data, encoding: .utf8) ?? "No error details"
                print("LIFT AI Server Error Status \(httpResponse.statusCode): \(errorBody)")
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "GeminiClient", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API Error (Status \(httpResponse.statusCode)): \(errorBody)"])))
                }
                return
            }
            
            // For debugging: print raw response
            if let rawString = String(data: data, encoding: .utf8) {
                print("LIFT AI Raw Response: \(rawString)")
            }
            
            do {
                let decoder = JSONDecoder()
                let responseObj = try decoder.decode(GeminiResponse.self, from: data)
                
                guard let jsonText = responseObj.candidates.first?.content.parts.first?.text else {
                    throw NSError(domain: "GeminiClient", code: -4, userInfo: [NSLocalizedDescriptionKey: "LIFT AI returned empty candidate content"])
                }
                
                // Parse the inner JSON string returned by the model
                guard let innerData = jsonText.data(using: .utf8) else {
                    throw NSError(domain: "GeminiClient", code: -5, userInfo: [NSLocalizedDescriptionKey: "Inner JSON conversion failed"])
                }
                
                let mealResult = try decoder.decode(GeminiMealResult.self, from: innerData)
                DispatchQueue.main.async {
                    completion(.success(mealResult))
                }
            } catch {
                print("LIFT AI Response Parsing Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        task.resume()
        return task
    }

    // Helper network request method for Food Search
    @discardableResult
    private func sendSearchRequest(url: URL, body: GeminiRequest, completion: @escaping (Result<[OpenFoodFactsClient.Product], Error>) -> Void) -> URLSessionDataTask? {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let encoder = JSONEncoder()
            let requestData = try encoder.encode(body)
            request.httpBody = requestData
            request.setValue("\(requestData.count)", forHTTPHeaderField: "Content-Length")
            request.setValue("LIFTWorkoutApp/1.0 (nihar@lift.com)", forHTTPHeaderField: "User-Agent")
        } catch {
            completion(.failure(error))
            return nil
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                if (error as NSError).code == NSURLErrorCancelled {
                    return // Silent return on cancel
                }
                print("LIFT AI Search Network Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "GeminiClient", code: -6, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response object"])))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "GeminiClient", code: -3, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                }
                return
            }
            
            if httpResponse.statusCode != 200 {
                let errorBody = String(data: data, encoding: .utf8) ?? "No error details"
                print("LIFT AI Search Server Error: \(errorBody)")
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "GeminiClient", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API Error (Status \(httpResponse.statusCode))"])))
                }
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let responseObj = try decoder.decode(GeminiResponse.self, from: data)
                
                guard let jsonText = responseObj.candidates.first?.content.parts.first?.text else {
                    throw NSError(domain: "GeminiClient", code: -4, userInfo: [NSLocalizedDescriptionKey: "LIFT AI search returned empty candidate content"])
                }
                
                guard let innerData = jsonText.data(using: .utf8) else {
                    throw NSError(domain: "GeminiClient", code: -5, userInfo: [NSLocalizedDescriptionKey: "Inner JSON conversion failed"])
                }
                
                let searchProducts = try decoder.decode([OpenFoodFactsClient.Product].self, from: innerData)
                DispatchQueue.main.async {
                    completion(.success(searchProducts))
                }
            } catch {
                print("LIFT AI Search Parsing Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        task.resume()
        return task
    }
    
    // Hardware-accelerated utility to resize images for API consumption
    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size
        
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        
        var newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        let rect = CGRect(origin: .zero, size: newSize)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: rect)
        }
    }
}

// MARK: - Gemini API Request/Response Encodable & Decodable Models

fileprivate struct GeminiRequest: Codable {
    let contents: [Content]
    let systemInstruction: SystemInstruction?
    let generationConfig: GenerationConfig?
    
    struct Content: Codable {
        let parts: [Part]
    }
    
    struct Part: Codable {
        let text: String?
        let inlineData: InlineData?
    }
    
    struct InlineData: Codable {
        let mimeType: String
        let data: String // base64 string
    }
    
    struct SystemInstruction: Codable {
        let parts: [Part]
    }
    
    struct GenerationConfig: Codable {
        let responseMimeType: String?
    }
}

fileprivate struct GeminiResponse: Codable {
    let candidates: [Candidate]
    
    struct Candidate: Codable {
        let content: Content
    }
    
    struct Content: Codable {
        let parts: [Part]
    }
    
    struct Part: Codable {
        let text: String?
    }
}
