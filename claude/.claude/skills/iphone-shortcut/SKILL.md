---
name: iphone-shortcut
description: Build, sign, deliver and debug iPhone Shortcuts (.shortcut files) yourself, for any purpose. Use whenever a task needs an iOS Shortcut or automation.
---

You build the shortcut; the user only imports and runs it. Never ask them to add, edit or configure actions by hand, even if one is broken: fix the file and resend it.

The only manual steps you may ask for:
- importing or running the file
- answering a system permission prompt
- creating an Automation (a shortcut file can't include one)
- turning on a Settings toggle

Ask for them in one short message, with exact taps.

## Build
- Generate the plist with Python `plistlib`. `examples/` holds a working generator; reuse its helpers (text tokens, variables, properties, dictionaries, HTTP request).
- Every action has a `UUID`. Reference another action's output via `{Type: ActionOutput, OutputUUID, OutputName}`.
- **Text with variables** (`WFTextTokenString`): put U+FFFC in the string at each variable's spot. In `attachmentsByRange`, the key is `{pos, 1}`, with pos counted in UTF-16 units.
- **Properties and date formats** go in `Aggrandizements`: `WFPropertyVariableAggrandizement` (PropertyName) and `WFDateFormatVariableAggrandizement` (e.g. `ISO 8601` with `WFISO8601IncludeTime`).
- **Sign:** check the plist with `plutil -lint`, then run `shortcuts sign --mode anyone -i in.shortcut -o out.shortcut`.
- **Deliver:** send the file to the user with whatever channel works (e.g. a message to themselves). AirDrop often fails.
- Put a version tag in the file name (`-v3`) and tell the user to delete the old copy.

## Don't guess encodings
Copy each action's parameter shape from a real exported shortcut, never from memory:
- Fetch a public iCloud shortcut that uses the action from `https://www.icloud.com/shortcuts/api/records/<id>`, then download `fields.shortcut.value.downloadURL` (an unsigned binary plist) and run `plutil -convert xml1` on it.
- Another source: the viticci/shortcuts-playground-plugin references.

Signs the encoding is wrong:
- the shortcut imports fine but acts on defaults (a wrong type, an ignored filter, an empty field)
- an unknown key is silently dropped

Don't blame the user's phone.

**Filters** ("Find …" actions) are a `WFContentPredicateTableTemplate`. Some actions need specific locked, non-removable rows, or the other rows are ignored. Copy the whole template.

**Picker values** use the UI label, not the API name.

## Runtime pitfalls
- **Don't use Repeat over large lists:** it can hang for minutes. Put list properties straight into one Text action (each becomes a newline-joined list), and process them on the receiving side.
- **On a locked iPhone, protected data may be unreadable,** so a time-based automation may get nothing. Never overwrite good data with an empty result.
- **The first run shows one-time permission prompts** (data access, sending to a domain, sharing large amounts of data). Tell the user to tap "Always Allow"; after that, unattended runs are fine.

## Secrets
- Import questions (`WFWorkflowImportQuestions`) are easy to skip by accident. If the user has already given you a value, embed it in the file instead.
- A file with an embedded secret is itself a secret: `chmod 600`, send it only to the user themselves, and never print the secret.

## Debug without the user
- Make the shortcut leave evidence you can check yourself. For example, write a version marker plus a timestamp to the destination, and show the server's reply in a notification.
- Only ask the user "did it run?" and for what any error said.
- If the marker didn't change, the run failed before reaching the destination.

## Domain notes
Load a file from `references/` only when the shortcut touches that area (e.g. `references/health.md` for Health data).
