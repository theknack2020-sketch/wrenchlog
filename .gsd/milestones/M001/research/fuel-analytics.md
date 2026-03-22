# Fuel Tracking & Cost Analytics Research — WrenchLog

## Summary

This research covers fuel economy calculation methods (MPG, L/100km), cost-per-mile analytics, spending visualizations, maintenance cost breakdowns by category, and total cost of ownership (TCO) views. It maps each analytics feature to concrete Swift Charts implementations, drawing on competitor patterns (Fuelio, Fuelly, Simply Auto) and industry-standard TCO models (AAA, Edmunds, KBB). The core insight: most competitor apps stop at fuel economy tracking — adding maintenance cost breakdown and a TCO summary view is a clear differentiator, especially in a privacy-first app.

---

## 1. Fuel Economy Calculations

### 1.1 The Fill-to-Fill Algorithm

The standard method used by Fuelio, Fuelly, and all major fuel trackers:

```
MPG = (currentOdometer - previousOdometer) / gallonsAdded
L/100km = (litersAdded / (currentOdometer - previousOdometer)) × 100
km/L = (currentOdometer - previousOdometer) / litersAdded
```

**Critical rule:** Both the current and previous entry must be full fill-ups (`isFillUp == true`). Partial fills break the calculation because you don't know the total fuel consumed over the distance.

**Handling partial fills (missed fill-ups):**
When a user logs a partial fill between two full fills, accumulate fuel and distance:
```
totalFuel = sum of all fuel entries between two full fills
totalDistance = lastFullFill.mileage - previousFullFill.mileage
MPG = totalDistance / totalFuel
```

This is how Fuelio handles it — it chains partial fills and only computes MPG when bookended by full fills.

### 1.2 Data Model (from technical-arch.md)

The existing `FuelLog` model already has the right fields:
- `mileage: Int` — odometer reading
- `fuelAmount: Double` — gallons or liters
- `fuelUnit: FuelUnit` — .gallons or .liters
- `pricePerUnit: Decimal` — price per gallon/liter
- `totalCost: Decimal` — total fill cost
- `isFillUp: Bool` — critical for MPG accuracy
- `currency: Currency`

**Computed properties to add (transient, not persisted):**

```swift
extension FuelLog {
    /// Fuel economy vs the previous full fill-up
    func fuelEconomy(previousMileage: Int, unit: FuelEconomyUnit) -> Double? {
        let distance = Double(mileage - previousMileage)
        guard distance > 0, fuelAmount > 0 else { return nil }

        switch unit {
        case .mpgUS:
            // Convert liters to gallons if needed
            let gallons = fuelUnit == .gallons ? fuelAmount : fuelAmount * 0.264172
            let miles = /* convert km to miles if metric */
            return miles / gallons
        case .lPer100km:
            let liters = fuelUnit == .liters ? fuelAmount : fuelAmount * 3.78541
            let km = /* convert miles to km if imperial */
            return (liters / km) * 100
        case .kmPerL:
            let liters = fuelUnit == .liters ? fuelAmount : fuelAmount * 3.78541
            let km = /* convert */
            return km / liters
        }
    }

    /// Cost per mile/km for this fill
    var costPerDistance: Decimal? {
        // Requires knowing previous odometer — computed by the view model
    }
}
```

### 1.3 Supported Units (matching Fuelly's breadth)

Fuelly supports: MPG (US), MPG (UK/Imperial), L/100km, km/L, km/gal, mi/L. For WrenchLog MVP, support:

| Unit | Formula | Markets |
|------|---------|---------|
| **MPG (US)** | miles ÷ US gallons | US, Canada |
| **L/100km** | (liters ÷ km) × 100 | EU, most of world |
| **km/L** | km ÷ liters | Japan, Brazil, India |
| **MPG (UK)** | miles ÷ imperial gallons | UK only |

Note: 1 US gallon = 3.78541 L, 1 Imperial gallon = 4.54609 L. UK MPG values are ~20% higher than US MPG for the same vehicle — this confuses users. Label clearly.

### 1.4 Edge Cases

- **First entry ever:** Cannot calculate MPG — need at least 2 full fills. Show "—" or "Add another fill-up to see MPG."
- **Odometer rollback/error:** If `current.mileage <= previous.mileage`, flag as error. Don't compute negative MPG.
- **Unit switching mid-stream:** If user changes from imperial to metric, historical data must be stored in original units with conversion at display time. Never re-convert stored values.
- **Very high/low MPG outliers:** Fuelio user reviews specifically mention incorrect data causing "61 MPG on a 24-27 MPG car." Consider a soft warning when computed MPG deviates >40% from the vehicle's rolling average.

---

## 2. Cost Per Mile/Km Analytics

### 2.1 Fuel Cost Per Mile

```
Fuel cost per mile = totalCost / (currentMileage - previousMileage)
```

Rolling average over all fuel entries gives the user's actual fuel cost per mile. AAA's 2024 benchmark: average maintenance cost ~$0.097/mile (~9.68 cents/mile). Total driving cost (fuel + maintenance + insurance + depreciation) averages much higher.

### 2.2 Maintenance Cost Per Mile

```
Maintenance cost per mile = sum(serviceRecord.cost) / totalMilesDriven
```

Where `totalMilesDriven = currentMileage - mileageAtFirstRecord`. This gives a meaningful per-mile maintenance cost that users can compare against industry benchmarks.

### 2.3 Combined Running Cost

```
Running cost per mile = (totalFuelCost + totalMaintenanceCost) / totalMilesDriven
```

This is the number most useful to users — it answers "what does it actually cost me to drive this car per mile?"

---

## 3. Charts & Visualizations — What Works Best

### 3.1 Chart Type → Use Case Mapping

Based on competitor analysis and data visualization best practices:

| Visualization | Chart Type | Swift Charts Mark | Priority |
|--------------|-----------|-------------------|----------|
| **Fuel economy over time** | Line chart with area fill | `LineMark` + `AreaMark` | P0 — core |
| **Monthly fuel spending** | Vertical bar chart | `BarMark` | P0 — core |
| **Cost breakdown by category** | Donut/ring chart | `SectorMark` (iOS 17+) | P0 — differentiator |
| **Fuel price trends** | Line chart | `LineMark` | P1 |
| **MPG per fill-up** | Scatter + trend line | `PointMark` + `LineMark` | P1 |
| **Monthly spending (fuel vs maintenance)** | Stacked bar chart | `BarMark` with `.foregroundStyle(by:)` | P1 |
| **Yearly cost comparison** | Grouped bar chart | `BarMark` with `.position(by:)` | P2 |
| **Cost of ownership waterfall** | Horizontal stacked bar | `BarMark` (horizontal) | P2 |
| **Fuel economy vs driving season** | Area chart | `AreaMark` | P2 |

### 3.2 Competitor Chart Patterns

**Fuelio (market leader):**
- Fuel consumption chart (line over time)
- Cost charts: fuel vs other costs, categories, total monthly costs
- Summary stats with each category breakdown
- Custom cost categories (service, maintenance, insurance, wash, parking)

**Fuelly:**
- MPG trend line per vehicle
- Gas price tracking
- Gas expenses over time
- Service expenses over time
- Comparative stats across vehicles

**FillUp:**
- Average gas mileage plot over time
- Monthly totals for gas purchased and distance driven
- Statistics as HTML report

**Gas Manager:**
- Fuel cost per month
- Distance per month
- Fuel price per mile
- CO2 emissions tracking

**Key gap in competitors:** None of the major competitors offer a comprehensive TCO view that combines fuel + maintenance + insurance in a single dashboard. This is WrenchLog's opportunity.

### 3.3 Dashboard Layout Recommendation

**Top-level Analytics Tab structure:**

```
┌─────────────────────────────────────┐
│  ▼ This Month / This Year / All Time │  ← Segmented picker
├─────────────────────────────────────┤
│  [Fuel Economy]  [Spending]  [TCO]  │  ← Tab bar or scroll sections
├─────────────────────────────────────┤
│                                      │
│   ╭──── Fuel Economy Card ────╮     │
│   │  28.4 MPG  (avg)          │     │
│   │  ▲ 2.1 vs last month     │     │
│   │  ┌──────────────────┐    │     │
│   │  │   Line Chart      │    │     │  ← LineMark + AreaMark
│   │  │   (MPG over time) │    │     │
│   │  └──────────────────┘    │     │
│   ╰───────────────────────────╯     │
│                                      │
│   ╭──── Spending Card ────────╮     │
│   │  $342.50 this month       │     │
│   │  ┌──────────────────┐    │     │
│   │  │  Stacked Bar       │    │     │  ← BarMark stacked (fuel/maint)
│   │  │  (monthly spend)   │    │     │
│   │  └──────────────────┘    │     │
│   ╰───────────────────────────╯     │
│                                      │
│   ╭──── Cost Breakdown ───────╮     │
│   │      [Donut Chart]        │     │  ← SectorMark
│   │  Oil: $85  Fuel: $220     │     │
│   │  Tires: $0  Brakes: $37   │     │
│   ╰───────────────────────────╯     │
│                                      │
└─────────────────────────────────────┘
```

---

## 4. Swift Charts Implementation Guide

### 4.1 Framework Overview

Swift Charts (introduced WWDC 2022, iOS 16+) uses a declarative SwiftUI syntax. Since WrenchLog targets iOS 17+, we get `SectorMark` (donut/pie charts) and scrollable charts. WWDC 2024 added vectorized plot APIs for larger datasets, and WWDC 2025 added 3D capabilities (iOS 26 only — not relevant for our target).

### 4.2 Core Mark Types We'll Use

| Mark | Use | Example |
|------|-----|---------|
| `BarMark` | Monthly spending, category comparison | Vertical bars for spending per month |
| `LineMark` | Fuel economy trend, price trend | MPG over time with smooth interpolation |
| `AreaMark` | Range visualization, area under line | Min/max MPG band + average line |
| `PointMark` | Individual data points on scatter | Each fill-up's MPG |
| `RuleMark` | Reference lines, averages, targets | Average MPG horizontal line |
| `SectorMark` | Pie/donut charts | Cost breakdown by category |
| `RectangleMark` | Heatmaps | Spending intensity by month (P2) |

### 4.3 Concrete Code Patterns

#### Fuel Economy Line Chart

```swift
import Charts

struct FuelEconomyChart: View {
    let entries: [FuelEconomyEntry]  // (date, mpg)
    let averageMPG: Double

    var body: some View {
        Chart {
            // Area fill under the line for visual weight
            ForEach(entries) { entry in
                AreaMark(
                    x: .value("Date", entry.date),
                    y: .value("MPG", entry.mpg)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [.blue.opacity(0.2), .blue.opacity(0.01)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }

            // Main line
            ForEach(entries) { entry in
                LineMark(
                    x: .value("Date", entry.date),
                    y: .value("MPG", entry.mpg)
                )
                .foregroundStyle(.blue)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }

            // Average reference line
            RuleMark(y: .value("Average", averageMPG))
                .foregroundStyle(.secondary)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                .annotation(position: .top, alignment: .trailing) {
                    Text("Avg: \(averageMPG, specifier: "%.1f")")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
        }
        .chartYScale(domain: .automatic(includesZero: false))
        .chartXAxis {
            AxisMarks(values: .stride(by: .month)) {
                AxisValueLabel(format: .dateTime.month(.abbreviated))
            }
        }
    }
}
```

#### Monthly Spending Stacked Bar Chart

```swift
struct MonthlySpendingChart: View {
    let data: [MonthlySpend]  // (month, category, amount)

    var body: some View {
        Chart(data) { item in
            BarMark(
                x: .value("Month", item.month, unit: .month),
                y: .value("Cost", item.amount)
            )
            .foregroundStyle(by: .value("Category", item.category.rawValue))
        }
        .chartForegroundStyleScale([
            "Fuel": Color.blue,
            "Oil Change": Color.orange,
            "Tires": Color.green,
            "Brakes": Color.red,
            "Battery": Color.purple,
            "Other": Color.gray
        ])
    }
}
```

#### Cost Breakdown Donut Chart (iOS 17+ SectorMark)

```swift
struct CostBreakdownDonut: View {
    let categories: [CostCategory]  // (name, total, color)

    var body: some View {
        Chart(categories) { category in
            SectorMark(
                angle: .value("Cost", category.total),
                innerRadius: .ratio(0.618),  // golden ratio donut
                angularInset: 1.5
            )
            .foregroundStyle(by: .value("Category", category.name))
            .cornerRadius(4)
        }
        .chartLegend(position: .bottom, spacing: 10)
    }
}
```

#### Interactive Selection (chart selection modifier)

```swift
struct InteractiveMPGChart: View {
    let entries: [FuelEconomyEntry]
    @State private var selectedDate: Date?

    var body: some View {
        Chart(entries) { entry in
            LineMark(
                x: .value("Date", entry.date),
                y: .value("MPG", entry.mpg)
            )
            .interpolationMethod(.catmullRom)

            if let selectedDate,
               let selectedEntry = entries.nearest(to: selectedDate) {
                RuleMark(x: .value("Selected", selectedEntry.date))
                    .foregroundStyle(.secondary)
                PointMark(
                    x: .value("Date", selectedEntry.date),
                    y: .value("MPG", selectedEntry.mpg)
                )
                .symbolSize(80)
                .foregroundStyle(.blue)
            }
        }
        .chartXSelection(value: $selectedDate)
        .chartOverlay { proxy in
            // Optional: custom tooltip overlay
        }
    }
}
```

### 4.4 Performance Considerations

- **Vectorized plots (iOS 18+):** For users with 100+ fuel entries over years, use `LinePlot` / `BarPlot` instead of `ForEach` + individual marks. These process the entire collection in parallel.
- **Lazy loading:** Don't compute all analytics on app launch. Compute on-demand when the user navigates to the analytics tab.
- **Aggregation:** For yearly views, pre-aggregate to monthly summaries rather than plotting every individual entry. A chart with 500+ data points degrades UX — aggregate to 12-24 visible points per screen.
- **Date windowing:** Default to "last 12 months." Let users expand to "all time" if they want. This keeps initial chart render fast.

### 4.5 Accessibility

Swift Charts provides VoiceOver support by default — each mark is navigable and speaks its values. Additional considerations:
- Add `.accessibilityLabel` to chart containers describing the trend ("Fuel economy trending upward over the last 6 months")
- Use `Audio Graph` support (built into Swift Charts) for sonification
- Ensure color choices work for color-blind users — use shape differentiation (`.symbol(by:)`) alongside color

---

## 5. Fuel Price Tracking

### 5.1 User-Logged Price History

Every fuel log entry already captures `pricePerUnit` — this gives us a personal fuel price history for free. No API or external data source needed.

**Visualization:** Line chart of price per gallon/liter over time, with the overall trend.

```swift
Chart(fuelLogs) { log in
    PointMark(
        x: .value("Date", log.date),
        y: .value("Price", log.pricePerUnit)
    )
    .symbolSize(30)

    LineMark(
        x: .value("Date", log.date),
        y: .value("Price", log.pricePerUnit)
    )
    .interpolationMethod(.catmullRom)
    .foregroundStyle(.orange)
}
.chartYScale(domain: .automatic(includesZero: false))
```

### 5.2 External Price APIs (Deferred — v1.1+)

Options for showing local fuel prices:
- **GasBuddy API:** Crowdsourced, US-focused. Requires partnership.
- **Fuel prices government APIs:** US EIA has weekly national/regional averages (free). EU varies by country.
- **Recommendation:** For MVP, user-logged data only. External price integration adds API dependency, network requirement, and ongoing maintenance — contradicts our on-device-only principle.

---

## 6. Maintenance Cost Breakdown by Category

### 6.1 Standard Categories

Based on the existing `ServiceType` enum in technical-arch.md and industry standards (AAA, Edmunds):

| Category | Common Items | Typical Frequency | Avg Cost (USD) |
|----------|-------------|-------------------|----------------|
| **Oil & Fluids** | Oil change, transmission fluid, coolant, brake fluid | 5k-10k miles | $80-$125 per oil change |
| **Tires** | Tire replacement, rotation, balancing, alignment | 40k-60k miles | $600-$1200 per set |
| **Brakes** | Pad replacement, rotor resurface/replace, caliper | 30k-70k miles | $300-$600 per axle |
| **Battery** | Battery replacement, terminal cleaning | 3-5 years | $150-$300 |
| **Filters** | Air filter, cabin filter, fuel filter | 15k-30k miles | $20-$80 each |
| **Belts & Hoses** | Serpentine belt, timing belt, coolant hoses | 60k-100k miles | $150-$1000 |
| **Electrical** | Alternator, starter, spark plugs, sensors | Varies | $100-$1000+ |
| **Suspension** | Shocks, struts, bushings, ball joints | 50k-100k miles | $200-$1500 |
| **Inspection** | State inspection, emissions test | Annually | $20-$100 |
| **Custom** | User-defined (car wash, parking, insurance, etc.) | User-defined | User-defined |

### 6.2 Donut Chart with Drill-Down

**Level 1:** Donut showing top-level categories (Fuel, Oil, Tires, Brakes, Other)
**Level 2:** Tap a category → list of individual service records in that category, sorted by date

This is the pattern Fuelio uses (cost charts with categories) and Fuelly uses (service expenses chart). WrenchLog's advantage: combining fuel AND maintenance in a single unified view.

### 6.3 Analytics Queries (SwiftData)

```swift
// Total cost by category for a date range
func costByCategory(
    vehicle: Vehicle,
    from: Date,
    to: Date
) -> [ServiceType: Decimal] {
    let records = vehicle.serviceRecords
        .filter { $0.date >= from && $0.date <= to }

    return Dictionary(grouping: records, by: \.serviceType)
        .mapValues { records in
            records.reduce(Decimal.zero) { $0 + $1.cost }
        }
}

// Monthly spending aggregation
func monthlySpending(
    vehicle: Vehicle,
    months: Int = 12
) -> [MonthlySpend] {
    let calendar = Calendar.current
    let cutoff = calendar.date(byAdding: .month, value: -months, to: Date())!

    let fuelByMonth = Dictionary(
        grouping: vehicle.fuelLogs.filter { $0.date >= cutoff },
        by: { calendar.startOfMonth(for: $0.date) }
    ).mapValues { $0.reduce(Decimal.zero) { $0 + $1.totalCost } }

    let serviceByMonth = Dictionary(
        grouping: vehicle.serviceRecords.filter { $0.date >= cutoff },
        by: { calendar.startOfMonth(for: $0.date) }
    ).mapValues { $0.reduce(Decimal.zero) { $0 + $1.cost } }

    // Merge into MonthlySpend array with fuel + maintenance breakdown
    // ...
}
```

---

## 7. Total Cost of Ownership (TCO) View

### 7.1 Industry Standard TCO Models

**Edmunds TCO® methodology (5-year model):**
Seven cost categories: depreciation, insurance, financing, taxes & fees, fuel, maintenance, repairs.

**AAA Your Driving Costs (annual):**
Six categories: depreciation, financing, fuel, insurance, fees, maintenance (including tires and repairs).

**KBB 5-Year Cost to Own:**
Average 5-year cost: ~$80,238 for all new vehicles. Year 1 is highest (~$26,560), declining over time.

### 7.2 WrenchLog TCO — What We Can Track

WrenchLog tracks **user-entered actual costs**, not estimates. This is more accurate than industry averages for the specific user. We can track:

| TCO Component | Source | Available in WrenchLog |
|---------------|--------|----------------------|
| Fuel costs | `FuelLog.totalCost` sum | ✅ Yes |
| Maintenance & repairs | `ServiceRecord.cost` sum | ✅ Yes |
| Cost per mile | Computed from above + mileage | ✅ Yes |
| Monthly/yearly totals | Aggregated from logs | ✅ Yes |
| Depreciation | Not tracked | ❌ No (would need external data) |
| Insurance | Could be user-entered | 🟡 Possible as custom cost category |
| Financing | Could be user-entered | 🟡 Possible as custom cost category |
| Taxes & fees | Could be user-entered | 🟡 Possible as custom cost category |

### 7.3 TCO Summary View Design

```
┌─────────────────────────────────────┐
│   Total Cost of Ownership           │
│   2019 Honda Civic — 3.2 years      │
├─────────────────────────────────────┤
│                                      │
│   Total Spent    $8,247.33          │
│   Cost/Mile       $0.18             │
│   Cost/Month      $214.50           │
│                                      │
│   ╭── Horizontal Stacked Bar ────╮  │
│   │ ████████ Fuel (62%)          │  │
│   │ ███░░░░░ Oil (12%)           │  │
│   │ ██░░░░░░ Tires (9%)          │  │
│   │ █░░░░░░░ Brakes (7%)         │  │
│   │ █░░░░░░░ Other (10%)         │  │
│   ╰──────────────────────────────╯  │
│                                      │
│   ╭── Cumulative Cost Line ──────╮  │
│   │  Line chart showing total     │  │
│   │  spend accumulating over time │  │
│   ╰──────────────────────────────╯  │
│                                      │
│   ╭── Year-over-Year Compare ────╮  │
│   │  Grouped bars: 2024 vs 2025   │  │
│   │  by category                  │  │
│   ╰──────────────────────────────╯  │
│                                      │
└─────────────────────────────────────┘
```

### 7.4 Cumulative Cost Chart (Swift Charts)

```swift
struct CumulativeCostChart: View {
    let entries: [CumulativeCostEntry]  // (date, runningTotal)

    var body: some View {
        Chart(entries) { entry in
            AreaMark(
                x: .value("Date", entry.date),
                y: .value("Total", entry.runningTotal)
            )
            .foregroundStyle(
                .linearGradient(
                    colors: [.red.opacity(0.3), .red.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            LineMark(
                x: .value("Date", entry.date),
                y: .value("Total", entry.runningTotal)
            )
            .foregroundStyle(.red)
            .lineStyle(StrokeStyle(lineWidth: 2))
        }
        .chartYAxis {
            AxisMarks(format: .currency(code: "USD"))
        }
    }
}
```

---

## 8. Multi-Vehicle Comparison

Users with multiple vehicles want to compare costs. This is a unique angle — most competitor apps show per-vehicle stats but don't make comparison easy.

### 8.1 Comparison Views

| Comparison | Chart | Implementation |
|-----------|-------|---------------|
| MPG across vehicles | Grouped bar or multi-line | `foregroundStyle(by: .value("Vehicle", name))` |
| Cost/mile comparison | Horizontal bar | One bar per vehicle, sorted by cost |
| Monthly spend overlay | Multi-line chart | Different colored lines per vehicle |

### 8.2 Multi-Series Line Chart

```swift
struct MultiVehicleMPGChart: View {
    let series: [(vehicle: String, entries: [FuelEconomyEntry])]

    var body: some View {
        Chart {
            ForEach(series, id: \.vehicle) { s in
                ForEach(s.entries) { entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("MPG", entry.mpg)
                    )
                    .foregroundStyle(by: .value("Vehicle", s.vehicle))
                }
            }
        }
        .chartLegend(position: .bottom)
    }
}
```

---

## 9. Chart Design Guidelines

### 9.1 iOS Human Interface Guidelines for Charts

- **Use the system font** for axis labels and annotations — don't customize fonts in charts
- **Respect Dynamic Type** — chart annotations should scale with accessibility settings
- **Support Dark Mode** — use semantic colors (`.primary`, `.secondary`) for axes, and named colors for data series
- **Keep chart height proportional** — 200-250pt for inline cards, 300-400pt for full-screen detail
- **Minimize chart junk** — no unnecessary gridlines, borders, or 3D effects
- **Label the Y-axis** with units (MPG, $, L/100km) — don't assume users know what the axis represents

### 9.2 Color Palette for Categories

Consistent colors across all charts:

```swift
enum CostCategoryColor {
    static let fuel = Color.blue
    static let oilChange = Color.orange
    static let tires = Color.green
    static let brakes = Color.red
    static let battery = Color.purple
    static let filters = Color.teal
    static let electrical = Color.yellow
    static let suspension = Color.indigo
    static let inspection = Color.mint
    static let custom = Color.gray
}
```

### 9.3 Animation

Swift Charts supports built-in animation via `.chartAnimationStyle()` and standard SwiftUI transitions. Use:
- **On-appear animation** for initial chart rendering (data "grows in")
- **Smooth transitions** when switching time ranges (This Month → This Year)
- **No animation** on scroll — charts should render instantly when scrolled into view

---

## 10. MVP vs Future Priorities

### P0 — MVP Analytics (launch)

1. **Fuel economy trend** — Line chart, MPG/L-per-100km over time per vehicle
2. **Monthly spending** — Bar chart, fuel + maintenance stacked
3. **Cost breakdown donut** — SectorMark showing category distribution
4. **Summary stats** — Total spent, cost/mile, average MPG (numeric, no chart)

### P1 — v1.1

5. **Fuel price trend** — Line chart from user data
6. **Year-over-year comparison** — Grouped bars
7. **Multi-vehicle comparison** — Side-by-side metrics
8. **Interactive chart selection** — Tap to see specific data points

### P2 — v1.2+

9. **TCO cumulative view** — Area chart showing total cost accumulation
10. **Spending forecast** — Projected future costs based on historical patterns
11. **Export charts as images** — Share analytics screenshots
12. **Anomaly detection** — Flag unusual MPG drops that might indicate vehicle problems
13. **Insurance/registration as custom recurring costs** — Expand TCO completeness

---

## 11. Key Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Chart framework | Apple Swift Charts (native) | No third-party dependency, follows project principles, excellent SwiftUI integration, accessible by default |
| MPG calculation | Fill-to-fill with partial accumulation | Industry standard, same as Fuelio/Fuelly, accurate with `isFillUp` flag |
| Data storage | Compute on-demand, don't persist analytics | Analytics are derived from raw FuelLog + ServiceRecord data. Avoid stale cache. |
| Time aggregation | Monthly buckets for bar charts | Balances granularity with readability. Daily is too noisy, yearly too sparse. |
| Chart minimum target | iOS 17+ | Gets us SectorMark (donut), scrollable charts, selection gestures |
| External price data | Deferred to v1.1+ | Keeps MVP on-device-only, avoids API dependency |
| TCO model | Track actuals, not estimates | More accurate than industry averages for the individual user |

---

## Sources

- Fuelio (fuel.io) — market leader features and patterns
- Fuelly — MPG tracking, unit support, chart types
- FillUp — open source, calculation methods
- Apple Swift Charts documentation (WWDC 2022, 2024)
- Edmunds TCO® methodology
- AAA Your Driving Costs calculator
- KBB 5-Year Cost to Own
- Consumer Reports maintenance cost data
- Argonne National Lab TCO study (ANL/ESD-21/4)
- Cardata maintenance cost analysis
