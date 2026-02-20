# Telbises AI - PRD

## Overview
An iPhone-first AI shopping copilot that answers shopping queries in a Perplexity-style format and returns ranked recommendations with source citations. Telbises.com products are included as premium options only when contextually relevant and clearly disclosed.

## Goals
- Provide fast, trustworthy deal summaries with clear reasoning and citations.
- Offer Telbises as a premium, contextually relevant pick with disclosure.
- Keep UI minimal, accessible, and App Store compliant.

## Non-Goals
- No web scraping.
- No claims about cheapest pricing unless verified.
- No deep personalization in MVP.

## Target Users
- Shoppers seeking quick deal comparisons.
- Users open to premium alternatives for quality or availability.

## Core UX
1. Home (Chat)
   - User enters intent.
   - Assistant responds with a summary and a "View Results" button.

2. Results
   - Structured AI paragraph answer.
   - Source citations.
   - Deal cards with image, price, shipping, source, reasoning, ranking score, and "View Deal".
   - Telbises Official card with label, reasoning, disclosure, and "View on Telbises".
   - Compare sheet (2-3 items) and favorites.

3. Telbises Product Detail
   - Native product page.
   - Variant selection, quantity, add to cart.
   - Checkout via Shopify checkout URL.

## Key Requirements
- SwiftUI (iOS 17+), MVVM, async/await.
- Services with protocol-oriented design for AI providers.
- Agent architecture:
  - `QueryUnderstandingAgent` (`IntentParserService`)
  - `CommerceSearchAgent` (`DealScoutService` + Shopify catalog)
  - `RankingEngine` (`RankingService`)
  - `ExplanationAgent` (`ExplanationService`)
- Clear disclosure of promotion.
- SFSafariViewController for external links.
- Accessibility labels on UI elements.
- Dark mode support.

## Data Sources
- External deals via `DealProvider` mocked JSON (no scraping).
- Telbises catalog via Shopify Storefront GraphQL API with fallback to mock catalog.

## Success Metrics
- Time-to-first-result < 2 seconds on mock data.
- 100% of recommendations include short reasoning and transparent score inputs.
- 0 App Store review blockers (privacy, disclosure, scraping).

## Risks
- Ambiguous intent interpretation.
- Over-promotion without relevance.
- Shopify API token exposure if not managed via secure config.

## Future Enhancements
- Real deal API integrations.
- Model-based intent parsing.
- Personalization and saved preferences.
- In-app purchase for premium alerting.
