# StoreKit 2 Strategy: WrenchLog Pro Monetization

**Date:** 2026-03-23  
**Purpose:** Implementation strategy for mixed monetization (subscription + lifetime unlock) using StoreKit 2, informed by 2025–2026 conversion benchmarks and paywall timing research.

---

## 1. Model Comparison: What Converts Better for Utility Apps?

### The Data

**One-time purchases are growing.** One-time purchases (including lifetime plans) grew from 6.4% of app revenue in 2023 to 10.3% in 2025, signaling a shift toward upfront value. Meanwhile, annual and lifetime subscription share is declining.  
*Source: Adapty State of In-App Subscriptions 2026 (16,000+ apps, $3B+ revenue)*

**Subscription fatigue is real.** Consumers now run regular "subscription audits" and actively question recurring costs. For utilities, local tools, and apps without continuous content delivery, users increasingly prefer one-time purchases that turn open-ended obligations into predictable choices.  
*Source: Influencers Time — Subscription Fatigue 2025*

**Utility apps have strong trial conversion.** Utility apps have a median download-to-trial rate of 24.1% — one of the highest across categories. They also increased trial usage faster than any other category in 2025, going from 78.0% to 84.7%.  
*Source: Adapty 2026 Report; Mirava.io Utility Benchmarks*

**Annual plans retain well but churn at renewal.** Annual plans keep almost everyone for 12 months, but churn spikes right after the renewal point. Monthly plans see 43% retention at day 90, dropping to 17% after a year.  
*Source: Adapty State of In-App Subscriptions 2025*

**Direct paywalls often outconvert trials.** In most categories, direct paywalls (no trial) lead to higher conversion than free trials. The gap can be significant. However, trials boost LTV — users who start with a trial have LTV up to 64% higher.  
*Source: Adapty 2025 Report*

### What This Means for WrenchLog

A vehicle maintenance app is a **low-frequency utility** — users interact with it when servicing their car (every few weeks/months), not daily. This creates a specific challenge:

1. **Subscription skepticism is high** in this category. ServiceLog reviews prove it: users explicitly say "I love the one-time fee and wish more developers would have this option. I'd rather pay a higher one-time fee than a subscription."
2. **Annual churn is a risk** because the app doesn't have daily engagement hooks. Users who forget about the app between oil changes won't renew.
3. **Lifetime unlock captures maximum willingness-to-pay** from the anti-subscription segment — which is large in automotive/utility apps.

### Verdict: Hybrid Model (Annual + Lifetime)

Offer both. This isn't compromise — it's optimal:

- **Annual subscription ($14.99/yr):** Revenue-predictable path for users who want low upfront cost. Captures the "try before committing big" segment. Creates recurring revenue.
- **Lifetime unlock ($49.99):** Captures the vocal anti-subscription segment. Acts as a **decoy** that makes annual look cheap. Pays for itself vs. annual in ~3.3 years.
- **Monthly ($1.99/mo):** Exists as a low-barrier discovery option and makes annual look like a great deal (monthly = $23.88/yr vs $14.99 annual = 37% savings).

The decoy effect is well-documented: having a clearly inferior option (monthly at effective $23.88/yr) makes the annual ($14.99) feel like an obvious bargain. Meanwhile, the lifetime option captures a completely different buyer persona who would never subscribe at all.

---

## 2. StoreKit 2 Implementation: Mixed Product Types

### Product Architecture

WrenchLog needs **two product types** in StoreKit:

| Product ID | Type | StoreKit Type | Price |
|---|---|---|---|
| `com.wrenchlog.pro.monthly` | Auto-renewable subscription | `.autoRenewable` | $1.99/mo |
| `com.wrenchlog.pro.annual` | Auto-renewable subscription | `.autoRenewable` | $14.99/yr |
| `com.wrenchlog.pro.lifetime` | Non-consumable IAP | `.nonConsumable` | $49.99 |

**Key architectural point:** The subscription products live in a **Subscription Group** in App Store Connect. The lifetime product lives in the separate **In-App Purchases** section. These are fundamentally different product types in StoreKit — but they all unlock the same "Pro" entitlement.

### Entitlement Check: The Core Pattern

StoreKit 2's `Transaction.currentEntitlements` is the single source of truth. It returns both active subscriptions AND non-consumable purchases that haven't been refunded. This means a unified entitlement check is straightforward:

```swift
import StoreKit

@MainActor
class StoreManager: ObservableObject {
    @Published private(set) var isProUnlocked = false
    private var updatesTask: Task<Void, Never>?
    
    // Product IDs
    static let subscriptionIDs = ["com.wrenchlog.pro.monthly", "com.wrenchlog.pro.annual"]
    static let lifetimeID = "com.wrenchlog.pro.lifetime"
    static let allProductIDs = subscriptionIDs + [lifetimeID]
    
    init() {
        // Listen for transaction updates (renewals, purchases from other devices, etc.)
        updatesTask = Task {
            for await update in Transaction.updates {
                if let transaction = try? update.payloadValue {
                    await refreshProStatus()
                    await transaction.finish()
                }
            }
        }
        Task { await refreshProStatus() }
    }
    
    deinit { updatesTask?.cancel() }
    
    /// Single source of truth: user is Pro if they have ANY active entitlement
    func refreshProStatus() async {
        var isPro = false
        for await entitlement in Transaction.currentEntitlements {
            if let transaction = try? entitlement.payloadValue {
                if Self.allProductIDs.contains(transaction.productID) {
                    isPro = true
                    break  // One match is enough
                }
            }
        }
        self.isProUnlocked = isPro
    }
}
```

**Why this works for mixed types:** `Transaction.currentEntitlements` automatically includes:
- Non-consumable purchases (lifetime) — always present unless refunded
- Active auto-renewable subscriptions — present while subscription is valid
- Both in a single async sequence

### Fetching and Separating Products

```swift
func fetchProducts() async throws {
    let products = try await Product.products(for: Self.allProductIDs)
    
    // Separate by type using StoreKit 2's .type property
    let subscriptions = products.filter { $0.type == .autoRenewable }
    let lifetime = products.first { $0.type == .nonConsumable }
    
    // Sort subscriptions: monthly first, then annual (for paywall display)
    let sortedSubs = subscriptions.sorted { $0.price < $1.price }
}
```

### Purchase Flow

```swift
func purchase(_ product: Product) async throws -> Transaction? {
    let result = try await product.purchase()
    
    switch result {
    case .success(let verification):
        let transaction = try verification.payloadValue
        await transaction.finish()
        await refreshProStatus()
        return transaction
        
    case .userCancelled:
        return nil
        
    case .pending:
        // Ask to Buy (family sharing) — transaction comes later via .updates
        return nil
        
    @unknown default:
        return nil
    }
}
```

The purchase flow is identical for both subscriptions and non-consumables. StoreKit 2 handles the difference internally. The paywall just calls `purchase(product)` regardless of type.

### Restore Purchases

```swift
func restorePurchases() async {
    // This syncs the device's transaction history with the App Store
    try? await AppStore.sync()
    await refreshProStatus()
}
```

`AppStore.sync()` handles both subscription and non-consumable restoration. Always provide a "Restore Purchases" button — App Review requires it.

### StoreKit Configuration File (Xcode Testing)

Create `WrenchLog.storekit` with:
1. **Subscription Group** "WrenchLog Pro" containing monthly and annual products
2. **Non-consumable** product for lifetime

This enables full local testing (purchases, renewals, cancellations, refunds) without App Store Connect until you're ready for TestFlight.

Use `Debug > StoreKit > Manage Transactions` during testing. Subscription renewal is accelerated in Xcode — monthly renews in minutes, not 30 days.

### App Store Connect Setup

Two separate sections:
1. **Subscriptions** → Create group "WrenchLog Pro" → Add monthly + annual products within it
2. **In-App Purchases** → Create non-consumable "WrenchLog Pro Lifetime"

Both need: reference name, product ID, price schedule, localized display names, and review screenshots.

---

## 3. Paywall Timing: When to Show It

### General Principles (from conversion data)

**Most conversions happen during or just after onboarding.** Placing the paywall after onboarding screens is the most common high-converting pattern. Users who haven't seen value won't pay.  
*Source: AppAgent — Paywall Optimization Strategies*

**Contextual triggers outperform cold paywalls.** Showing the paywall when users attempt to access a premium feature converts better than showing it at random moments. The paywall feels justified rather than interruptive.  
*Source: Business of Apps — Paywall Optimization*

**Hard paywalls drive faster trial adoption** — 78% of users start a trial in the first week with a hard paywall vs. slower adoption with soft paywalls. But hard paywalls lose users who never try the app.  
*Source: RevenueCat State of Subscription Apps 2025*

**Shorter trials convert better for utility apps.** Most trial conversions happen on install day. Longer trials (30+ days) see 51% cancellation vs. 26% for 3-day trials. The ideal: just long enough to experience value.  
*Source: Business of Apps — Subscription Trial Benchmarks 2026*

### WrenchLog-Specific Paywall Strategy

A maintenance app has a unique timing challenge: the first "value moment" might be **weeks away** (when the user's next oil change is due). We can't rely on daily engagement hooks.

#### Recommended: Soft Paywall with Contextual Triggers

**Phase 1: Generous free onboarding (no paywall)**
- First launch → clean onboarding (3 screens: what it does, privacy promise, add your first vehicle)
- User adds their first vehicle → full free experience
- First service log entry → congratulate, reinforce value
- **No paywall shown yet.** Let users fall in love with the core experience.

**Phase 2: Contextual paywall triggers (after value is demonstrated)**

Show the paywall ONLY when the user naturally hits a Pro boundary:

| Trigger | Why It Works |
|---|---|
| Adding a 2nd vehicle | User has proven commitment. Multi-vehicle is the #1 premium gate across all competitors. Natural moment: "Upgrade to track all your vehicles." |
| Tapping "Export PDF" | User wants to generate a service report (resale value moment). High intent — they have a specific goal. |
| Tapping "Add Photo" to a service entry | User wants richer records. Low friction ask. |
| After 5th service entry | User is invested in the app. They have data they care about. |
| Attempting to set a custom reminder | User wants advanced scheduling. They've outgrown basic reminders. |

**Phase 3: Passive paywall visibility (Settings tab)**
- Always-visible "Upgrade to Pro" row in Settings
- Shows current plan status and upgrade options
- Never nags, never pops up unexpectedly

#### What NOT to Do for a Maintenance App

- ❌ **Don't show paywall on first launch.** Users haven't seen value. They'll leave.
- ❌ **Don't offer a 7-day free trial.** Users won't have a second interaction within 7 days — maintenance apps are weekly/monthly use. They'll forget and cancel.
- ❌ **Don't use a hard paywall.** The free tier needs to be genuinely useful. Hard paywalls kill retention for low-frequency apps.
- ❌ **Don't show upgrade prompts after every action.** Utility apps need to feel respectful. One nag = one lost user.

---

## 4. Paywall UI Design

### Recommended Layout

Three-option paywall with decoy pricing:

```
┌─────────────────────────────────────┐
│       Unlock WrenchLog Pro          │
│                                     │
│  ✓ Unlimited vehicles               │
│  ✓ Photo & document attachments     │
│  ✓ PDF export for resale value      │
│  ✓ Smart service reminders          │
│  ✓ Cost analytics & reports         │
│                                     │
│  ┌─────────┐ ┌──────────┐ ┌──────┐ │
│  │ Monthly │ │  Annual  │ │ Life │ │
│  │ $1.99   │ │ $14.99   │ │time  │ │
│  │ /month  │ │ /year    │ │$49.99│ │
│  │         │ │ SAVE 37% │ │ once │ │
│  │         │ │ ★ BEST   │ │      │ │
│  └─────────┘ └──────────┘ └──────┘ │
│                                     │
│     [ Continue with Annual ]        │
│                                     │
│        Restore Purchases            │
│           Terms · Privacy           │
└─────────────────────────────────────┘
```

**Key design decisions:**
- **Pre-select Annual** — it's the best revenue/retention balance
- **Show savings** — "Save 37%" on annual vs. monthly equivalent
- **"BEST VALUE" badge** on annual — anchoring
- **Lifetime visible but not highlighted** — captures anti-sub users without cannibalizing annual
- **Benefits, not features** — "PDF export for resale value" not "PDF export capability"
- **Restore Purchases** always visible (App Review requirement)
- **Terms and Privacy** links (App Review requirement)

### SwiftUI Implementation Options

**Option A: Custom paywall (recommended for v1)**
Build a native SwiftUI paywall view. Full control over design, no dependencies.

**Option B: SubscriptionStoreView (iOS 17+)**
Apple's built-in subscription UI. Handles subscription display automatically but only works for subscriptions — won't show the lifetime non-consumable alongside them. Not suitable for our mixed model.

**Option C: RevenueCat / Superwall**
Third-party paywall SDKs with remote configuration and A/B testing. Powerful but adds dependency. Consider for v2 when you have enough users to A/B test.

**Recommendation:** Start with custom SwiftUI paywall (Option A). It's straightforward for 3 products, keeps zero dependencies, and matches the "no third-party" principle. Add RevenueCat later only if you need remote paywall experimentation at scale.

---

## 5. Implementation Checklist

### StoreKit Configuration
- [ ] Create `WrenchLog.storekit` configuration file
- [ ] Add subscription group "WrenchLog Pro" with monthly + annual
- [ ] Add non-consumable "WrenchLog Pro Lifetime"
- [ ] Enable StoreKit config in scheme settings for testing

### Store Manager
- [ ] `StoreManager` class with `@Published isProUnlocked`
- [ ] Product fetching with type separation (subscriptions vs lifetime)
- [ ] Unified purchase flow (works for both types)
- [ ] `Transaction.currentEntitlements` for entitlement check
- [ ] `Transaction.updates` listener for external changes
- [ ] `AppStore.sync()` for restore purchases
- [ ] Proper `transaction.finish()` calls

### Paywall View
- [ ] Three-option layout (monthly / annual / lifetime)
- [ ] Pre-selected annual with savings badge
- [ ] Benefit-focused copy (not feature lists)
- [ ] Restore Purchases button
- [ ] Terms of Use + Privacy Policy links
- [ ] Loading states during purchase
- [ ] Error handling (purchase failed, network error)
- [ ] Success state (dismiss paywall, celebrate)

### Pro Feature Gates
- [ ] `isProUnlocked` checks at each gate point
- [ ] 2nd vehicle → paywall trigger
- [ ] Export PDF → paywall trigger
- [ ] Add Photo → paywall trigger
- [ ] Custom reminder → paywall trigger
- [ ] Graceful fallback (show what they'd get, not just "locked")

### App Store Connect
- [ ] Create subscription group + products
- [ ] Create non-consumable product
- [ ] Set pricing for all regions (US + EU focus)
- [ ] Localized display names (EN, DE, FR, ES, TR at minimum)
- [ ] Review information + screenshots for each product
- [ ] TestFlight testing with sandbox purchases

### Testing
- [ ] Local StoreKit testing: purchase monthly, annual, lifetime
- [ ] Verify entitlement after each purchase type
- [ ] Test subscription renewal (accelerated in Xcode)
- [ ] Test subscription expiry → entitlement removed
- [ ] Test lifetime + subscription coexistence
- [ ] Test restore purchases flow
- [ ] Test "Ask to Buy" (pending) flow
- [ ] Test refund → entitlement removed
- [ ] TestFlight sandbox testing before submission

---

## 6. Revenue Projections (Conservative)

Assumptions: 1,000 downloads/month after 6 months (organic + ASO), 3% conversion rate (conservative for utility apps — median download-to-paid is ~1.7% across all apps, but utility apps trend higher).

| Scenario | Monthly Revenue | Annual Revenue |
|---|---|---|
| 100% annual ($14.99) | $449/mo | $5,391/yr |
| 70% annual + 30% lifetime | $314 + $450 = $764/mo declining | ~$6,600 yr1 |
| 50/30/20 monthly/annual/lifetime | $599/mo | ~$7,190/yr |

**Key insight:** Lifetime purchases front-load revenue but taper. Annual provides steady growth. The mix is healthier than either alone. After Apple's 30% cut (15% after year 1 with Small Business Program), expect ~70-85% take-home.

Apple's **Small Business Program** applies if total proceeds are under $1M/year (they will be). This reduces commission from 30% to 15% on subscriptions after the first year of each subscriber — a significant boost to subscription revenue.

---

## Sources

1. Adapty — State of In-App Subscriptions 2026 Report (16,000+ apps, $3B+ revenue)
   https://adapty.io/state-of-in-app-subscriptions-report/

2. RevenueCat — State of Subscription Apps 2025
   https://www.revenuecat.com/state-of-subscription-apps-2025/

3. Mirava.io — 2025 Benchmarks: Utility Apps
   https://www.mirava.io/blog/subscription-benchmarks-utility-apps

4. Business of Apps — App Subscription Trial Benchmarks 2026
   https://www.businessofapps.com/data/app-subscription-trial-benchmarks/

5. Adapty — State of In-App Subscriptions 2025 (conversion, retention, LTV data)
   https://adapty.io/blog/state-of-in-app-subscriptions-2025-in-10-minutes/

6. AppAgent — 5 Paywall Optimization Strategies
   https://appagent.com/blog/mobile-app-onboarding-5-paywall-optimization-strategies/

7. RevenueCat — Essential Guide to Mobile Paywalls
   https://www.revenuecat.com/blog/growth/guide-to-mobile-paywalls-subscription-apps/

8. Business of Apps — App Paywall Optimization
   https://www.businessofapps.com/guide/app-paywall-optimization/

9. Influencers Time — Subscription Fatigue 2025
   https://www.influencers-time.com/subscription-fatigue-in-2025-why-one-time-buys-dominate/

10. ServiceLog App Store Reviews (user sentiment on pricing)
    https://apps.apple.com/us/app/car-maintenance-servicelog/id1628067059

11. BleepingSwift — StoreKit 2 for In-App Purchases and Subscriptions
    https://bleepingswift.com/blog/storekit-2-in-app-purchases-subscriptions

12. CreateWithSwift — Implementing Non-Consumable IAP with StoreKit 2
    https://www.createwithswift.com/implementing-non-consumable-in-app-purchases-with-storekit-2/

13. Apple WWDC21 — Meet StoreKit 2
    https://developer.apple.com/videos/play/wwdc2021/10114/

14. Apphud — StoreKit 2 currentEntitlements for mixed product types
    https://apphud.com/blog/storekit-2-1
