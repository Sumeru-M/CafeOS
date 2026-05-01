// MARK: - JobScraperService.swift
// Multi-strategy job description extractor.
//
// Strategy waterfall (tried in order):
//   1. ATS Direct API  — Greenhouse public JSON (fastest, most reliable)
//   2. WKWebView + JS  — JS-rendered DOM extraction (works on most ATS)
//   3. URLSession      — Plain HTTP + SwiftSoup (fast, blocked by LinkedIn/Indeed)
//   4. Instructions    — If all fail, guides user to use ScrapingBee / Browserless

import Foundation
import WebKit
import SwiftSoup

// MARK: - Result Types

struct ScrapedJob {
    var title: String
    var company: String
    var location: String
    var description: String
    var strategy: String    // Which strategy succeeded
}

enum ScraperStrategy: String {
    case atsAPI      = "ATS Direct API"
    case webView     = "WKWebView + JS DOM"
    case urlSession  = "URLSession + SwiftSoup"
    case failed      = "All strategies failed"
}

// MARK: - Service

final class JobScraperService: NSObject {

    static let shared = JobScraperService()
    private override init() { super.init() }

    // MARK: - Entry Point

    /// Attempts to extract a job description from the given URL.
    /// Tries strategies in order; returns the first success.
    func scrape(url: URL) async throws -> ScrapedJob {
        // 1. Try Greenhouse public API
        if let result = try? await scrapeGreenhouse(url: url) {
            return result
        }
        // 2. Try Lever public API
        if let result = try? await scrapeLever(url: url) {
            return result
        }
        // 3. WKWebView (runs on main thread — needs actor isolation)
        if let result = try? await scrapeWithWebView(url: url) {
            return result
        }
        // 4. Plain URLSession
        if let result = try? await scrapeWithURLSession(url: url) {
            return result
        }
        throw AppError.scrapingFailed("All strategies failed. Try ScrapingBee or Browserless APIs.")
    }

    // MARK: - Strategy 1: Greenhouse Public API

    private func scrapeGreenhouse(url: URL) async throws -> ScrapedJob {
        // Greenhouse job URLs: boards.greenhouse.io/company/jobs/123456
        guard url.host?.contains("greenhouse.io") == true else {
            throw AppError.scrapingFailed("Not a Greenhouse URL")
        }
        let parts = url.pathComponents
        guard let jobsIdx = parts.firstIndex(of: "jobs"),
              jobsIdx + 1 < parts.count,
              let jobId = Int(parts[jobsIdx + 1]) else {
            throw AppError.scrapingFailed("Could not extract Greenhouse job ID")
        }
        // Find company token
        let company = parts.first(where: { $0 != "/" && $0 != "jobs" && !parts.prefix(upTo: jobsIdx).dropFirst().isEmpty }) ?? ""
        let apiURL = URL(string: "https://boards-api.greenhouse.io/v1/boards/\(company)/jobs/\(jobId)")!

        let (data, resp) = try await URLSession.shared.data(from: apiURL)
        guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
            throw AppError.scrapingFailed("Greenhouse API returned non-200")
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AppError.scrapingFailed("Invalid JSON from Greenhouse")
        }
        let title    = json["title"]          as? String ?? "Unknown Title"
        let rawHTML  = json["content"]        as? String ?? ""
        let location = (json["location"] as? [String: Any])?["name"] as? String ?? ""
        let companyName = (json["departments"] as? [[String: Any]])?.first?["name"] as? String ?? company

        // Strip HTML tags from description
        let plainText = (try? SwiftSoup.parse(rawHTML).text()) ?? rawHTML
        return ScrapedJob(title: title, company: companyName, location: location, description: plainText, strategy: ScraperStrategy.atsAPI.rawValue)
    }

    // MARK: - Strategy 2: Lever Public API

    private func scrapeLever(url: URL) async throws -> ScrapedJob {
        guard url.host?.contains("lever.co") == true else {
            throw AppError.scrapingFailed("Not a Lever URL")
        }
        // Lever URL: jobs.lever.co/company/uuid
        let parts = url.pathComponents
        guard parts.count >= 3 else { throw AppError.scrapingFailed("Invalid Lever URL") }
        let company = parts[1]
        let jobId   = parts[2]
        let apiURL  = URL(string: "https://api.lever.co/v0/postings/\(company)/\(jobId)")!

        let (data, resp) = try await URLSession.shared.data(from: apiURL)
        guard (resp as? HTTPURLResponse)?.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AppError.scrapingFailed("Lever API error")
        }
        let title    = json["text"]      as? String ?? "Unknown"
        let location = (json["categories"] as? [String: Any])?["location"] as? String ?? ""
        let lists    = json["lists"]     as? [[String: Any]] ?? []
        let desc     = lists.map { item in
            let heading = item["text"] as? String ?? ""
            let content = item["content"] as? String ?? ""
            return "\(heading)\n\(content)"
        }.joined(separator: "\n\n")

        return ScrapedJob(title: title, company: company, location: location, description: desc, strategy: ScraperStrategy.atsAPI.rawValue)
    }

    // MARK: - Strategy 3: WKWebView

    @MainActor
    private func scrapeWithWebView(url: URL) async throws -> ScrapedJob {
        return try await WebViewScraper.scrape(url: url)
    }

    // MARK: - Strategy 4: URLSession + SwiftSoup

    private func scrapeWithURLSession(url: URL) async throws -> ScrapedJob {
        var req = URLRequest(url: url, timeoutInterval: 15)
        req.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/120 Safari/537.36", forHTTPHeaderField: "User-Agent")

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard (resp as? HTTPURLResponse)?.statusCode == 200,
              let html = String(data: data, encoding: .utf8) else {
            throw AppError.scrapingFailed("URLSession: non-200 or no body")
        }

        let doc  = try SwiftSoup.parse(html)
        let title = (try? doc.select("h1").first()?.text()) ?? url.host ?? ""

        // Try common job description selectors
        let selectors = [
            "[data-testid='job-description']",
            ".job-description",
            ".description",
            "article",
            "main"
        ]
        var description = ""
        for sel in selectors {
            if let el = try? doc.select(sel).first(), let text = try? el.text(), !text.isEmpty {
                description = text
                break
            }
        }
        if description.isEmpty { throw AppError.noContentFound }
        return ScrapedJob(title: title, company: url.host ?? "", location: "", description: description, strategy: ScraperStrategy.urlSession.rawValue)
    }
}

// MARK: - WKWebView Scraper (Runs on MainActor)

@MainActor
final class WebViewScraper: NSObject, WKNavigationDelegate {

    private var webView: WKWebView!
    private var continuation: CheckedContinuation<String, Error>?
    private var hasFinished = false

    static func scrape(url: URL) async throws -> ScrapedJob {
        let scraper = WebViewScraper()
        let html    = try await scraper.loadAndExtract(url: url)
        let doc     = try SwiftSoup.parse(html)
        let title   = (try? doc.select("h1").first()?.text()) ?? ""

        let selectors = ["[data-testid='job-description']", ".job-description", ".description", "article", "main"]
        var desc = ""
        for sel in selectors {
            if let el = try? doc.select(sel).first(), let t = try? el.text(), !t.isEmpty {
                desc = t; break
            }
        }
        if desc.isEmpty { throw AppError.noContentFound }
        return ScrapedJob(title: title, company: url.host ?? "", location: "", description: desc, strategy: ScraperStrategy.webView.rawValue)
    }

    private func loadAndExtract(url: URL) async throws -> String {
        let config = WKWebViewConfiguration()
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 375, height: 812), configuration: config)
        webView.navigationDelegate = self

        return try await withCheckedThrowingContinuation { cont in
            self.continuation = cont
            self.webView.load(URLRequest(url: url))
            // Timeout after 20 s
            DispatchQueue.main.asyncAfter(deadline: .now() + 20) { [weak self] in
                guard let self, !self.hasFinished else { return }
                self.hasFinished = true
                self.continuation?.resume(throwing: AppError.scrapingFailed("WKWebView timed out"))
            }
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard !hasFinished else { return }
        // Small delay to let JS render fully
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self, !self.hasFinished else { return }
            self.hasFinished = true
            webView.evaluateJavaScript("document.documentElement.outerHTML") { result, error in
                if let html = result as? String {
                    self.continuation?.resume(returning: html)
                } else {
                    self.continuation?.resume(throwing: AppError.scrapingFailed(error?.localizedDescription ?? "JS eval failed"))
                }
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        guard !hasFinished else { return }
        hasFinished = true
        continuation?.resume(throwing: AppError.scrapingFailed(error.localizedDescription))
    }
}
