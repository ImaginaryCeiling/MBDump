//
//  isUrl.swift
//  MBDump
//
//  Created by Arnav Chauhan on 10/31/25.
//

import SwiftUI
import SwiftSoup

func isURL(_ text: String) -> Bool {
    let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Check if it already has a protocol
    if trimmedText.starts(with: "http://") || trimmedText.starts(with: "https://") ||
       trimmedText.starts(with: "ftp://") || trimmedText.starts(with: "file://") {
        return URL(string: trimmedText) != nil
    }
    
    // Check for www. prefix
    if trimmedText.starts(with: "www.") {
        //let withoutWww = String(trimmedText.dropFirst(4))
        if let url = URL(string: "https://\(trimmedText)") {
            return url.host != nil
        }
    }
    
    // Check if it looks like a domain name (contains at least one dot and valid TLD)
    let domainPattern = #"^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}(/.*)?$"#
    
    if let regex = try? NSRegularExpression(pattern: domainPattern) {
        let range = NSRange(location: 0, length: trimmedText.utf16.count)
        if regex.firstMatch(in: trimmedText, options: [], range: range) != nil {
            // Try to create a URL with https:// prefix
            if let url = URL(string: "https://\(trimmedText)") {
                return url.host != nil
            }
        }
    }
    
    // Check for common TLD patterns
    let tldPattern = #"^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.(com|org|net|edu|gov|mil|int|co|uk|de|fr|jp|au|ca|us|io|ai|app|dev|tech|online|site|website|blog|news|info|biz|name|mobi|tv|cc|me|ly|be|at|ch|dk|es|fi|it|nl|no|se|pl|br|mx|in|cn|ru|kr|nz|za|eg|ng|ke|ma|tn|dz|sd|so|et|ug|tz|zm|bw|sz|ls|mg|mu|sc|re|yt|km|dj|er|ss|cf|td|ne|ml|bf|ci|gh|sn|gm|gn|gw|lr|sl|tg|bj|cv|st|gq|ga|cg|cd|ao|mz|mw|zw)(/.*)?$"#
    
    if let regex = try? NSRegularExpression(pattern: tldPattern) {
        let range = NSRange(location: 0, length: trimmedText.utf16.count)
        if regex.firstMatch(in: trimmedText, options: [], range: range) != nil {
            return true
        }
    }
    
    return false
}


func extractTitleWithSwiftSoup(from html: String) -> String? {
    do {
        let doc = try SwiftSoup.parse(html)
        let title = try doc.title()
        
        // Clean up the title
        let cleanedTitle = title
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
        
        // Clean up multiple spaces
        let finalTitle = cleanedTitle.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        return finalTitle.isEmpty ? nil : finalTitle
    } catch {
        print("Failed to parse HTML with SwiftSoup: \(error)")
        return nil
    }
}


func fetchWebsiteTitle(for item: Item, store: DataStore) {
    // Ensure we have a valid URL
    let urlString = item.content
    let finalURL: String
    
    if urlString.starts(with: "http://") || urlString.starts(with: "https://") {
        finalURL = urlString
    } else if urlString.starts(with: "www.") {
        finalURL = "https://\(urlString)"
    } else {
        finalURL = "https://\(urlString)"
    }
    
    guard let url = URL(string: finalURL) else { return }
    
    // Create a URL session configuration with timeout
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 10.0
    config.timeoutIntervalForResource = 15.0
    let session = URLSession(configuration: config)
    
    // Create a URL session task to fetch the page
    let task = session.dataTask(with: url) { data, response, error in
        // Handle errors gracefully
        if let error = error {
            print("Failed to fetch title for \(urlString): \(error.localizedDescription)")
            return
        }
        
        guard let data = data,
              let html = String(data: data, encoding: .utf8) else {
            print("Failed to decode HTML for \(urlString)")
            return
        }
        
        // Extract title using SwiftSoup
        let title = extractTitleWithSwiftSoup(from: html)

        // Update the item on the main thread
        DispatchQueue.main.async {
            store.updateItemTitle(itemId: item.id, title: title)
        }
    }
    
    task.resume()
}
