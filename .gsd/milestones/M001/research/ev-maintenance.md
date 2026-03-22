# EV & Hybrid Vehicle Maintenance Research

> Research date: 2026-03-23
> Sources: Tesla owner's manuals, Consumer Reports, AAA, Argonne National Laboratory, Recharged, J.D. Power, ICCT, Bridgestone, Michelin, various automotive publications

---

## 1. EV vs ICE Maintenance: Fundamental Differences

### What EVs Eliminate
An ICE vehicle has ~2,000 moving parts; an EV motor has ~20. This eliminates:
- Oil changes & oil filters
- Spark plugs
- Timing belts / serpentine belts
- Transmission fluid changes
- Fuel filters / fuel pumps
- Exhaust system (catalytic converters, mufflers)
- Alternator
- Engine air filters
- Oxygen sensors
- Gaskets, pistons

### What EVs Share with ICE
- Tires (rotation, alignment, replacement)
- Brake pads & rotors (but last 2-3x longer on EVs)
- Brake fluid
- Cabin air filter
- Windshield wipers & washer fluid
- Suspension components (shocks, struts, bushings, ball joints, tie rods)
- Steering system
- 12V battery
- HVAC system
- Lights (headlights, taillights)

### What's New/Different for EVs
- **Battery health monitoring** — most critical and expensive component
- **Battery coolant system** — thermal management affects battery lifespan
- **Software updates** — OTA updates replace many dealer visits
- **Regenerative braking calibration** — affects brake pad and tire wear patterns
- **EV-specific tires** — required due to weight and torque characteristics
- **High-voltage system** — not user-serviceable, requires certified technicians
- **Electric drive assembly fluid** — long interval (e.g., Ford: 150,000 mi / 10 years)

### Cost Comparison
| Metric | BEV | ICE |
|--------|-----|-----|
| Maintenance cost per mile (DOE) | $0.061-0.093 | $0.10-0.154 |
| Avg annual maintenance (AAA) | ~$619 | ~$949 |
| Lifetime maintenance (Consumer Reports) | ~$4,600 | ~$9,200 |
| Maintenance savings | **~40-50% less** | baseline |
| Service interval | 12-18 months / 12,000-18,000 mi | 6 months / 5,000-6,000 mi |

Ford claims the 2023 E-Transit has 45% fewer scheduled maintenance costs vs gas Transit over 5 years.

---

## 2. Tesla-Specific Maintenance Schedule

### Official Tesla Service Intervals (Model 3/Y, 2024-2026)

| Item | Interval | Notes |
|------|----------|-------|
| Tire rotation | Every 6,250 mi (10,000 km) | Or if tread depth difference ≥ 2/32" |
| Cabin air filter | Every 2 years | 3 years for HEPA/carbon filters |
| HEPA filter | Every 3 years | Every year in China (pollution) |
| Brake fluid health check | Every 4 years | Replace if necessary |
| Brake caliper clean/lube | Every year or 12,500 mi | Only if roads are salted in winter |
| Wiper blades | Every year | Climate-dependent |
| A/C desiccant bag | ~6 years | Sensible HVAC check at year 4 in humid climates |

### Tesla-Specific Observations
- Tesla has moved to **condition-based maintenance** rather than fixed mileage packages
- The car has a **Maintenance Summary** screen: Controls > Service > Maintenance
- Tracks when items were last performed, suggests next service
- **Does NOT proactively send maintenance reminders** — owner must check manually or remember intervals
- Over-the-air **software updates** fix many issues without shop visits
- Tesla app provides battery monitoring (charge level, range, efficiency trends)
- Battery coolant reservoir must NOT be opened by owner (voids warranty)
- **12V battery** replacement triggers on-screen and in-app alerts when due

### Real-World Tesla Maintenance Costs
- Average annual: $300-700/year (primarily tires, filters, occasional shop visits)
- Tires are the biggest recurring cost
- Model 3 tires may need replacement every 18-24 months for high-mileage drivers

---

## 3. EV Tire Wear — A Critical Tracking Need

### The Problem
EVs wear tires **15-30% faster** than comparable ICE vehicles. Three main factors:

1. **Weight**: EV battery packs add 900-1,200 lbs vs comparable ICE vehicle (15-25% heavier)
2. **Instant torque**: Full torque from 0 RPM, every launch scrubs rubber
3. **Regenerative braking**: Shifts braking load to front tires, causes uneven wear patterns

### Key Data Points
- ICE tires: typically 40,000-50,000+ miles
- EV tires: typically 20,000-40,000 miles (model and driving dependent)
- J.D. Power 2024: **39% of BEV owners** replaced tires in last 12 months vs **20% of ICE owners**
- Bridgestone research: 30-40% faster wear for EVs
- Michelin: ~20% faster wear
- Roadside assistance data: EVs experience tire problems nearly **2x as often** as ICE vehicles
- EV-specific tires cost more ($900-$1,500 per set for crossovers)

### Implications for Tracking
- Tire rotation needs to happen more frequently (every 5,000-6,250 mi)
- Tire pressure monitoring is critical (affects range + wear)
- Users need to track tread depth differential between front/rear
- Alignment checks more important due to weight
- Tire replacement budgeting is a key planning need

---

## 4. Battery Health Monitoring

### What Needs Tracking
- **State of Health (SoH)**: percentage of original capacity remaining
- **Degradation rate**: Geotab study shows ~2.3% per year average
- **Charging habits**: frequent DC fast charging accelerates degradation
- **Temperature exposure**: extreme heat/cold affects battery life
- **Charge cycling**: avoid consistently going to 0% or 100%

### Warranty Baselines
- Tesla Model 3 RWD: 8 years / 100,000 mi, minimum 70% retention
- Tesla Model 3 LR/Performance, Model Y LR/Performance: 8 years / 120,000 mi, minimum 70% retention
- Most EV manufacturers: 8 year / 100,000+ mi warranty
- DOE: batteries designed for 12-15 years under normal conditions
- End-of-life threshold: ~70% of original capacity

### Current Monitoring State
- Tesla provides in-car and app-based battery level/range monitoring
- **No built-in SoH percentage readout** for most Tesla owners (requires third-party tools)
- Third-party services like Recurrent, Geotab, and Recharged provide battery health reports
- OBD2 adapters less useful for EVs (many use proprietary protocols)
- Carly app offers some EV battery health features

---

## 5. Software Updates as a Maintenance Category

### Why This Matters for EV Owners
- Tesla pushes OTA updates regularly (features, bug fixes, safety)
- Updates can change vehicle behavior (regen braking calibration, range optimization)
- Some updates require WiFi + specific battery charge level
- Users want to track: update version, date installed, what changed
- No standardized way to log update history across brands
- Some updates are recall-related (safety-critical)

---

## 6. Brake System — Less Frequent but Not Zero

### Regenerative Braking Impact
- Regen handles 64-95% of stopping power (driving style dependent)
- Brake pads last **2-3x longer** than ICE vehicles
- Brake components on EVs can last the life of the vehicle in moderate use
- **However**: calipers can seize from disuse (especially in salty/humid climates)
- Tesla recommends pressing brake pedal frequently to dry pads and prevent rust/corrosion

### Tracking Needs
- Brake fluid: check every 4 years (Tesla), every 3 years (Ford)
- Brake pad inspection: every 20,000-30,000 miles
- Caliper lubrication: annually in salt-belt regions
- Note: heavy towing, mountain driving, performance driving = more frequent checks

---

## 7. Other EV-Specific Maintenance Items

| Item | Interval | Notes |
|------|----------|-------|
| Cabin air filter | 2 years (standard), 3 years (HEPA) | More frequent in dusty/polluted areas |
| Battery coolant | Very long interval (Ford: 200,000 mi) | Owner should NOT service themselves |
| Electric drive assembly fluid | Ford: 150,000 mi / 10 years | Brand-specific |
| HVAC / A/C desiccant | ~6 years | Climate-dependent |
| 12V battery | As needed (alerts when due) | Critical — can strand vehicle if dead |
| Windshield wipers | Annually | Same as ICE |
| Wheel alignment | With tire changes + as needed | More important due to EV weight |

---

## 8. Existing Maintenance Tracking Apps — Competitive Gap Analysis

### Current Market Leaders
| App | EV Support | Strengths | Weaknesses |
|-----|-----------|-----------|------------|
| **CARFAX Car Care** | Minimal | Auto service history from partner shops, recall alerts, high ratings (4.7-4.8★) | ICE-centric, basic features, no EV-specific tracking |
| **Simply Auto** | Basic (kWh tracking) | Clean UI, multi-vehicle, mileage tracking | No battery health, no EV maintenance schedules |
| **Drivvo** | Limited | Expense analytics, multi-vehicle | Fuel-tracking focused, no EV optimization |
| **FIXD** | OBD2-based | Real-time diagnostics, predictive maintenance | OBD2 less useful for EVs, ICE-focused |
| **Fuelly** | Minimal | Community MPG comparison, fuel tracking | Entire value prop built around fuel consumption |
| **AUTOsist** | Minimal | Document storage, fleet management | Business-focused, no EV-specific features |
| **Carly** | Some (battery health) | EV battery diagnostics via OBD/WiFi | Requires adapter hardware, limited vehicle support |
| **Tesla App** | Tesla only | Battery monitoring, service scheduling, OTA updates | Single brand, no service history export, no proactive reminders |

### Identified Gaps — EV-Focused Maintenance App

**No existing app adequately addresses:**

1. **EV-specific maintenance schedules**: Apps use ICE intervals (oil change every 5K mi) as their core model. EV schedules are fundamentally different — longer intervals, different items, condition-based.

2. **Battery health tracking over time**: No consumer app tracks SoH degradation trends with historical graphs. Tesla doesn't even show SoH percentage natively.

3. **Tire wear as primary maintenance concern**: ICE apps treat tires as secondary to oil changes. For EVs, tires ARE the primary recurring maintenance item. Need tire-centric tracking with wear monitoring.

4. **Regenerative braking context**: No app accounts for the fact that brake maintenance intervals are 2-3x longer with regen braking, or warns about caliper seizing from disuse.

5. **Software update logging**: No maintenance app tracks OTA software updates as a maintenance category.

6. **Multi-powertrain support**: Most apps are ICE-only or bolt on minimal EV support. A growing number of households have mixed fleets (ICE + EV + hybrid). Need first-class support for all three with appropriate schedules for each.

7. **Charging habit impact on maintenance**: Charging patterns affect battery health, which is a maintenance concern. No app connects charging behavior to maintenance recommendations.

8. **Privacy-first design**: Competitor apps (CARFAX, Drivvo) collect extensive user data. EV owners skew tech-savvy and privacy-conscious — local-first data storage is a differentiator.

---

## 9. Hybrid Vehicle Maintenance — The Middle Ground

Hybrids (HEV/PHEV) combine both maintenance worlds:
- Still need oil changes (but less frequent due to electric assist)
- Still have transmission, exhaust, spark plugs
- Also have battery system (smaller than BEV)
- Also benefit from regenerative braking (less brake wear)
- PHEV maintenance costs: ~$3,288/year (higher than BEV, lower than ICE)
- HEV maintenance costs: ~$3,432/year

**Key implication**: A maintenance app supporting all powertrain types needs to dynamically adjust the maintenance schedule based on whether the vehicle is BEV, PHEV, HEV, or ICE.

---

## 10. Market Opportunity Summary

### Why Now
- EV adoption accelerating globally
- Vehicle servicing app market growing 9% annually (2024-2032)
- Global automotive repair/maintenance market projected at $1.06 trillion by 2030
- 70% of drivers prefer digital tools for vehicle upkeep
- Tesla has sold millions of vehicles; owners need better maintenance tracking than Tesla provides natively

### The Gap
Every major maintenance app was designed for ICE vehicles and has bolted on minimal EV support as an afterthought. There is no **EV-first** maintenance tracker that:
- Understands EV-specific maintenance schedules natively
- Tracks battery health trends over time
- Treats tires as the primary maintenance concern
- Logs software updates
- Supports mixed fleets (BEV + ICE + hybrid) with appropriate schedules
- Respects user privacy with local-first data storage

### WrenchLog Opportunity
Position as the **first maintenance tracker built for the EV era** while fully supporting ICE and hybrid vehicles. Privacy-first, offline-capable, with intelligent scheduling that adapts to powertrain type.

---

## Sources

1. Tesla Model 3 Owner's Manual — Maintenance Service Intervals (tesla.com)
2. Tesla Model Y Service Manual — Vehicle Service Intervals (service.tesla.com)
3. Tesla Support — Vehicle Maintenance (tesla.com/support/vehicle-maintenance)
4. Merchants Fleet — EV vs ICE Maintenance Guide (merchantsfleet.com)
5. Drive Electric Tennessee — Maintenance Costs EVs vs ICE (driveelectrictn.org)
6. Consumer Reports — EV Maintenance Cost Study (via multiple sources)
7. Argonne National Laboratory — BEV Maintenance Cost Study
8. AAA — Annual Vehicle Maintenance Cost Data
9. U.S. Department of Energy — EV Maintenance Per-Mile Data
10. Recharged — EV Tire Wear Explained 2025 (recharged.com)
11. J.D. Power 2024 — EV Tire Replacement Study
12. Bridgestone — EV Tire Wear Research
13. Michelin — EV Tire Wear Data
14. ICCT — Battery-Electric Truck Maintenance Costs
15. Geotab — EV Battery Degradation Study
16. AAA/ACG — Best Car Maintenance Apps Review
17. Mordor Intelligence — Automotive Repair & Maintenance Market Report
18. Motorfinity UK — EV Maintenance & Servicing Guide 2025
19. Recharged — Tesla Model 3 Maintenance Schedule 2026
20. Tesla Motors Club Forum — Maintenance Reminder Discussion
