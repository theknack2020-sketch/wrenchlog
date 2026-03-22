# Service Reminder System — Research

## Summary

A vehicle maintenance reminder system needs two independent trigger dimensions — **time-based** (e.g. "every 6 months") and **mileage-based** (e.g. "every 5,000 km") — firing on **whichever comes first**. iOS provides `UNUserNotificationCenter` for local notifications with three trigger types, a hard limit of 64 pending scheduled notifications, and `threadIdentifier` for grouping. The mileage dimension cannot be scheduled as a system notification because it depends on user-reported odometer readings; it must be evaluated at app launch / odometer update and converted to a time-based notification or in-app alert. Competitor apps (CARFAX, Simply Auto, Car Maintenance Reminder) all use this dual model and prompt users weekly/monthly to update their odometer.

---

## 1. Time-Based Reminders (UNNotification Scheduling)

### Trigger Types Available

| Trigger | Use Case | Repeats? |
|---------|----------|----------|
| `UNTimeIntervalNotificationTrigger` | Fire N seconds from now | Yes (min 60s) |
| `UNCalendarNotificationTrigger` | Fire at specific date/time or recurring pattern | Yes |
| `UNLocationNotificationTrigger` | Fire on geofence entry/exit | Yes |

**For maintenance reminders, `UNCalendarNotificationTrigger` is the right choice.** It accepts `DateComponents` — set only the fields you need (hour, day, month, weekday) and iOS matches on those components, ignoring unset ones.

### Scheduling Pattern

```swift
// Request permission first
UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
    // handle
}

// Schedule a reminder
let content = UNMutableNotificationContent()
content.title = "Oil Change Due"
content.body = "Your Honda Civic is due for an oil change"
content.sound = .default
content.categoryIdentifier = "MAINTENANCE_REMINDER"
content.threadIdentifier = "vehicle-\(vehicleId)"  // groups by vehicle
content.userInfo = [
    "vehicleId": vehicleId,
    "serviceType": "oil_change",
    "reminderId": reminderId
]

// Fire on a specific date
let components = Calendar.current.dateComponents(
    [.year, .month, .day, .hour, .minute],
    from: dueDate
)
let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

let request = UNNotificationRequest(
    identifier: "reminder-\(reminderId)",
    content: content,
    trigger: trigger
)
UNUserNotificationCenter.current().add(request)
```

### Key Constraints

- **64 pending notification limit**: iOS keeps only the 64 soonest-firing scheduled notifications per app. Anything beyond that is silently dropped. This is the single most important constraint for our design.
  - Source: Apple Developer Forums confirm this limit persists through iOS 17+.
  - Todoist's engineering team built a `LocalNotificationScheduler` that stores overflow notifications on disk (UserDefaults) and reschedules them as slots open.
  - **Our strategy**: Schedule only the next upcoming reminder per service item per vehicle. With ~12 service types × 3 vehicles = 36 notifications — comfortably under 64.

- **Deterministic identifiers**: Use stable identifiers (e.g. `"reminder-\(vehicleId)-\(serviceType)"`) so re-scheduling replaces the old notification instead of creating duplicates. Adding a request with the same identifier as a pending one replaces it.

- **Don't use `removeAllPendingNotificationRequests()`**: This is a common bug source — it removes ALL scheduled notifications including ones from other features. Use `removePendingNotificationRequests(withIdentifiers:)` for targeted removal.

- **Repeating triggers count as 1 notification** toward the 64 limit, but they aren't ideal for maintenance reminders because intervals aren't fixed — they change based on when the service was last performed.

---

## 2. Mileage-Based Reminders

Mileage-based reminders **cannot be scheduled as system notifications** because the app has no way to know when a mileage threshold will be reached. They depend entirely on user-reported odometer readings.

### Odometer Update Strategy

Competitor apps handle this with a two-pronged approach:

1. **Periodic "update your odometer" nudge**: A recurring notification (weekly or monthly, user-configurable) that reminds the user to open the app and enter their current mileage.
   - Car Maintenance Reminders app offers "weekly or monthly notification reminding you to update your vehicle's mileage."
   - This is a simple repeating `UNCalendarNotificationTrigger`.

2. **On-update evaluation**: When the user enters a new odometer reading, the app recalculates all mileage-based reminders and:
   - Displays in-app alerts for any services now due or overdue
   - Schedules/updates time-based notifications for services approaching their mileage threshold (by estimating the date based on driving patterns)

### Mileage Estimation Algorithm

To bridge the gap between mileage and time, estimate when a mileage threshold will be reached:

```
averageDailyKm = (currentOdometer - previousOdometer) / daysBetweenReadings
kmRemaining = nextServiceMileage - currentOdometer
estimatedDaysUntilDue = kmRemaining / averageDailyKm
estimatedDueDate = today + estimatedDaysUntilDue
```

This estimated date can then be scheduled as a `UNCalendarNotificationTrigger`. **Recalculate on every odometer update** to keep the estimate accurate.

### Data Model for Odometer History

```swift
struct OdometerReading {
    let id: UUID
    let vehicleId: UUID
    let reading: Int          // km or miles
    let date: Date
    let source: OdometerSource // .manual, .fuelLog, .serviceLog
}

enum OdometerSource {
    case manual        // user entered directly
    case fuelLog       // captured during fuel fill-up
    case serviceLog    // captured when logging a service
}
```

**Opportunistic capture**: Prompt for odometer when logging fuel or service — reduces the need for dedicated odometer-update sessions.

---

## 3. Dual-Trigger System (Whichever Comes First)

The core logic: each service reminder has both a **date threshold** and a **mileage threshold**. The reminder fires when **either** is reached.

### Data Model

```swift
struct ServiceReminder {
    let id: UUID
    let vehicleId: UUID
    let serviceType: ServiceType
    
    // Interval configuration
    let intervalMonths: Int?       // e.g. 6 months
    let intervalKm: Int?           // e.g. 5000 km
    
    // Calculated from last service + interval
    let nextDueDate: Date?         // time trigger
    let nextDueKm: Int?            // mileage trigger
    
    // Status
    let status: ReminderStatus     // .upcoming, .dueSoon, .overdue, .completed
    let lastServiceDate: Date?
    let lastServiceKm: Int?
}

enum ReminderStatus {
    case upcoming      // not yet in warning zone
    case dueSoon       // within warning threshold (e.g. 30 days or 500 km)
    case overdue       // past due on either dimension
    case completed     // service was performed, waiting for next cycle
}
```

### Evaluation Logic

```swift
func evaluateReminder(_ reminder: ServiceReminder, 
                      currentOdometer: Int, 
                      today: Date) -> ReminderStatus {
    
    let dateStatus = evaluateDateDimension(reminder, today: today)
    let mileageStatus = evaluateMileageDimension(reminder, currentOdometer: currentOdometer)
    
    // Whichever is worse wins
    return max(dateStatus, mileageStatus)
}

func evaluateDateDimension(_ reminder: ServiceReminder, today: Date) -> ReminderStatus {
    guard let dueDate = reminder.nextDueDate else { return .upcoming }
    let daysUntilDue = Calendar.current.dateComponents([.day], from: today, to: dueDate).day ?? 0
    
    if daysUntilDue < 0 { return .overdue }
    if daysUntilDue <= 30 { return .dueSoon }
    return .upcoming
}

func evaluateMileageDimension(_ reminder: ServiceReminder, currentOdometer: Int) -> ReminderStatus {
    guard let dueKm = reminder.nextDueKm else { return .upcoming }
    let kmRemaining = dueKm - currentOdometer
    
    if kmRemaining < 0 { return .overdue }
    if kmRemaining <= 500 { return .dueSoon }
    return .upcoming
}
```

### Notification Scheduling Strategy

When to reschedule notifications:
1. **App launch** — recalculate all reminders, reschedule notifications
2. **Odometer update** — recalculate mileage-dependent estimated dates
3. **Service logged** — reset the reminder cycle, schedule next occurrence
4. **User edits reminder settings** — update intervals and reschedule

For each reminder, schedule the **earlier** of:
- The actual due date (time dimension)
- The estimated date based on mileage extrapolation

Also schedule a "due soon" warning notification (e.g. 7 days before, or when estimated 500 km remain).

---

## 4. Multi-Vehicle Support

### Notification Budget Management

With 64 notifications max, budget carefully:

| Allocation | Count |
|-----------|-------|
| Per-vehicle service reminders (next due only) | ~12 types × N vehicles |
| "Update odometer" nudges | 1 per vehicle |
| "Due soon" warnings | variable |
| **Budget for 3 vehicles** | ~36 service + 3 odometer + ~10 warnings = **~49** |
| **Budget for 5 vehicles** | ~60 service + 5 odometer + warnings = **hits limit** |

**Design decision**: For 5+ vehicles, prioritize by soonest due date. Only schedule notifications for the 50 most urgent items, store the rest in the app's local database, and backfill when slots open (on app launch or when a notification fires).

### Per-Vehicle Grouping

Use `threadIdentifier` to group notifications by vehicle:

```swift
content.threadIdentifier = "vehicle-\(vehicle.id.uuidString)"
content.summaryArgument = vehicle.displayName  // "2020 Honda Civic"
```

Register notification categories with summary format:

```swift
let category = UNNotificationCategory(
    identifier: "MAINTENANCE_REMINDER",
    actions: [snoozeAction, markDoneAction],
    intentIdentifiers: [],
    hiddenPreviewsBodyPlaceholder: "",
    categorySummaryFormat: "%u more reminders for %@",
    options: []
)
UNUserNotificationCenter.current().setNotificationCategories([category])
```

This produces grouped notifications like:
```
🚗 2020 Honda Civic
  Oil Change Due — Due in 3 days
  3 more reminders for 2020 Honda Civic
```

### Identifier Scheme

Use deterministic, hierarchical identifiers:

```
reminder-{vehicleId}-{serviceType}           // main due notification
reminder-{vehicleId}-{serviceType}-warning    // "due soon" warning
odometer-nudge-{vehicleId}                    // periodic odometer prompt
```

This allows targeted removal/replacement without affecting other notifications.

---

## 5. Smart Reminder Grouping

### In-App Grouping

Beyond notification-level grouping, the app should present reminders intelligently:

**By urgency (primary sort)**:
- 🔴 Overdue — past due date or mileage
- 🟡 Due Soon — within 30 days / 500 km
- 🟢 Upcoming — scheduled but not yet urgent

**By vehicle (secondary grouping)**:
- Each vehicle gets its own section in the reminders list
- Dashboard shows the "worst status" per vehicle as an at-a-glance indicator

**Service bundling**: When multiple services are due at similar times, suggest bundling them into a single shop visit:

```swift
// If oil change is due in 3 days and tire rotation is due in 15 days,
// suggest doing both together
func suggestBundledServices(for vehicle: Vehicle) -> [ServiceBundle] {
    let dueSoon = reminders.filter { $0.status == .dueSoon || $0.status == .overdue }
    let upcoming = reminders.filter { 
        $0.status == .upcoming && daysUntilDue($0) <= 45 
    }
    
    // Group overlapping windows
    // e.g. "Oil Change + Tire Rotation — consider doing together"
}
```

### Notification Consolidation

When multiple services are due on the same day for the same vehicle, send **one consolidated notification** instead of spamming:

```swift
content.title = "2020 Honda Civic — 3 Services Due"
content.body = "Oil Change, Tire Rotation, Air Filter"
```

Use a single notification identifier per vehicle per day for consolidation:

```
daily-digest-{vehicleId}-{yyyy-MM-dd}
```

---

## 6. Notification Best Practices

### Permission & Timing

- **Request permission contextually**: Don't ask on first launch. Wait until the user creates their first reminder, then explain why notifications matter: "We'll remind you when services are due so you never miss maintenance."
- **Respect user preferences**: Let users choose notification timing (morning vs evening), and lead time (1 week, 3 days, 1 day before).
- **Don't over-notify**: One notification per reminder event. If the user doesn't act, wait before sending another (e.g. snooze for 3 days, not every day).

### Actionable Notifications

Register custom actions so users can respond without opening the app:

```swift
let snoozeAction = UNNotificationAction(
    identifier: "SNOOZE_1_WEEK",
    title: "Remind me in 1 week",
    options: []
)
let markDoneAction = UNNotificationAction(
    identifier: "MARK_DONE",
    title: "Done — Log Service",
    options: [.foreground]  // opens app to log the service
)
let category = UNNotificationCategory(
    identifier: "MAINTENANCE_REMINDER",
    actions: [snoozeAction, markDoneAction],
    intentIdentifiers: [],
    options: []
)
```

### Notification Lifecycle

```
Service logged
  → Calculate next due date + next due km
  → Schedule "due soon" warning notification
  → Schedule "due now" notification
  → Store in local DB as source of truth

App launches
  → Fetch all pending system notifications
  → Compare with DB state
  → Reconcile: add missing, remove stale, update changed

Odometer updated
  → Recalculate all mileage estimates
  → Reschedule affected notifications
  → Show in-app alert if anything is now overdue

Notification fires
  → User taps → deep link to specific vehicle + service
  → User snoozes → reschedule with delay
  → User marks done → open service logging flow
```

### Reliability Pattern

The local database is the **source of truth**, not the notification center. Notifications are a delivery mechanism that gets reconciled on every app launch:

```swift
func reconcileNotifications() async {
    let dbReminders = await database.fetchAllActiveReminders()
    let pendingNotifications = await UNUserNotificationCenter.current()
        .pendingNotificationRequests()
    
    let pendingIds = Set(pendingNotifications.map { $0.identifier })
    let expectedIds = Set(dbReminders.map { $0.notificationIdentifier })
    
    // Remove stale
    let staleIds = pendingIds.subtracting(expectedIds)
    UNUserNotificationCenter.current()
        .removePendingNotificationRequests(withIdentifiers: Array(staleIds))
    
    // Add missing (sorted by urgency, up to budget)
    let missingReminders = dbReminders
        .filter { !pendingIds.contains($0.notificationIdentifier) }
        .sorted { $0.effectiveDueDate < $1.effectiveDueDate }
        .prefix(notificationBudgetRemaining)
    
    for reminder in missingReminders {
        await scheduleNotification(for: reminder)
    }
}
```

---

## 7. Competitor Patterns Summary

| Feature | CARFAX Car Care | Car Maintenance Reminders | Simply Auto | OBDeleven |
|---------|----------------|--------------------------|-------------|-----------|
| Multi-vehicle | Up to 8 | Unlimited | Unlimited | Unlimited |
| Mileage + Date triggers | Yes | Yes | Yes | Yes |
| Odometer nudge | Unknown | Weekly/Monthly configurable | Auto (GPS trips) | Auto (OBD device) |
| Reminder lead times | Unknown | 1 month, 1 week, due day | Configurable | 30, 7, 1 day |
| Pre-loaded service types | Yes (model-specific) | Yes (categorized) | Yes | Yes |
| Custom reminders | Limited | Yes | Yes | Yes |

**Key differentiator opportunity**: Most apps make odometer updates feel like a chore. We can reduce friction by:
- Capturing odometer during fuel logs and service logs (opportunistic)
- Keeping the manual update to a single number field with smart defaults (last reading + average daily km)
- Making the odometer nudge notification actionable (tap to enter reading inline)

---

## 8. Recommended Architecture

```
┌─────────────────────────────────────────────┐
│              ReminderEngine                  │
│  ┌─────────────────┐  ┌──────────────────┐  │
│  │ TimeEvaluator    │  │ MileageEvaluator │  │
│  │ (pure date math) │  │ (odometer-based) │  │
│  └────────┬────────┘  └────────┬─────────┘  │
│           └───────┬────────────┘             │
│                   ▼                          │
│         DualTriggerResolver                  │
│         (whichever-comes-first)              │
│                   │                          │
│                   ▼                          │
│         NotificationScheduler                │
│         (budget-aware, reconciling)          │
└─────────────────────────────────────────────┘
          │                    │
          ▼                    ▼
   SwiftData DB         UNNotificationCenter
   (source of truth)    (delivery mechanism)
```

**Key principle**: The `ReminderEngine` is a pure calculation layer with no side effects. The `NotificationScheduler` is the only thing that talks to `UNUserNotificationCenter`. Reconciliation happens on app launch, odometer update, and service log.

---

## Sources

1. [Hacking with Swift — Scheduling Notifications](https://www.hackingwithswift.com/books/ios-swiftui/scheduling-local-notifications)
2. [Donny Wals — Scheduling Daily Notifications with Calendar and DateComponents](https://www.donnywals.com/scheduling-daily-notifications-on-ios-using-calendar-and-datecomponents/)
3. [Apple Developer Forums — 64 Notification Limit](https://developer.apple.com/forums/thread/106829)
4. [Todoist Engineering — Local Notification Scheduler](https://www.doist.dev/implementing-a-local-notification-scheduler-in-todoist-ios/)
5. [Hacking with Swift — Notification Grouping with threadIdentifier](https://www.hackingwithswift.com/example-code/system/how-to-group-user-notifications-using-threadidentifier-and-summaryargument)
6. [Smashing Magazine — Preparing for iOS 12 Notifications](https://www.smashingmagazine.com/2018/09/preparing-your-app-for-ios-12-notifications/)
7. [Car Maintenance Reminders App — App Store](https://apps.apple.com/us/app/car-maintenance-reminders/id1617869280)
8. [OBDeleven — Best Car Maintenance Apps](https://obdeleven.com/car-maintenance-apps)
9. [Apple Developer Docs — threadIdentifier](https://developer.apple.com/documentation/usernotifications/unnotificationcontent/threadidentifier)
10. [CreateWithSwift — Local Notifications with async/await](https://www.createwithswift.com/notifications-tutorial-creating-and-scheduling-user-notifications-with-async-await/)
