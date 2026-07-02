# WrenchLog — Retention & Conversion Plan

## Category Research
Vehicle maintenance apps: low daily engagement by nature. Users open when they service, fuel, or get a reminder. Competitors (ServiceLog, Simply Auto) have NO retention mechanics — this is our opportunity to differentiate.

**Benchmark conversion rates (freemium apps, utilities):**
- Free → trial start: 5-8%
- Trial → paid: 40-60%
- Day 7 retention (utilities): 15-25%
- Day 30 retention: 8-15%

## Free vs Pro Feature Matrix

| Feature | Free (1 vehicle) | Pro (unlimited) |
|---------|:-:|:-:|
| Vehicles | 1 | ∞ |
| Service logging | ✅ | ✅ |
| Fuel tracking | ✅ | ✅ |
| Smart reminders (time-based) | ✅ | ✅ |
| Basic insights (fleet summary + compliance) | ✅ | ✅ |
| Maintenance health score | ✅ | ✅ |
| Seasonal suggestions | ✅ | ✅ |
| Milestones & badges | ✅ | ✅ |
| Streak tracking | ✅ | ✅ |
| Daily tips | ✅ | ✅ |
| **Full Analytics & Charts** | ❌ | ✅ |
| **Fuel Efficiency Trends** | ❌ | ✅ |
| **Cost Projections & YoY** | ❌ | ✅ |
| **PDF Reports** | ❌ | ✅ |
| **CSV Export** | ❌ | ✅ |
| **Receipt Photos** | ❌ | ✅ |
| **Spending Projections** | ❌ | ✅ |
| **All Color Themes** (3/5 locked) | 2 themes | 5 themes |

### Why This Split Works
- **Free is genuinely useful** — you can track 1 car fully with services, fuel, reminders, basic insights
- **Pro is clearly better** — analytics depth, export, unlimited cars, all themes
- **1-vehicle limit creates natural upgrade moment** when user gets a second car or wants to track a family member's car
- **Retention features (streak, tips, badges) are FREE** — they keep users engaged regardless of payment

## Soft Paywall Triggers

| Trigger | When | Type |
|---------|------|------|
| 3rd completed action | After 3rd save (service/fuel/vehicle) | Non-blocking sheet |
| Locked feature tap | Tapping locked chart, export, theme | ProUpgradeView sheet |
| 2nd vehicle attempt | Tapping + when 1 vehicle exists (free) | ProUpgradeView sheet |
| Onboarding last page | Trial CTA banner | Inline banner |
| 5th returned visit | If dismissed before, show again | Non-blocking sheet |

## Retention Hooks

### Streak System
- Track consecutive days with app open
- Visual: 🔥 badge on dashboard
- Push: "Don't break your X-day streak!" at 10am daily (if streak ≥ 2)
- Milestones: 3, 5, 7, 14, 30 days → special message

### Daily Tips
- 21 rotating car maintenance tips
- Shown in RetentionBanner on dashboard
- Changes daily (deterministic by day-of-year)
- Provides value even when user has nothing to log

### Journey (Day 1-3)
- Day 1: "Welcome! Add your first vehicle to get started 🚗"
- Day 2: "Try logging a service or fuel fill-up 🔧"
- Day 3: "Check your maintenance health score ❤️"

### Notifications
| Type | When | Frequency |
|------|------|-----------|
| Streak reminder | 10am daily (if streak ≥ 2) | Daily |
| Weekly summary | Sunday 6pm | Weekly |
| Inactivity nudge | After 3 days inactive | One-shot (resets on open) |
| Service reminders | Based on intervals | Per-vehicle |
| Mileage nudge | Sunday 10am | Weekly |

## Pricing
- **Yearly:** $19.99/year (7-day free trial)
- **Lifetime:** $39.99 one-time
- Lifetime pays for itself in ~2 years (price anchor)
- "RECOMMENDED" badge on yearly (trial CTA)
- "Save X% vs Lifetime" dynamic badge

## Key Differentiators vs Competitors
1. **No ads** — ever, free or pro (ServiceLog has ads in free)
2. **Maintenance health score** — unique, no competitor has this
3. **Seasonal suggestions** — proactive, context-aware
4. **Streak system** — no car maintenance app does this
5. **Cost projection & YoY** — deeper analytics than ServiceLog
6. **Privacy-first** — no account, no data collection, iCloud sync
