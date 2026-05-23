# FixLine — AI-powered plant floor diagnostic assistant

A focused first version of a maintenance diagnostic app for plant floor technicians. Built around speed, safety, and one-handed use with gloves.

## Features

- **AI diagnostic chat** — Describe a fault and get a structured response: Safety First, Top 3 Probable Causes, 60-Second Check, Step-by-Step Resolution, and a feedback prompt at the end.
- **Hybrid AI** — Uses on-device Apple Intelligence when offline; switches to cloud AI when connected for richer diagnoses. A small badge shows which mode is active.
- **QR equipment scanner** — Tap "Scan" to open the camera, scan an equipment QR code, and instantly load that machine's profile and start a diagnostic session pre-tagged to it. Manual entry fallback for the simulator.
- **Equipment library** — Browse a list of pre-loaded plant equipment (conveyors, fillers, cappers, labelers, palletizers) with photos, line location, last service date, and recent fault history.
- **Equipment detail page** — Shows specs, common failure points, recent diagnostic sessions, and a "Start Diagnosis" button.
- **Diagnostic history** — All past sessions saved per equipment, searchable, with the resolution outcome (fixed / unresolved).
- **Quick-fault chips** — Tap common faults like "Won't start", "E-stop tripped", "Sensor fault", "VFD fault" to skip typing.
- **Fault code lookup** — Paste or type a VFD/PLC fault code to get an instant interpretation.
- **Vibration Check** — Use the phone gyroscope/motion sensor to capture a quick vibration baseline and flag likely mechanical issues like looseness, bearing wear, misalignment, imbalance, or belt/chain slap.
- **Feedback loop** — Every diagnosis ends with "Did this fix the issue?" Yes marks resolved; No prompts for PLC light status, voltage readings, and fault codes to refine.

## Design

- **Industrial dark mode** — Deep charcoal background, near-black surfaces, with a bold **safety-yellow** primary accent and a red alert color for hazards.
- **Big tap targets** — Buttons and list rows oversized for gloved hands, with strong haptic feedback on every action.
- **High-contrast typography** — Bold, condensed-feeling headers; mono-style readouts for codes and voltage values.
- **Hazard banners** — Safety warnings appear as a yellow-and-black striped header at the top of every diagnosis, instantly recognizable.
- **Status pills** — Color-coded tags for online/offline AI, equipment status (Running / Down / Maintenance), and session result.
- **Scannable layout** — Numbered steps, bullet checklists, and bold section headers so a tech can read while walking the line.
- **Subtle motion** — Smooth section reveals as the AI streams its diagnosis, plus a satisfying confirmation when an issue is marked resolved.
- **App icon** — Bold safety-yellow lightning bolt over a dark gear silhouette on charcoal — instantly reads as "industrial fix-it."

## Screens

- **Home / Dashboard** — Big "Scan Equipment" button at top, quick-fault chips, recent equipment, and recent diagnostic sessions.
- **QR Scanner** — Full-screen camera viewfinder with a yellow targeting frame; manual code entry on the simulator.
- **Equipment Library** — Searchable list of all machines on the line with status pills and last-fault info.
- **Equipment Detail** — Machine photo, specs, common failures, recent sessions, and "Start Diagnosis" CTA.
- **Diagnostic Session** — Chat-style screen showing the structured AI response (Safety → Causes → 60-Sec Check → Steps → Feedback). Online/offline AI badge in the header.
- **Fault Code Lookup** — Quick screen to paste a code and get an interpretation.
- **Vibration Check** — New screen for a 15-second motion capture with live g-force meter, safety warning, probable vibration pattern, and capture steps.
- **History** — All past diagnostic sessions across equipment, filterable by resolved/unresolved.
- **Settings** — AI mode preference (auto/online/offline), haptics toggle, and an "About" page noting login, subscriptions, and document upload are coming next.

