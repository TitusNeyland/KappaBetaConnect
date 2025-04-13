import SwiftUI

extension Date {
    func timeAgoDisplay() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.second, .minute, .hour, .day, .weekOfYear, .month, .year], from: self, to: now)
        
        if let years = components.year, years > 0 {
            return years == 1 ? "1yr ago" : "\(years)yrs ago"
        }
        if let months = components.month, months > 0 {
            return months == 1 ? "1mo ago" : "\(months)mo ago"
        }
        if let weeks = components.weekOfYear, weeks > 0 {
            return weeks == 1 ? "1w ago" : "\(weeks)w ago"
        }
        if let days = components.day, days > 0 {
            return days == 1 ? "1d ago" : "\(days)d ago"
        }
        if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1h ago" : "\(hours)h ago"
        }
        if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1m ago" : "\(minutes)m ago"
        }
        if let seconds = components.second, seconds > 0 {
            return seconds < 5 ? "now" : "\(seconds)s ago"
        }
        return "now"
    }
}

extension String {
    func detectURLs() -> [(url: URL, range: Range<String.Index>)] {
        var urls: [(URL, Range<String.Index>)] = []
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count))
        
        matches?.forEach { match in
            if let url = match.url,
               let range = Range(match.range, in: self) {
                urls.append((url, range))
            }
        }
        return urls
    }
} 