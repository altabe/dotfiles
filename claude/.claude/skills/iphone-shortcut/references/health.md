# Health (verified on a real device)

- **Find Health Samples** (`is.workflow.actions.filter.health.quantity`): `WFContentItemFilter` is a `WFContentPredicateTableTemplate` with `WFActionParameterFilterPrefix 1`. It needs both of these rows:
  - Type: `{Property: Type, Operator: 4, Bounded: true, Removable: false, Values: {Enumeration: {Value: "<label>", WFSerializationType: WFStringSubstitutableState}}}`
  - Start Date: `{Property: "Start Date", Operator: 1001, Bounded: true, Removable: false, Values: {Number: "1", Unit: 16}}` (1001 = "is in the last", 16 = days; "last 1 day" also reaches into the previous calendar day)
  - Without the date row, the type is ignored and you get Steps. `WFHealthQuantityType` does nothing.
- **Labels:** `Sleep` (not "Sleep Analysis"), `Heart Rate`, `Heart Rate Variability`, `Steps`, `Active Calories`, `Exercise Minutes`.
- **HRV values arrive in seconds.** Multiply by 1000 to get ms.
- **Sleep Value** is Core/Deep/REM/Awake/In Bed. Apple Watch tracks sleep only during Sleep Focus or the Sleep schedule.
- **Health data can't be read on a locked phone.**
- `examples/health_to_api.py` is a working Health → HTTP PUT shortcut.
