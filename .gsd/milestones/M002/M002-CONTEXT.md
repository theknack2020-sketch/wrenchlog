# M002 Context — MVP Build

## Goal
Build WrenchLog v1.0 — a privacy-first, ad-free vehicle maintenance tracker for iOS, targeting US + EU car owners.

## Scope
- Add vehicles (make, model, year, odometer, photo)
- Log maintenance with 22 preloaded service types + custom
- Service history timeline per vehicle
- Reminders by date AND mileage (dual-trigger, whichever first)
- Cost summary (total, by category, monthly/yearly charts)
- Unit toggle (miles/km, USD/EUR/GBP)
- Photo attachments to service records (Pro)
- PDF service history export (Pro)
- IAP: $14.99/yr + $49.99 lifetime
- No ads, no tracking, no account required
- Dark-mode support, amber/charcoal theme

## NOT in Scope (v1.1+)
- Fuel tracking & MPG calculation
- iCloud sync
- VIN decoder
- Widgets
- EV-specific features (battery health)
- Apple Watch

## Monetization Strategy
- **Free tier**: 1 vehicle (fully featured), all service logging, basic reminders, basic cost stats, no ads
- **Pro** ($14.99/yr or $49.99 lifetime): Unlimited vehicles, photo attachments, PDF/CSV export, advanced analytics, custom service categories
- **Why this works**: ServiceLog proves $24.99/yr + $69.99 lifetime converts. We undercut them. Car Cave proves anti-subscription users exist — lifetime option captures them.

## Constraints
- iOS 17+ (SwiftData)
- SwiftUI + SwiftData + StoreKit 2
- Bundle ID: com.theknack.wrenchlog
- Team ID: 99H9NJ6Z6J
- No third-party dependencies
- Privacy: "Data Not Collected" label
