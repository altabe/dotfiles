---
name: iphone-shortcut
description: Build, sign, deliver and debug iPhone Shortcuts (.shortcut files) yourself, e.g. to export Health data or call an API. Use whenever a task needs an iOS Shortcut or automation.
---

You build the shortcut; the user only imports and runs it. Never ask them to add, edit or configure actions by hand, even if one is broken: fix the file and resend it.

The only manual steps you may ask for:
- importing or running the file
- answering a system permission prompt
- creating an Automation (a shortcut file can't include one)
- turning on a Settings toggle

Ask for them in one short message, with exact taps.

## Build
- Generate the plist with Python `plistlib`. `example_build.py` is a working reference (Health → HTTP PUT); copy its helpers.
- Every action has a `UUID`. Reference another action's output via `{Type: ActionOutput, OutputUUID, OutputName}`.
- **Text with variables** (`WFTextTokenString`): put U+FFFC in the string at each variable's spot. In `attachmentsByRange`, the key is `{pos, 1}`, with pos counted in UTF-16 units.
- **Properties and date formats** go in `Aggrandizements`: `WFPropertyVariableAggrandizement` (PropertyName) and `WFDateFormatVariableAggrandizement` (`ISO 8601`, `WFISO8601IncludeTime`).
- **Sign:** `shortcuts sign --mode anyone -i in.shortcut -o out.shortcut`. Check the plist first with `plutil -lint`.
- **Deliver:** send the file to the user with whatever channel works (e.g. a WhatsApp message to themselves). AirDrop often fails.
- Put a version tag in the file name (`-v7`) and tell the user to delete the old copy.

## Don't guess encodings
Copy the parameter shapes from a real exported shortcut, never from memory:
- Fetch a public iCloud shortcut from `https://www.icloud.com/shortcuts/api/records/<id>`, then download `fields.shortcut.value.downloadURL` (an unsigned binary plist) and run `plutil -convert xml1` on it.
- Another source: the viticci/shortcuts-playground-plugin references.

If the shortcut imports fine but behaves like the default (wrong type, ignored filter), the encoding is wrong. Don't blame the user's phone.

## Health pitfalls (verified)
- **Find Health Samples** (`is.workflow.actions.filter.health.quantity`): `WFContentItemFilter` is a `WFContentPredicateTableTemplate` with `WFActionParameterFilterPrefix 1`. It needs both of these rows:
  - Type: `{Property: Type, Operator: 4, Bounded: true, Removable: false, Values: {Enumeration: {Value: "<label>", WFSerializationType: WFStringSubstitutableState}}}`
  - Start Date: `{Property: "Start Date", Operator: 1001, Bounded: true, Removable: false, Values: {Number: "1", Unit: 16}}` (1001 = "is in the last", 16 = days; "last 1 day" also reaches into the previous calendar day)
  - Without the date row, the type is ignored and you get Steps. `WFHealthQuantityType` does nothing.
- **Type labels:** `Sleep` (not "Sleep Analysis"), `Heart Rate`, `Heart Rate Variability`, `Steps`, `Active Calories`, `Exercise Minutes`.
- **HRV values arrive in seconds.** Multiply by 1000 to get ms.
- **Sleep samples:** Value is Core/Deep/REM/Awake/In Bed. Apple Watch tracks sleep only during Sleep Focus or the Sleep schedule.
- **Never Repeat over hundreds of samples:** it hangs for minutes. Put list properties straight into one Text action (each becomes a newline-joined list). Add a separator such as `\n---\n` between properties and zip them on the server.
- **"Allow sharing large amounts of data"** prompts appear above a few hundred items and block unattended runs. Keep the limits small (sort latest first, limit on). If a prompt still appears, ask the user once to turn on Settings → Apps → Shortcuts → Advanced → Allow Sharing Large Amounts of Data.
- **A locked iPhone can't read Health data**, so a time-based automation may get nothing. Never overwrite good data with empty data.

## Secrets
- Import questions (`WFWorkflowImportQuestions`) are easy to skip by accident. If the user has already given you the key, embed it in the file instead.
- A file with an embedded key is a secret: `chmod 600`, send it only to the user themselves, and never print the key.

## Debug without the user
- Have the shortcut write a version marker plus a timestamp to the destination, and show the server's reply in a notification. Then check the result on the server side yourself after each run.
- Only ask the user "did it run?" and for what the notification showed.
- If the marker didn't change, the run failed before sending. If the data is all the same type, the filter encoding is wrong.
