#!/usr/bin/env bash
# Scripted demo run using synthetic fixture data — see demo/README.md.
# Mirrors the real output format of an `/inbox` run; not a live capture.

bold=$(tput bold); dim=$(tput dim); reset=$(tput sgr0)
green=$(tput setaf 2); yellow=$(tput setaf 3); blue=$(tput setaf 4)

type_line() { printf "%s" "$1"; sleep 0.4; printf "\n"; }
pause() { sleep "$1"; }

printf "%s❯ %s/inbox\n" "$blue" "$reset"
pause 0.6

printf "%sScanning Inbox root...%s\n" "$dim" "$reset"
pause 0.6
printf "  1 new file in drop folder\n"
printf "  2 accounts checked (Gmail, Proton Mail) — 3 keeper attachments found\n"
pause 0.8
printf "\n%sExtracting + classifying...%s\n" "$dim" "$reset"
pause 0.9
printf "  scan_2026-07-17.pdf → digest written, SHA-256 recorded\n"
pause 0.4

printf "\n%s%s4 items need a decision%s\n\n" "$bold" "$green" "$reset"

printf "%s%-32s %-12s %-30s %s%s\n" "$bold" "Item" "Category" "Proposed action" "Conf." "$reset"
pause 0.2
printf "%-32s %-12s %-30s %s\n" "N26 statement, June" "Finance" "file only" "high"
pause 0.2
printf "%-32s %-12s %-30s %s\n" "Bolt receipt, Jul 12" "Mobility" "file only" "high"
pause 0.2
printf "%-32s %-12s %-30s %s\n" "Klassenfahrt Anmeldung" "Family" "calendar: reply by 2026-08-01" "high"
pause 0.2
printf "%-32s %-12s %-30s %s\n\n" "Krankenkasse reminder" "Health/skill" "task: schedule appt" "medium"

printf "%sConfirm all? [y/edit/skip]%s " "$yellow" "$reset"
pause 0.5
printf "y\n"
pause 0.5

printf "\n%s✓%s Filed 4 documents · %s✓%s 1 calendar entry created · %s✓%s 1 task handed to health-skill\n" \
  "$green" "$reset" "$green" "$reset" "$green" "$reset"
printf "%sNothing else pending. .inbox-state.json updated.%s\n" "$dim" "$reset"
pause 1.2
