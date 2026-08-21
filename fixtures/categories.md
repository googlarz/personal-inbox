<!--
Pinned eval manifest — never the user's real categories.md. Six categories,
chosen to exercise every field in FORMAT.md. calendar: none keeps the default
eval from ever touching a real calendar; see categories.calendar-on.md for the
one scenario that deliberately tests calendar execution.
-->

---
calendar: none
tasks: local
timezone: Europe/Berlin
---

## Mobility
description: Vehicle, public transit, and travel bookings and receipts.
destination: Mobility/
policy: file-only

## Tickets
description: Event tickets — concerts, festivals, shows.
destination: Tickets/
policy: always-check-dates

## Betriebsrat
description: ver.di correspondence and works council matters.
destination: Betriebsrat/
policy: propose-actions
skill: betriebsrat

## Finance
description: Banking, invoices, receipts, subscriptions, anything with a payment obligation.
destination: Finance/
policy: propose-actions
auto: true

## Health
description: Medical letters, lab results, insurance correspondence, appointment confirmations.
destination: Health/
policy: always-check-dates
skill: health-skill

## Tax
description: Tax authority letters, filings, annual statements needed for tax prep.
destination: Tax/
policy: file-only
