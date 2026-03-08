//
//  AIStylistService.swift
//  OOTD.AI
//

import Foundation // Foundation provides URLSession, JSON handling and other core APIs

// -------------------------------------------------------------
// MARK: - Returned JSON From AI (no Decodable to avoid Swift 6 issues)
// -------------------------------------------------------------

struct AIOutfitHints: Sendable { // Struct used to hold the parsed hints returned by the AI
    let jacket: String? // Optional jacket hint returned by the AI
    let shirt: String? // Optional shirt hint returned by the AI
    let pants: String? // Optional pants hint returned by the AI
    let shoes: String? // Optional shoes hint returned by the AI
}

// -------------------------------------------------------------
// MARK: - Request Body for OpenAI Responses API
// -------------------------------------------------------------

struct AIRequestBody: Codable { // Request body used to call the OpenAI Responses API
    struct Message: Codable { // Inner struct representing a single message in the conversation
        let role: String // Role of the message (e.g., "system" or "user")
        let content: String // Text content of the message
    }
    struct TextFormat: Codable { // Inner struct to indicate the desired text format
        let type: String   // e.g., "json_object"
    }
    
    let model: String // Model name to use for the request
    let input: [Message] // Conversation messages to send to the model
    let text: TextFormat // Desired text formatting for the response
}

// -------------------------------------------------------------
// MARK: - AI Stylist Service
// -------------------------------------------------------------

final class AIStylistService: @unchecked Sendable { // Singleton service to call OpenAI and return outfit hints
    
    static let shared = AIStylistService() // Shared singleton instance
    private init() {} // Private initializer to enforce singleton usage
    
    func suggestOutfit(
        temperature: Double, // Current temperature in Fahrenheit used to influence outfit choices
        profile: UserProfile?, // Optional user profile with style preferences
        closetSummary: String, // Text summary of the user's closet contents
        freeTextPrompt: String? = nil, // Optional free-text prompt from the user
        completion: @escaping (Result<AIOutfitHints, Error>) -> Void // Completion handler returning hints or an error
    ) {
        // 1. API key
        guard let apiKey = Bundle.main.infoDictionary?["OPENAI_API_KEY"] as? String, // Read the API key from Info.plist
              !apiKey.isEmpty else { // Ensure the key exists and is not empty
            let err = NSError(
                domain: "AIStylist", // Error domain string
                code: 1, // Error code for missing API key
                userInfo: [NSLocalizedDescriptionKey: "Missing OPENAI_API_KEY in Info.plist"] // Human-readable message
            )
            completion(.failure(err)) // Call completion with failure
            return // Early return on missing key
        }
        
        // 2. Responses endpoint
        guard let url = URL(string: "https://api.openai.com/v1/responses") else { // Construct the Responses API URL
            let err = NSError(
                domain: "AIStylist", // Error domain
                code: 2, // Error code for bad URL
                userInfo: [NSLocalizedDescriptionKey: "Bad URL"] // Message indicating the URL couldn't be formed
            )
            completion(.failure(err)) // Return failure via completion
            return // Early exit
        }
        
        // 3. Prompts
        let systemPrompt = """
        You are an AI fashion stylist. Given temperature, user style, and closet inventory,
        choose ONE jacket (or "none"), ONE shirt, ONE pair of pants, and ONE pair of shoes.

        Respond ONLY with valid JSON, no extra text:

        {
          "jacket": "...",
          "shirt": "...",
          "pants": "...",
          "shoes": "..."
        }
        """ // Multiline system prompt (kept exactly as originally written)
        
        // User prompt containing temperature, profile details, and the closet summary
        var userPrompt = """
Temperature (F): \(Int(temperature))

Style profile:
- Main: \(profile?.mainStyle.rawValue ?? "unknown")
- Fit: \(profile?.fitPreference.rawValue ?? "unknown")
- Colors: \(profile?.colorPreference.rawValue ?? "unknown")
- Climate: \(profile?.climate.rawValue ?? "unknown")

Closet:
\(closetSummary)
"""

        // Append any free-text prompt provided by the user
        if let free = freeTextPrompt, !free.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            userPrompt += "\n\nUser request: \(free)"
        }
        
        // 4. Build request body
        let body = AIRequestBody(
            model: "gpt-5.1-mini", // The model identifier to request
            input: [ // Conversation input array with system and user messages
                .init(role: "system", content: systemPrompt), // System message
                .init(role: "user", content: userPrompt) // User message
            ],
            text: .init(type: "json_object")   // Specify that we want a JSON object back from the Responses API
        )
        
        var request = URLRequest(url: url) // Create a URLRequest for the API call
        request.httpMethod = "POST" // Set HTTP method to POST
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization") // Add Authorization header with bearer token
        request.setValue("application/json", forHTTPHeaderField: "Content-Type") // Set content type header
        request.httpBody = try? JSONEncoder().encode(body) // Encode the request body as JSON and assign to the request
        
        print("🌐 Sending AI request...") // Debug log indicating the request is about to be sent
        
        // 5. Fire request
        URLSession.shared.dataTask(with: request) { data, _, error in // Perform the network request asynchronously
            
            if let error = error { // If a network error occurred
                print("❌ Network error:", error.localizedDescription) // Log the error
                completion(.failure(error)) // Return the error via completion
                return // Early return on error
            }
            
            guard let data = data else { // Ensure data was received
                let err = NSError(
                    domain: "AIStylist", // Error domain
                    code: 3, // Error code for missing data
                    userInfo: [NSLocalizedDescriptionKey: "No data from API"] // Message describing the issue
                )
                completion(.failure(err)) // Call completion with failure
                return // Early exit
            }
            
            // Debug raw JSON from OpenAI
            if let raw = String(data: data, encoding: .utf8) { // Try to decode the raw response data as a UTF-8 string
                print("⚠️ RAW API RESPONSE:\n\(raw)") // Print raw JSON for debugging
            }
            
            do {
                // 6. Parse top-level JSON using JSONSerialization to avoid Decodable isolation issues
                guard
                    let root = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                else {
                    throw NSError(
                        domain: "AIStylist", // Error domain
                        code: 4, // Error code for non-object root
                        userInfo: [NSLocalizedDescriptionKey: "Response is not a JSON object"] // Message indicating unexpected shape
                    )
                }
                
                // Check for error from OpenAI
                if let errorDict = root["error"] as? [String: Any], // If the root contains an "error" object
                   let message = errorDict["message"] as? String { // And it has a message string
                    print("⚠️ RAW API ERROR:", message) // Log the API-level error message
                    let err = NSError(
                        domain: "AIStylist", // Error domain
                        code: 5, // Error code for API error
                        userInfo: [NSLocalizedDescriptionKey: message] // Use the API message as the error description
                    )
                    completion(.failure(err)) // Return the API error via completion
                    return // Early exit
                }
                
                // 7. Extract output[0].content[0].text (Responses API shape)
                guard
                    let output = root["output"] as? [[String: Any]], // The API returns an array under "output"
                    let firstOutput = output.first, // Take the first element of the output array
                    let content = firstOutput["content"] as? [[String: Any]], // Each output has a content array
                    let firstContent = content.first, // Use the first content element
                    let contentText = firstContent["text"] as? String // Extract the text field containing the model's string
                else {
                    throw NSError(
                        domain: "AIStylist", // Error domain
                        code: 6, // Error code for missing nested content
                        userInfo: [NSLocalizedDescriptionKey: "Missing output.content[0].text"] // Message explaining what's missing
                    )
                }
                
                print("📩 RAW AI JSON STRING:\n\(contentText)\n") // Print the raw string the model returned
                
                // 8. Parse the JSON string the model returned into a dictionary
                guard
                    let jsonObject = try JSONSerialization.jsonObject(
                        with: Data(contentText.utf8)
                    ) as? [String: Any]
                else {
                    throw NSError(
                        domain: "AIStylist", // Error domain
                        code: 7, // Error code for AI string not being JSON
                        userInfo: [NSLocalizedDescriptionKey: "AI JSON was not an object"] // Message describing the decode failure
                    )
                }
                
                let hints = AIOutfitHints(
                    jacket: jsonObject["jacket"] as? String, // Map jacket value from AI JSON
                    shirt:  jsonObject["shirt"]  as? String, // Map shirt value
                    pants:  jsonObject["pants"]  as? String, // Map pants value
                    shoes:  jsonObject["shoes"]  as? String // Map shoes value
                )
                
                print("🎉 Parsed AI Outfit Hints:", hints) // Log the parsed hints for debugging
                completion(.success(hints)) // Return the parsed hints via completion
                
            } catch {
                print("❌ Decode error:", error) // Log any decoding/parsing errors
                completion(.failure(error)) // Return the parsing error via completion
            }
            
        }.resume() // Start the network task
    }
}
