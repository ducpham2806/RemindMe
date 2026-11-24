# RemindMe English style guide (source language)

> TL;DR: English is the source for every translation, so write short, literal, verb-first strings that translate cleanly.
> Address the user as "you", use sentence case, and never hand-format dates, times, numbers or prices: CLDR formatters do that.
> Every string is a complete ICU message with named placeholders and a description that states its length limit.
> Paywalls state price, period, renewal and how to cancel, with no pressure tactics. Terms come from `glossary.csv`.

Applies to: app UI, notifications, watch, widgets, permission strings, emails, store listing, help center.
Related: `docs/architecture/i18n-l10n.md` (process, tiers, quality gates), `docs/uiux/ux-flows-and-screens.md` §6 (microcopy),
`docs/product/pricing-entitlements.md` §4 (paywall messages). Vietnamese rules: `style-guide-vi.md`.

## 1. Source English
- Spelling: US English (`color`, `canceled`) in the `en` source. Users in GB/AU/IN/CA get the same strings; dates, times and numbers
  still follow their region through CLDR. Where US and UK spelling differ, keep US spelling everywhere; en-GB LQA checks only those
  words. Whether to ship an `en_GB` override file is an open question (README).
- Write for translation: one idea per string, no idioms, no puns, no pop-culture references, no sentence fragments that depend on
  another string. If a word has two meanings in English (check-in, ticket, open), the key description says which one.
- Do not use phrasal-verb chains or noun stacks: "Turn on notifications", not "Notification permission enablement".

## 2. Voice and tone
- Calm, direct, helpful. The app is a reliable assistant, not a cheerleader.
- Short sentences, verb first: "Snooze 10 min", "Add to trip", "Enter manually".
- Never blame the user. Say what happened and what they can do next.
- No exclamation marks in UI. No "Oops", "Uh-oh", "Awesome", "Magic".
- No hype words: "seamless", "powerful", "supercharge", "revolutionary", "effortless".

| Context | Tone | Example |
|---|---|---|
| Everyday UI | Plain, brief | "3 reminders today" |
| Errors | Calm, specific, one next step | "Can't read this photo. Try a sharper photo or enter it manually." |
| Health and medication | Neutral, factual, never advice | "Fasting required" (only if the slip says so) |
| Death anniversary, memorial dates | Respectful, no emoji | "Grandfather's death anniversary" |
| Paywall | Factual, no pressure | "Plus has no limit on repeating reminders." |
| Success | Quiet confirmation | "Plus unlocked" |

## 3. Addressing the user
- Second person, "you". Do not use "my" in labels ("My lists" → "Lists"). Exception: the tab named `Me` (see glossary `nav_me`).
- The app does not say "I". It uses "RemindMe" or an impersonal sentence. "We" only in legal text, privacy explanations and support emails.
- Sample sentences the user would type or say may use "me": "Remind me to call Mom tomorrow at 9".
- Do not guess the user's gender, age, or family role. No gendered forms anywhere.

## 4. Capitalization
- Sentence case for everything: titles, buttons, tabs, menu items, settings, notification titles. "Restore purchases", "Language & region".
- Capitalize proper nouns and product names as their owners do: RemindMe, Plus, Free (plan name), Apple Watch, Wear OS, Microsoft To Do,
  Google Calendar, App Store, Google Play. Named feature "Quick Add" keeps its capitals.
- Never use ALL CAPS in strings. If a design shows uppercase section headers ("OVERDUE"), the style does it, and only for scripts
  that have case.
- Codes stay as written: VN245, SGN, ABC123.

## 5. Punctuation and symbols
- No period at the end of buttons, labels, titles, chips, tabs or notification titles. Use periods in body text, even with one sentence.
- Ellipsis character `…` for progress ("Reading…"), not three dots. Do not use ellipsis to mean "opens a dialog".
- Serial comma: "events, appointments, and bookings".
- No em dashes or semicolons in UI. Use a period or a colon.
- `·` (middle dot) separates facts in compact lines: "VN245 SGN→HAN · Terminal 1". The arrow `→` is decoration; give screen readers
  a spoken label (§11).
- `&` only in fixed short labels from the glossary ("Language & region", "Plan & usage"). In sentences write "and".
- Use the typographic apostrophe `’` (U+2019) in contractions ("can’t") and curly quotes `“ ”`. With `use-escaping` on, a straight `'`
  is an ICU escape character and must be doubled, which translators often break.
- Emoji: at most one, as a leading marker in notifications (⏰ ✈), never carrying meaning alone and never in errors or paywalls.

## 6. Numbers, dates, times, money
Never format by hand. No `dd/MM/yyyy`, no `"$" + price`, no `"8" + "am"`.

| Value | How | en-US output | en-GB output |
|---|---|---|---|
| Date | `DateFormat` skeleton (`MMMEd`, `yMMMd`) | Thu, Nov 26 | Thu 26 Nov |
| Time | skeleton `jm` + 24h setting from OS | 8:00 AM | 08:00 |
| Number | `NumberFormat` | 1,890 | 1,890 |
| Store price | Localized price string from the store/RevenueCat | $39.99 | £39.99 |
| Booking price | Original currency, never converted | ₫1,890,000 | ₫1,890,000 |
| Time zone | City name from CLDR, both times when they differ | 10:30 AM Hanoi time · 4:30 AM London time | |

- Always numerals: "3 reminders", "1 trip", not "three reminders".
- Durations ("10 min", "1 hour") and relative times ("in 2 hours"): Dart `intl` has no unit or relative-time formatter, so L1 decides the
  formatter (platform ICU via channel, or a package). Until then, write them as ICU plural messages per unit and let translators
  own the unit word. Never concatenate a number and a unit string.
- Ambiguous user input (`03/04`) is a parser concern, not copy: the UI shows a chip with both readings.
- Example sentences for Quick Add hints are user input, so they can read "Take pills tomorrow at 8am". Displayed times are never
  written like that.

## 7. Length limits
Count user-perceived characters (grapheme clusters). Each limit goes in the key's `@description`; CI fails strings over the limit
(i18n-l10n.md §8.6). For CJK, use about 60% of the Latin limit (proposed). German and French run about 30-35% longer than English,
so the English source should sit well under the limit.

| Surface | Limit | Status |
|---|---|---|
| Watch notification title | ≤ 30 | from i18n-l10n.md §7 |
| Notification title (phone) | ≤ 40 | proposed |
| Notification body | ≤ 100 (2 lines on most lock screens) | proposed |
| Notification action button | ≤ 20 | proposed |
| Watch line 2, complication, Tile text | ≤ 20 / ≤ 12 / ≤ 20 | proposed |
| Widget line (small / medium) | ≤ 20 / ≤ 30 | proposed |
| Button | ≤ 24, may wrap to 2 lines | proposed |
| Tab label | ≤ 12 | proposed |
| Chip | ≤ 18 | proposed |
| Section header | ≤ 24 | proposed |
| Snackbar / toast | ≤ 60 | proposed |
| Empty state: sentence + CTA | ≤ 80 + ≤ 24 | proposed |
| Paywall headline / body | ≤ 40 / ≤ 140 | proposed |
| App Store: name, subtitle, keywords | 30, 30, 100 | platform limit, check before submission |
| Google Play: title, short description | 30, 80 | platform limit, check before submission |

## 8. Placeholders and ICU (Flutter `gen-l10n`)
- One complete sentence per key. Never build a sentence from parts: word order changes by language.
- Named, meaningful placeholders: `{used}`, `{limit}`, `{tripName}`, never `{0}` or `{s}`.
- Each placeholder is declared with `type` and `example` in the ARB metadata.
- Times that depend on an event's time zone are pre-formatted in code and passed as `String`. Plain dates can be passed as `DateTime`
  with a skeleton in `format`.
- Plurals: write all forms English needs (`=0` only when the zero sentence is different, `one`, `other`). Translators add the CLDR
  categories their language uses (`few`, `many`...). `other` is always present.
- Repeat the named placeholder inside plural branches instead of `#`; Flutter's handling of `#` is not reliable across tools.
- Flutter does not support `offset` in plurals or ICU gender. Use `select` for item kinds and booking types, not for the user.
- Nest at most one level (a `select` containing a `plural`). Deeper nesting goes into separate keys.
- Enable `use-escaping` in `l10n.yaml` so `'` and `{` can be escaped consistently; describe escapes in the key description.

```json
"paywallRecurringLimit": "You’re using {used} of {limit} repeating reminders on Free. Plus has no limit: {monthlyEquivalent}/month, billed {yearlyPrice} per year.",
"@paywallRecurringLimit": {
  "description": "Paywall body when the user creates one more repeating series than Free allows. Prices are store-localized strings. Max 140 chars.",
  "placeholders": {
    "used": {"type": "int", "example": "5"},
    "limit": {"type": "int", "example": "5"},
    "monthlyEquivalent": {"type": "String", "example": "$3.33"},
    "yearlyPrice": {"type": "String", "example": "$39.99"}
  }
},
"notifRemainingToday": "{count, plural, =0{Last one today} one{{count} more today} other{{count} more today}}",
"@notifRemainingToday": {"description": "Line 2 of a repeating reminder notification. Max 40 chars.", "placeholders": {"count": {"type": "int", "example": "2"}}}
```

Key descriptions say: where the string appears, what each placeholder holds, the length limit, and which glossary term applies
when a word is ambiguous ("check-in = airline check-in, glossary trip_checkin_flight").

## 9. Error messages
Pattern: **what happened** + **what to do**. Add why only when it helps the user act.
- Lead with the problem in plain words: "Can't read this photo."
- Give one next step, as a sentence or as the button: "Try a sharper photo or enter it manually."
- No error codes, stack names or "failed" in the main text. Codes go in a details view or the bug report.
- Never imply data loss that did not happen. If data is safe, say so: "Your changes are saved on this phone."
- Use "can't" for things the app can't do, not "you can't".
- Offline is a state, not an error: no red, no blocking.

## 10. Paywall wording
These rules apply to every locale and every A/B test.
1. Show the real charge: price, billing period, and that it renews automatically. A per-month equivalent always appears next to the
   actual yearly or 3-month charge.
2. Prices come from the store as localized strings. No hand-built currency, no rounded "only $3".
3. Trial: state its length and the date of the first charge: "Free for 7 days, then {price} per month from {date}."
4. Say how to cancel ("Cancel anytime in App Store settings") and show Restore purchases, Terms and Privacy Policy links.
5. No fake urgency (countdowns, "only today"), no fake scarcity, no confirmshaming ("No thanks, I like forgetting things").
   The close button is "Not now" or an icon with the label "Close".
6. "Unlimited" only for limits that are really unlimited in Plus (`-1` in `plan_entitlements`). Never "unlimited everything".
7. Savings percentages are computed from the actual store prices for that storefront, not written into the string.
8. Reassure, never threaten: reminders the user already created keep ringing on Free (pricing-entitlements.md §3). Say it when relevant:
   "Your existing reminders keep ringing."
9. Do not call the Free plan "limited", "basic" or "trial" in a way that belittles it.

## 11. Accessibility wording
- Every icon-only control has a label that names the action: "Snooze", "Add item", "Search". Not "Button", not "Icon".
- Strings with symbols get a separate spoken label: `VN245 SGN→HAN` → "Flight VN245 from SGN to HAN"; `⏰` and `🔁` are not read;
  "🔁" becomes "Repeats daily" in the semantics label.
- Spoken labels expand abbreviations: "10 minutes", not "10 min".
- No directions by position or color: "Tap Save", not "Tap the button on the right"; "Fields marked Check this", not "yellow fields".
- Link and button text says where it goes: "Open Privacy Policy", not "Learn more" alone.
- Plain language: common words, about 15 words per sentence or fewer.
- Layout must survive 200% text size (i18n-l10n.md §9). Never shorten a string just to fit at default size.

## 12. Terminology
Use `glossary.csv` for every product term. Highlights:
- "Repeat" in UI, never "recurrence". "This one / this and future ones / all repeats", never "occurrence" or "series".
- "Snooze", "Done", "Open ticket", "Directions" for notification actions.
- "Suggestions" for unreviewed imports; "Review" for the checking screen.
- "booking code", not "PNR" (PNR only in help).
- "Follows current time zone" / "Fixed to event time zone", never "floating"/"fixed" alone.
- Airline check-in and hotel check-in are different keys.

## 13. Do and don't (from the P0 flows)
| # | Flow | Do | Don't |
|---|---|---|---|
| 1 | Onboarding value | Snap a ticket or say a sentence. RemindMe handles the reminders. | Unlock your productivity superpowers with AI magic! |
| 2 | Permission priming | Allow notifications so reminders ring on time. | We need notification access. |
| 3 | Priming, second button | Not now | No, I don't care about my tasks |
| 4 | Quick Add hint | Take pills tomorrow at 8am | Enter task here... |
| 5 | Notification | Title: `⏰ 8:00 AM Take blood pressure pill`. Body: `2 more today` | Reminder!!! It's time to take your blood pressure pill now |
| 6 | Notification action | Snooze 10 min | Remind me again in ten minutes |
| 7 | Overdue item | Overdue | You missed this! |
| 8 | OCR failure | Can't read this photo. Try a sharper photo or enter it manually. | Error 422: OCR failed. |
| 9 | Review, unsure field | Check this: arrival time | Invalid arrival time |
| 10 | Offline banner | You're offline. Reminders still ring on time, and changes sync when you're back online. | No internet connection. Please try again later. |
| 11 | Missing permission | Reminders may not ring. [Turn on notifications] | Notifications disabled. Fix it now! |
| 12 | Paywall, repeating limit | You're using 5 of 5 repeating reminders on Free. Plus has no limit: $3.33/month, billed $39.99 per year. | Only today! 80% off, don't miss out! |
| 13 | Trip limit | Free includes 1 active trip. Archive a past trip or upgrade to Plus. | You've hit your limit. Upgrade now. |
| 14 | Voice language missing | This language isn't available for speech on this phone yet. [Change voice language] | Speech recognition not supported. |
| 15 | Empty Suggestions | Forward a booking email and it shows up here. [Set up email forwarding] | Nothing here yet! |
| 16 | Delete account | Delete your account and synced data? This can't be undone. Your App Store subscription continues until you cancel it there. | Are you sure? |
| 17 | DST gap | 2:30 AM doesn't exist on Mar 8 because of daylight saving time. This reminder will ring at 3:00 AM. | Invalid time (DST). |
| 18 | Restore purchases, nothing found | No purchases found for this Apple ID. | Restore failed. |

Prices and dates in the table are examples of formatter output, not literals.
