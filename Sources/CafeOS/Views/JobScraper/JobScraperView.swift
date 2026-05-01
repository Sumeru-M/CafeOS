// MARK: - JobScraperView.swift
// Job description extractor with multi-strategy waterfall approach.

import SwiftUI

struct JobScraperView: View {
    @State private var urlText      = ""
    @State private var isLoading    = false
    @State private var result:       ScrapedJob?   = nil
    @State private var errorMsg:     String?        = nil
    @State private var showApproach = false

    private let scraper = JobScraperService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection

                // URL Input
                urlInputSection

                // Result or loading
                if isLoading { loadingSection }
                else if let result { ResultView(job: result) }
                else if let err    { errorSection(err) }

                // Strategy explanation (always visible)
                strategyExplanation
            }
            .padding(AppLayout.padding)
        }
        .navigationTitle("Job Lookup")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Sub-views

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("🔍")
                .font(.system(size: 44))
            Text("Extract Job Descriptions")
                .font(AppFonts.heading(20))
            Text("Paste any job URL — we'll try multiple strategies to fetch the content.")
                .font(AppFonts.body_(14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AppLayout.padding)
        .cardStyle()
    }

    private var urlInputSection: some View {
        VStack(spacing: 12) {
            CafeTextField(
                title: "Job URL",
                placeholder: "https://boards.greenhouse.io/…",
                text: $urlText,
                keyboardType: .URL,
                error: errorMsg != nil && result == nil ? errorMsg : nil
            )
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)

            PrimaryButton(title: "Extract Job", icon: "arrow.down.circle",
                         isLoading: isLoading) { scrape() }
        }
    }

    private var loadingSection: some View {
        VStack(spacing: 12) {
            ProgressView().scaleEffect(1.3).tint(.cafeCaramel)
            Text("Trying extraction strategies…")
                .font(AppFonts.body_(14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .cardStyle()
    }

    private func errorSection(_ msg: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
            Text(msg).font(AppFonts.body_(14)).foregroundColor(.primary)
        }
        .padding(AppLayout.padding)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(AppLayout.cardRadius)
    }

    private var strategyExplanation: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { withAnimation(.spring()) { showApproach.toggle() } }) {
                HStack {
                    Image(systemName: "info.circle").foregroundColor(.cafeCaramel)
                    Text("Extraction Approach & Limitations")
                        .font(AppFonts.heading(15))
                    Spacer()
                    Image(systemName: showApproach ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding(AppLayout.padding)
            }
            if showApproach {
                VStack(alignment: .leading, spacing: 12) {
                    ApproachRow(number: "1", title: "ATS Direct API ✅",
                                body: "Greenhouse and Lever expose public JSON APIs. We hit these first — fastest and most reliable. Works without auth.",
                                color: .cafeSage)
                    ApproachRow(number: "2", title: "WKWebView + JS DOM ✅",
                                body: "Load the page in a hidden WKWebView (full JS rendering), wait 1.5s, inject JS to extract outerHTML, then parse with SwiftSoup. Works on Workday, BambooHR, and most ATS platforms.",
                                color: .cafeCaramel)
                    ApproachRow(number: "3", title: "URLSession + SwiftSoup ⚠️",
                                body: "Simple HTTP GET with a browser User-Agent. Fast, but blocked by LinkedIn (999), Indeed (403), and Naukri (CAPTCHA).",
                                color: .orange)
                    ApproachRow(number: "4", title: "Third-Party API (Not Implemented) 💡",
                                body: "ScrapingBee, Browserless.io, or Diffbot handle bot protection via headless Chrome. Requires paid API key. Best production option for blocked sites.",
                                color: .secondary)
                }
                .padding([.horizontal, .bottom], AppLayout.padding)
            }
        }
        .cardStyle()
    }

    // MARK: - Scrape Action

    private func scrape() {
        errorMsg = nil
        result   = nil
        guard let url = URL(string: urlText.trimmingCharacters(in: .whitespacesAndNewlines)),
              url.scheme == "https" else {
            errorMsg = "Please enter a valid HTTPS URL."
            return
        }
        isLoading = true
        Task {
            do {
                let job = try await scraper.scrape(url: url)
                result = job
            } catch let e as AppError {
                errorMsg = e.localizedDescription
            } catch {
                errorMsg = error.localizedDescription
            }
            isLoading = false
        }
    }
}

// MARK: - ResultView

struct ResultView: View {
    let job: ScrapedJob
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Success header
            HStack {
                Image(systemName: "checkmark.circle.fill").foregroundColor(.cafeSage)
                Text("Extracted via: \(job.strategy)")
                    .font(AppFonts.body_(13))
                    .foregroundColor(.cafeSage)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(job.title).font(AppFonts.display(20))
                if !job.company.isEmpty  { Text(job.company).font(AppFonts.body_(15)).foregroundColor(.secondary) }
                if !job.location.isEmpty { Text("📍 \(job.location)").font(AppFonts.body_(14)).foregroundColor(.cafeCaramel) }
            }
            Divider()
            Text(job.description)
                .font(AppFonts.body_(14))
                .textSelection(.enabled)
            // Copy button
            Button(action: {
                UIPasteboard.general.string = job.description
                withAnimation { copied = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
            }) {
                Label(copied ? "Copied!" : "Copy Description", systemImage: copied ? "checkmark" : "doc.on.doc")
                    .font(AppFonts.heading(14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20).padding(.vertical, 10)
                    .background(copied ? Color.cafeSage : Color.cafeCaramel)
                    .cornerRadius(20)
            }
        }
        .padding(AppLayout.padding)
        .cardStyle()
    }
}

// MARK: - ApproachRow

struct ApproachRow: View {
    let number: String
    let title: String
    let body: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(AppFonts.heading(13))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(color)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(AppFonts.heading(14))
                Text(body).font(AppFonts.body_(13)).foregroundColor(.secondary)
            }
        }
    }
}
