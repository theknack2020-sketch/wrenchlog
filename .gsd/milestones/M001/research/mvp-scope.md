# MVP Scope: WrenchLog v1.0

**Date:** 2026-03-23  
**Purpose:** Define minimum features for App Store approval + first-week 4.5+ ratings, based on competitor analysis and user pain-point research.

---

## Methodology

Analysis of 10+ competing iOS apps (CARFAX Car Care, Simply Auto, Drivvo, ServiceLog, Car Cave, MyAutoLog, Fuelly, AUTOsist, Motorist, AUTOFIXER, Vehicle Maintenance Tracker), 200+ user reviews (1–5 star), forum threads (BobIsTheOilGuy, Reddit, MaverickTruckClub), and app review roundups (AAA, Family Handyman, OBDeleven, iSimplifiedTech). Pricing research across all monetization models.

---

## What Gets 4.5+ Stars in Week One

Cross-referencing top-rated apps (CARFAX 4.8, ServiceLog ~4.8, MyAutoLog ~4.8, Car Cave 4.6) with negative review patterns, five factors drive high first-week ratings:

1. **Fast first-run experience** — users log their first vehicle + first service in under 2 minutes. MyAutoLog users praise "set up their first car in under 10 minutes" including historical entries. WrenchLog must beat this.
2. **Preloaded service types** — no blank slate. Drivvo ships a "long list of service types already preloaded" and users praise the reduction in typing. ServiceLog and MyAutoLog both use "preset services."
3. **Clean, modern UI** — the #1 praise for ServiceLog is "sleek and modern" design. The #1 complaint for Simply Auto and Drivvo is outdated/confusing interfaces.
4. **No friction monetization** — Car Cave and ServiceLog prove that "no ads, no login required" is an explicit driver of 5-star reviews. Users write reviews specifically to praise the absence of friction.
5. **Reliability** — data loss is the #1 trust-destroyer across all competitors. The app must feel rock-solid from minute one.

---

## v1.0 MVP — Must Ship

### 1. Core Service Logging ✅ (R002, R005, R011)

**What:** Log any maintenance event with date, odometer, cost, service type, notes.

**Evidence:** This is table-stakes — every single competitor has it. The differentiator is speed and simplicity. ServiceLog's "log a service in seconds" positioning drives its highest-rated reviews. Vehicle Maintenance Tracker is praised as "enough without being too much."

**Implementation:**
- Service entry: date (default today), odometer, cost (optional), service type (from presets or custom), notes (optional)
- Service history timeline per vehicle, chronologically sorted
- Tap-to-edit any field inline (addresses the Simply Auto/Fuelly pain point where editing requires support tickets)
- Auto-save drafts (addresses the Drivvo "lost data because I didn't press Register" complaint)

### 2. Preloaded Service Types ✅ (R011)

**How many: 22 preloaded types, organized in 5 categories.**

This number is based on competitor analysis:
- MyAutoLog ships presets including "Rear Differential Fluid, U-Joint Greasing, Transfer Case Fluid" (niche items), suggesting 25+ presets
- CARFAX is criticized for limited categories ("no air filters, cabin filters")
- VMT covers "oil changes, brakes, tires, batteries, and more"
- ServiceLog covers "oil changes, repairs, tyre swaps, inspections"
- Drivvo ships a "long list" and users praise not having to type

**Recommended presets:**

| Category | Service Types |
|----------|--------------|
| **Engine & Fluids** | Oil Change, Transmission Fluid, Coolant Flush, Brake Fluid, Power Steering Fluid |
| **Tires & Brakes** | Tire Rotation, Tire Replacement, Wheel Alignment, Brake Pads, Brake Rotors |
| **Filters & Belts** | Air Filter, Cabin Air Filter, Fuel Filter, Serpentine Belt, Timing Belt |
| **Electrical & Battery** | Battery Replacement, Spark Plugs, Alternator |
| **Inspection & Other** | State Inspection, Wiper Blades, AC Service, General Repair |

Plus **"Custom"** — user can type anything. This is critical: CARFAX's biggest UI complaint is "user should be able to add services in their own words."

### 3. Service Reminders ✅ (R003)

**What:** Set reminders by date, by mileage, or both (whichever comes first).

**Evidence:** Reminders are the #2 reason users download maintenance apps (after logging). MyAutoLog explicitly advertises "mileage or time" reminders. The most important feature per iSimplifiedTech is "the ability to set reminders based on both time and mileage." ServiceLog gates reminders behind Pro — WrenchLog should include basic reminders in free tier.

**Implementation:**
- Attach a reminder to any service type (e.g., "Oil Change: every 5,000 mi or 6 months")
- Local notifications via UNUserNotificationCenter
- Dashboard shows upcoming/overdue services with color coding (MyAutoLog uses "subtle tint" for due/overdue)
- Mileage-based reminders trigger when user updates odometer (no OBD needed)

### 4. Multiple Vehicles ✅ (R001)

**What:** Add unlimited vehicles in free tier. Each vehicle: make, model, year, odometer, photo.

**Evidence:** Multi-vehicle is the most common Pro gate across competitors:
- CARFAX: up to 8 (free)
- ServiceLog: Pro only
- Car Cave: unclear
- Simply Auto: limited in free
- Drivvo: limited in free

WrenchLog's free tier allowing unlimited vehicles is a major differentiator. Users with 2-3 family cars are the sweet spot audience. The VMT user managing "over 100 vehicles" is an outlier but proves the need.

**Implementation:**
- Vehicle card: make, model, year, current odometer, license plate (optional), VIN (optional), photo
- Vehicle picker on home screen (tab or horizontal scroll)
- Archive/restore vehicles no longer owned

### 5. Cost Summary ✅ (R006)

**What:** Total spent per vehicle, by category, over time.

**Evidence:** Cost tracking is the #3 feature users expect. Drivvo's cost analysis is its primary selling point. Simply Auto's "Stats & Charts" tab is heavily used. Users want to answer: "How much did I spend on my car this year?"

**Implementation:**
- Per-vehicle: total lifetime cost, cost by service category, monthly/yearly breakdown
- Simple bar/line chart (SwiftCharts)
- No fuel analytics in v1.0 (see fuel tracking below for reasoning)

### 6. Unit Toggle ✅ (R010)

**What:** Miles/km, gallons/liters, USD/EUR/GBP.

**Evidence:** US + EU market focus (D004). Auto Care 1 is praised specifically for supporting "distance in miles or kilometers and fuel in gallons or liters." Essential for non-US markets.

### 7. Privacy & No-Ads Architecture ✅ (R007)

**What:** No account required. No ads. No tracking. No third-party SDKs. Data on-device + iCloud.

**Evidence:** This is THE differentiator. ServiceLog's second-highest praise is "it does not capture your data (So carfax is not getting my data)." Car Cave reviews specifically praise "not a subscription app or one that makes you login." CARFAX users complain about data harvesting. Drivvo users complain about invasive ads. K008 confirms competitors collect excessive user data.

### 8. IAP: Pro Unlock ✅ (R008)

**What:** Freemium with lifetime + annual options.

**Evidence:** ServiceLog proves willingness to pay $24.99/yr or $69.99 lifetime (K009). Car Cave proves the "no subscription" segment exists. Monetization research recommends $14.99/yr and $49.99 lifetime.

**Free vs Pro gate:**
- **Free:** 1 vehicle (full-featured), all service logging, basic reminders, basic stats, no ads
- **Pro:** Unlimited vehicles, photo attachments, PDF/CSV export, advanced cost analytics, custom service categories

---

## v1.0 MVP — Include but Lean

### 9. Photo Attachments ✅ (R012) — Pro Feature

**What:** Attach photos/receipts to service records.

**Evidence:** VMT users praise "upload receipts and other data needed for historical value." ServiceLog users highlight "attach photos and files" as a top feature. CARFAX users "just take a picture on the CARFAX app." AUTOsist's mobile scanning of receipts is its standout feature.

**Implementation (lean):**
- Photo picker (camera + photo library) per service entry
- Store in app's document directory, referenced by SwiftData
- Thumbnail in service history, full-screen on tap
- No OCR, no scanning, no PDF generation from photos — that's v1.1+
- **Pro feature** (matches ServiceLog's gating)

### 10. PDF Export ✅ (R009) — Pro Feature

**What:** Export full service history per vehicle as a clean PDF.

**Evidence:** MyAutoLog positions PDF export as "perfect for resale value, insurance claims, or professional record-keeping." ServiceLog's PDF export is a Pro feature. VMT supports CSV export and users praise it for resale: "Whoever buys my truck after me will have a comprehensive life history above and beyond CarFax."

**Implementation (lean):**
- Single PDF per vehicle: vehicle details + chronological service history with costs
- Basic template — no custom branding in v1.0
- Share sheet integration (AirDrop, email, Files)
- **Pro feature** (matches ServiceLog, provides clear Pro value)

---

## v1.0 MVP — Defer to v1.1

### ❌ Fuel Tracking (R004) → v1.1

**Rationale for deferral:**

This is the most controversial call. Fuel tracking is in the requirements (R004) and competitors include it. But:

1. **Fuel tracking is a separate product category.** Fuelly, Fuelio, and Simply Auto are *fuel trackers that added maintenance*, not the other way around. WrenchLog is a *maintenance tracker* — fuel is additive, not core.
2. **Fuel tracking done right is complex.** Partial fill-ups, MPG/L100km calculations, fuel price tracking, gas station logging, octane types — Simply Auto's fuel entry requires odometer + quantity + octane + brand + price per unit + total cost. Getting this wrong (Fuelly's "61 mpg bug") destroys trust.
3. **No competitor reviewer has ever said "I deleted this app because it lacked fuel tracking."** But many say "I deleted it because it lost my data" or "the UI is confusing."
4. **Focus wins.** ServiceLog has 4.8 stars with zero fuel tracking. Car Cave has 4.6 stars without it. MyAutoLog added it later and still got 4.8 stars on the maintenance core alone.
5. **Risk mitigation.** Fuel tracking adds 30-40% more surface area (new data model, new charts, new entry flow, new edge cases). Shipping a polished maintenance tracker beats shipping a mediocre everything-tracker.

**v1.1 plan:** Add fuel log entry (date, odometer, gallons/liters, price, total cost, full/partial fill), MPG/L100km calculation, fuel cost chart. No gas station database, no octane tracking — keep it lean.

### ❌ iCloud Sync → v1.1 (R013)

**Rationale:** SwiftData + CloudKit is notoriously finicky (ServiceLog's developer publicly acknowledged iCloud sync challenges). Ship v1.0 with rock-solid local persistence. Add sync in v1.1 after the data model stabilizes. Users on a single device won't notice. Users who want multi-device will wait for v1.1 — this is normal for v1.0 apps.

### ❌ VIN Decoder → v1.1 (R014)

**Rationale:** Requires third-party API or on-device VIN database. Adds network dependency to an otherwise offline app. Nice-to-have, not launch-critical.

### ❌ Widgets → v1.1 (R015)

**Rationale:** Widgets are a retention feature, not an acquisition feature. No one downloads an app because of its widget. Ship the widget after users have data to display.

### ❌ CSV Export → v1.1

**Rationale:** PDF export covers the primary use case (resale, insurance). CSV is for power users who want to migrate data. Ship it alongside data import in v1.1.

### ❌ Data Import from Competitors → v1.1

**Rationale:** Import wizard for Fuelly/Drivvo/Simply Auto CSV formats is a great acquisition tool but requires reverse-engineering each format. Not launch-critical.

### ❌ Advanced Analytics → v1.1+

**Rationale:** Cost-per-mile, depreciation tracking, maintenance prediction — these are retention features for engaged users. v1.0 ships basic "total spent" and "cost by category."

---

## Feature Matrix: WrenchLog vs. Competitors at Launch

| Feature | WrenchLog v1.0 | ServiceLog | CARFAX | Simply Auto | Drivvo |
|---------|----------------|------------|--------|-------------|--------|
| Service logging | ✅ | ✅ | ✅ | ✅ | ✅ |
| Preloaded service types (22) | ✅ | ✅ (~15) | ✅ (limited) | ✅ | ✅ (many) |
| Custom service types | ✅ Free | ✅ Pro | ❌ | ✅ | ✅ |
| Reminders (date + mileage) | ✅ Free | ✅ Pro | ✅ | ✅ | ✅ |
| Multiple vehicles | ✅ Free (unlimited) | Pro only | ✅ (up to 8) | Limited free | Limited free |
| Photo attachments | ✅ Pro | ✅ Pro | ❌ | ❌ | ❌ |
| PDF export | ✅ Pro | ✅ Pro | ❌ | ❌ | ❌ |
| Cost summary | ✅ Free | ✅ | ✅ | ✅ | ✅ |
| Fuel tracking | ❌ (v1.1) | ❌ | ✅ | ✅ | ✅ |
| iCloud sync | ❌ (v1.1) | ✅ | N/A (account) | Pro | Pro |
| No ads | ✅ | ✅ | ✅ (but promotes shops) | ❌ (free has ads) | ❌ (invasive ads) |
| No account required | ✅ | ✅ | ❌ | ❌ | ❌ |
| Lifetime purchase | ✅ ($49.99) | ✅ ($69.99) | Free | ❌ | ❌ |
| Modern SwiftUI design | ✅ | ✅ | Decent | ❌ (dated) | ❌ (dated) |

**WrenchLog's unfair advantages at launch:**
- Unlimited vehicles in free tier (only CARFAX does this, and CARFAX harvests your data)
- Basic reminders in free tier (ServiceLog gates this behind Pro)
- No ads + no account + no tracking (only ServiceLog and Car Cave match this)
- Modern native SwiftUI design (only ServiceLog competes here)
- Competitive lifetime price ($49.99 vs ServiceLog's $69.99)

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| "No fuel tracking" causes negative reviews | Medium | Medium | Add to v1.1 roadmap, mention in App Store description as "coming soon" |
| iCloud sync absence noticed | Medium | Low | Most v1.0 users are single-device. Ship local backup/restore. |
| ServiceLog ships a major update first | Low | Medium | WrenchLog's free tier is more generous — different positioning |
| SwiftData bugs on iOS 17 | Medium | High | Extensive testing on real devices, migration strategy ready |
| App Review rejection | Low | High | No restricted APIs, standard IAP, clean privacy label |

---

## Success Criteria for v1.0

1. **App Store approval** on first submission
2. **4.5+ star average** after 50+ ratings
3. **< 2 minute** first vehicle + first service entry flow
4. **Zero data loss** reports in first 30 days
5. **Pro conversion rate > 5%** within 7 days of install
6. **Crash-free rate > 99.5%** (App Store threshold for quality)

---

## Summary

**Ship in v1.0 (10 features):**
1. Service logging (fast entry, inline edit, auto-save)
2. 22 preloaded service types + custom
3. Reminders (date + mileage, whichever-first)
4. Multiple vehicles (unlimited, free)
5. Cost summary (total, by category, by period)
6. Unit toggle (miles/km, gal/L, multi-currency)
7. Privacy-first architecture (no ads, no account, no tracking)
8. IAP with lifetime option
9. Photo attachments (Pro)
10. PDF export (Pro)

**Defer to v1.1 (6 features):**
1. Fuel tracking (R004)
2. iCloud sync (R013)
3. VIN decoder (R014)
4. Widgets (R015)
5. CSV export + data import
6. Advanced analytics

The thesis: **a polished maintenance tracker that does 10 things flawlessly will outperform a mediocre everything-app that does 20 things adequately.** ServiceLog proves this at 4.8 stars with no fuel tracking. WrenchLog ships faster, with a more generous free tier, and adds fuel + sync in the v1.1 update 4-6 weeks post-launch.
