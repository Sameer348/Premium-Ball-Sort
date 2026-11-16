# Sort Sphere: store listing

## Identity
| | |
|---|---|
| App name (both stores) | **Sort Sphere: Ball Sort Puzzle** (29 chars, fits Play's and Apple's 30) |
| Android package | `com.sortsphere.sort_sphere` |
| iOS bundle ID | `com.sortsphere.sortSphere` |
| Version | 1.0.0 (build 1), from `pubspec.yaml` |
| Devices | Phones only, portrait. iOS is iPhone-only. |
| Default language | English (US) |

The package and bundle IDs can't be changed after the first upload. If you want your own domain in them, change them before you publish (Android: `android/app/build.gradle.kts`; iOS: Xcode › Runner › Signing & Capabilities).

## Category
| Store | Primary | Secondary / tags |
|---|---|---|
| Google Play | **Game › Puzzle** | Tags: Puzzle, Casual, Brain games, Relaxing, Offline |
| Apple App Store | **Games › Puzzle** | Secondary: Games › Casual |

## Age rating
- **Google Play (IARC questionnaire):** answer *No* to violence, fear, gambling, user-generated content, real-money purchases and location sharing. Expected rating: **Everyone / PEGI 3**. Answer *Yes* to "Contains ads".
- **App Store:** answer *None* to every content descriptor. Expected rating: **4+**. Answer *No* to "Made for Kids", because the AdMob ads aren't set up for children's apps.
- **Google Play target audience:** pick 13+ age groups only, for the same reason.

## Google Play short description (80 chars)
Sort colorful balls into tubes. 2,000 calm, satisfying puzzles that play offline.

## App Store subtitle (30 chars)
Calm, satisfying ball puzzles

## App Store promotional text (170 chars)
A fresh Daily Challenge every day, 2,000 campaign levels, Endless, Time Attack and Perfect modes, plus glowing ball skins and themes to unlock.

## App Store keywords (100 chars, comma-separated, no spaces)
ball,sort,color,tube,puzzle,water,brain,relax,logic,offline,casual,match,bubble,daily,iq,calm

## Full description (both stores, under 4,000 chars)

**Sort the balls. Clear your mind.**

Sort Sphere is a calm, beautiful color-sorting puzzle. Tap a tube to pick up its top ball, then tap another tube to drop it, onto a matching color or into an empty tube. Fill every tube with a single color to win. It takes seconds to learn and stays satisfying for hours.

Glass tubes, glossy 3D balls, gentle animations and soft sounds make every move feel good.

**WHY YOU'LL LOVE IT**
• 2,000 levels that grow from relaxing to truly clever, up to 12 tubes and 10 colors.
• Every level is solvable: a built-in solver checks each one.
• No timers or penalties in Classic mode. Play at your own pace.
• Earn up to 3 stars per level by beating the move target.
• Plays fully offline: progress, levels and rewards all work without internet.

**5 WAYS TO PLAY**
• Classic: follow the journey map through the whole campaign.
• Daily Challenge: one new puzzle every day, the same for every player, with streak rewards.
• Endless: puzzle after puzzle that slowly gets harder.
• Time Attack: beat the clock for a time bonus.
• Perfect Sort: finish within the move limit for double coins.

**HELPFUL BOOSTERS**
Stuck? A Hint shows the smartest next move, found by the same solver that checks every level. Undo a mistake, add an Extra Tube, or Shuffle the unsorted balls. Shuffle always keeps the puzzle solvable.

**MAKE IT YOURS**
Unlock 10 ball styles (Glass, Crystal, Neon, Candy, Metallic, Pearl, Galaxy, Fire, Ice), tube styles and 9 glowing board themes. They are purely cosmetic and never pay-to-win.

**COME BACK EVERY DAY**
Collect a 7-day login reward, keep your daily streak alive and unlock 12 achievements.

**ACCESSIBLE**
Color symbols put a shape on every ball, so color is never the only clue. Reduce Motion, large touch targets and text scaling are also supported.

Relax, focus, and sort your way to a clear mind.

---

## Google Play: Data safety form
The game collects no personal data, needs no account and stores progress only on the device. The AdMob SDK does collect data, so declare:

| Data type | Collected | Shared | Purpose |
|---|---|---|---|
| Device or other IDs (advertising ID) | Yes | Yes | Advertising or marketing, Analytics, Fraud prevention |
| App interactions | Yes | Yes | Advertising, Analytics |
| Crash logs / Diagnostics | Yes | Yes | Analytics |
| Approximate location (from IP, via the ads SDK) | Yes | Yes | Advertising |

Answer the remaining questions as follows:
- Data is encrypted in transit: **Yes**.
- Users can request data deletion: **No**. No account data is stored. Players can reset local progress in Settings.
- Contains ads: **Yes**.

## App Store: App Privacy ("nutrition label")
The app shows Apple's App Tracking Transparency prompt once, after the consent form and before any ad loads, and ships an app privacy manifest (`ios/Runner/PrivacyInfo.xcprivacy`) that matches these answers.

- **Data Used to Track You:** Identifiers › Device ID (Third-Party Advertising). Only this type is marked "used for tracking", matching Google Mobile Ads' own manifest.
- **Data Linked to You:** none.
- **Data Not Linked to You:** Usage Data (Advertising Data, Product Interaction), Location (Coarse), Diagnostics (Crash Data, Performance Data, Other Diagnostic Data). None of these are used for tracking.

## Required URLs (you host these)
- **Privacy policy URL:** required on both stores because the app shows ads. It must mention Google AdMob and the advertising ID. The in-app privacy text is in `lib/core/constants/app_info.dart`.
- **Support email** (both stores) and **Support URL** (App Store).
- **Marketing URL:** optional.

## Assets in this folder
| File | Use |
|---|---|
| `branding/app_icon_1024.png` | App Store icon (1024×1024, no transparency) |
| `branding/play_store_icon_512.png` | Play Store hi-res icon (512×512) |
| `branding/splash_logo.png` | Transparent logo used on the launch screens |
| `google_play/feature_graphic_1024x500.png` | Play feature graphic |
| `google_play/screenshots/*.png` | Play phone screenshots (1080×1920, ×8) |
| `app_store/screenshots_6.9/*.png` | App Store iPhone 6.9" (1320×2868, ×8) |
| `app_store/screenshots_6.5/*.png` | App Store iPhone 6.5" (1284×2778, ×8) |
| `app_store/screenshots_6.3/*.png` | App Store iPhone 6.1"/6.3" (1179×2556, ×8) |
| `app_store/screenshots_ipad_13/*.png` | App Store iPad 12.9"/13" (2048×2732, ×8). Only needed if the build supports iPad; this build is iPhone-only. |
| `raw_screenshots/*.png` | Unframed captures from the iPhone 17 Pro Max simulator |

Screenshot order and captions: 1 Sort the balls · 2 2,000 levels · 3 Collect stars · 4 Daily puzzle · 5 Five modes · 6 Journey map · 7 Ball skins & themes · 8 Smart hint.

## Before you submit
1. **AdMob:** create the AdMob apps and ad units. Replace Google's test App IDs in `android/app/src/main/AndroidManifest.xml` and `ios/Runner/Info.plist`. Put your unit IDs in `lib/services/ads/ad_config.dart` and set `_productionNotConfigured = false`.
2. **Android upload key:** create a keystore and fill in `android/key.properties` (copy `android/key.properties.example`). Without it, release builds are debug-signed and Play will reject them. Then build:
   ```bash
   flutter build appbundle --release
   ```
   Upload `build/app/outputs/bundle/release/app-release.aab`.
3. **iOS:** open `ios/Runner.xcworkspace` in Xcode, choose your Team under Signing & Capabilities, then build:
   ```bash
   flutter build ipa --release
   ```
   Upload with Transporter or Xcode Organizer.
4. **Privacy messages:** configure the GDPR / US-states messages in the AdMob console. The app already shows them through UMP.
