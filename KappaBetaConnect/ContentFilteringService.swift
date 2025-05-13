import Foundation

class ContentFilteringService {
    static let shared = ContentFilteringService()
    
    private let profanityList: Set<String> = [
        "fuck", "shit", "bitch", "damn", "dick", "faggot", "cunt"
        // Add more words as needed
    ]
    
    // Common variations of profanity (e.g., using special characters)
    private let profanityPatterns: [String] = [
        "f[^a-z]*u[^a-z]*c[^a-z]*k",
        "s[^a-z]*h[^a-z]*i[^a-z]*t",
        // Add more patterns as needed
    ]
    
    func containsProfanity(_ text: String) -> Bool {
        let lowercasedText = text.lowercased()
        
        // Check for exact matches
        for word in profanityList {
            if lowercasedText.contains(word) {
                return true
            }
        }
        
        // Check for pattern matches
        for pattern in profanityPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(lowercasedText.startIndex..., in: lowercasedText)
                if regex.firstMatch(in: lowercasedText, options: [], range: range) != nil {
                    return true
                }
            }
        }
        
        return false
    }
    
    func filterContent(_ text: String) -> String {
        var filteredText = text
        
        // Replace profanity with asterisks
        for word in profanityList {
            let pattern = "\\b\(word)\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
                let range = NSRange(filteredText.startIndex..., in: filteredText)
                filteredText = regex.stringByReplacingMatches(
                    in: filteredText,
                    options: [],
                    range: range,
                    withTemplate: String(repeating: "*", count: word.count)
                )
            }
        }
        
        return filteredText
    }
} 
