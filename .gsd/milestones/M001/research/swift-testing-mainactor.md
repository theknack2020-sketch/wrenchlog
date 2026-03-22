# Swift Testing Framework: @MainActor Isolation in Swift 6

## Summary

When a class like `UserSettings` is marked `@MainActor`, Swift 6 strict concurrency forbids accessing its properties or methods from nonisolated contexts. The error `main actor-isolated property cannot be mutated from a nonisolated context` occurs because Swift Testing test functions default to nonisolated execution. The fix: mark the test `@Suite` struct (or individual `@Test` functions) with `@MainActor` so they share the same isolation domain.

## The Problem

```
// UserSettings.swift
@Observable @MainActor
final class UserSettings {
    static let shared = UserSettings()
    var distanceUnit: DistanceUnit { ... }
    func formatMileage(_ miles: Int) -> String { ... }
}
```

```
// ❌ Fails in Swift 6 strict concurrency
@Suite struct UnitTests {
    @Test func formatMiles() {
        let settings = UserSettings.shared          // ERROR: main actor-isolated
        settings.distanceUnit = .miles              // ERROR: cannot mutate
        #expect(settings.formatMileage(50000) == "50,000 mi")
    }
}
```

**Why it fails:** Swift Testing runs test functions in a nonisolated, parallelized context by default. `UserSettings` is `@MainActor`-isolated. Accessing it synchronously from nonisolated code is a data race the compiler now rejects.

## Key Findings

### 1. Should test functions be marked `@MainActor`?

**Yes — this is a valid approach.** You can annotate individual test functions:

```swift
@Test @MainActor func formatMiles() { ... }
```

This makes that specific test run in the main actor's execution context, allowing synchronous access to `@MainActor`-isolated types.

**Sources:** Hacking with Swift shows `@Test @MainActor func` as the first option for Swift Testing actor isolation. The "Introduction to Swift Testing" guide confirms `@MainActor` on test functions ensures they "run on the main thread, which is important for the correct functioning of the user interface."

### 2. Should the @Suite struct be marked `@MainActor`?

**Yes — this is the recommended approach when all tests in the suite need MainActor access.** Unlike XCTest (where `@MainActor` on the class conflicted with nonisolated `XCTestCase` superclass), Swift Testing has no such restriction:

```swift
@MainActor
@Suite("Unit Formatting Tests")
struct UnitTests {
    @Test func formatMiles() {
        // All access to @MainActor types works here
    }
}
```

**Key advantage:** Swift Testing suites are structs — no Objective-C superclass, no isolation conflict. You can freely annotate the whole suite.

**Sources:** Fat Bob Man's guide states: "In Swift Testing, such restrictions do not exist. You can directly use the @MainActor annotation on a Suite." The XCTest limitation (`Main actor-isolated class has different actor isolation from nonisolated superclass 'XCTestCase'`) simply does not apply because Swift Testing suites don't inherit from `XCTestCase`.

**Parallelization note:** Even with `@MainActor` on the suite, tests still execute in parallel by default. Add `.serialized` trait to `@Suite` if sequential execution is needed.

### 3. How Swift Testing handles actor isolation differently from XCTest

| Aspect | XCTest | Swift Testing |
|--------|--------|---------------|
| **Type** | Class inheriting `XCTestCase` (Obj-C) | Struct/class/actor (pure Swift) |
| **@MainActor on type** | ⚠️ Error in Swift 6: "different actor isolation from nonisolated superclass" | ✅ Works cleanly — no superclass conflict |
| **@MainActor on methods** | Works (workaround for class-level restriction) | Works |
| **setUp/tearDown** | Obj-C methods, can't have actor isolation overrides | `init`/`deinit` on the suite struct — inherits suite's actor |
| **Default execution** | Sync tests run on main actor; async tests run on background | All tests run nonisolated by default (parallelized) |
| **Parallelization** | Sequential by default | Parallel by default |

**Critical difference:** XCTest's `XCTestCase` is an Objective-C class with no actor annotations. Swift 6 flags the mismatch when you try to make a subclass `@MainActor`. Swift Testing suites are plain Swift types — `@MainActor` composes naturally.

**Sources:** QualityCoding.org explains the XCTest issue: XCTestCase is Objective-C, "which knows nothing about actors." With Xcode 16, class-level `@MainActor` on `XCTestCase` works again, but setUp/tearDown still have issues. Swift Testing avoids all of this by being pure Swift with `init`/`deinit` instead of setUp/tearDown.

### 4. Swift 6.2 `defaultIsolation` (future improvement)

Swift 6.2 introduces a module-level setting:

```swift
// Package.swift swiftSettings
.defaultIsolation(MainActor.self)
```

With this, all types in the module (including test suites) implicitly get `@MainActor` isolation. Tests that need to run off the main actor use the new `@concurrent` attribute. This is the future direction but requires Swift 6.2 toolchain.

**Source:** SwiftCrafted.dev shows this pattern working with Swift Testing suites — "With default MainActor isolation enabled in your module, your tests work seamlessly."

## Corrected Test File

```swift
import Testing
import Foundation
@testable import WrenchLog

// MARK: - Service Type Tests

@Suite("Service Type Tests")
struct ServiceTypeTests {

    @Test("All 22 service types have a category")
    func allTypesHaveCategory() {
        for type in ServiceType.allCases {
            #expect(ServiceCategory.allCases.contains(type.category))
        }
    }

    @Test("Service types are distributed across all non-custom categories")
    func typeDistribution() {
        let nonCustomCategories = ServiceCategory.allCases.filter { $0 != .custom }
        for category in nonCustomCategories {
            let types = ServiceType.types(for: category)
            #expect(!types.isEmpty, "Category \(category.rawValue) has no types")
        }
    }

    @Test("Total service types count is 22")
    func totalCount() {
        #expect(ServiceType.allCases.count == 22)
    }

    @Test("Oil change has default mileage interval")
    func oilChangeDefaults() {
        #expect(ServiceType.oilChange.defaultMileageInterval == 5000)
        #expect(ServiceType.oilChange.defaultMonthInterval == 6)
    }

    @Test("General repair has no default interval")
    func generalRepairNoDefaults() {
        #expect(ServiceType.generalRepair.defaultMileageInterval == 0)
        #expect(ServiceType.generalRepair.defaultMonthInterval == 0)
    }

    @Test("Each type has an icon")
    func allTypesHaveIcons() {
        for type in ServiceType.allCases {
            #expect(!type.icon.isEmpty)
        }
    }
}

// MARK: - Unit Formatting Tests
// ✅ @MainActor on the suite — all tests run in MainActor context
// This is required because UserSettings is @MainActor @Observable

@MainActor
@Suite("Unit Formatting Tests")
struct UnitTests {

    @Test("Distance formatting - miles")
    func formatMiles() {
        let settings = UserSettings.shared
        settings.distanceUnit = .miles
        #expect(settings.formatMileage(50000) == "50,000 mi")
        #expect(settings.formatMileage(0) == "No mileage set")
    }

    @Test("Distance formatting - km")
    func formatKm() {
        let settings = UserSettings.shared
        settings.distanceUnit = .km
        let result = settings.formatMileage(80000)
        #expect(result.contains("km"))
        settings.distanceUnit = .miles // reset
    }

    @Test("Cost formatting")
    func formatCost() {
        let settings = UserSettings.shared
        settings.currency = .usd
        #expect(settings.formatCost(45.99) == "$45.99")
        settings.currency = .eur
        #expect(settings.formatCost(45.99) == "€45.99")
        settings.currency = .usd // reset
    }

    @Test("All currencies have symbols")
    func currencySymbols() {
        for currency in Currency.allCases {
            #expect(!currency.symbol.isEmpty)
        }
    }
}

// MARK: - Service Category Tests

@Suite("Service Category Tests")
struct CategoryTests {

    @Test("All categories have icons")
    func allHaveIcons() {
        for cat in ServiceCategory.allCases {
            #expect(!cat.icon.isEmpty)
        }
    }

    @Test("Category count is 6")
    func categoryCount() {
        #expect(ServiceCategory.allCases.count == 6)
    }
}
```

## Rules of Thumb

1. **If the system under test is `@MainActor`, mark the `@Suite` as `@MainActor`.**
   No half-measures — the suite struct, its `init`, and all `@Test` methods share the isolation.

2. **Prefer `@MainActor` on the suite over individual functions** when most tests in the suite touch MainActor-isolated types. It's less noisy and mirrors the actual isolation boundary.

3. **Use `@MainActor` on individual `@Test` functions** when only one or two tests in an otherwise nonisolated suite need main actor access.

4. **For mixed suites:** split into two `@Suite` structs — one `@MainActor`, one nonisolated. Each struct is cheap; there's no setup cost like XCTest classes.

5. **Don't fight the compiler with `@unchecked Sendable` or `nonisolated(unsafe)`** — those suppress warnings without fixing the data race. `@MainActor` on the test is the correct, zero-cost fix.

6. **`ServiceType`, `ServiceCategory`, `Currency`, `DistanceUnit`** are enums (value types, implicitly Sendable) — their tests don't need `@MainActor`. Only suites that touch `@MainActor`-isolated reference types need it.

## Sources

1. [Hacking with Swift — Force concurrent tests to run on a specific actor](https://www.hackingwithswift.com/quick-start/concurrency/how-to-force-concurrent-tests-to-run-on-a-specific-actor)
2. [Fat Bob Man — Mastering the Swift Testing Framework](https://fatbobman.com/en/posts/mastering-the-swift-testing-framework/)
3. [QualityCoding.org — XCTest Meets @MainActor](https://qualitycoding.org/xctest-mainactor/)
4. [SwiftCrafted.dev — Complete Guide to Swift Testing](https://swiftcrafted.dev/article/complete-guide-swift-testing-first-test-advanced-patterns)
5. [Swift Ultimate Testing Playbook (GitHub Gist)](https://gist.github.com/steipete/84a5952c22e1ff9b6fe274ab079e3a95)
6. [Donny Wals — Exploring concurrency changes in Swift 6.2](https://www.donnywals.com/exploring-concurrency-changes-in-swift-6-2/)
7. [Introduction to Swift Testing (Medium)](https://medium.com/@maxches99/introduction-to-swift-testing-66fed7027435)
