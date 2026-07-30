# Product Requirements Document — Kids Church Check-In/Check-Out App

**Document status:** Draft, reverse-engineered from the current codebase (v1.0.0+1) as of 2026-07-30.
**App identifier:** `com.kidschurch.checkin` · Flutter (Android only, no iOS target)
**Owner:** TBD
**Audience:** Product, engineering, church operations/volunteer coordinators

---

## 1. Overview

### 1.1 Purpose
The app digitizes the children's check-in and check-out process for a church service (Kids Church). It replaces manual sign-in sheets with a kiosk-style tablet/phone workflow where a volunteer scans a guardian's badge, selects the children to check in, and the system prints a name-tag sticker for each child and a pickup slip with a QR code for the guardian. At pickup, the guardian's pickup slip is scanned to release the matching children.

### 1.2 Problem statement
Physical sign-in sheets are slow, error-prone, and provide no reliable audit trail of who a child was released to. This app aims to:
- Speed up drop-off and pickup lines during service.
- Guarantee every checked-in child has a matching physical sticker and a guardian-held pickup slip.
- Match guardians to children unambiguously via a scannable code (QR/barcode), reducing wrong-person pickups.
- Give staff/admins a record of attendance per service session.

### 1.3 Deployment model
This is a **kiosk-mode Android application**, deployed on dedicated tablets/devices at check-in and check-out stations, each paired with:
- A **Mindeo/MS-M7710 handheld barcode scanner** (USB-HID keyboard-wedge — it "types" scanned codes, no SDK integration needed).
- An **M90 / REGO RG-KL532A-H 80mm Bluetooth or USB thermal printer**.

There is currently no iOS build; the product is Android-only by design (kiosk hardware pairing via USB is central to the workflow).

### 1.4 Out of scope (for this version)
- Parent/guardian self-service mobile app (this app is volunteer/staff-operated only).
- Payments, giving, or donation features.
- Multi-campus/multi-tenant support.
- iOS.

---

## 2. Goals & success metrics

| Goal | Metric (proposed) |
|---|---|
| Faster check-in than paper | Avg. time to check in 1 guardian + N children under kiosk conditions |
| Zero wrong-guardian pickups | 0 checkout confirmations where scanned pickup code doesn't match issued code |
| Every checked-in child has a physical audit artifact | 100% of successful check-ins produce a printed sticker + pickup slip |
| Reliable hardware pairing | < X% of shifts require printer/scanner reconnection troubleshooting |
| Accurate attendance reporting | Attendance Summary reflects real backend data (currently a gap — see §8) |

---

## 3. Users & roles

The app has three roles (`User.role`: `volunteer`, `staff`, `admin`), enforced client-side via computed permission flags on the `User` entity:

| Capability | Volunteer | Staff | Admin |
|---|:---:|:---:|:---:|
| Log in, scan/check in, check out (`canScan`) | ✅ | ✅ | ✅ |
| View Attendance Summary (`canViewReports`) | ❌ | ✅ | ✅ |
| Manage users / access Settings management (`canManageUsers`) | ❌ | ❌ | ✅ |

Demo credentials currently shown directly on the Login screen: `scanner/scanner123` (volunteer-tier), `admin/admin123` (admin-tier) — **should be removed before production release.**

The Home screen exposes role-gated action tiles via `RoleBasedNavigation`; the Settings gear in the AppBar is reachable by everyone regardless of role, which is an inconsistency with the "admin only" Settings tile gating (see §8).

---

## 4. Information architecture / navigation

Single-stack push/pop navigation via `go_router` — no bottom tab bar, no drawer.

```
Splash (auto-login check, ~2s branded splash)
  → Login (if no valid session)
  → Home (if session restored)

Home (AppBar: settings gear, logout menu; body: role-gated action cards)
  ├─ Guardian Check-In      (primary check-in flow)
  ├─ Check Out              (primary checkout flow)
  ├─ Attendance Summary     (staff/admin only)
  └─ Settings               (admin-only tile; also reachable via AppBar gear for all roles)

Guardian Check-In / Check Out
  └─ QR Scanner (camera fallback, shared page, returns via callback)
```

Two check-in entry points exist in the codebase: the current **Guardian Check-In** flow (linked from Home) and a **legacy single-child Check-In** page (`/checkin`, routable but not linked from Home) — see §8 for reconciliation notes.

---

## 5. Features

### 5.1 Authentication

**Login**
- Username/password form → `POST /api/auth/login` with `{username, password}`.
- On success: JWT + serialized user profile persisted to `SharedPreferences`; token attached to all subsequent API calls.
- Blocked outright with a clear message if the device has no internet connectivity (checked via `connectivity_plus` before attempting login).

**Session restore**
- On app launch, Splash calls `GET /api/auth/me` if a stored token exists.
- If that call fails (e.g., offline), the app falls back to the last cached user profile in `SharedPreferences` so a volunteer isn't locked out by a transient network blip.

**Token refresh**
- A Dio interceptor watches for `401` responses. On first 401 (excluding the login/refresh calls themselves), it calls `POST /api/auth/refresh` with the current token, updates the stored token, and **transparently retries the original request** — the end user never sees a forced re-login mid-shift unless the refresh itself fails.

**Logout**
- Client-side only: clears in-memory token and wipes the cached session. No backend logout/session-revocation endpoint is called.

**Requirement gaps to decide on:** secure token storage (currently plaintext `SharedPreferences`, no `flutter_secure_storage`), removal of demo credentials from the login UI, and a real backend logout call if session revocation matters.

### 5.2 Guardian-based check-in (primary flow)

1. Volunteer opens **Guardian Check-In**. The screen is **gated behind an active printer connection** — if no printer is connected, scanning is blocked entirely and the volunteer is directed to Settings to pair one (rationale: guarantee every check-in produces a physical sticker/audit trail).
2. Guardian's badge is scanned — either automatically via the paired hardware barcode scanner (keystroke-wedge input captured globally on the page) or via camera fallback (`QRScannerPage`).
3. The scanned value is resolved as either a guardian's raw QR code or a Mongo ObjectId, and the app fetches the guardian plus their linked children (`GET /api/guardians/:id/children`).
4. Volunteer selects a **service session** (from `GET /api/services`) and checks off which of the guardian's children are being dropped off (multi-select checklist).
5. Volunteer taps "Check In N Child(ren)" → `POST /api/attendance/checkin` with `{guardianId, serviceId, childIds}`.
6. On success, each child gets its own `AttendanceRecord` with a unique **pickup code**. The app immediately prints:
   - One **name-tag sticker per child** (child's name, age group, service + check-in time).
   - One **pickup slip** listing all children's names + pickup codes, plus a QR code encoding `{guardianQrCode, pickupCodes[], childIds[]}` — this QR is what checkout later scans.
7. Success is confirmed on-screen with child names + codes; the form resets automatically after ~3 seconds so the station is ready for the next family.
8. API errors (e.g., "child already checked in," validation errors) are parsed from the standard error envelope and shown as a clear message rather than a raw exception.

### 5.3 Check-out

1. Volunteer opens **Check Out**. Guardian scans their **pickup slip QR** (same hardware-scanner-first, camera-fallback pattern as check-in).
2. The app validates the scanned JSON payload (`guardianQrCode`, `pickupCodes[]`, `childIds[]`), then looks up each child's display name individually (`GET /api/children/:id` per child — no batch lookup endpoint currently).
3. A confirmation card lists the children and their pickup codes for the volunteer to visually verify against the guardian.
4. Volunteer taps "Confirm Check-Out" → `POST /api/attendance/checkout` with `{guardianId, childIds, pickupCodes}`, which closes out the matching `AttendanceRecord`s.
5. Success message shown; form resets after ~4 seconds.

### 5.4 Legacy single-child check-in (secondary/legacy flow)
A pre-guardian-model flow (`/checkin` route) still present in the codebase: pick a service, scan one child directly (QR or RFID button — RFID is disabled, see §5.6), check in that single child via `POST /api/attendance/checkin`, and print a single name-tag sticker with a pickup code. Not linked from the Home screen's role-based navigation, so it's effectively dormant in the current UX. **Decision needed:** keep as a documented fallback, or remove now that the guardian flow is the standard.

### 5.5 Sticker & pickup-slip printing

- **Sticker size:** 50mm × 100mm, rendered at 8 dots/mm on an 80mm thermal printer (M90/REGO RG-KL532A-H class), 576 dots/line.
- **Rendering:** stickers are drawn as a bitmap (Flutter `Canvas`/`Paragraph` + a generated QR image), rotated to match the physical feed orientation, then converted to ESC/POS raster print commands — not plain ESC/POS text — so layout/centering is controlled precisely.
- **Name-tag sticker contents:** "KIDS CHURCH" header, child's full name (large/bold), age group, service name + check-in time.
- **Pickup slip contents:** "PICKUP SLIP" header, each child's name and pickup code, service name/time, and a QR code (the payload checkout scans back in).
- **Connectivity:** Bluetooth (primary) and USB (OTG, with a native Android fallback that queries `UsbManager` directly for printers the Bluetooth/USB plugins miss). Last-connected printer is remembered and auto-reconnected on app start; a manual "reconnect" path exists for when the printer silently drops mid-shift.
- **Device matching heuristic:** name-based matching (e.g. contains "printer," "thermal," "rego," "m90," "goojprt," etc.) used when scanning for pairable devices.
- Settings screen supports connect/disconnect, scanning for both Bluetooth and USB printers, a test-print button, and clearing the saved connection.

### 5.6 Hardware scanner integration (MS-M7710)

- The M7710 is treated as a **USB-HID keyboard**: it types the scanned code's characters rapidly, followed by Enter.
- A dedicated service buffers raw key events, distinguishes machine-speed input from human typing (max ~100ms between keystrokes), requires a minimum code length, and auto-clears stale partial input — emitting a clean "barcode scanned" event.
- Both Guardian Check-In and Check Out pages listen globally for this event (via an always-focused, invisible key listener) so a badge scan works automatically without the volunteer tapping any button first — camera scanning remains available as a manual fallback.
- **RFID/NFC support exists in the data model and UI (buttons, fields) but is currently disabled** at the service layer — treat as a "not yet available" capability, not a working one, until re-enabled.

### 5.7 Attendance Summary (reporting)

- Staff/admin-only screen: date picker, three summary stat cards (Total Check-ins / Still Here / Completed), and a list of individual attendance entries.
- **Current state: this screen renders hardcoded sample data**, not live attendance. The backend already exposes reporting/attendance endpoints (`/api/reports/attendance`, `/api/attendance/active`, `/api/attendance/stats`) that are not yet wired up. This is the single biggest functional gap between "what the UI implies" and "what the app actually does" today — see §8.

### 5.8 Settings

- User info display.
- Printer pairing/management (see §5.5).
- Data Management section: "Clear Cache" and "Export Data" buttons are present but currently non-functional (UI stub only).
- About section: app version, Privacy Policy/Terms links — currently non-functional placeholders.

### 5.9 Offline behavior

- A local SQLite database (`sqflite`) exists with tables for children and check-in sessions, but is **currently wiped on every app launch** (explicit dev-only code, marked for removal before production) and is **not used at all** by the primary guardian check-in/checkout flow — those are fully network-dependent today.
- Practical implication for the PRD: **the app currently has no meaningful offline mode.** If offline resilience during a service (e.g., venue WiFi drop) is a real requirement, it needs to be scoped and rebuilt deliberately rather than assumed to exist.

---

## 6. Data model (as implemented)

| Entity | Key fields |
|---|---|
| **Child** | id, fullName, dateOfBirth, gender, ageGroup, guardianIds[] (supports multiple guardians per child), emergencyContact {name, relationship, phone}, specialNotes, qrCode, rfidTag, isActive, currentlyCheckedIn, lastCheckIn/Out, audit fields |
| **Guardian** | id, guardianId (separate human-readable code), firstName, lastName, contactNumber, email, relationship, qrCode, rfidTag, linkedChildren[], isActive, audit fields |
| **AttendanceRecord** | id, childId, guardianId, serviceId, checkInTime, checkOutTime, pickupCode, stickerPrinted, status (checkedIn/checkedOut), audit fields |
| **ServiceSession** | id, name, startTime/endTime, dayOfWeek, isActive, description, ageGroups[], maxCapacity, audit fields; computed "is currently active" based on day/time window |
| **User** | id, username, email, fullName, role, isActive, lastLogin, audit fields |
| **CheckInSession** *(legacy)* | id, serviceSessionId, date, createdBy, checkedInChildren[], isActive — superseded by per-child `AttendanceRecord`, retained for backward compatibility |

**Relationship model:** children and guardians are many-to-many (`Child.guardianIds[]` and `Guardian.linkedChildren[]`), which correctly reflects real families (blended families, multiple authorized pickup adults, etc.).

---

## 7. Backend / API summary

- REST API, JSON envelope `{success, message, data}`, consumed via `dio`.
- Auth: login, current-user, refresh.
- Children: list/search/filter, get by id, get by QR/RFID code.
- Guardians: list, get by id, get children for guardian, link/unlink child, update, activate/deactivate, generate QR/RFID.
- Attendance: check in (single + guardian/batch), check out (single + guardian/batch), active list, stats, per-child/per-guardian history.
- Services: list, get by id.
- Reports: attendance, children, guardians, dashboard (**defined but not yet consumed by any screen** — needed to make §5.7 real).
- **Environment config:** base URL is hardcoded in source (currently a LAN dev IP) with no build-flavor/env-var switching mechanism — a production deployment concern, not just a code style issue, since it means every environment change requires a new build.

---

## 8. Known gaps & decisions needed

These are real discrepancies between the current implementation and what the UI/UX implies is available. They should be explicitly triaged (fix now vs. accept as-is vs. remove UI) rather than left ambiguous:

1. **Attendance Summary shows mock data**, not live attendance — needs to be wired to the existing (unused) reporting endpoints.
2. **RFID/NFC UI is visible but disabled** — decide whether to ship it, hide it, or remove it from this release.
3. **No real offline mode** despite `sqflite` being present — decide if offline resilience is a requirement; if so it needs dedicated design (sync strategy, conflict handling), not just "turn the DB back on."
4. **Two check-in flows** (guardian-based vs. legacy single-child) — recommend deprecating/removing the legacy flow now that guardian-based check-in is standard, to reduce maintenance surface and volunteer confusion.
5. **Two API client implementations** in the codebase (`api_service.dart`, `enhanced_api_service.dart`) — needs consolidation.
6. **Hardcoded dev API URL**, no environment switching — needs a proper dev/staging/prod config mechanism before wider rollout.
7. **Settings "Clear Cache" / "Export Data" / Privacy Policy / Terms"** are non-functional stubs — decide scope or remove from UI until implemented.
8. **JWT stored in plaintext SharedPreferences** — consider secure storage given the app handles children's PII.
9. **Demo credentials shown on the login screen** — must be removed before any production/public-facing deployment.
10. **No distinct production signing config** (release build reuses debug signing) — needs a real release signing setup before store/enterprise distribution.
11. **Verbose request/response logging** (Dio `LogInterceptor`, full bodies) — should be disabled or scrubbed in production builds to avoid leaking tokens/PII to device logs.
12. **Checkout does per-child name lookups one at a time** (no batch endpoint) — fine at small family sizes, but worth a batch endpoint if performance matters at scale.

---

## 9. Non-functional requirements

- **Platform:** Android only (no iOS project in repo); kiosk-style dedicated devices, portrait orientation locked.
- **Hardware pairing:** must support Bluetooth and USB(OTG) thermal printers in the M90/REGO family, and USB-HID barcode scanners in the M7710 family (plus common alternatives: Honeywell, Zebra/Symbol, Datalogic, Newland).
- **Connectivity:** requires internet connectivity for all core flows (login, check-in, check-out) in the current implementation; connectivity is checked proactively before login attempts.
- **Permissions:** Camera (QR fallback scanning), Bluetooth (scan/connect, plus location permission as required by Android for BLE scanning), USB host (OTG printer/scanner), NFC (declared, unused while RFID is disabled).
- **Data sensitivity:** the app handles children's PII (name, DOB, emergency contact, special notes) and guardian PII (contact info) — data handling, retention, and storage practices should be reviewed against relevant child-safety and privacy expectations for the organization.

---

## 10. Suggested roadmap (not yet committed)

1. **Harden for production:** remove demo credentials, add env-based API config, add release signing, gate/remove debug logging, decide on secure token storage.
2. **Close the reporting gap:** wire Attendance Summary to real backend data.
3. **Resolve legacy duplication:** retire the legacy single-child check-in flow and the unused `CheckInSession` model, or explicitly document why both remain.
4. **Decide on RFID/offline:** either invest in re-enabling RFID and building real offline support, or remove the vestigial UI/dependencies to reduce confusion.
5. **Settings follow-through:** implement or remove Clear Cache/Export Data/Privacy/Terms stubs.

---

*This document was generated by reading the current source tree (routes, providers, services, models, native Android code, and API client) rather than from prior product specs, since none existed in the repo. Sections 8–10 should be reviewed with the product owner to confirm which gaps are intentional trade-offs versus unfinished work.*
