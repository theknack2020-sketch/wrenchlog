# WrenchLog — Branding & Visual Identity Research

> Research date: 2026-03-23  
> Sources: Competitor app analysis, Apple HIG (app icons, SF Symbols), UX benchmark research, color psychology research, App Store visual analysis

---

## Executive Summary

The vehicle maintenance app category is visually homogeneous — dominated by generic car silhouettes, wrench icons, and blue/red color schemes. WrenchLog has a clear opportunity to stand out by choosing a distinctive color identity (warm amber/charcoal) and an icon concept that references the *log/journal* aspect of the name rather than yet another car outline. The name "WrenchLog" already contains a strong visual noun (wrench) — the brand should lean into that tool-in-hand, DIY-mechanic identity while keeping the visual language clean and premium.

---

## 1. Color Palette Analysis

### 1.1 What Competitors Use

| App | Primary Color | Secondary | Palette Feel |
|-----|--------------|-----------|--------------|
| CARFAX | Green (#00A84F) | White | Corporate trust, eco-friendly |
| Simply Auto | Blue (#2196F3) | Orange accents | Generic tech app |
| Drivvo | Blue (#1565C0) | White/Gray | Functional, cold |
| Fuelly | Green/Teal | White | Web-era, dated |
| ServiceLog | White/Light gray | Blue accents | Minimal, Apple-like |
| Car Cave | Dark charcoal | Warm accents | Premium, enthusiast |
| Loggy | Teal (#009688) | White | Modern but generic |
| MyAutoLog | Purple/Violet | White | Distinctive, unexpected |
| Jerry | Purple | White | Insurance/fintech feel |

**Key observation:** Blue and green dominate. Purple is emerging as a differentiator (MyAutoLog, Jerry). No major player owns amber/orange as a primary identity.

### 1.2 Three Palette Directions

#### Option A: "Workshop" — Dark/Mechanical (Recommended)

The garage workbench aesthetic. Speaks to DIY mechanics and enthusiasts. Feels premium without being cold.

| Role | Color | Hex | Usage |
|------|-------|-----|-------|
| **Background (dark)** | Charcoal | `#1C1C1E` | Primary canvas (dark mode) |
| **Background (light)** | Warm white | `#F5F3F0` | Light mode canvas |
| **Primary accent** | Amber/warm orange | `#E8A317` | CTAs, active states, progress bars |
| **Secondary accent** | Rust orange | `#C75B12` | Urgency indicators, overdue states |
| **Surface** | Dark steel | `#2C2C2E` | Cards, elevated surfaces (dark) |
| **Surface (light)** | Warm gray | `#E8E5E0` | Cards in light mode |
| **Text primary** | Off-white | `#F0EDEA` | Headings, labels (dark) |
| **Text secondary** | Medium gray | `#8E8E93` | Metadata, timestamps |
| **Success** | Sage green | `#4CAF50` | "All good" status |
| **Warning** | Amber (same as accent) | `#E8A317` | Due soon |
| **Danger** | Warm red | `#D32F2F` | Overdue |

**Why this works:**
- Amber is the color of instrument panels, warning lights, and workshop lamps — immediately automotive
- Charcoal backgrounds feel premium (Car Cave's users praise this)
- Dark-mode-first aligns with 2026 design expectations and iOS 26 Liquid Glass
- No major competitor owns amber/charcoal in this space
- Natural urgency gradient: green → amber → red maps to service status

**Color psychology:**
- Amber/orange: energy, action, warmth, mechanical. Associated with road signs, construction, caution
- Charcoal: sophistication, reliability, strength. Associated with carbon fiber, engine blocks, tools
- Warm undertones throughout (no pure grays) create approachability without sacrificing professionalism

#### Option B: "Clean Garage" — Modern/Minimal

The Apple Store aesthetic applied to car care. Neutral canvas, single accent color. Targets users who find "garage" aesthetics too niche.

| Role | Color | Hex | Usage |
|------|-------|-----|-------|
| **Background** | System white/black | iOS defaults | Follows system appearance |
| **Primary accent** | Teal blue | `#0A84FF` | Links, CTAs (iOS system blue) |
| **Secondary accent** | Warm gray | `#8E8E93` | Secondary text |
| **Surface** | System grouped | iOS defaults | Standard grouped table backgrounds |

**Why this might work:** Blends seamlessly with iOS, zero learning curve, ServiceLog's approach.  
**Why it probably doesn't:** Looks like every other app. No personality. ServiceLog already occupies this space perfectly. Nothing to screenshot and share.

#### Option C: "Garage Neon" — Bold/Distinctive

Neon accents on dark backgrounds. The automotive aftermarket / tuner culture aesthetic.

| Role | Color | Hex | Usage |
|------|-------|-----|-------|
| **Background** | Near-black | `#0D0D0D` | Canvas |
| **Primary accent** | Electric cyan | `#00E5FF` | CTAs, active states |
| **Secondary accent** | Hot pink/magenta | `#FF1744` | Urgency, alerts |
| **Surface** | Dark gray | `#1A1A1A` | Cards |

**Why this might work:** Eye-catching, memorable, would dominate App Store screenshots.  
**Why it probably doesn't:** Alienates the family/practical audience. Feels like a racing game, not a maintenance tracker. Accessibility concerns with saturated colors on dark backgrounds. Tires users' eyes over long sessions.

### 1.3 Recommendation

**Option A ("Workshop")** is the clear winner. It:
- Differentiates from the blue/green/white competition
- Feels authentically automotive without being niche
- Supports dark-mode-first design (2026 iOS expectation)
- Maps naturally to the status/urgency system (green → amber → red)
- Scales to both "enthusiast" and "practical owner" audiences
- The warm amber is distinctive in screenshots and App Store listings

---

## 2. SF Symbols for Automotive UI

SF Symbols 7 includes 6,900+ symbols. The automotive/maintenance subset is rich enough to avoid custom icons entirely for core UI.

### 2.1 Core Navigation & Tab Bar Icons

| Symbol | Name | Usage in WrenchLog |
|--------|------|---------------------|
| 🔧 | `wrench.fill` | Service/maintenance tab — the hero symbol |
| 🚗 | `car.fill` | Vehicles/garage tab |
| ⛽ | `fuelpump.fill` | Fuel log tab or section |
| 📊 | `chart.bar.fill` | Reports/statistics tab |
| ⚙️ | `gearshape.fill` | Settings tab |

### 2.2 Service Category Icons

| Symbol | Name | Usage |
|--------|------|-------|
| 🔧 | `wrench.and.screwdriver.fill` | General maintenance |
| 💧 | `drop.fill` | Oil change (with amber tint) |
| 🛞 | `tire.fill` *(iOS 17+)* | Tire rotation/replacement |
| 🔋 | `battery.100percent` | Battery service |
| ❄️ | `snowflake` | A/C service |
| 💨 | `wind` | Air filter |
| 🔦 | `headlight.high.beam.fill` *(iOS 17+)* | Lights/electrical |
| 🛑 | `brake.signal` *(if available)* | Brakes |
| 🌡️ | `thermometer.medium` | Coolant/temperature |
| ⚡ | `bolt.fill` | Electrical/spark plugs |
| 🪟 | `windshield.front.and.wiper` *(iOS 17+)* | Wipers/washer fluid |
| 🔑 | `key.fill` | Ignition/keys |
| ⛓️ | `chain` | Timing belt/chain |
| 🧰 | `wrench.adjustable.fill` | Custom/other service |

### 2.3 Status & Gauge Icons

| Symbol | Name | Usage |
|--------|------|-------|
| ⏱️ | `gauge.open.with.needle.33percent` | Mileage/interval progress |
| ⏱️ | `gauge.open.with.needle.67percent` | Service approaching due |
| ⏱️ | `gauge.open.with.needle.100percent` | Service overdue |
| 🔔 | `bell.fill` | Reminders |
| 🔔 | `bell.badge.fill` | Active reminder |
| ✅ | `checkmark.circle.fill` | Service completed |
| ⚠️ | `exclamationmark.triangle.fill` | Service overdue |
| 📅 | `calendar` | Date-based reminder |
| 🛣️ | `road.lanes` *(iOS 17+)* | Mileage-based reminder |

### 2.4 Vehicle & Data Icons

| Symbol | Name | Usage |
|--------|------|-------|
| 🚗 | `car.side.fill` *(iOS 17+)* | Vehicle profile (side view) |
| 🏍️ | `motorcycle.fill` *(if available)* | Motorcycle vehicle type |
| 🚛 | `truck.box.fill` | Truck vehicle type |
| 📄 | `doc.text.fill` | PDF export |
| 📷 | `camera.fill` | Receipt photo |
| 📎 | `paperclip` | Attachment |
| 💰 | `dollarsign.circle.fill` | Cost tracking |
| 🏷️ | `tag.fill` | Part number |
| 📤 | `square.and.arrow.up` | Share/export |

### 2.5 Animation Opportunities (SF Symbols 7)

- **Variable rendering** on `gauge.open.with.needle.*` — animate the needle as progress changes
- **Draw animation** on `wrench.fill` — calligraphic reveal when app launches
- **Bounce effect** on `bell.badge.fill` — when a reminder triggers
- **Pulse** on `exclamationmark.triangle.fill` — for overdue services
- **Replace transition** on gauge symbols — smooth needle movement when status changes

### 2.6 Symbol Rendering Modes

For WrenchLog's amber accent palette:
- **Hierarchical** rendering with amber as primary — creates depth without custom coloring
- **Palette** rendering for status icons — green/amber/red with consistent background
- **Multicolor** for fuel and specific service icons where Apple provides defaults
- **Monochrome** for tab bar (standard iOS behavior, tints to accent color)

---

## 3. App Icon Concepts

### 3.1 Competitor Icon Audit

| App | Icon Description | Standout? |
|-----|-----------------|-----------|
| CARFAX | Orange car silhouette on white | Recognized by brand, not by design |
| Simply Auto | Blue car + speedometer | Generic, forgettable |
| Drivvo | Blue steering wheel | Generic |
| Fuelly | Green fuel pump | On-the-nose, dated |
| ServiceLog | Minimal wrench on light bg | Clean but bland |
| Car Cave | Garage/cave silhouette | Most distinctive in category |
| Loggy | Teal clipboard + car | Busy, two concepts competing |
| MyAutoLog | Purple car outline | Color is distinctive, shape is not |
| Vehicle Maint. Tracker | Blue car + wrench | Generic clipart feel |

**Pattern:** Nearly every competitor uses a car silhouette + tool. The icons blur together in search results. Car Cave is the only one with a unique concept (garage mouth as the shape).

### 3.2 How to Stand Out

From Apple HIG (June 2025 update):
- "Find a concept that captures the **essence** of your app" — not every feature
- "Express it in a simple, unique way with a **minimal number of shapes**"
- "Prefer a simple background, such as a solid color or gradient"
- "Embrace simplicity" — fine details get lost at small sizes
- Support **layered icons** for iOS 26 Liquid Glass effects
- Provide **dark, clear, and tinted** variants
- "Based around filled, overlapping shapes" — with transparency for depth

**Differentiation strategies:**
1. **Don't use a car silhouette** — every competitor does this
2. **Lean into the wrench** — it's in the name and it's a strong, simple shape
3. **Combine wrench + log/journal** — the "Log" in WrenchLog is the differentiator
4. **Use amber on charcoal** — no competitor uses this palette in their icon

### 3.3 Icon Concept Options

#### Concept A: "The Wrench Mark" (Recommended)

A single, bold wrench shape — simplified to its essential geometry — tilted at a dynamic angle. Amber/gold on dark charcoal background. The wrench head forms a subtle "W" shape when stylized.

**Layers (for iOS 26 Liquid Glass):**
1. Background: Dark charcoal with subtle warm gradient (lighter at top)
2. Foreground: Bold amber wrench silhouette, slightly off-center for dynamism

**Variants:**
- Default: Amber wrench on charcoal
- Dark: Darker charcoal, slightly subdued amber
- Tinted: Wrench shape in system tint color on neutral background

**Why it works:**
- One shape, instantly recognizable at any size
- The wrench is already in the name — strong brand connection
- No car = stands out from every competitor
- Amber on charcoal is unique in the category
- Simple enough for Liquid Glass effects to enhance, not obscure
- The wrench says "tool/mechanic/DIY" without being literal about "car"

#### Concept B: "The Service Book"

A small notebook/journal shape with a wrench laid across it diagonally. Represents the "log" in WrenchLog — your vehicle's service diary.

**Layers:**
1. Background: Warm amber gradient
2. Middle: Dark notebook/journal rectangle with subtle page lines
3. Foreground: Small wrench crossing the journal corner

**Why it works:** Captures both halves of "WrenchLog." Unique concept no competitor uses.  
**Risk:** Two elements might get busy at small sizes. Requires careful simplification.

#### Concept C: "The Gauge"

A speedometer/gauge face with the needle replaced by a wrench shape. Combines automotive instrumentation with the tool metaphor.

**Layers:**
1. Background: Dark charcoal
2. Middle: Subtle gauge markings (arc)
3. Foreground: Wrench as the gauge needle, amber-colored

**Why it works:** Clever visual pun. Automotive without being a car silhouette.  
**Risk:** Gauge icons are common in the fitness/dashboard app space. May read as "speedometer app."

#### Concept D: "The Stamp"

A circular badge/stamp mark (like a quality-certification seal) with a wrench in the center. Conveys "certified," "logged," "verified" — reinforcing that maintenance is officially tracked.

**Layers:**
1. Background: Charcoal
2. Middle: Circular badge outline (amber, slightly translucent)
3. Foreground: Bold wrench in center

**Why it works:** Stamp/seal conveys trust and officialness — great for the "resale value" angle.  
**Risk:** Might look like a generic certification logo at small sizes.

### 3.4 Icon Recommendation

**Concept A ("The Wrench Mark")** is the strongest choice:
- Simplest — one shape, one background, maximum clarity
- Apple HIG explicitly recommends "minimal number of shapes" and "filled, overlapping shapes"
- Layered icon with transparency will look excellent with iOS 26 Liquid Glass
- Immediately says "tool / mechanic / wrench" → strong name-to-icon connection
- Amber on charcoal palette carries into the app's overall identity
- Most distinctive in an App Store search results grid full of car silhouettes

**Concept B ("The Service Book")** is a strong backup if the wrench alone feels too generic as a standalone shape.

### 3.5 iOS 26 Liquid Glass Considerations

Per Apple's June 2025 HIG update:
- Layered icons get specular highlights, frostiness, and translucency
- System applies visual effects — don't bake in shadows or highlights
- Prefer vector graphics (SVG/PDF) for layers
- Vary opacity in foreground for depth
- Solid color or gradient backgrounds respond best to system lighting
- Keep primary content centered (system crops edges during effects)
- Provide dark, clear, and tinted variants
- Use Icon Composer (ships with Xcode) to build and preview layers

---

## 4. Typography Considerations

### System Font (SF Pro) Usage

WrenchLog should use the system font stack exclusively — no custom fonts needed. SF Pro already provides:
- **SF Pro Display** for large titles — clean, modern, authoritative
- **SF Pro Text** for body text — optimized for readability at small sizes
- **SF Pro Rounded** (optional) for softer, friendlier contexts
- **SF Mono** for part numbers, VIN display, technical data

### Weight Hierarchy

| Context | Weight | Size (Dynamic Type base) |
|---------|--------|--------------------------|
| Screen title | Bold | Large Title |
| Section header | Semibold | Title 3 |
| Card title (service name) | Medium | Headline |
| Body text (notes, descriptions) | Regular | Body |
| Metadata (date, mileage, cost) | Regular | Subheadline |
| Caption (secondary info) | Regular | Caption 1 |
| Technical data (VIN, part #) | SF Mono Medium | Caption 1 |

### Tabular Figures

Use `monospacedDigit()` for:
- Mileage displays
- Cost figures
- Date columns
- Gauge readings

This prevents layout jitter when numbers update.

---

## 5. Naming & Verbal Identity

### Brand Name Analysis: "WrenchLog"

**Strengths:**
- Two clear syllables, easy to remember and spell
- Both words are concrete nouns with strong mental images
- "Wrench" = tool, hands-on, DIY, mechanical competence
- "Log" = record, history, journal, systematic tracking
- CamelCase reads naturally on screen
- Unique — no apps with this exact name found in App Store search
- Strong ASO potential: both "wrench" and "log" are relevant search terms

**Potential concerns:**
- "Wrench" skews masculine/mechanic — might feel exclusionary to casual car owners
- Mitigation: visual identity and copy can be warm and approachable to balance
- "Log" can mean both "journal/record" and "a piece of wood" — no real confusion risk in context

### Tagline Options

| Tagline | Vibe |
|---------|------|
| "Never miss a service." | Direct, benefit-focused |
| "Your vehicle's service diary." | Personal, approachable |
| "Track it. Keep it healthy." | Action-oriented |
| "The maintenance log your car deserves." | Quality-focused |
| "Service history, simplified." | Clean, minimal |

**Recommendation:** "Never miss a service." — short, benefit-first, works in both ASO and casual contexts.

---

## 6. Visual Identity Summary

### The WrenchLog Brand in One Sentence

**A warm, dark, tool-in-hand aesthetic that feels like a clean workshop — organized, competent, and trustworthy.**

### Brand Attributes

| Attribute | Expression |
|-----------|------------|
| **Trustworthy** | Dark, solid backgrounds. No flashy gradients. Consistent spacing. |
| **Competent** | Precise alignment, tabular figures, clear information hierarchy |
| **Warm** | Amber accent, warm grays (never pure gray), rounded corners |
| **Efficient** | Minimal UI chrome, fast data entry, no clutter |
| **DIY-friendly** | Wrench imagery, part number fields, "what I used" logging |
| **Private** | No login wall, no tracking badges, "on your device" messaging |

### Design Token Summary

```swift
// WrenchLog Design Tokens (SwiftUI)

// Primary palette
static let amber       = Color(hex: "#E8A317")  // Primary accent
static let rust        = Color(hex: "#C75B12")  // Secondary accent
static let charcoal    = Color(hex: "#1C1C1E")  // Dark background
static let warmWhite   = Color(hex: "#F5F3F0")  // Light background
static let steel       = Color(hex: "#2C2C2E")  // Dark surface
static let warmGray    = Color(hex: "#E8E5E0")  // Light surface

// Semantic colors
static let statusGood  = Color(hex: "#4CAF50")  // Service OK
static let statusSoon  = Color(hex: "#E8A317")  // Due soon (= amber)
static let statusDue   = Color(hex: "#FF9800")  // Due now
static let statusOver  = Color(hex: "#D32F2F")  // Overdue

// Text
static let textPrimary   = Color(hex: "#F0EDEA")  // Dark mode
static let textSecondary = Color(hex: "#8E8E93")  // Both modes
```

### What Makes WrenchLog Visually Unique

1. **Amber accent** — no competitor uses it; instantly automotive (instrument cluster, warning lights)
2. **Dark-mode-first** — designed for the garage, not the office
3. **The wrench, not the car** — icon and identity center on the *tool*, not the *vehicle*
4. **Warm, not cold** — warm grays, amber highlights, rounded shapes vs. the clinical blue/white of competitors
5. **SF Symbols throughout** — native, consistent, supports all iOS accessibility and animation features
6. **Layered Liquid Glass icon** — designed for iOS 26 from day one

---

## Sources

1. Apple HIG — App Icons (developer.apple.com, updated June 2025)
2. Apple SF Symbols 7 (developer.apple.com/sf-symbols)
3. Competitor App Store listings — CARFAX, ServiceLog, Car Cave, Drivvo, Simply Auto, Loggy, MyAutoLog
4. WrenchLog competitor analysis (.gsd/milestones/M001/research/competitor-analysis.md)
5. WrenchLog UX benchmarks (.gsd/milestones/M001/research/ux-benchmarks.md)
6. Apple HIG — Color, Dark Mode, Branding, SF Symbols guidelines
7. Color psychology: orange/amber associations with energy, warmth, mechanical/industrial contexts
8. iOS 26 Liquid Glass design language (WWDC25 sessions 220, 361)
