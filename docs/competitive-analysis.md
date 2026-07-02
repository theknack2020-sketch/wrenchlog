# WrenchLog — Competitive Analysis

> Date: 2026-03-31
> Market: iOS Vehicle Maintenance Tracker
> App ID: 6743597962

---

## 1. Market Overview

Vehicle maintenance tracker pazarı olgun ama parçalı. Baskın tek bir kazanan yok — kullanıcılar farklı ihtiyaçlara göre farklı uygulamalar tercih ediyor. Pazar 3 katmandan oluşuyor:

- **Hardware + App** (FIXD, OBDeleven, Carly) — OBD2 dongle gerektiren, tanılama odaklı
- **Platform Giants** (CARFAX) — Büyük veri avantajı, otomatik servis geçmişi
- **Pure Software** (Simply Auto, MyAutoLog, Road Trip, Fuelly, Drivvo, VMT, WrenchLog) — Doğrudan rakip alanı

**Trend:** Kullanıcılar hâlâ kâğıt not + Excel/Google Sheets kullanıyor. Forum'larda "I use a notebook" yorumları yaygın. Dijital dönüşüm fırsatı hâlâ büyük.

---

## 2. Top 5 Doğrudan Rakip

### 🥇 CARFAX Car Care
| | |
|---|---|
| **Platform** | iOS + Android |
| **Rating** | ⭐ 4.8 (iOS), 4.7 (Android) |
| **Fiyat** | Tamamen Ücretsiz |
| **Araç limiti** | 8 |
| **Moat** | Dealer/servis ağından otomatik servis geçmişi çekme |

**Güçlü:**
- Servis geçmişini otomatik çeken tek app (CARFAX veritabanı)
- Recall uyarıları
- Tamamen ücretsiz, reklamsız
- Tamir maliyet tahmini

**Zayıf:**
- Sadece Kuzey Amerika (US + Canada)
- Manuel loglama zayıf — profesyonel servise gidenlere odaklı
- DIY kullanıcılar için yetersiz detay
- Fuel tracking yok veya çok basit
- Veri export yok

**WrenchLog vs:** Biz privacy-first, CARFAX veri topluyor. Biz global, onlar sadece NA. Biz DIY-friendly detaylı loglama, onlar "set it and forget it". Biz fuel analytics, onlar yok.

---

### 🥈 Simply Auto
| | |
|---|---|
| **Platform** | iOS + Android + Web |
| **Rating** | ~4.5 |
| **Fiyat** | Freemium + Ads / Gold subscription |
| **Araç limiti** | Sınırsız (Pro) |
| **Moat** | GPS mileage tracking, vergi indirimi raporlama |

**Güçlü:**
- GPS ile otomatik trip tracking (vergi indirimi için)
- Oktan/marka/istasyon bazında yakıt takibi — sektörde en detaylı
- Cross-platform + web erişimi
- Cloud sync + otomatik haftalık/aylık rapor
- Sesli giriş desteği
- Elektrikli araç desteği (kWh)

**Zayıf:**
- Ücretsiz versiyonda reklam var
- UI "busy" olarak tanımlanıyor — basit log bile çok alan dolduruyor
- Data entry overwhelming (her yakıt girişi: odometre, miktar, oktan, marka, fiyat/L, toplam)
- Çok karmaşık, yeni kullanıcıyı korkutuyor

**WrenchLog vs:** Biz sade ve hızlı giriş, onlar her şeyi soruyor. Biz reklamsız, onlar reklamlı. Biz health score + gamification, onlar yok. Biz privacy-first (zero data collection), onlar cloud-dependent. Onların moat'u GPS mileage tracking — biz yapmıyoruz.

---

### 🥉 MyAutoLog
| | |
|---|---|
| **Platform** | iOS only (+ Mac Catalyst + visionOS) |
| **Rating** | ⭐ Yeni ama güçlü review'lar |
| **Fiyat** | Freemium, yearly subscription |
| **Araç limiti** | Sınırsız (Pro) |
| **Moat** | iOS 26 Liquid Glass UI, Garage Locator, iCloud sync |

**Güçlü:**
- "Best car maintenance tracker for iPhone" olarak 1 numarada önerilmiş
- Aktif ve responsive developer
- iCloud sync
- Garage/servis lokasyon bulucu (entegre harita)
- PDF export
- Modification tracking (sadece servis değil, modifikasyon da)
- iOS 26 uyumlu (Liquid Glass), Home Screen Quick Actions
- Document storage (sigorta, ruhsat)

**Zayıf:**
- Accessibility bildirilmemiş ("developer has not yet indicated")
- Yeni app — henüz az kullanıcı tabanı
- Fuel tracking basit (WrenchLog'un 6 yakıt tipi + MPG trend'leri vs)
- Health score yok
- Gamification yok
- Privacy yaklaşımı belirsiz

**WrenchLog vs:** En yakın doğrudan rakip. Benzer pozisyonlama (iOS-first, clean UI). Onların avantajı: iCloud sync, garage locator, modification tracking. Bizim avantajımız: health score, gamification (milestones/badges), smart reminders (driving pace-aware), seasonal tips, privacy-first (zero data), çok daha detaylı fuel analytics.

⚠️ **DİKKAT: MyAutoLog en hızlı büyüyen rakip. Yakından takip edilmeli.**

---

### 4. Road Trip (iOS)
| | |
|---|---|
| **Platform** | iOS only |
| **Fiyat** | Tek seferlik satın alma (premium) |
| **Moat** | Detaylı TCO analitikleri, data visualization |

**Güçlü:**
- Subscription YOK — tek seferlik ödeme, premium his
- Çok detaylı charts/analytics (MPG, cost-per-mile, TCO)
- CSV full export
- Uzun süredir piyasada, sadık kullanıcı tabanı

**Zayıf:**
- Ücretsiz deneme yok — "try before you buy" eksik
- Modern UI olmayabilir (eskiler)
- Reminders / push notification zayıf
- Health score yok
- Gamification yok

**WrenchLog vs:** Biz freemium — düşük bariyer. Biz health score, smart reminders, gamification. Onlar one-time, biz yearly + lifetime. Analytics alanında onlar daha derin olabilir ama trend yakalaşıyoruz.

---

### 5. Fuelly / Drivvo / AUTOsist (İkincil Rakipler)
| App | Odak | Fiyat | Platform |
|---|---|---|---|
| **Fuelly** | Fuel tracking (MPG master) | Free / Premium | iOS + Web |
| **Drivvo** | Fleet management | Freemium (ads) | iOS + Android |
| **AUTOsist** | Fleet inspection, checklists | Freemium | iOS + Android + Web |

**Ortak zayıflıklar:** Eski UI, modern iOS özelliklerini kullanmıyor, gamification yok, privacy odaklı değil.

---

## 3. Feature Matrix

| Feature | WrenchLog | CARFAX | Simply Auto | MyAutoLog | Road Trip |
|---|:---:|:---:|:---:|:---:|:---:|
| Service logging | ✅ 30+ tip | ✅ basic | ✅ detaylı | ✅ + mods | ✅ |
| Fuel tracking | ✅ 6 tip, MPG | ❌/basic | ✅ oktan+marka | ✅ basic | ✅ detaylı |
| Smart reminders | ✅ pace-aware | ✅ basic | ✅ basic | ✅ mileage/time | ⚠️ basic |
| **Health score** | ✅ 0-100 | ❌ | ❌ | ❌ | ❌ |
| **Gamification** | ✅ badges | ❌ | ❌ | ❌ | ❌ |
| **Seasonal tips** | ✅ | ❌ | ❌ | ❌ | ❌ |
| Cost analytics | ✅ Pro | ❌ | ✅ | ✅ Pro | ✅ detaylı |
| PDF export | ✅ Pro | ❌ | ⚠️ | ✅ Pro | ❌ |
| CSV export/import | ✅ | ❌ | ✅ | ⚠️ | ✅ |
| Multi-vehicle | ✅ Pro | ✅ (8) | ✅ | ✅ Pro | ✅ |
| Receipt photos | ✅ Pro | ✅ | ✅ | ✅ | ❌ |
| Recall alerts | ✅ (NHTSA) | ✅ (CARFAX) | ❌ | ❌ | ❌ |
| **Privacy (zero data)** | ✅ | ❌ | ❌ | ❓ | ⚠️ |
| iCloud sync | ❌ | N/A (server) | ❌ (own cloud) | ✅ | ❌ |
| GPS mileage | ❌ | ❌ | ✅ | ❌ | ❌ |
| Garage locator | ❌ | ✅ (repair shops) | ❌ | ✅ | ❌ |
| Mod tracking | ❌ | ❌ | ❌ | ✅ | ❌ |
| Cross-platform | ❌ | ✅ | ✅ | ❌ | ❌ |
| Ad-free | ✅ | ✅ | ❌ (free) | ✅ | ✅ |
| VIN decoder | ✅ | ✅ | ❌ | ❌ | ❌ |
| Checklist | ✅ | ❌ | ✅ | ❌ | ❌ |
| Document storage | ❌ | ❌ | ❌ | ✅ | ❌ |

---

## 4. Pricing Comparison

| App | Free Tier | Premium | Lifetime |
|---|---|---|---|
| **WrenchLog** | 1 vehicle, core features | $14.99/yr | $49.99 |
| **CARFAX** | Full (8 vehicles) | — | — |
| **Simply Auto** | Ads, limited | ~$4-5/mo or yearly | ❌ |
| **MyAutoLog** | Limited | Yearly sub (TBD) | ❌ |
| **Road Trip** | ❌ | — | ~$5-10 one-time |

**Insight:** WrenchLog'un fiyatlandırması pazarla uyumlu. $14.99/yr makul. $49.99 lifetime iyi bir hook. CARFAX tamamen ücretsiz olması agresif ama onlar farklı bir iş modeli (veri satışı). Simply Auto reklamlı free tier'ı ile paranoyak privacy kullanıcılarını kaybediyor — biz bu segmenti yakalıyoruz.

---

## 5. WrenchLog'un Unique Moat'ları (Rakiplerde YOK)

### 🏆 Tier 1 Moat (Hiç kimsede yok)
1. **Vehicle Health Score (0-100)** — Gerçek zamanlı bakım sağlık puanı. Kritik servislere ağırlık veriyor. **Pazardaki tek app.**
2. **Smart Reminders (driving pace-aware)** — Sadece tarih/km değil, kullanıcının gerçek sürüş hızına göre hatırlatan tek app.
3. **Gamification (Milestone Badges)** — First Service, Dedicated, Road Warrior, Fleet Owner... Retention mekaniklerinin olmadığı bir pazarda güçlü differentiator.
4. **Seasonal Maintenance Suggestions** — Mevsime göre context-aware bakım önerileri.
5. **Zero Data Collection + No Ads** — Privacy manifestoda "Data Not Collected". CARFAX verini topluyor, Simply Auto reklam gösteriyor. Biz temiz.

### 🥈 Tier 2 Moat (Bazılarında var ama bizimki daha iyi)
6. **NHTSA Recall Alerts** — CARFAX dışında çok az rakipte var
7. **6 Fuel Type Support** — Regular, Mid-Grade, Premium, Diesel, E85, Electric
8. **30+ Preset Service Types / 6 Categories** — Hızlı giriş kolaylığı
9. **Maintenance Checklist** — Custom to-do lists per vehicle

---

## 6. Gap Analysis — WrenchLog'da Eksik Olanlar

| Gap | Rakipte Var | Öncelik | Not |
|---|---|---|---|
| **iCloud Sync** | MyAutoLog | 🔴 Yüksek | Multi-device kullanıcılar için kritik. En çok istenen feature olabilir. |
| **Garage/Service Locator** | MyAutoLog, CARFAX | 🟡 Orta | MapKit ile uygulanabilir ama scope büyük |
| **Modification Tracking** | MyAutoLog | 🟡 Orta | Enthusiast segment için önemli |
| **Document Storage** | MyAutoLog | 🟡 Orta | Sigorta, ruhsat, garanti belgeleri |
| **GPS Mileage Tracking** | Simply Auto | 🟠 Düşük-Orta | Tax deduction use case — niş ama sadık |
| **Cross-platform** | Simply Auto, CARFAX | 🔵 Düşük | iOS-only stratejimiz doğru, başka bir zaman |
| **Voice Input** | Simply Auto | 🔵 Düşük | Nice-to-have, öncelikli değil |

---

## 7. Positioning Map

```
                    SIMPLE ←————————————→ COMPLEX
                         |
              CARFAX     |        Simply Auto
              (free,     |        (GPS, tax,
               auto)     |         detailed)
                         |
        FREE  ———————————+————————————— PAID
                         |
           WrenchLog     |        Road Trip
           (health,      |        (TCO, charts,
            privacy)     |         one-time)
                         |
              MyAutoLog  |        FIXD/OBD
              (clean,    |        (hardware,
               iCloud)   |         diagnostics)
                         |
```

**WrenchLog'un Sweet Spot:** Simple + Affordable + Privacy + Unique Features (health score, gamification)

---

## 8. Strategic Recommendations

### Kısa Vade (Önümüzdeki 1-2 update)
1. **iOS 26 SDK build** — 28 Nisan deadline! Zorunlu.
2. **iCloud Sync** — En büyük gap. MyAutoLog bunu yapıyor, biz yapmıyoruz.
3. **Document Storage** — Sigorta/ruhsat ekleme, düşük effort, yüksek perceived value.

### Orta Vade (3-6 ay)
4. **Modification Tracking** — Enthusiast segment'i yakala.
5. **Garage Locator** — MapKit entegrasyonu.
6. **Widget** — Home screen'de health score + sonraki servis hatırlatması.

### Uzun Vade
7. **AI-powered predictions** — "Your brake pads may need replacement in ~2 months based on your driving pattern"
8. **CarPlay entegrasyonu** — Mileage log while driving
9. **Watch complication** — Health score at a glance

### ASO Aksiyonları
- Keyword'lerde "oil change tracker" ve "car health" öne çıkarılmalı — rakipler bu termleri kullanmıyor
- Description'da "health score" ve "privacy" vurgusunu artır — unique differentiator
- MyAutoLog'un "best car maintenance tracker" sıralamasını hedefle

---

## 9. Threat Assessment

| Threat | Seviye | Açıklama |
|---|---|---|
| **MyAutoLog büyümesi** | 🔴 Yüksek | Aynı segment, aktif geliştirici, Liquid Glass UI, iCloud sync |
| **CARFAX ücretsiz kalması** | 🟡 Orta | Onlar farklı segment (profesyonel servis), DIY kullanıcıları bize gelir |
| **Apple Reminders yeterli** | 🟢 Düşük | Basit hatırlatma app'e alternatif değil, tracking yok |
| **AI/LLM maintenance apps** | 🟡 Orta | Henüz iyi bir örneği yok ama gelecekte tehdit olabilir |

---

## 10. Bottom Line

WrenchLog **doğru pozisyonda**: privacy-first, health score, gamification, smart reminders — hiçbir rakipte birlikte bulunmayan bir kombinasyon.

**Acil aksiyon:** iOS 26 SDK deadline (28 Nisan) ve iCloud Sync gap'ini kapatmak.

**En yakın tehdit:** MyAutoLog — benzer pozisyonlama ama iCloud sync + garage locator + mod tracking avantajları var. Health score ve gamification bizim en büyük moat'umuz.
