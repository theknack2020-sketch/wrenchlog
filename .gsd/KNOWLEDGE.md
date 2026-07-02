# Knowledge

| ID | Rule | Source |
|----|------|--------|
| K001 | Never commit AuthKey_*.p8, *.p12, .env to git repos | Lumifaste GitGuardian incident |
| K002 | ASC subscription pricing can't be set via API (409) — do manually | Lumifaste M003 |
| K003 | Use xcodebuild archive with -allowProvisioningUpdates for entitlement apps | AquaFaste M002 |
| K004 | App Store requires iPad 13" screenshots | Lumifaste M003 |
| K005 | Use reviewSubmissions API for submit | Lumifaste M003 |
| K006 | ASC description: no emoji, keywords max 100 chars | AquaFaste M002 |
| K007 | Age rating: scale fields = "NONE" string, toggle fields = false boolean | AquaFaste M002 |
| K008 | Competitor apps (CARFAX, Drivvo) collect excessive user data — privacy is a differentiator | Web research |
| K009 | ServiceLog charges $24.99/yr or $69.99 lifetime — there's willingness to pay in this category | Web research |
| K010 | Onboarding binding inversion bug: if `@Binding var isComplete` is bound to `showOnboarding` (true=showing), setting `isComplete = true` is a no-op because the value doesn't change. Use `isShowing` with `= false` to dismiss, or invert the semantics. Always test onboarding dismiss on iPad. | WrenchLog 1.0.0 rejection — Guideline 2.1(a) |
