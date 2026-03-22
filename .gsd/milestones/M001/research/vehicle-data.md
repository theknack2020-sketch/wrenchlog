# Vehicle Data & Service Types Research

Research for WrenchLog maintenance tracker — common service types, standard schedules, regional differences, and fuel type considerations.

---

## 1. Common Service Types

### 1.1 Fluids & Filters

| Service | What It Covers | Typical Interval (US) | Typical Interval (EU) |
|---------|---------------|----------------------|----------------------|
| **Oil Change** | Engine oil + oil filter replacement | 5,000–7,500 mi / 6 months | 10,000–20,000 km / 12–24 months |
| **Transmission Fluid** | ATF or CVT fluid replacement | 30,000–60,000 mi | 60,000–80,000 km |
| **Coolant Flush** | Engine coolant replacement | 30,000 mi or 2 years | 40,000–50,000 km or 2–3 years |
| **Brake Fluid** | Hydraulic brake fluid replacement | 20,000–45,000 mi or 2 years | Every 2 years (common EU standard) |
| **Power Steering Fluid** | PS fluid replacement (if applicable) | 50,000–100,000 mi | 80,000–120,000 km |
| **Air Filter (Engine)** | Engine air filter element | 15,000–30,000 mi | 20,000–40,000 km |
| **Cabin Air Filter** | Interior ventilation filter | 15,000–20,000 mi / 12 months | 15,000–20,000 km / 12 months |
| **Fuel Filter** | Inline or in-tank fuel filter | 30,000 mi (more critical on diesel) | 30,000–40,000 km |
| **Windshield Washer Fluid** | Top-off washer reservoir | As needed | As needed |

### 1.2 Wear Components

| Service | What It Covers | Typical Interval |
|---------|---------------|-----------------|
| **Brake Pads** | Front/rear pad replacement | 10,000–20,000 mi (inspect); replace 25,000–70,000 mi |
| **Brake Rotors/Discs** | Rotor resurfacing or replacement | 50,000–70,000 mi (often with 2nd pad change) |
| **Tire Rotation** | Rotate tire positions for even wear | 5,000–8,000 mi / every oil change |
| **Tire Replacement** | New tires | ~50,000–60,000 mi or 6 years |
| **Wiper Blades** | Windshield wiper replacement | 10,000 mi / 12 months |
| **Battery** | 12V starter battery replacement | 3–5 years / ~50,000–60,000 mi |
| **Spark Plugs** | Ignition plug replacement | Copper: 30,000 mi; Iridium/Platinum: 60,000–100,000 mi |
| **Drive Belt / Serpentine Belt** | Accessory drive belt | 60,000–100,000 mi |
| **Timing Belt** | Engine timing belt (interference engines) | 60,000–100,000 mi (critical — failure = engine damage) |
| **Timing Chain** | Typically no scheduled replacement | Inspect at 100,000+ mi; replace if noisy |

### 1.3 Chassis & Alignment

| Service | Typical Interval |
|---------|-----------------|
| **Wheel Alignment** | Every 12 months or after tire rotation |
| **Suspension Check** | Every 15,000–20,000 mi |
| **Shocks/Struts** | 50,000–100,000 mi |
| **CV Boots / Driveshaft Boots** | Inspect at 10,000 mi intervals |

### 1.4 Inspections & Regulatory

| Service | Region | Interval |
|---------|--------|----------|
| **MOT (UK)** | United Kingdom | Annual for vehicles 3+ years old |
| **TÜV / HU (Germany)** | Germany | Every 2 years (new cars: first at 3 years) |
| **Contrôle Technique (France)** | France | Every 2 years for vehicles 4+ years old |
| **EU Roadworthiness (Directive 2014/45)** | EU-wide | First at 4 years, then every 2 years |
| **State Safety Inspection (US)** | Varies by state | Annual in ~19 states; some states have none |
| **Emissions / Smog Test (US)** | Varies by state/county | Annual or biennial where required |

---

## 2. Standard Maintenance Schedules

### 2.1 The 30-60-90 Framework (US Standard)

Most US manufacturers follow a 30-60-90 thousand mile schedule for major maintenance milestones:

**Every 5,000 miles / 6 months:**
- Oil & filter change
- Tire rotation
- Multi-point inspection

**Every 10,000 miles / 12 months:**
- All of the above, plus:
- Brake pad/rotor inspection
- Wiper blade replacement
- Transmission fluid check
- Alignment check

**Every 15,000 miles:**
- All of the above, plus:
- Engine air filter inspection
- Cabin air filter replacement

**30,000 miles (Minor Major Service):**
- All of the above, plus:
- Fuel filter replacement
- Coolant flush
- Transmission fluid change
- Brake fluid flush
- Exhaust system inspection
- Steering/suspension inspection

**60,000 miles (Major Service):**
- All 30k items, plus:
- Spark plug replacement (copper type)
- Belt inspection/replacement
- Battery inspection/replacement
- Tire replacement (if worn)

**90,000–100,000 miles (Critical Service):**
- All 60k items, plus:
- Timing belt replacement (if applicable)
- Water pump inspection
- O2 sensor replacement
- Transmission overhaul inspection
- High-mileage coolant/spark plugs

### 2.2 Time-Based vs. Mileage-Based

The app needs to support **dual-trigger scheduling**: whichever comes first.

| Item | Mileage Trigger | Time Trigger |
|------|----------------|-------------|
| Oil change | 5,000–10,000 mi | 6–12 months |
| Tire rotation | 5,000–8,000 mi | 6 months |
| Brake fluid | 20,000–45,000 mi | 2 years |
| Coolant | 30,000 mi | 2–3 years |
| Wiper blades | 10,000 mi | 12 months |
| Battery | 50,000 mi | 3–5 years |
| Timing belt | 60,000–100,000 mi | 5–7 years |

---

## 3. US vs. EU Service Interval Differences

### 3.1 Oil Change Intervals

The most significant divergence between US and EU maintenance cultures:

| Factor | United States | Europe |
|--------|-------------|--------|
| **Typical OCI** | 5,000–7,500 mi (8,000–12,000 km) | 10,000–20,000 km (some up to 30,000 km) |
| **Oil specification** | Broader tolerances; "Synthetic" label less regulated | Manufacturer-specific specs (e.g., BMW LL-01, VW 504/507) |
| **Condition-based service** | Becoming common (e.g., Honda Maintenance Minder) | Standard on most European brands (BMW CBS, Mercedes ASSYST) |
| **Cultural norm** | Many drivers still follow the legacy 3,000 mi interval | Drivers generally follow manufacturer-specified longer intervals |

**Reasons for the difference:**
- European oils are often PAO/ester-based synthetics fortified with more additives
- Fuel quality: EU had stricter sulfur limits earlier (now converged at 10 ppm since US EPA 2017 Tier 3)
- European manufacturers use condition-based monitoring systems that adapt intervals to driving patterns
- Average annual mileage differs: US ~14,000 mi/year vs. Germany ~8,400 mi, France ~6,000 mi

### 3.2 Inspection Regimes

| Aspect | United States | Europe (EU) |
|--------|-------------|-------------|
| **Mandatory inspection** | State-by-state; ~19 states require annual safety | EU Directive 2014/45 mandates periodic inspection |
| **First inspection** | Varies (some states: at registration) | New cars: 4 years after registration |
| **Recurring frequency** | Annual or biennial where required | Every 1–2 years (UK: annual; most EU: biennial) |
| **Scope** | Safety only, or emissions only, or both | Comprehensive: safety + emissions + roadworthiness |
| **Cost** | $20–70 (US) | $100–300 (EU); $400–500 (Japan) |
| **States with no inspection** | ~13 states (Alaska, Mississippi, etc.) | Not applicable — all EU countries require it |

### 3.3 Service Schedule Approach

| Aspect | US Approach | EU Approach |
|--------|-----------|-------------|
| **Schedule type** | Fixed mileage/time intervals | Condition-based + fixed maximum intervals |
| **Parts philosophy** | Generic/aftermarket widely accepted | OEM-spec parts often required to maintain warranty |
| **Unit system** | Miles, quarts, Fahrenheit | Kilometers, liters, Celsius |
| **Fuel grade** | Regular (87), Mid (89), Premium (91/93) | RON 95 (standard), RON 98 (premium) |

### 3.4 App Implications

The app must support:
- **Dual unit system**: miles/km, quarts/liters, °F/°C
- **Configurable intervals per service type**: US defaults vs. EU defaults
- **Inspection reminders with regional context**: MOT, TÜV, state inspection, emissions
- **Condition-based vs. fixed scheduling**: some users follow manufacturer CBS, others use fixed intervals

---

## 4. Fuel Types & Their Maintenance Impact

### 4.1 Gasoline (Petrol)

The baseline fuel type. All standard services apply.

**Unique maintenance items:**
- Oil changes (every 5,000–10,000 mi)
- Spark plugs (30,000–100,000 mi depending on type)
- Engine air filter
- Fuel filter
- Exhaust system (catalytic converter, muffler)
- Emissions/smog testing

### 4.2 Diesel

Shares most gasoline services but has significant additional requirements:

**Unique maintenance items:**
- **Fuel filter**: More critical than gasoline; typically every 15,000–30,000 mi. Dirty fuel filters are the #1 cause of injector failure in diesel engines
- **Diesel Particulate Filter (DPF)**: Requires periodic regeneration (burns off soot). Fitted to all new diesels since Euro 5 (2009). Replacement cost: $1,500–5,000. Short trips are the enemy of DPF health
- **AdBlue/DEF (Diesel Exhaust Fluid)**: Required on Euro 6+ vehicles. Consumption: ~1 liter per 600 miles. Average refill interval: 5,000–10,000 miles. Tank refill at every service. Vehicle won't start if AdBlue runs empty
- **Glow plugs** (instead of spark plugs): Replace every 60,000–100,000 mi
- **EGR valve cleaning**: Periodic cleaning to prevent carbon buildup
- **Turbocharger maintenance**: Most modern diesels are turbocharged
- **Oil specification**: Diesel-specific low-SAPS oil required for DPF compatibility

**DPF regeneration tracking** is a potential unique feature for diesel owners.

### 4.3 Electric (BEV)

Drastically simplified maintenance compared to ICE vehicles. EVs have ~50% lower lifetime maintenance costs ($4,600 vs. $9,200 for gas vehicles).

**Services that are ELIMINATED:**
- Oil changes
- Spark plugs
- Engine air filter
- Transmission fluid (no multi-speed gearbox)
- Exhaust system
- Fuel filter
- Timing belt/chain
- Drive belts
- Emissions testing

**Services that REMAIN:**
- Tire rotation (more frequent — instant torque causes faster wear)
- Tire replacement
- Brake inspection (much less frequent due to regenerative braking)
- Brake fluid replacement
- Cabin air filter (every 2–3 years)
- Wiper blades
- Windshield washer fluid
- Wheel alignment
- Suspension components
- 12V auxiliary battery
- **Battery coolant check** (for liquid-cooled battery packs)

**EV-specific services:**
- **HV Battery health monitoring**: Track state-of-health (SoH) percentage over time
- **Battery coolant system**: Check coolant levels and condition
- **Software updates**: Track OTA update history
- **Charging log**: Track charging sessions, charging habits (20–80% recommended for most Li-ion)

**Key EV stats:**
- Brake pads last significantly longer due to regenerative braking
- One side effect: brake rust from disuse — occasional forced mechanical braking recommended
- Battery warranty: typically 8 years / 100,000–185,000 mi
- Less than 1% chance of battery replacement needed for vehicles built 2016+

### 4.4 Hybrid (HEV / PHEV)

Combines both ICE and EV maintenance requirements — the most complex from a tracking perspective.

**Full ICE maintenance applies**, PLUS:
- HV battery health monitoring
- Battery coolant system
- Regenerative braking system
- Electric motor inspection
- Inverter/power electronics check

**Key differences from pure ICE:**
- Brake pads last longer (regenerative braking shares the load)
- Oil change intervals may be similar or slightly extended
- Engine may not run constantly, affecting warm-up cycles and oil condition
- PHEVs may have very different maintenance needs depending on how much electric-only driving occurs

---

## 5. Data Model Implications

### 5.1 Vehicle Properties

```
Vehicle:
  - make: String
  - model: String
  - year: Int
  - fuelType: enum [gasoline, diesel, electric, hybrid_hev, hybrid_phev]
  - engineSize: Float? (nil for BEV)
  - odometerUnit: enum [miles, kilometers]
  - currentOdometer: Int
  - region: enum [US, EU, UK, other]  // affects default intervals & inspection types
  - licensePlate: String?
  - vin: String?
```

### 5.2 Service Type Categories

```
ServiceCategory:
  - fluids_filters     (oil, coolant, brake fluid, transmission fluid, etc.)
  - wear_components    (brakes, tires, wipers, battery, belts, plugs)
  - inspection         (MOT, TÜV, state inspection, emissions test)
  - chassis_alignment  (alignment, suspension, CV boots)
  - diesel_specific    (DPF, AdBlue, glow plugs, EGR)
  - ev_specific        (HV battery, battery coolant, software update)
  - other              (custom user-defined services)
```

### 5.3 Service Record

```
ServiceRecord:
  - id: UUID
  - vehicleId: UUID
  - serviceType: ServiceType
  - date: Date
  - odometer: Int
  - cost: Decimal?
  - currency: String?
  - provider: String?       // shop name or "self"
  - notes: String?
  - photos: [Photo]?        // receipt scans, part photos
  - nextDueOdometer: Int?   // calculated or manual
  - nextDueDate: Date?      // calculated or manual
```

### 5.4 Maintenance Schedule Template

```
ScheduleTemplate:
  - serviceType: ServiceType
  - fuelType: [FuelType]          // which fuel types this applies to
  - intervalMiles: Int?           // mileage trigger
  - intervalKm: Int?              // km trigger  
  - intervalMonths: Int?          // time trigger
  - isRequired: Bool              // mandatory vs. recommended
  - severity: enum [critical, important, routine]
  - applicableRegions: [Region]?  // nil = universal
```

### 5.5 Predefined Service Types (Seed Data)

For the app to be useful out of the box, pre-populate these service types grouped by fuel type applicability:

| Service Type | Gas | Diesel | EV | Hybrid | Default Interval |
|-------------|-----|--------|-------|--------|-----------------|
| Oil Change | ✅ | ✅ | ❌ | ✅ | 5,000 mi / 6 mo |
| Oil Filter | ✅ | ✅ | ❌ | ✅ | (with oil change) |
| Tire Rotation | ✅ | ✅ | ✅ | ✅ | 5,000–8,000 mi / 6 mo |
| Brake Pad Inspection | ✅ | ✅ | ✅ | ✅ | 10,000 mi / 12 mo |
| Brake Pad Replacement | ✅ | ✅ | ✅ | ✅ | 25,000–70,000 mi |
| Brake Fluid | ✅ | ✅ | ✅ | ✅ | 2 years |
| Engine Air Filter | ✅ | ✅ | ❌ | ✅ | 15,000–30,000 mi |
| Cabin Air Filter | ✅ | ✅ | ✅ | ✅ | 15,000 mi / 12 mo |
| Coolant Flush | ✅ | ✅ | ❌ | ✅ | 30,000 mi / 2 yr |
| Transmission Fluid | ✅ | ✅ | ❌ | ✅ | 30,000–60,000 mi |
| Spark Plugs | ✅ | ❌ | ❌ | ✅ | 30,000–100,000 mi |
| Glow Plugs | ❌ | ✅ | ❌ | ❌ | 60,000–100,000 mi |
| Timing Belt | ✅ | ✅ | ❌ | ✅ | 60,000–100,000 mi |
| Drive Belt | ✅ | ✅ | ❌ | ✅ | 60,000–100,000 mi |
| Wiper Blades | ✅ | ✅ | ✅ | ✅ | 10,000 mi / 12 mo |
| Battery (12V) | ✅ | ✅ | ✅ | ✅ | 3–5 years |
| Wheel Alignment | ✅ | ✅ | ✅ | ✅ | 12 months |
| Tire Replacement | ✅ | ✅ | ✅ | ✅ | 50,000 mi / 6 yr |
| Fuel Filter | ✅ | ✅ | ❌ | ✅ | 30,000 mi |
| DPF Service | ❌ | ✅ | ❌ | ❌ | As needed / inspect annually |
| AdBlue/DEF Refill | ❌ | ✅ | ❌ | ❌ | 5,000–10,000 mi |
| HV Battery Check | ❌ | ❌ | ✅ | ✅ | 12 months |
| Battery Coolant | ❌ | ❌ | ✅ | ✅ | Per manufacturer |
| MOT / TÜV / Inspection | ✅ | ✅ | ✅ | ✅ | 12–24 months (regional) |
| Emissions Test | ✅ | ✅ | ❌ | ✅ | 12–24 months (regional) |

---

## 6. Key Design Decisions for the App

1. **Fuel-type-aware service lists**: When a user adds a vehicle, filter available service types by fuel type. Don't show "Oil Change" for a Tesla.

2. **Regional defaults**: Default intervals should change based on user's region (US vs EU/UK). EU oil changes default to longer intervals.

3. **Dual-trigger reminders**: Always track both mileage AND time. Remind on whichever threshold is hit first.

4. **Custom services**: Users must be able to add custom service types beyond the predefined list. Edge cases: roof rack maintenance, trailer hitch inspection, winter tire swap.

5. **Severity levels**: Differentiate between critical (timing belt — failure = engine destruction), important (brake pads), and routine (wiper blades) services.

6. **Inspection tracking**: Treat regulatory inspections (MOT, TÜV, state inspection, emissions) as a distinct category with pass/fail tracking and expiry dates.

7. **Multi-vehicle support**: Many households have 2+ vehicles with different fuel types. The data model must be vehicle-centric.

8. **Unit flexibility**: Support miles/km toggle per vehicle (not just global). A user might have a US-spec car in miles and an imported EU car in km.

---

## Sources

1. Spitzer Automotive — Routine Car Maintenance Schedule By Mileage (https://www.spitzernorthfield.com/routine-car-maintenance-schedule-by-mileage/)
2. Farm Bureau Financial Services — Scheduling Car Maintenance by Mileage (https://www.fbfs.com/learning-center/scheduling-car-maintenance-by-mileage)
3. Blake Ford — Preventative Car Maintenance by Mileage (https://www.blakefordoffranklin.com/blogs/5696/preventative-car-maintenance-by-mileage)
4. SpeedHaus405 — How European Car Maintenance Differs (https://speedhaus405.com/post/how-european-car-maintenance-differs-from-us)
5. Bimmer Mag — BMW and European Brands Maintenance in the US (https://www.bimmer-mag.com/european-car-maintenance-us/)
6. BobIsTheOilGuy — European Service Intervals Discussion (https://bobistheoilguy.com/forums/threads/is-it-true-european-service-intervals-run-as-high-as-20k-miles.374576/)
7. Drive Electric Vermont — EV vs Gas Vehicle Maintenance (https://www.driveelectricvt.com/about-evs/maintenance-differences)
8. US DOE AFDC — Maintenance and Safety of Electric Vehicles (https://afdc.energy.gov/vehicles/electric-maintenance)
9. Recharged — EV Maintenance Differences (https://recharged.com/learning/maintenance-and-repair/differences-between-gas-vehicles-and-ev-maintenance)
10. Lectron EV — Electric vs Gas Maintenance Costs (https://ev-lectron.com/blogs/blog/electric-car-maintenance-cost)
11. Gofor UK — Adblue and DPF Explained (https://www.gofor.co.uk/news/adblue-and-diesel-particulate-filters-explained)
12. Wikipedia — Vehicle Inspection (https://en.wikipedia.org/wiki/Vehicle_inspection)
13. GoodCar — Vehicle Safety Inspection by State (https://goodcar.com/car-ownership/vehicle-inspections-by-state)
14. Insurify — Vehicle Inspection Requirements by State 2026 (https://insurify.com/car-insurance/vehicle/state-vehicle-inspection/)
