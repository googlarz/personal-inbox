<!--
Variant of categories.md with calendar: auto — used only for the one scenario
(fixture #2 / #11) that deliberately exercises real calendar execution against
a connected calendar MCP. Never use this manifest against a real Inbox root;
it will create a real event if a calendar is connected.
-->

---
calendar: auto
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
