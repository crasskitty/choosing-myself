# Choosing Myself

A private no-contact counter for iPhone. It is the companion to the choosing.myself page: quiet lines about outgrowing people, on a dark screen, with the words you do not send.

There is no account, no backend, and no AI. The day count, the letters, and the nickname stay on the phone in SwiftData. A one-time unlock (intended price $4.99, product id `com.choosingmyself.unlock`) is the only purchase. The day counter is never behind it.

Requires iOS 17 or later. Open the project in current Xcode on a Mac.

## What you get

- Onboarding in three pages. The line "You chose yourself.", the date no contact started, an optional nickname ("him", "the ex"), and one mood: Rain, Night Drive, or Ocean.
- Home. A large day count, today's line, and one button: "I want to text them."
- Urge. A 60-second breath, then a letter. "Lock it away" saves it on the phone. The streak stays. "I need to write now" skips the rest of the minute if you cannot wait.
- Letters. The vault. Tap to reread. Swipe, or use Release, to delete one.
- Milestones at 7, 30, 60, 90, and 365 days. Sharing a 9:16 card is part of the unlock.
- Settings. Mood, a daily reminder, the lock, "I slipped", restore, and erase.
- A Home Screen and Lock Screen widget with the day count and today's line, after the unlock.

Day 1 is the date you pick. The next local midnight makes it day 2.

## Free and unlocked

| | Free | Unlock |
| --- | --- | --- |
| Day counter | Yes | Yes |
| Today's line | Yes | Yes |
| Urge breathing | Yes | Yes |
| Daily reminder | Yes | Yes |
| Moods | The one you pick at the start | Rain, Night Drive, and Ocean |
| Unsent letters | 3 | No limit |
| Face ID or passcode lock | No | Yes |
| Milestone list | Yes, you can see them | Yes, and you can share the card |
| Widgets | A locked placeholder | Day count and today's line |
| "I slipped" | Today becomes day 1. The record of this run does not stay. Letters stay. | Today becomes day 1. Your best streak stays. Letters stay. |

There is no subscription.

## Open it on a Mac

1. Install current Xcode from the Mac App Store. The project format is the Xcode 16 synchronized-folder format (`objectVersion` 77), which current Xcode opens. The deployment target is iOS 17.0. Swift language mode is 5.
2. Clone this repository.
3. Open `ChoosingMyself.xcodeproj`. Do not open a workspace you create yourself. The project already has one inside the xcodeproj.
4. If Xcode offers to update project settings, accept it, then build again.
5. In the toolbar, set the run destination to any iPhone simulator on iOS 17 or later.
6. Select the **ChoosingMyself** target, then the **ChoosingMyselfWidget** target. For each one, open **Signing & Capabilities** and choose your Team. Automatic signing is already on.
7. Press Run.

The first build needs a development team because of the App Group entitlement. A free personal team is enough for the simulator. A paid Apple Developer Program membership is required to put the app on a device for more than a few days and to submit to the App Store.

## Bundle ids

| Target | Bundle id |
| --- | --- |
| App | `com.choosingmyself.app` |
| Widget | `com.choosingmyself.app.widget` |

Change both if `com.choosingmyself` is not yours. Keep the widget id as the app id plus `.widget`. In Xcode this is **Signing & Capabilities**, or the build setting `PRODUCT_BUNDLE_IDENTIFIER`.

## App Group (required for the widget)

The app and the widget share one group:

`group.com.choosingmyself.shared`

It is written in three places that must match:

- `Shared/AppIdentity.swift` (`appGroupID`)
- `ChoosingMyself/ChoosingMyself.entitlements`
- `ChoosingMyselfWidget/ChoosingMyselfWidget.entitlements`

Create it once, then attach it to both App IDs:

1. Go to [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources).
2. Identifiers → App Groups → add `group.com.choosingmyself.shared`.
3. Edit the app id `com.choosingmyself.app` and the widget id `com.choosingmyself.app.widget`. Enable App Groups and check that group on both.
4. Back in Xcode, select each target → **Signing & Capabilities**. Confirm **App Groups** lists `group.com.choosingmyself.shared` and that it is checked. If the capability is missing, add it with the + button. Do not let Xcode replace the group with a different id.

If the group does not match, the app still runs. The widget will say "Open Choosing Myself" or stay on the locked state, because it cannot read the snapshot.

The snapshot is the day count's start date, the mood, and whether the unlock is on. Unsent letters are never copied into the App Group.

## In-app purchase

Product id: `com.choosingmyself.unlock`

Type: Non-Consumable. Intended price: $4.99. No subscription.

The id is in `Shared/AppIdentity.swift` and in `Products.storekit`. Those two strings must match the product you create in App Store Connect.

### Test it in Xcode before App Store Connect exists

The shared scheme is already pointed at `Products.storekit`.

1. Product → Scheme → Edit Scheme… → Run → Options.
2. Set **StoreKit Configuration** to `Products.storekit`. If the row is red, choose the file again from the project root. The path stored in the scheme is `../Products.storekit`, relative to the xcodeproj.
3. Run the app.
4. Finish onboarding. Open Settings → **The rest of the room**, or hit the fourth letter.
5. The button should show a price from the configuration file (about $4.99). Buy it in the simulated sheet. There is no charge.
6. Debug → StoreKit → Manage Transactions lets you refund or delete the transaction so you can test the free state again.

Deleting the app resets the on-device letters and the day count. The simulated purchase is separate. Clear it from Manage Transactions.

### Create the real product

1. App Store Connect → your app → In-App Purchases → create a **Non-Consumable**.
2. Product ID: `com.choosingmyself.unlock`. Reference name: something you will recognize, such as Unlock.
3. Set the price (the $4.99 tier, unless you choose another). Add the English display name and description. The local StoreKit file uses "Choosing Myself Unlock" and a one-sentence description. You can match that.
4. Add a review screenshot of the paywall when you submit the in-app purchase.
5. On the app id, add the **In-App Purchase** capability if it is not already there. StoreKit 2 does not need an extra entitlement key in the entitlements file.
6. Family Sharing is off in the local configuration. Turn it on in App Store Connect only if you want it. The letters still do not sync between phones.

The paywall shows `Product.displayPrice` from StoreKit. It does not invent $4.99 if the product fails to load. Restore Purchases is on the paywall and in Settings. Apple expects that.

A purchase is remembered by Apple for that Apple ID. **Erase everything on this phone** deletes the days and the letters. It does not refund the unlock.

## Notifications

Reminders are off until you turn them on in Settings. The app then asks for notification permission and schedules the next 14 days, each with that day's line and the day count. It refreshes the schedule when the app comes forward and when you change the time. The default time, once you enable it, is 9:00 p.m.

Letters are not in the notification. The line can show on the Lock Screen. Say so if someone asks. Settings already says it.

## Face ID

Off until the unlock is purchased and the switch is turned on. Turning it on, and turning it off, asks for Face ID or the device passcode first. The app uses `deviceOwnerAuthentication`, so a passcode works when Face ID does not. On a Touch ID phone the label follows the hardware.

On the simulator: Features → Face ID → Enrolled. Then Matching Face or Non-matching Face while the prompt is up.

The lock appears when the app goes to the background and the next time it opens. The widget cannot ask for Face ID. It shows the day count and today's line, not the letters. Settings says that.

## Widget

1. Run the app once and finish onboarding so it writes a snapshot.
2. Unlock the purchase if you want the real widget. Without it, the widget is a lock, not the day count. The widget is part of the paid set. The counter inside the app is not.
3. On the simulator home screen, long-press, add a widget, and choose Choosing Myself. Small and medium are there, plus the Lock Screen styles (inline, circular, rectangular).
4. The widget computes the day count and the line itself from the start date and `HealingLines.json`, so it can change at midnight without opening the app. If you edit the lines, run the app once so both copies are rebuilt.

## The lines

Edit `Shared/HealingLines.json`. Keep it valid JSON. There are 60 lines.

The app picks one line per calendar day: days since January 1, 2001, wrapped around the list. The same date always shows the same line until the file changes.

- Rewording a line changes that sentence only.
- Inserting, deleting, or reordering lines changes which day lands on which sentence.

Both the app and the widget copy this file into their bundles. It is already a member of both targets. You do not add it again.

If the file fails to load, the app falls back to a few built-in lines and, in a debug build, prints a message in the Xcode console.

## Project map

New Swift files you drop into `ChoosingMyself/` are picked up by Xcode (synchronized folder) and compiled into the app. The same is true for `ChoosingMyselfWidget/`. Files in `Shared/` are listed by hand in the Xcode project and compiled into both targets. If you add a new file under `Shared/`, select it and check both targets in the File inspector.

| Path | What it is |
| --- | --- |
| `ChoosingMyself/` | The app. SwiftUI, SwiftData, StoreKit, notifications, Face ID. |
| `ChoosingMyselfWidget/` | The WidgetKit extension. |
| `Shared/AppIdentity.swift` | Bundle-adjacent ids: App Group, product id, free letter limit, milestone days, the handle. |
| `Shared/HealingLines.json` | The lines. |
| `Shared/HealingCatalog.swift` | Loads the file and picks today's line. |
| `Shared/StreakMath.swift` | Day count, slip math, milestone lookup. |
| `Shared/MoodTheme.swift` | Rain, Night Drive, Ocean. |
| `Shared/JourneySnapshot.swift` | The small record the widget is allowed to see. |
| `Shared/SnapshotStore.swift` | Reads and writes that record in the App Group. |
| `Products.storekit` | Local StoreKit testing. Not shipped inside the app. |
| `Scripts/verify_logic.swift` | A small check of the day math and the JSON. Not part of the Xcode target. |
| `APP_STORE_LISTING.md` | Name, subtitle, description, keywords, review notes. |
| `PRIVACY_POLICY.md` | Draft policy to host. |

`Journey` and `UnsentLetter` are the SwiftData models. Adding an optional property is usually a lightweight migration. Renaming or removing a property can crash on launch for a phone that already opened the app. Install over an old build when you change them.

## Run the logic check

From the repository root, with a Swift toolchain:

```bash
swiftc -o /tmp/choosing-verify \
  Shared/AppIdentity.swift \
  Shared/StreakMath.swift \
  Shared/HealingCatalog.swift \
  Scripts/verify_logic.swift
/tmp/choosing-verify
```

That checks the day count, what "I slipped" does to the best streak, the free letter cap, and that the JSON still has 60 unique lowercase lines. It does not compile SwiftUI. Xcode does that.

## Before you archive

- Team set on both targets. Bundle ids are yours.
- App Group created and checked on both targets.
- In-App Purchase product created, cleared for sale, same product id.
- Version and build in the app target (`1.0.0` and `1` to start). Keep the widget's marketing version and build number the same as the app's.
- Replace `PRIVACY_POLICY.md`'s contact line, host it, and put the URL in App Store Connect. Add a support URL too.
- Privacy nutrition: Data Not Collected.
- Export compliance: the app sets `ITSAppUsesNonExemptEncryption` to NO. It does not add its own encryption.
- Archive with **Any iOS Device (arm64)**, then Distribute App. The widget is embedded by the app target. You do not archive the widget by itself.
- Review notes are drafted in `APP_STORE_LISTING.md`.

## What has not been run yet

The day-count rules, the slip rules, and the line file were checked with the command above. Every Swift file was parsed. This repository was not opened in Xcode, so the app, the widget, StoreKit, Face ID, and notifications still need the first run on your Mac. That is the step that proves it builds.
