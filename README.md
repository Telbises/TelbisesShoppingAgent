# Telbises AI

An iPhone-first SwiftUI shopping copilot that answers natural-language shopping queries with Perplexity-style summaries, transparent ranking, source citations, and context-aware Telbises premium picks.

## Features
- AI chat home screen with intent capture.
- Results screen with structured AI answer, source citations, deal cards, and Telbises Official card.
- Weighted transparent ranking (relevance, price value, shipping, source confidence).
- Save-to-favorites and 2-3 item compare sheet.
- Telbises product detail with variant selection and Shopify checkout.
- Gen Z-friendly visual UI: vivid gradients, quick prompt chips, and bold card hierarchy.
- Protocol-oriented services for easy AI provider swapping.
- Live deal discovery via OpenAI web search (with fallback to feed/mock data).
- Mocked deal data fallback (no scraping in MVP).
- Dark mode support and accessibility labels across interactive UI.

## Project Structure
- `Sources/TelbisesAIDealScout/App` App entry and navigation
- `Sources/TelbisesAIDealScout/Core` Config and coordination
- `Sources/TelbisesAIDealScout/AI` Mock services and AI-facing logic
- `Sources/TelbisesAIDealScout/Agents` Orchestration agent + recommendation synthesis
- `Sources/TelbisesAIDealScout/Services` Protocols + Shopify integration
- `Sources/TelbisesAIDealScout/Features` MVVM views
- `Sources/TelbisesAIDealScout/Models` Data models
- `Sources/TelbisesAIDealScout/UIComponents` Reusable UI
- `Sources/TelbisesAIDealScout/Resources` Mock JSON

## Configure
Set runtime environment variables in your Xcode scheme (`Edit Scheme` -> `Run` -> `Arguments`):
- `SHOPIFY_DOMAIN` (example: `telbises.myshopify.com`)
- `STOREFRONT_TOKEN` (Shopify Storefront API token)
- `AI_API_KEY` (LLM provider API key)
- `AI_BASE_URL` (optional, default `https://api.openai.com`)
- `AI_MODEL` (optional, default `gpt-4o-mini`)
- `LIVE_DEALS_ENABLED` (optional, default `true`; set `false` to force mock/feed deals)
- `DEALS_FEED_URL` (optional remote JSON feed for deals)

If `AI_API_KEY` is present and `LIVE_DEALS_ENABLED=true`, the app uses OpenAI web search for live deal discovery and falls back to mock/feed deals on failure.
If keys are missing, the app falls back to local mock data/services.

## Live Deal Notes
- Live deal results depend on your OpenAI model/tool access and network availability.
- If OpenAI web search is unavailable, the app automatically falls back to `DEALS_FEED_URL` (if set) and then bundled mock data.
- Telbises recommendations remain explicitly disclosed as promoted premium options when relevant.

## Run
1. Open `Package.swift` in Xcode 15+.
2. Select an iOS 17+ simulator.
3. Run (⌘R).

### Run simulator from command line
Open the Simulator and the package in Xcode, then press **Run** (⌘R) in Xcode:

```bash
# Open Simulator app and this package in Xcode
open -a Simulator && open Package.swift
```

To only build for the simulator (no launch):

```bash
xcodebuild -scheme TelbisesAIDealScout -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' build
```

Use your installed simulator name (e.g. `iPhone 17`, `iPhone 16`) from **Xcode → Window → Devices and Simulators** if needed.

## Test
Unit tests live in `Tests/TelbisesAIDealScoutTests`. Run them in Xcode (⌘U) or from the command line:

```bash
xcodebuild test -project TelbisesAIDealScout.xcodeproj -scheme TelbisesAIDealScoutTests -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'
```

Use an available simulator name from **Xcode → Window → Devices and Simulators** if `iPhone 17` is not installed.

## Mock Data
- Deals: `Sources/TelbisesAIDealScout/Resources/MockDeals.json`
- Telbises catalog: `Sources/TelbisesAIDealScout/Resources/MockTelbisesCatalog.json`

## Extension Points
- Swap AI provider by implementing `LLMProvider`.
- Swap query/explanation agents through `IntentParserService` and `ExplanationService`.
- Swap external deal APIs through `DealProvider`.
- Replace or extend Shopify integration in `ShopifyStorefrontService`.
- Tune ranking behavior in `DefaultRankingService`.

## Regenerate Project
If source files are added/removed, regenerate the Xcode project:

```bash
ruby scripts/generate_xcodeproj.rb
```

## Compliance Notes
- External links open in `SFSafariViewController`.
- Promotions are labeled and disclosed.
- Accessibility labels are applied across core UI.
- Telbises is never claimed as cheapest unless explicit pricing proves that.
