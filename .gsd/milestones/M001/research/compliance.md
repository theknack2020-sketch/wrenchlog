# App Store Compliance Research — WrenchLog

> Vehicle maintenance tracker · SwiftUI + SwiftData · No ads, no analytics, no tracking, no third-party SDKs · All data on-device

---

## 1. Privacy Nutrition Labels

### What They Are
Apple requires all apps to disclose data collection practices through "privacy nutrition labels" visible on each app's product page. This is mandatory for all new apps and updates since December 2020 (iOS 14.3).

### WrenchLog's Position: "Data Not Collected"
This is the cleanest possible label. Apps that collect no data display a unique **"Data Not Collected"** badge on the App Store.

**Key definition from Apple:** "Collect" means transmitting data off the device in a way that allows you and/or third-party partners to access it. **Data that is processed only on device is not "collected" and does not need to be disclosed.** Since WrenchLog uses SwiftData with local-only storage and has zero third-party SDKs, this applies perfectly.

### App Store Connect Questionnaire
When submitting, you'll answer privacy questions. For WrenchLog:
- **Do you or your third-party partners collect data from this app?** → **No**
- That's it. Answering "No" produces the "Data Not Collected" label.

### Privacy Manifest File (PrivacyInfo.xcprivacy)
Since May 1, 2024, apps that use "Required Reason APIs" must include a privacy manifest. Even with no third-party SDKs, WrenchLog likely uses some system APIs that require declaration:

| API Category | Likely Used? | Reason |
|---|---|---|
| `NSPrivacyAccessedAPICategoryUserDefaults` | Yes | UserDefaults for app preferences |
| `NSPrivacyAccessedAPICategoryFileTimestamp` | Maybe | If reading file timestamps |
| `NSPrivacyAccessedAPICategoryDiskSpace` | No | Not needed |
| `NSPrivacyAccessedAPICategorySystemBootTime` | No | Not needed |

**Action:** Create `PrivacyInfo.xcprivacy` declaring UserDefaults usage with reason code `CA92.1` (app functionality). Even if no third-party SDKs exist, Apple validates this at upload time.

### Privacy Policy URL
**Required for all apps**, even those that collect no data. Apple requires:
1. A privacy policy URL in App Store Connect metadata
2. The policy accessible from within the app (typically Settings/About)

For a "no data collected" app, the policy can be simple — stating that no personal information is collected or transmitted. Host it on a simple webpage (GitHub Pages, personal site).

### What NOT to Do
- Don't add Firebase, Crashlytics, AdMob, or any analytics SDK — each would require data disclosures
- Don't use IDFA or IDFV — triggers tracking/linking disclosures
- Don't add a "contact us via email" form that transmits data without disclosing it
- If StoreKit 2 transaction data stays on-device (which it does with native StoreKit), no disclosure needed for IAP

---

## 2. Age Rating

### Current System (Updated July 2025)
Apple expanded the age rating system with new categories: **4+, 9+, 13+, 16+, 18+** (replacing the old 4+, 9+, 12+, 17+). All developers must answer updated questionnaire by **January 31, 2026**.

### WrenchLog's Target: 4+
A vehicle maintenance tracker has zero objectionable content. The questionnaire covers:

| Category | WrenchLog Answer |
|---|---|
| **Cartoon/Fantasy Violence** | None |
| **Realistic Violence** | None |
| **Sexual Content** | None |
| **Profanity/Crude Humor** | None |
| **Alcohol/Tobacco/Drug Use** | None |
| **Simulated Gambling** | None |
| **Horror/Fear Themes** | None |
| **Medical/Wellness Topics** | None (vehicle maintenance ≠ health) |
| **In-App Controls** | N/A (no parental controls needed) |
| **Capabilities** | No chat, no web access, no social features |
| **Violent Themes** | None |

All "None" / "No" answers → **4+ rating** in all regions.

### Regional Variations
Age ratings can vary by region. With all-zero content descriptors, WrenchLog should receive 4+ globally. Some countries (Australia, Brazil, Korea) have specific rating systems, but a utility app with no objectionable content maps to the lowest tier everywhere.

### Metadata Constraint
Per Guideline 2.3.8: all metadata (icons, screenshots, previews) must adhere to **4+ age rating** regardless of app rating. Not an issue for WrenchLog, but worth noting.

---

## 3. Required Metadata for Submission

### App Store Connect Fields

| Field | Requirement | WrenchLog Notes |
|---|---|---|
| **App Name** | ≤30 chars | "WrenchLog" ✓ |
| **Subtitle** | ≤30 chars | e.g., "Vehicle Maintenance Tracker" |
| **Description** | ≤4000 chars | Feature-focused, no keyword stuffing |
| **Keywords** | ≤100 chars, comma-separated | Research needed for ASO |
| **Category** | Primary + optional secondary | Primary: **Utilities** or **Lifestyle** |
| **Privacy Policy URL** | Required for all apps | Must be live at submission |
| **Support URL** | Required | Must include easy contact method |
| **Marketing URL** | Optional | Nice to have |
| **App Icon** | 1024×1024 PNG, no alpha | Single icon, no layers |
| **Screenshots** | Per device size | iPhone 6.7", 6.5", 5.5"; iPad 13" required |
| **App Preview** | Optional video | Up to 30 seconds |
| **Copyright** | Required | "© 2026 [Developer Name]" |
| **SKU** | Internal identifier | e.g., "wrenchlog-ios" |
| **Bundle ID** | Reverse domain | e.g., "com.yourname.wrenchlog" |
| **Build** | Uploaded via Xcode/Transporter | Built with current Xcode |
| **Age Rating** | Questionnaire-derived | 4+ (see above) |
| **Pricing** | Free with IAP, or paid | Free + StoreKit 2 IAP |
| **Availability** | Countries/regions | US + EU markets initially |
| **Localization** | Per-language metadata | English required; Turkish optional |

### Screenshot Requirements (Critical)
- **iPhone 6.7"** (iPhone 15 Pro Max / 16 Pro Max): required
- **iPhone 6.5"** (iPhone 11 Pro Max etc.): required for older display support
- **iPhone 5.5"** (iPhone 8 Plus): may be required if supporting older devices
- **iPad 13"**: required if app runs on iPad (and it will by default on SwiftUI)
- Format: PNG or JPEG, no alpha, no rounded corners (Apple adds those)

### Review Notes
- No login required → simpler review
- No special hardware → no extra notes needed
- Describe key flows briefly for the reviewer

### Content Rights
If your app displays user-generated content (like vehicle photos), you should be prepared to answer "Yes, I own or have rights to all content" in the Content Rights section. Since WrenchLog only displays user's own data entered locally, this is straightforward.

---

## 4. Content Rights & Intellectual Property

### Guideline 5.2 — Intellectual Property
- All content (icons, screenshots, previews) must be original or properly licensed
- Don't use car manufacturer logos (BMW, Toyota, etc.) in screenshots or the app itself without permission
- Don't copy UI from competitor apps (CARFAX, Drivvo, etc.)
- Vehicle silhouettes/icons should be generic or custom-designed

### Guideline 2.3.9 — Screenshots & Previews
- Use fictional account information in screenshots (not real user data)
- Screenshots must show actual app functionality
- Don't show features that don't exist yet

### Guideline 4.1c — Brand Usage
- Cannot use another developer's icon, brand, or product name in metadata without permission
- Don't mention "CARFAX alternative" or "better than Drivvo" in descriptions/keywords

### Vehicle Data
- Vehicle makes/models are factual data (Ford F-150, Toyota Camry) — using them as data entries is fine
- Don't use trademarked logos as visual elements
- Service interval data should be generic/user-entered, not copied from copyrighted manuals

### Open Source Compliance
- No third-party dependencies planned → no OSS license compliance issues
- If any are added later, check licenses (MIT/Apache OK, GPL requires care)

---

## 5. GDPR Compliance for EU Distribution

### Does GDPR Apply to WrenchLog?
**Technically yes** — if the app is available in the EU, GDPR applies. But WrenchLog's architecture makes compliance nearly effortless.

### Why WrenchLog Is GDPR-Friendly By Design

| GDPR Principle | WrenchLog Status |
|---|---|
| **Lawful basis for processing** | No data processing occurs off-device |
| **Data minimization** | Only user-entered vehicle/service data, stored locally |
| **Purpose limitation** | Data used only for the stated purpose (maintenance tracking) |
| **Storage limitation** | User controls their own data lifecycle |
| **Right to access** | Data is on user's device — they already have access |
| **Right to erasure** | User can delete any record; app deletion removes all data |
| **Right to portability** | Possible via export feature (JSON/CSV) — nice to have |
| **Data protection by design** | On-device storage with no transmission = privacy by design |
| **Breach notification** | No server = no breach risk from app side |

### What's Still Required

1. **Privacy Policy** — Must mention GDPR compliance for EU users. Even with no data collection, state:
   - What data the app stores locally (vehicle info, service records, fuel logs)
   - That no data leaves the device
   - That no third parties receive any data
   - Contact information for privacy inquiries
   - Reference to GDPR rights (access, erasure, portability)

2. **No DPO Required** — A Data Protection Officer is only required for organizations doing large-scale data processing. A solo developer with an on-device app is exempt.

3. **No DPIA Required** — Data Protection Impact Assessment is for high-risk processing. Local-only storage doesn't qualify.

4. **StoreKit 2 / Apple's Processing** — Apple handles payment processing for IAP. Apple is the data controller for transaction data. You don't need to disclose Apple's own processing, but your privacy policy should mention that purchases are processed by Apple per their privacy policy.

### Cookie/Tracking Consent
- No cookies (native app)
- No tracking → no ATT prompt needed
- No consent banner needed

---

## 6. Summary: Compliance Checklist

### Before First Submission

- [ ] Create `PrivacyInfo.xcprivacy` with Required Reason API declarations
- [ ] Write and host privacy policy webpage (covers both App Store requirement and GDPR)
- [ ] Link privacy policy in App Store Connect AND in-app Settings
- [ ] Complete privacy nutrition label questionnaire → "Data Not Collected"
- [ ] Complete age rating questionnaire → 4+ globally
- [ ] Prepare all required screenshots (iPhone 6.7", iPad 13" minimum)
- [ ] Set up support URL with contact method
- [ ] Verify all screenshot content uses fictional data
- [ ] Verify no trademarked logos appear in app or screenshots
- [ ] Set copyright field
- [ ] Configure pricing + IAP in App Store Connect
- [ ] Select availability regions (US + EU)

### Privacy Policy Must Include
- [ ] App name and developer contact
- [ ] Statement: no data collected or transmitted
- [ ] Description of locally stored data types
- [ ] GDPR rights acknowledgment (access, erasure, portability)
- [ ] Apple's role in payment processing
- [ ] Effective date
- [ ] How to contact developer for privacy questions

### Ongoing Compliance
- Update privacy labels if ANY SDK is added in the future
- Update age rating answers if features change
- Keep privacy policy URL active and current
- Re-answer age rating questionnaire by January 31, 2026 deadline (if not submitted before then)

---

## Sources

1. [Apple — App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/) — Official privacy label requirements
2. [Apple — App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) — Full review guidelines including 2.3, 5.1.1, 5.2
3. [Apple — Updated Age Ratings](https://developer.apple.com/news/?id=ks775ehf) — July 2025 age rating system update
4. [Apple — Set App Age Rating](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating/) — Questionnaire instructions
5. [Apple — Submitting to App Store](https://developer.apple.com/app-store/submitting/) — Submission requirements and SDK deadlines
6. [App Store Privacy Policy Requirements 2025](https://iossubmissionguide.com/app-store-privacy-policy-requirements) — Comprehensive privacy requirement guide
7. [App Store Age Ratings Guide](https://capgo.app/blog/app-store-age-ratings-guide/) — 2025 rating categories and questionnaire walkthrough
8. [iOS Privacy Measures: GDPR and Privacy Manifests](https://medium.com/axel-springer-tech/apple-privacy-measures-gdpr-privacy-nutrition-labels-app-tracking-transparency-and-privacy-912a7dabc85e) — Privacy manifest and GDPR intersection
