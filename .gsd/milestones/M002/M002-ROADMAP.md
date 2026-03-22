# M002: WrenchLog MVP Build

**Vision:** Ship a privacy-first, ad-free vehicle maintenance tracker that helps car owners track services, never miss maintenance, and increase resale value.

## Success Criteria

- User can add a vehicle and log first service in under 2 minutes
- 22 preloaded service types cover all common maintenance
- Reminders fire for both date-based and mileage-based triggers
- Cost summary shows spending by category and over time
- PDF export generates a clean service history document
- Pro unlock works in StoreKit sandbox
- App feels premium — amber/charcoal theme, smooth animations
- Builds, archives, uploads to ASC via CLI

## Slices

- [ ] **S01: Data Models & Vehicle Management** `risk:high` `depends:[]`
  > After this: user can add/edit vehicles with make/model/year/odometer/photo, vehicle list shows on home screen

- [ ] **S02: Service Logging & History** `risk:high` `depends:[S01]`
  > After this: user can log maintenance with 22 preloaded types, view service history timeline, edit/delete records

- [ ] **S03: Reminders & Notifications** `risk:medium` `depends:[S01,S02]`
  > After this: dual-trigger reminders (date + mileage), dashboard shows upcoming/overdue services with color coding

- [ ] **S04: Cost Analytics & Charts** `risk:medium` `depends:[S02]`
  > After this: cost summary per vehicle, spending by category donut chart, monthly bar chart, total lifetime cost

- [ ] **S05: Pro Features (Photos, PDF, IAP)** `risk:medium` `depends:[S01,S02]`
  > After this: photo attachments on service records, PDF export of service history, Pro unlock $14.99/yr + $49.99 lifetime

- [ ] **S06: App Icon, Polish & Launch** `risk:low` `depends:[S01,S02,S03,S04,S05]`
  > After this: amber/charcoal icon, all flows polished, builds via CLI, uploaded to ASC, screenshots captured, submitted for review

## Boundary Map

### S01 → S02
Produces:
- Vehicle SwiftData model with relationships
- VehicleListView, VehicleDetailView
- ServiceType enum (22 types + custom)

### S02 → S03
Produces:
- ServiceRecord model with date, mileage, serviceType
- Reminder data attached to service types

### S02 → S04
Produces:
- ServiceRecord with cost field for aggregation queries

### S01,S02 → S05
Produces:
- Vehicle + ServiceRecord models for PDF generation and photo attachment
