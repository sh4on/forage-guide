# ForageGuide 🌿

A Flutter app for wild plant and mushroom foraging. Helps users identify edible and toxic species, find what's growing nearby, and keep a personal foraging journal.

Built with Flutter + free iNaturalist API. No backend, no server costs, works offline.

---

## Table of Contents

- [Features](#features)
- [Screens](#screens)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Setup & Installation](#setup--installation)
- [API Reference](#api-reference)
- [Monetization](#monetization)
- [Roadmap](#roadmap)
- [Safety Disclaimer](#safety-disclaimer)

---

## Features

- **Species Search** — Search 180M+ real-world observations from iNaturalist
- **Smart Edibility Detection** — Automatically classifies species as Edible / Toxic / Caution / Unknown using name + genus heuristics
- **Species Detail** — Photo, Wikipedia summary, foraging tips, observation count, safety warnings
- **Nearby Species** — GPS-based discovery of species recorded within 5–50 km
- **Map View** — Toggle between list and Google Maps view of nearby sightings
- **My Finds Journal** — Log personal finds with photo, GPS location, and notes
- **Offline Cache** — Recently viewed species cached in SQLite for offline use
- **Dark Mode** — Full dark/light theme support

---

## Screens

### 1. Search
- Live search against iNaturalist `/taxa` API
- Popular search chips (Chanterelle, Porcini, Morel, etc.)
- Recently viewed species list
- Offline fallback from local cache

### 2. Species Detail
- Full-size hero photo
- Edibility badge (Edible / Toxic / Caution / Unknown)
- Color-coded safety section with explanation
- Quick facts: scientific name, kingdom, observation count, rarity level, alternative names
- Wikipedia summary
- Species-specific foraging tips (custom tips for 7+ common species)
- Photo attribution from iNaturalist

### 3. Nearby
- GPS permission handling with clear error states
- Radius selector: 5 / 10 / 25 / 50 km
- Type filter: All / Fungi only / Plants only
- Summary stat cards: mushrooms, plants, edible, toxic counts
- Toggle between list view and Google Maps
- Pull-to-refresh

### 4. My Finds (Journal)
- Log finds with camera or gallery photo
- Live species search when logging
- GPS coordinates auto-tagged
- Notes up to 500 characters
- Entries grouped by month
- Stats row: total finds, unique species, with photo, located
- Swipe to delete
- Edit notes in detail view
- Sort by date or species name

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x |
| Language | Dart |
| Species Data | iNaturalist API (free, no key needed) |
| Maps | Google Maps Flutter |
| Local DB | SQLite via sqflite |
| Image Cache | cached_network_image |
| Photos | image_picker |
| Location | geolocator |
| Preferences | shared_preferences |
| Date Formatting | intl |

---

## Project Structure

```
lib/
├── main.dart                          # App entry point, theme mode, first-run routing
│
├── core/
│   ├── constants.dart                 # API base URL, free tier limits, SharedPrefs keys
│   ├── theme.dart                     # Brand colors, light/dark ThemeData
│   ├── router.dart                    # Named routes + onGenerateRoute for species detail
│   ├── disclaimer_screen.dart         # Safety disclaimer shown once on first launch
│   └── home_screen.dart               # Bottom NavigationBar shell (Search/Nearby/Journal)
│
├── data/
│   ├── api/
│   │   └── inaturalist_api.dart       # searchSpecies(), getNearbySpecies()
│   ├── local/
│   │   └── database_helper.dart       # SQLite: species_cache + journal_entries tables
│   └── models/
│       ├── species.dart               # Species model + smart edibility detection logic
│       └── journal_entry.dart         # JournalEntry model with fromMap/toMap
│
├── features/
│   ├── search/
│   │   ├── search_screen.dart         # Search UI with chips, results, recent history
│   │   └── search_controller.dart     # ChangeNotifier state for search
│   ├── species_detail/
│   │   └── species_detail_screen.dart # Full detail: photo, safety, facts, tips, wiki
│   ├── nearby/
│   │   └── nearby_screen.dart         # GPS + map + radius filter + species list
│   └── journal/
│       ├── journal_screen.dart        # Journal list grouped by month, stats row
│       ├── add_find_sheet.dart        # Bottom sheet: photo + species search + GPS + notes
│       └── journal_entry_detail.dart  # Detail view with editable notes + delete
│
└── widgets/
    ├── species_card.dart              # Reusable card: photo thumbnail + name + badge
    └── safety_badge.dart             # Colored pill badge for Edible/Toxic/Caution/Unknown
```

---

## Setup & Installation

### Prerequisites

- Flutter SDK 3.10+
- Android Studio or VS Code
- Android device or emulator (API 21+)
- Google Maps API key (free)

### 1. Clone and install dependencies

```bash
git clone https://github.com/yourname/forage_guide.git
cd forage_guide
flutter pub get
```

### 2. pubspec.yaml dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.0
  geolocator: ^12.0.0
  sqflite: ^2.3.0
  shared_preferences: ^2.2.3
  path: ^1.9.0
  cached_network_image: ^3.3.0
  google_maps_flutter: ^2.6.0
  image_picker: ^1.1.2
  intl: ^0.19.0
  url_launcher: ^6.2.6
  # Phase 5 — uncomment when ready:
  # google_mobile_ads: ^5.0.0
  # in_app_purchase: ^3.1.0
```

### 3. Android permissions

Add to `android/app/src/main/AndroidManifest.xml` inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```

### 4. Google Maps API key

Add inside `<application>` in `AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE"/>
```

Get a free key at: https://console.cloud.google.com  
Enable: **Maps SDK for Android**

### 5. Run

```bash
flutter run
```

---

## API Reference

All data comes from the **iNaturalist API** — completely free, no authentication required for read-only calls.

### Search species
```
GET https://api.inaturalist.org/v1/taxa
  ?q=chanterelle
  &rank=species
  &per_page=20
  &iconic_taxa=Plantae,Fungi
  &locale=en
```

### Nearby observations
```
GET https://api.inaturalist.org/v1/observations
  ?lat=51.5
  &lng=-0.12
  &radius=10
  &iconic_taxa=Plantae,Fungi
  &quality_grade=research
  &per_page=30
```

### Notes
- No API key needed for these endpoints
- Rate limit: ~100 requests/minute (more than enough for a mobile app)
- `quality_grade=research` means observations verified by the iNaturalist community
- Data attribution required: "Powered by iNaturalist (inaturalist.org)"

[//]: # (---)

[//]: # ()
[//]: # (## Monetization)

[//]: # ()
[//]: # (### Current &#40;Phase 1–4&#41;: Free app)

[//]: # ()
[//]: # (The app is fully free. Revenue model for Phase 5:)

[//]: # ()
[//]: # (### Phase 5: AdMob + Premium unlock)

[//]: # ()
[//]: # (**Free tier:**)

[//]: # (- Search: 5 species views per day)

[//]: # (- Nearby: available &#40;ads shown&#41;)

[//]: # (- Journal: up to 10 entries)

[//]: # ()
[//]: # (**Premium — $2.99 one-time:**)

[//]: # (- Unlimited species views)

[//]: # (- No ads)

[//]: # (- Unlimited journal entries)

[//]: # (- Offline mode for all cached species)

[//]: # ()
[//]: # (**Implementation plan:**)

[//]: # (1. Add `google_mobile_ads: ^5.0.0` to pubspec)

[//]: # (2. Create AdMob account at admob.google.com)

[//]: # (3. Add banner ad to Search and Nearby screens)

[//]: # (4. Add `in_app_purchase: ^3.1.0` for the $2.99 unlock)

[//]: # (5. Gate features using `SharedPreferences` key `is_premium`)

[//]: # ()
[//]: # (**Expected AdMob CPM for EU/US audience:** $3–12 per 1000 impressions)

[//]: # ()
[//]: # (---)

[//]: # ()
[//]: # (## Roadmap)

[//]: # ()
[//]: # (### ✅ Phase 1 — Core search &#40;complete&#41;)

[//]: # (- [x] iNaturalist API integration)

[//]: # (- [x] Species search screen)

[//]: # (- [x] Species detail screen)

[//]: # (- [x] Smart edibility detection)

[//]: # (- [x] SQLite offline cache)

[//]: # (- [x] Safety disclaimer)

[//]: # ()
[//]: # (### ✅ Phase 2 — Rich detail &#40;complete&#41;)

[//]: # (- [x] Wikipedia summary)

[//]: # (- [x] Species-specific foraging tips)

[//]: # (- [x] Photo attribution)

[//]: # (- [x] Observation count + rarity)

[//]: # (- [x] Caution badge for lookalikes)

[//]: # ()
[//]: # (### ✅ Phase 3 — Nearby &#40;complete&#41;)

[//]: # (- [x] GPS location)

[//]: # (- [x] iNaturalist observations API)

[//]: # (- [x] Google Maps integration)

[//]: # (- [x] Radius + type filters)

[//]: # (- [x] Summary stat cards)

[//]: # ()
[//]: # (### ✅ Phase 4 — Journal &#40;complete&#41;)

[//]: # (- [x] Camera + gallery photo picker)

[//]: # (- [x] GPS tagging)

[//]: # (- [x] Notes)

[//]: # (- [x] Monthly grouping)

[//]: # (- [x] Edit + delete)

[//]: # (- [x] Stats row)

[//]: # ()
[//]: # (### 🔲 Phase 5 — Monetization &#40;next&#41;)

[//]: # (- [ ] AdMob banner ads)

[//]: # (- [ ] $2.99 premium in-app purchase)

[//]: # (- [ ] Freemium gate &#40;5 views/day free&#41;)

[//]: # (- [ ] App icon + splash screen)

[//]: # (- [ ] Play Store listing)

[//]: # ()
[//]: # (### 🔲 Phase 6 — Growth features &#40;planned&#41;)

[//]: # (- [ ] Season calendar &#40;what to forage each month&#41;)

[//]: # (- [ ] Share a find &#40;WhatsApp, Instagram&#41;)

[//]: # (- [ ] Open Wikipedia in browser from detail screen)

[//]: # (- [ ] Onboarding walkthrough for new users)

[//]: # (- [ ] Push notifications for foraging season alerts)

[//]: # ()
[//]: # (---)

## Safety Disclaimer

This app is for **educational purposes only**.

- Never consume any wild plant or mushroom based solely on information from this app
- Many edible species have toxic lookalikes that require expert identification
- Always verify with a qualified local expert before eating anything foraged
- If you feel ill after foraging, seek medical attention immediately and tell the doctor what you consumed

The edibility classifications in this app are based on common name and genus heuristics and **are not a substitute for expert identification**.

---

## Data Attribution

Species data and observations are provided by **iNaturalist** (inaturalist.org), a joint initiative of the California Academy of Sciences and the National Geographic Society. All observation data is used under iNaturalist's open data policy.

---

## License

MIT License — free to use, modify, and distribute.

---

*Built with Flutter · Powered by iNaturalist · Made for foragers everywhere*