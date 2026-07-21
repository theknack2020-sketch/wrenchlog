# WrenchLog Pricing — Decision Record

Date: 2026-07-21 · Owner-law: bespoke, evidence-based, ≤90-day freshness · Decided autonomously (monetization-pricing-autonomy).

## Current products (verified live via ASC API, 2026-07-21)

| Product | ID | Type | US price | State |
|---|---|---|---|---|
| Yearly Pro | `com.theknack.wrenchlog.pro.yearly` | Auto-renew sub (1 yr), 7-day free trial | **$14.99/yr** (proceeds $10.50 → $12.74 yr2) | APPROVED |
| Lifetime Pro | `com.theknack.wrenchlog.pro.lifetime` | Non-consumable | **$49.99** (proceeds $35.00) | APPROVED |

## Competitive evidence (live scan, `asc apps public search "car maintenance"` + App Store pages, 2026-07-21)

- **Whole top-25 is free + IAP.** No paid-up-front survivors.
- **CARFAX Car Care** (125k ratings) & **Fuelly** (29k) — free, data/ads-subsidized. Compete on privacy, not price.
- **Motorist (Edovia)** — closest premium indie analog: **$3.49/mo (~$42/yr-equiv)**, annual tier with free trial; review complaints say "pricing a bit high" and free tier too thin.
- **Simply Auto / MyAutoLog / Car Cave** — freemium subs; IAP sheets not exposed server-side (page-level check).

## Own funnel evidence (ASC, 2026-07-20 analiz)

- Downloads: Apr 12 → May 17 → Jun 22 (only growing app in portfolio).
- Revenue: 1× Yearly ($10.50 proceeds) + 2 trial starts → funnel converts at current price.
- 0 ratings yet → no social proof to support a premium-price experiment today.

## Decision

1. **Yearly Pro stays $14.99/yr** (with 7-day trial). Rationale: ~⅓ of Motorist's monthly-equivalent while our feature depth (VIN decoder + NHTSA recalls + health score + PDF/CSV) exceeds it; the funnel already converts; repricing the portfolio's only growing app mid-momentum adds noise for no expected upside.
2. **Lifetime Pro stays $49.99** — 3.3× yearly, inside the healthy 2.5–4× band; anchors the yearly as the "sensible" choice.
3. **Free tier stays 2 vehicles** — proven acquisition wedge; competitors' too-thin free tiers are their top review complaint.

## Next review triggers (whichever first)

- ≥10 ratings land (social proof unlocks a $19.99/yr test), or
- monthly downloads >100, or
- 2026-10-19 (90-day freshness expiry).

Planned experiment then: A/B $14.99 vs $19.99 yearly via paywall cohort; consider $4.99 monthly tier only if trial-start volume stalls.
