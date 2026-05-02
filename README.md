# **CaféOS**

> A production-quality iOS café management app built with SwiftUI, Firebase Firestore, and an on-device AI stock prediction engine.

![Platform](https://img.shields.io/badge/platform-iOS%2016%2B-blue)
![Swift](https://img.shields.io/badge/swift-5.9-orange)
![Architecture](https://img.shields.io/badge/architecture-MVVM-green)
![Firebase](https://img.shields.io/badge/backend-Firebase%20Firestore-yellow)


# Screenshots

| Inventory List | AI Insights | Add Item | Job Scraper |
|---|---|---|---|
| Real-time list with low-stock badges | Predicted depletion cards | Form with inline validation | Multi-strategy URL extractor |

# Features

# Inventory Management (Full CRUD)
- Add, view, edit, delete inventory items
- Fields: name, quantity, unit, reorder threshold, price, category, notes, last updated
- Real-time Firestore sync via Combine listener
- Search, multi-category filter, and 4 sort options
- Swipe-to-delete, swipe-to-edit actions
- Low-stock badge on Tab Bar and in-list banner

# AI Feature — Smart Low-Stock Prediction
- **Algorithm**: On-device least-squares linear regression over usage history
- Every quantity change is recorded as a `UsageSnapshot` in Firestore
- Predicts days until depletion: *"Milk will run out in ~2 days"*
- 3-tier severity: Critical (≤2 days) / Warning (≤5 days) / OK
- Confidence score based on number of data points (caps at 14)
- Zero external API dependencies — runs entirely on-device

# Firebase Auth
- Anonymous sign-in (one tap, no credentials)
- Email/password sign-in and account creation
- Anonymous → email upgrade path (preserves all data)

Job Description Extractor
Multi-strategy waterfall approach (see below).


# Architecture: MVVM

```
CafeOS/
├── Models/           # Pure data structures, Codable, no logic
│   ├── InventoryItem.swift
│   ├── UsageSnapshot.swift
│   ├── StockInsight.swift
│   └── AppError.swift
├── ViewModels/       # Business logic, state, calls Services only
│   ├── AuthViewModel.swift
│   ├── InventoryViewModel.swift
│   └── InsightsViewModel.swift
├── Views/            # Pure SwiftUI, binds to ViewModels
│   ├── Auth/LoginView.swift
│   ├── Inventory/{List,Detail,AddEdit,Row}View.swift
│   ├── Insights/InsightsDashboardView.swift
│   ├── JobScraper/JobScraperView.swift
│   ├── SettingsView.swift
│   ├── MainTabView.swift
│   └── Common/CommonViews.swift
├── Services/         # Firebase, AI, Scraping — zero UI awareness
│   ├── FirestoreService.swift
│   ├── AuthService.swift
│   ├── AIInsightService.swift
│   └── JobScraperService.swift
├── Utilities/
│   ├── Constants.swift
│   └── Extensions.swift
└── App/CafeOSApp.swift
```

# Data Flow
```
View → ViewModel → Service → Firebase/AI
         ↑                      ↓
    @Published            Combine/async
```


# Firestore Structure

```
/inventory/{itemId}
  ├── name: String
  ├── quantity: Double
  ├── unit: String          ("kg" | "L" | "units" | …)
  ├── threshold: Double
  ├── price: Double
  ├── category: String
  ├── notes: String
  └── lastUpdated: Timestamp

/inventory/{itemId}/history/{snapshotId}
  ├── itemId: String
  ├── quantity: Double
  └── timestamp: Timestamp
```


# AI Feature: Low-Stock Prediction Engine

# How It Works

1. **Data Collection**: Every time an item's quantity changes, a `UsageSnapshot` is written to Firestore under `/inventory/{itemId}/history/`.

2. **Trend Analysis** (in `AIInsightService.swift`):
   - Fetch the last 14 snapshots per item
   - Map to `(days_elapsed, quantity)` coordinate pairs
   - Apply **least-squares linear regression** to find the slope

3. **Prediction**:
   ```
   avgDailyUsage = -slope (clamp to ≥ 0)
   daysUntilEmpty = currentQuantity / avgDailyUsage
   ```

4. **Severity Classification**:
   | Condition | Severity |
   |-----------|----------|
   | quantity ≤ threshold OR days ≤ 2 |  Critical |
   | days ≤ 5 OR quantity < 2× threshold |  Warning |
   | Otherwise |  OK |

5. **Confidence Score**: `min(snapshotCount / 14, 1.0)` — shown to the manager so they know how reliable the prediction is.

# Example Output
> " Whole Milk will run out in ~3 days based on usage trends."  
> Confidence: 71% (10 data points) · Daily use: 1.17 L/day


# Job Description Scraper

### The Challenge
Sites like LinkedIn, Indeed, and Naukri use bot protection (CAPTCHA, login walls, JS rendering) that blocks simple HTTP requests.

# Strategy Waterfall

| # | Strategy | How | Result |
|---|----------|-----|--------|
| 1 | **ATS Direct API** | Greenhouse & Lever expose free public JSON APIs | Works reliably |
| 2 | **WKWebView + JS DOM** | Hidden WKWebView fully renders JS, inject JS to extract `outerHTML`, parse with SwiftSoup | Works for most ATS (Workday, BambooHR) |
| 3 | **URLSession + SwiftSoup** | HTTP GET with browser User-Agent, parse HTML | Blocked by LinkedIn (999), Indeed (403), Naukri (CAPTCHA) |
| 4 | **Third-Party API** | ScrapingBee / Browserless.io headless Chrome | Works but requires paid key — documented, not hard-coded |

# What Failed & Why
- **URLSession alone**: LinkedIn returns HTTP 999 (custom block code); Indeed returns 403. No session cookies = rejected.
- **WKWebView on LinkedIn**: Login wall before job description. JS extraction works but returns the login page content.
- **ATS APIs**: Only Greenhouse and Lever have public APIs. Workday, Taleo have no public endpoint.

# Live Demo URL (works without auth)
```
https://boards.greenhouse.io/segment/jobs/5852955
```
Paste this into the Job Lookup tab — it uses Strategy 1 (Greenhouse API) and returns full job details instantly.


# Setup Instructions

# Prerequisites
- Xcode 15+
- iOS 16+ Simulator or device
- A Firebase project (free tier sufficient)

# 1. Clone the Repo
```bash
git clone https://github.com/YOUR_USERNAME/CafeOS.git
cd CafeOS
```

# 2. Create Firebase Project
1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Create a new project → Add iOS app
3. Bundle ID: `com.yourname.CafeOS`
4. Download `GoogleService-Info.plist`
5. Place it in `CafeOS/` (same level as `Package.swift`)

# 3. Enable Firebase Services
In Firebase Console:
- **Firestore Database** → Create in test mode
- **Authentication** → Enable Anonymous + Email/Password

# 4. Open in Xcode
```bash
open Package.swift
```
Xcode will resolve SPM dependencies automatically (Firebase + SwiftSoup).

# 5. Add `GoogleService-Info.plist` to Target
In Xcode → Project Navigator → drag `GoogleService-Info.plist` into the CafeOS target group.

# 6. Run
Select an iOS 16+ simulator → ▶ Run (⌘R)

# 7. Populate Demo Data
Tap **"+ Add Item"** and create a few items. Change quantities multiple times to build usage history for AI predictions. Then visit the **Insights** tab.


# Running Without Firebase (Demo Mode)

The app will crash on launch without `GoogleService-Info.plist`. For a quick demo without Firebase:

1. Comment out `FirebaseApp.configure()` in `CafeOSApp.swift`
2. In `InventoryViewModel.swift`, replace the `startListening()` body with:
   ```swift
   items = InventoryItem.previewItems
   isLoading = false
   ```
3. The app will run with mock data, all UI features visible.

# Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| [firebase-ios-sdk](https://github.com/firebase/firebase-ios-sdk) | 10.24+ | Firestore + Auth |
| [SwiftSoup](https://github.com/scinfu/SwiftSoup) | 2.7+ | HTML parsing for job scraper |


# License

MIT © 2024
